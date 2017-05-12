package App::MadEye::Plugin::Agent::Qudo::ExceptionLog;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use Qudo;

sub is_dead {
    my ($self, $dsn) = @_;

    my $conf     = $self->config->{config};
    my $user     = $conf->{user}     or die "missing user";
    my $password = $conf->{password} or die "missing password";

    my $qudo = Qudo->new(
        databases => [+{
            dsn      => $dsn,
            username => $user,
            password => $password,
        }],
    );

    my $exceptions = $qudo->exception_list;
    if (scalar(@{$exceptions->{$dsn}}) >= 1) {
        return 'qudo has exceptions...';
    } else {
        return; # alive.
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::Qudo::ExceptionLog - monitoring exception count of Qudo

=head1 SYNOPSIS

    - module: Agent::Qudo::ExceptionLog
      config:
        target:
           - DBI:mysql:database=foo
         user: root
         password: ~

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

=head1 SEE ALSO

L<Qudo>, L<App::MadEye>

=head1 REPOS

http://github.com/nekokak/App-MadEye-Plugin-Agent-Qudo

=head1 AUTHOR

Atsushi Kobayashi <nekokak _at_ gmail dot com>


