package App::MadEye::Plugin::Agent::SNMP::Process;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;
use App::MadEye::Util;
use List::Util qw/first/;

my $hrSWRunPath = '.1.3.6.1.2.1.25.4.2.1.4';

sub is_dead {
    my ($self, $host) = @_;

    my $process   = $self->config->{config}->{process}   or die "missing process";

    my $response = snmp_session(
        $self,
        $host => sub {
            my $session = shift;
            my $response = $session->get_table(
                -baseoid => $hrSWRunPath,
            ) or die "cannot get a $_ : " . $session->error;
            return $response;
        }
    );

    if (first { $_ eq $process } values %$response) {
        return; # alive
    } else {
        return "404 $process not found";
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::SNMP::Process - monitoring process

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        community:
            required: yes
            type: str
        port:
            required: no
            type: int
        timeout:
            required: no
            type: int
        process:
            required: yes
            type: str

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Net::SNMP>, L<App::MadEye>

