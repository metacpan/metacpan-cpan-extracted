use ExtUtils::MakeMaker;

my $prereqs = {
    'LWP::Simple'       => 0,
    'XML::RSSLite'      => 0,
};

WriteMakefile(
    'NAME'		        => 'Acme::24',
    'VERSION_FROM'	    => 'lib/Acme/24.pm', # finds $VERSION
    'PREREQ_PM'		    => $prereqs, 
    ( $] >= 5.005 
        ? ( ABSTRACT_FROM    => 'lib/Acme/24.pm', # retrieve abstract from module
            AUTHOR           => 'Cosimo Streppone <cosimo@cpan.org>' )
        : ()
    ),
);
