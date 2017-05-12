use inc::Module::Install 0.76;

all_from      'lib/Data/Digest.pm';
requires      'Carp'                    => 0;
requires      'IO::Handle'              => 0;
requires      'IO::File'                => 0;
requires      'Params::Util'            => '0.10';
test_requires 'File::Spec'              => '0.80';
test_requires 'Test::More'              => '0.47';
requires      'Digest'                  => '1.06';
requires      'Digest::MD5'             => '2.33';

if ( can_cc() ) {
    # Compile the latest version
    requires  'Digest::SHA'             => '5.34';
} elsif ( can_use('Digest::SHA') ) {
    # Keep the installed version
    requires  'Digest::SHA'             => 0;
} else {
    # Install what we can on places without compilers
    requires  'Digest::SHA::PurePerl'   => 0;
}

WriteAll;
