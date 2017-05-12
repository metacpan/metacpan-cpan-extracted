package App::vaporcalc::Cmd::Subject::TargetAmount;
$App::vaporcalc::Cmd::Subject::TargetAmount::VERSION = '0.005004';
use Defaults::Modern;
use Moo;

method _subject { 'target amount' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';


method _action_show { $self->_action_view }
method _action_view {
  my $amt = $self->recipe->target_quantity;
  $self->create_result(string => " target => $amt ml")
}

method _action_set {
  my $new_tgt = $self->params->get(0);
  $self->throw_exception(
    message => 'set requires a parameter'
  ) unless defined $new_tgt;

  my $recipe = $self->munge_recipe(
    target_quantity => $new_tgt
  );
  $self->create_result(recipe => $recipe)
}

1;

=for Pod::Coverage .*

=cut

