package App::vaporcalc::Role::UI::Cmd;
$App::vaporcalc::Role::UI::Cmd::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -types;

use App::vaporcalc::Exception;
use App::vaporcalc::Recipe;
use App::vaporcalc::Cmd::Result;

use Moo::Role;

has verb => (
  is       => 'ro',
  isa      => Str,
  builder  => sub { '' },
);

has params => (
  is       => 'ro',
  isa      => ArrayObj,
  coerce   => 1,
  builder  => sub { array },
);

has recipe => (
  required  => 1,
  is        => 'ro',
  isa       => RecipeObject,
  coerce    => 1,
  writer    => '_set_recipe',
);

method execute {
  App::vaporcalc::Exception->throw(
    message => 'Missing verb; no action to perform!'
  ) unless $self->verb;
  my $meth = '_action_'.lc $self->verb; 
  return $self->$meth if $self->can($meth);
  App::vaporcalc::Exception->throw(
    message => 'Unknown action: '.$self->verb
  )
}

method throw_exception (@params) {
  App::vaporcalc::Exception->throw(@params)
}

method create_result (%params) {
  App::vaporcalc::Cmd::Result->new(%params)
}

method munge_recipe (%params) {
  my $data = $self->recipe->TO_JSON;
  $data->{$_} = $params{$_} for keys %params;
  App::vaporcalc::Recipe->new(%$data)
}

1;

=pod

=head1 NAME

App::vaporcalc::Role::UI::Cmd - Helper for vaporcalc command objects

=head1 SYNOPSIS

  # An example command subject;
  # placed in the App::vaporcalc::Cmd::Subject:: namespace so it can be found
  # by an App::vaporcalc::CmdEngine instance:
  package App::vaporcalc::Cmd::Subject::Foo;

  use Defaults::Modern;

  use Moo;
  with 'App::vaporcalc::Role::UI::Cmd';

  # To be listed in an App::vaporcalc::CmdEngine's 'subject_list';
  # must be a class method (not an attribute):
  sub _subject { 'foo' }

  # To provide a default verb:
  has '+verb' => ( builder => sub { 'show' } );

  # Add verbs that return an App::vaporcalc::Cmd::Result:
  method _action_view { $self->_action_show }
  method _action_show {
    $self->create_result(
      string => "hello world!"
    )
  }

=head1 DESCRIPTION

A L<Moo::Role> providing attributes & behavior common to L<App::vaporcalc>
command objects.

Command objects define a "subject" that provides "verbs" -- methods prefixed
with C<_action_> that have access to the current L</recipe> object and command
L</params>. Executing a verb returns a L<App::vaporcalc::Cmd::Result> (see
L</create_result>) or throws an exception (see L</throw_exception>) in case of
failure.

If using an L<App::vaporcalc::CmdEngine>, consumers of this role will likely
also want to define a C<_subject> class method returning a string to be taken
as the command subject when building the CmdEngine's C<subject_list>.

The given C<_subject> string must translate to the relevant class name by
trimming spaces and CamelCasing; for example:

  sub _subject { 'flavor' }    # -> ::Cmd::Subject::Flavor
  sub _subject { 'nic base' }  # -> ::Cmd::Subject::NicBase

=head2 ATTRIBUTES

=head3 verb

The action to perform.

An empty string by default. Consumers may want to override to provide a
default action.

=head3 params

The parameters for the command, as a L<List::Objects::Types/"ArrayObj">.

Can be coerced from a plain ARRAY.

=head3 recipe

The L<App::vaporcalc::Recipe> object being operated on.

Required by default.

=head2 METHODS

=head3 execute

A default dispatcher that, when called, converts L</verb> to lowercase and attempts to find
a method named C<< _action_$verb >>  to call.

=head3 throw_exception

  $self->throw_exception(
    message => 'failed!'
  );

Throw an exception object.

=head3 create_result

Builds an L<App::vaporcalc::Cmd::Result> instance.

=head3 munge_recipe

  my $new_recipe = $self->munge_recipe( 
    target_vg => 50, 
    target_pg => 50 
  );

Calls C<TO_JSON> on the current L</recipe> object, merges in the
given key/value pairs, and returns a new L<App::vaporcalc::Recipe> with the
appropriate values.

=head1 SEE ALSO

L<App::vaporcalc::Cmd::Result>

L<App::vaporcalc::CmdEngine>

L<App::vaporcalc::Role::UI::ParseCmd>

L<App::vaporcalc::Role::UI::PrepareCmd>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
