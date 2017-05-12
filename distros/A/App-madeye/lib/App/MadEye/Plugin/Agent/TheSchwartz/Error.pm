package App::MadEye::Plugin::Agent::TheSchwartz::Error;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use DBI;

sub is_dead {
    my ($self, $dsn) = @_;

    my $conf = $self->config->{config};
    my $user     = $conf->{user}     or die "missing user";
    my $password = $conf->{password} || '';

    my $dbh;
    eval {
        $dbh = DBI->connect(
            $dsn,
            $user,
            $password,
            {RaiseError => 1, AutoCommit => 1}
        );
    };

    if ($@) {
        return $@;
    } else {
        my ($cnt) = $dbh->selectrow_array(q{select count(*) from error});
        if ($cnt > 0) {
            return "error count: $cnt";
        } else {
            return; # alive
        }
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::TheSchwartz::Error - monitoring error count of TheSchwartz

=head1 SYNOPSIS

    - module: Agent::DBI
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

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<DBI>, L<App::MadEye>


