use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Which qw(which);
use Test::More;

my ($out, $err, $log);

my $dir = 't/var/basic';
my $root = Cwd::getcwd;
my $perl = Cwd::realpath($^X);
my $path_perl = which('perl');
my $path_cpanm = which('cpanm');

require './bin/plx';

sub plx {
  no warnings qw(once redefine);
  ($log, $out, $err) = ([], [], []);
  local *App::plx::say = sub { push @$out, $_[0] };
  local *App::plx::stderr = sub { push @$err, $_[0] };
  local *App::plx::barf = sub { push @$err, $_[0]; die $_[0] };
  local *App::plx::run_action_exec = sub { shift; push @$log, @_ };
  App::plx->new->run(@_);
}

sub reset_var_dir {
  chdir $root;
  remove_tree $dir;
  make_path $dir;
  chdir $dir;
}

sub plx_subtest {
  reset_var_dir;
  plx '--init';
  goto &subtest;
}

subtest 'no .plx', sub {
  reset_var_dir;
  ok(do{ eval { plx "--$_" }; @$err }, "no init: --$_ failed") for qw(
    base
    cmd
    commands
    config
    cpanm
    libs
    paths
    perl
  );
};

plx_subtest 'plx --init', sub {
  ok(-f '.plx/perl', 'file created');
};

plx_subtest 'plx --actions', sub {
  eval { plx '--actions' };
  like $err->[0], qr/No such action --actions/, 'not an action; see perldoc';
};

plx_subtest 'plx --cmd', sub {
  plx qw(--cmd echo 'ehlo');
  is_deeply $log, ['echo', "'ehlo'"];
  plx qw(--cmd perl -MData::Dumper=Dumper -E 'Dumper(@ARGV)');
  is_deeply $log, [$path_perl, '-MData::Dumper=Dumper', '-E', "'Dumper(\@ARGV)'"];
  # plx qw(--cmd /usr/local/bin/psql postgres);
  # is_deeply $log, ['/usr/local/bin/psql', 'postgres'];
};

plx_subtest 'plx --commands', sub {
  plx qw(--commands);
  is_deeply [$out, $err], [[],[]], 'commands list empty';
};

plx_subtest 'plx --config', sub {
  plx qw(--config perl set), $^X;
  plx '--perl';
  is_deeply $out, [ $perl ], '--perl output';
  plx qw(--config libspec);
  is_deeply $out, [
    '25-local.ll  local',
    '50-devel.ll  devel',
    '75-lib.dir   lib',
  ], 'libspec config';
};

if (0) {

plx_subtest 'plx --cpanm', sub {
  eval { plx qw(--cpanm --help) };
  like $err->[0], qr(-cpanm args must start with -l or -L), 'no cpanm w/o lib';
  plx qw(--cpanm -llocal --help);
  is_deeply $log, [$path_perl, $path_cpanm, '-llocal', '--help'], 'cpanm ok';
  plx qw(--config perl set), $^X;
  plx qw(--cpanm -llocal --help);
  is_deeply $log, [$perl, $path_cpanm, '-llocal', '--help'], 'custom perl cpanm ok';
};

}

plx_subtest 'plx --exec', sub {
  plx '--exec';
  ok !@$log && !@$out && !@$err;
  plx qw(--exec echo);
  is_deeply $log, ['echo'];
};

plx_subtest 'plx --help', sub {
  no warnings qw(once redefine);
  require Pod::Usage;
  my $called_usage;
  local *Pod::Usage::pod2usage = sub { $called_usage = 1 };
  plx '--help';
  ok $called_usage, 'pod2usage fired for --help';
};

plx_subtest 'plx --libs', sub {
  plx '--libs';
  is_deeply $out, [];
};

plx_subtest 'plx --paths', sub {
  plx '--paths';
  is_deeply $out, [];
};

plx_subtest 'plx --perl', sub {
  plx '--perl';
  is_deeply $out, [ scalar which('perl') ], '--perl output';
};

plx_subtest 'plx --version', sub {
  plx '--version';
  is_deeply $out, [ App::plx->VERSION ], '--version output';
};

done_testing;
