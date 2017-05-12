use strict;
use warnings;
use ExtUtils::MakeMaker;

my %my_globals = (
	SUPPORT_FILES_DIR	=> '/usr/local/B_Shipping_DataTools'
);

WriteMakefile(
    NAME                => 'Business::Shipping::DataTools',
    AUTHOR              => 'Dan Browning <db@kavod.com>',
    VERSION_FROM        => 'lib/Business/Shipping/DataTools.pm',
    ABSTRACT_FROM       => 'lib/Business/Shipping/DataTools.pm',
    CONFIGURE		    => \&extra_WriteMakefile_options,
    PL_FILES            => {},
    EXE_FILES           => [
        'bin/analyze.pl',
        'bin/update.pl',
    ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Config::IniFiles' => 0,
        'Archive::Zip' => 0,
        'Storable' => 0,
        'Text::CSV::Simple' => 0,
        'Business::Shipping' => 1.92,
        'Business::Shipping::DataFiles' => 1.00,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-Shipping-DataTools-*' },
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
	\@echo "Installing data files to $my_globals{SUPPORT_FILES_DIR}/data"
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/data
	\@\$(CP) --recursive --force data/*   $my_globals{SUPPORT_FILES_DIR}/data/
	\@echo "Installing config files to $my_globals{SUPPORT_FILES_DIR}/config"
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/config
	\@\$(CP) --recursive --force config/*   $my_globals{SUPPORT_FILES_DIR}/config/
};  #/qq
}

sub extra_WriteMakefile_options {
    my $module = "Business::Shipping::DataTools";
    
    my $question = qq(
    
Note: Installation is not recommended.  You may use the module without make
or make install.
    
             ---  $module Support files directory  ---
  
$module module comes with various support files for configuration, database, 
etc.  Please input the path you would like to copy these files to.  You can 
modify the path later by changing the Config.pm file.

On many systems, this directory will only be accessible by the user who 
installed perl, typically root.

$module Support files directory:);

	$my_globals{ SUPPORT_FILES_DIR } = prompt( 
        $question, 
		$my_globals{ SUPPORT_FILES_DIR },
	);
    
	$my_globals{ SUPPORT_FILES_DIR } =~ s:[\\/]\s*$::;
	$my_globals{ SUPPORT_FILES_DIR } =~ s:^\s*::;

	my %EXTRA_CONFIG_OPTIONS;
    #$EXTRA_CONFIG_OPTIONS{ } 
	#$EXTRA_CONFIG_OPTIONS{ OPTION_NAME } = 'value';
    
	return \%EXTRA_CONFIG_OPTIONS;
}
