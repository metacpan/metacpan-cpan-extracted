#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

if ( ! $ENV{TEST_ACT_EMAILER_ADDR} ) {
    plan skip_all => 'set TEST_ACT_EMAILER_ADDR (a "to" address) to enable this test';
}
else {
    plan tests => 1;
}

# DEFINE THIS TO TEST
my $to = $ENV{ACT_EMAILER_TEST_ADDR};
my $cc = $ENV{ACT_EMAILER_TEST_CC};
BEGIN {
    $ENV{ACT_REG_YAML_FILE} = "$ENV{PWD}/t/data/Emailer/registry.yml";
}

use Activator::Emailer;
use Activator::Log;
Activator::Log->level('DEBUG');

my $tt_vars = {
	       name => 'Karim Nassar',
	       to          => $to,
	       cc          => $cc,
	      };
my $mailer = Activator::Emailer->new(
				     To          => $to,
				     Cc          => $cc,
				     Subject     => 'Activator::Emailer Test Email',
				     html_body   => 'html_body.tt',
				     tt_options  => { INCLUDE_PATH => "$ENV{PWD}/t/data/Emailer" },
				    );

# future test
$mailer->attach(
		Type        => 'application/msword',
		Path        => "$ENV{PWD}/t/data/Emailer/test-mission.doc",
		Filename    => 'Test Mission.doc',
		Disposition => 'attachment' );

#print Dumper( $mailer)."\n";

lives_ok {
    $mailer->send( $tt_vars );
} 'can send email';
