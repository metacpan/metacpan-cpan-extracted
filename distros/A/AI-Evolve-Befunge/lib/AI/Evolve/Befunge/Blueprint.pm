package AI::Evolve::Befunge::Blueprint;
use strict;
use warnings;
use Carp;
use Language::Befunge::Vector;
use Perl6::Export::Attrs;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(code dims size id host fitness name));
use AI::Evolve::Befunge::Util;

# FIXME: consolidate "host" and "id" into a single string

=head1 NAME

    AI::Evolve::Befunge::Blueprint - code storage object

=head1 SYNOPSIS

    my $blueprint = Blueprint->new(code => $codestring, dimensions => 4);
    my $name   = $blueprint->name;
    my $string = $blueprint->as_string;

=head1 DESCRIPTION

Blueprint is a container object for a befunge creature's code.  It gives
new blueprints a unique name, so that we can keep track of them and
tell critters apart.  One or more Critter objects may be created from
the Befunge source code contained within this object, so that it may
compete with other critters.  As the critter(s) compete, the fitness
score of this object is modified, for use as sort criteria later on.


=head1 METHODS

=head2 new

    my $blueprint = Blueprint->new(code => $codestring, dimensions => 4);

Create a new Blueprint object.  Two attributes are mandatory:

    code - a Befunge code string.  This must be exactly the right
           length to fill a hypercube of the given dimensions.
    dimensions - The number of dimensions we will operate in.

Other arguments are optional, and will be determined automatically if
not specified:

    fitness - assign it a fitness score, default is 0.
    id - assign it an id, default is to call new_popid() (see below).
    host - the hostname, default is $ENV{HOST}.

=cut

sub new {
    my $self = bless({}, shift);
    my %args = @_;
    my $usage = 'Usage: AI::Evolve::Befunge::Blueprint->new(code => "whatever", dimensions => 4, [, id => 2, host => "localhost", fitness => 5]);\n';
    croak $usage unless exists $args{code};
    croak $usage unless exists $args{dimensions};
    $$self{code}      = $args{code};
    $$self{dims}      = $args{dimensions};
    if($$self{dims} > 1) {
        $$self{size}      = int((length($$self{code})+1)**(1/$$self{dims}));
    } else {
        $$self{size} = length($$self{code});
    }
    croak("code has a non-orthogonal size!")
        unless ($$self{size}**$$self{dims}) == length($$self{code});
    $$self{size}      = Language::Befunge::Vector->new(map { $$self{size} } (1..$$self{dims}));
    $$self{fitness}   = $args{fitness} // 0;
    $$self{id}        = $args{id}          if exists $args{id};
    $$self{host}      = $args{host}        if exists $args{host};
    $$self{id}        = $self->new_popid() unless defined $$self{id};
    $$self{host}      = $ENV{HOST}         unless defined $$self{host};
    $$self{name}      = "$$self{host}-$$self{id}";
    return $self;
}


=head2 new_from_string

    my $blueprint = Blueprint->new_from_string($string);

Parses a text representation of a blueprint, returns a Blueprint
object.  The text representation was likely created by L</as_string>,
below.

=cut

sub new_from_string {
    my ($package, $line) = @_;
    return undef unless defined $line;
    chomp $line;
    if($line =~ /^\[I(-?\d+) D(\d+) F(\d+) H([^\]]+)\](.+)/) {
        my ($id, $dimensions, $fitness, $host, $code) = ($1, $2, $3, $4, $5);
        return AI::Evolve::Befunge::Blueprint->new(
            id         => $id,
            dimensions => $dimensions,
            fitness    => $fitness,
            host       => $host,
            code       => $code,
        );
    }
    return undef;
}


=head2 new_from_file

    my $blueprint = Blueprint->new_from_file($file);

Reads a text representation (single line of text) of a blueprint from
a results file (or a migration file), returns a Blueprint object.
Calls L</new_from_string> to do the dirty work.

=cut

sub new_from_file {
    my ($package, $file) = @_;
    return $package->new_from_string($file->getline);
}


=head2 as_string

    print $blueprint->as_string();

Return a text representation of this blueprint.  This is suitable for
sticking into a results file, or migrating to another node.  See
L</new_from_string> above.

=cut

sub as_string {
    my $self = shift;
    my $rv =
        "[I$$self{id} D$$self{dims} F$$self{fitness} H$$self{host}]";
    $rv .= $$self{code};
    $rv .= "\n";
    return $rv;
}


=head1 STANDALONE FUNCTIONS

These functions are exported by default.

=cut

{
    my $_popid;

=head2 new_popid

    my $id = new_popid();

Return a unique identifier.

=cut

    sub new_popid :Export(:DEFAULT) {
        $_popid = 0 unless defined $_popid;
        return $_popid++;
    }


=head2 set_popid

    set_popid($id);

Initialize the iterator to the given value.  This is typically done
when a new process reads a results file, to keep node identifiers
unique across runs.

=cut

    sub set_popid :Export(:DEFAULT) {
        $_popid = shift;
    }
}

new_popid();


=head1 AUTHOR

    Mark Glines <mark-cpan@glines.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 Mark Glines.

It is distributed under the terms of the Artistic License 2.0.  For details,
see the "LICENSE" file packaged alongside this module.

=cut


1;
