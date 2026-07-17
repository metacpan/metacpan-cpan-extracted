package MockBuiltins;
use v5.36;
no feature 'signatures';

our $FAIL_OPEN      = 0;
our $FAIL_OPEN_PATH = undef;    # if set, only fail opens of this exact path
our $FAIL_FLOCK  = 0;
our $FAIL_CHMOD  = 0;
our $FAIL_UNLINK = 0;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ($FAIL_OPEN
            && (!defined $FAIL_OPEN_PATH
                || (defined $_[2] && $_[2] eq $FAIL_OPEN_PATH)
                || (@_ == 2 && defined $_[1] && $_[1] eq $FAIL_OPEN_PATH))
        ) {
            no warnings 'numeric';
            $! = "Injected open failure for testing";
            return 0;
        }
        goto &CORE::open;
    };
    *CORE::GLOBAL::flock = sub (*$) {
        if ($FAIL_FLOCK) {
            no warnings 'numeric';
            $! = "Injected flock failure for testing";
            return 0;
        }
        goto &CORE::flock;
    };
    *CORE::GLOBAL::chmod = sub (@) {
        if ($FAIL_CHMOD) {
            no warnings 'numeric';
            $! = "Injected chmod failure for testing";
            return 0;
        }
        goto &CORE::chmod;
    };
    *CORE::GLOBAL::unlink = sub (@) {
        if ($FAIL_UNLINK) {
            no warnings 'numeric';
            $! = "Injected unlink failure for testing";
            return 0;
        }
        # unlink can't be goto'd via &CORE::unlink ("cannot be called
        # directly"), unlike open/flock/chmod -- call it as a function.
        return CORE::unlink(@_);
    };
}

use feature 'signatures';
use Exporter 'import';
our @EXPORT = qw($FAIL_OPEN $FAIL_OPEN_PATH $FAIL_FLOCK $FAIL_CHMOD $FAIL_UNLINK);

1;
