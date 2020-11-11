use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';

use lib 't/';
use Local::Ansible::Test1;

#########################################

use_ok('Ansible::Util::Run');

my $run = Ansible::Util::Run->new;
isa_ok( $run, 'Ansible::Util::Run' );

my $Test1 = Local::Ansible::Test1->new;

SKIP: {
	skip "ansible-playbook executable not found" unless $Test1->ansiblePlaybookExeExists;

	$Test1->chdir;

	my ( $stdout, $stderr, $exit ) =
	  $run->ansiblePlaybook( playbook => 'dump.yml' );
	ok(!$exit); 
};

done_testing();
