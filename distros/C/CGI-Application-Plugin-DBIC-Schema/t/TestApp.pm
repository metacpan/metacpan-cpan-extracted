package TestApp;

use strict;

use CGI::Application;
use base 'CGI::Application';
use CGI::Application::Plugin::DBIC::Schema qw/schema dbic_config resultset rs/;
use DBICT;
use DBICT::Result::Test;


sub cgiapp_init{
	my $c = shift;

	my $dsn = $c->param('dsn');
	my $dbpw = $c->param('dbpw');
	my $dbuser = $c->param('dbuser');

	# Provide a default config.

	$c->dbic_config({schema=>"DBICT",
			 connect_info=>[$dsn,$dbuser,$dbpw]
			});

	# Or, provide additional configs by name.

	$c->dbic_config("test_config",
			{schema=>"DBICT",
			 connect_info=>[$dsn,$dbuser,$dbpw]
			});
	
}


sub setup {
	my $c = shift;
	$c->start_mode('test_create');
	$c->run_modes([qw/test_create test_create_named_config test_rs_shortform test_rs_shortform_named/]);
}

sub test_create_named_config {
	my $c = shift;
	
	$c->schema('test_config')
	    ->resultset("DBICT::Result::Test")
	    ->create({description=>"inserting via named config."});

	return "successful test: named config.";
}

sub test_create {
	my $c = shift;
	
	$c->schema()->resultset("DBICT::Result::Test")
	    ->create({description=>"inserting via default config."});

	return "successful test: default config.";
}

sub test_rs_shortform{
	my $c = shift;
	
	$c->rs("DBICT::Result::Test")
	    ->create({description=>"inserting via rs shortform."});

	return "successful test: rs shortform default";

}




sub test_rs_shortform_named{
	my $c = shift;
	
	$c->rs('test_config', "DBICT::Result::Test")
	    ->create({description=>"inserting via rs shortform named config."});

	return "successful test: rs shortform named";

}


1;
