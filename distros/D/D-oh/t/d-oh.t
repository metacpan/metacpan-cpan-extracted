#!perl
use strict;
use warnings;

use Test::More;

use_ok("D'oh", 'DEBUG_ME');

# we use "#'#" to fix syntax highlighting for stupid parsers
# that do not understand ' as a package separator ;-)

my($out, $err);
do_stuff();

my $rgx = qr/^# D'oh: d-oh.t \[$$\] \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d+Z$/m;
like($out, $rgx, 'output looks right for STDOUT');
like($err, $rgx, 'output looks right for STDERR');

like($out, qr/^bee!$/m, 'text in STDOUT');
like($err, qr/^boo! at t\/d-oh\.t line \d+\.$/m, 'text in STDERR');

like($err, qr/^\["I STINK"\]$/m, 'string data in STDERR');
like($err, qr/^\{"YOU":"STINK"\}$/m, 'hash data in STDERR');
like($err, qr/^\[\{"YOU":"STINK"\},"I STINK"\]$/m, 'list data in STDERR');

done_testing();

sub do_stuff {
    my($outf, $errf) = ('./stdout_temp', './stderr_temp');
    local(*SAVEOUT, *SAVEERR);
    open(SAVEOUT, '>&STDOUT');
    open(SAVEERR, '>&STDERR');

    D'oh::stdout($outf); #'#
    D'oh::date('STDOUT'); #'#
    print "bee!\n"; #'#

    D'oh::stderr($errf); #'#
    D'oh::date(); #'#
    warn "boo!";

    D'oh::stupid_program('I STINK'); #'#
    D'oh::stupid_program({ YOU => 'STINK' }); #'#
    DEBUG_ME({ YOU => 'STINK' }, 'I STINK'); #'#

    close(STDOUT);
    close(STDERR);

    open(STDOUT, '>&SAVEOUT');
    open(STDERR, '>&SAVEERR');

    open(OLDOUT, $outf) or die $!;
    open(OLDERR, $errf) or die $!;

    while(<OLDOUT>) {$out .= $_}
    while(<OLDERR>) {$err .= $_}

    close(OLDOUT);
    close(OLDERR);

    unlink $outf or die $!;
    unlink $errf or die $!;

    note $_ for ('STDOUT:', $out, 'STDERR:', $err);
}
