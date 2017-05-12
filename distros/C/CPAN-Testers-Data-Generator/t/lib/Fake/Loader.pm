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
    $self->{CPANSTATS} = $self->config_db('CPANSTATS')    or return;
    $self->{METABASE}  = $self->config_db('METABASE')     or return;
    
    return $self;
}

sub delete_cpanstats {
    my $self = shift;
    $self->{CPANSTATS}{dbh}->do_query('DELETE FROM cpanstats');
}

sub create_cpanstats {
    my $self = shift;

    my $fh = IO::File->new("t/data/cpanstats.sql") or return 1;
    while(<$fh>) {
        s/(\s|;)*$//;
        $self->{CPANSTATS}{dbh}->do_query($_);
    }
    $fh->close;
}

sub delete_metabase {
    my $self = shift;
    $self->{METABASE}{dbh}->do_query('DELETE FROM metabase');
    $self->{METABASE}{dbh}->do_query('DELETE FROM testers_email');
}

sub create_metabase {
    my $self = shift;

    my $fh = IO::File->new("t/data/metabase.sql") or return 1;
    while(<$fh>) {
        s/(\s|;)*$//;
        $self->{METABASE}{dbh}->do_query($_);
    }
    $fh->close;

    $fh = IO::File->new("t/data/testers_email.sql") or return 1;
    while(<$fh>) {
        s/(\s|;)*$//;
        $self->{METABASE}{dbh}->do_query($_);
    }
    $fh->close;
}

sub create_uploads {
    my $self = shift;

    my $fh = IO::File->new("t/data/uploads.sql") or return 1;
    while(<$fh>) {
        s/(\s|;)*$//;
        $self->{CPANSTATS}{dbh}->do_query($_);
    }
    $fh->close;
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

        $self->delete_metabase();
        $self->create_metabase();
    }
    
    if($type > 0 && $type < 3) {
        $self->delete_cpanstats();
    }

    if($type > 1) {
        $self->delete_metabase();
    }

    return 0;
}

sub delete_metabase_id {
    my ($self,$id) = @_;
    my @rows = $self->{METABASE}{dbh}->get_query('array','SELECT * FROM metabase WHERE id = ?',$id);
    $self->{METABASE}{dbh}->do_query('DELETE FROM metabase WHERE id = ?',$id)    if(@rows);
}

sub count_metabase {
    my $self = shift;
    my @rows = $self->{METABASE}{dbh}->get_query('array','SELECT * FROM metabase');
#    diag(Dumper($_))    for(@rows);
    return scalar(@rows);
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

sub count_requests {
    my $self = shift;
    my @rows = $self->{CPANSTATS}{dbh}->get_query('array','SELECT * FROM page_requests');
#    diag(Dumper($_))    for(@rows);
    return scalar(@rows);
}

sub count_summaries {
    my $self = shift;
    my @rows = $self->{CPANSTATS}{dbh}->get_query('array','SELECT * FROM release_summary');
#    diag(Dumper($_))    for(@rows);
    return scalar(@rows);
}

sub count_releases {
    my $self = shift;
    my @rows = $self->{CPANSTATS}{dbh}->get_query('array','SELECT * FROM release_data');
#    diag(Dumper($_))    for(@rows);
    return scalar(@rows);
}

1;
