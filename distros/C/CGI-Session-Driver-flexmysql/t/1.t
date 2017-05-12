#!/usr/bin/perl -w
use Test::Simple tests=>3;
use CGI::Session;

my         $session = new CGI::Session("driver:flexmysql", undef, {
              DataSource => 'dbi:mysql:test',
              User => '',
              Password => '',
              Table => 'sessions',    # You can put your sessions in any table
              KeyField => 'id',           # or any field for your session ids
              DataField => 'a_session',   # or any field for your session data
              AutoCreate => 1,            # FlexMySQL can create session table for you
              AutoDisconnect => 1,        
           });

ok( $session );
ok( $session->flush );

eval {
	$session->delete;
};
ok( !$@ );

