package t::Bb::Collaborate::V3;
use warnings; use strict;

=head1 NAME

t::Bb::Collaborate::V3

=head1 DESCRIPTION

Testing support package for Bb::Collaborate::V3

=cut
=head2 auth

locate test authorization from the environment

=cut

use URI;
use Bb::Collaborate::V3;

sub test_connection {
    my $class = shift;
    my %opt = @_;

    my $suffix = $opt{suffix} || '';
    my %result;

    my $user = $ENV{'BBC_TEST_USER'.$suffix};
    my $pass = $ENV{'BBC_TEST_PASS'.$suffix};
    my $url  = $ENV{'BBC_TEST_URL'.$suffix};

    if ($url) {
	my $uri_obj = URI->new($url, 'http');
	my $userinfo = $uri_obj->userinfo; # credentials supplied in URI

	if ($userinfo) {
	    my ($uri_user, $uri_pass) = split(':', $userinfo, 2);
	    $user ||= URI::Escape::uri_unescape($uri_user);
	    $pass ||= URI::Escape::uri_unescape($uri_pass)
		if $uri_pass;
	}

	if ($user && $pass && $url !~ m{^mock:}i) {
	    $result{auth} = [map {m{(.*)};$1} ($url, $user, $pass, type => 'StandardV3')];
	    if (my $debug = Bb::Collaborate::V3->debug) {
		push (@{$result{auth}}, debug => $debug);
	    }
	    eval {require Bb::Collaborate::V3::Connection};
	    die $@ if $@;
	    $result{class} = 'Bb::Collaborate::V3::Connection';
	}
    }
    else {
	$result{reason} = 'skipping live tests (set $BBC_TEST_URL'.$suffix.' to enable)';
    }

    return %result;
}

sub generate_id {
    my @chars = ('a' .. 'z', 'A' .. 'Z', '0' .. '9', '.', '_', '-');
    my @p = map {$chars[ sprintf("%d", rand(scalar @chars)) ]} (1.. 6);

    return join('', @p);
}

=head2 a_week_between

    ok(t::Elive::a_week_between($last_week_t, $this_week_t)

A rough test of times being about a week apart. Anything more
precise is going to require time-zone aware date/time calculations
and will introduce some pretty fat build dependencies.

=cut

sub a_week_between {
    my $start = shift;
    my $end = shift;

    my $seconds_in_a_week = 7 * 24 * 60 * 60;
    #
    # just test that the dates are a week apart to within an hour and a
    # half, or so. This should accomodate daylight savings and other
    # adjustments of up to 1.5 hours.
    #
    my $drift = 1.6 * 60 * 60; # a little over 1.5 hours
    my $ok = abs ($end - $start - $seconds_in_a_week) < $drift;

    return $ok;
}

1;
