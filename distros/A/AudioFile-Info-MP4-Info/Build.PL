use lib 'lib';
use AudioFile::Info::Build;

my $module = 'AudioFile::Info::MP4::Info';

my $b = AudioFile::Info::Build->new(module_name => $module,
                                    license => 'perl',
                                    requires => {
                                                 perl            => '5.6.0',
                                                 AudioFile::Info => 0,
                                                 MP4::Info        => 0,
                                                },
                                    build_requires     => { Module::Build => 0.38, YAML => 0 },
				    configure_requires => { Module::Build => 0.38, YAML => 0 },
                                    create_makefile_pl => 'small',
                                   );

$b->create_build_script;

$b->notes(package => $module);
$b->notes(config  => {
                      read_mp3  => 0,
                      write_mp3 => 0,
                      read_ogg  => 0,
                      write_ogg => 0,
                      pure_perl => 1,
                      read_mp4  => 1,
                     });

