use inc::Module::Install 1.00;

name          'CPAN-Inject';
all_from      'lib/CPAN/Inject.pm';
requires      'File::Spec'      => '0.80';
requires      'File::stat'      => '1.00';
requires      'File::chmod'     => '0.30';
requires      'File::Path'      => '1.00';
requires      'File::Copy'      => '2.02';
requires      'File::Basename'  => '2.6';
requires      'Params::Util'    => '0.21';
requires      'CPAN'            => '1.36';
requires      'CPAN::Checksums' => '1.05';
test_requires 'Test::More'      => '0.42';
test_requires 'Test::Script'    => '1.02';
test_requires 'File::Remove'    => ($^O eq 'MSWin32')
	? '0.38'  # 0.36 had lots of Win32 fixes
	: '0.34'; # No need to be aggressive otherwise
install_script 'cpaninject';

WriteAll;
