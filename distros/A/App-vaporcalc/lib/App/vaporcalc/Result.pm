package App::vaporcalc::Result;
$App::vaporcalc::Result::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -types;

use Moo;

 
has vg => (
  required => 1,
  is       => 'ro',
  isa      => RoundedResult,
  coerce   => 1,
);

has pg => (
  required => 1,
  is       => 'ro',
  isa      => RoundedResult,
  coerce   => 1,
);

has nic => (
  required => 1,
  is       => 'ro',
  isa      => RoundedResult,
  coerce   => 1,
);

has flavors => (
  required => 1,
  is       => 'ro',
  isa      => TypedHash[RoundedResult],
  coerce   => 1,
);

method flavor_total {
  return 0 unless $self->flavors->keys->has_any;
  my $flavor_ml = 0;
  $flavor_ml += $self->flavors->values->reduce(sub { $_[0] + $_[1] });
  $flavor_ml
}

method total { $self->vg + $self->pg + $self->nic + $self->flavor_total }

method TO_JSON {
  +{
    map {; 
      my ($attr, $val) = ($_, $self->$_);
      my $raw = blessed $val && $val->can('TO_JSON') ? $val->TO_JSON : $val;
      $attr => $raw
    } qw/
      vg
      pg
      nic
      flavors
    /,
  }
}

with 'App::vaporcalc::Role::Store';

1;

=pod

=for Pod::Coverage TO_JSON

=head1 NAME

App::vaporcalc::Result - A calculated App::vaporcalc::Recipe result

=head1 SYNOPSIS

  use App::vaporcalc::Recipe;
  my $result = App::vaporcalc::Recipe->new(
    # See App::vaporcalc::Recipe
  );

  my $vg_ml     = $result->vg;
  my $pg_ml     = $result->pg;
  my $nic_ml    = $result->nic;
  my $flavor_ml = $result->flavor;
  my $total_ml  = $result->total;

=head1 DESCRIPTION

A calculated result produced by L<App::vaporcalc::Recipe>.

All quantities are in C<ml>.

=head2 ATTRIBUTES

=head3 vg

The required amount of VG filler.

=head3 pg

The required amount of PG filler.

=head3 nic

The required amount of nicotine base solution.

=head3 flavors

A typed L<List::Objects::WithUtils::Array> containing a list of tuples in the
form of:

  name => quantity_in_ml

=head2 METHODS

=head3 total

The calculated total.

=head3 flavor_total

The calculated total flavor.

=head2 CONSUMES

L<App::vaporcalc::Role::Store>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
