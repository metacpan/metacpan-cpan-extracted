#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempfile);

use App::Test::Generator::PodExampleExtractor;

# Helper: write a temporary .pm file with given content and return its path.
sub _tmp_pm {
	my ($content) = @_;
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh $content;
	close $fh;
	return $path;
}

# ==================================================================
# Constructor
# ==================================================================

subtest 'new() dies when file argument is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::PodExampleExtractor->new() },
		qr/file is required/,
		'missing file croaks',
	);
};

subtest 'new() dies when file does not exist' => sub {
	throws_ok(
		sub { App::Test::Generator::PodExampleExtractor->new(file => '/no/such/file.pm') },
		qr/File not found/,
		'non-existent file croaks',
	);
};

subtest 'new() succeeds for an existing file' => sub {
	my $path = _tmp_pm("package Foo;\n1;\n");
	my $ex = App::Test::Generator::PodExampleExtractor->new(file => $path);
	isa_ok($ex, 'App::Test::Generator::PodExampleExtractor');
};

# ==================================================================
# extract() — empty / no POD
# ==================================================================

subtest 'extract() returns empty arrayref when there is no POD' => sub {
	my $path = _tmp_pm("package Foo;\nsub bar { 42 }\n1;\n");
	my $ex   = App::Test::Generator::PodExampleExtractor->new(file => $path);
	my $res  = $ex->extract();
	is(ref $res, 'ARRAY', 'returns arrayref');
	is(scalar @$res, 0, 'no examples from no POD');
};

# ==================================================================
# =head1 SYNOPSIS extraction
# ==================================================================

subtest 'extract() finds verbatim block in =head1 SYNOPSIS' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head1 SYNOPSIS

    use Foo;
    my $x = Foo->new();

=cut

1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	ok(scalar @$res >= 1, 'at least one example found');
	like($res->[0]{code}, qr/use Foo/, 'SYNOPSIS code present');
	is($res->[0]{section}, 'SYNOPSIS', 'section tagged correctly');
};

# ==================================================================
# =head2 SYNOPSIS extraction (per-method)
# ==================================================================

subtest 'extract() finds verbatim block in =head2 SYNOPSIS' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head2 greet

=head2 SYNOPSIS

    my $msg = greet('Alice');

=cut

sub greet { "Hello, $_[0]!" }
1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	my @synopsis = grep { $_->{section} eq 'SYNOPSIS' } @$res;
	ok(@synopsis >= 1, 'head2 SYNOPSIS example captured');
	like($synopsis[0]{code}, qr/greet/, 'code contains greet');
};

# ==================================================================
# =for example begin/end
# ==================================================================

subtest 'extract() finds =for example begin/end blocks' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head1 NAME

Foo - test

=for example begin

    my $y = compute(5);

=for example end

=cut

sub compute { $_[0] * 2 }
1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	my @for = grep { $_->{section} =~ /for example/i } @$res;
	ok(@for >= 1, '=for example block captured');
	like($for[0]{code}, qr/compute/, 'for-example code present');
};

# ==================================================================
# Annotated single-line examples (# returns / # =>)
# ==================================================================

subtest 'extract() finds # returns annotation' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head2 add

    my $sum = add(2, 3);  # returns 5

=cut

sub add { $_[0] + $_[1] }
1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	my @ann = grep { defined $_->{expected} } @$res;
	ok(@ann >= 1, 'annotated example found');
	is($ann[0]{expected}, '5', 'expected value extracted correctly');
	like($ann[0]{code}, qr/add\(2, 3\)/, 'code text correct');
};

subtest 'extract() finds # => annotation' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head2 double

    my $d = double(7);  # => 14

=cut

sub double { $_[0] * 2 }
1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	my @ann = grep { defined $_->{expected} } @$res;
	ok(@ann >= 1, '# => annotation found');
	is($ann[0]{expected}, '14', 'expected value from # => extracted');
};

# ==================================================================
# Deduplication
# ==================================================================

subtest 'extract() deduplicates identical code blocks' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head1 SYNOPSIS

    use Foo;

=head2 new

    use Foo;

=cut

1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	my @use_foo = grep { $_->{code} eq 'use Foo;' } @$res;
	is(scalar @use_foo, 1, 'duplicate code block appears only once');
};

# ==================================================================
# Label assignment
# ==================================================================

subtest 'extract() assigns numbered labels within each section' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head2 greet

    my $x = greet('A');  # returns 'Hello, A!'
    my $y = greet('B');  # => 'Hello, B!'

=cut

sub greet { "Hello, $_[1]!" }
1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	my @greet = grep { $_->{section} eq 'greet' } @$res;
	ok(@greet >= 2, 'two greet examples');
	like($greet[0]{label}, qr/example 1/, 'first label ends in 1');
	like($greet[1]{label}, qr/example 2/, 'second label ends in 2');
};

# ==================================================================
# Real module: Sample::Module
# ==================================================================

subtest 'extract() works on Sample::Module and finds annotated examples' => sub {
	my $path = 'lib/App/Test/Generator/Sample/Module.pm';
	unless(-f $path) {
		plan skip_all => "Sample::Module not present ($path)";
	}
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $path);
	my $res = $ex->extract();
	ok(scalar @$res > 0, 'examples found in Sample::Module');
	my @ann = grep { defined $_->{expected} } @$res;
	ok(@ann >= 2, 'at least two annotated examples found');
	my ($vs) = grep { $_->{code} =~ /validate_score.*75\.5/ } @ann;
	ok(defined $vs, 'validate_score(75.5) example found');
	is($vs->{expected}, "'Pass'", "expected value is 'Pass'");
};

# ==================================================================
# Shell-command filtering (_looks_like_perl)
# ==================================================================

subtest 'extract() skips verbatim blocks containing only shell commands' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head1 SYNOPSIS

    fuzz-harness-generator -r schemas/foo.yml

    extract-schemas lib/Foo.pm && fuzz-harness-generator -r schemas/greet.yml

    use Foo;

=cut

1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	ok(!grep({ $_->{code} =~ /fuzz-harness-generator|extract-schemas/ } @$res),
		'shell-command blocks are not extracted');
	my @perl = grep { $_->{code} =~ /use Foo/ } @$res;
	is(scalar @perl, 1, 'Perl code block is still extracted');
};

subtest 'pod-example-tester neutralizes system() calls in generated output' => sub {
	my $pm = _tmp_pm(<<'PM');
package Bar;

=head1 SYNOPSIS

    my $result = Bar->run();
    system("rm -rf /");

=cut

sub run { 1 }
1;
PM
	my $out = File::Temp->new(SUFFIX => '.t', UNLINK => 1);
	system($^X, '-Ilib', 'bin/pod-example-tester', '--output', "$out", $pm) == 0
		or plan skip_all => 'pod-example-tester not runnable';
	my $generated = do { local $/; open my $fh, '<', "$out" or die $!; <$fh> };
	unlike($generated, qr/^\s+system\s*\(/m, 'no executable system() statement in generated file');
	like($generated,   qr/note\(.*skipped shell call/i, 'system() replaced with note()');
};

subtest '_looks_like_perl keeps blocks with sigils, keywords, :: and ->' => sub {
	my $pm = _tmp_pm(<<'PM');
package Foo;

=head1 SYNOPSIS

    my $obj = Foo->new();

    prove -l t/foo.t

    $obj->method();

=cut

1;
PM
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	ok(!grep({ $_->{code} =~ /prove/ } @$res), 'bare "prove" command is skipped');
	is(scalar(grep { $_->{code} =~ /Foo->new/ || $_->{code} =~ /\$obj/ } @$res),
		2, 'two Perl blocks retained');
};

done_testing();
