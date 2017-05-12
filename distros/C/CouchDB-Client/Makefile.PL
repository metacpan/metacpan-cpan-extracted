use inc::Module::Install 0.64;

name 'CouchDB-Client';

perl_version '5.006';
license 'perl';
all_from 'lib/CouchDB/Client.pm';

# override the default author detection behavior
author 'Maverick Edwards <maverick @t smurfbane d.t org>';
resources 'repository' => 'git://github.com/maverick/couchdb-client.git';
resources 'homepage'   => 'http://github.com/maverick/couchdb-client';

requires 'JSON::Any' => '1.17';
requires 'LWP::UserAgent';
requires 'HTTP::Request';
requires 'URI::Escape';
requires 'MIME::Base64';

# we need a JSON module that isn't Syck (no UTF-8 support makes it useless)
sub check_json () {
	my @order = qw(XS JSON DWIW);
	foreach my $testmod (@order) {
		$testmod = "JSON::$testmod" unless $testmod eq "JSON";
		eval "require $testmod";
		return unless $@;
	}
	requires 'JSON' => '2.02';
}
check_json();

WriteAll;
