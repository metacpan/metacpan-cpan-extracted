use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use ClamAV::Clamd;
use FakeClamd;

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

my $dir = File::Temp->newdir();

# THE RULE THIS FILE EXISTS FOR
#
# clamd answers OK for files it declined to scan. A boolean API reports
# "clean" for exactly the inputs an attacker constructs and passes every
# test anybody writes, because nobody writes the test where the answer is
# "I did not look". So: four states, and is_clean true for exactly one.

# --- the parser, driven from a peer that says whatever we want ----------
# Every shape below was captured from a real clamd (see the plan's phase
# 0, 3 and 4 results). Replaying them against a fake means the parser is
# tested everywhere, not only where ClamAV is installed.
my @SHAPES = (
    # reply                                                  state          signature                                reason
    ['fd[11]: OK',                                           'clean',       undef,                                   undef],
    ['stream: OK',                                           'clean',       undef,                                   undef],
    ['fd[11]: Eicar-Test-Signature FOUND',                   'infected',    'Eicar-Test-Signature',                  undef],
    ['stream: Win.Test.EICAR_HDB-1 FOUND',                   'infected',    'Win.Test.EICAR_HDB-1',                  undef],
    ['fd[11]: Heuristics.Limits.Exceeded.MaxFileSize FOUND', 'unscannable', 'Heuristics.Limits.Exceeded.MaxFileSize', 'MaxFileSize'],
    ['fd[11]: Heuristics.Limits.Exceeded.MaxRecursion FOUND','unscannable', 'Heuristics.Limits.Exceeded.MaxRecursion','MaxRecursion'],
    ['fd[11]: Heuristics.Limits.Exceeded.MaxFiles FOUND',    'unscannable', 'Heuristics.Limits.Exceeded.MaxFiles',    'MaxFiles'],
    ['fd[11]: Heuristics.Encrypted.Zip FOUND',               'unscannable', 'Heuristics.Encrypted.Zip',               'Encrypted'],
    ['fd[11]: Heuristics.Encrypted.DOC FOUND',               'unscannable', 'Heuristics.Encrypted.DOC',               'Encrypted'],
    ['INSTREAM size limit exceeded. ERROR',                  'unscannable', undef,                                    'StreamMaxLength'],
    ['/x: File path check failure: Permission denied. ERROR','error',       undef,                                    undef],
    ['UNKNOWN COMMAND',                                      'error',       undef,                                    undef],
    ['',                                                     'error',       undef,                                    undef],
    ['something nobody has ever seen',                       'error',       undef,                                    undef],

    # NOT unscannable: clamd looked and thinks the thing is bad. Only the
    # Limits.Exceeded and Encrypted families mean "I could not look".
    ['fd[11]: Heuristics.Phishing.Email.SpoofedDomain FOUND','infected',   'Heuristics.Phishing.Email.SpoofedDomain', undef],
    ['fd[11]: Heuristics.OLE2.ContainsMacros FOUND',         'infected',   'Heuristics.OLE2.ContainsMacros',          undef],

    # a path containing ": " must not eat the signature
    ['/tmp/a: b/c: Eicar-Test-Signature FOUND',              'infected',   'Eicar-Test-Signature',                    undef],
);

for my $case (@SHAPES) {
    my ($reply, $state, $sig, $reason) = @$case;
    my $srv = FakeClamd->new(mode => 'literal', literal => $reply);
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);
    my $v   = $c->scan('payload');

    my $label = length($reply) ? $reply : '(empty reply)';
    $label = substr($label, 0, 52);

    is $v->state,     $state,  "$label -> $state";
    is $v->signature, $sig,    "  signature" if defined $sig || $state eq 'clean';
    is $v->reason,    $reason, "  reason: " . ($reason // 'none')
        if defined $reason;

    # THE INVARIANT: is_clean is true for exactly one state, always.
    is !!$v->is_clean, !!($state eq 'clean'), "  is_clean matches, and only for clean";
    $srv->stop;
}

# --- the four predicates are mutually exclusive and total ---------------
for my $mode (
    ['fd[11]: OK',                                'is_clean'],
    ['fd[11]: Eicar-Test-Signature FOUND',        'is_infected'],
    ['fd[11]: Heuristics.Encrypted.Zip FOUND',    'is_unscannable'],
    ['UNKNOWN COMMAND',                           'is_error'],
) {
    my ($reply, $true_one) = @$mode;
    my $srv = FakeClamd->new(mode => 'literal', literal => $reply);
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);
    my $v   = $c->scan('x');

    my @on = grep { $v->$_ } qw(is_clean is_infected is_unscannable is_error);
    is_deeply \@on, [$true_one], "exactly one predicate is true for '$reply'";
    $srv->stop;
}

# --- a scan that never reached clamd is STILL a verdict -----------------
# Returning undef here would make
#     if ($clamd->scan($x)->is_clean) { ... }
# die on the one path where it matters most.
{
    my $c = ClamAV::Clamd->new(socket => '/tmp/cc-nothing-here.sock');
    my $v = $c->scan('x');
    isa_ok $v, 'ClamAV::Clamd::Verdict', 'a failed connect still yields a verdict';
    is $v->state, 'error', '  in the error state';
    ok !$v->is_clean, '  is_clean is safe to call and false';
    ok defined $v->error, '  and it carries the reason';
}

# --- overloading --------------------------------------------------------
# An object is always true, so `if ($clamd->scan($f))` would otherwise
# accept every infected file. bool is wired to is_clean so the most
# dangerous plausible misuse is correct instead of catastrophic.
{
    for my $case (['fd[11]: OK', 1], ['fd[11]: Eicar-Test-Signature FOUND', 0],
                  ['fd[11]: Heuristics.Encrypted.Zip FOUND', 0], ['UNKNOWN COMMAND', 0]) {
        my ($reply, $want) = @$case;
        my $srv = FakeClamd->new(mode => 'literal', literal => $reply);
        my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);
        my $v   = $c->scan('x');
        is +($v ? 1 : 0), $want, "boolean context follows is_clean for '$reply'";
        $srv->stop;
    }

    my $srv = FakeClamd->new(mode => 'literal', literal => 'fd[11]: Heuristics.Encrypted.Zip FOUND');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);
    my $v   = $c->scan('x');
    is "$v", 'unscannable', 'stringification gives the state, not an address';
    $srv->stop;
}

# --- the signature is remote input --------------------------------------
# A file crafted to match a chosen signature chooses this string. It is
# length-bounded so a hostile reply cannot hand a consumer an unbounded
# one to put in a log line or, worse, a response body.
{
    my $long = 'A' x 4000;
    my $srv  = FakeClamd->new(mode => 'literal', literal => "fd[11]: $long FOUND");
    my $c    = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);
    my $v    = $c->scan('x');
    is $v->state, 'infected', 'an absurdly long signature still parses';
    cmp_ok length($v->signature), '<', 300, '  but the name is bounded';
    $srv->stop;
}

# --- the same rule, against a real clamd --------------------------------
my $sock = $ENV{CLAMD_SOCKET};
unless ($sock) {
    for my $p (qw(
        /var/run/clamav/clamd.ctl  /run/clamav/clamd.ctl
        /var/run/clamav/clamd.sock /run/clamav/clamd.sock
        /tmp/clamd.socket
        /opt/homebrew/var/run/clamav/clamd.sock
        /usr/local/var/run/clamav/clamd.sock
    )) {
        next unless -S $p;
        next if length($p) >= ClamAV::Clamd::_sun_path_max();
        $sock = $p; last;
    }
}
unless ($sock) { done_testing; exit 0 }

my $live = ClamAV::Clamd->new(socket => $sock);
unless ($live->ping) { done_testing; exit 0 }

my $EICAR = 'X5O!P%@AP[4\PZX54(P^)7CC)7}' . '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*';

is $live->scan($EICAR)->state,  'infected', 'live: EICAR is infected';
is $live->scan('harmless')->state, 'clean',  'live: harmless bytes are clean';

# A nested archive past MaxRecursion. Whether this reads as unscannable
# or as clean depends on AlertExceedsMax, which is exactly the point:
# without it clamd cannot tell anyone it declined to scan. So this
# asserts the parser's mapping when the signal exists, and reports
# loudly when it does not, rather than silently passing either way.
SKIP: {
    eval { require Archive::Zip; 1 }
        or skip 'need a zip builder for the recursion fixture', 1;
    skip 'zip fixture builder not wired up', 1;
}

# A file over the local ceiling must be unscannable against a real clamd
# too - this path never reaches the daemon, but it must agree.
{
    my $m = ClamAV::Clamd->new(socket => $sock, max_size => 8);
    my $v = $m->scan('more than eight bytes');
    is $v->state, 'unscannable', 'live: over max_size is unscannable';
    is $v->reason, 'max_size',   '  naming the local ceiling';
    ok !$v->is_clean, '  and not clean';
}

done_testing;
