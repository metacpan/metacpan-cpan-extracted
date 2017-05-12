package Fake::Loader;

use strict;
use warnings;

use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use IO::File;

my %options;
my $config = 't/_DBDIR/test-config.ini';

# -----------------------------------------------------------------------------
# Object methods

sub new {
	my $class = shift;

    return unless(-f $config);

	# create an attributes hash
	my $self = {};

	# create the object
	bless $self, $class;

    # preload databases
    $self->{CPANSTATS} = $self->config_db('CPANSTATS')  or return;
    $self->{TESTERS}   = $self->config_db('TESTERS')    or return;
    
    return $self;
}

sub delete_cpanstats {
    my ($self,@dbs) = @_;
    @dbs = qw(cpanstats ixlatest leaderboard release_summary uploads)   unless(@dbs);
    $self->{CPANSTATS}{dbh}->do_query("DELETE FROM $_") for(@dbs);
}

sub create_cpanstats {
    my $self = shift;

    # calculate dates
    my @date = localtime(time);
    my $THISMONTH = sprintf "%04d%02d", $date[4] > 0 ? ($date[5]+1900, $date[4])   : ($date[5]+1899, 12);
    my $LASTMONTH = sprintf "%04d%02d", $date[4] > 1 ? ($date[5]+1900, $date[4]-1) : ($date[5]+1899, 11 + $date[4]);

    for my $db (qw(cpanstats ixlatest leaderboard release_summary uploads passreports)) {
        my $fh = IO::File->new("t/data/$db.sql") or next;
        while(<$fh>) {
            s/(\s|;)*$//;
            s/LASTMONTH/$LASTMONTH/g;
            s/THISMONTH/$THISMONTH/g;

            $self->{CPANSTATS}{dbh}->do_query($_)   if($_);
        }
        $fh->close;
    }
}

sub delete_testers {
    my ($self,@dbs) = @_;
    @dbs = qw(profile address)   unless(@dbs);
    $self->{TESTERS}{dbh}->do_query("DELETE FROM $_")   for(@dbs);
}

sub create_testers {
    my $self = shift;

    for my $db (qw(profile address)) {
        my $fh = IO::File->new("t/data/$db.sql") or next;
        while(<$fh>) {
            s/(\s|;)*$//;
            $self->{TESTERS}{dbh}->do_query($_);
        }
        $fh->close;
    }
}

#----------------------------------------------------------------------------
# Test Functions

sub config_db {
    my ($self,$db) = @_;

    # load config file
    my $cfg = Config::IniFiles->new( -file => $config );

    # configure databases
    die "No configuration for $db database\n"   unless($cfg->SectionExists($db));
    my %opts = map {$_ => ($cfg->val($db,$_)||undef);} qw(driver database dbfile dbhost dbport dbuser dbpass);
    unlink $opts{database}  if($opts{driver} eq 'SQLite' && -f $opts{database});

    # need to store new configuration details here

    my $dbh = CPAN::Testers::Common::DBUtils->new(%opts);
    die "Cannot configure $db database\n" unless($dbh);

    my %hash = ( opts => \%opts, dbh => $dbh );
    return \%hash;
}

sub create_db {
    my $self = shift;
    my $type = shift || 0;

    if($type == 0) {
        $self->delete_cpanstats();
        $self->create_cpanstats();

        $self->delete_testers();
        $self->create_testers();
    }
    
    if($type > 0 && $type < 3) {
        $self->delete_cpanstats();
    }

    if($type > 1) {
        $self->delete_testers();
    }

    return 0;
}

sub count_cpanstats {
    my ($self,$state) = @_;
    my @rows;
    if($state) {
        @rows = $self->{CPANSTATS}{dbh}->get_query('array','SELECT * FROM cpanstats WHERE state=?',$state);
    } else {
        @rows = $self->{CPANSTATS}{dbh}->get_query('array','SELECT * FROM cpanstats');        
    }
#    diag(Dumper($_))    for(@rows);
    return scalar(@rows);
}

sub count_cpanstats_table {
    my ($self,$db) = @_;
    my @rows = $self->{CPANSTATS}{dbh}->get_query('array',"SELECT count(*) FROM $db");
    my $count = @rows ? $rows[0]->[0] : 0;
    return $count;
}

sub count_testers_table {
    my ($self,$db) = @_;
    my @rows = $self->{TESTERS}{dbh}->get_query('array',"SELECT count(*) FROM $db");
    my $count = @rows ? $rows[0]->[0] : 0;
    return $count;
}

1;
