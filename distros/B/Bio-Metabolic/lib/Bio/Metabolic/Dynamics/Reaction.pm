package Bio::Metabolic::Dynamics::Reaction;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.06';

=head2 Method kinetics

Sets the rate expression of the reaction. The rate is expressed by a Math::Symbolic
object and accessible by the method rate(). Additional, some parameters will be set.
The first argument specifies the template to determine the rate expression.

The following templates are available at the moment:
    'linear', 'linear_reversible' : multilinear reversible kinetics
        results in the parameters 'k+' and 'k-'.
    'linear_irreversible' : mutlilinear irreversible (forward) kinetics
        results in the parameter 'k'

=cut

sub Bio::Metabolic::Reaction::kinetics {

# determines the reaction rate by some templates. Presently supported templates:
#      'linear' (same as 'linear_reversible')
#      'linear_irreversible'
    my $reaction = shift;
    my $kinetics = shift;

    my %old_params = %{ $reaction->parameters() };
    if ( $kinetics eq 'linear' || $kinetics eq 'linear_reversible' ) {
        my $varname    = $reaction->name;
        my $kplus      = Math::Symbolic::Variable->new( "kplus_" . $varname );
        my $kminus     = Math::Symbolic::Variable->new( "kminus_" . $varname );
        my %param_hash = (
            'k+' => $kplus,
            'k-' => $kminus,

            %old_params,

            #			  'k1' => $kminus,
            #			  'k-1' => $kplus
        );
        $reaction->parameters( \%param_hash );

        my %terms;
        foreach my $dir ( -1, 1 ) {
            my $pkey = $dir == -1 ? 'k+' : 'k-';
            $terms{$dir} = $reaction->parameter($pkey);
            foreach my $substrate ( $reaction->dir($dir)->list ) {
                my $sterm =
                  abs( $reaction->st_coefficient($substrate) ) == 1
                  ? $substrate->var
                  : Math::Symbolic::Operator->new( '^', $substrate->var,
                    abs( $reaction->st_coefficient($substrate) ) );
                $terms{$dir} =
                  Math::Symbolic::Operator->new( '*', $terms{$dir}, $sterm );
            }

#	    $terms{$dir} = Math::Symbolic::Operator->new('neg',$terms{$dir}) if $dir == 1;
        }

        $reaction->rate(
            Math::Symbolic::Operator->new( '-', $terms{-1}, $terms{1} ) );
    }
    elsif ( $kinetics eq 'linear_irreversible' ) {
        my $varname    = $reaction->name;
        my $k          = Math::Symbolic::Variable->new( "k_" . $varname );
        my %param_hash = (
            'k' => $k,
            %old_params,
        );
        $reaction->parameters( \%param_hash );

        my $rate = $reaction->parameter('k');
        foreach my $substrate ( $reaction->in->list ) {
            my $sterm =
              abs( $reaction->st_coefficient($substrate) ) == 1
              ? $substrate->var
              : Math::Symbolic::Operator->new( '^', $substrate->var,
                abs( $reaction->st_coefficient($substrate) ) );
            $rate = Math::Symbolic::Operator->new( '*', $rate, $sterm );
        }

        $reaction->rate($rate);
    }
    else {
        croak( "unknown reaction rate scheme \"" . $kinetics . "\"" );
    }
}

=head2 Method rate

Optional argument: Sets the rate expression.
Returns the rate expression.

Rate expressions are Math::Symbolic objects.

=cut

sub Bio::Metabolic::Reaction::rate {

   # use this subroutine to set or retrieve the rate expression for the reaction
    my $reaction = shift;
    return $reaction->{'rate'} unless @_;

    $reaction->{'rate'} = shift;
}

=head2 Method parameters

Optional argument: Sets the parameters.
Returns the parameters.

Parameters are given as hashrefs and are set e.g. by the method kinetics.

=cut

sub Bio::Metabolic::Reaction::parameters {
    my $reaction = shift;
    return $reaction->{'parameters'} unless @_;

    my $param = shift;
    croak("Parameters must be given as hashref!") unless ref($param) =~ /^HASH/;
    $reaction->{'parameters'} = $param;
}

=head2 Method parameter

Returns the parameter specified by the argument or undef if that parameter
is not defined.

=cut

sub Bio::Metabolic::Reaction::parameter {

    # get parameter: $p = $r->parameter(key)
    # set parameter: $r->parameter(key, variable);
    my $reaction  = shift;
    my $param_key = shift;
    return $reaction->{'parameters'}->{$param_key} unless @_;

    my $variable = shift;
    $reaction->{'parameters'}->{$param_key} = $variable;
}

sub Bio::Metabolic::Reaction::fullinfo {
    my $reaction = shift;

    my $retstr;
    my $subsdir = {
        -1 => [],
        1  => []
    };
    foreach my $dir ( -1, 1 ) {
        foreach my $substrate ( $reaction->dir($dir)->list ) {
            for (
                my $i = 1 ;
                $i <= abs( $reaction->st_coefficient($substrate) ) ;
                $i++
              )
            {
                push( @{ $subsdir->{$dir} }, "$substrate" );
            }
        }
    }

    $retstr =
        join( "+", @{ $subsdir->{-1} } ) . "->"
      . join( "+", @{ $subsdir->{1} } ) . "\n";

    if ( defined( $reaction->rate ) ) {
        $retstr .= "rate: " . $reaction->rate . "\n";
        foreach my $param ( keys( %{ $reaction->parameters } ) ) {
            if (   ref( $reaction->parameter($param) )
                && ref( $reaction->parameter($param) ) eq
                'Math::Symbolic::Variable'
                && defined $reaction->parameter($param)->value )
            {
                $retstr .= "\t"
                  . $reaction->parameter($param) . "="
                  . $reaction->parameter($param)->value . "\n";
            }
        }
    }

    return $retstr;
}
