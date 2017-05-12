package App::vaporcalc::Cmd::Subject::Notes;
$App::vaporcalc::Cmd::Subject::Notes::VERSION = '0.005004';
use Defaults::Modern;
use Moo;

method _subject { 'notes' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';


method _action_show { $self->_action_view }
method _action_view {
  my $n = 0;
  my $str = " -> notes:\n";
  if ($self->recipe->notes->has_any) {
    $str .= $self->recipe->notes->map(sub { $n++ .' - '. $_ })->join("\n")
  } else {
    $str .= 'none'
  }
  $self->create_result(string => $str)
}

method _action_clear {
  my $recipe = $self->munge_recipe(
    notes => array(),
  );
  $self->create_result(recipe => $recipe)
}

method _action_add {
  $self->throw_exception(
    message => 'add requires a parameter'
  ) unless $self->params->has_any;
  my $newnote = $self->params->join(' ');

  $self->throw_exception(
    message => 'new note is zero length'
  ) unless length $newnote;

  my $recipe = $self->munge_recipe(
    notes => array( $self->recipe->notes->all, $newnote ),
  );
  $self->create_result(recipe => $recipe)
}

method _action_delete { $self->_action_del }
method _action_del {
  my $delidx = $self->params->get(0);
  $self->throw_exception(
    message => 'expected an integer index to delete'
  ) unless is_Int $delidx;
  
  my $cloned = $self->recipe->notes->copy;
  $cloned->delete($delidx) if $cloned->has_any;

  my $recipe = $self->munge_recipe(
    notes => $cloned
  );
  $self->create_result(recipe => $recipe)
}

1;

=for Pod::Coverage .*

=cut

