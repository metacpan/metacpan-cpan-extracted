package App::vaporcalc::Cmd::Subject::Flavor;
$App::vaporcalc::Cmd::Subject::Flavor::VERSION = '0.005004';
use App::vaporcalc::Flavor;

use Defaults::Modern;
use Moo;

method _subject { 'flavor' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';


method _action_show { $self->_action_view }
method _action_view {
  my $output = "Flavors:\n";
  for my $flavor ($self->recipe->flavor_array->all) {
    my $pcnt = $flavor->percentage;
    my $tag  = $flavor->tag;
    my $type = $flavor->type;
    $output .= " $tag -> $pcnt %  ($type)";
  }

  $self->create_result(string => $output)
}

method _action_set {
  my ($tag, $pcnt, $type) = $self->params->all;
  $self->throw_exception(
    message => 'set requires at least a flavor tag and percentage'
  ) unless defined $tag and length $tag and defined $pcnt;

  my $existing = $self->recipe->flavor_array->first_where(
    sub { $_->tag eq $tag }
  );
  my $others = $self->recipe->flavor_array->grep(sub { $_->tag ne $tag });

  $type = $existing->type if $existing and not defined $type;

  my $flavors = [
    $others->all,
    App::vaporcalc::Flavor->new(
            tag        => $tag, 
            percentage => $pcnt, 
      maybe type       => $type,
    )
  ];

  my $recipe = $self->munge_recipe(
    flavor_array => $flavors,
  );
  $self->create_result(recipe => $recipe)
}

method _action_add {
  my ($tag, $pcnt, $type) = $self->params->all;
  $self->throw_exception(
    message => 'add requires at least a flavor tag and percentage'
  ) unless defined $tag and length $tag and defined $pcnt;

  $self->throw_exception(
    message => 'Attempting to add an existing flavor tag'
  ) if $self->recipe->flavor_array->has_any(sub { $_->tag eq $tag });

  my $flavors = array(
    $self->recipe->flavor_array->all,
    App::vaporcalc::Flavor->new(
            tag        => $tag,
            percentage => $pcnt,
      maybe type       => $type,
    )
  );

  my $recipe = $self->munge_recipe(
    flavor_array => $flavors,
  );
  $self->create_result(recipe => $recipe)
}

method _action_del {
  my $tag = $self->params->get(0);
  $self->throw_exception(
    message => 'del requires a flavor tag'
  ) unless defined $tag and length $tag;

  $self->throw_exception(
    message => 'Attempting to del an unknown flavor tag'
  ) unless $self->recipe->flavor_array->has_any(sub { $_->tag eq $tag });

  my $flavors = $self->recipe->flavor_array->grep(sub { $_->tag ne $tag });

  my $recipe = $self->munge_recipe(
    flavor_array => $flavors,
  );
  $self->create_result(recipe => $recipe)
}

method _action_clear {
  my $recipe = $self->munge_recipe(flavor_array => array);
  $self->create_result(recipe => $recipe)
}

1;

=for Pod::Coverage .*

=cut

