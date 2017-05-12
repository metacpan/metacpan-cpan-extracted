use inc::Module::Install;

name('Audio-Musepack');
license('perl');
perl_version('5.005');
all_from('lib/Audio/Musepack.pm');

requires('Audio::Scan' => '0.85');

auto_install();
WriteAll();
