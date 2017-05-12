#!/usr/bin/perl

use CGI::MakeItStatic;
use CGI;

my $q = new CGI;
my $check = CGI::MakeItStatic->check
  (
   $q,
   {
    dir => "/tmp/CGI-MakeItStatic",
    keys => [qw/month/],
    noprint => $ARGV[0],
    name  =>
    sub
    {
      my($q) = @_;
      return sprintf("month=%02d", $q->param('month'))
    },
    forbid =>
    sub {
      my($q) = @_;
      return ($q->param('month') == 1) or $q->param('month') < 0;
    },
    forbidrenew =>
    sub {
      my($q) = @_;
      return $q->param('month') == 2 or $q->param('month') < 0;
    }
   }
  );

unless($ARGV[0] == 2 or $check){
  exit;
}

print "This will be made static.\n";
print "hoge=". $q->param("hoge"), "\n";
print "month=". $q->param("month"), "\n";
print "times=" . $q->param("times"), "\n";
print time;

if(defined $ARGV[0] and $ARGV[0] == 2){
  $check->end;
  print $check->output;
}

