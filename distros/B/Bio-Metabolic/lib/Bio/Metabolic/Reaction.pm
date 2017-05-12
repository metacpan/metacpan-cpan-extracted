
=head1 NAME

Bio::Metabolic::Reaction - Perl extension for biochemical reactions

=head1 SYNOPSIS

  use Bio::Metabolic::Reaction;

  my $r1 = Bio::Metabolic::Reaction->new('r1',[$sub1,$sub2],[$sub3,$sub4]);

  $r1->kinetics('linear');


=head1 DESCRIPTION

This class implements objects representing a biochemical reaction.
A biochemical reaction in this context is defined by its input and its output
substrates, i.e. by two Bio::Metabolic::Network::Cluster objects.
Further, every instance of this class is associated with a mathematical expression
which determines the dynamical behaviour of the reaction, i.e. the reaction rate.

=head2 EXPORT

None

=head2 OVERLOADED OPERATORS

  String Conversion
    $string = "$reaction";
    print "\$reaction = '$reaction'\n";

  Equality
    if ($reaction1 == $reaction2)
    if ($reaction1 != $reaction2)


=head1 AUTHOR

Oliver Ebenhöh, oliver.ebenhoeh@rz.hu-berlin.de

=head1 SEE ALSO

Bio::Metabolic Bio::Metabolic::Substrate Bio::Metabolic::Substrate::Cluster.

=cut

package Bio::Metabolic::Reaction;

require 5.005_62;
use strict;
use warnings;

require Exporter;

use Carp;

use Bio::Metabolic::Substrate::Cluster;

#use Math::Symbolic;

use overload

  #  "\"\"" => \&reaction_to_string,
  "\"\"" => \&to_compact_string,
  "=="   => \&equals,
  "!="   => sub { return 1 -equals(@_) };

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::Metabolic::Reaction ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our %OutputFormat = (
    -1 => "%20s",
    1  => "%-20s"
);

our $OutputArrow = " => ";

our $VERSION = '0.06';

#our $DEBUG = 1;

=head1 METHODS

=head2 Constructor new

There are three ways to call the constructor method:

1.) $r = Bio::Metabolic::Reaction->new($name, $inlist, $outlist);

    Here, the first argument must hold the name. The following two arguments 
    provide arrayrefs of Bio::Metabolic::Substrate objects, defining the input and 
    output substrates of the biochemical reaction.
    If a reactant occurs twice (e.g. X + X -> Y), it has to appear twice in the
    corresponding list.

2.) $r = Bio::Metabolic::Reaction->new($name, $substrates, $coefficients)

    The first argument must specify the name. The second argument can be an 
    arrayref of Bio::Metabolic::Substrate objects or a Bio::Metabolic::Substrate::Cluster
    object, defining all participating reactants.
    The third argument must hold numbers specifying the multiplicity of the 
    reactants in the same order as the reactants have been specified.

    Example: Let $X and $Y be Bio::Metabolic::Substrate objects defining the
        reactants X and Y. The reaction X + X -> Y can be defined either by

            $r1 = Bio::Metabolic::Reaction->new('r1', [$X,$X], [$Y]);

        or by

            $r2 = Bio::Metabolic::Reaction->new('r2', [$X,$Y], [-2,1]);

3.) The constructor can be called as an object method, using another reaction as
    template: $r2 = $r1->new().

=cut

sub new {    # defines a new reaction.
    my $proto = shift;
    my $pkg   = ref($proto) || $proto;

    my %attr = ref($proto) eq 'Bio::Metabolic::Reaction' ? %$proto : ();

    my $name = shift;

    $attr{name} = $name if defined $name;
    croak("name must be specified in constructor new()")
      unless defined $attr{name};

    #  my ($insubs,$outsubs) = @_;
    my $insubs  = shift;
    my $outsubs = shift;
    if (   defined $outsubs
        && ref($outsubs) eq 'ARRAY'
        && join( '', @$outsubs ) =~ /^[0-9\-\.]*$/ )
    {

        # list with stoichiometric coefficients
        $attr{substrates} =
          ref($insubs) eq 'Bio::Metabolic::Substrate::Cluster'
          ? $insubs
          : Bio::Metabolic::Substrate::Cluster->new(@$insubs);
        my @slist = $attr{substrates}->list;

        croak(
"numbers of substrates and stoichiometric coefficients don't agree in constructor new()"
          )
          unless @slist == @$outsubs;

        $attr{stoichiometry} = { map( ( $_->name, 0 ), @slist ) };
        for ( my $i = 0 ; $i < @slist ; $i++ ) {
            $attr{stoichiometry}->{ $slist[$i]->name } = $outsubs->[$i];
        }
    }
    elsif ( defined $insubs ) {
        $attr{substrates} =
          Bio::Metabolic::Substrate::Cluster->new( @$insubs, @$outsubs );

        my %tmphash = ( -1 => $insubs, 1 => $outsubs );
        while ( my ( $dir, $list ) = each %tmphash ) {
            foreach my $subs (@$list) {
                $attr{stoichiometry}->{ $subs->name } += $dir;
            }
        }
    }

#  $attr{-1} = Bio::Metabolic::Substrate::Cluster->new(@$insubs) if @$insubs;
#  croak ("in-metabolites have to be specified in constructor new()") unless defined $attr->{-1};
#  $attr{1} = Bio::Metabolic::Substrate::Cluster->new(@$insubs) if @$outsubs;
#  croak ("out-metabolites have to be specified in constructor new()") unless defined $attr->{1};

    croak(
        "participating compounds have not been specified in constructor new()")
      unless defined $attr{substrates} && defined $attr{stoichiometry};

    my %extra_attr = @_ ? %{ shift() } : ();

    my $new_reaction = bless {
        %attr,
        'parameters' => {},
        'rate'       => undef,
        %extra_attr,
    }, $pkg;

    return $new_reaction;
}

=head2 Method copy

  copy() is exactly the same as $r2 = $r1->new();

=cut

sub copy {
    return shift->new();
}

=head2 Method name

Optional argument: sets the object's name. Returns the object's name.

=cut

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    return $self->{name};
}

=head2 Method substrates

Returns all participating compounds as a Bio::Metabolic::Substrate::Cluster object.
Optional argument: sets the substrates.

=cut

sub substrates {
    my $self = shift;
    $self->{substrates} = shift if @_;
    return $self->{substrates};
}

=head2 Method stoichiometry

Returns a hashref. Keys are the substrate names, values the stoichiometric 
coefficients (negative for input substrates, positive for output substrates).
It the absolute value differs from one, the corresponding substrate is 
consumed/produced more than once.
Optional argument: sets the stoichiometries.

=cut

sub stoichiometry {
    my $self = shift;
    $self->{stoichiometry} = shift if @_;
    return $self->{stoichiometry};
}

=head2 Method st_coefficient

Argument must be a substrate. Returns the stoichiometric coefficient
(cf. method stoichiometry()) of the specified substrate.

=cut

sub st_coefficient {
    my $self      = shift;
    my $substrate = shift;
    return $self->stoichiometry->{ $substrate->name };
}

=head2 Method in

Returns the input substrates as a Bio::Metabolic::Substrate::Cluster object.

=cut

sub in {
    my $self   = shift;
    my @slist  = $self->substrates->list;
    my @inlist = map ( $self->st_coefficient($_) < 0 ? ($_) : (), @slist );

    return Bio::Metabolic::Substrate::Cluster->new(@inlist);

    #  return shift->{-1};
}

=head2 Method out

Returns the output substrates as a Bio::Metabolic::Substrate::Cluster object.

=cut

sub out {
    my $self    = shift;
    my @slist   = $self->substrates->list;
    my @outlist = map ( $self->st_coefficient($_) > 0 ? ($_) : (), @slist );

    return Bio::Metabolic::Substrate::Cluster->new(@outlist);

    #  return shift->{1};
}

=head2 Method dir

Take one parameter which must be -1 or 1. Returns the input or output
substrates, respectively.

=cut

sub dir {
    my $reaction = shift;
    my $dir      = shift;

    croak("Direction must be either -1 our 1") unless $dir == -1 || $dir == 1;

    return $dir == -1 ? $reaction->in : $reaction->out;
}

=head2 Method get_substrate_list

Returns input and output substrates as one list.

=cut

sub get_substrate_list {
    my $reaction = shift;

    return $reaction->substrates->list;

    #  return (@{$reaction->{-1}},@{$reaction->{1}});
}

#sub substrates {
#  return Bio::Metabolic::Substrate::Cluster->new(shift->get_substrate_list);
#}

sub reaction_to_string {
    my $reaction = shift;

    #  print "reaction_to_string called.\n";

    my $retstr;
    my $subsdir = {
        -1 => [],
        1  => []
    };
    foreach my $dir ( -1, 1 ) {
        foreach my $substrate ( $reaction->dir($dir)->list ) {
            push(
                @{ $subsdir->{$dir} },
                sprintf( $OutputFormat{$dir}, "$substrate" )
            );
        }
    }
    my $dir;
    my $bstr = $OutputArrow;
    while ( @{ $subsdir->{-1} } || @{ $subsdir->{1} } ) {
        my $left =
          @{ $subsdir->{-1} }
          ? shift( @{ $subsdir->{-1} } )
          : sprintf( $OutputFormat{-1}, "" );
        my $right =
          @{ $subsdir->{1} }
          ? shift( @{ $subsdir->{1} } )
          : sprintf( $OutputFormat{1}, "" );
        $retstr .= $left . $bstr . $right . "\n";
        $bstr =~ s/./ /g;

        #    print $retstr;
    }
    return $retstr;
}

sub to_compact_string {
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

    #    if ( defined( $reaction->rate ) ) {
    #        $retstr .= "rate: " . $reaction->rate . "\n";
    #        foreach my $param ( keys( %{ $reaction->parameters } ) ) {
    #            if (   ref( $reaction->parameter($param) )
    #                && ref( $reaction->parameter($param) ) eq
    #                'Math::Symbolic::Variable'
    #                && defined $reaction->parameter($param)->value )
    #            {
    #                $retstr .= "\t"
    #                  . $reaction->parameter($param) . "="
    #                  . $reaction->parameter($param)->value . "\n";
    #            }
    #        }
    #    }

    return $retstr;
}

=head2 Method equals()

compares two Bio::Metabolic::Reaction objects.
Returns 1 if all substrates occur with the same stoichiometric coefficient,
0 otherwise.

=cut

sub equals {
    my ( $r1, $r2 ) = @_;

    my $sl1 = $r1->substrates;
    my $sl2 = $r2->substrates;

    my @sl1 = $sl1->list;
    my @sl2 = $sl2->list;

    return 0 unless @sl1 == @sl2;

    foreach my $sub (@sl1) {
        return 0 unless $sl2->has($sub);
        return 0 unless $r1->st_coefficient($sub) == $r2->st_coefficient($sub);
    }

    return 1;
}

1;
__END__
