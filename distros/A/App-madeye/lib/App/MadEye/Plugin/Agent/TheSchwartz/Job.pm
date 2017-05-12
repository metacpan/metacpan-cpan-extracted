package App::MadEye::Plugin::Agent::TheSchwartz::Job;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;

use DBI;

sub is_dead {
    my ($self, $dsn) = @_;

    my $conf = $self->config->{config};
    my $user     = $conf->{user}     or die "missing user";
    my $password = $conf->{password} || '';
    my $threshold = $conf->{threshold} or die "missing threshold";

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
        my ($cnt) = $dbh->selectrow_array(q{select count(*) from job});
        if ($cnt > $threshold) {
            return "job count: $cnt";
        } else {
            return; # alive
        }
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::TheSchwartz::Job - monitoring error count of TheSchwartz

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
        threshold:
            required: yes
            type: int

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<DBI>, L<App::MadEye>


