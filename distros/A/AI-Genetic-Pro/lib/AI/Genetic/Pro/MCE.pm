package AI::Genetic::Pro::MCE;

use warnings;
use strict;
use base 							qw( AI::Genetic::Pro );
#-----------------------------------------------------------------------
use Clone 							qw( clone   );
use List::Util 						qw( shuffle );
use MCE( Sereal => 0 );
#use MCE::Loop;
use MCE::Map;
use MCE::Util;
#-----------------------------------------------------------------------	
$Storable::Deparse 	= 1;
$Storable::Eval 	= 1;
#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors( qw(
	_pop
	_tpl
));
#=======================================================================
sub new {
	my ( $cls, $obj, $tpl ) = @_;
	
	my $self = bless $obj, $cls;
	
	#-------------------------------------------------------------------
	$self->_init_mce;
	$self->_init_pop;
	
	#-------------------------------------------------------------------
	$AI::Genetic::Pro::Array::Type::Native = 1 if $self->native;
	
	#-------------------------------------------------------------------
	delete $tpl->{ $_ } for qw( -history -mce -population -workers );
	$self->_tpl( $tpl );
	
	#-------------------------------------------------------------------
	return $self;
}
#=======================================================================
sub _init_pop {
	my ( $self ) = @_;
	
	my $pop = int( $self->population / $self->workers );
	my $rst = $self->population % $self->workers;
	
	my @pop = ( $pop ) x $self->workers;
	$pop[ 0 ] += $rst;
	
	$self->_pop( \@pop );
}
#=======================================================================
sub _calculate_fitness_all {
	my ($self) = @_;
	
	my %fit = mce_map {
			$_ => $self->fitness()->( $self, $self->chromosomes->[ $_ ] )
		} 0 .. $#{ $self->chromosomes };
	$self->_fitness( \%fit );
	
	return;
}
#=======================================================================
sub _init_mce {
	my ( $self ) = @_;
	
	#-------------------------------------------------------------------
	$self->workers( MCE::Util::get_ncpu() ) unless $self->workers;
	
	#-------------------------------------------------------------------
	MCE::Map->init(
		chunk_size 	=> q[auto], 
		max_workers => $self->workers,
	);
	
	#-------------------------------------------------------------------
	return;
}
#=======================================================================
sub init {
	my ( $self, $val ) = @_;
	
	#-------------------------------------------------------------------
	my $pop = $self->population;
	$self->population( 1 );
	$self->SUPER::init(  $val  );
	$self->population( $pop );
	
	#-------------------------------------------------------------------
	my $one = shift @{ $self->chromosomes };	
	my $tpl = $self->_tpl;
	
	my @lst = mce_map {
		my $arg = clone( $tpl );
		$arg->{ -population } = $_;
		my $gal = AI::Genetic::Pro->new( %$arg );
		$gal->init( $val );
		@{ $gal->_state };
		
	} @{ $self->_pop };
	
	#-------------------------------------------------------------------
	return $self->_adopt( \@lst );
}
#=======================================================================
sub _adopt {
	my ( $self, $lst ) = @_;
	
	if( my $typ = $self->_package ){
		for my $idx ( 0 .. $#$lst ){
			$lst->[ $idx ]->[ 0 ] = $typ->make_with_packed( $lst->[ $idx ]->[ 0 ] );
			bless $lst->[ $idx ]->[ 0 ], q[AI::Genetic::Pro::Chromosome];
		}
	}
	
	my ( @chr, %fit, @rhc, %tif );
	for my $sth ( @$lst ){
		push @chr, $sth->[ 0 ];
		$fit{ $#chr } = $sth->[ 1 ];
	}
	
	#@$lst = ( );
	
	my @idx = shuffle 0 .. $#chr;
	
	for my $i ( @idx ){
		push @rhc, $chr[ $i ];
		$tif{ $#rhc } = $fit{ $i };
	}
	
	$self->_fitness	  ( \%tif );
	$self->chromosomes( \@rhc );
	
	return;
}
#=======================================================================
sub _chunks {
	my ( $self ) = @_;
	
	my $cnt = 0;
	my @chk;
	
	for my $idx ( 0 .. $#{ $self->_pop } ){
		my $pos = 0;
		my %tmp = map { $pos++ => $self->_fitness->{ $_ } } $cnt .. $cnt + $self->_pop->[ $idx ] -1 ;
		my @tmp = splice @{ $self->chromosomes }, 0, $self->_pop->[ $idx ];
		$cnt += @tmp;
		
		if( $self->_package ){
			push @chk, [
				[ map { ${ tied( @$_ ) } } @tmp ],
				\%tmp,
			];
		}else{
			push @chk, [
				\@tmp,
				\%tmp,
			];
		}
	}
	
	return \@chk;
}
#=======================================================================
sub evolve {
	my ( $self, $generations ) = @_;

	$generations ||= -1; 	 

	for(my $i = 0; $i != $generations; $i++){
		
		# terminate ----------------------------------------------------
		last if $self->terminate and $self->terminate->( $self );
		
		# update generation --------------------------------------------
		$self->generation($self->generation + 1);
		
		# update history -----------------------------------------------
		$self->_save_history;

		my $tpl = $self->_tpl;
		my @lst = mce_map {
			#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			my $ary = $_;
			#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			my $arg = clone( $tpl );
			$arg->{ -population } = 1;
			my $gal = AI::Genetic::Pro->new( %$arg );
			$gal->init( 1 );
			#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			if( my $typ = $self->_package ){
				for my $idx ( 0 .. $#{ $ary->[ 0 ] } ){
					$ary->[ 0 ][ $idx ] = $typ->make_with_packed( $ary->[ 0 ][ $idx ] );
					bless $ary->[ 0 ][ $idx ], q[AI::Genetic::Pro::Chromosome];
				}	
			}
			#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			$gal->population ( scalar( @{ $ary->[ 0 ] } ) );
			$gal->chromosomes( $ary->[ 0 ] );
			$gal->_fitness	 ( $ary->[ 1 ] );
			$gal->strict	 ( 0 );
			#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			$gal->evolve	 ( 1 );
			#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			@{ $gal->_state };
			
		} $self->_chunks;

		$self->_adopt( \@lst );
	}

	return;
}
#=======================================================================
1;
