#!perl

my @modules;

BEGIN {
    @modules =
      qw( Comics
	  Comics::Fetcher::Base
	  Comics::Fetcher::Cascade
	  Comics::Fetcher::Direct
	  Comics::Fetcher::GoComics
	  Comics::Fetcher::Single
	  Comics::Plugin::Base
	  Comics::Plugin::Sigmund
	  Comics::Utils::Icon
       );
}

use Test::More tests => scalar @modules;

BEGIN {
    use_ok($_) foreach @modules;
}

diag( "Testing Comics $Comics::VERSION, Perl $], $^X" );
