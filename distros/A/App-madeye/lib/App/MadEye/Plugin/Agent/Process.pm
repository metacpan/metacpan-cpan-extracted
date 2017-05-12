package App::MadEye::Plugin::Agent::Process;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Net::SSH qw/ssh_cmd/;

sub is_dead {
    my ($self, $host) = @_;

    my $conf = $self->config->{config};
    my $pattern = $conf->{pattern} or die "missing pattern";

    my @result = split /\n/, ssh_cmd($host, "/usr/bin/pgrep -f $pattern");

    if (scalar(@result) == 0) {
        return "$pattern not found";
    } else {
        return;
    }
}
  
1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::Process - monitoring process

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        pattern:
            required: yes
            type: str

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<pgrep>, L<App::MadEye>

