package App::vaporcalc::Cmd::Subject::NicTarget;
$App::vaporcalc::Cmd::Subject::NicTarget::VERSION = '0.005004';
use Defaults::Modern;
use Moo;

method _subject { 'nic target' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';


method _action_show { $self->_action_view }
method _action_view {
  my $ntarget = $self->recipe->target_nic_per_ml;
  $self->create_result(
    string => " -> Target nicotine: $ntarget mg/ml"
  )
}

method _action_set {
  my $newnic = $self->params->get(0);
  $self->throw_exception(
    message => 'set requires a parameter'
  ) unless defined $newnic;

  my $recipe = $self->munge_recipe(
    target_nic_per_ml => $newnic,
  );
  $self->create_result(
    recipe => $recipe,
  )
}

1;

=for Pod::Coverage .*

=cut

