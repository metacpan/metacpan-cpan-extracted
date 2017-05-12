# Iterator version of Brackup::Dict::SQLite - slower, but lighter on memory

package Brackup::Dict::SQLite2;
use strict;
use warnings;
use DBI;
use DBD::SQLite;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        table => $opts{table},
        file  => $opts{file},
    }, $class;

    my $dbh = $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$opts{file}","","", { RaiseError => 1, PrintError => 0 }) or
        die "Failed to connect to SQLite filesystem digest cache database at $opts{file} " . DBI->errstr;

    eval {
        $dbh->do("CREATE TABLE $opts{table} (key TEXT PRIMARY KEY, value TEXT)");
    };
    die "Error: $@" if $@ && $@ !~ /table \w+ already exists/;

    $self->{get_sth} = $self->{dbh}->prepare("SELECT value FROM $self->{table} WHERE key = ?");

    return $self;
}

sub get {
    my ($self, $key) = @_;
    $self->{get_sth}->bind_param(1, $key);
    $self->{get_sth}->execute;
    my ($val) = $self->{get_sth}->fetchrow_array;
    return $val;
}

sub set {
    my ($self, $key, $val) = @_;
    $self->{dbh}->do("REPLACE INTO $self->{table} VALUES (?,?)", undef, $key, $val);
    return 1;
}

# Iterator interface, returning ($key, $value), and () on eod
sub each {
    my $self = shift;
    if (! $self->{each_sth}) {
        $self->{each_sth} = $self->{dbh}->prepare("SELECT key, value from $self->{table}");
        $self->{each_sth}->execute;
    }
    my ($k, $v) = $self->{each_sth}->fetchrow_array;
    return wantarray ? ($k, $v) : $k if defined $k;
    return wantarray ? () : undef;
}

sub delete {
    my ($self, $key) = @_;
    $self->{dbh}->do("DELETE FROM $self->{table} WHERE key = ?", undef, $key);
    return 1;
}

sub count {
    my $self = shift;
    my ($count) = $self->{dbh}->selectrow_array("SELECT COUNT(key) FROM $self->{table}");
    return $count;
}

sub backing_file {
    my $self = shift;
    return $self->{file};
}

1;

=head1 NAME

Brackup::Dict::SQLite2 - key-value dictionary implementation, using a 
SQLite database for storage (lighter/slower version of 
Brackup::Dict::SQLite)

=head1 DESCRIPTION

Brackup::Dict::SQLite2 implements a simple key-value dictionary using
a SQLite database for storage. Brackup::Dict::SQLite2 is identical to 
L<Brackup::Dict::SQLite> (so see that for more details), but it uses 
conventional database cursors/iterators for all operations, instead of 
pre-loading the entire database into memory. As such, it is slightly 
slower than Brackup::Dict::SQLite, but uses much less memory.

See L<Brackup::DigestCache> and L<Brackup::InventoryDatabase> for
how to manually specify the dictionary class to use.

=head1 SEE ALSO

L<brackup>

L<Brackup>

L<Brackup::Dict::SQLite>

=cut
