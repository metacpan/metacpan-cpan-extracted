use inc::Module::Install 0.78;

all_from      'lib/Alien/BatToExeConverter.pm';
requires      'File::Which'    => '0.05';
requires      'File::ShareDir' => '1.00';
requires      'IPC::Run3'      => '0.042';
test_requires 'Test::More'     => '0.47';
test_requires 'File::Spec'     => '0.80';
test_requires 'File::Remove'   => '1.42';
install_share;

WriteAll;
