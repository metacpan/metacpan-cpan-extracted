package MyTest;

use strict;
use warnings;
use Test2::Tools::Basic;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture );
use base qw( Exporter );

our @EXPORT = qw( alienfile run last_stdout last_stderr last_exit );

sub alienfile
{
  my($str, $name) = @_;
  my(undef, $filename, $line) = caller;
  $str = '# line '. $line . ' "' . $filename . qq("\n) . $str;
  my $alienfile = path($name||'alienfile')->absolute;
  $alienfile->spew($str);
  return;
}

my $out;
my $err;
my $ret;

sub last_stdout
{
  $out;
}

sub last_stderr
{
  $err;
}

sub last_exit
{
  $ret;
}

sub run
{
  my($subcommand, @args) = @_;
  
  my $class = "App::af::$subcommand";
  
  note "[command]\naf $subcommand @args";
  
  $out = '';
  $err = '';
  ($out, $err, $ret) = capture {
    $class->new(@args)->main;
  };
  
  note "[stdout]\n$out" if defined $out && $out ne '';
  note "[stderr]\n$err" if defined $err && $err ne '';
  
  $ret;
}

1;
