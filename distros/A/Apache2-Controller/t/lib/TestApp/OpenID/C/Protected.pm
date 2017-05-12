package TestApp::OpenID::C::Protected;

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

sub allowed_methods {qw( 
    access_user_area    login       logout      register
    dump_params
)}

sub access_user_area {
    my ($self) = @_;
    DEBUG 'Accessing the protected user area.';
    $self->content_type('text/plain');
    $self->print("Protected user area worked!");
    return Apache2::Const::HTTP_OK;
}

sub dump_params {
    my ($self) = @_;
    DEBUG 'Dumping params';
    $self->content_type('text/plain');
    # dump them in scalar-or-array style
    my @param_names = $self->param;
    my %params_hash = map {
        my @vals = $self->param($_);
        ($_ => @vals > 1 ? \@vals : $vals[0])
    } @param_names;
    $self->print(Dump(\%params_hash));
    return Apache2::Const::HTTP_OK;
}

sub login {
    my ($self) = @_;
    DEBUG 'login page';
    $self->content_type('text/plain');
    $self->print("This is the login page.");
    return Apache2::Const::HTTP_OK;
}

sub logout {
    my ($self) = @_;
    DEBUG 'login page';
    $self->content_type('text/plain');
    $self->print("This is the logout page.");
    return Apache2::Const::HTTP_OK;
}

sub register {
    my ($self) = @_;
    DEBUG "Redirected to the registration page. ENV:\n".Dump(\%ENV);

    if (!$self->param('for_real')) {
        $self->content_type('text/plain');
        $self->print("Registration page - just testing.");
        return Apache2::Const::HTTP_OK;
    }

    my $url = $self->param('openid_url') || a2cx "No openid_url for test";

    my $dbh = $self->pnotes->{a2c}{dbh} || a2cx 'no dbh in pnotes';
    eval {
        $dbh->do(
            q{ INSERT INTO openid VALUES (?, ?) }, undef, 'a2ctest', $url
        );
    };
    a2cx "Could not register user: $EVAL_ERROR" if $EVAL_ERROR;

    $self->content_type('text/plain');
    $self->print("Registration page - registered user.");
    return Apache2::Const::HTTP_OK;
}

1;

