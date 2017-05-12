package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
}

__PACKAGE__->config(namespace => '');

sub test_render
    :Local
{
    my ($self, $c) = @_;

    $c->stash->{message} = eval {
        $c->view('Xslate::Appconfig')->render($c, $c->req->param('template'), {param => $c->req->param('param') || ''})
    };
    if (my $err = $@) {
        $c->response->body($err);
        $c->response->status(403);
    } else {
        $c->stash->{template} = 'test.tx';
    }

}

# XXX From View::TT, but not supported in Xslate
# sub test_msg : Local {
#     my ($self, $c) = @_;
#     my $tmpl = $c->req->param('msg');
# 
#     $c->stash->{message} = $c->view('Xslate::AppConfig')->render($c, $tmpl);
#     $c->stash->{template} = 'test.xt';
# }
#
sub test_expose_methods
    : Local
{
    my ($self, $c) = @_;

    $c->stash(exposed => 'ok');
    
    my $return = $c
      ->view('Xslate::ExposeMethods')
      ->render($c, \'hello <: $abc() :> world <: $def("arg") :>');

    $c->response->body($return);
}

sub test_expose_methods_coerced
    : Local
{
    my ($self, $c) = @_;

    $c->stash(exposed => 'ok');
    
    my $return = $c
      ->view('Xslate::ExposeMethodsCoerced')
      ->render($c, \'hello <: $abc() :> world <: $def("arg") :>');

    $c->response->body($return);
}

sub test_header_footer
    : Local
{
    my ($self, $c) = @_;

    my $return = $c->view('Xslate::HeaderFooter')->render($c, \'content!');
    $c->response->body($return);
}

sub end 
    :Private
{
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;
    my $req_view = $c->request->param('view');

    my $view = $req_view ? ('Xslate::' . $req_view) : $c->config->{default_view};
    $c->forward($view);
}


__PACKAGE__->meta->make_immutable();

1;
