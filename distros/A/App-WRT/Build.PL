use Module::Build;

my $build = Module::Build->new(

  module_name => 'App::WRT',

  license  => 'gpl',

  requires => {
    'Data::Dumper'             => '2.170',
    'Exporter'                 => '5.74',
    'File::Basename'           => '2.85',
    'File::Copy'               => '2.39',
    'File::Spec'               => '3.75',
    'Getopt::Long'             => '2.52',
    'HTML::Entities'           => '3.78',
    'Image::Size'              => '3.300',
    'IPC::Cmd'                 => '1.04',
    'JSON'                     => '4.06',
    'JSON::Feed'               => '1.001',
    'Mojo::DOM'                => '9.26',
    'POSIX'                    => '1.84',
    'Text::Markdown::Discount' => '0.11',
    'Text::Textile'            => '2.13',
    'Time::HiRes'              => '1.9759',
    'XML::Atom::SimpleFeed'    => '0.900',
    'perl'                     => '5.14.0',
  },

  resources => {
    repository  => {
      url  => 'git://code.p1k3.com/gitea/brennen/wrt.git',
      web  => 'https://code.p1k3.com/gitea/brennen/wrt',
      type => 'git',
    },
  }

);

$build->create_build_script;
