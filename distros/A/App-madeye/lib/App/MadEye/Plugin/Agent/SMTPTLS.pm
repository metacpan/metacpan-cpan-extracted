package App::MadEye::Plugin::Agent::SMTPTLS;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Net::SMTP::TLS;

sub is_dead {
    my ( $self, $host ) = @_;

    my $conf    = $self->config->{config};
    my $port    = $conf->{port} || 25;
    my $timeout = $conf->{timeout} || 3;

    eval {
        my $smtptls = Net::SMTP::TLS->new(
            $host,
            Hello   => $host,
            Port    => $port,
            NoTLS   => 1,
            Timeout => $timeout,
        );
    };
    if ($@) {
        return "dead: $@";
    }
    else {
        return;    # alive!
    }
}

1;
__END__

=for stopwords smtptls

=head1 NAME

App::MadEye::Plugin::Agent::SMTPTLS - check smtptls.

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        port:
            required: no
            type: int
        timeout:
            required: no
            type: int

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>, L<Net::SMTP::TLS>

