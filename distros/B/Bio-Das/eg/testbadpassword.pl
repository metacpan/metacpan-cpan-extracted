#!/usr/local/bin/perl

use lib './blib/lib','../blib/lib';
use Bio::Das;

my $das = Bio::Das->new(5);  # timeout of 5 sec

sub auth{
  my ($fetcher, $realm, $iteration) = @_;

  if($iteration > 3){return undef}

  select STDOUT;
  $| = 1;
  print "Please enter username and password for realm '$realm' at ", $fetcher->host, " (attempt $iteration of 3)\nUser
name: ";
  my $user = <STDIN>;
  chomp $user;
  print "Password: ";
  my $pass = <STDIN>;
  chomp $pass;

  return ($user, $pass);
}

$das->auth_callback(\&auth);

my @response = $das->dsn('http://test:badpass@magpie.ucalgary.ca/magpiedev-cgi/das'
			);
print "\n\n**DSN Lists**\n";

foreach (@response) {
  if ($_->is_success) {
    my @results = $_->results;
    print "$_:\n\t",join ("\n\t",@results),"\n";
  } else {
    print "$_: ",$_->error,"\n";
  }
}

print "\n\n**Types**\n";

my @dsn = map {$_->results} @response;

@responses = $das->types(-dsn=>\@dsn);
for my $r (@responses) {
  my $dsn = $r->dsn;
  print $dsn,"\n";
  warn $r->error,"\n" unless $r->is_success;
  my @results = $r->results;
  print join "\t",@results,"\n";
}

@responses = $das->types(-dsn=>\@dsn,
			 -segments => ['chr22:13000000,14000000',
				       'chr1:1000000,2000000']);
for my $r (@responses) {
  my $dsn = $r->dsn;
  warn $r->error unless $r->is_success;

  my @results = $r->results;
  print join "\t",$dsn,@results,"\n";
  my $segs = $r->results;
  print join "\n",%$segs;
}

my $response = $das->types(-dsn => 'http://www.wormbase.org/db/das/elegans');
if ($response->is_success) {
  print join ',',$response->results,"\n";
} else {
  warn $response->error;
}
