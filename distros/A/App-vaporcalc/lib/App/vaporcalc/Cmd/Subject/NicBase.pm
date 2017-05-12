package App::vaporcalc::Cmd::Subject::NicBase;
$App::vaporcalc::Cmd::Subject::NicBase::VERSION = '0.005004';
use Defaults::Modern;
use Moo;

method _subject { 'nic base' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';


method _action_show { $self->_action_view }
method _action_view {
  my $nbase = $self->recipe->base_nic_per_ml;
  $self->create_result(
    string => " -> Nic base: $nbase mg/ml"
  )
}

method _action_set {
  my $newbase = $self->params->get(0);
  $self->throw_exception(
    message => 'set requires a parameter'
  ) unless defined $newbase;

  my $recipe = $self->munge_recipe(
    base_nic_per_ml => $newbase
  );
  $self->create_result(
    recipe => $recipe
  )
}

1;

=for Pod::Coverage .*

=cut

