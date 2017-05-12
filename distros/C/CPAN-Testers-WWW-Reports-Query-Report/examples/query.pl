#!/usr/bin/perl -w
use strict;

use lib qw(../lib);

use Data::Dumper;
use CPAN::Testers::WWW::Reports::Query::Report;
use Getopt::Long;

my %options;
GetOptions(\%options, 'json', 'hash', 'host=s') or usage();
my $id = @ARGV ? $ARGV[0] : 0;
usage() unless($id);

print "@ARGV\n";

my $query = CPAN::Testers::WWW::Reports::Query::Report->new( host => $options{host} );
exit    unless($query);

my $spec = { report => $id };
$spec->{as_json} = 1  if($options{json});
$spec->{as_hash} = 1  if($options{hash});

my $data = $query->report( %$spec );
print Dumper($data);

print "Errors: " . $query->error . "\n";

sub usage {
    print "id=$id\n";
    print "$0 [ --json ] [ --hash ] [ --host=<host> ] <report id>\n";
    exit 0;
}
