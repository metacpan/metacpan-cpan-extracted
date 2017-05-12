use strict;
use CGI::Wiki;
use CGI::Wiki::TestConfig::Utilities;
use Test::More tests =>
  (1 + 17 * $CGI::Wiki::TestConfig::Utilities::num_stores);

use_ok( "CGI::Wiki::Plugin::Diff" );

my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing", 17
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = CGI::Wiki->new( store => $store );
      my $differ = eval { CGI::Wiki::Plugin::Diff->new; };
      is( $@, "", "'new' doesn't croak" );
      isa_ok( $differ, "CGI::Wiki::Plugin::Diff" );
      $wiki->register_plugin( plugin => $differ );

      # Test ->null diff
      my %nulldiff = $differ->differences(
      			node => "Jerusalem Tavern",
      			left_version => 1,
      			right_version => 1);
      ok( !exists($nulldiff{diff}), "Diffing the same version returns empty diff");
      
      # Test ->body diff
      my %bodydiff = $differ->differences(
      			node => "Jerusalem Tavern",
      			left_version => 1,
      			right_version => 2);
      is( @{$bodydiff{diff}}, 2, "Differ returns 2 elements for body diff");
      is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 0 ==\n",
      			right => "== Line 1 ==\n"},
      		"First element is line number on right");
      is_deeply( $bodydiff{diff}[1], {
      			left => '<span class="diff1">Pub </span>'.
      				'in Clerkenwell with St Peter\'s beer.'.
      				"<br />\n",
      			right => '<span class="diff2">Tiny pub </span>'.
      				'in Clerkenwell with St Peter\'s beer.'.
      				'<span class="diff2"><br />'.
      				"\nNear Farringdon station</span>".
      				"<br />\n",
      				},
      		"Differences highlights body diff with span tags");
      		
      # Test ->meta diff
      my %metadiff = $differ->differences(
      			node => "Jerusalem Tavern",
      			left_version => 2,
      			right_version => 3);
      is( @{$metadiff{diff}}, 2, "Differ returns 2 elements for meta diff");
      is_deeply( $metadiff{diff}[0], {
      			left =>  "== Line 2 ==\n",
      			right => "== Line 2 ==\n"},
      		"First element is line number on right");
      is_deeply( $metadiff{diff}[1], {
      			left => "category='Pubs'",
      			right => "category='Pubs".
      				'<span class="diff2">,Real Ale\'<br />'.
      				"\nlocale='Farringdon</span>'",
      				},
      		"Differences highlights metadata diff with span tags");
      		
	# Another body diff with bracketed content
	%bodydiff = $differ->differences(
			node => 'IvorW',
			left_version => 1,
			right_version => 2);
        is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 11 ==\n",
      			right => "== Line 11 ==\n"},
      		"Diff finds the right line number on right");
        is_deeply( $bodydiff{diff}[1], {
        		left => "metatest='".
        			'<span class="diff1">Moo</span>\'',
        		right => '<span class="diff2">'.
        			"[[IvorW's Test Page]]<br />\n".
        			"<br />\n</span>".
        			"metatest='".
        			'<span class="diff2">Boo</span>\'',
        			},
        	"Diff scans words correctly");
        # And now a check for framing
	%bodydiff = $differ->differences(
			node => 'IvorW',
			left_version => 2,
			right_version => 3);
        is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 13 ==\n",
      			right => "== Line 13 ==\n"},
      		"Diff finds the right line number on right");
        is_deeply( $bodydiff{diff}[1], {
        		left => "metatest='".
        			'<span class="diff1">Boo</span>\'',
        		right => '<span class="diff2">'.
        			"[[Another Test Page]]<br />\n".
        			"<br />\n</span>".
        			"metatest='".
        			'<span class="diff2">Quack</span>\'',
        			},
        	"Diff frames correctly");
	# Trailing whitespace test 1
	%bodydiff = $differ->differences(
			node => 'IvorW',
			left_version => 3,
			right_version => 4);
    
    ok(!exists($bodydiff{diff}), 'No change found for trailing whitespace');

	# Trailing whitespace test 2
	%bodydiff = $differ->differences(
			node => 'Jerusalem Tavern',
			left_version => 3,
			right_version => 4);
        is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 0 ==\n",
      			right => "== Line 0 ==\n" },
      		"Diff finds the right line numbers");
        is_deeply( $bodydiff{diff}[1], {
        		left => "Tiny pub in Clerkenwell with St Peter's beer".
        		        ".<br />\n",
        		right => "Tiny pub in Clerkenwell with St Peter's beer".
        			' <span class="diff2">but no food</span>.'.
        			"<br />\n",
        			},
        	"Diff handles trailing whitespace correctly");
        eval {
               $differ->differences(
                        node => 'Test',
                        left_version => 1,
                        right_version => 2 ) };
        is( $@, "", "differences doesn't die when only difference is a newline");
    } # end of SKIP
}
