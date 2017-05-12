#
# Copyright (c) 2011-2015 T.v.Dein <tlinden |AT| cpan.org>.
#
# Licensed under the terms of the Artistic License 2.0
# see: http://www.perlfoundation.org/artistic_license_2_0
#

require 5.004;
use ExtUtils::MakeMaker;

my %optional = (
		  'Bytes::Random::Secure' => 0.09,
		);

foreach my $module (sort keys %optional) {
  eval "require $module";
  if ($@) {
    warn("Optional module $module not installed, $optional{$module}\n");
  }
}


my %params = (
	      'NAME'         => 'Crypt::PWSafe3',
	      'VERSION_FROM' => 'lib/Crypt/PWSafe3.pm',
	      'PREREQ_PM'    => { 'Digest::HMAC'   => 1.00,
				  'Digest::SHA'    => 1.00,
				  'Crypt::CBC'     => 2.30,
				  'Crypt::ECB'     => 1.45,
				  'Crypt::Twofish' => 2.14,
				  'Crypt::Random'  => 1.25,
				  'Data::UUID'     => 1.217,
				  'Shell'          => 0.5,
				  'File::Temp'     => 0,
				},
	      'AUTHOR'       => 'T.v.Dein <tlinden@cpan.org>',
	      'clean'        => {
				 FILES                   => 't/*.out *~ */*~ */*/*~ */*/*/*~'
				},
		($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'perl', ) : ()),
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $params{META_MERGE} = {
        resources => {
            homepage    => 'http://www.daemon.de/',
            bugtracker  => 'http://github.com/tlinden/Crypt--PWSafe3',
            license     => 'http://www.perlfoundation.org/artistic_license_2_0',
            repository  => 'git://github.com/tlinden/Crypt--PWSafe3.git',
        }
    };
}

WriteMakefile( %params );
