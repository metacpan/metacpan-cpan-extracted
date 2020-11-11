package Local::Ansible::Test1;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Kavorka 'method';
use Util::Medley::File;

with 'Util::Medley::Roles::Attributes::File';

################################

has vaultPasswordFiles => (
	is      => 'rw',
	isa     => 'ArrayRef',
	default => sub { return [] }
);

has testDir => (
	is      => 'rw',
	isa     => 'Str',
	default => 'ansible-test1'
);

#################################

has _prevDir => (
	is  => 'rw',
	isa => 'Str',
);

#################################

method ansiblePlaybookExeExists {

    my $path = $self->File->which('ansible-playbook');	
    if ($path) {
        return 1;	
    }
    
    return 0;
}

method chdir {

	my $cwd      = $self->File->basename($self->File->getcwd);
	my $testDir  = $self->testDir;

	if ( $cwd ne $testDir ) {
		my $prevDir = $self->File->chdir("t/$testDir");
		$self->_prevDir($prevDir);
	}
}

1;
