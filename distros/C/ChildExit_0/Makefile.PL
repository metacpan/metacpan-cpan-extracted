use ExtUtils::MakeMaker;

our $APACHE_HOME = '/usr/local/apache' ;

$perl = '$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB)' ;

die "Please specify APACHE_HOME in $0, line 3\n\n" unless $APACHE_HOME
		&& -d $APACHE_HOME ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::ChildExit',
    'VERSION_FROM'	=> 'ChildExit.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ChildExit.pm', # retrieve abstract from module
       AUTHOR     => 'Jim Schueler <jschueler@tqis.com>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);



sub MY::install {
	package MY ;

	my $inherited = shift->SUPER::install( @_ ) ;

	$inherited =~ s/(install :: .*)/$1 apache/ ;
	$inherited .= <<EOF ;

apache :: pure_all
	$main::perl httpd.conf.pl $main::APACHE_HOME

EOF
	}
