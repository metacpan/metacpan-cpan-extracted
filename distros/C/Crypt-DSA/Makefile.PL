use inc::Module::Install 1.01;

all_from      'lib/Crypt/DSA.pm';
requires      'IPC::Open3'   => 0;
requires      'File::Spec'   => 0;
requires      'Digest::SHA1' => 0;
requires      'MIME::Base64' => 0;
requires      'File::Which'  => '0.05';
requires      'Math::BigInt' => '1.78';
requires      'Data::Random' => '0.05' if win32;
requires      'Data::Buffer' => '0.01';
test_requires 'Test::More'   => '0.42';

WriteAll;
