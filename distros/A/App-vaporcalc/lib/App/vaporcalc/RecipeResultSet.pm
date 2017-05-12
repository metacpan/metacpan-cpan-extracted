package App::vaporcalc::RecipeResultSet;
$App::vaporcalc::RecipeResultSet::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -types;


use Moo;

has recipe => (
  required => 1,
  is       => 'ro',
  isa      => RecipeObject,
  coerce   => 1,
);

has result => (
  init_arg => undef,
  lazy     => 1,
  is       => 'ro',
  isa      => ResultObject,
  coerce   => 1,
  writer   => '_set_result',
  builder  => sub { shift->recipe->calc },
);

method TO_JSON {
  +{ recipe => $self->recipe }
}

with 'App::vaporcalc::Role::Store';

1;

=pod

=for Pod::Coverage TO_JSON

=head1 NAME

App::vaporcalc::RecipeResultSet - An e-liquid recipe and result pair

=head1 SYNOPSIS

  my $rset = App::vaporcalc::RecipeResultSet->new(
    recipe => +{
      # See App::vaporcalc::Recipe
    },
  );

=head1 DESCRIPTION

An instance of this class couples an L<App::vaporcalc::Recipe> with its
calculated L<App::vaporcalc::Result>.

=head2 ATTRIBUTES

=head3 recipe

The L<App::vaporcalc::Recipe> we are calculating.

Can be coerced from a C<HASH> of L<App::vaporcalc::Recipe> constructor
options.

=head3 result

Automatically created from the current L</recipe> object.

=head2 CONSUMES

L<App::vaporcalc::Role::Store>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
