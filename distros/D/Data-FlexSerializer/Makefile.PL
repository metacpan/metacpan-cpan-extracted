use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME              => 'Data::FlexSerializer',
    VERSION_FROM      => 'lib/Data/FlexSerializer.pm', # finds $VERSION
    PREREQ_PM         => {
      'Storable' => '0',
      'JSON::XS' => '0',
      'Sereal::Decoder' => '0.15',
      'Sereal::Encoder' => '0.17',
      'Moose' => '0',
      'MooseX::Types' => '0',
      'MooseX::ClassAttribute' => '0',
      'MooseX::Types::Structured' => '0',
      'List::Util' => '0',
      'Compress::Zlib' => '0',
      'IO::Uncompress::AnyInflate' => '0',
      'Carp' => '0',
      'Constant::FromGlobal' => '0',
      'Test::More' => '0.88',
      'File::Spec' => '0',
      'autodie' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/FlexSerializer.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    ( $mm < 6.3002 ? () : (
        LICENSE => 'perl',
    )),
    ( $mm < 6.46 ? () : (
        META_MERGE => {
            requires => {
                perl => '5.008001',
            },
            resources => {
                repository  => 'https://github.com/tsee/Data-FlexSerializer',
            },
            no_index => {
                directory => [qw/ t /],
            }
        },
        META_ADD => {
            build_requires     => {},
            configure_requires => {}
        },
    )),
);
