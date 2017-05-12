package App::vaporcalc::Cmd::Result;
$App::vaporcalc::Cmd::Result::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -types;

use Moo;

has action => (
  lazy      => 1,
  is        => 'ro',
  isa       => CommandAction,
  builder   => sub {
    my ($self) = @_;
      $self->has_recipe    ? 'recipe'
    : $self->has_resultset ? 'display'
    : $self->has_prompt    ? 'prompt'
    :                        'print'
  },
);


has string => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 1,
  builder   => sub { '' },
);


has prompt => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 1,
  builder   => sub { '(undef)' },
);

has prompt_callback => (
  lazy      => 1,
  is        => 'ro',
  isa       => CodeRef,
  predicate => 1,
  builder   => sub { sub {} }
);

has prompt_default_ans => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 1,
  builder   => sub { '' },
);

method run_prompt_callback (Str $answer = '') {
  chomp $answer;
  $self->prompt_callback->(
    local $_ = $answer || $self->prompt_default_ans || undef
  )
}


has recipe => (
  lazy      => 1,
  is        => 'ro',
  isa       => RecipeObject,
  coerce    => 1,
  predicate => 1,
);


has resultset => (
  lazy      => 1,
  is        => 'ro',
  isa       => RecipeResultSet,
  predicate => 1,
);


1;


=pod

=for Pod::Coverage has_\w+

=head1 NAME

App::vaporcalc::Cmd::Result

=head1 SYNOPSIS

  # Usually received from a App::vaporcalc:Role::UI::Cmd consumer

=head1 DESCRIPTION

An object representing the result of an L<App::vaporcalc::Role::UI::Cmd>
consumer's execution.

=head2 ATTRIBUTES

=head3 action

The action the controller should take; must be a
L<App::vaporcalc::Types/"CommandAction">.

=head3 prompt

The prompt to display when L</action> eq 'prompt'

=head3 prompt_callback

An optional callback that should be run with the answer given to L</prompt> (or
L</prompt_default_ans> if no answer is given).

See L</run_prompt_callback>.

=head3 prompt_default_ans

A default answer for use by L</run_prompt_callback> if none is given.

=head3 recipe

The L<App::vaporcalc::Recipe> to attach for L</action> eq 'recipe'

=head3 resultset

The L<App::vaporcalc::RecipeResultSet> to attach for L</action> eq 'display'

=head2 METHODS

=head3 run_prompt_callback

Runs L</prompt_callback> with C<$_> and C<$_[0]> set to either the given
argument or L</prompt_default_ans> if none given.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
