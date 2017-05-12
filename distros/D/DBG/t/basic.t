use strict;
use warnings;
use Cwd qw(getcwd);
use File::Temp qw(tempfile);
our ( $fh, $filename );

BEGIN {
    ( $fh, $filename ) = tempfile( 'logXXXXX', DIR => getcwd );
    close $fh;
    $ENV{DBG_LOG} = $filename;
}
END { unlink $filename }

use DBG;
use Test::More tests => 25;
use Capture::Tiny qw(capture_stderr);

my ( $stderr, $log );
$log = '';
$log .= $stderr = capture_stderr {
    dbg "foo";
};
ok index( $stderr, '>> DEBUGGING SESSION START' ) > -1, 'opening log statement';
ok $stderr =~ /foo/, 'dbg';

sub foo { png shift };
$log .= $stderr = capture_stderr { foo() };
ok $stderr =~ /^PING main::foo/, 'png -- no args';
$log .= $stderr = capture_stderr { foo(1) };
ok $stderr =~ /^in code foo$/, 'png -- arg 1';
$log .= $stderr = capture_stderr { foo(2) };
ok $stderr =~ /^in code foo -- 2$/, 'png -- arg 2';

$log .= $stderr = capture_stderr { dmp {} };
ok $stderr =~ /^\{\}/, 'dmp';

sub bar { baz() }
sub baz { trc }
$log .= $stderr = capture_stderr { bar() };
ok $stderr =~ /^TRACE.*^1\) main::baz.*^2\) main::bar.*^END TRACE/ms, 'trc';

my $ts = ts 'foo';
ok $ts->isa('DateTime'), 'ts made DateTime';
is $ts->text, 'foo', 'ts recorded label';
$log .= $stderr = capture_stderr { $ts = rt $ts, ts };
ok $stderr =~ /^timestamp foo.*\tnegligible/s, 'rt with labeled ts';
$log .= $stderr = capture_stderr { $ts = rt $ts, ts };
ok $stderr =~ /^negligible/s, 'rt with unlabeled ts';

my $r1 = {};
my $r2 = { r => $r1 };
$r1->{r} = $r2;
$log .= $stderr = capture_stderr { cyc $r1 };
ok $stderr =~ /ref count: 2/, 'cyc';

$log .= $stderr = capture_stderr { prp 'foo', 1 };
ok $stderr =~ /^foo\? yes$/, 'prp true';
$log .= $stderr = capture_stderr { prp 'foo', 0 };
ok $stderr =~ /^foo\? no$/, 'prp false';

$log .= $stderr = capture_stderr { cnm sub {} };
ok $stderr =~ /^main::__ANON__ defined at .*\bbasic\.t:22/, 'cnm';

{
    package Foo;
    use overload '""' => sub { 'str' };
    sub new { bless {} }
    sub foo { }
}
my $foo = Foo->new;
$log .= $stderr = capture_stderr { pkg $foo, 'foo' };
ok $stderr =~ /^package: Foo; file: .*\bbasic.t; line: \d/, 'pgk -- 2 arg';
$log .= $stderr = capture_stderr { pkg $foo, 'foo', 1 };
ok $stderr =~ /^Foo$/, 'pgk -- 3 arg';

SKIP: {
    skip 'Devel::Size required', 2, unless eval { require Devel::Size };
    $log .= $stderr = capture_stderr { sz [] };
    ok $stderr =~ /^\d+$/, 'sz -- 1 arg';
    $log .= $stderr = capture_stderr { sz 'foo', [] };
    ok $stderr =~ /^foo \d+$/, 'sz -- 2 arg';
}

$log .= $stderr = capture_stderr { mtd $foo };
ok $stderr =~ /^Class: Foo.*'Foo::foo.*'Foo::new/s, 'mtd -- 1 arg';
$log .= $stderr = capture_stderr { mtd $foo, 1 };
ok $stderr =~ /^Class: Foo(?!=.*VAR1).*^foo.*^new/ms, 'mtd -- 2 arg';

{
    package Bar;
    our @ISA = qw(Foo);
}
$log .= $stderr = capture_stderr { inh 'Bar' };
ok $stderr =~
  /^Classes in the inheritance hierarchy of Bar:.*^\s+Bar.*^\s+Foo/ms, 'inh';

$log .= $stderr = capture_stderr {
    dpr sub { print "foo" }
};
like $stderr, qr/^\{.*\bprint\s.*\bfoo\b.*\}/s, 'dpr';

$log .= $stderr = capture_stderr { flt { foo => $foo } };
ok $stderr =~ /^\{ foo => 'str' \}/, 'flt';

test_log($log);

$DBG::ON = 0;    # block session closing statement

done_testing();

sub test_log {
    open my $fh, '<', $filename;
    local $/;
    my $stdout = <$fh>;
    close $fh;
    is $stdout, shift, 'output teed correctly';
}

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

