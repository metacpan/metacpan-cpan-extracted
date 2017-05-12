package App::MadEye::Plugin::Agent::MySQLSlave;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use DBI;

sub is_dead {
    my ($self, $dsn) = @_;

    App::MadEye->context->log('debug' => "watching $dsn");

    my $user     = $self->config->{config}->{user} or die "missing user";
    my $password = $self->config->{config}->{password};
    my $threshold = $self->config->{config}->{threshold} or die "missing threshold";

    my $dbh;
    eval {
        $dbh = DBI->connect(
            $dsn,
            $user,
            $password,
            { RaiseError => 1, AutoCommit => 1 }
        ) or return 'cannot connect';
    };
    if ($@) {
        return $@;
    }

    my $sth = $dbh->prepare(q{SHOW SLAVE STATUS;});
    $sth->execute() or return 'DBI error: ' . $dbh->errstr;

    if (my $row = $sth->fetchrow_hashref) {
        # see. http://dev.mysql.com/doc/refman/4.1/ja/show-slave-status.html

        if (my $le = $row->{'Last_Error'}) {
            return "replication error : $le\n";
        }

        if ( $row->{'Slave_IO_Running'} ne 'Yes' ) {
            return "Slave IO Not Running\n";
        }

        if ( $row->{'Slave_SQL_Running'} ne 'Yes' ) {
            return "Slave SQL Not Running\n";
        }

        my $rmlp = $row->{'Read_Master_Log_Pos'};
        my $emlp = $row->{'Exec_Master_Log_Pos'};
        if ( abs($rmlp - $emlp) > $threshold ) {
            return "considerable delay : $rmlp $emlp\n";
        }

        return; # alive!
    } else {
        return "this is not a slave!";
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::MySQLSlave - monitoring mysql slave.

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
            type: any
        threshold:
            required: yes
            type: int

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<DBI>, L<App::MadEye>

