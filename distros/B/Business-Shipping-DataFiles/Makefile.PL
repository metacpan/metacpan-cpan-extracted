use strict;
use warnings;
use ExtUtils::MakeMaker;

my %my_globals = (
	DATA_DIR	=> '/usr/local/B_Shipping/data'
);

WriteMakefile(
    NAME                => 'Business::Shipping::DataFiles',
    AUTHOR              => 'Dan Browning <db@kavod.com>',
    VERSION_FROM        => 'lib/Business/Shipping/DataFiles.pm',
    ABSTRACT_FROM       => 'lib/Business/Shipping/DataFiles.pm',
    CONFIGURE		    => \&extra_WriteMakefile_options,
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-Shipping-DataFiles-*' },
);


# Override the standard "install" target, so that it calls "support_files_install"

sub MY::install {
	package MY;
	my $inherited = shift->SUPER::install(@_);
	my $new; 
	for ( split( "\n", $inherited ) ) {
		if ( /^install :: / ) {
			$_ .= " support_files_install";
		}
		$new .= "$_\n";
	}
	return $new;
}

sub MY::postamble {
	return qq{
docs :
	find lib -name '*.pm' -or -name '*.pod' -exec podchecker -nowarnings {} \\;
	
support_files_install :
	\@echo "Installing data files to $my_globals{DATA_DIR}"
	\@\$(MKPATH) $my_globals{DATA_DIR}
	\@\$(CP) --recursive --force data/*   $my_globals{DATA_DIR}/
};  #/qq
}

sub extra_WriteMakefile_options {
    my $module = "Business::Shipping::DataFiles";
    
    # TODO: Try to determine the directory by using 
    # Business::Shipping::Config::support_files()
    
    # TODO: This probaby causes CPAN to try to install Business::Shipping, so don't do it for now.
    # eval {
    #    use Business::Shipping;
    #    my $support_files_installed = Business::Shipping::Config::support_files();
    #    if ( $support_files_installed ) {
    #        $my_globals{ SUPPORT_FILES_DIR } = $support_files_installed;
    #    }
    #};
    
    # ignore errors.  If Business::Shipping isn't installed, don't make
    # a big deal about it.
    
    $@ = ''; 
    
    
    my $question = qq(
             ---  $module data directory  ---
  
$module data directory:);

        $my_globals{ DATA_DIR } = prompt( 
            $question, 
            $my_globals{ DATA_DIR },
        );
    
	$my_globals{ DATA_DIR } =~ s:[\\/]\s*$::;
	$my_globals{ DATA_DIR } =~ s:^\s*::;

	my %EXTRA_CONFIG_OPTIONS;
    #$EXTRA_CONFIG_OPTIONS{ } 
	#$EXTRA_CONFIG_OPTIONS{ OPTION_NAME } = 'value';
    
	return \%EXTRA_CONFIG_OPTIONS;
}
