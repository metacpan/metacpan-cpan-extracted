package DBIx::QuickDB::Driver::DuckDB;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;
use Scalar::Util qw/reftype/;

our $VERSION = '0.000048';

use parent 'DBIx::QuickDB::Driver';

use DBIx::QuickDB::Util::HashBase qw{-duckdb -started};

my ($DUCKDB, $DBDDUCKDB);

BEGIN {
    local $@;

    $DUCKDB = can_run('duckdb');
    $DBDDUCKDB = eval { require DBD::DuckDB; 'DBD::DuckDB' };
}

sub version_string {
    my $binary;

    # Go in reverse order assuming the last param hash provided is most important
    for my $arg (reverse @_) {
        my $type = reftype($arg) or next;    # skip if not a ref
        next unless $type eq 'HASH';         # We have a hashref, possibly blessed

        # If we find a launcher we are done looping, we want to use this binary.
        $binary = $arg->{+DUCKDB} and last;
    }

    # If no args provided one to use we fallback to the default from $PATH
    $binary ||= $DUCKDB;

    return 'unknown' unless $binary;

    # Call the binary with '--version', capturing and returning the output using backticks.
    return `$binary --version`;
}

sub _default_paths { return (duckdb => $DUCKDB) }

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my %check = (ref($this) ? %$this : (), $this->_default_paths, %$spec);

    my @bad;
    push @bad => "'DBD::DuckDB' module could not be loaded, needed for connecting" unless $DBDDUCKDB;
    push @bad => "'duckdb' command is missing, needed for loading SQL"              unless $check{+DUCKDB};

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

    require DBD::DuckDB;
    return "dbi:DuckDB:dbname=$path";
}

sub load_sql {
    my $self = shift;
    my ($db_name, $file) = @_;

    my $dir = $self->{+DIR};
    my $path = "$dir/$db_name";

    # DBD::DuckDB cannot prepare multiple statements in one do(); the CLI reads
    # statements from STDIN, so pipe the file through it.
    $self->run_command([$self->{+DUCKDB}, $path], {stdin => $file});
}

sub shell_command {
    my $self = shift;
    my ($db_name) = @_;

    my $dir = $self->{+DIR};
    my $path = "$dir/$db_name";

    return ($self->{+DUCKDB}, $path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver::DuckDB - DuckDB driver for DBIx::QuickDB.

=head1 DESCRIPTION

DuckDB driver for L<DBIx::QuickDB>. DuckDB is an embedded engine (a file, no
server process), so this driver is architecturally identical to the SQLite
driver: C<start>/C<stop>/C<bootstrap> are no-ops and the database lives in a
file under the QuickDB directory.

=head1 REQUIREMENTS

=over 4

=item L<DBD::DuckDB>

Required for connecting to the database.

=item The C<duckdb> CLI on C<$PATH>

Required for C<load_sql>. DBD::DuckDB cannot prepare multiple statements at
once, so SQL files are piped through the CLI which handles multi-statement
input.

=back

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
