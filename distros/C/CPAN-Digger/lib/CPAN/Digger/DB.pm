package CPAN::Digger::DB;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.04';

use DBI;
use Exporter qw(import);
use File::HomeDir ();
use FindBin ();
use Path::Tiny qw(path);

our @EXPORT_OK = qw(get_fields);

my @fields = qw(distribution version author date vcs_url vcs_name travis github_actions appveyor circleci has_ci licenses issues azure_pipeline gitlab_pipeline);
sub get_fields {
    return @fields;
}


sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;
    for my $key (keys %args) {
        $self->{$key} = $args{$key};
    }

    my $dbh = $self->{dbh} = $self->get_db();
    $self->{sth_get_distro} = $dbh->prepare('SELECT * FROM dists WHERE distribution=?');
    $self->{sth_get_every_distro} = $dbh->prepare('SELECT * FROM dists ORDER by date DESC');
    my $fields = join ', ', @fields;
    my $places = join ', ', ('?') x scalar @fields;
    $self->{sth_insert} = $dbh->prepare("INSERT INTO dists ($fields) VALUES ($places)");
    $self->{sth_delete} = $dbh->prepare("DELETE FROM dists WHERE distribution=?");
    return $self;
}


sub get_db {
    my ($self) = @_;

    # Default to in-memory database
    my $db_file = ':memory:';
    my $exists = undef;

    if ($self->{db}) {
        $db_file = $self->{db};
        $exists = -e $db_file;
    }
    my $dbh = DBI->connect( "dbi:SQLite:dbname=$db_file", "", "", {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
        FetchHashKeyName => 'NAME_lc',
    });
    if (not $exists) {
        local $/ = undef;
        my $schema = <DATA>;
        $dbh->do($schema);
    }
    return $dbh
}

sub db_insert_into {
    my ($self, @params) = @_;
    $self->{sth_insert}->execute(@params);
}

# TODO have an update here?
sub db_update {
    my ($self, $distribution, @params) = @_;
    $self->{sth_delete}->execute($distribution);
    $self->{sth_insert}->execute(@params);
}


sub db_get_distro {
    my ($self, $distribution) = @_;

    $self->{sth_get_distro}->execute($distribution);
    my $row = $self->{sth_get_distro}->fetchrow_hashref;
    return $row;
}

sub db_get_every_distro {
    my ($self) = @_;

    $self->{sth_get_every_distro}->execute;
    my @distros;
    while (my $row = $self->{sth_get_every_distro}->fetchrow_hashref) {
        push @distros, $row;
    }
    return \@distros;
}

sub get_distro_count {
    my ($self, $start_date, $end_date) = @_;

    my $sth = $self->{dbh}->prepare('SELECT COUNT(*) FROM dists WHERE date >= ? AND date < ?');
    $sth->execute($start_date, $end_date);
    my ($total) = $sth->fetchrow_array;
    return $total;
}

sub get_author_count {
    my ($self, $start_date, $end_date) = @_;

    my $sth = $self->{dbh}->prepare('SELECT COUNT(DISTINCT(author)) FROM dists WHERE date >= ? AND date < ?');
    $sth->execute($start_date, $end_date);
    my ($total) = $sth->fetchrow_array;
    return $total;
}

sub get_vcs_count {
    my ($self, $start_date, $end_date) = @_;

    my $sth = $self->{dbh}->prepare('SELECT COUNT(*) FROM dists WHERE vcs_name IS NOT NULL AND date >= ? AND date < ?');
    $sth->execute($start_date, $end_date);
    my ($total) = $sth->fetchrow_array;
    return $total;
}

sub get_ci_count {
    my ($self, $start_date, $end_date) = @_;

    my $sth = $self->{dbh}->prepare('SELECT COUNT(*) FROM dists WHERE has_ci IS NOT NULL AND date >= ? AND date < ?');
    $sth->execute($start_date, $end_date);
    my ($total) = $sth->fetchrow_array;
    return $total;
}


42;

__DATA__
CREATE TABLE dists (
    distribution VARCHAR(255) NOT NULL UNIQUE,
    date         VARCHAR(255),
    version      VARCHAR(255),
    author       VARCHAR(255),
    licenses     VARCHAR(255),
    issues       VARCHAR(255),
    vcs_url      VARCHAR(255),
    vcs_name     VARCHAR(255),
    appveyor         BOOLEAN,
    circleci         BOOLEAN,
    travis           BOOLEAN,
    github_actions   BOOLEAN,
    azure_pipeline   BOOLEAN,
    gitlab_pipeline  BOOLEAN,
    has_ci           BOOLEAN
);
