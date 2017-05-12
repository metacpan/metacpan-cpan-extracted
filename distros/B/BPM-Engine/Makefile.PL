use strict;
use warnings;

sub author_requires     {}
sub author_tests        {}
sub readme_from         {}
sub auto_set_repository {}
sub version_check       {}
sub manifest_skip       {}
sub auto_manifest       {}
sub auto_license        {}
sub auto_include        {}
sub auto_include_deps   {}

use inc::Module::Install;

name            'BPM-Engine';
all_from        'lib/BPM/Engine.pm';
readme_from;
homepage        'http://bpmengine.org/';

author_requires 'Module::Install::AuthorRequires';
author_requires 'Module::Install::AutoManifest';
author_requires 'Module::Install::AutoLicense';
author_requires 'Module::Install::AuthorTests';
author_requires 'Module::Install::ReadmeFromPod';
author_requires 'Module::Install::ExtraTests';
author_requires 'Module::Install::ManifestSkip';
author_requires 'Module::Install::GithubMeta';
author_requires 'Module::Install::Repository';
author_requires 'Module::Install::VersionCheck';

author_requires 'Test::Pod'                  => '1.14';
author_requires 'Test::Pod::Coverage';
author_requires 'Pod::Coverage::Moose';
author_requires 'Perl::Critic'               => '1.11';
author_requires 'Perl::Critic::Swift'        => '1.0.3';
author_requires 'Test::MinimumVersion'       => '0.101080';
author_requires 'Test::Perl::Critic'         => '1.02';

build_requires  'Test::More'                 => '0.92';
build_requires  'Test::Exception'            => '0.29';
build_requires  'Test::Moose'                => '1.17';
build_requires  'Test::Fatal'                => '0.003';
build_requires  'Test::Requires'             => '0.06';
build_requires  'Test::NoWarnings'           => '1.02';

# minimum versions required upstream (indirect deps)
requires        'MooseX::Method::Signatures' => '0.42';
requires        'YAML::LibYAML'              => '0.18';
requires        'Config::Any'                => '0.23';

# direct dependencies
requires        'aliased'                    => '0';
requires        'parent'                     => '0';
requires        'namespace::clean'           => '0.18';
requires        'namespace::autoclean'       => '0.11';
requires        'DateTime'                   => '0.53';
requires        'Sub::Exporter'              => '0.98';
requires        'Path::Class'                => '0.21';
requires        'File::ShareDir'             => '1.03';
requires        'JSON'                       => '0';
requires        'Silly::Werder'              => '0.90';
requires        'Data::GUID'                 => '0.046';
requires        'Class::MOP'                 => '1.1';
requires        'Try::Tiny'                  => '0.11';
requires        'Exception::Class'           => '1.29';
requires        'Template'                   => '2.20';
requires        'Text::Xslate'               => '1.0012';
requires        'Text::Xslate::Bridge::TT2Like' => '0';
requires        'XML::LibXML'                => '1.70';
requires        'XML::LibXML::Simple'        => '0.13';
requires        'Class::Workflow'            => '0.11';
requires        'BPM::XPDL'                  => '0.04';
requires        'Graph'                      => '0.94';
requires        'Moose'                      => '2.0601';
requires        'MooseX::StrictConstructor'  => '0.07';
requires        'MooseX::NonMoose'           => '0.22';
requires        'MooseX::Types'              => '0.23';
requires        'MooseX::Types::UUID'        => '0.02';
requires        'MooseX::Types::DBIx::Class' => '0.05';
requires        'MooseX::Declare'            => '0.35';
requires        'MooseX::LogDispatch'        => '1.20';
requires        'MooseX::Traits'             => '0.11';
requires        'MooseX::SimpleConfig'       => '0.09';
requires        'DBIx::Class'                => '0.08';
requires        'DBIx::Class::InflateColumn::Serializer' => '0.02';
requires        'DBIx::Class::DynamicDefault'=> '0.03';
requires        'DBIx::Class::UUIDColumns'   => '0.02';
requires        'DBIx::Class::TimeStamp'     => '0.14';

tests           't/*/*.t';
author_tests    'xt';

manifest_skip;
auto_set_repository;
auto_manifest;
auto_license;
auto_include;
version_check;

auto_include_deps;
install_share 'share';
auto_install;
WriteAll;
