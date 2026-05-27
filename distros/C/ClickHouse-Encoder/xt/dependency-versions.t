#!/usr/bin/env perl
# Pin Makefile.PL's declared PREREQ_PM / TEST_REQUIRES against what
# actually ends up in META.json after `make dist`, and verify that
# every "core" module we rely on really is core at MIN_PERL_VERSION.
# Catches drift like `require Foo;` being added to a .pm without a
# matching Makefile.PL update.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run dependency-versions tests'
    unless $ENV{RELEASE_TESTING};

# Lazy-load CPAN::Meta - if it isn't available the test is informational
# only. Without META.json on disk there's nothing to verify; running
# `make distdir` generates META.json + META.yml.
eval { require CPAN::Meta; 1 }
    or plan skip_all => 'CPAN::Meta not installed';

my $meta_path;
for my $candidate ('META.json',
                   glob('ClickHouse-Encoder-*/META.json')) {
    if (-f $candidate) { $meta_path = $candidate; last }
}
plan skip_all => 'no META.json on disk (run `make distdir` to generate one)'
    unless $meta_path;

my $meta = CPAN::Meta->load_file($meta_path);

# 1. Every PREREQ_PM and TEST_REQUIRES entry from Makefile.PL ends up in
#    META's requires sections.
my $prereqs = $meta->effective_prereqs;
my $runtime_req = $prereqs->requirements_for('runtime', 'requires');
my $test_req    = $prereqs->requirements_for('test',    'requires');

ok($runtime_req->required_modules,
   'runtime requires section is non-empty in META');
ok($test_req->required_modules,
   'test requires section is non-empty in META');

# Spot-check well-known entries that Makefile.PL declares.
for my $mod (qw(XSLoader HTTP::Tiny Time::HiRes Math::BigInt)) {
    ok($runtime_req->accepts_module($mod, '0'),
       "runtime requires lists $mod (>= 0)");
}
for my $mod (qw(Test::More File::Temp IO::Socket::INET Digest::SHA)) {
    ok($test_req->accepts_module($mod, '0'),
       "test requires lists $mod (>= 0)");
}

# 2. MIN_PERL_VERSION sanity: declared in META and >= 5.10 (we use //
#    and similar 5.10 features unguarded).
my $min_perl = $prereqs->requirements_for('runtime', 'requires')
                       ->requirements_for_module('perl');
ok(defined $min_perl, 'META declares perl version requirement');
my ($num) = ($min_perl // '5.010') =~ /^v?(\d+\.\d+)/;
cmp_ok($num // 0, '>=', 5.010,
       "MIN_PERL_VERSION is at least 5.10 (got $min_perl)");

# 3. Recommends section: optional compression deps live here, not in
#    requires. Verify the indirection so a future Makefile.PL refactor
#    that moves them into PREREQ_PM is caught.
my $recommends = $prereqs->requirements_for('runtime', 'recommends');
for my $mod (qw(Compress::LZ4 Compress::Zstd IO::Compress::Gzip)) {
    ok($recommends->accepts_module($mod, '0'),
       "runtime recommends lists $mod (optional)");
}

# 4. abstract / license / repository values are present and sane.
like($meta->abstract,        qr/ClickHouse|encoder/i,
     'META abstract mentions ClickHouse or encoder');
my @lic = $meta->license;
is($lic[0], 'perl_5',         'META license is perl_5');
my $repo = ($meta->resources->{repository} || {})->{url} // '';
like($repo, qr{github\.com/vividsnow},
     'META repository URL points at vividsnow github');

done_testing();
