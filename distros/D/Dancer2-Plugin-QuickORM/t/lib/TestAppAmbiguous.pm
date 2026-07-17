package TestAppAmbiguous;

# Two ORM configs that both expose the same table names. The bare
# singular/plural keywords collide and should become ambiguous, while the
# schema-prefixed keywords must keep working independently for each ORM.

use Dancer2;

BEGIN {
   set logger     => 'null';
   set serializer => 'JSON';

   set plugins => {
      QuickORM => {
         default => { class => 'FakeORM' },
         second  => { class => 'FakeORM' },
      },
   };
}

use Dancer2::Plugin::QuickORM;

get '/widget_ambiguous' => sub {
   my $ok = eval { widget(1); 1 };
   return { error => $ok ? '' : "$@" };
};

get '/widgets_ambiguous' => sub {
   my $ok = eval { widgets( {} ); 1 };
   return { error => $ok ? '' : "$@" };
};

get '/moose_ambiguous' => sub {
   my $ok = eval { moose(1); 1 };
   return { error => $ok ? '' : "$@" };
};

get '/default_widget/:id' =>
   sub { default_widget( route_parameters->get('id') ) };
get '/second_widget/:id' =>
   sub { second_widget( route_parameters->get('id') ) };

get '/default_widgets/blue' =>
   sub { [ default_widgets( { color => 'blue' } ) ] };
get '/second_widgets/blue' =>
   sub { [ second_widgets( { color => 'blue' } ) ] };

get '/default_moose/:id' =>
   sub { default_moose( route_parameters->get('id') ) };
get '/second_moose/:id' =>
   sub { second_moose( route_parameters->get('id') ) };

1;
