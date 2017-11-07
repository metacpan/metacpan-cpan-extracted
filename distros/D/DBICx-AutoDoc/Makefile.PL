use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'templates';

my $eumm_version = eval $ExtUtils::MakeMaker::VERSION;
my %eumm_args = (
  NAME => 'DBICx::AutoDoc',
  ABSTRACT_FROM => 'lib/DBICx/AutoDoc.pm',
  AUTHOR => 'Jason Kohles <email@jasonkohles.com>',
  LICENSE => 'perl',
  VERSION_FROM => 'lib/DBICx/AutoDoc.pm',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.42',
    'File::ShareDir::Install' => '0',
  },
  PREREQ_PM => {
    'DBIx::Class' => '0',
    'Template' => '0',
    'Carp' => '0',
    'Class::Accessor::Grouped' => '0',
    'FindBin' => '0',
    'Data::Dump' => '0',
    'File::Temp' => '0',
    'Pod::Usage' => '0',
    'Getopt::Long' => '0',
    'Tie::IxHash' => '0',
    'File::ShareDir' => '1.00',
  },
  TEST_REQUIRES => {
    'Test::More' => '0',
  },
  EXE_FILES => [ qw(dbicx-autodoc) ],
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      repository => {
        type => 'git',
        url => 'git@github.com:ilmari/dbicx-autodoc.git',
        web => 'https://github.com/ilmari/dbicx-autodoc',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    no_index => {
      directory => [qw(examples templates xt)],
    },
  },
);
sub _move_to {
  my ($hash, $fromkey, $tokey) = @_;
  $hash->{$tokey} = {
    %{ $hash->{$tokey} || {} },
    %{ delete($hash->{$fromkey}) || {} },
  };
}
delete $eumm_args{META_MERGE} if $eumm_version < 6.45_01;
_move_to(\%eumm_args, 'CONFIGURE_REQUIRES', 'PREREQ_PM')
  if $eumm_version < 6.51_03;
_move_to(\%eumm_args, 'BUILD_REQUIRES', 'PREREQ_PM')
  if $eumm_version < 6.55_01;
$eumm_args{NO_MYMETA} = 1
  if $eumm_version >= 6.57_02 and $eumm_version < 6.57_07;
_move_to(\%eumm_args, 'TEST_REQUIRES', 'PREREQ_PM')
  if $eumm_version < 6.63_03;
WriteMakefile(%eumm_args);

package MY;
use File::ShareDir::Install qw(postamble);
