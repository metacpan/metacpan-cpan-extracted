#!/usr/bin/perl -wT

use strict;
use warnings;

BEGIN { unshift @INC, ($ENV{'PERL5LIB'} =~ m/([^:]+)/g); }


use MyApp::Service::Scraper;
use Getopt::Long;

my ($opt_async, $opt_help);
my $no_args = (@ARGV == 0) ? 1 : 0;

GetOptions(
    "async" => \$opt_async,  # --async
    "help"  => \$opt_help,   # --help    
) or exit;

my @urls = @ARGV;

my $Help = "
Usage: client.pl [OPTIONS] [urls]
Extract titles from given urls

  -a, --async  process urls concurrently
  -h, --help   display this help and exit

Example:

  ./client.pl --async  https://cpan.org  https://perl.org
";

if ($opt_help || $no_args) {
    print $Help;
    exit;
}

if (!$opt_async) {

    foreach my $url (@urls) {

        # Using the synchronous client: urls will be processed one after another

        my $response = MyApp::Service::Scraper->get_title( $url );

        if ($response->success) {
            my $title = $response->result;
            print qq'\n$url\n"$title"\n';
        }
        else {
            print "\n$url\n". $response->code ." ". $response->message ."\n";
        }
    }
}
else {

    my $cv = AnyEvent->condvar;

    foreach my $url (@urls) {

        # Using the asynchronous client: urls will be processed concurrently

        $cv->begin;

        MyApp::Service::Scraper->get_title_async( $url, sub {
            my ($response) = @_;

            if ($response->success) {
                my $title = $response->result;
                print qq'\n$url\n"$title"\n';
            }
            else {
                print "\n$url\n". $response->code ." ". $response->message ."\n";
            }

            $cv->end;
        });
    }

    $cv->recv;
}
