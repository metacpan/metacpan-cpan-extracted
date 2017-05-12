package TestApp::Controller::Root;

use parent 'Catalyst::Controller::WrapCGI';
use CGI ();

__PACKAGE__->config->{namespace} = '';

my $cgi = sub {
    my $cgi = CGI->new;
    print $cgi->header(-charset => 'utf-8');
    print 'foo:',~~$cgi->param('foo'),' bar:',~~$cgi->param('bar');
    if (my $fh = $cgi->param('baz')) {
      local $/;
      print ' baz:',<$fh>;
    }
    if (my $fh = $cgi->param('quux')) {
      local $/;
      print ' quux:',<$fh>;
    }
    die $cgi->cgi_error if $cgi->cgi_error;
};

sub handle_cgi : Path('/cgi-bin/test.cgi') {
    my ($self, $c) = @_;
    $self->cgi_to_response($c, $cgi);
}

sub test_path_info : Path('/cgi-bin/test_pathinfo.cgi') {
    my ($self, $c) = @_;

    $self->cgi_to_response($c, sub {
        my $cgi = CGI->new;
        print $cgi->header(-charset => 'utf-8');
        print $ENV{PATH_INFO}
    });
}

sub test_filepath_info : Path('/cgi-bin/test_filepathinfo.cgi') {
    my ($self, $c) = @_;

    $self->cgi_to_response($c, sub {
        my $cgi = CGI->new;
        print $cgi->header(-charset => 'utf-8');
        print $ENV{FILEPATH_INFO}
    });
}

sub test_script_name_root : Chained('/') PathPart('cgi-bin') CaptureArgs(1) {}

sub test_script_name : Chained('test_script_name_root') PathPart('test_scriptname.cgi') Args {
    my ($self, $c) = @_;

    $self->cgi_to_response($c, sub {
        my $cgi = CGI->new;
        print $cgi->header(-charset => 'utf-8');
        print $ENV{SCRIPT_NAME}
    });
}

sub test_remote_user : Path('/cgi-bin/test_remote_user.cgi') Args(0) {
    my ($self, $c) = @_;

    $self->cgi_to_response($c, sub {
        my $cgi = CGI->new;
        print $cgi->header(-charset => 'utf-8');
        print $ENV{REMOTE_USER}
    });
}

sub test_body_reset : Path('/cgi-bin/test_body_reset.cgi') Args(0) {
    my ($self, $c) = @_;

    # read body and don't seek back to 0
    my $body = $c->req->body;
    { local $/; my $dummy = <$body>; }

    $self->cgi_to_response($c, sub {
        my $cgi = CGI->new('');
        print $cgi->header(-charset => 'utf-8');
        print <STDIN>;
    });
}

sub test_body_post_reset : Path('/cgi-bin/test_body_post_reset.cgi') Args(0) {
    my ($self, $c) = @_;

    # read body and don't seek back to 0
    my $body = $c->req->body;
    { local $/; my $dummy = <$body>; }

    $self->cgi_to_response($c, sub {
        my $cgi = CGI->new('');
        print $cgi->header(-charset => 'utf-8');
        print <STDIN>;
    });

    # check the WrapCGI did a seek back to 0
    my $body_content = do { local $/; <$body> };

    $c->res->body($c->res->body . $body_content);
}

1;
