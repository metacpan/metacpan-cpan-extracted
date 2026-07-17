package TestAppDispatch;

use Dancer2;

BEGIN {
   set logger     => 'null';
   set serializer => 'JSON';
   set session    => 'Simple';

   set plugins => {
      QuickORM => {
         default => {
            class => 'FakeORM',
         },
      },
   };
}

use Dancer2::Plugin::QuickORM;

# -- singular/plural dispatch on a table with distinct singular & plural --

get '/widget/:id'      => sub { widget( route_parameters->get('id') ) };
get '/widget_bad_hash' => sub {
   my $ok = eval { widget( { color => 'blue' } ); 1 };
   return { error => $ok ? '' : "$@" };
};
get '/widget_no_args' => sub {
   my $ok = eval { widget(); 1 };
   return { error => $ok ? '' : "$@" };
};

get '/widgets'      => sub { [ widgets() ] };
get '/widgets/blue' => sub { [ widgets( { color => 'blue' } ) ] };
get '/widgets_bad'  => sub {
   my $ok = eval { widgets('not-a-hashref'); 1 };
   return { error => $ok ? '' : "$@" };
};

# -- smart dispatch on a table whose singular & plural forms are identical --

get '/moose/:id'          => sub { moose( route_parameters->get('id') ) };
get '/moose_search/:herd' => sub {
   [ moose( { herd => route_parameters->get('herd') } ) ];
};
get '/moose_no_args' => sub {
   my $ok = eval { moose(); 1 };
   return { error => $ok ? '' : "$@" };
};
get '/moose_bad_ref' => sub {
   my $ok = eval {
      moose( sub { } );
      1;
   };
   return { error => $ok ? '' : "$@" };
};
get '/moose_arrayref' => sub { moose( [ 'not', 'a', 'primary', 'key' ] ) };

# -- orm() keyword --

get '/orm_default_name' => sub { { name => orm()->name } };
get '/orm_named_name/:name' =>
   sub { { name => orm( route_parameters->get('name') )->name } };
get '/orm_unknown' => sub {
   my $ok = eval { orm('nope'); 1 };
   return { error => $ok ? '' : "$@" };
};

# -- table whose derived keyword ('orm') collides with the plugin's own
#    orm() keyword; the bare form should be skipped in favour of the
#    already-registered orm() method, but the schema-prefixed form should
#    still reach the table --

get '/default_orm/:id' => sub { default_orm( route_parameters->get('id') ) };

# -- tables whose derived keyword(s) collide with Dancer2 core DSL keywords --

get '/session_builtin_roundtrip' => sub {
   session( 'greeting' => 'hello' );
   return { greeting => session('greeting') };
};

get '/sessions_search/:token' => sub {
   [ sessions( { token => route_parameters->get('token') } ) ];
};

get '/response_header_roundtrip/:value' => sub {
   response_header( 'X-QuickORM-Test' => route_parameters->get('value') );
   return 'ok';
};

get '/default_header/:id' =>
   sub { default_header( route_parameters->get('id') ) };
get '/default_headers/:label' => sub {
   [ default_headers( { label => route_parameters->get('label') } ) ];
};

1;
