use warnings;
use strict;

use 5.008001;
use ExtUtils::MakeMaker;
my ($dev_requires) = ( do './maint/Makefile.PL.include' or die $@ )
  unless -f 'META.yml';

my $eumm_version = eval $ExtUtils::MakeMaker::VERSION;
my %eumm_args    = (
    NAME               => 'DBIx::Class::Schema::Loader',
    VERSION_FROM       => 'lib/DBIx/Class/Schema/Loader.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => '5.008001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'DBD::SQLite'       => '1.29',
        'Test::Exception'   => '0.31',
        'Test::More'        => '0.94',
        'Test::Warn'        => '0.21',
        'Test::Deep'        => '0.107',
        'Test::Differences' => '0.60',

        # core, but specific versions not available on older perls
        'File::Temp' => '0.16',
        'File::Path' => '2.07',
    },
    test      => { TESTS => 't/*.t t/*/*.t t/*/*/*.t' },
    PREREQ_PM => {
        'Carp::Clan'                  => 0,
        'Class::Accessor::Grouped'    => '0.10008',
        'Class::C3::Componentised'    => '1.0008',
        'Class::Inspector'            => '1.27',
        'Class::Unload'               => '0.07',
        'curry'                       => '1.000000',
        'Data::Dump'                  => '1.06',
        'DBIx::Class'                 => '0.08127',
        'Hash::Merge'                 => '0.12',
        'Lingua::EN::Inflect::Number' => '1.1',
        'Lingua::EN::Tagger'          => '0.23',
        'Lingua::EN::Inflect::Phrase' => '0.15',
        'List::Util'                  => '1.33',
        'MRO::Compat'                 => '0.09',
        'namespace::clean'            => '0.23',
        'Scope::Guard'                => '0.20',
        'String::ToIdentifier::EN'    => '0.05',
        'String::CamelCase'           => '0.04',
        'Sub::Util'                   => '1.40',
        'Try::Tiny'                   => 0,

        # core, but specific versions not available on older perls
        'Digest::MD5' => '2.36',
        'Exporter'    => '5.63',
    },
    realclean => {
        FILES => 'lib/DBIx/Class/Schema/Loader/Optional/Dependencies.pod'
    },
    EXE_FILES  => [qw(script/dbicdump)],
    META_MERGE => {
        "meta-spec"    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            bugtracker => {
                web =>
                  'https://github.com/dbsrgits/dbix-class-schema-loader/issues'
            },
            repository => {
                type => 'git',
                url  => 'git@github.com/dbsrgits/dbix-class-schema-loader.git',
                web  => 'https://github.com/dbsrgits/dbix-class-schema-loader',
            },
            x_IRC         => 'irc://irc.perl.org/#dbix-class',
            license       => ['http://dev.perl.org/licenses/'],
            x_MailingList =>
              'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbix-class',
        },
        no_index => {
            directory => [qw(maint xt)],
        },
        prereqs => {
            develop => { requires => $dev_requires || +{} },
        },
    },
);

sub _move_to {
    my ( $hash, $fromkey, $tokey ) = @_;
    $hash->{$tokey} =
      { %{ $hash->{$tokey} || {} }, %{ delete( $hash->{$fromkey} ) || {} }, };
}
delete $eumm_args{META_MERGE} if $eumm_version < 6.45_01;
delete $eumm_args{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;    # too late to use so just delete
_move_to( \%eumm_args, 'TEST_REQUIRES', 'BUILD_REQUIRES' )
  if $eumm_version < 6.63_03;
_move_to( \%eumm_args, 'BUILD_REQUIRES', 'PREREQ_PM' )
  if $eumm_version < 6.55_01;
$eumm_args{NO_MYMETA} = 1
  if $eumm_version >= 6.57_02 and $eumm_version < 6.57_07;
WriteMakefile(%eumm_args);

print <<"EOF";
******************* DBIx::Class::Schema::Loader WARNING ***********************
The default attributes for belongs_to relationships for foreign keys with no
rules has been changed for most databases, and is soon changing for the rest,
as ON DELETE/UPDATE and DEFERRABLE clauses for foreign keys are now being
introspected.

THIS MAY AFFECT YOUR DDL DIFFS WHEN DEPLOYING

YOUR GENERATED CODE WILL ALMOST CERTAINLY CHANGE

Read more about the changes in "relationship_attrs" in:

perldoc DBIx::Class::Schema::Loader::Base

https://metacpan.org/module/DBIx::Class::Schema::Loader::Base#relationship_attrs

See also the "Changes" file for the last few revisions.
*******************************************************************************
EOF

# vim:et sts=4 sw=4 tw=0:
