#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Encode qw( encode_utf8 );
use Test::More;

use App::Briefing;
use App::Briefing::Filesystem;

# These tests fake the Windows environment read on any platform. On native
# Windows the real %ENV and wide API are in play, so the fakes do not apply.
plan skip_all => 'the fake Windows environment is for non-Windows hosts'
  if $^O eq 'MSWin32';

{
  package FakeWindowsFilesystem;
  use Moo;
  extends 'App::Briefing::Filesystem';
  sub is_windows { 1 }
}

my $real_home = "home-ä-技能";
my $mangled   = "home-\xE4-??";    # what the ANSI code page leaves in %ENV

my ( %wide, @asked );
{
  no warnings 'redefine';
  no warnings 'once';
  *Win32::ExpandEnvironmentStrings = sub {
    my ( $reference ) = @_;
    push @asked, $reference;
    my ( $name ) = $reference =~ /%(\w+)%\z/ or die "unexpected $reference";
    return $reference unless exists $wide{$name};   # unset: left unexpanded
    my $mode = $wide{$name};
    return $mode->{raw} if ref $mode;               # a literal result
    return "\x{FFFF}$mode";                         # the usual wide result
  };
}

sub windows_briefing {
  @asked = ();
  return App::Briefing->new(
    filesystem => FakeWindowsFilesystem->new,
    cwd        => '/nonexistent',
  );
}

sub clean_env {
  delete @ENV{qw( HOME USERPROFILE HOMEDRIVE HOMEPATH CODEX_HOME PWD CLAUDE_PLUGIN_ROOT )};
}

subtest 'wide read replaces the ANSI-mangled HOME' => sub {
  local %ENV = %ENV;
  clean_env();
  $ENV{HOME} = $mangled;
  %wide = ( HOME => $real_home );

  my $briefing = windows_briefing();
  is($briefing->home, $real_home, 'home is the wide value, not the mangled %ENV value');
  is_deeply(\@asked, ["\x{FFFF}%HOME%"], 'the wide read references the variable behind U+FFFF');
  is(
    $briefing->filesystem->join_path( $briefing->home, '.claude', 'skills' ),
    $real_home.'/.claude/skills',
    'the user skill directory is built below the wide home',
  );
};

subtest 'USERPROFILE, HOMEDRIVE and HOMEPATH, CODEX_HOME and PWD use the wide read' => sub {
  local %ENV = %ENV;
  clean_env();

  $ENV{USERPROFILE} = $mangled;
  %wide = ( USERPROFILE => $real_home );
  is(windows_briefing()->home, $real_home, 'unset HOME falls through to the wide USERPROFILE');

  clean_env();
  @ENV{qw( HOMEDRIVE HOMEPATH )} = ( 'C:', "\\Users\\$mangled" );
  %wide = ( HOMEDRIVE => 'C:', HOMEPATH => "\\Users\\$real_home" );
  is(
    windows_briefing()->home,
    "C:\\Users\\$real_home",
    'unset HOME and USERPROFILE fall through to the wide HOMEDRIVE+HOMEPATH',
  );

  clean_env();
  $ENV{HOME}       = encode_utf8($real_home);
  $ENV{CODEX_HOME} = $mangled;
  %wide = ( CODEX_HOME => "codex-ä-技能" );
  is(windows_briefing()->codex_home, "codex-ä-技能", 'CODEX_HOME is the wide value');

  clean_env();
  $ENV{PWD} = $mangled;
  %wide = ( PWD => "cwd-ä-技能" );
  is(
    App::Briefing->new(
      filesystem => FakeWindowsFilesystem->new,
      home       => '/nonexistent',
    )->cwd,
    "cwd-ä-技能",
    'PWD is the wide value',
  );
};

subtest 'HOME falls back to the %ENV value whenever the wide read is unusable' => sub {
  local %ENV = %ENV;
  my $utf8_home = encode_utf8($real_home);

  my @cases = (
    [ 'variable left unexpanded (unset in the wide environment)', undef ],
    [ 'undef result (UTF-8 code page)',                           { raw => undef } ],
    [ 'unflagged byte result',                                    { raw => 'plain-bytes' } ],
    [ 'prefix lost from the result',                              { raw => "lost-ä-技能" } ],
  );
  for my $case (@cases) {
    my ( $label, $mode ) = @$case;
    clean_env();
    $ENV{HOME} = $utf8_home;
    %wide = defined $mode ? ( HOME => $mode ) : ();
    is(windows_briefing()->home, $real_home, "$label: the decoded %ENV value is used");
  }

  clean_env();
  $ENV{USERPROFILE} = $utf8_home;
  %wide = ( HOME => 'must-not-be-used' );
  is(windows_briefing()->home, $real_home, 'a wide HOME is ignored while HOME is unset in %ENV');
  $ENV{HOME} = '';
  is(windows_briefing()->home, $real_home, 'an empty HOME counts as unset');
};

subtest 'without Windows the plain %ENV path decodes as before' => sub {
  local %ENV = %ENV;
  clean_env();
  %wide = ( HOME => 'must-not-be-used' );
  @asked = ();
  my $fs = App::Briefing::Filesystem->new;

  $ENV{HOME} = encode_utf8($real_home);
  is(
    App::Briefing->new( filesystem => $fs, cwd => '/nonexistent' )->home,
    $real_home,
    'UTF-8 bytes in %ENV decode to characters',
  );
  $ENV{HOME} = $mangled;
  is(
    App::Briefing->new( filesystem => $fs, cwd => '/nonexistent' )->home,
    $mangled,
    'bytes that are not UTF-8 stay as they are',
  );
  is_deeply(\@asked, [], 'the wide API is never consulted');
};

done_testing;
