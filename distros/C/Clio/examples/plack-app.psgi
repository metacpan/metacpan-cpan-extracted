
package Clio::PlackApp::Package;

use Moo;
use Plack::Builder;

sub authen_cb {
    my ($self, $username, $password) = @_;
    return $username eq 'admin' && $password eq 's3cr3t';
}

sub to_app {
    my $self = shift;

    return sub {
        my $app = shift;
        builder {
            enable "Auth::Basic", authenticator => sub {
                my ($username, $password) = @_;

                $self->authen_cb($username, $password);
            };
            $app;
        };
    }
}


__PACKAGE__->new();
