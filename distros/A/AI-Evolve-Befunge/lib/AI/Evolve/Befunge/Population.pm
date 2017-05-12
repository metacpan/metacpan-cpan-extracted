package AI::Evolve::Befunge::Population;
use strict;
use warnings;
use File::Basename;
use IO::File;
use Carp;
use Algorithm::Evolutionary::Wheel;
use Parallel::Iterator qw(iterate_as_array);
use POSIX qw(ceil);

use aliased 'AI::Evolve::Befunge::Blueprint' => 'Blueprint';
use aliased 'AI::Evolve::Befunge::Physics'   => 'Physics';
use aliased 'AI::Evolve::Befunge::Migrator'  => 'Migrator';
use AI::Evolve::Befunge::Util;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw{ blueprints config dimensions generation host physics popsize tokens } );


=head1 NAME

    AI::Evolve::Befunge::Population - manage a population


=head1 SYNOPSIS

    use aliased 'AI::Evolve::Befunge::Population' => 'Population';
    use AI::Evolve::Befunge::Util qw(v nonquiet);

    $population = Population->new();

    while(1) {
        my $gen  = $population->generation;
        nonquiet("generation $gen\n");
        $population->fight();
        $population->breed();
        $population->migrate();
        $population->save();
        $population->generation($gen+1);
    }


=head1 DESCRIPTION

This manages a population of Befunge AI critters.

This is the main evolution engine for AI::Evolve::Befunge.  It has
all of the steps necessary to evolve a population and generate the
next generation.  The more times you run this process, the more
progress it will (theoretically) make.


=head1 CONSTRUCTORS

There are two constructors, depending on whether you want to create
a new population, or resume a saved one.


=head2 new

    my $population = Population->new(Generation => 50);

Creates a Population object.  The following arguments may be
specified (none are mandatory):

    Blueprints - a list (array reference) of critters.   (Default: [])
    Generation - the generation number.                   (Default: 1)
    Host - the hostname of this Population.      (Default: `hostname`)

=cut

sub new {
    my ($package, %args) = @_;
    $args{Host}         = $ENV{HOST} unless defined $args{Host};
    $args{Generation} //= 1;
    $args{Blueprints} //= [];

    my $self = bless({
        host       => $args{Host},
        blueprints => [],
        generation => $args{Generation},
        migrate    => spawn_migrator(),
    }, $package);

    $self->reload_defaults();
    my $nd          = $self->dimensions;
    my $config      = $self->config;
    my $code_size   = v(map { 4 } (1..$nd));
    my @population;

    foreach my $code (@{$args{Blueprints}}) {
        my $chromosome = Blueprint->new(code => $code, dimensions => $nd);
        push @population, $chromosome;
    }

    while(scalar(@population) < $self->popsize()) {
        my $size = 1;
        foreach my $component ($code_size->get_all_components()) {
            $size *= $component;
        }
        my $code .= $self->new_code_fragment($size, $config->config('initial_code_density', 90));
        my $chromosome = AI::Evolve::Befunge::Blueprint->new(code => $code, dimensions => $nd);
        push @population, $chromosome;
    }
    $$self{blueprints} = [@population];
    return $self;
}


=head2 load

    $population->load($filename);

Load a savefile, allowing you to pick up where it left off.

=cut

sub load {
    my ($package, $savefile) = @_;
    use IO::File;
    my @population;
    my ($generation, $host);
    $host = $ENV{HOST};

    my $file = IO::File->new($savefile);
    croak("cannot open file $savefile") unless defined $file;
    while(my $line = $file->getline()) {
        chomp $line;
        if($line =~ /^generation=(\d+)/) {
            # the savefile is the *result* of a generation number.
            # therefore, we start at the following number.
            $generation = $1 + 1;
        } elsif($line =~ /^popid=(\d+)/) {
            # and this tells us where to start assigning new critter ids from.
            set_popid($1);
        } elsif($line =~ /^\[/) {
            push(@population, AI::Evolve::Befunge::Blueprint->new_from_string($line));
        } else {
            confess "unknown savefile line: $line\n";
        }
    }
    my $self = bless({
        host       => $host,
        blueprints => [@population],
        generation => $generation,
        migrate    => spawn_migrator(),
    }, $package);
    $self->reload_defaults();
    return $self;
}


=head1 PUBLIC METHODS

These methods are intended to be the normal user interface for this
module.  Their APIs will not change unless I find a very good reason.


=head2 reload_defaults

    $population->reload_defaults();

Rehashes the config file, pulls various values from there.  This is
common initializer code, shared by new() and load().  It defines the
values for the following items:

=over 4

=item boardsize

=item config

=item dimensions

=item physics

=item popsize

=item tokens

=back

=cut

sub reload_defaults {
    my $self = shift;
    my @config_args = (host => $self->host, gen => $self->generation);
    my $config = custom_config(@config_args);
    delete($$self{boardsize});
    my $physics        = $config->config('physics', 'ttt');
    $$self{physics}    = Physics->new($physics);
    $config            = custom_config(@config_args, physics => $self->physics->name);
    $$self{dimensions} = $config->config('dimensions', 3);
    $$self{popsize}    = $config->config('popsize', 40);
    $$self{tokens}     = $config->config('tokens', 2000);
    $$self{config}     = $config;
    $$self{boardsize}  = $$self{physics}->board_size if defined $$self{physics}->board_size;
}


=head2 fight

    $population->fight();

Determines (through a series of fights) the basic fitness of each
critter in the population.  The fight routine (see the "double_match"
method in Physics.pm) is called a bunch of times in parallel, and the
loser dies (is removed from the list).  This is repeated until the total
population has been reduced to 25% of the "popsize" setting.

=cut

sub fight {
    my $self = shift;
    my $physics    = $self->physics;
    my $popsize    = $self->popsize;
    my $config     = $self->config;
    my $workers    = $config->config("cpus", 1);
    my @population = @{$self->blueprints};
    my %blueprints = map { $_->name => $_ } (@population);
    $popsize = ceil($popsize / 4);
    while(@population > $popsize) {
        my (@winners, @livers, @fights);
        while(@population) {
            my $attacker = shift @population;
            my $attacked = shift @population;
            if(!defined($attacked)) {
                push(@livers, $attacker);
            } else {
                push(@fights, [$attacker, $attacked]);
            }
        }
        my @results = iterate_as_array(
            { workers => $workers },
            sub {
                my ($index, $aref) = @_;
                my ($attacker, $attacked) = @$aref;
                my $score;
                $score = $physics->double_match($config, $attacker, $attacked);
                my $winner = $attacked;
                $winner = $attacker if $score > -1;
                return [$winner->name, $score];
            },
            \@fights);
        foreach my $result (@results) {
            my ($winner, $score) = @$result;
            $winner = $blueprints{$winner};
            if($score) {
                # they actually won
                push(@winners, $winner);
            } else {
                # they merely tied
                push(@livers, $winner);
            }
        }
        @population = (@winners, @livers);
    }
    for(my $i = 0; $i < @population; $i++) {
        $population[$i]->fitness(@population - $i);
    }
    $self->blueprints([@population]);
}


=head2 breed

    $population->breed();

Bring the population count back up to the "popsize" level, by a
process of sexual reproduction.  The newly created critters will have
a combination of two previously existing ("winners") genetic makeup,
plus some random mutation.  See the L</crossover> and L</mutate>
methods, below.  There is also a one of 5 chance a critter will be
resized, see the L</crop> and L</grow> methods, below.

=cut

sub breed {
    my $self       = shift;
    my $popsize    = $self->popsize;
    my $nd         = $self->dimensions;
    my @population = @{$self->blueprints};
    my @probs = map { $$_{fitness} } (@population);
    while(@population < $popsize) {
        my ($p1, $p2) = $self->pair(@probs);
        my $child1 = AI::Evolve::Befunge::Blueprint->new(code => $p1->code, dimensions => $nd);
        my $child2 = AI::Evolve::Befunge::Blueprint->new(code => $p2->code, dimensions => $nd, id => -1);
        $child1 = $self->grow($child1);
        $self->crossover($child1, $child2);
        $self->mutate($child1);
        $child1 = $self->crop($child1);
        push @population, $child1;
    }
    $self->blueprints([@population]);
}


=head2 migrate

    $population->migrate();

Send and receive critters to/from other populations.  This requires an
external networking script to be running.

Exported critters are saved to a "migrate-$HOST/out" folder.  The
networking script should broadcast the contents of any files created
in this directory, and remove the files afterwards.

Imported critters are read from a "migrate-$HOST/in" folder.  The
files are removed after they have been read.  The networking script
should save any received critters to individual files in this folder.

=cut

sub migrate {
    my $self = shift;
    $self->migrate_export();
    $self->migrate_import();
}


=head2 save

    $population->save();

Write out the current population state.  Savefiles are written to a
"results-$HOST/" folder.  Also calls L</cleanup_intermediate_savefiles>
to keep the results directory relatively clean, see below for the
description of that method.

=cut

sub save {
    my $self    = shift;
    my $gen     = $self->generation;
    my $pop     = $self->blueprints;
    my $host    = $self->host;
    my $results = "results-$host";
    mkdir($results);
    my $fnbase = "$results/" . join('-', $host, $self->physics->name);
    my $fn = "$fnbase-$gen";
    unlink("$fn.tmp");
    my $savefile = IO::File->new(">$fn.tmp");
    my $popid = new_popid();
    $savefile->print("generation=$gen\n");
    $savefile->print("popid=$popid\n");
    foreach my $critter (@$pop) {
        $savefile->print($critter->as_string);
    }
    $savefile->close();
    unlink($fn);
    rename("$fn.tmp",$fn);
    $self->cleanup_intermediate_savefiles();
}


=head1 INTERNAL METHODS

The APIs of the following methods may change at any time.


=head2 mutate

    $population->mutate($blueprint);

Overwrite a section of the blueprint's code with trash.  The section
size, location, and the trash are all randomly generated.

=cut

sub mutate {
    my ($self, $blueprint) = @_;
    my $code_size = $blueprint->size;
    my $code_density = $self->config->config('code_density', 70);
    my $base = Language::Befunge::Vector->new(
        map { int(rand($code_size->get_component($_))) } (0..$self->dimensions-1));
    my $size = Language::Befunge::Vector->new(
        map { my $d = ($code_size->get_component($_)-1) - $base->get_component($_);
              int($d/(rand($d)+1)) } (0..$self->dimensions-1));
    my $end  = $base + $size;
    my $code = $blueprint->code;
    for(my $v = $base->copy(); defined($v); $v = $v->rasterize($base, $end)) {
        my $pos = 0;
        for my $d (0..$v->get_dims()-1) {
            $pos *= $code_size->get_component($d);
            $pos += $v->get_component($d);
        }
        vec($code,$pos,8) = ord($self->new_code_fragment(1,$code_density));
    }
    $blueprint->code($code);
    delete($$blueprint{cache});
}


=head2 crossover

    $population->crossover($blueprint1, $blueprint2);

Swaps a random chunk of code in the first blueprint with the same
section of the second blueprint.  Both blueprints are modified.

=cut

sub crossover {
    my ($self, $chr1, $chr2) = @_;
    my $code_size = $chr1->size;
    my $base = Language::Befunge::Vector->new(
        map { int(rand($code_size->get_component($_))) } (0..$self->dimensions-1));
    my $size = Language::Befunge::Vector->new(
        map { my $d = ($code_size->get_component($_)-1) - $base->get_component($_);
              int($d/(rand($d)+1)) } (0..$self->dimensions-1));
    my $end  = $base + $size;
    my $code1 = $chr1->code;
    my $code2 = $chr2->code;
    # upgrade code sizes if necessary
    $code1 .= ' 'x(length($code2)-length($code1))
        if(length($code1) < length($code2));
    $code2 .= ' 'x(length($code1)-length($code2))
        if(length($code2) < length($code1));
    for(my $v = $base->copy(); defined($v); $v = $v->rasterize($base, $end)) {
        my $pos = 0;
        for my $d (0..$v->get_dims()-1) {
            $pos *= $code_size->get_component($d);
            $pos += $v->get_component($d);
        }
        my $tmp = vec($code2,$pos,8);
        vec($code2,$pos,8) = vec($code1,$pos,8);
        vec($code1,$pos,8) = $tmp;
    }
    $chr1->code($code1);
    $chr2->code($code2);
    delete($$chr1{cache});
    delete($$chr2{cache});
}


=head2 crop

    $population->crop($blueprint);

Possibly (1 in 10 chance) reduce the size of a blueprint.  Each side
of the hypercube shall have its length reduced by 1.  The preserved
section of the original code will be at a random offset (0 or 1 on each
axis).

=cut

sub crop {
    my ($self, $chromosome) = @_;
    return $chromosome if int(rand(10));
    my $nd       = $chromosome->dims;
    my $old_size = $chromosome->size;
    return $chromosome if $old_size->get_component(0) < 4;
    my $new_base = Language::Befunge::Vector->new_zeroes($nd);
    my $old_base = $new_base->copy;
    my $ones     = Language::Befunge::Vector->new(map { 1 } (1..$nd));
    my $old_offset = Language::Befunge::Vector->new(
        map { int(rand()*2) } (1..$nd));
    my $new_size = $old_size - $ones;
    my $old_end  = $old_size - $ones;
    my $new_end  = $new_size - $ones;
    my $length = 1;
    map { $length *= ($_) } ($new_size->get_all_components);
    my $new_code = '';
    my $old_code = $chromosome->code();
    my $vec  = Language::Befunge::Storage::Generic::Vec->new($nd, Wrapping => undef);
    for(my $new_v = $new_base->copy(); defined($new_v); $new_v = $new_v->rasterize($new_base, $new_end)) {
        my $old_v = $new_v + $old_offset;
        my $old_offset = $vec->_offset($old_v, $new_base, $old_end);
        my $new_offset = $vec->_offset($new_v, $new_base, $new_end);
        $new_code .= substr($old_code, $old_offset, 1);
    }
    return AI::Evolve::Befunge::Blueprint->new(code => $new_code, dimensions => $nd);
}


=head2 grow

    $population->grow($blueprint);

Possibly (1 in 10 chance) increase the size of a blueprint.  Each side
of the hypercube shall have its length increased by 1.  The original
code will begin at the origin, so that the same code executes first.

=cut

sub grow {
    my ($self, $chromosome) = @_;
    return $chromosome if int(rand(10));
    my $nd       = $chromosome->dims;
    my $old_size = $chromosome->size;
    my $old_base = Language::Befunge::Vector->new_zeroes($nd);
    my $new_base = $old_base->copy();
    my $ones     = Language::Befunge::Vector->new(map { 1 } (1..$nd));
    my $new_size = $old_size + $ones;
    my $old_end  = $old_size - $ones;
    my $new_end  = $new_base + $new_size - $ones;
    my $length = 1;
    map { $length *= ($_) } ($new_size->get_all_components);
    return $chromosome if $length > $self->tokens;
    my $new_code = ' ' x $length;
    my $old_code = $chromosome->code();
    my $vec  = Language::Befunge::Storage::Generic::Vec->new($nd, Wrapping => undef);
    for(my $old_v = $old_base->copy(); defined($old_v); $old_v = $old_v->rasterize($old_base, $old_end)) {
        my $new_v = $old_v + $new_base;
        my $old_offset = $vec->_offset($old_v, $old_base, $old_end);
        my $new_offset = $vec->_offset($new_v, $new_base, $new_end);
        substr($new_code, $new_offset, 1) = substr($old_code, $old_offset, 1);
    }
    return AI::Evolve::Befunge::Blueprint->new(code => $new_code, dimensions => $nd);
}


=head2 cleanup_intermediate_savefiles

    $population->cleanup_intermediate_savefiles();

Keeps the results folder mostly clean.  It preserves the milestone
savefiles, and tosses the rest.  For example, if the current
generation is 4123, it would preserve only the following:

savefile-1
savefile-10
savefile-100
savefile-1000
savefile-2000
savefile-3000
savefile-4000
savefile-4100
savefile-4110
savefile-4120
savefile-4121
savefile-4122
savefile-4123

This allows the savefiles to accumulate and allows access to some recent
history, and yet use much less disk space than they would otherwise.

=cut

sub cleanup_intermediate_savefiles {
    my $self    = shift;
    my $gen     = $self->generation;
    my $physics = $self->physics;
    my $host    = $self->host;
    my $results = "results-$host";
    mkdir($results);
    my $fnbase = "$results/" . join('-', $host, $physics->name);
    return unless $gen;
    for(my $base = 1; !($gen % ($base*10)); $base *= 10) {
        my $start = $gen - ($base*10);
        if($base * 10 != $gen) {
            for(1..9) {
                my $delfn = "$fnbase-" . ($start+($_*$base));
                unlink($delfn) if -f $delfn;
            }
        }
    }
}


=head2 migrate_export

    $population->migrate_export();

Possibly export some critters.  if the result of rand(13) is greater
than 10, than the value (minus 10) number of critters are written out
to the migration network.

=cut

sub migrate_export {
    my ($self) = @_;
    $$self{migrate}->blocking(1);
    # export some critters
    for my $id (0..(rand(13)-10)) {
        my $cid = ${$self->blueprints}[$id]{id};
        $$self{migrate}->print(${$self->blueprints}[$id]->as_string);
        debug("exporting critter $cid\n");
    }
}


=head2 migrate_import

    $population->migrate_import();

Look on the migration network for incoming critters, and import some
if we have room left.  To prevent getting swamped, it will only allow
a total of (Popsize*1.5) critters in the array at once.  If the number
of incoming migrations exceeds that, the remainder will be left in the
Migrator receive queue to be handled the next time around.

=cut

sub migrate_import {
    my ($self) = @_;
    my $critter_limit = ($self->popsize * 1.5);
    my @new;
    my $select = IO::Select->new($$self{migrate});
    if($select->can_read(0)) {
        my $data;
        $$self{migrate}->blocking(0);
        $$self{migrate}->sysread($data, 10000);
        my $in;
        while(((scalar @{$self->blueprints} + scalar @new) < $critter_limit)
           && (($in = index($data, "\n")) > -1)) {
            my $line = substr($data, 0, $in+1, '');
            debug("migrate: importing critter\n");
            my $individual =
                AI::Evolve::Befunge::Blueprint->new_from_string($line);
            push(@new, $individual) if defined $individual;
        }
    }
    $self->blueprints([@{$self->blueprints}, @new])
        if scalar @new;
}


=head2 new_code_fragment

    my $trash = $population->new_code_fragment($length, $density);

Generate $length bytes of random Befunge code.  The $density parameter
controls the ratio of code to whitespace, and is given as a percentage.
Density=0 will return all spaces; density=100 will return no spaces.

=cut

sub new_code_fragment {
    my ($self, $length, $density) = @_;
    my @safe = ('0'..'9', 'a'..'h', 'j'..'n', 'p'..'z', '{', '}', '`', '_',
                '!', '|', '?', '<', '>', '^', '[', ']', ';', '@', '#', '+',
                '/', '*', '%', '-', ':', '$', '\\' ,'"' ,"'");

    my $usage = 'Usage: $population->new_code_fragment($length, $density);';
    croak($usage) unless ref($self);
    croak($usage) unless defined($length);
    croak($usage) unless defined($density);
    my $physics = $self->physics;
    push(@safe, sort keys %{$$physics{commands}})
        if exists $$physics{commands};
    my $rv = '';
    foreach my $i (1..$length) {
        my $chr = ' ';
        if(rand()*100 < $density) {
            $chr = $safe[int(rand()*(scalar @safe))];
        }
        $rv .= $chr;
    }
    return $rv;
}


=head2 pair

    my ($c1, $c2) = $population->pair(map { 1 } (@population));
    my ($c1, $c2) = $population->pair(map { $_->fitness } (@population));

Randomly select and return two blueprints from the blueprints array.
Some care is taken to ensure that the two blueprints returned are not
actually two copies of the same blueprint.

The @fitness parameter is used to weight the selection process.  There
must be one number passed per entry in the blueprints array.  If you
pass a list of 1's, you will get an equal probability.  If you pass
the critter's fitness scores, the more fit critters have a higher
chance of selection.

=cut

sub pair {
    my $self = shift;
    my @population = @{$self->blueprints};
    my $popsize    = scalar @population;
    my $matchwheel = Algorithm::Evolutionary::Wheel->new(@_);
    my $c1 = $matchwheel->spin();
    my $c2 = $matchwheel->spin();
    $c2++ if $c2 == $c1;
    $c2 = 0 if $c2 >= $popsize;
    $c1 = $population[$c1];
    $c2 = $population[$c2];
    return ($c1, $c2);
}


=head2 generation

    my $generation = $population->generation();
    $population->generation(1000);

Fetches or sets the population's generation number to the given value.
The value should always be numeric.

When set, as a side effect, rehashes the config file so that new
generational overrides may take effect.

=cut

sub generation {
    my ($self, $gen) = @_;
    if(defined($gen)) {
        $$self{generation} = $gen;
        $self->reload_defaults();
    }
    return $$self{generation};
}


1;
