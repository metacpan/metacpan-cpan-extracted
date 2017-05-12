package App::MadEye::Plugin::Agent::Sleep;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

sub is_dead {
    my ($self, $host) = @_;

    my $conf = $self->config->{config};
    my $sleep           = $conf->{sleep} or die "missing sleep";

    sleep $sleep;

    return;
}

1;

__END__

=head1 NAME

App::MadEye::Plugin::Agent::Sleep - every time timeout

=head1 DESCRIPTION

THIS MODULE IS ONLY FOR DEBUGGING.

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        sleep:
            required: yes
            type: int

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>

