package App::MadEye::Plugin::Agent::SNMP::Disk;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;
use App::MadEye::Util;

my $oid_map = {
    hrStorageType      => '.1.3.6.1.2.1.25.2.3.1.2',
    hrStorageSize      => '.1.3.6.1.2.1.25.2.3.1.5',
    hrStorageUsed      => '.1.3.6.1.2.1.25.2.3.1.6',
    hrStorageDescr     => '.1.3.6.1.2.1.25.2.3.1.3',
    hrStorageFixedDisk => '.1.3.6.1.2.1.25.2.1.4',
};

sub is_dead {
    my ($self, $host) = @_;

    my $threshold = $self->config->{config}->{threshold} or die "missing threshold";

    my $response = snmp_session(
        $self,
        $host => sub {
            my $session = shift;

            return +{
                map {
                    $_ => (
                        $session->get_table(
                            -baseoid => $oid_map->{$_},
                        ) or die "cannot get a $_ : " . $session->error
                    )
                }
                qw/hrStorageDescr hrStorageUsed hrStorageType hrStorageSize/
            };
        },
    );

    my $result = '';
    each_storage($response => sub {
        my $get = shift;

        return if $get->('hrStorageSize') == 0; # /proc/bus/usb0 とかはサイズがゼロなのだ

        my $used_per = $get->('hrStorageUsed') / $get->('hrStorageSize') * 100;
        if ($used_per > $threshold) {
            $result .= join ' ', $get->('hrStorageDescr'), $get->('hrStorageUsed'), $get->('hrStorageSize'), sprintf('%3.2f%%', $used_per), "\n";
        }
    });
    return $result;
}

sub each_storage {
    my ($response, $code) = @_;

    while (my ($node, $storage_type) = each %{ $response->{hrStorageType} }) {
        if ($storage_type eq $oid_map->{hrStorageFixedDisk}) {
            (my $storage_number = $node) =~ s/.+\.//;

            $code->(
                sub {
                    my $key = shift;
                    $response->{$key}->{$oid_map->{$key} . '.' . $storage_number}
                }
            );
        }
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::SNMP::Disk - monitoring disk

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        threshold:
            required: yes
            type: int
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

