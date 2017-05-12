#!perl

use ExtUtils::MakeMaker;

my $versionfile = "lib/Crypt/KDF/_base.pm";

my %makehash=( 
    NAME            => "Crypt::KDF", 
    AUTHOR          => "areibens\@cpan.org", 
    ABSTRACT        => "Cryptographic Key Derivation API", 
    dist            => { 
        ZIP         => "zip ", 
        ZIPFLAGS    => " -v -o -r -9 ",
        COMPRESS    => "gzip -9 -f ", 
    }, 
    PREREQ_PM       => {
    	'Digest::MD5' => 0,
    	'Digest::SHA1' => 0,
	}, 
    VERSION_FROM    => $versionfile,
);

WriteMakefile( %makehash );

exit;

__END__
