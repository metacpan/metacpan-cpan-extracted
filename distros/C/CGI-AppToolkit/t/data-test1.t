#!/usr/bin/perl -w
$| = 1;
use ExtUtils::testlib;

use CGI::AppToolkit;
use strict;

use Data::Dumper;

BEGIN {
	print "1..8\n";
}

my $V = 0;

# set these and uncomment the two lines after $dbpassword
my $dbuser = '';
my $dbpassword = '';
my $testdb = '';

# comment the following lines to make the test happen
foreach (1..8) { print "ok skipped until username and password are supplied\n"; }
exit;

sub compare {
	my $num = shift;
	my $value = shift;
	my $should_be = shift;
	
	my ($filename, $line) = (caller)[1,2];
	
	if ($value eq $should_be) {
		print "'$value'\n" if $V > 1;
		print "ok $num Line: " . $line . "\n";
	} else {
		print "'$value'\nshould be: '$should_be'\n\tat line: $line of file '$filename'\n" if $V;
		print "not ok $num\n";
	}
}

local $^W = 0;

my $T = 1;

my $kit = CGI::AppToolkit->new();

#test connect 
{
	$kit->connect("DBI:mysql:database=$testdb;host=localhost", $dbuser, $dbpassword, {'RaiseError' => 1});
	
	my $dbh = $kit->get_dbi();
	
	compare($T++, $dbh ? 'true' : 'connection failed', 'true');
	
	#test database creation - NOT a function of CGI::AppToolkit (mysql specific?)
	
	my $sth = $dbh->prepare('DROP TABLE IF EXISTS test_shebang');
	$sth->execute();
	
	my $sth2 = $dbh->prepare(<<'CREATE_TABLE_END');
	CREATE TABLE test_shebang (
		id        int(11)    NOT NULL auto_increment,
		address   tinytext   NOT NULL,
		zip       tinytext   NOT NULL,
		password  tinytext   NOT NULL,
		start     date       NOT NULL default '0000-00-00',
		active    tinyint(1) NOT NULL default '0',
		verified  tinyint(1) NOT NULL default '0',
		html      tinyint(1) NOT NULL default '0',
		KEY id(id)
	)
CREATE_TABLE_END
	$sth2->execute();
}

#test storing 
{
	my $data = $kit->data('TestSQLObject')->store([
			{
				address => 'email1@test.com',
				zip => '90028',
				password => 'pass1',
				active => 1,
				verified => 1,
				html => 0
			},
			{
				address => 'email2@test.com',
				zip => '64504',
				password => 'pass2',
				active => 0,
				verified => 1,
				html => 0
			},
			{
				address => 'email3@test.com',
				zip => '12345',
				password => 'pass3',
				active => 0,
				verified => 0,
				html => 1
			}
		]);

	compare($T++, Data::Dumper->Dump([$data], ['*data']), <<'COMPARE');
@data = (
          {
            'zip' => '90028',
            'address' => 'email1@test.com',
            'id' => undef,
            'active' => 1,
            'password' => 'pass1',
            'html' => 0,
            'verified' => 1
          },
          {
            'zip' => '64504',
            'address' => 'email2@test.com',
            'id' => undef,
            'active' => 0,
            'password' => 'pass2',
            'html' => 0,
            'verified' => 1
          },
          {
            'zip' => '12345',
            'address' => 'email3@test.com',
            'id' => undef,
            'active' => 0,
            'password' => 'pass3',
            'html' => 1,
            'verified' => 0
          }
        );
COMPARE
}

	my $date = undef;

#test retrieval 
{
	my $date_hash = $kit->data('TestSQLObject')->fetch_row(now => 1);
	compare($T++, ref $date_hash, 'HASH');
	
	if (ref $date_hash eq 'HASH') {
		$date = $date_hash->{'now'};
		
		my $data = $kit->data('TestSQLObject')->fetch(id => ['in', qw/1 2 3/]);
		compare($T++, Data::Dumper->Dump([$data], ['*data']), <<"COMPARE");
\@data = (
          {
            'zip' => '90028',
            'address' => 'email1\@test.com',
            'start' => '$date',
            'active' => '1',
            'password' => 'pass1',
            'id' => '1',
            'html' => '0',
            'verified' => '1'
          },
          {
            'zip' => '64504',
            'address' => 'email2\@test.com',
            'start' => '$date',
            'active' => '0',
            'password' => 'pass2',
            'id' => '2',
            'html' => '0',
            'verified' => '1'
          },
          {
            'zip' => '12345',
            'address' => 'email3\@test.com',
            'start' => '$date',
            'active' => '0',
            'password' => 'pass3',
            'id' => '3',
            'html' => '1',
            'verified' => '0'
          }
        );
COMPARE
	}
}

#test 'store' update 
{
	my $data = $kit->data('TestSQLObject')->fetch_row(id => 1);
	compare($T++, ref $data, 'HASH');
	
	if (ref $data eq 'HASH') {
		$data->{'html'} = 1;
		$data->{'active'} = 0;
		$data->{'verified'} = 0;
		$data->{'password'} = 'new_pass';
		
		$kit->data('TestSQLObject')->store($data);
	}

	my $data2 = $kit->data('TestSQLObject')->fetch_row(id => 1);
	compare($T++, Data::Dumper->Dump([$data2], ['*data2']), <<"COMPARE");
\%data2 = (
           'zip' => '90028',
           'address' => 'email1\@test.com',
           'start' => '$date',
           'active' => '0',
           'password' => 'new_pass',
           'id' => '1',
           'html' => '1',
           'verified' => '0'
         );
COMPARE
}

#test automorph
{
	my $data = $kit->data('automorph:test_shebang')->fetch_row(id => 1);
	compare($T++, ref $data, 'HASH');
	
	if (ref $data eq 'HASH') {
		$data->{'html'} = 0;
		$data->{'active'} = 1;
		$data->{'verified'} = 1;
		$data->{'password'} = 'new_pass';
		
		$kit->data('TestSQLObject')->store($data);
	}

	my $data2 = $kit->data('automorph:test_shebang')->fetch_row(id => 1);
	compare($T++, Data::Dumper->Dump([$data2], ['*data2']), <<"COMPARE");
\%data2 = (
           'zip' => '90028',
           'address' => 'email1\@test.com',
           'start' => '$date',
           'active' => '1',
           'password' => 'new_pass',
           'id' => '1',
           'html' => '0',
           'verified' => '1'
         );
COMPARE
}
