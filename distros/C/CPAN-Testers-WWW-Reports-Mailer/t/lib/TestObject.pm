package TestObject;

use strict;
use warnings;

use CPAN::Testers::WWW::Reports::Mailer;
use File::Path;
use File::Basename;

my %phrasebook = (
    'LastReport'        => "SELECT MAX(id) FROM cpanstats",
    'GetEarliest'       => "SELECT id FROM cpanstats WHERE fulldate > ? ORDER BY id LIMIT 1",

    'FindAuthorType'    => "SELECT pauseid FROM prefs_distributions WHERE report = ?",

    'GetReports'        => "SELECT id,guid,dist,version,platform,perl,state FROM cpanstats WHERE id > ? AND state IN ('pass','fail','na','unknown') ORDER BY id",
    'GetReports2'       => "SELECT c.id,c.guid,c.dist,c.version,c.platform,c.perl,c.state FROM cpanstats AS c INNER JOIN ixlatest AS x ON x.dist=c.dist WHERE c.id > ? AND c.state IN ('pass','fail','na','unknown') AND author IN (%s) ORDER BY c.id",
    'GetReportCount'    => "SELECT id FROM cpanstats WHERE platform=? AND perl=? AND state=? AND id < ? AND dist=? AND version=? LIMIT 2",
    'GetLatestDistVers' => "SELECT version FROM uploads WHERE dist=? ORDER BY released DESC LIMIT 1",
    'GetAuthor'         => "SELECT author FROM uploads WHERE dist=? AND version=? LIMIT 1",
    'GetAuthors'        => "SELECT author,dist,version FROM uploads",

    'GetAuthorPrefs'    => "SELECT * FROM prefs_authors WHERE pauseid=?",
    'GetDefaultPrefs'   => "SELECT * FROM prefs_authors AS a INNER JOIN prefs_distributions AS d ON d.pauseid=a.pauseid AND d.distribution='-' WHERE a.pauseid=?",
    'GetDistPrefs'      => "SELECT * FROM prefs_distributions WHERE pauseid=? AND distribution=?",
    'InsertAuthorLogin' => 'INSERT INTO prefs_authors (active,lastlogin,pauseid) VALUES (1,?,?)',
    'InsertDistPrefs'   => "INSERT INTO prefs_distributions (pauseid,distribution,ignored,report,grade,tuple,version,patches,perl,platform) VALUES (?,?,0,1,'FAIL','FIRST','LATEST',0,'ALL','ALL')",

    'GetArticle'        => "SELECT * FROM articles WHERE id=?",

    'GetReportTest'     => "SELECT id,guid,dist,version,platform,perl,state FROM cpanstats WHERE id = ? AND state IN ('pass','fail','na','unknown') ORDER BY id",

    'GetMetabaseByGUID' => 'SELECT * FROM metabase WHERE guid=?',
    'GetTestersEmail'   => 'SELECT * FROM testers_email',
    'GetTesters'        => 'SELECT * FROM testers_email ORDER BY id'
);

sub load {
    my ($class,%opts) = @_;
    $opts{config} ||= 't/_DBDIR/preferences.ini';

    %CPAN::Testers::WWW::Reports::Mailer::phrasebook = %phrasebook;
    my $self = CPAN::Testers::WWW::Reports::Mailer->new(%opts);

    return $self;
}

sub mail_check {
    my ($file1,$file2) = @_;
    my $mail1 = readfile($file1);
    my $mail2 = readfile($file2);

    # remove sponsor block
    my $state = 0;
    my @lines;
    for my $line (@$mail1) {
        $state = 1 if($line =~ /^Thanks,/);
        $state = 2 if($line =~ /^The CPAN Testers/);
        $state = 0 if($line =~ /^--/);

        push @lines, $line unless($state == 3);

        $state = 3 if($state == 2);
    }

    $mail1 = \@lines;

    return ($mail1,$mail2);
}

sub readfile {
    my $file = shift;
    my @text;
    my $fh = IO::File->new($file,'r') or die "Cannot open file [$file]: $!\n";
    while(<$fh>) { 
        next    if(/^Date:/);
        push @text, $_ 
    }
    $fh->close;
    return \@text;
}

1;
