package App::MadEye::Plugin::Agent::SMTP;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Net::SMTP;

sub is_dead {
    my ($self, $host) = @_;

    my $conf = $self->config->{config};
    my $timeout = $conf->{timeout} || 5;

    my $smtp = Net::SMTP->new($host, Timeout => $timeout);
    if ($smtp) {
        $smtp->quit;
        return;
    } else {
        return "DEAD";
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::SMTP - check SMTP.

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        timeout:
            required: yes
            type: int

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>, L<Net::SMTP>

