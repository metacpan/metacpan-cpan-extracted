#!/usr/bin/perl -w
use strict;

use IO::File;
use CPAN::Testers::Common::Article;

# read report
my $article = readfile('t/nntp/126015.txt');
my $a = CPAN::Testers::Common::Article->new($article);

$a->parse_report();

if($a->passed)      { print "PASS:" }
elsif($a->failed)   { print "FAIL:" }
else                { print "OTHER:" }

print join(',',
        $a->from,           # 'Jost.Krieger+perl@rub.de (Jost Krieger+Perl)'
        $a->postdate,       # '200403'
        $a->date,           # '200403081025'
        $a->status,         # 'PASS'
        $a->distribution,   # 'AI-Perceptron'
        $a->version,        # '1.0'
        $a->perl,           # '5.8.3'
        $a->osname,         # 'solaris'
        $a->osvers,         # '2.8'
        $a->archname);      # 'sun4-solaris-thread-multi'

sub readfile {
    my $file = shift;
    my $text;
    my $fh = IO::File->new($file)   or return;
    while(<$fh>) { $text .= $_ }
    $fh->close;
    return $text;
}
