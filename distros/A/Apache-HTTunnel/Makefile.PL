use strict ;
use ModPerl::MM() ;
use Apache::TestMM qw(test clean) ;
use Apache::TestRunPerl() ;


Apache::TestMM::filter_args() ;

Apache::TestRunPerl->generate_script() ;

$Apache::HTTunnel::Makefile = 1 ;
ModPerl::MM::WriteMakefile(
    NAME              => 'Apache::HTTunnel',
    VERSION_FROM      => 'lib/Apache/HTTunnel.pm', 
    PREREQ_PM         => {
		mod_perl => 2.0,
		'File::FDkeeper' => 0,
	}, 
	clean => { 
		FILES => "t/TEST t/httunnel.sock _Inline" 
	},
) ;


sub MY::postamble {
	my $make = '' ;
	$make = <<'MAKEFILE';

install::
	$(NOECHO)cd Client && $(MAKE) -f $(FIRST_MAKEFILE) install $(PASTHRU)
MAKEFILE

	if ($^O eq 'linux') { 
		$make .= <<'MAKEFILE';

install::
	mkdir -p /etc/httpd/conf.d
	$(TEST_F) /etc/httpd/conf.d/perl_httunnel.conf || $(PERL) -MApache::HTTunnel=sample_config > /etc/httpd/conf.d/perl_httunnel.conf

MAKEFILE
	}

	return $make ;
}
