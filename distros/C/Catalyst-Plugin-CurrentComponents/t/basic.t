use Test::Most;

{
  package MyApp::Model::CurrentModel;
  $INC{'MyApp/Model/CurrentModel.pm'} = __FILE__;
  use base 'Catalyst::Model';

  package MyApp::Model::CurrentModel2;
  $INC{'MyApp/Model/CurrentModel2.pm'} = __FILE__;
  use base 'Catalyst::Model';

  package MyApp::View::CurrentView;
  $INC{'MyApp/View/CurrentView.pm'} = __FILE__;
  use base 'Catalyst::View';

  package MyApp::Controller::CurrentModel;
  $INC{'MyApp/Controller/CurrentModel.pm'} = __FILE__;
  use base 'Catalyst::Controller';

  sub current_model { return 'CurrentModel' }

  sub base : Path('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body(ref $c->model);
  }

  package MyApp::Controller::CurrentModelInstance;
  $INC{'MyApp/Controller/CurrentModelInstance.pm'} = __FILE__;
  use base 'Catalyst::Controller';

  sub current_model_instance { return pop->model('CurrentModel') }

  sub base : Path('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body(ref $c->model);
  }

  package MyApp::Controller::CurrentView;
  $INC{'MyApp/Controller/CurrentView.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub current_view { return 'CurrentView' }

  sub base : Path('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body(ref $c->view);
  }

  package MyApp::Controller::CurrentViewInstance;
  $INC{'MyApp/Controller/CurrentViewInstance.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub current_view_instance { return pop->view('CurrentView') }

  sub base : Path('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body(ref $c->view);
  }

  package MyApp::Controller::Methods;
  $INC{'MyApp/Controller/Methods.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub current_model_action : Local Args(0) {
    my ($self, $c) = @_;
    $c->current_model('CurrentModel');
    $c->res->body(ref $c->model);
  }

  sub current_view_action : Local Args(0) {
    my ($self, $c) = @_;
    $c->current_model('CurrentView');
    $c->res->body(ref $c->view);
  }

  sub current_model_instance_action : Local Args(0) {
    my ($self, $c) = @_;
    $c->current_model_instance( $c->model('CurrentModel') );
    $c->res->body(ref $c->model);
  }

  sub current_view_instance_action : Local Args(0) {
    my ($self, $c) = @_;
    $c->current_view_instance( $c->view('CurrentView') );
    $c->res->body(ref $c->view);
  }

  sub set_model_by_return :Chained(/) CaptureArgs(0) {
    my ($self, $c) = @_;
    return $c->model('CurrentModel2');
  }

    sub midpoint :Chained('set_model_by_return') PathPart('') CaptureArgs(0) {
      my ($self, $c) = @_;
    }

      sub endpoint :Chained('midpoint') PathPart('') Args(0) {
        my ($self, $c) = @_;
        $c->res->body(ref $c->model);
      }

  sub set_view_by_return :Chained(/) CaptureArgs(0) {
    my ($self, $c) = @_;
    return $c->model('CurrentView');
  }

    sub midpoint2 :Chained('set_view_by_return') PathPart('') CaptureArgs(0) {
      my ($self, $c) = @_;
    }

      sub endpoint2 :Chained('midpoint2') PathPart('') Args(0) {
        my ($self, $c) = @_;
        $c->res->body(ref $c->view);
      }

  package MyApp;
  use Catalyst 'CurrentComponents';

  MyApp->config(
    default_model=>'CurrentModel',
    'Plugin::CurrentComponents' => {
      model_instance_from_return => 1,
      model_instance_from_state => 1,
      view_instance_from_return => 1,
    },
  );
  
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my $res = request "/currentmodel";
  is $res->content, 'MyApp::Model::CurrentModel';
}

{
  my $res = request "/currentmodelinstance";
  is $res->content, 'MyApp::Model::CurrentModel';
}

{
  my $res = request "/currentview";
  is $res->content, 'MyApp::View::CurrentView';
}

{
  my $res = request "/currentviewinstance";
  is $res->content, 'MyApp::View::CurrentView';
}

{
  my $res = request "/methods/current_model_action";
  is $res->content, 'MyApp::Model::CurrentModel';
}

{
  my $res = request "/methods/current_model_instance_action";
  is $res->content, 'MyApp::Model::CurrentModel';
}

{
  my $res = request "/methods/current_view_action";
  is $res->content, 'MyApp::View::CurrentView';
}

{
  my $res = request "/methods/current_view_instance_action";
  is $res->content, 'MyApp::View::CurrentView';
}

{
  my $res = request "/set_model_by_return";
  is $res->content, 'MyApp::Model::CurrentModel2';
}

{
  my $res = request "/set_view_by_return";
  is $res->content, 'MyApp::View::CurrentView';
}

done_testing;
