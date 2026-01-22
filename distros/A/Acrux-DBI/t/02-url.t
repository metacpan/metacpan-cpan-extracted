#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use Test::More;
use Acrux::DBI;

ok(Acrux::DBI->VERSION, 'Version');

# URL: 'postgres://foo:pass@localhost/mydb?PrintError=1&foo=123'
{
    my $dbi = Acrux::DBI->new(undef, bar => 'baz');
    $dbi->url('postgres://foo:pass@localhost/mydb?PrintError=1&foo=123');
	is($dbi->driver, 'postgres', 'Driver (scheme) is postgres');
	is($dbi->host, 'localhost', 'Host is localhost');
	is($dbi->port, '', 'Port is null');
	is($dbi->userinfo, 'foo:pass', 'Userinfo is foo:pass');
	is($dbi->username, 'foo', 'Username is foo');
	is($dbi->password, 'pass', 'Password is pass');
	is($dbi->database, 'mydb', 'Password is mydb');
	is($dbi->dsn, 'DBI:Pg:dbname=mydb;host=localhost', 'DSN is DBI:Pg:dbname=mydb;host=localhost');
	#note explain $dbi->cachekey;
}

done_testing;

1;

__END__

prove -lv t/02-url.t
