package TestApp::Session::Controller;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller
    Apache2::Request
);

use Readonly;
use Apache2::Const -compile => qw(HTTP_OK REDIRECT SERVER_ERROR);
use Log::Log4perl qw(:easy);
use YAML::Syck;

sub allowed_methods {qw( set read redirect redirect_force_save server_error )}

sub set {
    my ($self) = @_;
    DEBUG('setting session data');
    $self->content_type('text/plain');
    my ($data) = $self->param('data') =~ m{ \A (.*?) \z }mxs;
    die "no data param!\n" if !$data;
    DEBUG("received param data:\n$data|||\n");
    $self->{session}{testdata} = Load($data);
    DEBUG(sub { "session data is now:\n".Dump($self->{session}) });
    $self->print("Set session data.\n");
    return Apache2::Const::HTTP_OK;
}

# test path_args:
sub read {
    my ($self) = @_;
    DEBUG('Printing session data');
    $self->content_type('text/plain');
    $self->print(Dump($self->{session}));
    return Apache2::Const::HTTP_OK;
}

# set some data and try issuing a redirect
sub redirect {
    my ($self) = @_;
    DEBUG 'Putting data in for redirect test';
    $self->{session}{testdata}{redirect_data} = 'redirect data test';
    $self->err_headers_out->add(Location => '/session/read');
    return Apache2::Const::REDIRECT;
}

# try setting the same redirect data but set the force-save flag
sub redirect_force_save {
    my ($self) = @_;
    $self->pnotes->{a2c}{session_force_save} = 1;
    return $self->redirect();
}

# what about an error?  does the session get saved or not?
sub server_error {
    my ($self) = @_;
    DEBUG 'Putting data in for error test';
    $self->{session}{testdata}{error_data} = 'error data test';
    return Apache2::Const::SERVER_ERROR;
}

1;
