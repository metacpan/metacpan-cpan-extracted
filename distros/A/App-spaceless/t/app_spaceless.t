use Test2::V0 -no_srand => 1;
use App::spaceless;
use Capture::Tiny qw( capture capture_stdout );
use Env qw( @PATH );
use File::Temp qw( tempdir );
use Path::Class qw( file dir );
use Config;

subtest 'running_Shell' => sub {
  my($out, $err, $shell) = capture { App::spaceless::_running_shell() };
  note $err if $err;
  isa_ok $shell, 'Shell::Guess';
  note "guessed shell = ", $shell->name;
};

subtest '--version' => sub {
  my($out, $err, $ret) = capture { App::spaceless->main('--version') };
  chomp $out;
  is $ret, 1, 'exit is 1';
  my $ver = $App::spaceless::VERSION // 'dev';
  is $out, "App::spaceless version $ver", 'output';
  is $err, '', 'error';
};

subtest '-v' => sub {
  my($out, $err, $ret) = capture { App::spaceless->main('-v') };
  chomp $out;
  is $ret, 1, 'exit is 1';
  my $ver = $App::spaceless::VERSION // 'dev';
  is $out, "App::spaceless version $ver", 'output';
  is $err, '', 'error';
};

subtest '-f' => sub {
  my $tmp = dir( tempdir( CLEANUP => 1 ));
  ok -d $tmp, "dir created";
  
  my $expected;
  
  subtest 'spaceless (no args)' => sub {
    my($out, $err, $exit) = capture { App::spaceless->main };
    is $exit, 0, 'exit okay';
    is $err, '', 'error is empty';
    isnt $out, '', 'output is not empty';
    
    $expected = $out;
  };
  
  my $file = $tmp->file('foo.txt');
  
  my $actual;
  
  subtest "spaceless -f $file" => sub {
    my($out, $err, $exit) = capture { App::spaceless->main(-f => $file->stringify) };
    is $exit, 0, 'exit okay';
    is $err, '', 'error is empty';
    is $out, '', 'output is not empty';
    
    $actual = $file->slurp;
  };
  
  is $actual, $expected, 'output matches';
  
  note $actual;
};

subtest 'cmd.exe' => sub {
  skip_all 'only on MSWin32 and cygwin' unless $^O =~ /^(MSWin32|cygwin)$/;
  my($cmd_exe) = grep { -e $_ } grep !/\s/, map { "$_/cmd$Config{exe_ext}" } @PATH;
  skip_all 'unable to find sh' unless defined $cmd_exe;
  note 'full path:', $cmd_exe;

  my $tmp = dir( tempdir( CLEANUP => 1 ) );
  
  my $run_cmd = sub {
    my($path) = @_;
    $path = Cygwin::posix_to_win_path($path) if $^O eq 'cygwin';
    my @cmd = ($path);
    @cmd = ($cmd_exe, '/c', @cmd) if $^O eq 'cygwin';
    note "execute: @cmd";
    system @cmd;
    $?;
  };
  
  my $script1 = file( $tmp, 'test1.cmd' );
  {
    $script1->spew("\@echo off\necho hi there\n");
    my($out, $err, $ret) = capture { $run_cmd->($script1) };
    skip_all "really really simple .cmd script didn't exit 0" unless $ret == 0;
    skip_all "really really simple .cmd script had error output" unless $err eq '';
    skip_all "really really simple .cmd script didn't have the expected output" unless $out =~ /hi there/;
  };
  
  my $dir1 = dir($tmp, 'Program Files', 'Foo', 'bin');
  my $dir2 = dir($tmp, 'Program Files (x86)', 'Foo', 'bin');
  note capture_stdout { map { $_->mkpath(1,0700) } $dir1, $dir2 };
  ok -d $dir1, "dir $dir1";
  ok -d $dir2, "dir $dir2";

  unshift @PATH, $dir1, $dir2;

  my $set_path;

  subtest 'spaceless --cmd' => sub {
    my($out, $err, $exit) = capture { App::spaceless->main('--cmd') };
    is $exit, 0, 'exit is 0';
    is $err, '', 'error is empty';
    isnt $out, '', 'output is not empty';
    $set_path = $out;
  };
  
  note "[set_path] begin";
  note $set_path;
  note "[set_path] end";

  splice @PATH, 0, 2; 

  $tmp->file('caller2.cmd')->openw->print($set_path, "\n\nscript2.cmd\n");
  $dir1->file('script2.cmd')->openw->print("\@echo off\necho this is script TWO\n");
  
  subtest 'script2' => sub {
    my($out, $err, $exit) = capture { $run_cmd->($tmp->file('caller2.cmd')) };
    is $exit, 0, 'exit okay';
    is $err, '', 'error is empty';
    like $out, qr{TWO}, "out matches";
  };

  $tmp->file('caller3.cmd')->openw->print($set_path, "\n\nscript3.cmd\n");
  $dir2->file('script3.cmd')->openw->print("\@echo off\necho this is script THREE\n");

  subtest 'script3' => sub {
    my($out, $err, $exit) = capture { $run_cmd->($tmp->file('caller3.cmd')) };
    is $exit, 0, 'exit okay';
    is $err, '', 'error is empty';
    like $out, qr{THREE}, "out matches";
  };
};

subtest 'bourne shell' => sub {
  skip_all 'test does not work on MSWin32' if $^O eq 'MSWin32';
  my($sh_exe) = grep { -e $_ } grep !/\s/, map { "$_/sh$Config{exe_ext}" } @PATH;
  skip_all 'unable to find sh' unless defined $sh_exe;
  note 'full path:', $sh_exe;

  my $tmp = dir( tempdir( CLEANUP => 1 ) );
  
  my $run_sh = sub {
    my($path) = @_;
    my @cmd = ($sh_exe, $path);
    note "execute: @cmd";
    system @cmd;
    $?;
  };
  
  my $script1 = file( $tmp, 'test1.sh' );
  do {
    $script1->spew("#!/bin/sh\necho hi there\n");
    my($out, $err, $ret) = capture { $run_sh->($script1) };
    skip_all "really really simple sh script didn't exit 0" unless $ret == 0;
    skip_all "really really simple sh script had error output" unless $err eq '';
    skip_all "really really simple sh script didn't have the expected output" unless $out =~ /hi there/;
  };
  
  my $dir1 = dir($tmp, 'Program Files', 'Foo', 'bin');
  my $dir2 = dir($tmp, 'Program Files (x86)', 'Foo', 'bin');
  note capture_stdout { map { $_->mkpath(1,0700) } $dir1, $dir2 };
  ok -d $dir1, "dir $dir1";
  ok -d $dir2, "dir $dir2";

  unshift @PATH, $dir1, $dir2;

  my $set_path;

  subtest 'spaceless --sh' => sub {
    my($out, $err, $exit) = capture { App::spaceless->main('--sh') };
    is $exit, 0, 'exit is 0';
    is $err, '', 'error is empty';
    isnt $out, '', 'output is not empty';
    $set_path = $out;
  };
  
  note "[set_path] begin";
  note $set_path;
  note "[set_path] end";

  splice @PATH, 0, 2; 

  $tmp->file('caller2.sh')->openw->print($set_path, "\n\nscript2.sh\n");
  $dir1->file('script2.sh')->openw->print("#!$sh_exe\necho this is script TWO\n");
  chmod(0700, $dir1->file('script2.sh'));
  
  subtest 'script2' => sub {
    my($out, $err, $exit) = capture { $run_sh->($tmp->file('caller2.sh')) };
    is $exit, 0, 'exit okay';
    is $err, '', 'error is empty';
    like $out, qr{TWO}, "out matches";
  };

  $tmp->file('caller3.sh')->openw->print($set_path, "\n\nscript3.sh\n");
  $dir2->file('script3.sh')->openw->print("#!$sh_exe\necho this is script THREE\n");
  chmod(0700, $dir2->file('script3.sh'));

  subtest 'script3' => sub {
    my($out, $err, $exit) = capture { $run_sh->($tmp->file('caller3.sh')) };
    is $exit, 0, 'exit okay';
    is $err, '', 'error is empty';
    like $out, qr{THREE}, "out matches";
  };
};

subtest 'actual spacelessness' => sub {
  skip_all 'only for MSWin32 and cygwin' unless $^O =~ /^(MSWin32|cygwin)$/;

  my $tmp = dir( tempdir( CLEANUP => 1 ));
  
  my @foo = map { $tmp->subdir($_) } 'nospace1', 'one space', 'no_space2', 'reallyreallyreallyreallyreallylongpath';
  note capture_stdout { $_->mkpath(1, 0700) for @foo };
  
  $ENV{FOO} = join $Config{path_sep}, @foo;
  note "FOO=$ENV{FOO}";
  
  my $path_set;
  
  subtest 'spaceless --sh FOO' => sub {
    my($out, $err, $exit) = capture { App::spaceless->main('--sh', 'FOO') };
    is $exit, 0, 'exit okay';
    is $err, '', 'no error';
    isnt $out, '', 'some output';
    $path_set = $out;
  };
  
  my $path;
  
  if($path_set =~ /FOO='(.*?)'/)
  {
    $path = $1;
    pass "found path $path";
  }
  else
  {
    fail 'path not found';
  }
  
  unlike $path, qr{\s}, "no white space";
  like $path, qr{nospace1}, "contains nospace1";
  like $path, qr{no_space2}, "contains no_space2";
  like $path, qr{reallyreallyreallyreallyreallylongpath}, 'contains reallyreallyreallyreallyreallylongpath';
  
};

subtest 'trim' => sub {
  my $tmp = dir( tempdir ( CLEANUP => 1 ));
  skip_all "$tmp matches dir1 or dir2" if $tmp =~ /dir[12]/;
  
  $ENV{FOO} = join $Config{path_sep}, $tmp->subdir('dir1'), $tmp->subdir('dir2');
  $tmp->subdir('dir1')->mkpath(0,0700);
  
  my $path_set;
  
  subtest 'spaceless --trim --sh FOO' => sub {
    my($out, $err, $exit) = capture { App::spaceless->main('--trim', '--sh', 'FOO') };
    is $exit, 0, 'exit okay';
    is $err, '', 'no error';
    isnt $out, '', 'some output';
    $path_set = $out;
  };
  
  note $path_set;
  
  like $path_set, qr{dir1}, 'contains dir1';
  unlike $path_set, qr{dir2}, 'does not contain dir2';
};

subtest '--no-cygwin' => sub {
  skip_all "cygwin only" unless $^O eq 'cygwin';
  my $tmp = dir( tempdir ( CLEANUP => 1 ));
  skip_all "$tmp matches dir1, dir2 or dir3" if $tmp =~ /dir[123]/;
  
  my $dir3 = Cygwin::posix_to_win_path($tmp->subdir('dir3'));
  $dir3 =~ s{^(.):\\(.*)$}{/cygdrive/$1/$2};
  $dir3 =~ s{\\}{/}g;
  
  $ENV{FOO} = join $Config{path_sep}, $tmp->subdir('dir1'), $dir3;
  $_->mkpath(0,0700) for map { $tmp->subdir($_) } qw( dir1 dir2 dir3 );
  note "FOO=$ENV{FOO}";
  
  my $path_set;
  
  subtest 'spaceless --no-cygwin --cmd FOO' => sub {
    my($out, $err, $exit) = capture { App::spaceless->main('--no-cygwin', '--cmd', 'FOO') };
    is $exit, 0, 'exit okay';
    is $err, '', 'no error';
    isnt $out, '', 'some output';
    $path_set = $out;
  };
  
  note $path_set;
  
  unlike $path_set, qr{dir1}, "does not contain dir1";
  like $path_set, qr{dir3}, "does contain dir3";
  
};

done_testing;
