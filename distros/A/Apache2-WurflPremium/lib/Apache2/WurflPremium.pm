package Apache2::WurflPremium;


use strict;
use warnings;
use Data::Dumper;


use Apache2::Const;
use Apache2::RequestRec;
use APR::Table;
use Apache2::Module ();
use Apache2::ServerUtil;
use Net::WURFL::ScientiaMobile;
use Net::WURFL::ScientiaMobile::Cache::Cache;
use Cache::File;


# ABSTRACT: A module that the Wurfl Perl client to retrieve capabilities data from the Wurfl server

=pod

=head1 NAME

Apache2::WurflPremium -A module that the Wurfl Perl client to retrieve capabilities data from the Wurfl server



=head1 DESCRIPTION

-A module that the Wurfl Perl client to retrieve capabilities data from the Wurfl server

=head1 METHODS

=cut

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

=pod

=head2 handler

The handler retrieves the user_agens and the api key.
It then checks the cache for existing data
If none is there is retrieves data from the Wurfl server
and sets the environment accordingly.

=cut

sub get_config {
	Apache2::Module::get_config('Apache2::Wurfl::Parameters', @_);
}

sub handler {
	my $r = shift;

        #get user agent
         my $headers_in = $r->headers_in;
         my $user_agent =  $headers_in->get('User-Agent');
         
	#get api key
	my $s = $r->server;
	my $dir_cfg = get_config($s, $r->per_dir_config);
	my $api_key = $dir_cfg->{WurflAPIKey};

	#load wurflcloud client library with local file cache
	my $cache = Net::WURFL::ScientiaMobile::Cache::Cache->new(
		cache => Cache::File->new(cache_root => '/tmp/wurfl_cacheroot'));
	my $scientiamobile = Net::WURFL::ScientiaMobile->new(
		api_key => $api_key,
		cache   => $cache,
	);

	#run device detection and retrieve data
	my $capabilities;
	my %env = %ENV;
	$env{'User-Agent'} = $user_agent unless $env{'User-Agent'};
	
	$scientiamobile->detectDevice(\%env);
	$capabilities = $scientiamobile->capabilities();

	#load capabilities into apache environment
	foreach my $key (keys %{$capabilities}) {
		my $upperkey = uc($key);
		$r->subprocess_env("WURFL_$upperkey" => $capabilities->{$key});
	}

	return Apache2::Const::OK;
}



=pod


=cut


1;
