package MyIntegration;

use strict;
use warnings;
use experimental qw( signatures );
use Capture::Tiny qw( capture );
use Exporter qw( import );
use Test2::API qw( context_do );

our @EXPORT_OK = qw( run );

sub run ($script, $section, $expected, $name) {
  context_do {
    my $ctx = shift;

    my @diag;
    my @cmd = ($^X, "$script", $section);

    my($out, $err, $ret) = capture {
      system @cmd;
    };

    push @diag, "returned $ret" unless $ret == 0;
    push @diag, "$section does not match \"$out\" ne \"$expected\"" unless $out eq $expected;

    if(@diag) {
      push @diag, "+@cmd";
      push @diag, "[out]\n$out\n" if $out ne '';
      push @diag, "[err]\n$err\n" if $err ne '';
      $ctx->fail($name, @diag);
    } else {
      $ctx->pass($name);
    }

  };
}

1;
