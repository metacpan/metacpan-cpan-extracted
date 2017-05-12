use strict;
use warnings;

use Module::Build 0.4004;

my $perl_ver = 5.010001;
my $name     = 'Class-Usul'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'recommends' => {
    'IPC::Run' => '0.89',
    'Proc::ProcessTable' => '0.42'
  },
  'requires' => {
    'Class::Inspector' => '1.28',
    'Class::Null' => '2.110730',
    'Crypt::CBC' => '2.33',
    'Crypt::Twofish2' => '1.02',
    'Data::Printer' => '0.36',
    'Data::Record' => '0.02',
    'Date::Format' => '2.24',
    'DateTime::Format::Epoch' => '0.16',
    'Exporter::Tiny' => '0.042',
    'File::DataClass' => 'v0.68.0',
    'File::Gettext' => 'v0.30.0',
    'File::HomeDir' => '1.0',
    'File::Which' => '1.18',
    'Getopt::Long::Descriptive' => '0.099',
    'IO::Interactive' => 'v0.0.6',
    'IPC::SRLock' => 'v0.30.0',
    'JSON::MaybeXS' => '1.003',
    'Log::Handler' => '0.84',
    'Module::Runtime' => '0.014',
    'Moo' => '2.000001',
    'Pod::Eventual' => '0.094001',
    'Sub::Install' => '0.928',
    'Term::ReadKey' => '2.33',
    'Text::Autoformat' => '1.72',
    'Time::Zone' => '2.24',
    'Try::Tiny' => '0.22',
    'Type::Tiny' => '1.000002',
    'Unexpected' => 'v0.43.0',
    'namespace::autoclean' => '0.26',
    'namespace::clean' => '0.25',
    'perl' => '5.010001'
  },
  'test_requires' => {
    'Capture::Tiny' => '0.22',
    'File::Spec' => '0',
    'Hash::MoreUtils' => '0.05',
    'Module::Build' => '0.4004',
    'Module::Metadata' => '0',
    'Sys::Hostname' => '0',
    'Test::Deep' => '0.108',
    'Test::Requires' => '0.06',
    'version' => '0.88'
  },
};
my $testing  = sub { $ENV{AUTOMATED_TESTING}
                  || $ENV{PERL_CPAN_REPORTER_CONFIG}
                  || $ENV{PERL5_CPANPLUS_IS_VERSION} };
my $whimper  = sub { print {*STDOUT} $_[ 0 ]."\n"; exit 0 };
my $stop     = sub {
   $testing->() or $whimper->( $_[ 0 ] );
   $prereqs->{build_requires} = { %{ $prereqs->{configure_requires} } };
   $prereqs->{test_requires } = { %{ $prereqs->{configure_requires} } };
   $prereqs->{test_requires }->{ 'Test::Requires' } = 0.06;
   delete $prereqs->{requires};
};

# Not interested in reports below min perl ver
$] < $perl_ver and $stop->( "Minimum required Perl version is ${perl_ver}" );

Module::Build->subclass( code => do { local $/; <DATA> } )->new(
   'module_name' => $name,
   'notes'       => { min_perl_version => $perl_ver, testing => $testing->() },
   %{ $prereqs },

)->create_build_script;

exit 0;

__DATA__

sub _added_to_INC { # CVE-2016-1238
  my $self = shift; my %seen;

  for ($self->_default_INC) { $seen{ $_ }++ }

  return grep { not $seen{ $_ }++ } $self->base_dir, @INC;
}
