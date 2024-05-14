package DBIx::QuickDB::Driver::SQLite;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;
use Scalar::Util qw/reftype/;

our $VERSION = '0.000033';

use parent 'DBIx::QuickDB::Driver';

use DBIx::QuickDB::Util::HashBase qw{-sqlite -started};

my ($SQLITE, $DBDSQLITE);

BEGIN {
    local $@;

    $SQLITE = can_run('sqlite3');
    $DBDSQLITE = eval { require DBD::SQLite; 'DBD::SQLite' };
}

sub version_string {
    my $binary;

    # Go in reverse order assuming the last param hash provided is most important
    for my $arg (reverse @_) {
        my $type = reftype($arg) or next;    # skip if not a ref
        next unless $type eq 'HASH';         # We have a hashref, possibly blessed

        # If we find a launcher we are done looping, we want to use this binary.
        $binary = $arg->{+SQLITE} and last;
    }

    # If no args provided one to use we fallback to the default from $PATH
    $binary ||= $SQLITE;

    # Call the binary with '-V', capturing and returning the output using backticks.
    return `$binary -version`;
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

    $self->{+STARTED} = 1;

    return;
}

sub bootstrap { return }
sub start     { return }
sub stop      { return }

sub clone {
    my $self = shift;

    local $self->{+STARTED} = 0;

    return $self->SUPER::clone(@_);
}

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

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
