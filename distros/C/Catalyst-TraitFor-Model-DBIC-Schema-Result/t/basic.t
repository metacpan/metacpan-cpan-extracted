use Test::Most;

BEGIN {
  package MyApp::Schema::User;
  $INC{'MyApp/Schema/User.pm'} = __FILE__;

  use base 'DBIx::Class::Core';
 
  __PACKAGE__->table("users");
  __PACKAGE__->add_columns(
    id => { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    first_name => { data_type => "varchar", size => 100 });

  __PACKAGE__->set_primary_key("id");
  __PACKAGE__->add_unique_constraint([ qw/first_name/ ]);

  package MyApp::Schema;
  $INC{'MyApp/Schema.pm'} = __FILE__;

  use base 'DBIx::Class::Schema';
 
  __PACKAGE__->load_classes('User');
}

{
  package MyApp::Model::Schema;
  $INC{'MyApp/Model/Schema.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model::DBIC::Schema';

  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub user :Local Args(1) {
    my ($self, $c) = @_;

    Test::Most::ok (my $user1 = $c->model('Schema::User::Result'));
    Test::Most::ok (my $user2 = $c->model('Schema::User::Result'));
    Test::Most::ok (my $user3 = $c->model('Schema::User::Result'));

    $c->res->body('test');
  }

  sub user_with_attr :Local Args(1) ResultModelFrom(first_name=>$args[0]) {
    my ($self, $c) = @_;
    Test::Most::ok (my $user = $c->model('Schema::User::Result'));

    $c->res->body('test');
  }

  sub user_with_local :Local {
    my ($self, $c) = @_;

    {
      Test::Most::ok (my $user = $c->model('Schema::User::Result', 1));
      Test::Most::is $user->first_name, 'john';
    }
 
    {
      Test::Most::ok (my $user = $c->model('Schema::User::Result', 2));
      Test::Most::is $user->first_name, 'joe';
    }

    {
      Test::Most::ok (my $user = $c->model('Schema::User::Result', +{first_name=>'mark'}));
      Test::Most::is $user->first_name, 'mark';
    }

    $c->res->body('test');
  }

  sub new_result :Local Args(0) {
    my ($self, $c) = @_;

    Test::Most::ok (my $user = $c->model('Schema::User::Result'));
    Test::Most::is $user->first_name, undef;
    Test::Most::ok !$user->in_storage;

    $user->first_name('Vanessa');
    $user->insert;

    Test::Most::ok $user->in_storage;
  }

  sub from_rs :Local Args(1) {
    my ($self, $c, $id) = @_;
    my $rs = $c->model("Schema::User")->search({first_name=>['john','joe']});

    Test::Most::is $rs->count, 2, 'got right count';

    $c->stash->{user} = $c->model('Schema::User::Result', $rs);
    $c->response->body(1);
  }

  package MyApp;
  use Catalyst;
  use Test::DBIx::Class
    -schema_class => 'MyApp::Schema', qw/User Schema/;

  User->populate([
    ['id','first_name'],
    [ 1 => 'john'],
    [ 2 => 'joe'],
    [ 3 => 'mark'],
    [ 4 => 'matt'],
  ]);

  MyApp->config(
    'Model::Schema' => {
      traits => ['Result'],
      schema_class => 'MyApp::Schema',
      connect_info => [ sub { Schema()->storage->dbh } ],
    },
  );

  MyApp->setup;

}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/example/user/1' );
}

{
  my ($res, $c) = ctx_request( '/example/user_with_attr/john' );
}

{
  my ($res, $c) = ctx_request( '/example/user_with_local' );
}

{
  my ($res, $c) = ctx_request( '/example/new_result' );
}

{
  my ($res, $c) = ctx_request( '/example/from_rs/2' );
  ok $res->content;
  ok $c->stash->{user};
  is $c->stash->{user}->first_name, 'joe';
}
{
  my ($res, $c) = ctx_request( '/example/from_rs/3' );
  ok $res->content;
  ok ! $c->stash->{user};
}


done_testing;
