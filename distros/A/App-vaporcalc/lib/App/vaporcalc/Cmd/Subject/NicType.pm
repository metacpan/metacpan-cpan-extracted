package App::vaporcalc::Cmd::Subject::NicType;
$App::vaporcalc::Cmd::Subject::NicType::VERSION = '0.005004';
use Defaults::Modern;
use Moo;

method _subject { 'nic type' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';


method _action_show { $self->_action_view }
method _action_view {
  my $type = $self->recipe->base_nic_type;
  $self->create_result(
    string => " -> Nic type: $type"
  )
}

method _action_set {
  my $new_nic = $self->params->get(0);
  $self->throw_exception(
    message => 'set requires a parameter'
  ) unless defined $new_nic;

  my $recipe = $self->munge_recipe(
    base_nic_type => $new_nic
  );
  $self->create_result(
    recipe => $recipe,
  )
}

1;

=for Pod::Coverage .*

=cut

