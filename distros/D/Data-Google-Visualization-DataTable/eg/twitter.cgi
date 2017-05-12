#!/usr/bin/perl

# Slightly contrived example CGI showing Data::Google::Visualization::DataTable
# usage.

use strict;
use warnings;

use Template;
use DateTime;
use DateTime::Format::Mail;
use Net::Twitter::Lite;
use Data::Google::Visualization::DataTable;

my $template = 'eg/twitter.tt2';
my @tweeters = qw( PlanetPerl shadowcat_mst perl_api );

my $dt = Data::Google::Visualization::DataTable->new({ with_timezone => 1 });
$dt->add_columns(
	{ id => 'name',       label => 'Name',         type => 'string'    },
	{ id => 'followers',  label => 'Followers',    type => 'number'    },
	{ id => 'posted',     label => 'Last Updated', type => 'datetime'  },
	{ id => 'tweet',      label => 'Last Tweet',   type => 'string'    },
	{ id => 'retweet',    label => 'Retweet?',     type => 'boolean'   },
);

my $nt = Net::Twitter::Lite->new();

# Get the Twitter Data
for my $twitter_name ( @tweeters ) {

	# Get the user data
	my $user = $nt->show_user( $twitter_name );

	my $row = {};
	$row->{'name'}      = { v => $twitter_name, f => $user->{'name'} };
	$row->{'followers'} = $user->{'followers_count'};
	$row->{'tweet'}     = $user->{'status'}->{'text'};
	my $raw_posted = $user->{'status'}->{'created_at'};
	$raw_posted =~ s/^(...) (...) (..) (........) (.....) (....)/$1, $3 $2 $6 $4 $5/;
	$row->{'posted'}    = DateTime::Format::Mail->parse_datetime( $raw_posted );
	$row->{'retweet'}   = (
		$user->{'status'}->{'in_reply_to_user_id'} ||
		$user->{'status'}->{'in_reply_to_status_id'} ||
		$user->{'status'}->{'in_reply_to_screen_name'}
	) ? 1 : 0;

	$dt->add_rows( $row );
}

my $data = $dt->output_javascript( pretty => 1 );

print "Content-type: text/html\n\n";
Template->new->process( $template, { data => $data } );

exit;

