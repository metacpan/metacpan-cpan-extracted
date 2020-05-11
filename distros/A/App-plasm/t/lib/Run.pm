package Run;

use strict;
use warnings;
use Test::Exit ();
use App::plasm;
use Capture::Tiny qw( capture );
use Test2::API qw( context );

sub run
{
  my($class, @cmd) = @_;
  my($out, $err, $exit) = capture {
    local $0 = 'bin/plasm';
    my $ret;
    my $exit = Test::Exit::exit_code(sub { $ret = App::plasm->main(@cmd) });
    defined $exit
      ? $exit
      : $ret;
  };

  my $ctx = context();
  $ctx->note("% plasm @cmd");
  $ctx->note("[out]\n$out") if $out ne '';
  $ctx->note("[err]\n$err") if $err ne '';
  $ctx->note("ret = $exit") if $exit;
  $ctx->release;

  bless {
    out  => $out,
    err  => $err,
    exit => $exit,
  }, $class;
}

sub out { shift->{out} }
sub err { shift->{err} }
sub ret { shift->{exit} }

1;
