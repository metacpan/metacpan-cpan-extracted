use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';
use File::Temp 'tempdir';
use Util::Medley::File;

use lib 't/';
use Local::Ansible::Test1;

use vars qw($File);

#########################################

$File = Util::Medley::File->new;

use_ok('Ansible::Util::Vars');

my $vars = Ansible::Util::Vars->new(keepTempFiles => 1);
ok($vars);
ok($vars->clearCache);

my $test1 = Local::Ansible::Test1->new;

SKIP: {
	skip "ansible-playbook executable not found"
	  unless $test1->ansiblePlaybookExeExists;

	$test1->chdir;

    my $href = $vars->getVars(['states']);
    ok( exists $href->{states} );
    
    #
    # ensure tempfiles were not cleaned up
    #
    my @files = @{ $vars->_tempFiles };
    my $tempDir = $vars->_tempDir;
    $vars = undef;
    
    foreach my $file (@files) {
        ok( -f $file );
        $File->unlink($file);
    }
    
    $File->rmdir($tempDir);
}

done_testing();

#############################################

sub _getVars {
    my $vars = shift;
    
    eval {
        $vars->getVars;	
    }	;
    ok($@);
}

sub getVars {
	my $vars = shift;

	my $href = $vars->getVars( ['states'] );
	ok( exists $href->{states} );

	eval { $vars->getVars; };
	ok($@);
}

sub getVar {
	my $vars = shift;

	my $href = $vars->getVar('states.iowa');
	my @keys = keys %{ $href->{states} };
	ok( @keys == 1 );

	$href = $vars->getVar('states.texas');
	@keys = keys %{ $href->{states} };
	ok( @keys == 1 );

	$href = $vars->getVar('states.iowa.cities');
	ok( ref( $href->{states}->{iowa}->{cities} ) eq 'ARRAY' );

	$href = $vars->getVar('states.iowa.cities.0');
	ok( ref( $href->{states}->{iowa}->{cities}->[0] ) eq 'HASH' );

	$href = $vars->getVar('states.iowa.cities.0.zip_codes.0');
	ok( $href->{states}->{iowa}->{cities}->[0]->{zip_codes}->[0] eq '52001' );

	eval { $vars->getVar; };
	ok($@);
}

sub getValue {
	my $vars = shift;

	my $val = $vars->getValue('states.iowa.cities.0.zip_codes.0');
	ok( $val eq '52001' );

	eval { $vars->getValue; };
	ok($@);
}

sub _getTempFile {
	my $vars = shift;

	eval { $vars->_getTempFile; };
	ok($@);
}
