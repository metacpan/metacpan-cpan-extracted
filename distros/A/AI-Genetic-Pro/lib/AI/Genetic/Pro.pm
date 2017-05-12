package AI::Genetic::Pro;

use vars qw($VERSION);

$VERSION = 0.401;
#---------------

use warnings;
use strict;
use lib qw(../lib/perl);
use Carp;
use Clone qw(clone);
use Struct::Compare;
use Digest::MD5 qw(md5_hex);
use List::Util qw(sum);
use List::MoreUtils qw(minmax first_index apply);
#use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use UNIVERSAL::require;
use AI::Genetic::Pro::Array::Type qw(get_package_by_element_size);
use AI::Genetic::Pro::Chromosome;
use base qw(Class::Accessor::Fast::XS);
#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors(qw(
	type
	population
	terminate
	chromosomes 
	crossover 
	parents 		_parents 
	history 		_history
	fitness 		_fitness 		_fitness_real
	cache
	mutation 		_mutator
	strategy 		_strategist
	selection 		_selector 
	_translations
	generation
	preserve		
	variable_length
	_fix_range
	_package
	strict			_strict
));
#=======================================================================
# Additional modules
use constant STORABLE	=> 'Storable';
use constant GD 		=> 'GD::Graph::linespoints'; 
#=======================================================================
my $_Cache = { };
my $_temp_chromosome;
#=======================================================================
sub new {
	my $class = shift;
	
	my %opts = map { if(ref $_){$_}else{ /^-?(.*)$/o; $1 }} @_;
	my $self = bless \%opts, $class;
	
	croak(q/Type of chromosomes cannot be "combination" if "variable length" feature is active!/)
		if $self->type eq q/combination/ and $self->variable_length;
	croak(q/You must specify a crossover strategy with -strategy!/)
		unless defined ($self->strategy);
	croak(q/Type of chromosomes cannot be "combination" if strategy is not one of: OX, PMX!/)
		if $self->type eq q/combination/ and ($self->strategy->[0] ne q/OX/ and $self->strategy->[0] ne q/PMX/);
	croak(q/Strategy cannot be "/,$self->strategy->[0],q/" if "variable length" feature is active!/ )
		if ($self->strategy->[0] eq 'PMX' or $self->strategy->[0] eq 'OX') and $self->variable_length;
	
	$self->_set_strict if $self->strict;
	
	return $self;
}
#=======================================================================
sub _Cache { $_Cache; }
#=======================================================================
# INIT #################################################################
#=======================================================================
sub _set_strict {
	my ($self) = @_;
	
	# fitness
	my $fitness = $self->fitness();
	my $replacement = sub {
		my @tmp = @{$_[1]};
		my $ret = $fitness->(@_);
		my @cmp = @{$_[1]};
		die qq/Chromosome was modified in a fitness function from "@tmp" to "@{$_[1]}"!\n/ unless compare(\@tmp, \@cmp);
		return $ret;
	};
	$self->fitness($replacement);
}
#=======================================================================
sub _fitness_cached {
	my ($self, $chromosome) = @_;
	my $key = md5_hex(${tied(@$chromosome)});
	return $_Cache->{$key} if exists $_Cache->{$key};
	$_Cache->{$key} = $self->_fitness_real->($self, $chromosome);
	return $_Cache->{$key};
}
#=======================================================================
sub _init_cache {
	my ($self) = @_;
		
	$self->_fitness_real($self->fitness);
	$self->fitness(\&_fitness_cached);
	return;
}
#=======================================================================
sub _check_data_ref {
	my ($self, $data_org) = @_;
	my $data = clone($data_org);
	my $ars;
	for(0..$#$data){
		next if $ars->{$data->[$_]};
		$ars->{$data->[$_]} = 1;
		unshift @{$data->[$_]}, undef;
	}
	return $data;
}
#=======================================================================
# we have to find C to (in some cases) incrase value of range
# due to design model
sub _find_fix_range {
	my ($self, $data) = @_;

	for my $idx (0..$#$data){
		if($data->[$idx]->[1] < 1){ 
			my $const = 1 - $data->[$idx]->[1];
			push @{$self->_fix_range}, $const; 
			$data->[$idx]->[1] += $const;
			$data->[$idx]->[2] += $const;
		}else{ push @{$self->_fix_range}, 0; }
	}

	return $data;
}
#=======================================================================
sub init { 
	my ($self, $data) = @_;
	
	croak q/You have to pass some data to "init"!/ unless $data;
	#-------------------------------------------------------------------
	$self->generation(0);
	$self->_fitness( { } );
	$self->_fix_range( [ ] );
	$self->_history( [  [ ], [ ], [ ] ] );
	$self->_init_cache if $self->cache;
	#-------------------------------------------------------------------
	
	if($self->type eq q/listvector/){
		croak(q/You have to pass array reference if "type" is set to "listvector"/) unless ref $data eq 'ARRAY';
		$self->_translations( $self->_check_data_ref($data) );
	}elsif($self->type eq q/bitvector/){
		croak(q/You have to pass integer if "type" is set to "bitvector"/) if $data !~ /^\d+$/o;
		$self->_translations( [ [ 0, 1 ] ] );
		$self->_translations->[$_] = $self->_translations->[0] for 1..$data-1;
	}elsif($self->type eq q/combination/){
		croak(q/You have to pass array reference if "type" is set to "combination"/) unless ref $data eq 'ARRAY';
		$self->_translations( [ clone($data) ] );
		$self->_translations->[$_] = $self->_translations->[0] for 1..$#$data;
	}elsif($self->type eq q/rangevector/){
		croak(q/You have to pass array reference if "type" is set to "rangevector"/) unless ref $data eq 'ARRAY';
		$self->_translations( $self->_find_fix_range( $self->_check_data_ref($data) ));
	}else{
		croak(q/You have to specify first "type" of vector!/);
	}
	
	my $size = 0;

	if($self->type ne q/rangevector/){ for(@{$self->_translations}){ $size = $#$_ if $#$_ > $size; } }
#	else{ for(@{$self->_translations}){ $size = $_->[1] if $_->[1] > $size; } }
	else{ for(@{$self->_translations}){ $size = $_->[2] if $_->[2] > $size; } }		# Provisional patch for rangevector values truncated to signed  8-bit quantities. Thx to Tod Hagan

	my $package = get_package_by_element_size($size);
	$self->_package($package);

	my $length = ref $data ? sub { $#$data; } : sub { $data - 1 };
	if($self->variable_length){
		$length = ref $data ? sub { 1 + int(rand($#$data)); } : sub { 1 + int(rand($data - 1)); };
	}

	$self->chromosomes( [ ] );
	push @{$self->chromosomes}, 
		AI::Genetic::Pro::Chromosome->new($self->_translations, $self->type, $package, $length->())
			for 1..$self->population;
	
	$self->_calculate_fitness_all();
}
#=======================================================================
# SAVE / LOAD ##########################################################
#=======================================================================
sub save { 
	STORABLE->use(qw(store retrieve)) or croak(q/You need "/.STORABLE.q/" module to save a state of "/.__PACKAGE__.q/"!/);
	$Storable::Deparse = 1;
	$Storable::Eval = 1;
	
	my ($self, $file) = @_;
	croak(q/You have to specify file!/) unless defined $file;

	my $clone = { 
		vector_type	=> ref(tied(@{$self->chromosomes->[0]})),
		chromosomes => [ map { my @genes = @$_; \@genes; } @{$self->chromosomes} ],
		_selector	=> undef,
		_strategist	=> undef,
		_mutator	=> undef,
	};
	
	foreach my $key(keys %$self){
		next if exists $clone->{$key};
		$clone->{$key} = $self->{$key};
	}
	
	store($clone, $file);
}
#=======================================================================
sub load { 
	STORABLE->use(qw(store retrieve)) or croak(q/You need "/.STORABLE.q/" module to load a state of "/.__PACKAGE__.q/"!/);	
	$Storable::Deparse = 1;
	$Storable::Eval = 1;
	
	my ($self, $file) = @_;
	croak(q/You have to specify file!/) unless defined $file;

	my $clone = retrieve($file);
	return carp('Incorrect file!') unless $clone;
	
	$clone->{chromosomes} = [ 
		map {
    		tie my (@genes), $clone->{vector_type};
    			@genes = @$_;
    			\@genes;
    		} @{$clone->{chromosomes}}
    ];
    
    delete $clone->{vector_type};
    
    %$self = %$clone;
    
    return 1;
}
#=======================================================================
# CHARTS ###############################################################
#=======================================================================
sub chart { 
	GD->require or croak(q/You need "/.GD.q/" module to draw chart of evolution!/);	
	my ($self, %params) = (shift, @_);

	my $graph = GD()->new(($params{-width} || 640), ($params{-height} || 480));

	my $data = $self->getHistory;

	if(defined $params{-font}){
    	$graph->set_title_font  ($params{-font}, 12);
    	$graph->set_x_label_font($params{-font}, 10);
    	$graph->set_y_label_font($params{-font}, 10);
    	$graph->set_legend_font ($params{-font},  8);
	}
	
    $graph->set_legend(
    	$params{legend1} || q/Max value/,
    	$params{legend2} || q/Mean value/,
    	$params{legend3} || q/Min value/,
    );

    $graph->set(
        x_label_skip        => int(($data->[0]->[-1]*4)/100),
        x_labels_vertical   => 1,
        x_label_position    => .5,
        y_label_position    => .5,
        y_long_ticks        => 1,   # poziome linie
        x_ticks             => 1,   # poziome linie

        l_margin            => 10,
        b_margin            => 10,
        r_margin            => 10,
        t_margin            => 10,

        show_values         => (defined $params{-show_values} ? 1 : 0),
        values_vertical     => 1,
        values_format       => ($params{-format} || '%.2f'),

        zero_axis           => 1,
        #interlaced          => 1,
        logo_position       => 'BR',
        legend_placement    => 'RT',

        bgclr               => 'white',
        boxclr              => '#FFFFAA',
        transparent         => 0,

        title       		=> ($params{'-title'}   || q/Evolution/ ),
        x_label     		=> ($params{'-x_label'} || q/Generation/),
        y_label     		=> ($params{'-y_label'} || q/Value/     ),
        
        ( $params{-logo} && -f $params{-logo} ? ( logo => $params{-logo} ) : ( ) )
    );
	
	
    my $gd = $graph->plot( [ [ 0..$#{$data->[0]} ], @$data ] ) or croak($@);
    open(my $fh, '>', $params{-filename}) or croak($@);
    binmode $fh;
    print $fh $gd->png;
    close $fh;
    
    return 1;
}
#=======================================================================
# TRANSLATIONS #########################################################
#=======================================================================
sub as_array_def_only {
	my ($self, $chromosome) = @_;
	
	return $self->as_array($chromosome) 
		if not $self->variable_length or $self->variable_length < 2;
	
	if( $self->type eq q/bitvector/ ){
		return $self->as_array($chromosome);
	}else{
		my $ar = $self->as_array($chromosome);
		my $idx = first_index { $_ } @$ar;
		my @array = @$ar[$idx..$#$chromosome];
		return @array if wantarray;
		return \@array;
	}
}
#=======================================================================
sub as_array {
	my ($self, $chromosome) = @_;
	
	if($self->type eq q/bitvector/){
		return @$chromosome if wantarray;
		return $chromosome;
	}elsif($self->type eq q/rangevector/){
		my $fix_range = $self->_fix_range;
		my $c = -1;
		#my @array = map { $c++; warn "WARN: $c | ",scalar @$chromosome,"\n" if not defined $fix_range->[$c]; $_ ? $_ - $fix_range->[$c] : undef } @$chromosome;
		my @array = map { $c++; $_ ? $_ - $fix_range->[$c] : undef } @$chromosome;
		
		return @array if wantarray;
		return \@array;
	}else{
		my $cnt = 0;
		my @array = map { $self->_translations->[$cnt++]->[$_] } @$chromosome;
		return @array if wantarray;
		return \@array;
	}
}
#=======================================================================
sub as_string_def_only {	
	my ($self, $chromosome) = @_;
	
	return $self->as_string($chromosome) 
		if not $self->variable_length or $self->variable_length < 2;

	my $array = $self->as_array_def_only($chromosome);
	
	return join(q//, @$array) if $self->type eq q/bitvector/;
	return join(q/___/, @$array);
}
#=======================================================================
sub as_string {	
	return join(q//, @{$_[1]}) if $_[0]->type eq q/bitvector/;
	return 	join(q/___/, map { defined $_ ? $_ : q/ / } $_[0]->as_array($_[1]));
}
#=======================================================================
sub as_value { 
	my ($self, $chromosome) = @_;
	croak(q/You MUST call 'as_value' as method of 'AI::Genetic::Pro' object./)
		unless defined $_[0] and ref $_[0] and ref $_[0] eq 'AI::Genetic::Pro';
	croak(q/You MUST pass 'AI::Genetic::Pro::Chromosome' object to 'as_value' method./) 
		unless defined $_[1] and ref $_[1] and ref $_[1] eq 'AI::Genetic::Pro::Chromosome';
	return $self->fitness->($self, $chromosome);  
}
#=======================================================================
# ALGORITHM ############################################################
#=======================================================================
sub _calculate_fitness_all {
	my ($self) = @_;
	
	$self->_fitness( { } );
	$self->_fitness->{$_} = $self->fitness()->($self, $self->chromosomes->[$_]) 
		for 0..$#{$self->chromosomes};

# sorting the population is not necessary	
#	my (@chromosomes, %fitness);
#	for my $idx (sort { $self->_fitness->{$a} <=> $self->_fitness->{$b} } keys %{$self->_fitness}){
#		push @chromosomes, $self->chromosomes->[$idx];
#		$fitness{$#chromosomes} = $self->_fitness->{$idx};
#		delete $self->_fitness->{$idx};
#		delete $self->chromosomes->[$idx];
#	}
#	
#	$self->_fitness(\%fitness);
#	$self->chromosomes(\@chromosomes);

	return;
}
#=======================================================================
sub _select_parents {
	my ($self) = @_;
	unless($self->_selector){
		croak "You must specify a selection strategy!"
			unless defined $self->selection;
		my @tmp = @{$self->selection};
		my $selector = q/AI::Genetic::Pro::Selection::/ . shift @tmp;
		$selector->require;
		$self->_selector($selector->new(@tmp));
	}
	
	$self->_parents($self->_selector->run($self));
	
	return;
}
#=======================================================================
sub _crossover {
	my ($self) = @_;
	
	unless($self->_strategist){
		my @tmp = @{$self->strategy};
		my $strategist = q/AI::Genetic::Pro::Crossover::/ . shift @tmp;
		$strategist->require;
		$self->_strategist($strategist->new(@tmp));
	}

	my $a = $self->_strategist->run($self);
	$self->chromosomes( $a );
	
	return;
}
#=======================================================================
sub _mutation {
	my ($self) = @_;
	
	unless($self->_mutator){
		my $mutator = q/AI::Genetic::Pro::Mutation::/ . ucfirst(lc($self->type));
		unless($mutator->require){
			$mutator = q/AI::Genetic::Pro::Mutation::Listvector/;
			$mutator->require;
		}
		$self->_mutator($mutator->new);
	}
	
	return $self->_mutator->run($self);
}
#=======================================================================
sub _save_history {
	my @tmp;
	if($_[0]->history){ @tmp = $_[0]->getAvgFitness; }
	else { @tmp = (undef, undef, undef); }
	
	push @{$_[0]->_history->[0]}, $tmp[0]; 
	push @{$_[0]->_history->[1]}, $tmp[1];
	push @{$_[0]->_history->[2]}, $tmp[2];
	return 1;
}
#=======================================================================
sub inject {
	my ($self, $candidates) = @_;
	
	for(@$candidates){
		push @{$self->chromosomes}, 
			AI::Genetic::Pro::Chromosome->new_from_data($self->_translations, $self->type, $self->_package, $_, $self->_fix_range);
		$self->_fitness->{$#{$self->chromosomes}} = $self->fitness()->($self, $self->chromosomes->[-1]);

	}			
	$self->_strict( [ ] );

	return 1;
}
#=======================================================================
sub evolve {
	my ($self, $generations) = @_;

	# generations must be defined
	$generations ||= -1; 	 
	
	if($self->strict and $self->_strict){
		for my $idx (0..$#{$self->chromosomes}){
			croak(q/Chromosomes was modified outside the 'evolve' function!/) unless $self->chromosomes->[$idx] and $self->_strict->[$idx];
			my @tmp0 = @{$self->chromosomes->[$idx]};
			my @tmp1 = @{$self->_strict->[$idx]};
			croak(qq/Chromosome was modified outside the 'evolve' function from "@tmp0" to "@tmp1"!/) unless compare(\@tmp0, \@tmp1);
		}
	}
	
	# split into two loops just for speed
	unless($self->preserve){
		for(my $i = 0; $i != $generations; $i++){
			# terminate ----------------------------------------------------
			last if $self->terminate and $self->terminate->($self);
			# update generation --------------------------------------------
			$self->generation($self->generation + 1);
			# update history -----------------------------------------------
			$self->_save_history;
			# selection ----------------------------------------------------
			$self->_select_parents();
			# crossover ----------------------------------------------------
			$self->_crossover();
			# mutation -----------------------------------------------------
			$self->_mutation();
		}
	}else{
		croak('You cannot preserve more chromosomes than is in population!') if $self->preserve > $self->population;
		my @preserved;
		for(my $i = 0; $i != $generations; $i++){
			# terminate ----------------------------------------------------
			last if $self->terminate and $self->terminate->($self);
			# update generation --------------------------------------------
			$self->generation($self->generation + 1);
			# update history -----------------------------------------------
			$self->_save_history;
			#---------------------------------------------------------------
			# preservation of N unique chromosomes
			@preserved = map { clone($_) } @{ $self->getFittest_as_arrayref($self->preserve - 1, 1) };
			# selection ----------------------------------------------------
			$self->_select_parents();
			# crossover ----------------------------------------------------
			$self->_crossover();
			# mutation -----------------------------------------------------
			$self->_mutation();
			#---------------------------------------------------------------
			for(@preserved){
				my $idx = int rand @{$self->chromosomes};
				$self->chromosomes->[$idx] = $_;
				$self->_fitness->{$idx} = $self->fitness()->($self, $_);
			}
		}
	}
	
	if($self->strict){
		$self->_strict( [ ] );
		push @{$self->_strict}, clone($_) for @{$self->chromosomes};
	}
}
#=======================================================================
# ALIASES ##############################################################
#=======================================================================
sub people { $_[0]->chromosomes() }
#=======================================================================
sub getHistory { $_[0]->_history()  }
#=======================================================================
sub mutProb { shift->mutation(@_) }
#=======================================================================
sub crossProb { shift->crossover(@_) }
#=======================================================================
sub intType { shift->type() }
#=======================================================================
# STATS ################################################################
#=======================================================================
sub getFittest_as_arrayref { 
	my ($self, $n, $uniq) = @_;
	$n ||= 1;
	
	$self->_calculate_fitness_all() unless scalar %{ $self->_fitness };
	my @keys = sort { $self->_fitness->{$a} <=> $self->_fitness->{$b} } 0..$#{$self->chromosomes};
	
	if($uniq){
		my %grep;
		my $chromosomes = $self->chromosomes;
		@keys = grep { 
				my $add_to_list = 0;
				my $key = md5_hex(${tied(@{$chromosomes->[$_]})});
				unless($grep{$key}) { 
					$grep{$key} = 1; 
					$add_to_list = 1;
				}
				$add_to_list;
			} @keys;
	}
	
	$n = scalar @keys if $n > scalar @keys;
	return [ reverse @{$self->chromosomes}[ splice @keys, $#keys - $n + 1, $n ] ];
}
#=======================================================================
sub getFittest { return wantarray ? @{ shift->getFittest_as_arrayref(@_) } : shift @{ shift->getFittest_as_arrayref(@_) }; }
#=======================================================================
sub getAvgFitness {
	my ($self) = @_;
	
	my @minmax = minmax values %{$self->_fitness};
	my $mean = sum(values %{$self->_fitness}) / scalar values %{$self->_fitness};
	return $minmax[1], int($mean), $minmax[0];
}
#=======================================================================
1;


__END__

=head1 NAME

AI::Genetic::Pro - Efficient genetic algorithms for professional purpose.

=head1 SYNOPSIS

    use AI::Genetic::Pro;
    
    sub fitness {
        my ($ga, $chromosome) = @_;
        return oct('0b' . $ga->as_string($chromosome)); 
    }
    
    sub terminate {
        my ($ga) = @_;
        my $result = oct('0b' . $ga->as_string($ga->getFittest));
        return $result == 4294967295 ? 1 : 0;
    }
    
    my $ga = AI::Genetic::Pro->new(        
        -fitness         => \&fitness,        # fitness function
        -terminate       => \&terminate,      # terminate function
        -type            => 'bitvector',      # type of chromosomes
        -population      => 1000,             # population
        -crossover       => 0.9,              # probab. of crossover
        -mutation        => 0.01,             # probab. of mutation
        -parents         => 2,                # number  of parents
        -selection       => [ 'Roulette' ],   # selection strategy
        -strategy        => [ 'Points', 2 ],  # crossover strategy
        -cache           => 0,                # cache results
        -history         => 1,                # remember best results
        -preserve        => 3,                # remember the bests
        -variable_length => 1,                # turn variable length ON
    );
	
    # init population of 32-bit vectors
    $ga->init(32);
	
    # evolve 10 generations
    $ga->evolve(10);
    
    # best score
    print "SCORE: ", $ga->as_value($ga->getFittest), ".\n";
    
    # save evolution path as a chart
    $ga->chart(-filename => 'evolution.png');
     
    # save state of GA
    $ga->save('genetic.sga');
    
    # load state of GA
    $ga->load('genetic.sga');

=head1 DESCRIPTION

This module provides efficient implementation of a genetic algorithm for
professional use. It was designed to operate as fast as possible
even on very large populations and big individuals/chromosomes. C<AI::Genetic::Pro> 
was inspired by C<AI::Genetic>, so it is in most cases compatible 
(there are some changes). Additionally C<AI::Genetic::Pro> isn't a pure Perl solution, so it 
B<doesn't have> limitations of its ancestor (such as serious slow-down in the
case of big populations ( >10000 ) or vectors with more than 33 fields).

If You are looking for a pure Perl solution, consider L<AI::Genetic>.

=over 4

=item Speed

To increase speed XS code is used, however with portability in 
mind. This distribution was tested on Windows and Linux platforms 
(and should work on any other).

=item Memory

This module was designed to use as little memory as possible. A population
of size 10000 consisting of 92-bit vectors uses only ~24MB (C<AI::Genetic> 
would use about 78MB!).

=item Advanced options

To provide more flexibility C<AI::Genetic::Pro> supports many 
statistical distributions, such as C<uniform>, C<natural>, C<chi_square>
and others. This feature can be used in selection and/or crossover. See
the documentation below.

=back

=head1 METHODS

=over 4

=item I<$ga>-E<gt>B<new>( %options )

Constructor. It accepts options in hash-value style. See options and 
an example below.

=over 8

=item -fitness

This defines a I<fitness> function. It expects a reference to a subroutine.

=item -terminate 

This defines a I<terminate> function. It expects a reference to a subroutine.

=item -type

This defines the type of chromosomes. Currently, C<AI::Genetic::Pro> supports four types:

=over 12

=item bitvector

Individuals/chromosomes of this type have genes that are bits. Each gene can be in one of two possible states, on or off.

=item listvector

Each gene of a "listvector" individual/chromosome can assume one string value from a specified list of possible string values.

=item rangevector

Each gene of a "rangevector" individual/chromosome can assume one integer 
value from a range of possible integer values. Note that only integers 
are supported. The user can always transform any desired fractional values 
by multiplying and dividing by an appropriate power of 10.

=item combination

Each gene of a "combination" individual/chromosome can assume one string value from a specified list of possible string values. B<All genes are unique.>

=back

=item -population

This defines the size of the population, i.e. how many chromosomes
simultaneously exist at each generation.

=item -crossover 

This defines the crossover rate. The fairest results are achieved with
crossover rate ~0.95.

=item -mutation 

This defines the mutation rate. The fairest results are achieved with mutation
rate ~0.01.

=item -preserve

This defines injection of the bests chromosomes into a next generation. It causes a little slow down, however (very often) much better results are achieved. You can specify, how many chromosomes will be preserved, i.e.

    -preserve => 1, # only one chromosome will be preserved
    # or
    -preserve => 9, # 9 chromosomes will be preserved
    # and so on...

Attention! You cannot preserve more chromosomes than exist in your population.

=item -variable_length

This defines whether variable-length chromosomes are turned on (default off)
and a which types of mutation are allowed. See below.

=over 8

=item level 0

Feature is inactive (default). Example:

	-variable_length => 0
	
    # chromosomes (i.e. bitvectors)
    0 1 0 0 1 1 0 1 1 1 0 1 0 1
    0 0 1 1 0 1 1 1 1 0 0 1 1 0
    0 1 1 1 0 1 0 0 1 1 0 1 1 1
    0 1 0 0 1 1 0 1 1 1 1 0 1 0
    # ...and so on

=item level 1 

Feature is active, but chromosomes can varies B<only on the right side>, Example:

	-variable_length => 1
	
    # chromosomes (i.e. bitvectors)
    0 1 0 0 1 1 0 1 1 1 
    0 0 1 1 0 1 1 1 1
    0 1 1 1 0 1 0 0 1 1 0 1 1 1
    0 1 0 0 1 1 0 1 1 1
    # ...and so on
	
=item level 2 

Feature is active and chromosomes can varies B<on the left side and on 
the right side>; unwanted values/genes on the left side are replaced with C<undef>, ie.
 
	-variable_length => 2
 
    # chromosomes (i.e. bitvectors)
    x x x 0 1 1 0 1 1 1 
    x x x x 0 1 1 1 1
    x 1 1 1 0 1 0 0 1 1 0 1 1 1
    0 1 0 0 1 1 0 1 1 1
    # where 'x' means 'undef'
    # ...and so on

In this situation returned chromosomes in an array context ($ga-E<gt>as_array($chromosome)) 
can have B<undef> values on the left side (only). In a scalar context each 
undefined value is replaced with a single space. If You don't want to see
any C<undef> or space, just use C<as_array_def_only> and C<as_string_def_only> 
instead of C<as_array> and C<as_string>.

=back

=item -parents  

This defines how many parents should be used in a crossover.

=item -selection

This defines how individuals/chromosomes are selected to crossover. It expects an array reference listed below:

    -selection => [ $type, @params ]

where type is one of:

=over 8

=item B<RouletteBasic>

Each individual/chromosome can be selected with probability proportional to its fitness.

=item B<Roulette>

First the best individuals/chromosomes are selected. From this collection
parents are selected with probability poportional to their fitness.

=item B<RouletteDistribution>

Each individual/chromosome has a portion of roulette wheel proportional to its
fitness. Selection is done with the specified distribution. Supported
distributions and parameters are listed below.

=over 12

=item C<-selection =E<gt> [ 'RouletteDistribution', 'uniform' ]>

Standard uniform distribution. No additional parameters are needed.

=item C<-selection =E<gt> [ 'RouletteDistribution', 'normal', $av, $sd ]>

Normal distribution, where C<$av> is average (default: size of population /2) and $C<$sd> is standard deviation (default: size of population).


=item C<-selection =E<gt> [ 'RouletteDistribution', 'beta', $aa, $bb ]>

I<Beta> distribution.  The density of the beta is:

    X^($aa - 1) * (1 - X)^($bb - 1) / B($aa , $bb) for 0 < X < 1.

C<$aa> and C<$bb> are set by default to number of parents.

B<Argument restrictions:> Both $aa and $bb must not be less than 1.0E-37.

=item C<-selection =E<gt> [ 'RouletteDistribution', 'binomial' ]>

Binomial distribution. No additional parameters are needed.

=item C<-selection =E<gt> [ 'RouletteDistribution', 'chi_square', $df ]>

Chi-square distribution with C<$df> degrees of freedom. C<$df> by default is set to size of population.

=item C<-selection =E<gt> [ 'RouletteDistribution', 'exponential', $av ]>

Exponential distribution, where C<$av> is average . C<$av> by default is set to size of population.

=item C<-selection =E<gt> [ 'RouletteDistribution', 'poisson', $mu ]>

Poisson distribution, where C<$mu> is mean. C<$mu> by default is set to size of population.

=back

=item B<Distribution>

Chromosomes/individuals are selected with specified distribution. See below.

=over 12

=item C<-selection =E<gt> [ 'Distribution', 'uniform' ]>

Standard uniform distribution. No additional parameters are needed.

=item C<-selection =E<gt> [ 'Distribution', 'normal', $av, $sd ]>

Normal distribution, where C<$av> is average (default: size of population /2) and $C<$sd> is standard deviation (default: size of population).

=item C<-selection =E<gt> [ 'Distribution', 'beta', $aa, $bb ]>

I<Beta> distribution.  The density of the beta is:

    X^($aa - 1) * (1 - X)^($bb - 1) / B($aa , $bb) for 0 < X < 1.

C<$aa> and C<$bb> are set by default to number of parents.

B<Argument restrictions:> Both $aa and $bb must not be less than 1.0E-37.

=item C<-selection =E<gt> [ 'Distribution', 'binomial' ]>

Binomial distribution. No additional parameters are needed.

=item C<-selection =E<gt> [ 'Distribution', 'chi_square', $df ]>

Chi-square distribution with C<$df> degrees of freedom. C<$df> by default is set to size of population.

=item C<-selection =E<gt> [ 'Distribution', 'exponential', $av ]>

Exponential distribution, where C<$av> is average . C<$av> by default is set to size of population.

=item C<-selection =E<gt> [ 'Distribution', 'poisson', $mu ]>

Poisson distribution, where C<$mu> is mean. C<$mu> by default is set to size of population.

=back

=back

=item -strategy 

This defines the astrategy of crossover operation. It expects an array
reference listed below:

    -strategy => [ $type, @params ]

where type is one of:

=over 4

=item PointsSimple

Simple crossover in one or many points. The best chromosomes/individuals are
selected for the new generation. For example:

    -strategy => [ 'PointsSimple', $n ]

where C<$n> is the number of points for crossing.

=item PointsBasic

Crossover in one or many points. In basic crossover selected parents are
crossed and one (randomly-chosen) child is moved to the new generation. For
example:

    -strategy => [ 'PointsBasic', $n ]

where C<$n> is the number of points for crossing.

=item Points

Crossover in one or many points. In normal crossover selected parents are crossed and the best child is moved to the new generation. For example:

    -strategy => [ 'Points', $n ]

where C<$n> is number of points for crossing.

=item PointsAdvenced

Crossover in one or many points. After crossover the best
chromosomes/individuals from all parents and chidren are selected for the  new
generation. For example:

    -strategy => [ 'PointsAdvanced', $n ]

where C<$n> is the number of points for crossing.

=item Distribution

In I<distribution> crossover parents are crossed in points selected with the
specified distribution. See below.

=over 8

=item C<-strategy =E<gt> [ 'Distribution', 'uniform' ]>

Standard uniform distribution. No additional parameters are needed.

=item C<-strategy =E<gt> [ 'Distribution', 'normal', $av, $sd ]>

Normal distribution, where C<$av> is average (default: number of parents/2) and C<$sd> is standard deviation (default: number of parents).

=item C<-strategy =E<gt> [ 'Distribution', 'beta', $aa, $bb ]>

I<Beta> distribution.  The density of the beta is:

    X^($aa - 1) * (1 - X)^($bb - 1) / B($aa , $bb) for 0 < X < 1.

C<$aa> and C<$bb> are set by default to the number of parents.

B<Argument restrictions:> Both $aa and $bb must not be less than 1.0E-37.

=item C<-strategy =E<gt> [ 'Distribution', 'binomial' ]>

Binomial distribution. No additional parameters are needed.

=item C<-strategy =E<gt> [ 'Distribution', 'chi_square', $df ]>

Chi-squared distribution with C<$df> degrees of freedom. C<$df> by default is set to the number of parents.

=item C<-strategy =E<gt> [ 'Distribution', 'exponential', $av ]>

Exponential distribution, where C<$av> is average . C<$av> by default is set to the number of parents.

=item C<-strategy =E<gt> [ 'Distribution', 'poisson', $mu ]>

Poisson distribution, where C<$mu> is mean. C<$mu> by default is set to the number of parents.

=back

=item PMX

PMX method defined by Goldberg and Lingle in 1985. Parameters: I<none>.

=item OX

OX method defined by Davis (?) in 1985. Parameters: I<none>.

=back

=item -cache    

This defines whether a cache should be used. Allowed values are 1 or 0
(default: I<0>).

=item -history 

This defines whether history should be collected. Allowed values are 1 or 0 (default: I<0>).

=item -strict

This defines if the check for modifying chromosomes in a user-defined fitness
function is active. Directly modifying chromosomes is not allowed and it is 
a highway to big trouble. This mode should be used only for testing, because it is B<slow>.

=back

=item I<$ga>-E<gt>B<inject>($chromosomes)

Inject new, user defined, chromosomes into the current population. See example below:

    # example for bitvector
    my $chromosomes = [
        [ 1, 1, 0, 1, 0, 1 ],
        [ 0, 0, 0, 1, 0, 1 ],
        [ 0, 1, 0, 1, 0, 0 ],
        ...
    ];
    
    # inject
    $ga->inject($chromosomes);

If You want to delete some chromosomes from population, just C<splice> them:

    my @remove = qw(1 2 3 9 12);
	for my $idx (sort { $b <=> $a }  @remove){
        splice @{$ga->chromosomes}, $idx, 1;
    }

=item I<$ga>-E<gt>B<population>($population)

Set/get size of the population. This defines the size of the population, i.e. how many chromosomes to simultaneously exist at each generation.

=item I<$ga>-E<gt>B<indType>()

Get type of individuals/chromosomes. Currently supported types are:

=over 4

=item C<bitvector>

Chromosomes will be just bitvectors. See documentation of C<new> method.

=item C<listvector>

Chromosomes will be lists of specified values. See documentation of C<new> method.

=item C<rangevector>

Chromosomes will be lists of values from specified range. See documentation of C<new> method.

=item C<combination>

Chromosomes will be unique lists of specified values. This is used for example
in the I<Traveling Salesman Problem>. See the documentation of the C<new>
method.

=back

In example:

    my $type = $ga->type();

=item I<$ga>-E<gt>B<type>()

Alias for C<indType>.

=item I<$ga>-E<gt>B<crossProb>()

This method is used to query and set the crossover rate.

=item I<$ga>-E<gt>B<crossover>()

Alias for C<crossProb>.

=item I<$ga>-E<gt>B<mutProb>()

This method is used to query and set the mutation rate.

=item I<$ga>-E<gt>B<mutation>()

Alias for C<mutProb>.

=item I<$ga>-E<gt>B<parents>($parents)

Set/get number of parents in a crossover.

=item I<$ga>-E<gt>B<init>($args)

This method initializes the population with random individuals/chromosomes. It MUST be called before any call to C<evolve()>. It expects one argument, which depends on the type of individuals/chromosomes:

=over 4

=item B<bitvector>

For bitvectors, the argument is simply the length of the bitvector.

    $ga->init(10);

This initializes a population where each individual/chromosome has 10 genes.

=item B<listvector>

For listvectors, the argument is an anonymous list of lists. The number of sub-lists is equal to the number of genes of each individual/chromosome. Each sub-list defines the possible string values that the corresponding gene can assume.

    $ga->init([
               [qw/red blue green/],
               [qw/big medium small/],
               [qw/very_fat fat fit thin very_thin/],
              ]);

This initializes a population where each individual/chromosome has 3 genes and each gene can assume one of the given values.

=item B<rangevector>

For rangevectors, the argument is an anonymous list of lists. The number of sub-lists is equal to the number of genes of each individual/chromosome. Each sub-list defines the minimum and maximum integer values that the corresponding gene can assume.

    $ga->init([
               [1, 5],
               [0, 20],
               [4, 9],
              ]);

This initializes a population where each individual/chromosome has 3 genes and each gene can assume an integer within the corresponding range.

=item B<combination>

For combination, the argument is an anonymous list of possible values of gene.

    $ga->init( [ 'a', 'b', 'c' ] );

This initializes a population where each chromosome has 3 genes and each gene
is a unique combination of 'a', 'b' and 'c'. For example genes looks something
like that:

    [ 'a', 'b', 'c' ]    # gene 1
    [ 'c', 'a', 'b' ]    # gene 2
    [ 'b', 'c', 'a' ]    # gene 3
    # ...and so on...

=back

=item I<$ga>-E<gt>B<evolve>($n)

This method causes the GA to evolve the population for the specified number of
generations. If its argument is 0 or C<undef> GA will evolve the population to
infinity unless a C<terminate> function is specified.

=item I<$ga>-E<gt>B<getHistory>()

Get history of the evolution. It is in a format listed below:

	[
		# gen0   gen1   gen2   ...          # generations
		[ max0,  max1,  max2,  ... ],       # max values
		[ mean,  mean1, mean2, ... ],       # mean values
		[ min0,  min1,  min2,  ... ],       # min values
	]

=item I<$ga>-E<gt>B<getAvgFitness>()

Get I<max>, I<mean> and I<min> score of the current generation. In example:

    my ($max, $mean, $min) = $ga->getAvgFitness();

=item I<$ga>-E<gt>B<getFittest>($n, $unique)

This function returns a list of the fittest chromosomes from the current
population.  You can specify how many chromosomes should be returned and if
the returned chromosomes should be unique. See example below.

    # only one - the best
    my ($best) = $ga->getFittest;

    # or 5 bests chromosomes, NOT unique
    my @bests = $ga->getFittest(5);

    # or 7 bests and UNIQUE chromosomes
    my @bests = $ga->getFittest(7, 1);

If you want to get a large number of chromosomes, try to use the
C<getFittest_as_arrayref> function instead (for efficiency).

=item I<$ga>-E<gt>B<getFittest_as_arrayref>($n, $unique)

This function is very similar to C<getFittest>, but it returns a reference 
to an array instead of a list. 

=item I<$ga>-E<gt>B<generation>()

Get the number of the current generation.

=item I<$ga>-E<gt>B<people>()

Returns an anonymous list of individuals/chromosomes of the current population. 

B<IMPORTANT:> the actual array reference used by the C<AI::Genetic::Pro> 
object is returned, so any changes to it will be reflected in I<$ga>.

=item I<$ga>-E<gt>B<chromosomes>()

Alias for C<people>.

=item I<$ga>-E<gt>B<chart>(%options)

Generate a chart describing changes of min, mean, and max scores in your
population. To satisfy your needs, you can pass the following options:

=over 4

=item -filename

File to save a chart in (B<obligatory>).

=item -title

Title of a chart (default: I<Evolution>).

=item -x_label

X label (default: I<Generations>).

=item -y_label

Y label (default: I<Value>).

=item -format

Format of values, like C<sprintf> (default: I<'%.2f'>).

=item -legend1

Description of min line (default: I<Min value>).

=item -legend2

Description of min line (default: I<Mean value>).

=item -legend3

Description of min line (default: I<Max value>).

=item -width

Width of a chart (default: I<640>).

=item -height

Height of a chart (default: I<480>).

=item -font

Path to font (in *.ttf format) to be used (default: none).

=item -logo

Path to logo (png/jpg image) to embed in a chart (default: none).

=item For example:

	$ga->chart(-width => 480, height => 320, -filename => 'chart.png');

=back

=item I<$ga>-E<gt>B<save>($file)

Save the current state of the genetic algorithm to the specified file.

=item I<$ga>-E<gt>B<load>($file)

Load a state of the genetic algorithm from the specified file. 

=item I<$ga>-E<gt>B<as_array>($chromosome)

In list context return an array representing the specified chromosome. 
In scalar context return an reference to an array representing the specified 
chromosome. If I<variable_length> is turned on and is set to level 2, an array 
can have some C<undef> values. To get only C<not undef> values use 
C<as_array_def_only> instead of C<as_array>.

=item I<$ga>-E<gt>B<as_array_def_only>($chromosome)

In list context return an array representing the specified chromosome. 
In scalar context return an reference to an array representing the specified 
chromosome. If I<variable_length> is turned off, this function is just an
alias for C<as_array>. If I<variable_length> is turned on and is set to 
level 2, this function will return only C<not undef> values from chromosome. 
See example below:

    # -variable_length => 2, -type => 'bitvector'
	
    my @chromosome = $ga->as_array($chromosome)
    # @chromosome looks something like that
    # ( undef, undef, undef, 1, 0, 1, 1, 1, 0 )
	
    @chromosome = $ga->as_array_def_only($chromosome)
    # @chromosome looks something like that
    # ( 1, 0, 1, 1, 1, 0 )

=item I<$ga>-E<gt>B<as_string>($chromosome)

Return a string representation of the specified chromosome. See example below:

	# -type => 'bitvector'
	
	my $string = $ga->as_string($chromosome);
	# $string looks something like that
	# 1___0___1___1___1___0 
	
	# or 
	
	# -type => 'listvector'
	
	$string = $ga->as_string($chromosome);
	# $string looks something like that
	# element0___element1___element2___element3...

Attention! If I<variable_length> is turned on and is set to level 2, it is 
possible to get C<undef> values on the left side of the vector. In the returned
string C<undef> values will be replaced with B<spaces>. If you don't want
to see any I<spaces>, use C<as_string_def_only> instead of C<as_string>.

=item I<$ga>-E<gt>B<as_string_def_only>($chromosome)

Return a string representation of specified chromosome. If I<variable_length> 
is turned off, this function is just alias for C<as_string>. If I<variable_length> 
is turned on and is set to level 2, this function will return a string without
C<undef> values. See example below:

	# -variable_length => 2, -type => 'bitvector'
	
	my $string = $ga->as_string($chromosome);
	# $string looks something like that
	#  ___ ___ ___1___1___0 
	
	$string = $ga->as_string_def_only($chromosome);
	# $string looks something like that
	# 1___1___0 

=item I<$ga>-E<gt>B<as_value>($chromosome)

Return the score of the specified chromosome. The value of I<chromosome> is 
calculated by the fitness function.

=back

=head1 SUPPORT

C<AI::Genetic::Pro> is still under development; however, it is used in many
production environments.

=head1 TODO

=over 4

=item Examples.

=item More tests.

=item More warnings about incorrect parameters.

=back

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.
It may be difficult for me to reproduce the problem as almost every setup
is different.

A small script which yields the problem will probably be of help. 

=head1 THANKS

Miles Gould for suggestions and some fixes (even in this documentation! :-).

Alun Jones for fixing memory leaks.

Tod Hagan for reporting a bug (rangevector values truncated to signed  8-bit quantities) and supplying a patch.

Randal L. Schwartz for reporting a bug in this documentation.

Maciej Misiak for reporting problems with C<combination> (and a bug in a PMX strategy).

LEONID ZAMDBORG for recommending the addition of variable-length chromosomes as well as supplying relevant code samples, for testing and at the end reporting some bugs.

Christoph Meissner for reporting a bug.

Alec Chen for reporting some bugs.

=head1 AUTHOR

Strzelecki Lukasz <lukasz@strzeleccy.eu>

=head1 SEE ALSO

L<AI::Genetic>
L<Algorithm::Evolutionary>

=head1 COPYRIGHT

Copyright (c) Strzelecki Lukasz. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
