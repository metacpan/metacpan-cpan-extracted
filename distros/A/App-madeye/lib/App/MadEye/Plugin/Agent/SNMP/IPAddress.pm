package App::MadEye::Plugin::Agent::SNMP::IPAddress;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;
use App::MadEye::Util;

my $oid_map = {
    ipAdEntAddr => '.1.3.6.1.2.1.4.20.1.1'
};

sub is_dead {
    my ($self, $target) = @_;

    my $response = snmp_session(
        $self,
        $target->{host} => sub {
            my $session = shift;

            $session->get_table(
                -baseoid => $oid_map->{ipAdEntAddr},
            ) or die "cannot get a $_ : " . $session->error
        },
    );

    my $expected = join ' ', sort { $a cmp $b } @{ $target->{ip} };
    my $got      = join ' ', sort { $a cmp $b } values %$response;

    context->log('debug' => "got: $got, expected: $expected");

    if ($got eq $expected) {
        return; # alive
    } else {
        return "got: '$got' expected: '$expected'";
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::SNMP::IPAddress - monitoring IP address

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: map
                  mapping:
                    host:
                      type: str
                      required: yes
                    ip:
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
        retries:
            required: no
            type: int

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Net::SNMP>, L<App::MadEye>

