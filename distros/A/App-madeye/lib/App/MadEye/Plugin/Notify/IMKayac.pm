package App::MadEye::Plugin::Notify::IMKayac;
use strict;
use warnings;
use base qw/App::MadEye::Plugin::Base/;
use Params::Validate;
use MIME::Lite;
use DateTime;
use LWP::UserAgent;
use Digest::SHA1;

sub notify : Hook {
    my ($self, $context, $args) = @_;

    my $conf = $self->{config}->{config};
    my $username   = $conf->{username} or die "missing username";

    while (my ($plugin, $results) = each %$args) {
        $plugin =~ s/.+::Agent:://;
        my $msg = "ME: $plugin: ";
        for my $result (@$results) {
            $msg .= "'$result->{target}': $result->{message} ";
        }

        my $params = {message => $msg};
        if (my $secret_key = $conf->{secret_key}) {
            $params->{sig} = sha1_hex($msg . $secret_key);
        }
        if (my $password = $conf->{password}) {
            $params->{password} = $password;
        }

        my $ua = LWP::UserAgent->new(timeout => 5, agent => "MadEye/$App::MadEye::VERSION");
        my $res = $ua->post("http://im.kayac.com/api/post/$username", $params);
        $res->is_success or die $res->status_line;
    }
}

1;
