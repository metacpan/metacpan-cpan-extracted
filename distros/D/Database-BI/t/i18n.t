#!/usr/bin/env perl

# The messages in American English (Database::BI::I18N, ::en_us).
#
#   * CGI::Lingua chooses the language: en-US is en-us, every other English and
#     anything else is en (British), from a request's Accept-Language or, for
#     the scripts, the locale (en_US.UTF-8, which CGI::Lingua alone reads as no
#     language);
#   * the American table says what the template word list says each British
#     message becomes - no more, no less - so a new British message with a
#     word to respell fails here until it is translated;
#   * a request in en-US gets its messages in American English, from the
#     controller and from a model alike, and the next request is not left in
#     that language.
#
#   prove -l t/i18n.t

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw(tempdir);
use Mojo::File;
use Test::Most;
use Test::Mojo;

use BI::Test::EnUS qw(americanize);

my $data_dir  = Mojo::File->new(tempdir(CLEANUP => 1));
my $model_dir = Mojo::File->new(tempdir(CLEANUP => 1))->to_string;
$data_dir->child('orders.csv')->spew("id,region,amount\n1,North,10\n2,South,20\n");

my $t = Test::Mojo->new('Database::BI', { data_dir => $data_dir->to_string, model_dir => $model_dir });

require Database::BI::I18N;
require Database::BI::I18N::en_us;

my $choose = \&Database::BI::I18N::choose;

subtest 'CGI::Lingua chooses from Accept-Language' => sub {
	is($choose->(accept => 'en-US'), 'en-us', 'en-US');
	is($choose->(accept => 'en-us'), 'en-us', 'in lower case');
	is($choose->(accept => 'en-US,en;q=0.9'), 'en-us', 'first of several');
	is($choose->(accept => 'en-GB'), 'en', 'en-GB is British');
	is($choose->(accept => 'en-CA'), 'en', 'so is en-CA');
	is($choose->(accept => 'en'), 'en', 'and plain en');
	is($choose->(accept => 'fr-FR'), 'en', 'a language there is no table for is British');
	is($choose->(), 'en', 'no header is British');
	is($choose->(default => 'en-us'), 'en-us', 'or the configured language');
	is($choose->(accept => 'en-GB', default => 'en-us'), 'en', 'which a header naming British overrides');
	is($choose->(default => 'fr'), 'en', 'a configured language with no table is British');
};

subtest 'the scripts follow the locale' => sub {
	local $Database::BI::I18N::LANGUAGE;
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	for my $case (['en_US.UTF-8', 'en-us'], ['en_US', 'en-us'], ['en_US.UTF-8@euro', 'en-us'],
		['en_GB.UTF-8', 'en'], ['fr_FR.UTF-8', 'en'], ['C', 'en'], ['POSIX', 'en'], ['', 'en']) {
		local $ENV{LANG} = $case->[0];
		is(Database::BI::I18N::from_locale(), $case->[1], "LANG=$case->[0]");
	}
	local $ENV{LANG} = 'en_GB.UTF-8';
	local $ENV{LC_ALL} = 'en_US.UTF-8';
	is(Database::BI::I18N::from_locale(), 'en-us', 'LC_ALL comes before LANG');
	{
		delete local $ENV{LC_ALL};
		local $ENV{LC_MESSAGES} = 'en_US.UTF-8';
		is(Database::BI::I18N::from_locale(), 'en-us', 'so does LC_MESSAGES');
	}
	{
		local $ENV{LC_ALL} = 'C';
		local $ENV{LANG}   = 'en_US.UTF-8';
		is(Database::BI::I18N::from_locale(), 'en', 'LC_ALL=C names no language, whatever LANG says');
	}
	{
		local $ENV{LC_ALL} = 'en_US.UTF-8';
		local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-GB';
		is(Database::BI::I18N::from_locale(), 'en-us', 'a request header left in the environment is not read');
	}

	is(Database::BI::I18N::language(), 'en', 'but a module called directly is British whatever the locale');
	local $Database::BI::I18N::LANGUAGE = 'en-us';
	is(Database::BI::I18N::language(), 'en-us', 'and follows a language a script or request set');
};

# Each module's British messages, read from its source: the controller's are
# lexical, so they cannot be reached from here.  The same reading t/unit.t uses.
my %SOURCES = (
	'Database::BI::Controller::Dashboard' => 'lib/Database/BI/Controller/Dashboard.pm',
	'Database::BI::Model::DataSource'     => 'lib/Database/BI/Model/DataSource.pm',
	'Database::BI::Model::Geocode'        => 'lib/Database/BI/Model/Geocode.pm',
	'Database::BI::Calc'                  => 'lib/Database/BI/Calc.pm',
	'Database::BI::Password'              => 'lib/Database/BI/Password.pm',
	'Database::BI::Command::password'     => 'lib/Database/BI/Command/password.pm',
);

sub british_messages {
	my ($file) = @_;
	(my $source = Mojo::File->new("$Bin/../$file")->slurp) =~ s/\r\n/\n/g;
	my ($block) = $source =~ /%MESSAGES\s*=>?\s*\((.*?)^\);/ms or BAIL_OUT("no %MESSAGES in $file");
	my %messages = eval "($block)";	## no critic (ProhibitStringyEval): the module's own constant data
	BAIL_OUT("cannot read %MESSAGES in $file: $@") if $@;
	return \%messages;
}

subtest 'the American table is the word list applied to every British message' => sub {
	my $table = do { no warnings 'once'; \%Database::BI::I18N::en_us::MESSAGES };

	ok(!(grep { !$SOURCES{$_} } keys %{$table}), 'it names only packages that have messages');

	my $count = 0;
	for my $package (sort keys %SOURCES) {
		my $british = british_messages($SOURCES{$package});
		my $own     = $table->{$package} // {};
		ok(scalar(keys %{$british}), "$package has messages");

		for my $key (sort keys %{$own}) {
			ok(exists $british->{$key}, "$package: $key is one of its messages");
		}
		for my $key (sort keys %{$british}) {
			my $want = americanize($british->{$key});
			my $have = $own->{$key} // $british->{$key};
			is($have, $want, "$package: $key reads as American English")
				or diag("Add it to lib/Database/BI/I18N/en_us.pm:\n\t$key => '$want',");
			isnt($own->{$key}, $british->{$key}, "$package: $key is listed only because it differs")
				if exists $own->{$key};
			$count++;
		}
	}
	ok($count > 150, 'every module was read');
};

subtest 'a message is given in the language of the moment' => sub {
	my $messages = { greeting => 'British %s', same => 'Same' };
	my $text = \&Database::BI::I18N::text;
	{
		local $Database::BI::I18N::LANGUAGE = 'en-us';
		is($text->('Database::BI::Controller::Dashboard', {}, 'error_text_card_colour'),
			'A color must be written #rrggbb', 'American');
		is($text->('No::Such::Package', $messages, 'same'), 'Same', 'a message with no translation is British');
		is($text->('No::Such::Package', $messages, 'missing'), undef, 'and an unknown key is undef');
		is($text->('No::Such::Package', $messages, undef), undef, 'as is no key');
	}
	{
		local $Database::BI::I18N::LANGUAGE = 'en';
		is($text->('Database::BI::Controller::Dashboard', { error_text_card_colour => 'British' },
			'error_text_card_colour'), 'British', 'British');
	}
	{
		local $Database::BI::I18N::LANGUAGE = 'xx';
		is($text->('No::Such::Package', $messages, 'same'), 'Same', 'a language with no module is British');
	}
	{
		local $Database::BI::I18N::LANGUAGE = 'en-us';
		like(Database::BI::Model::DataSource::_fmt('error_backend_init', 'orders', 'gone'),
			qr/\ADataSource: failed to initialize database backend for table "orders": gone\z/,
			'a model message too');
	}
};

subtest 'a request in en-US gets American messages, and the next is not left in it' => sub {
	$t->post_ok('/api/analyses' => json => {
		name     => 'Report',
		datasets => [ { spec => 'table:orders' } ],
		visuals  => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
	})->status_is(201);
	my $id = $t->tx->res->json->{id};
	my $bad = { kind => 'text', options => { text => 'x', colour => 'red' } };

	$t->post_ok("/api/analyses/$id/visuals" => { 'Accept-Language' => 'en-US' } => json => $bad)
		->status_is(400)->json_like('/error' => qr/A color must be written/, 'en-US: color');
	is($Database::BI::I18N::LANGUAGE, undef, 'the language ends with the request');

	$t->post_ok("/api/analyses/$id/visuals" => { 'Accept-Language' => 'en-GB' } => json => $bad)
		->status_is(400)->json_like('/error' => qr/A colour must be written/, 'en-GB: colour');
	$t->post_ok("/api/analyses/$id/visuals" => json => $bad)
		->status_is(400)->json_like('/error' => qr/A colour must be written/, 'no header: colour');

	local $t->app->config->{language} = 'en-us';
	$t->post_ok("/api/analyses/$id/visuals" => json => $bad)
		->status_is(400)->json_like('/error' => qr/A color must be written/, "language => 'en-us': color");
	$t->post_ok("/api/analyses/$id/visuals" => { 'Accept-Language' => 'en-GB' } => json => $bad)
		->status_is(400)->json_like('/error' => qr/A colour must be written/, 'unless the browser asks for British');
};

subtest 'a page and its messages are in the same language' => sub {
	$t->get_ok('/view/orders', { 'Accept-Language' => 'en-US' })->status_is(200)
		->content_like(qr/<html lang="en-us">/, 'the page is en-us');
};

done_testing();
