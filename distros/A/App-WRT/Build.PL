use Module::Build;

my $build = Module::Build->new(

  module_name => 'App::WRT',

  license  => 'gpl',

  requires => {
    'Data::Dumper'             => '2.170',
    'Exporter'                 => '5.73',
    'File::Basename'           => '2.85',
    'File::Copy'               => '2.33',
    'File::Spec'               => '3.74',
    'Getopt::Long'             => '2.5',
    'HTML::Entities'           => '3.69',
    'Image::Size'              => '3.300',
    'JSON'                     => '4.02',
    'JSON::Feed'               => '0.001',
    'Mojo::DOM'                => '0',
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
