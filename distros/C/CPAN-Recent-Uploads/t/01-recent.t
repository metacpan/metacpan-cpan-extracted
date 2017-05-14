use strict;
use warnings;

BEGIN {

$|=1;
require YAML::XS;
my @data = qw(
id/A/AA/AAU/MRIM/CHECKSUMS
id/A/AA/AAU/MRIM/Net-MRIM-1.10.meta
id/A/AA/AAU/MRIM/Net-MRIM-1.10.tar.gz
id/A/AD/ADAMK/CHECKSUMS
id/A/AD/ADAMK/ORLite-1.17.meta
id/A/AD/ADAMK/ORLite-1.17.readme
id/A/AD/ADAMK/ORLite-1.17.tar.gz
id/A/AD/ADAMK/Test-NeedsDisplay-1.06.meta
id/A/AD/ADAMK/Test-NeedsDisplay-1.06.readme
id/A/AD/ADAMK/Test-NeedsDisplay-1.06.tar.gz
id/A/AD/ADAMK/Test-NeedsDisplay-1.07.meta
id/A/AD/ADAMK/Test-NeedsDisplay-1.07.readme
id/A/AD/ADAMK/Test-NeedsDisplay-1.07.tar.gz
id/A/AD/ADAMK/YAML-Tiny-1.36.meta
id/A/AD/ADAMK/YAML-Tiny-1.36.readme
id/A/AD/ADAMK/YAML-Tiny-1.36.tar.gz
id/J/JO/JONATHAN/Perl6/NativeCall-v1.tar.gz
);

my $yaml = YAML::XS::Dump( { recent => [ map { { path => $_, type => 'new', epoch => (time() - (60*20)) } } @data ] } );

my $D = shift || '';
if ($D eq 'daemon') {
  require HTTP::Daemon;
  require File::Spec;
  my $d = HTTP::Daemon->new(LocalAddr => '127.0.0.1', Timeout => 10);
  print "Please to meet you at: <URL:", $d->url, ">\n";
  open( STDOUT, '>', File::Spec->devnull );
  while( my $c = $d->accept ) {
    my $r = $c->get_request;
    if ( $r ) {
      require HTTP::Response;
      my $resp = HTTP::Response->new( 200 );
      $resp->protocol('HTTP/1.1');
      $resp->header('Content-Type', 'application/octet-stream');
      $resp->header('Connection', 'close');
      $resp->content( $yaml );
      $c->send_response( $resp );
    }
    $c = undef;
  }
  warn "# HTTP Server Terminated\n";
  exit 0;
}
else {
  open (DAEMON, "$^X t/01-recent.t daemon |") or die "Can\'t exec daemon: $!";
}

}

use Test::More 'no_plan';
use CPAN::Recent::Uploads;

my @tests = qw(
A/AA/AAU/MRIM/Net-MRIM-1.10.tar.gz
A/AD/ADAMK/ORLite-1.17.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.06.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.07.tar.gz
A/AD/ADAMK/YAML-Tiny-1.36.tar.gz
);

my $greeting = <DAEMON>;
$greeting =~ /(<[^>]+>)/;

require URI;
my $base = URI->new($1);
sub url {
   my $u = URI->new(@_);
   $u = $u->abs($_[1]) if @_ > 1;
   $u->as_string;
}

print "Will access HTTP server at $base\n";

my @recent = sort CPAN::Recent::Uploads->recent( time() - ( 60 * 30 ), $base );

is_deeply( \@recent, \@tests, 'We got the correct list of uploads' );

diag("Waiting for HTTP server to terminate\n");
