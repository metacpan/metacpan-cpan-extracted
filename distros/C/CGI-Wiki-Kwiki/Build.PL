use Module::Build;
use File::Spec;
use File::Copy;

# This magically subclasses Module::Build. We override the install action
# to install the template files for us.
my $class = Module::Build->subclass(
  code => q{
    sub ACTION_install {
      my $self = shift;
      my $ret = $self->SUPER::ACTION_install(@_);

      # Slightly hacky. We require one of the modules that we just installed.
      # then, we pull it's path out of %INC, strip off the filename, and
      # install the templates there. Well, they have to go _somewhere_, and
      # perl doens't have a good place fir this stuff otherwise.

      require CGI::Wiki::Kwiki or die;
      my (undef, $path, undef) = File::Spec->splitpath($INC{'CGI/Wiki/Kwiki.pm'});

      mkdir( File::Spec->catfile( $path, "Kwiki" ) );
      die "Can't make template install folder: $!\n" unless (-d File::Spec->catfile( $path, "Kwiki" ) );

      mkdir( File::Spec->catfile( $path, "Kwiki", "templates" ) );
      die "Can't make template install folder: $!\n" unless (-d File::Spec->catfile( $path, "Kwiki", "templates" ) );

      print "Installing templates to $path/Kwiki/templates\n";
      opendir TEMPLATES, "templates" or die "Can't open template source folder: $!\n";
      for (grep { /\.(tt|css)$/ } readdir(TEMPLATES)) {
        print "  installing template $_\n";
        File::Copy::copy(
          File::Spec->catfile('templates', $_),
          File::Spec->catfile( $path, "Kwiki", "templates", $_ )
        ) or die "Error copying $_: $!\n";;
      }
      closedir(TEMPLATES);

      return $ret;
    }
  },
);

my $build = MyModuleBuilder->new(
    module_name => 'CGI::Wiki::Kwiki',
    license => 'perl',
    requires => {
        'perl'        => '5.6.0',
        'CGI'         => 0,
        'CGI::Wiki'   => '0.56', # for enhanced recent changes
        'CGI::Wiki::Plugin::Diff' => '0.07', # earlier is buggy
        'Template' => 0,
        'Getopt::Long' => 0,
        'Time::Piece' => 0,
        'CGI::Wiki::Search::DB' => 0,
        'Algorithm::Merge' => 0,
        'CGI::Wiki::Formatter::UseMod' => 0,
    },
    recommends => {
        'CGI::Wiki::Formatter::Multiple' => 0.02,# if you want multiple formatters
        'DBD::SQLite'         => 0, # for testing
        'DBI'                 => 0, # for testing
        'Test::HTML::Content' => 0, # for testing
    },
    build_requires => {
        'Digest::MD5' => 0, #for testing,didn't make optional as CGI::Wiki uses
        'Test::More'  => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme => 1,
    script_files => [
        'bin/cgi-wiki-kwiki-install',
        'bin/cgi-wiki-kwiki-import',
        'bin/cgi-wiki-kwiki-cgi-script',
    ],
);
$build->create_build_script;

