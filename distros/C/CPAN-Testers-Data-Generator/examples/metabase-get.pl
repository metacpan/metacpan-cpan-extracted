#!/usr/bin/perl -w
use strict;

use Data::Dumper;

use Metabase    	0.004;
use Metabase::Fact	0.011;
use Metabase::Resource;
use CPAN::Testers::Fact::LegacyReport;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Metabase::AWS;
use CPAN::Testers::Report;

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->no_proxy( 'cpantesters.org' );

die "Usage: $0 <guid>\n"    unless(@ARGV);

{
    my $guid = shift @ARGV;

    my $metabase = CPAN::Testers::Metabase::AWS->new(
        bucket      => 'cpantesters',
        namespace   => 'beta7',
    );

    my $key;

    if($metabase) {
        # check whether tester has a valid access key
        die "No access key!"   unless($key = $metabase->access_key_id());
    } 

    #print "key=$key\n";
    #print "secret=".$metabase->secret_access_key()."\n";
    #print "metabase=" . Dumper($metabase);

    my $librarian = $metabase->public_librarian();
    #print "librarian=" . Dumper($librarian);

    my $archive = $librarian->archive;

    my $s3_object = $archive->s3_bucket->object( key => $archive->prefix . lc $guid );
    #print "s3_object=" . Dumper($s3_object);

    my $fact;
    eval { $fact = $librarian->extract( $guid ) };

    if($@) {
        print STDERR "FAIL: $@\n";
    } else {
        print "Fact: ".Dumper($fact);
    }
}

__END__
