#!/usr/bin/perl
# startup.pl - Apache perl startup file
#
# $Id: startup.pl,v 1.15 2002/05/19 05:15:33 pliam Exp $
#

## must provide basic db hooks and secure objects at startup
use Apache::SecSess::DBI; 
use Apache::SecSess::Cookie::BasicAuth;
use Apache::SecSess::Cookie::LoginForm;
use Apache::SecSess::Cookie::X509;
use Apache::SecSess::Cookie::X509PIN;
use Apache::SecSess::Cookie::URL;
use Apache::SecSess::URL::Cookie;

## instantiate session security hander objects

## basic authentication
$Acme::adam = Apache::SecSess::Cookie::BasicAuth->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
#	lifeTime => 1440, idleTime => 60, renewRate => 5, 
	lifeTime => 5, idleTime => 2, renewRate => 1,
	minSessQOP => 0, minAuthQOP => 40,
	authRealm => 'Acme',
	cookieDomain => {'0,40' => 'adam.acme.com'},
	authenURL => 'https://adam.acme.com/authen',
	defaultURL => 'http://adam.acme.com/protected',
	renewURL => 'http://adam.acme.com/renew',
	timeoutURL => 'http://adam.acme.com/signout/timeout.html'
);

## login form 
$Acme::lysander = Apache::SecSess::Cookie::LoginForm->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
	lifeTime => 1440, idleTime => 60, renewRate => 5,
	minSessQOP => 0, minAuthQOP => 40,
	authRealm => 'Acme',
	cookieDomain => {'0,40' => 'lysander.acme.com'},
	authenURL => 'https://lysander.acme.com/authen',
	defaultURL => 'http://lysander.acme.com/protected',
	renewURL => 'http://lysander.acme.com/renew',
	timeoutURL => 'http://lysander.acme.com/signout/timeout.html'
);

## X.509 certificate authentication, issuing multiple cookies
$Acme::multi = Apache::SecSess::Cookie::X509->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
	lifeTime => 1440, idleTime => 60, renewRate => 5,
	minSessQOP => 128, minAuthQOP => 128,
	authRealm => 'Acme',
	cookieDomain => {
		0 => '.acme.com',
		40 => '.acme.com',
		128 => 'tom.acme.com'
	},
	authenURL => 'https://tom.acme.com/authen',
	defaultURL => 'https://tom.acme.com/protected',
	renewURL => 'https://tom.acme.com/renew',
	timeoutURL => 'https://tom.acme.com/signout/timeout.html',
	adminURL => 'https://tom.acme.com/changeid',
	errorURL => 'http://tom.acme.com/error.html'
);

## Two-factor auth (X.509 & PIN) issuing multiple cookies w/ secure wildcard
$Acme::twofact = Apache::SecSess::Cookie::X509PIN->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
	lifeTime => 1440, idleTime => 60, renewRate => 5,
	minSessQOP => 128, minAuthQOP => 128,
	authRealm => 'Acme',
	cookieDomain => {
		0 => '.acme.com',
		40 => '.acme.com',      # insecure wildcard domain
		'64,128' => '.sec.acme.com', # secure wildcard domain
		128 => 'john.sec.acme.com'
	},
	authenURL => 'https://john.sec.acme.com/authen',
	defaultURL => 'https://john.sec.acme.com/protected',
	renewURL => 'https://john.sec.acme.com/renew',
	timeoutURL => 'https://john.sec.acme.com/signout/timeout.html',
	adminURL => 'https://john.sec.acme.com/changeid',
	errorURL => 'http://john.sec.acme.com/error.html'
);

#
# multi-host Cookie/URL chaining
#

## stu.transacme.com standard cookies (strong auth: X.509 & PIN)
$Acme::stu = Apache::SecSess::Cookie::X509PIN->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
	lifeTime => 1440, idleTime => 60, renewRate => 5,
	minSessQOP => 128, minAuthQOP => 128,
	authRealm => 'Acme',
	cookieDomain => { 128 => 'stu.transacme.com' },
	authenURL => 'https://stu.transacme.com/authen',
	defaultURL => 'https://stu.transacme.com/chain',
	renewURL => 'https://stu.transacme.com/renew',
	timeoutURL => 'https://stu.transacme.com/signout/timeout.html',
	adminURL => 'https://stu.transacme.com/changeid',
	errorURL => 'http://stu.transacme.com/error.html'
);

## stu.transacme.com issue mangled-URL credentials based on stu cookies
$Acme::chain = Apache::SecSess::URL::Cookie->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
	lifeTime => 1440, idleTime => 60, renewRate => 5,
	sessQOP => 128, authQOP => 128,
	minSessQOP => 128, minAuthQOP => 128,
	authRealm => 'Acme',
	authenURL => 'https://stu.transacme.com/authen',
	chainURLS => [
		'https://milt.sec.acme.com/authen', 
		'https://noam.acme.org/authen'
	],
	issueURL => 'https://stu.transacme.com/chain',
	defaultURL => 'https://stu.transacme.com/protected',
	renewURL => 'https://stu.transacme.com/renew',
	timeoutURL => 'https://stu.transacme.com/signout/timeout.html',
	adminURL => 'https://stu.transacme.com/changeid',
	errorURL => 'http://stu.transacme.com/error.html'
);

## noam.acme.org cookies based on mangled-URL
$Acme::noam = Apache::SecSess::Cookie::URL->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
	lifeTime => 1440, idleTime => 60, renewRate => 5,
	minSessQOP => 128, minAuthQOP => 128,
	authRealm => 'Acme',
	cookieDomain => { 128 => 'noam.acme.org' },
	authenURL => 'https://stu.transacme.com/chain',
	defaultURL => 'https://noam.acme.org/protected',
	renewURL => 'https://noam.acme.org/renew',
	timeoutURL => 'https://noam.acme.org/signout/timeout.html',
	adminURL => 'https://noam.acme.org/changeid',
	errorURL => 'http://noam.acme.org/error.html'
);

## milt.sec.acme.com multi-cookies based on mangled-URL
$Acme::milt = Apache::SecSess::Cookie::URL->new(
	dbo => Apache::SecSess::DBI->new(
		dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
	),
	secretFile => '/usr/local/apache/conf/private/ckysec.txt',
	lifeTime => 1440, idleTime => 60, renewRate => 5,
	minSessQOP => 128, minAuthQOP => 128,
	authRealm => 'Acme',
	cookieDomain => {
		0 => '.acme.com',
		40 => '.acme.com',           # insecure wildcard domain
		'64,128' => '.sec.acme.com', # secure wildcard domain
		128 => 'milt.sec.acme.com'
	},
	authenURL => 'https://stu.transacme.com/chain',
	defaultURL => 'https://milt.sec.acme.com/protected',
	renewURL => 'https://milt.sec.acme.com/renew',
	timeoutURL => 'https://milt.sec.acme.com/signout/timeout.html',
	adminURL => 'https://milt.sec.acme.com/changeid',
	errorURL => 'http://milt.sec.acme.com/error.html'
);

#
# other site handlers
#


1;
