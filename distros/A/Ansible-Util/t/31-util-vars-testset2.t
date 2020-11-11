use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';
use Util::Medley::File;

use lib 't/';
use Local::Ansible::Test2;

use vars qw($File);

#########################################

$File = Util::Medley::File->new;

use_ok('Ansible::Util::Vars');

#my $vars = Ansible::Util::Vars->new;
#isa_ok( $vars, 'Ansible::Util::Vars' );
#ok( $vars->clearCache );

my $test2 = Local::Ansible::Test2->new;

SKIP: {
	skip "ansible-playbook executable not found"
	  unless $test2->ansiblePlaybookExeExists;

	$test2->chdir;

	doRuntimeException();
	doKeepFiles0();
	doKeepFiles1();
}

done_testing();

#############################################

sub doKeepFiles0 {

	my $vars = Ansible::Util::Vars->new(
		vaultPasswordFiles => $test2->vaultPasswordFiles,
		keepTempFiles      => 0
	);
	ok( $vars->clearCache );

    my $href = $vars->getVars( ['states'] );
    ok( exists $href->{states} );
    
	# ensure tempfile cleanup worked
	my $dir   = $vars->_tempDir;
	my @files = @{ $vars->_tempFiles };
	$vars = undef;

	foreach my $file (@files) {
		ok( !-f $file );
	}

	ok( !-d $dir );
}

sub doKeepFiles1 {

	my $vars = Ansible::Util::Vars->new(
		vaultPasswordFiles => $test2->vaultPasswordFiles,
		keepTempFiles      => 1
	);
	ok( $vars->clearCache );

    my $href = $vars->getVars( ['states'] );
    ok( exists $href->{states} );
    
	# ensure tempfile cleanup worked
	my $dir   = $vars->_tempDir;
	my @files = @{ $vars->_tempFiles };
	$vars = undef;

	foreach my $file (@files) {
		ok( -f $file );
	}

	cleanup( $dir, \@files );
}

sub doRuntimeException {

	#
	# test a runtime exception (files should be kept for debug)
	# ...this one fails because it needs vault pass files.
	#
	my $vars = Ansible::Util::Vars->new( keepTempFiles => 0 );
	ok( $vars->clearCache );

	eval { $vars->getVars( ['states'] ); };
	ok($@);

	# ensure tempfile cleanup did NOT happen
	my $dir   = $vars->_tempDir;
	my @files = @{ $vars->_tempFiles };
	$vars = undef;

	foreach my $file (@files) {
		ok( -f $file );
	}

	cleanup( $dir, \@files );
}

sub cleanup {

	my ( $dir, $files ) = @_;

	foreach my $file (@$files) {
		$File->unlink($file);
	}

	$File->rmdir($dir);
}

