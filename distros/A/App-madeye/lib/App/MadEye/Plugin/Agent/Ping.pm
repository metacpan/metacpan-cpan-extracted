package App::MadEye::Plugin::Agent::Ping;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Net::Ping;

sub is_dead {
    my ($self, $host) = @_;

    my $timeout = $self->config->{config}->{timeout};

    my $p = Net::Ping->new("tcp");
    $p->hires(1);
    my ( $ret, ) = $p->ping( $host, $timeout );
    $p->close;

    if ($ret) {
        return; # success
    } else {
        return "dead";
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::Ping - ping! ping!

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

L<App::MadEye>, L<Gearman::Client>, L<Gearman::Worker>

