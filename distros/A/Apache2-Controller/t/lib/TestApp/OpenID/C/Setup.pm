package TestApp::OpenID::C::Setup;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller
    Apache2::Request
);

use Readonly;
use Apache2::Const -compile => qw(HTTP_OK);
use Log::Log4perl qw(:easy);
use YAML::Syck;
use Apache2::Controller::X;

sub allowed_methods {qw( create_db force_timeout )}

sub create_db {
    my ($self) = @_;
    DEBUG 'Creating database for OpenID test...';
    my $dbh = $self->pnotes->{a2c}{dbh} || a2cx 'no dbh in pnotes';
    eval {
        $dbh->do(q{
            CREATE TABLE openid (
                uname               VARCHAR(255)    NOT NULL,
                openid_url          VARCHAR(255)    NOT NULL,
                PRIMARY KEY (uname)
            )
        });
    };
    a2cx "Could not create database table: '$EVAL_ERROR'" if $EVAL_ERROR;
    DEBUG 'Making sure session is completely clear...';
    # don't delete the session id!  oops.
    delete $self->{session}{$_} for grep !m{ \A _ }mxs, keys %{$self->{session}};
    $self->content_type('text/plain');
    $self->print("Created Database Tables.");
    return Apache2::Const::HTTP_OK;
}

# force a timeout of the openid session for testing purposes
sub force_timeout {
    my ($self) = @_;
    my $timeout = $self->get_directive('A2C_Auth_OpenID_Timeout') || 3600;
    my $openid_sess = $self->{session}{a2c}{openid};
    $openid_sess->{last_accessed_time} -= $timeout * 2
        if defined $openid_sess->{last_accessed_time};
    $self->content_type('text/plain');
    $self->print("Forced session timeout.");
    DEBUG "FORCE SESSION TIMEOUT, SESSION NOW:\n".Dump($self->{session});
    return Apache2::Const::HTTP_OK;
}

1;

