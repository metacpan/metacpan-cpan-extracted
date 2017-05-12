use strict;
use warnings;

use Test::More tests => 8;

use Brat::Handler;
use Brat::Handler::File;

my $bratfile = Brat::Handler::File->new();
ok( defined($bratfile) && ref $bratfile eq 'Brat::Handler::File',     'Brat::Handler::File->new() works' );

$bratfile = Brat::Handler::File->new("examples/taln-2012-long-001-resume.ann");
ok( defined($bratfile) && ref $bratfile eq 'Brat::Handler::File',     'Brat::Handler::File->new(taln-2012-long-001-resume.ann) works' );

my $ann = $bratfile->getAnnotationList;
#print STDERR "\n$ann\n" . scalar(split /\n/, $ann) . "\n";

ok((defined $ann) && (scalar(split /\n/, $ann) == 21), "getAnnotationList works");
# $bratfile->print('-');

$bratfile = Brat::Handler::File->new("examples/taln-2012-long-002-resume.ann");
ok( defined($bratfile) && ref $bratfile eq 'Brat::Handler::File',     'Brat::Handler::File->new(taln-2012-long-002-resume.ann) works' );

$ann = $bratfile->getAnnotationList;
#print STDERR "\n$ann\n" . scalar(split /\n/, $ann) . "\n";

ok((defined $ann) && (scalar(split /\n/, $ann) == 48), "getAnnotationList works");
# $bratfile->print('-');

my $termList = $bratfile->getTermList;
ok((defined $termList) && (scalar(split /\n/, $termList) == 36), "getTermList works");
# $bratfile->printTermList("-");

my $relationList = $bratfile->getRelationList;
ok((defined $relationList) && (scalar(split /\n/, $relationList) == 11), "getRelationList works");
# $bratfile->printRelationList("-");

my $stats = $bratfile->getStats;
ok((defined $stats) && (scalar(split /\n/, $stats) == 6), "getStats works");
# $bratfile->printStats("-");

