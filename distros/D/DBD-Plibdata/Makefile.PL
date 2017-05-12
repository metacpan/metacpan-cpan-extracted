use DBI 1.43;
use DBI::DBD;
use ExtUtils::MakeMaker;

WriteMakefile(
             dbd_edit_mm_attribs( {
                 'NAME'         => 'DBD::Plibdata',
                 'VERSION'	=> '0.06',
                 'INC'          => $DBI_INC_DIR,
                 'dist'         => { 'SUFFIX'   => '.gz',
                                     'COMPRESS' => 'gzip -9f' },
                 'realclean'    => { FILES => '*.xsi' },
		 'PREREQ_PM'	=> { 'DBI' => '1.43', 
		 		'Digest::MD5' => '2.16',
				'IO::Socket::INET' => '1.25'},
             },
             { create_pp_tests => 0})
);

package MY;
sub postamble { return main::dbd_postamble(@_); }
sub libscan {
             my ($self, $path) = @_;
             ($path =~ m/\~$/) ? undef : $path;
}

print <<EOT;

To run 'make test', do:
\$ make test INFORMIXSERVER=ifxhost INFORMIXDB=ifxdb PLBHOST=hostname PLBPORT=1234 PLBUSER=username PLBPASS=password
EOT
