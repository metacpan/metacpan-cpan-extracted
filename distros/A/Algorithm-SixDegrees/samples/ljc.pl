#!/usr/bin/perl -Tw

=head1 NAME

ljc.pl - A sample script to link LiveJournal users

=head1 SYNOPSIS

  # Link "ljuser1" to "ljuser2"
  ./ljc.pl ljuser1 ljuser2

=head1 DESCRIPTION

This sample script uses the popular weblog site LiveJournal
L<http://www.livejournal.com> and creates the necessary framework
for C<Algorithm::SixDegrees> to link users together into a chain.

=head1 FINDING USERS

Before running the script for the first time, please read
L<http://www.livejournal.com/bots/>.  In short, you will need to
change the C<$agent> variable; it must contain your email address.

Also, if you intend to run this more than a couple times, please
implement some form of results caching.  It could be as simple as
a C<tie>d DBM file; just please don't abuse the resource, as other
people rely on this courtesy LiveJournal extends for their own uses.

It will then try to connect the two LiveJournal users given on the
command line.

=head1 WEB VERSION

A web version of this utility is at
L<http://www.petekrawczyk.com/lj_connect/>.  It has extra options,
and will show the users as it progresses.  You may not get the same
result on the web version as this sample, but they should both be
equivalent lengths.

=cut

use warnings;
use strict;
use vars qw/$agent/;

use Algorithm::SixDegrees;
use LWP::UserAgent;

# GO LOOK AT THIS NOW: http://www.livejournal.com/bots/
$agent = 'Algorithm-SixDegrees Sample User';

my ($userfrom, $userto) = @ARGV;

$userfrom = clean_user($userfrom);
$userto   = clean_user($userto);

die "Usage: $0 from-user to-user\n" unless ($userfrom && $userto);

my $sd = Algorithm::SixDegrees->new;
$sd->forward_data_source( friends => \&get_friend_to );
$sd->reverse_data_source( friends => \&get_friend_of );
my @friends = $sd->make_link('friends',$userfrom,$userto);

if(scalar(@friends)) {
	print join (' -> ',@friends), "\n";
} else {
	my $err = $Algorithm::SixDegrees::ERROR;
	print $err ? "Error: $err\n" : "No chain found.\n";
}

exit(0);

# Only a-z, 0-9 and _ are allowed in LJ names.  This cleans up input.
sub clean_user {
	my $username = shift;
	return unless $username;
	$username =~ tr/-/_/;
	$username =~ s/\W//g;
	return lc($username);
}

# Returns a list of friends this user has declared.
sub get_friend_to {
	my $user = shift;
	my @f = get_friends($user,'to');
	return @f;
}

# Returns a list of users that have declared our user a friend.
sub get_friend_of {
	my $user = shift;
	my @f = get_friends($user,'of');
	return @f;
}

# This does the heavy lifting of making the HTTP call.
sub get_friends {
	my $user = shift;
	my $dir = shift;
	return unless $user;
	die "Look at the bot policy, then change the user agent.\n"
		if !$agent || $agent eq 'Algorithm-SixDegrees Sample User';
	my $ua = LWP::UserAgent->new(agent=>$agent);
	my $url = 'http://www.livejournal.com/misc/fdata.bml?user='.$user;
	my $res = $ua->get($url);
	my $content = $res->content;

	my @friends = ();
	if ($dir eq 'to') {
		while ($content =~ m#^> (.*?)$#mig) {
			my $user = $1;
			last unless $user;
			push(@friends,lc($user));
		}
	} elsif ($dir eq 'of') {
		while ($content =~ m#^< (.*?)$#mig) {
			my $user = $1;
			last unless $user;
			push(@friends,lc($user));
		}
	}
	return @friends;
}
