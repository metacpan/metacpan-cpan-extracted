use Modern::Perl;
use Data::Printer alias => 'pdump';

sub commonGetAnsibleTest1Dir {
    
    return 't/ansible-test1';	
}

sub commonGetAnsibleTest2Dir {
   
    return 't/ansible-test2';   
}

sub commonGetVaultPassFiles {
    my $file = shift;
    
	my @files = $file->find(
		dir      => '.',
	);

    my @vaultPassFiles;	
    foreach my $e (grep { /vault.+\.txt$/ } @files) {
        push @vaultPassFiles, $file->basename($e);	
    }
    
    return @vaultPassFiles;
}

1;