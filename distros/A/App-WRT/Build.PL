use Module::Build;

my $build = Module::Build->new(

  module_name => 'App::WRT',

  license  => 'gpl',

  requires => {
    'Data::Dumper'             => 0,
    'Exporter'                 => 0,
    'File::Basename'           => 0,
    'File::Copy'               => 0,
    'File::Spec'               => 0,
    'Getopt::Long'             => 0,
    'HTML::Entities'           => 0,
    'Image::Size'              => 0,
    'JSON'                     => 0,
    'POSIX'                    => 0,
    'Text::Markdown::Discount' => '0.11',
    'Text::Textile'            => 0,
    'Time::HiRes'              => 0,
    'XML::Atom::SimpleFeed'    => '0.8',
    'XML::Feed'                => 0,
    'perl'                     => '5.10.0',
  },

  recommends => {
    'CGI::Fast' => 0,
  },

  resources => {
    repository  => {
      url  => 'git://github.com/brennen/wrt.git',
      web  => 'https://github.com/brennen/wrt',
      type => 'git',
    },
  }

);

$build->create_build_script;
