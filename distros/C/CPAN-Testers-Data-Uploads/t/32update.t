#!/usr/bin/perl -w
use strict;

# testing the update process

use CPAN::Testers::Data::Uploads;
use Test::More;

#----------------------------------------------------------------------------
# Prepare Mock Conditions

my ($nomock,$mock1);

BEGIN {
    eval "use Test::MockObject";
    $nomock = $@;

    unless($nomock) {
        $mock1 = Test::MockObject->new();
        $mock1->fake_module( 'Net::NNTP',
                    'group'     =>  \&mock_group,
                    'article'   =>  \&mock_article );
        $mock1->fake_new( 'Net::NNTP' );
        $mock1->mock( 'group',      \&mock_group );
        $mock1->mock( 'article',    \&mock_article );
    }
}

if($nomock) {
    plan skip_all => 'generate tests require Test::MockObject';
} else {
    plan tests => 12;
}

#----------------------------------------------------------------------------

my $config = 't/_DBDIR/test-config.ini';
my $idfile = 't/_DBDIR/lastid.txt';

my %articles = (
    1 => 't/nntp/31085.txt',    # already inserted (should just overwrite)
    2 => 't/nntp/13394.txt',
    3 => 't/nntp/72870.txt',
    4 => 't/nntp/34358.txt',
);

SKIP: {
    skip "Test::Database required for DB testing", 12 unless(-f $config);

    my $obj;
    eval { $obj = CPAN::Testers::Data::Uploads->new( config => $config, update => 1 ) };
    isa_ok($obj,'CPAN::Testers::Data::Uploads');

    SKIP: {
        skip "Problem creating object", 11 unless($obj);

        my $dbh = $obj->uploads;
        ok($dbh);

        is(lastid(),0,'.. lastid is 0 from start');

        my @rows = $dbh->get_query('hash','select count(*) as count from uploads');
        is($rows[0]->{count}, 63, "row count for uploads");
        @rows = $dbh->get_query('hash','select count(*) as count from ixlatest');
        is($rows[0]->{count}, 17, "row count for ixlatest");

        $obj->process;

        is(lastid(),72870,'.. lastid is updated after process');

        @rows = $dbh->get_query('hash','select count(*) as count from uploads');
        is($rows[0]->{count}, 66, "row count for uploads");
        @rows = $dbh->get_query('hash','select count(*) as count from ixlatest');
        is($rows[0]->{count}, 18, "row count for ixlatest");
        @rows = $dbh->get_query('hash','select count(*) as count from page_requests');
        is($rows[0]->{count}, 16, "row count for page_requests");
        @rows = $dbh->get_query('hash','select * from ixlatest where dist=?','Acme-CPANAuthors-French');
        is($rows[0]->{version}, '0.07', "old index version not overwritten");
        @rows = $dbh->get_query('hash','select * from ixlatest where dist=?','Acme-CPANAuthors-Japanese');
        is($rows[0]->{version}, '0.090911', "old index version");
        @rows = $dbh->get_query('hash','select * from ixlatest where dist=?','CPAN-Testers-Data-Uploads');
        is($rows[0]->{version}, '0.12', "new index version");
    }
}

sub lastid {
    my $lastid = 0;

    if(-f $idfile) {
        if(my $fh = IO::File->new($idfile,'r')) {
            my @lines = <$fh>;
            ($lastid) = $lines[0] =~ /(\d+)/;
            $fh->close;
        }
    }

    return $lastid;
}

sub mock_group {
    return(4,13394,72870);
}

sub mock_article {
    my ($self,$id) = @_;
    my @text;

    return \@text   unless($articles{$id});

    my $fh = IO::File->new($articles{$id}) or return \@text;
    while(<$fh>) { push @text, $_ }
    $fh->close;

    return \@text;
}
