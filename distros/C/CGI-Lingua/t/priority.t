#!/usr/bin/env perl

use strict;
use warnings;

# use Data::Dumper;
use Test::Most;

BEGIN { use_ok('CGI::Lingua') }

local $ENV{'HTTP_ACCEPT_LANGUAGE'} = 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7';

# Stop I18N::LangTags::Detect from detecting something
delete local $ENV{'LANGUAGE'};
delete local $ENV{'LC_ALL'};
delete local $ENV{'LC_MESSAGES'};
delete local $ENV{'LANG'};
if($^O eq 'MSWin32') {
	local $ENV{'IGNORE_WIN32_LOCALE'} = 1;
}

delete local $ENV{'REMOTE_ADDR'};

my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);

ok(defined $l);
ok($l->isa('CGI::Lingua'));
ok($l->language() eq 'English');
ok($l->sublanguage() eq 'United States');
ok($l->requested_language() eq 'English (United States)');

$l = CGI::Lingua->new(supported => ['en', 'fr', 'de', 'en-us']);

ok(defined $l);
ok($l->isa('CGI::Lingua'));
ok($l->language() eq 'German');
ok(!defined($l->sublanguage()));
ok($l->requested_language() eq 'German');

local $ENV{'HTTP_ACCEPT_LANGUAGE'} = 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7';

$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
ok(defined $l);
ok($l->isa('CGI::Lingua'));
ok($l->language() eq 'English');
ok($l->sublanguage() eq 'United States');
ok($l->requested_language() eq 'English (United States)');

# diag(Data::Dumper->new([$l->{'messages'}])->Dump());

$l = CGI::Lingua->new(supported => ['en-gb']);
ok(defined $l);
ok($l->isa('CGI::Lingua'));
ok($l->language() eq 'English');
ok(!defined($l->sublanguage()));	# We don't have US English sublanguage only British English supported
ok($l->requested_language() eq 'English (United States)');
# diag(Data::Dumper->new([$l->{'messages'}])->Dump());

local $ENV{'HTTP_ACCEPT_LANGUAGE'} = 'zh-CN,zh;q=0.9,en;q=0.8,*;q=0.1';

$l = CGI::Lingua->new(supported => ['en-gb']);
ok(defined $l);
ok($l->isa('CGI::Lingua'));
ok($l->language() eq 'English');
ok(!defined($l->sublanguage()));	# We don't have US English sublanguage only British English supported
ok($l->requested_language() eq 'English');
# diag(Data::Dumper->new([$l->{'messages'}])->Dump());

done_testing();
