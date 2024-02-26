package Chess::ELO::FIDE;

use strict;
use warnings;

use Moo;
use DateTime;
use DateTime::Format::Mail;
use DateTime::Format::Strptime;
use DBI;
use DBD::SQLite;
use File::Spec::Functions;
use File::Temp qw/tempdir/;
use HTTP::Tiny;
use IO::Uncompress::Unzip qw/unzip $UnzipError/;
use Log::Handler;
use Types::Standard -types;

#------------------------------------------------------------------------------

our $VERSION = "0.01";

#------------------------------------------------------------------------------

has 'sqlite'     => ( is => 'ro', isa=> Str, required=> 1 );
has 'federation' => ( is => 'ro', isa=> Str, default=> sub { '' } );
has 'fide_url'   => ( is => 'ro', isa=> Str, default=> sub { 'https://ratings.fide.com/download/players_list.zip' } );
has 'log'        => ( is => 'rwp' );
has '_dbh'       => ( is => 'rwp', isa=> InstanceOf['DBI::db']);
has '_temp_dir'  => (is => 'rwp',  isa=> Str, default => '/tmp');

#------------------------------------------------------------------------------

sub BUILD {
    my $self = shift;
    my $dsn = "dbi:SQLite:dbname=" . $self->sqlite;
    my $dbh = DBI->connect($dsn, "", "", { RaiseError=>1, AutoCommit=>1 });
    $self->_set__dbh($dbh);
    $self->_set__temp_dir( tempdir(CLEANUP=> 1) );
    $self->_init_sqlite_;
}

#------------------------------------------------------------------------------

sub DEMOLISH {
    my $self = shift;
    $self->_dbh->disconnect;
}

#------------------------------------------------------------------------------

sub _trim_ {
    my $s = shift;
    $s =~ s/\s+$//;
    $s =~ s/^\s+//;
    return $s;
}
#------------------------------------------------------------------------------

sub _debug_ {
    my $self = shift;
    my $log = $self->log;
    $log->debug(shift) if $log;
}

#------------------------------------------------------------------------------

sub _db_property_ {
    my $self = shift;
    my $name = shift;

    if( @_ ) {
        my $value = shift;
        my $stmt = $self->_dbh->prepare("UPDATE properties SET value=? WHERE name=?");
        $stmt->execute($value, $name);
    } else {
        my ($value) = $self->_dbh->selectrow_array("SELECT value FROM properties WHERE name=?", undef, $name);
        return $value;
    }
}

#------------------------------------------------------------------------------

sub _init_sqlite_ {
    my $self = shift;
    my $dbh = $self->_dbh;
    
    my $sql_create_fide = <<~'SQL_FIDE';
    CREATE TABLE IF NOT EXISTS fide (
        fide_id   INTEGER PRIMARY KEY,
        fed       TEXT,
        gender    TEXT,
        title     TEXT,
        year      INTEGER,
        s_rating  INTEGER,
        r_rating  INTEGER,
        b_rating  INTEGER,
        s_k       INTEGER,
        r_k       INTEGER,
        b_k       INTEGER,
        s_games   INTEGER,
        r_games   INTEGER,
        b_games   INTEGER,
        surname   TEXT,
        name      TEXT,
        flag      TEXT
    );
    SQL_FIDE

    my $sql_create_properties = <<~'SQL_PROPERTIES';
    CREATE TABLE IF NOT EXISTS properties (
        name  TEXT PRIMARY KEY,
        value TEXT
    );
    SQL_PROPERTIES

    $dbh->do($sql_create_fide);
    $dbh->do($sql_create_properties);

    my ($last_date) = $dbh->selectrow_array("SELECT count(*) FROM properties WHERE name='last-modified'");
    if( ! $last_date ) {
        $dbh->do("INSERT INTO properties (name, value) VALUES ('last-modified', '1970-01-01T00:00:00Z')");
    }
}


#------------------------------------------------------------------------------

sub _load_combined_file_ {
    my $self         = shift;
    my $players_file = shift;

    my $dbh = $self->_dbh;
    my $sql_insert = <<~'SQL_INSERT';
    INSERT INTO fide (
        fide_id, 
        fed, 
        gender, 
        title, 
        year, 
        s_rating, r_rating, b_rating, 
        s_k, r_k, b_k, 
        s_games, r_games, b_games,
        surname, name,
        flag
    ) 
    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    SQL_INSERT

    my $stmt = $dbh->prepare($sql_insert);
    $dbh->begin_work;

    $dbh->do("DELETE FROM fide");

    open my $fh , '<', $players_file or die "Can't open file [$players_file]: $!";

    my $header = <$fh>;
    my $expected = 'ID Number      Name                                                         Fed Sex Tit  WTit OTit           FOA SRtng SGm SK RRtng RGm Rk BRtng BGm BK B-day Flag';

#ID Number      Name                                                         Fed Sex Tit  WTit OTit           FOA SRtng SGm SK RRtng RGm Rk BRtng BGm BK B-day Flag
    if( substr($header, 0, length($expected)) ne $expected) {
        $self->log->error("FIDE file format is not valid");
        return 0;
    }

    my $count = 0;
    while (my $line = <$fh>) {
        my $fed      = substr($line, 76, 3);
        next if ($self->federation && ($fed ne $self->federation));
        next if length($line) < 156;
        my $fide_id   = _trim_ substr($line, 0, 15);
        my $s_rating  = _trim_ substr($line, 113, 4);
        my $r_rating  = _trim_ substr($line, 126, 4);
        my $b_rating  = _trim_ substr($line, 139, 4);
        my $year      = _trim_ substr($line, 152, 4);
        my $gender    = _trim_ substr($line, 80, 1);
        my $title     = _trim_ substr($line, 84, 5);
        my $full_name = _trim_ substr($line, 15, 60);

        my ($surname, $name) = split(/ *, */, $full_name);

        $s_rating = undef if defined($s_rating) && ($s_rating eq '');
        $r_rating = undef if defined($r_rating) && ($r_rating eq '');
        $b_rating = undef if defined($b_rating) && ($b_rating eq '');
        
        my $s_K = _trim_ substr($line, 123, 2);
        my $r_K = _trim_ substr($line, 136, 2);
        my $b_K = _trim_ substr($line, 149, 2);
        $s_K = undef if defined($s_K) && ($s_K eq '');
        $r_K = undef if defined($r_K) && ($r_K eq '');
        $b_K = undef if defined($b_K) && ($b_K eq '');

        my $s_games = _trim_ substr($line, 119, 3);
        my $r_games = _trim_ substr($line, 132, 3);
        my $b_games = _trim_ substr($line, 145, 3);
        $s_games = undef if defined($s_games) && ($s_games eq '');
        $r_games = undef if defined($r_games) && ($r_games eq '');
        $b_games = undef if defined($b_games) && ($b_games eq '');

        my $flag = substr($line, 158, 4);
        $flag = undef if defined($flag) && ($flag eq '');

        $stmt -> execute(
                    $fide_id, 
                    $fed, 
                    $gender, 
                    $title, 
                    $year, 
                    $s_rating, $r_rating, $b_rating, 
                    $s_K,      $r_K,      $b_K,
                    $s_games,  $r_games,  $b_games,
                    uc($surname // ''), uc($name // ''),
                    $flag
        );
        $count++;
    }

    $dbh->commit;
    close $fh;
    return $count;
}

#------------------------------------------------------------------------------

sub load {
    my $self = shift;

    my $count = 0;
    my $strp = DateTime::Format::Strptime->new(pattern=> '%T');
    my $last_download = $self->_db_property_('last-modified');
    my $dt_last_modified = $strp->parse_datetime($last_download);   

    my $http = HTTP::Tiny->new;
    my $response = $http->head($self->fide_url);
    return 0 unless $response->{success};
    
    my $dt_fide_last_modified = DateTime::Format::Mail->parse_datetime($response->{'headers'}->{'last-modified'});

    if ( DateTime->compare( $dt_last_modified, $dt_fide_last_modified ) == 0 ) {
        $self->_debug_("No new ratings available from $last_download");
        return 0;
    }

    my $zip_file = catfile($self->_temp_dir, "fide_players_list.zip");
    my $players_file = catfile($self->_temp_dir, "players_list_foa.txt");
    
    unlink $zip_file if -e $zip_file;
    unlink $players_file if -e $players_file;
    
    $self->_debug_("download: " . $self->fide_url . " => $zip_file");
    $response = $http->mirror($self->fide_url, $zip_file);
    if( $response->{success} ) {
        $self->_debug_("unzip: $zip_file [$dt_fide_last_modified]");
        
        unzip($zip_file => $players_file);
        if (-e $players_file) {
            $self->_debug_("OK: $players_file [" . $dt_fide_last_modified->iso8601 ."]");
            $count = $self->_load_combined_file_($players_file);
            $self->_db_property_('last-modified', $strp->format_datetime($dt_fide_last_modified)) if $count;
        }    
    }
    return $count;
}

#------------------------------------------------------------------------------

1;

__END__

=encoding utf-8

=head1 NAME

Chess::ELO::FIDE - Download and store FIDE ratings

=head1 SYNOPSIS

    use Chess::ELO::FIDE;
    my $ratings = Chess::ELO::FIDE->new(
                    federation=> 'ESP',
                    sqlite    => 'elo.sqlite'
    );
    my $count = $ratings->load;
    print "Loaded $count players\n";

=head1 DESCRIPTION

Chess::ELO::FIDE is a module to download and store FIDE ratings in a SQLite database.
It is intended to be used as a backend for chess applications.
There are 3 main phases:

=over 4

=item 1. Download the FIDE ratings file from the L<FIDE website|https://ratings.fide.com/download/players_list.zip>

=item 2. Unzip the file and load the ratings into a SQLite database

=item 3. Store the last download date to avoid downloading the same file again

=back

=head1 LICENSE

Copyright (C) Miguel PRZ - NICEPERL

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

NICEPERL L<https://metacpan.org/author/NICEPERL>

=cut

