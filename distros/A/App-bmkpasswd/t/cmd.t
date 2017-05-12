use Test::More;
use strict; use warnings;

BEGIN {
  if ($^O eq 'MSWin32') {
    require Test::More;
    Test::More::diag(
      "This test is broken on Windows, a platform the author does not have
      access to -- although it is reported that the 'bmkpasswd' utility does
      work as-advertised on MSWin32 platforms. Pull requests welcome!
      http://github.com/avenj/app-bmkpasswd"
    );
    Test::More::plan(skip_all => 'these tests are known to fail on Windows');
  }

  if ($ENV{AUTOMATED_TESTING} && $^O ne 'MSWin32' && getpwuid($<) eq 'njh') {
    # obnoxious and useless test noise, something's fucky with this cat's
    # smokers; f.ex:
    # http://www.cpantesters.org/cpan/report/82c71a7e-e6a9-11e5-8839-f3218d218ed8
    require Test::More;
    Test::More::plan(skip_all => 
      "this looks like one of Nigel Horne's busted smokers"
    )
  }
}

use Test::Cmd;

use Config;
my $perl = $Config{perlpath};
if ($^O ne 'VMS') {
  $perl .= $Config{_exe} unless $perl =~ /$Config{_exe}$/i
}

my $cmd = Test::Cmd->new(
  prog        => 'bin/bmkpasswd',
  interpreter => $perl,
  workdir     => '',
);

{ $cmd->run(args => '-h');
  is $? >> 8, 0, 'bmkpasswd -h exit 0';
  ok !$cmd->stderr, 'bmkpasswd -h produced no stderr';
  like $cmd->stdout, qr/bmkpasswd/, 'bmkpasswd -h';
}

{ $cmd->run(args => '--version');
  is $? >> 8, 0, 'bmkpasswd --version exit 0';
  ok !$cmd->stderr, 'bmkpasswd --version produced no stderr';
  like $cmd->stdout, qr/bmkpasswd/, 'bmkpasswd --version';
}

{ $cmd->run(args => '--man');
  is $? >> 8, 0, 'bmkpasswd --man exit 0';
  ok !$cmd->stderr, 'bmkpasswd --man produced no stderr';
  like $cmd->stdout, qr/^NAME/, 'bmkpasswd --man';
}

{ $cmd->run(args => '--usage');
  is $? >> 8, 2, 'bmkpasswd --usage exit 2';
  like $cmd->stderr, qr/^Usage/, 'bmkpasswd --usage';
  ok !$cmd->stdout, 'bmkpasswd --usage produced no stdout';
}

{ $cmd->run(args => '--available');
  is $? >> 8, 0, 'bmkpasswd --available exit 0';
  ok !$cmd->stderr, 'bmkpasswd --available produced no stderr';
  like $cmd->stdout, qr/bcrypt\n/, 'bmkpasswd --available';
}

{ $cmd->run(stdin => 'foo');
  is $? >> 8, 0, 'bmkpasswd (defaults) exit 0';
  like $cmd->stderr, qr/Password/, 'bmkpasswd prompted on stderr';
  my $crypt = $cmd->stdout;
  chomp $crypt;
  cmp_ok length($crypt), '==', 60, 'bcrypt output correct length';
  
  $cmd->run(args => "--check=@{[quotemeta $crypt]} foo");
  is $? >> 8, 0, 'bmkpasswd --check exit 0';
  ok !$cmd->stderr, 'bmkpasswd --check produced no stderr' 
    or diag $cmd->stderr;
  cmp_ok $cmd->stdout, 'eq', "Match\n$crypt\n",
    'bmkpasswd --check returned hash';

  $cmd->run(args => "--check=@{[quotemeta $crypt]} bar");
  is $? >> 8, 1, 'bmkpasswd -c bad passwd exit 1';
  ok !$cmd->stdout, 'bad passwd produced no stdout';
}

{ $cmd->run(args => '-m bcrypt -w 2 foo');
  is $? >> 8, 0, 'bmkpasswd (-m bcrypt -w 2) exit 0';
  my $crypt = $cmd->stdout;
  chomp $crypt;
  cmp_ok length($crypt), '==', 60, 'bcrypt output correct length';
  ok index($crypt, '$2a$02') == 0, 'bcrypt tuned work cost ok';
  
  $cmd->run(args => "-c @{[quotemeta $crypt]} foo");
  cmp_ok $cmd->stdout, 'eq', "Match\n$crypt\n",
    'bmkpasswd -c (tuned work cost) returned hash';
}

require App::bmkpasswd;
if (App::bmkpasswd::mkpasswd_available('sha256')) { 
  diag "Found SHA support";
  $cmd->run(args => '-m sha256', stdin => 'foo');
  is $? >> 8, 0, 'bmkpasswd (-m sha256) exit 0';
  my $crypt = $cmd->stdout;
  chomp $crypt;
  ok index($crypt, '$5$') == 0, 'sha256 hash looks ok';
  
  $cmd->run(args => "-c @{[quotemeta $crypt]} foo");
  cmp_ok $cmd->stdout, 'eq', "Match\n$crypt\n",
    'bmkpasswd -c (sha256) returned hash';
}

done_testing
