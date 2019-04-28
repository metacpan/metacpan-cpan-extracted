package DBIx::QuickDB::Driver::SQLite;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;

our $VERSION = '0.000008';

use parent 'DBIx::QuickDB::Driver';

use DBIx::QuickDB::Util::HashBase qw{-sqlite};

my ($SQLITE, $DBDSQLITE);

BEGIN {
    local $@;

    $SQLITE = can_run('sqlite3');
    $DBDSQLITE = eval { require DBD::SQLite; 'DBD::SQLite' };
}

sub _default_paths { return (sqlite => $SQLITE) }

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my %check = (ref($this) ? %$this : (), $this->_default_paths, %$spec);

    my @bad;
    push @bad => "'DBD::SQLite' module could not be loaded, needed for everything" unless $DBDSQLITE;

    return (1, undef) unless @bad;
    return (0, join "\n" => @bad);
}

sub init {
    my $self = shift;
    $self->SUPER::init();

    my %defaults = $self->_default_paths;
    $self->{$_} ||= $defaults{$_} for keys %defaults;

    return;
}

sub bootstrap { return }
sub start     { return }
sub stop      { return }

sub connect_string {
    my $self = shift;
    my ($db_name) = @_;
    $db_name = 'quickdb' unless defined $db_name;

    my $dir = $self->{+DIR};
    my $path = "$dir/$db_name";

    require DBD::SQLite;
    return "dbi:SQLite:dbname=$path";
}

sub load_sql {
    my $self = shift;
    my ($db_name, $file) = @_;

    my $dbh = $self->connect($db_name, sqlite_allow_multiple_statements => 1, RaiseError => 1, AutoCommit => 1);

    open(my $fh, '<', $file) or die "Could not open file '$file': $!";
    my $sql = join "" => <$fh>;
    close($fh);

    $dbh->do($sql) or die $dbh->errstr;
}

sub shell_command {
    my $self = shift;
    my ($db_name) = @_;

    my $dir = $self->{+DIR};
    my $path = "$dir/$db_name";

    return ($self->{+SQLITE}, $path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver::SQLite - SQLite driver for DBIx::QuickDB.

=head1 DESCRIPTION

SQLite driver for L<DBIx::QuickDB>.

=head1 SYNOPSIS

See L<DBIx::QuickDB>.

=head1 SOURCE

The source code repository for DBIx-QuickDB can be found at
F<https://github.com/exodist/DBIx-QuickDB/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2018 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
