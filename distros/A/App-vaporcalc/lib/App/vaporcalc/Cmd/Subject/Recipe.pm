package App::vaporcalc::Cmd::Subject::Recipe;
$App::vaporcalc::Cmd::Subject::Recipe::VERSION = '0.005004';
use App::vaporcalc::RecipeResultSet;

use Defaults::Modern;
use Moo;

method _subject { 'recipe' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';


method _action_show { $self->_action_view }
method _action_view {
  my $rset = App::vaporcalc::RecipeResultSet->new(recipe => $self->recipe);
  # Force a calc now; easier to catch Result exceptions:
  $rset->result;
  $self->create_result(resultset => $rset)
}

method _action_save {
  my $dest = $self->params->get(0);
  unless ($dest) {
    $self->throw_exception(
      message => 'save requires a path'
    )
  }
  App::vaporcalc::RecipeResultSet->new(recipe => $self->recipe)->save($dest);
  $self->create_result(string => "Saved: $dest")
}

method _action_load {
  my $src = $self->params->get(0);
  unless ($src) {
    $self->throw_exception(
      message => 'load requires a path'
    )
  }
  my $recipe = App::vaporcalc::RecipeResultSet->load($src)->recipe;
  $self->create_result(recipe => $recipe)
}

1;

=for Pod::Coverage .*

=cut

