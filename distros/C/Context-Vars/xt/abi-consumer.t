#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin ();

# A second extension, written as a stranger would write one, that knows
# Context::Vars only through the header ExtUtils::Depends points it at: built
# here with HAMT's header kept out of its include path, loaded beside
# Context::Vars, and made to run a callback queue in C.

plan skip_all => 'Author tests not required for installation' unless $ENV{RELEASE_TESTING};
plan skip_all => 'no compiler recorded in Config' unless $Config{cc} && $Config{make};

# Named, and resolved from where this file is, not by counting directories up.
my $xt_dir       = abs_path($FindBin::Bin);
my $consumer_src = File::Spec->catdir($xt_dir, 'abi-consumer');
my $dist_root    = abs_path(File::Spec->catdir($xt_dir, File::Spec->updir));
my $blib_arch    = File::Spec->catdir($dist_root, 'blib', 'arch');
my $blib_lib     = File::Spec->catdir($dist_root, 'blib', 'lib');

plan skip_all => "no consumer source at $consumer_src"
    unless -f File::Spec->catfile($consumer_src, 'Consumer.xs');
plan skip_all => 'Context::Vars is not built: run make first'
    unless -f File::Spec->catfile($blib_arch, 'Context', 'Vars', 'Install', 'Files.pm');

my $build = tempdir(CLEANUP => 1);
my $pm_dir = File::Spec->catdir($build, 'lib', 'Context', 'Vars', 'ABI');
make_path($pm_dir);
copy(File::Spec->catfile($consumer_src, $_), File::Spec->catfile($build, $_)) or die "copy $_: $!"
    for 'Makefile.PL', 'Consumer.xs';
copy(File::Spec->catfile($consumer_src, 'lib', 'Context', 'Vars', 'ABI', 'Consumer.pm'),
     File::Spec->catfile($pm_dir, 'Consumer.pm')) or die "copy: $!";

local $ENV{PERL5LIB} = join $Config{path_sep}, $blib_arch, $blib_lib, grep { defined && length } $ENV{PERL5LIB};

my $log = `cd "$build" && "$^X" Makefile.PL 2>&1 && "$Config{make}" 2>&1`;
is($?, 0, 'a consumer that knows only context_vars_abi.h configures and builds') or do {
    diag($log);
    done_testing;
    exit;
};
unlike($log, qr/warning:/, 'without a compiler warning') or diag($log);
my ($inc) = $log =~ /^INC: (.*)$/m;
ok(defined $inc, 'its include path is reported');
unlike($inc // '', qr/HAMT/, 'and holds nothing of HAMT\'s') or diag "INC: $inc";

unshift @INC, File::Spec->catdir($build, 'blib', 'arch'), File::Spec->catdir($build, 'blib', 'lib');
ok(eval { require Context::Vars::ABI::Consumer; 1 }, 'it loads beside Context::Vars') or do { diag($@); done_testing; exit };

my $C = 'Context::Vars::ABI::Consumer';

# A reference count off by one shows as a warning from perl, not as a failure.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };
is($C->can('abi_version')->(), Context::Vars::_abi_version(), 'it resolved the table, at the version Context::Vars reports');

# ---- the C queue -------------------------------------------------------------
{
    package Task;
    use Context::Vars qw($id);
    our @read;
    sub start {
        my ($name) = @_;
        $id = $name;
        Context::Vars::ABI::Consumer::later(sub { push @read, "$name reads " . ($id // 'nothing') }) for 1 .. 2;
    }
}
Task::start($_) for qw(A B C);
is(Context::Vars::ABI::Consumer::run_all(1), 6, 'six callbacks ran from the C queue, last queued first');
is_deeply(\@Task::read, ['C reads C', 'C reads C', 'B reads B', 'B reads B', 'A reads A', 'A reads A'],
          'each read its own task\'s id: the C queue captured and entered for every one');

# ---- variables from C ----------------------------------------------------------------
{
    package Task;
    my @seen;
    Context::Vars::ABI::Consumer::store_scoped('id', 'from C', sub { push @seen, $id, Context::Vars::ABI::Consumer::fetch('id') });
    main::is_deeply(\@seen, ['from C', 'from C'], 'a value stored from C is read by an imported variable, and fetched back by C');
    main::ok(!defined $id, 'and is gone once the scope C opened has closed');
}

# ---- objects ---------------------------------------------------------------
{
    my $obj = Context::Vars::ABI::Consumer::current_object();
    isa_ok($obj, 'Context::Vars::Context', 'an object made by C');
    ok(Context::Vars::ABI::Consumer::is_context($obj), 'C recognises it');
    ok(!Context::Vars::ABI::Consumer::is_context(bless {}, 'Context::Vars::Context'), 'and not a forgery');
}

is(Context::Vars::_depth(), 0, 'nothing is left entered');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

# ---- version 2: elements from C ------------------------------------------------
{
    package Deep;
    use Context::Vars qw(%seen @trail);
    my @r;
    Context::Vars::_t_scope(sub {
        Context::Vars::ABI::Consumer::elem_set('%seen', 'from C', 'a', 'b');
        push @r, $seen{a}{b};
        $seen{a}{c} = 'from Perl';
        push @r, Context::Vars::ABI::Consumer::elem_get('%seen', 'a', 'c');
        my $whole = Context::Vars::ABI::Consumer::elem_get('%seen');
        push @r, join ',', sort keys %{ $whole->{a} };
        push @r, tied(%$whole) ? 'tied' : 'plain';
        Context::Vars::ABI::Consumer::elem_set('@trail', 'third', 2);
        push @r, scalar(@trail), $trail[2];
        Context::Vars::ABI::Consumer::elem_set('%seen', undef, 'a', 'b');
        push @r, exists $seen{a}{b} ? 'still there' : 'removed';
    });
    main::is_deeply(\@r, ['from C', 'from Perl', 'b,c', 'plain', 3, 'third', 'removed'],
                    'C reads and writes single elements at any depth, and Perl sees them, and the other way');
    main::ok(!exists $seen{a}, 'and they belonged to the scope C wrote them in');
}

# A store from C at the top level, with no scope: it is the program's, as an
# assignment in file code would be.
{
    package Task;
    Context::Vars::ABI::Consumer::store('id', 'top from C');
    main::is($id, 'top from C', 'a store from C outside any context is read at the top level');
    Context::Vars::ABI::Consumer::store('id', undef);
    main::ok(!defined $id, 'and a store of undef unsets it');
}

for (1 .. 3) {
    my $obj = Context::Vars::ABI::Consumer::current_object();
}
is_deeply(\@warnings, [], 'perl warned of nothing on the way');

done_testing;
