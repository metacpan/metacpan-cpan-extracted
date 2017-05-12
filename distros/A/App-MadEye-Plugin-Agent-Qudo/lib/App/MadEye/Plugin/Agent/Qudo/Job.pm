package App::MadEye::Plugin::Agent::Qudo::Job;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Qudo;

sub is_dead {
    my ($self, $dsn) = @_;

    my $conf      = $self->config->{config};
    my $user      = $conf->{user}      or die "missing user";
    my $password  = $conf->{password}  or die "missing password";
    my $threshold = $conf->{threshold} or die "missing threshold";

    my $qudo = Qudo->new(
        databases => [+{
            dsn      => $dsn,
            username => $user,
            password => $password,
        }],
    );

    my $job_count = $qudo->job_count;
    if ($job_count->{$dsn} >= $threshold) {
        return sprintf(q{qudo has many job '%s': %s count.}, $dsn, $job_count->{$dsn});                                                                                                                           
    } else {
        return; # alive.
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::Qudo::Job - monitoring job count of Qudo

=head1 SYNOPSIS

    - module: Agent::Qudo::Job
      config:
        target:
           - DBI:mysql:database=foo
        user: root
        password: ~
        threshold: 1000

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        user:
            required: yes
            type: str
        password:
            required: yes
            type: str
        threshold:
            required: yes
            type: int

=head1 SEE ALSO

L<Qudo>, L<App::MadEye>

=head1 REPOS

http://github.com/nekokak/App-MadEye-Plugin-Agent-Qudo

=head1 AUTHOR

Atsushi Kobayashi <nekokak _at_ gmail dot com>

