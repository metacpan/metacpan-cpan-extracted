use strict;
use warnings;
use Test::Requires qw/Test::LeakTrace/;
use Data::Monad::CondVar;
use Data::Monad::Base::Sugar;
use Test::More;

sub clear_events() {
    # Run the event loop and cleanup @timers in AE::Impl::Perl
    cv_unit->sleep(0)->recv;
}

# Initialize AE to do better leak tests.
AnyEvent::detect;

no_leaks_ok { cv_unit->sleep(.002)->recv };
no_leaks_ok { cv_unit->sleep(0)->flat_map(sub { cv_unit })->recv };
no_leaks_ok { cv_unit->flat_map(sub { cv_unit->sleep(0) })->recv };
no_leaks_ok {
    cv_unit->sleep(.0004)->timeout(.0006);
    cv_unit->sleep(.002)->recv;
};
no_leaks_ok {
    Data::Monad::Base::Sugar::for { pick sub { cv_unit } }->recv;
};
no_leaks_ok {
    Data::Monad::Base::Sugar::for { pick sub { cv_unit }; yield {} }->recv;
};
no_leaks_ok {
    Data::Monad::Base::Sugar::for {
        pick sub { cv_unit };
        let \my $x => sub { cv_unit };
    }->recv;
};
no_leaks_ok {
    Data::Monad::Base::Sugar::for {
        pick sub { cv_unit };
        satisfy { ! defined $_[0] };
     }->recv;
};
no_leaks_ok {
    Data::Monad::Base::Sugar::for {
        pick \my $x => sub { cv_unit(10 / 2)->sleep(0) };
        let \my $m => sub { cv_unit($x + 1) };
        pick \my $y => sub { $m };
        pick \my $z => sub { cv_unit($x - 1) };
        pick sub { cv_unit($y * $z) };
    }->recv;
};

no_leaks_ok { cv_unit->sleep(0)->cancel; clear_events };

no_leaks_ok { cv_unit->sleep(0)->or(cv_unit)->cancel; clear_events };
no_leaks_ok { cv_unit->sleep(0)->or(cv_unit->sleep(0))->cancel; clear_events };
no_leaks_ok { cv_unit->or(cv_unit->sleep(0))->cancel; clear_events };
no_leaks_ok { cv_unit->sleep(0)->or(cv_unit->sleep(0))->recv };
no_leaks_ok { cv_unit->sleep(0)->fail->or(cv_unit->sleep(0))->recv };

no_leaks_ok { AnyEvent::CondVar->sequence(cv_unit->sleep(0), cv_unit)->recv };

done_testing;
