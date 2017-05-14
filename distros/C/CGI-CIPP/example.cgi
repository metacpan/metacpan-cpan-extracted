#!/usr/local/bin/perl
#!/usr/local/bin/speedy -- -r30 -t120

# delete the first line for CGI::SpeedyCGI usage

use strict;
use CGI::CIPP;

CGI::CIPP->request (
	document_root  => '/www/htdocs',
	directoy_index => 'index.cipp',
	cache_dir      => '/tmp/cipp_cache',
	databases      => {
		test => {
			data_source => 'dbi:mysql:test',
			user        => 'dbuser',
			password    => 'dbpassword',
			auto_commit => 1
		}
	}
	default_database => 'test',
	lang => 'EN'
);

