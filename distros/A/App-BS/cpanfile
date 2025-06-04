requires 'perl', 'v5.40';

use utf8;
use v5.40;

requires 'Cwd';
use Cwd 'abs_path';

requires 'Const::Fast';
use Const::Fast;

const our $PWD => abs_path;

requires 'DBI';
requires 'Const::Fast::Exporter';
requires 'DBD::SQLite';
requires 'DBIx::Connector';
requires 'Inline';
requires 'Inline::C';
requires 'Object::Pad';
requires 'Syntax::Keyword::Try';
requires 'Syntax::Keyword::Defer';
requires 'Syntax::Keyword::MultiSub';
requires 'Syntax::Keyword::Dynamically';
requires 'Data::Printer';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Path::Tiny';
requires 'File::chdir';
requires 'IPC::Run3';
requires 'IO::Socket::SSL';
requires 'Net::SSLeay';
requires 'List::Util';
requires 'List::AllUtils';
requires 'Path::Tiny';
requires 'HTTP::Tinyish';
requires 'JSON::MaybeXS';
requires 'TOML::Tiny';
requires 'Struct::Dumb';
requires 'Future::AsyncAwait';
requires 'IO::Async';
requires 'IO::Async::SSL';
requires 'File::chdir';
requires 'Devel::CheckBin';

requires 'Plack'
   , dist => "CRABAPP/Plack-1.5003-TRIAL"
   , url  => "file://$PWD/vendor/Plack-1.5003-TRIAL.tar.gz";

on 'test' => sub {
  requires 'Test::More', '0.98';
  requires 'Test::CPAN::Meta', '0.25',
  # requires 'Test::PAUSE::Permissions';
  requires 'Test::Spellunker';
  requires 'Test::MinimumVersion::Fast';
  requires 'Test::Pod'
};

const our $DEV_PREREQS => sub {
  requires 'CPAN::Uploader';
  requires 'Version::Next';
  requires 'Minilla';
  requires 'Minilla::Profile::ModuleBuildTiny';
  requires 'Perl::Critic';
  requires 'Perl::Tidy';
  requires 'App::perlimports';
  requires 'Perl::Critic::Community';
  requires 'Inline';
  requires 'Inline::C';
  requires 'Inline::MakeMaker';
  requires 'ExtUtils::MakeMaker';
  requires 'Devel::StackTrace::WithLexicals', '2.01';
  requires 'Module::Build::XSUtil';
};

on 'build' => $DEV_PREREQS;
on 'develop' => $DEV_PREREQS
