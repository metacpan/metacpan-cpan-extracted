use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

sub capture_warn(&) {
    my $code = shift;
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };

    $code->();

    return @warns;
}

{
    my $done;
    is +AnyEvent::CondVar->any(
        cv_unit("NG")->sleep(.04)->map(sub { $done++; @_ }),
        cv_unit("OK")->sleep(.02)->map(sub { $done++; @_ }),
        cv_unit("NG")->sleep(.06)->map(sub { $done++; @_ }),
    )->sleep(.06)->recv, "OK";

    is $done, 1;
}

{
    eval { AnyEvent::CondVar->any(cv_fail "fail immediately")->recv };
    like $@, qr/\bimmediately\b/;
}

{
    is_deeply [capture_warn {
        AnyEvent::CondVar->any(cv_unit->sleep(0));
        cv_unit->sleep(0)->recv;
    }], [], "No warnings even when the return value isn't retained.";
}

done_testing;
