package Bio::Metabolic::Dynamics::Network;

require 5.005_62;
use strict;
use warnings;

use Math::Symbolic::VectorCalculus;

require Exporter;

our $VERSION = '0.06';

=begin comment

_time_derivative_by_substrate_number returns the temporal change of a substrate
(specified by an index). This change is determined by teh reaction rates.

=end comment

=cut

sub Bio::Metabolic::Network::_time_derivative_by_substrate_number {
    my $network = shift;
    my $s       = shift;

    my $matrix    = $network->matrix;
    my $reactions = $network->reactions;

    my $sterm = Math::Symbolic::Constant->zero();

    my @rcols = PDL::which( $matrix->slice("($s),:") != 0 )->list;
    foreach my $r (@rcols) {
        my $rterm = Math::Symbolic::Operator->new(
            '*',
            Math::Symbolic::Constant->new( $matrix->at( $s, $r ) ),
            $reactions->[$r]->rate
        );

#    my $rterm = Symbolic::Function::Operator::Mult->new([Symbolic::Function::Constant->new($matrix->at($s,$r)),
#							 $reactions->[$r]->rate])->simplify;
        $sterm =
          Math::Symbolic::Operator->new( '+', $rterm->simplify, $sterm )
          ->simplify;

#    $sterm = Symbolic::Function::Operator::Add->new([$rterm,$sterm])->simplify;
    }

    return $sterm;
}

=head2 Method time_derivative

This method returns a Math::Symbolic tree representing a function which determines the temporal
change of the concentration of the substrate passed as the argument.
This function is determined by the reaction rates.

=cut

sub Bio::Metabolic::Network::time_derivative {
    my $network   = shift;
    my $substrate = shift;

    my $s = $network->substrates->which($substrate);

    return
      defined $s ? $network->_time_derivative_by_substrate_number($s) : undef;
}

=head2 Method ODEs

This method returns an array of Math::Symbolic trees. One for each substrate.
The optional argument can be a Bio::Metabolic::Substrate::Cluster, an arrayref or an array
of Bio::Metabolic::Substrate objects.
If no argument is specified, it defaults to what the method substrates() returns.

=cut

sub Bio::Metabolic::Network::ODEs {
    my $network = shift;

    my @sindices   = ();
    my @substrates = ();
    if (@_) {
        if ( ref( $_[0] ) eq 'Bio::Metabolic::Substrate::Cluster' ) {
            @substrates = shift->list;
        }
        elsif ( ref( $_[0] ) eq 'ARRAY' ) {
            @substrates = @{ shift() };
        }
        else {
            @substrates = @_;
        }
    }
    else {
        @substrates = $network->substrates->list;
    }

    #  if (@_) {
    #    my @substrates = shift->list;
    while ( my $sub = shift(@substrates) ) {
        push( @sindices, $network->substrates->which($sub) );
    }

    my @time_derivatives = ();

    for ( my $s = 0 ; $s < @sindices ; $s++ ) {
        push( @time_derivatives,
            $network->_time_derivative_by_substrate_number( $sindices[$s] ) );

        #    push (@time_derivatives,$sterm);
    }

    return @time_derivatives;
}

=head2 Method mfile

Dumps a strong which can be used as an mfile for Matlab.
The optional argument can be a Bio::Metabolic::Substrate::Cluster, an arrayref or an array
of Bio::Metabolic::Substrate objects.
If no argument is specified, it defaults to what the method substrates() returns.

The corresponding substrate concentrations are considered to be integration variables.

All parameters within the participating reactions must have a value.
The method croaks if one parameter value is not defined.

=cut

sub Bio::Metabolic::Network::mfile {
    my $network = shift;

    #  my $substrates = shift;

    my @substrates = ();
    if (@_) {
        if ( ref( $_[0] ) eq 'Bio::Metabolic::Substrate::Cluster' ) {
            @substrates = shift->list;
        }
        elsif ( ref( $_[0] ) eq 'ARRAY' ) {
            @substrates = @{ shift() };
        }
        else {
            @substrates = @_;
        }
    }
    else {
        @substrates = $network->substrates->list;
    }

#  my @substrates = ref($_[0]) ? ref($_[0]) eq 'Bio::Metabolic::Substrate::Cluster' ? $_[0]->list : @{$_[0]} : @_;

    my @odes = $network->ODEs(@substrates);

    #  my @odes = &$odesub($network, @substrates);

    #  my $varlist = Math::Symbolic::VectorCalculus::_combined_signature(@odes);

    my %varchecklist = map ( ( $_, 1 ),
        @{ Math::Symbolic::VectorCalculus::_combined_signature(@odes) } );

    my %parameters = ();    # collect all parameter values;
    foreach my $reaction ( @{ $network->reactions } ) {
        foreach my $param ( keys( %{ $reaction->parameters } ) ) {
            $parameters{ $reaction->parameter($param)->{name} } =
              $reaction->parameter($param)->value();
        }
    }

    my $mfile = "function f=func(t,y)\n";

    my @varnames = map ( $_->name, @substrates );
    for ( my $vnr = 0 ; $vnr < @varnames ; $vnr++ ) {
        $mfile .= $varnames[$vnr] . "=y(" . eval( $vnr + 1 ) . ");\n";
        delete( $varchecklist{ $varnames[$vnr] } )
          if defined( $varchecklist{ $varnames[$vnr] } );
    }

    foreach my $param ( keys(%varchecklist) ) {
        croak("undefined parameter $param in method mfile")
          unless defined $parameters{$param};
        $mfile .= $param . "=" . $parameters{$param} . "\n";

        foreach my $ode (@odes) {
            $ode->implement( $param => $parameters{$param} );
        }

        delete( $varchecklist{$param} ) if defined( $varchecklist{$param} );
    }

    for ( my $snr = 0 ; $snr < @odes ; $snr++ ) {
        my ( $codeline, $leftovers ) =
          Math::Symbolic::Compiler->compile_to_code( $odes[$snr], \@varnames );
        croak("cannot handle leftover trees in method mfile") if @$leftovers;

        for ( my $vnr = 0 ; $vnr < @varnames ; $vnr++ ) {
            $codeline =~ s/\$_\[$vnr\]/$varnames[$vnr]/g;
        }

        $mfile .= "f(" . eval( $snr + 1 ) . ",1)=" . $codeline . ";\n";
    }

    return $mfile;
}

