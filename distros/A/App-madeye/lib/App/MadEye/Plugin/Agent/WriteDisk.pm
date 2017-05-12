package App::MadEye::Plugin::Agent::WriteDisk;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Net::SSH qw/ssh_cmd/;

sub is_dead {
    my ($self, $host) = @_;

    my $conf = $self->config->{config};
    my $fname = $conf->{filename} or die "missing filename";

    my @result = split /\n/, ssh_cmd($host, "/bin/touch $fname && /bin/rm $fname");

    if (scalar(@result) == 0) {
        return; # ok
    } else {
        return join("\n", @result);
    }
}
  
1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::WriteDisk - is this disk writable?

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        filename:
            required: yes
            type: str

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<pgrep>, L<App::MadEye>

