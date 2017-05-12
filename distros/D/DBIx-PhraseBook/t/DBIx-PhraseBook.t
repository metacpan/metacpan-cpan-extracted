#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

use Data::Dumper;
use DBIx::PhraseBook;
use File::Temp qw(tempfile);
use Term::ReadLine;
use Term::ReadKey;

my $PROPSPREFIX="test.hosts.db";
my $DEFAULTPHRASEBOOK = "examples/test.xml";

$|=1;
ReadMode 'normal';
my $term = Term::ReadLine->new();
my $dsn = $term->readline("enter dsn: ");
my $username = $term->readline("enter username: ");
ReadMode 'noecho';
my $password = $term->readline("enter password(echo off): ");
ReadMode 'normal';
my $phrasebookfile = $term->readline("\nenter path to test phrasebook (follow template from $DEFAULTPHRASEBOOK): ");

if(!defined $phrasebookfile || $phrasebookfile eq ""){
    warn "default to default phrasebook $DEFAULTPHRASEBOOK\n";
    $phrasebookfile = $DEFAULTPHRASEBOOK;
};

print "\nattempt to connect with: dsn=$dsn username=$username pwd=".('*'x length($password))."\n";
my ($tempFile,$tempFileName) = tempfile();
{
    local $|;
    select TEMPFH;
    $|=1;
*TEMPFH = $tempFile;
print TEMPFH<<"EOF";
$PROPSPREFIX.dsn=$dsn
$PROPSPREFIX.username=$username
$PROPSPREFIX.password=$password
$PROPSPREFIX.phrasebooks.1.name=testphrases
$PROPSPREFIX.phrasebooks.1.path=$phrasebookfile
$PROPSPREFIX.phrasebooks.1.key=testdictionary
$PROPSPREFIX.phrasebooks.2.name=somethingelse
$PROPSPREFIX.phrasebooks.2.path=examples/another.xml
$PROPSPREFIX.phrasebooks.2.key=anotherkey
EOF
}
my %phraseBooks = DBIx::PhraseBook->load( $PROPSPREFIX, $tempFileName );

ok(keys %phraseBooks == 2 , "correct number of phrasebooks ".(scalar keys %phraseBooks) );

my DBIx::PhraseBook $phraseBook = $phraseBooks{testphrases};
die "could not load test phrasebook" unless defined $phraseBook;

ok(defined $phraseBook, "test phrasebook defined");

my $testtext = $phraseBook->fetch( "test.query" );
ok(defined $testtext,"got result from query <<$testtext>>");


my @queries = $phraseBook->getAllQueryNames();
ok(@queries,"getting all query names");

my $dbh = $phraseBook->getDbh();
ok($dbh,"db handle");

foreach my $queryName(@queries){
    my $sth = $phraseBook->prepare($queryName);
    ok(!$@ && ref $sth && !$sth->errstr(),"prepare $queryName");
    eval {
        $sth->execute();
    };
    ok(!$@,"execute $queryName".($@?$dbh->errstr():""));

};
