package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;
use Cwd ();
use Data::Dumper;
$Data::Dumper::Indent = 1;

BEGIN { extends 'Catalyst::Controller' }

our %stash_globals;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    $c->response->body('matched TestApp::Controller::Root/index');
}

#
# process a PHP template in t/php
#
sub template :Regex('(\w+\.php)$') {
    my ($self, $c, @args) = @_;
    $DB::single = 1;
#    $c->log->info("args are @args, path is " . $c->req->{_path});
#    $c->log->debug("request is " . $c->req->captures->[0]);

    $c->stash->{template} = $c->req->captures->[0];
    $c->stash->{template_dir} = $APP::DIR. "/t/php";

    if (%stash_globals) {
	while (my ($k,$v) = each %stash_globals) {
	    $c->stash->{$k} = $v;
	}
	%stash_globals = ();
    }

    $c->forward( 'TestApp::View::PHPTest' );
}

sub template2 :Regex('(\w+\.php)2$') {
    my ( $self, $c, @args) = @_;
    $c->stash->{template} = $c->req->captures->[0];
    $c->stash->{template_dir} = $APP::DIR . "/t/php2";
    $c->forward( 'TestApp::View::PHPTest' );
}

sub foo :Local {
    my ( $self, $c, @args ) = @_;
    $c->response->content_type('text/plain; charset=utf-8');
    $c->response->body('foo');
}

sub body :Local {
    my ( $self, $c, @args ) = @_;
    $c->response->content_type( 'text/plain' );
    if (ref($c->request->body) eq 'File::Temp') {
	$c->response->body( join q//, readline($c->request->body) );
    } else {
	$c->response->body( Data::Dumper::Dumper($c->request->body) );
    }
}

sub default :Path {
    my ($self, $c, @args) = @_;
    $c->response->body('<pre>args are:' . "\n@args\n</pre>" );
}

sub end : ActionClass( 'RenderView' ) {}

1;
