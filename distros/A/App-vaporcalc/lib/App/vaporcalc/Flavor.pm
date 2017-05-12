package App::vaporcalc::Flavor;
$App::vaporcalc::Flavor::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -types;

use Moo;

has percentage => (
  required  => 1,
  is        => 'ro',
  isa       => Percentage,
);

has tag => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has type => (
  is        => 'ro',
  isa       => VaporLiquid,
  coerce    => 1,
  builder   => sub { 'PG' },
);

method TO_JSON {
  +{
    percentage => $self->percentage,
    tag        => $self->tag,
    type       => $self->type,
  }
}

with 'App::vaporcalc::Role::Store';

1;

=pod

=for Pod::Coverage TO_JSON

=head1 NAME

App::vaporcalc::Flavor

=head1 SYNOPSIS

  # Usually used via App::vaporcalc::Recipe

=head1 DESCRIPTION

An object representing a flavor extract for use in a
L<App::vaporcalc::Recipe>.

=head2 ATTRIBUTES

=head3 percentage

The total target percentage of this flavor.

=head3 tag

The flavor's identifying tag.

=head3 type

The flavor base (VG/PG).

=head2 CONSUMES

L<App::vaporcalc::Role::Store>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
