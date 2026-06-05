use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::Task;
use App::karr::Foundation;

my $repo = path( tempdir( CLEANUP => 1 ) );

subtest '_agent_command resolution precedence' => sub {
  my $f = App::karr::Foundation->new( _config_data => {} );

  is $f->_agent_command( $repo, {} ), undef,
    'no agent configured -> undef';

  is $f->_agent_command( $repo, { command => 'foo' } ), 'foo',
    '.karr command used';

  is $f->_agent_command( $repo, { command => 'foo', claude => 1 } ), 'foo',
    'explicit command wins over claude: true';

  is $f->_agent_command( $repo, { claude => 1 } ),
    'claude -p "$PROMPT" --permission-mode bypassPermissions --max-turns 30',
    'claude: true synthesizes the canonical command';

  is $f->_agent_command( $repo,
    { claude => 1, claude_bin => 'claude_with_minimax', claude_max_turns => 5, claude_permission_mode => 'plan' } ),
    'claude_with_minimax -p "$PROMPT" --permission-mode plan --max-turns 5',
    'claude_bin and knobs override the defaults';
};

subtest 'config-level defaults and CLI override' => sub {
  my $fd = App::karr::Foundation->new( _config_data => { default_command => 'gd' } );
  is $fd->_agent_command( $repo, { command => 'foo' } ), 'gd',
    'config default_command beats .karr command';

  my $fc = App::karr::Foundation->new( command => 'cli', _config_data => { default_command => 'gd' } );
  is $fc->_agent_command( $repo, { command => 'foo' } ), 'cli',
    'CLI --command wins over everything';

  my $fg = App::karr::Foundation->new( _config_data => { claude => 1 } );
  like $fg->_agent_command( $repo, {} ), qr/^claude -p "\$PROMPT"/,
    'global claude: true applies when no per-repo agent';
};

subtest '_prompt_for precedence' => sub {
  my $f = App::karr::Foundation->new( _config_data => { default_prompt => 'CFG' } );
  is $f->_prompt_for( { prompt => 'KARR' } ), 'KARR', '.karr prompt wins';
  is $f->_prompt_for( {} ), 'CFG', 'config default_prompt next';

  my $f2 = App::karr::Foundation->new( _config_data => {} );
  like $f2->_prompt_for( {} ), qr/karr-coordinator skill/, 'built-in default last';
};

subtest '$PROMPT is substituted into the command at run time' => sub {
  my $rdir = path( tempdir( CLEANUP => 1 ) );
  my $f = App::karr::Foundation->new( _config_data => {} );

  my ( $code, $out ) = $f->_run_command( $rdir, {}, 'printf "%s" "$PROMPT"' );
  like $out, qr/karr-coordinator skill/, 'default prompt reaches $PROMPT';

  my ( $c2, $o2 ) = $f->_run_command( $rdir, { prompt => 'CUSTOM-PROMPT' }, 'printf "%s" "$PROMPT"' );
  is $o2, 'CUSTOM-PROMPT', 'per-repo prompt overrides';
};

subtest '_print_overview renders a board summary' => sub {
  my $rdir = path( tempdir( CLEANUP => 1 ) );
  system( 'git', 'init', '-q', "$rdir" );
  system( 'git', '-C', "$rdir", 'config', 'user.email', 'o@test.com' );
  system( 'git', '-C', "$rdir", 'config', 'user.name', 'O' );
  my $git = App::karr::Git->new( dir => "$rdir" );
  $git->write_ref( 'refs/karr/config', Dump( { version => 1 } ) );
  $git->write_ref( 'refs/karr/meta/next-id', "3\n" );
  require App::karr::BoardStore;
  my $store = App::karr::BoardStore->new( git => $git );
  $store->save_task( App::karr::Task->new( id => 1, title => 'A', status => 'in-progress', priority => 'medium', class => 'standard' ) );
  $store->save_task( App::karr::Task->new( id => 2, title => 'B', status => 'todo', priority => 'medium', class => 'standard' ) );

  my $f = App::karr::Foundation->new( _config_data => {} );
  my $out = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    $f->_print_overview( [$rdir] );
  }
  like $out, qr/\Q@{[ $rdir->basename ]}\E/, 'board name shown';
  like $out, qr/2 tasks/, 'task total shown';
  like $out, qr/in-progress:1/, 'status counts shown';
  like $out, qr/in-progress: #1/, 'in-progress ids listed';
};

done_testing;
