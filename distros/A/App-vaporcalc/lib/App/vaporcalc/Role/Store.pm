package App::vaporcalc::Role::Store;
$App::vaporcalc::Role::Store::VERSION = '0.005004';
use Defaults::Modern;

use JSON::MaybeXS 1.001 ();

use Role::Tiny;

requires 'TO_JSON';

method save ( (Str | Path) $path ) {
  my $jseng = JSON::MaybeXS->new(
    utf8            => 1,
    pretty          => 1,
    allow_blessed   => 1,
    convert_blessed => 1,
  );

  my $json  = $jseng->encode($self)
    || confess "Could not encode JSON: ".$jseng->error;

  path($path)->spew_utf8($json)
}

method load ( (Str | Path) $path ) {
  my $json  = path($path)->slurp_utf8;
  my $jseng = JSON::MaybeXS->new(
    utf8      => 1,
    relaxed   => 1,
  );

  my $data  = $jseng->decode($json)
    || confess "Could not decode JSON: ".$jseng->error;

  $self->_load_create_obj($data)
}

method _load_create_obj ($data) {
  (blessed $self || $self)->new(%$data)
}

1;

=pod

=head1 NAME

App::vaporcalc::Role::Store

=head1 SYNOPSIS

  # See App::vaporcalc::Recipe, App::vaporcalc::RecipeResultSet
  use Moo;
  with 'App::vaporcalc::Role::Store';

=head1 DESCRIPTION

This role provides L</save> and L</load> methods that attempt to serialize or
retrieve objects via L<JSON::MaybeXS>; this is used by
L<App::vaporcalc::Recipe> & L<App::vaporcalc::RecipeResultSet> to preserve
e-liquid recipes.

=head2 REQUIRES

=head3 TO_JSON

Consumers are expected to implement a C<TO_JSON> method that returns a plain
C<HASH> for storage.

=head2 METHODS

=head3 save

Takes a path (as a string or a L<Path::Tiny> object) and attempts to serialize
the C<$self> object to the given path.

Objects are expected to provide their own C<TO_JSON> method; if it is not
available, an exception is thrown.

=head3 load

Takes a path (as a string or a L<Path::Tiny> object) and attempts to create a
new object by calling C<new()>.

(Usually called as a class method.)

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
