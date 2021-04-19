#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use Test::CodeGen::Helpers;
use CodeGen::Protection::Format::Perl;
my $version = CodeGen::Protection::Format::Perl->VERSION;

my $existing_code = update_version(<<'END');
#<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: aa97a021bd70bf3b9fa3e52f203f2660

sub sum {
    my $total = 0;
    $total += $_ foreach @_;
    return $total;
}

#>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660
END

my $protected_code = <<'END';
sub sum {
    my $total = 0;
    $total += $_ foreach @_;
    return $total;
}
END

throws_ok {
    CodeGen::Protection::Format::Perl->new(
        existing_code  => $existing_code,
        protected_code => $protected_code,
    )
}
qr/\QStart digest (aa97a021bd70bf3b9fa3e52f203f2660) does not match end digest (fa97a021bd70bf3b9fa3e52f203f2660)/,
  'If our start and end digests are not identical we should get an appropriate error';

$existing_code = <<'END';
sub sum {
    my $total = 0;
    $total += $_ foreach @_;
    return $total;
}
END

$protected_code = <<'END';
sub sum { my $total = 0; $total += $_ foreach @_; return $total; }
END

throws_ok {
    CodeGen::Protection::Format::Perl->new(
        existing_code  => $existing_code,
        protected_code => $protected_code,
    )
}
qr/Could not find the Perl start and end markers in existing_code/,
  '... or for trying to rewrite Perl without start/end markers in the text';

$existing_code = <<'END';
my $bar = 1;

#<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: aa97a021bd70bf3b9fa3e52f203f2660

sub sum {
    my $total = 0;
    $total += $_ foreach @_;
    return $total;
}

#>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: aa97a021bd70bf3b9fa3e52f203f2660

my $foo = 1;
END

$protected_code = <<'END';
my $protected_code = foo();
END

throws_ok {
    CodeGen::Protection::Format::Perl->new(
        existing_code  => $existing_code,
        protected_code => $protected_code,
    )
}
qr/\QChecksum (aa97a021bd70bf3b9fa3e52f203f2660) did not match expected checksum (fa97a021bd70bf3b9fa3e52f203f2660)/,
  '... or if our digests do not match the code, we should get an appropriate error';

my $rewrite;
lives_ok {
    $rewrite = CodeGen::Protection::Format::Perl->new(
        existing_code  => $existing_code,
        protected_code => $protected_code,
        overwrite      => 1,
    )
}
'We should be able to force an overwrite of code if the checksums do not match';

my $expected = update_version(<<'END');
my $bar = 1;

#<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: bc6f3064e7db2fe8e1628087989bfad6

my $protected_code = foo();

#>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: bc6f3064e7db2fe8e1628087989bfad6

my $foo = 1;
END

is_multiline_text $rewrite->rewritten, $expected,
  '... and get our new code back';

done_testing;
