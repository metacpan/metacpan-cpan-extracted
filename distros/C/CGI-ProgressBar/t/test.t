#! perl -w
# TODO bother to update this
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib '..';
use strict;

use Test;
BEGIN { plan tests => 12 };
use CGI::ProgressBar qw/:standard/;
ok(1); # If we made it this far, we're ok.

die "Old version" if $CGI::ProgressBar::VERSION != "0.05";

#goto TEST11; #############

my $query;

$query = new CGI::ProgressBar;
# Test 2
ok(ref $query,'CGI::ProgressBar');
# Test 3
ok (defined start_html('A Simple Example'), 1);
# Test 4
ok (defined progress_bar, 1);
# Test 5
ok (defined $query->progress_bar, 1);
# 6
ok( defined start_html, 1);
# 7
my $html = progress_bar( from=>10 );
ok (defined $html, 1);

# 8

$query = new CGI::ProgressBar;
$html = $query->progress_bar( blocks=>20 );
ok (defined $html, 1);

# 9 TODO
ok( $query->{progress_bar}->{blocks}, 20);

# 10
ok( defined update_progress_bar, 1);

#progress_bar ( -colors => [ 0, 'green', 50, 'red' ] );

# 11
my $blocks = 20;
$html = progress_bar( blocks=>$blocks );
$html =~ /if\s\(pblib_at\s>\s(\d+)/;
ok( $1, $blocks);

# 12
ok( defined hide_progress_bar, 1);








