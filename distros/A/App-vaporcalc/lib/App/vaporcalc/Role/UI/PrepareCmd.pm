package App::vaporcalc::Role::UI::PrepareCmd;
$App::vaporcalc::Role::UI::PrepareCmd::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -types;

use Module::Runtime 'use_package_optimistically';

use Moo::Role;

has cmd_class_prefix => (
  lazy    => 1,
  is      => 'ro',
  isa     => Str,
  builder => sub { 'App::vaporcalc::Cmd::Subject::' },
);

method prepare_cmd (
  Str           :$subject,
  (Str | Undef) :$verb   = undef,
  ArrayObj      :$params = array(),
  RecipeObject  :$recipe,
) {
  
  # 'nic base' -> NicBase, etc
  my $fmt_subj = join '', map {; ucfirst } split ' ', lc $subject;
  my $mod = $self->cmd_class_prefix . $fmt_subj;

  use_package_optimistically($mod)->new(
    maybe verb   => $verb,
          params => $params,
          recipe => $recipe,
  )
}

1;

=pod

=head1 NAME

App::vaporcalc::Role::UI::PrepareCmd

=head1 SYNOPSIS

  package MyCmdEngine;
  use Moo;
  with 'App::vaporcalc::Role::UI::PrepareCmd';

  package main;
  use List::Objects::WithUtils 'array';
  use App::vaporcalc::Recipe;
  my $recipe = App::vaporcalc::Recipe->new(
    # See App::vaporcalc::Recipe
  );
  my $cmdeng = MyCmdEngine->new;
  my $cmd = $cmdeng->prepare_cmd(
    recipe  => $recipe,
    verb    => 'set',
    subject => 'nic base',
    params  => array('36'),
  );

=head1 DESCRIPTION

A L<Moo::Role> for producing B<vaporcalc> command objects.

=head2 ATTRIBUTES

=head3 cmd_class_prefix

The prefix to use when constructing command object class names from a given
subject.

Defaults to C<App::vaporcalc::Cmd::Subject::>

=head2 METHODS

=head3 prepare_cmd

Takes a L<App::vaporcalc::Recipe>, an optional verb (action to perform), a
subject (used to find/build command objects), and an optional set of
parameters (as an ARRAY or ARRAY-type object). See L</SYNOPSIS>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
