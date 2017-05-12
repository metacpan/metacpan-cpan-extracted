package TestPnotes::pnotes;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;

#use Apache2::RequestUtil ();
use Apache2::SafePnotes;

use Apache2::Const -compile => 'OK';

sub handler {
    my $r = shift;

    Apache::Test::test_pm_refresh();
    plan $r, tests => 15;

    ok $r->safe_pnotes;

    ok t_cmp($r->safe_pnotes('pnotes_foo', 'pnotes_bar'),
             'pnotes_bar',
             q{$r->safe_pnotes(key,val)});

    ok t_cmp($r->safe_pnotes('pnotes_foo'),
             'pnotes_bar',
             q{$r->safe_pnotes(key)});

    ok t_cmp(ref($r->safe_pnotes), 'HASH', q{ref($r->safe_pnotes)});

    ok t_cmp($r->safe_pnotes()->{'pnotes_foo'}, 'pnotes_bar',
             q{$r->safe_pnotes()->{}});

    # unset the entry (but the entry remains with undef value)
    $r->safe_pnotes('pnotes_foo', undef);
    ok t_cmp($r->safe_pnotes('pnotes_foo'), undef,
             q{unset entry contents});
    my $exists = exists $r->safe_pnotes->{'pnotes_foo'};
    $exists = 1 if $] < 5.008001; # changed in perl 5.8.1
    ok $exists;

    # now delete completely (possible only via the hash inteface)
    delete $r->safe_pnotes()->{'pnotes_foo'};
    ok t_cmp($r->safe_pnotes('pnotes_foo'), undef,
             q{deleted entry contents});
    ok !exists $r->safe_pnotes->{'pnotes_foo'};

    my $x;

    $x=1;
    $r->safe_pnotes(x=>$x);
    $x++;
    ok t_cmp($r->safe_pnotes('x'), 1, q{increment $x});
    delete $r->safe_pnotes()->{'x'};

    $x=1;
    $r->safe_pnotes(x=>$x);
    $r->safe_pnotes->{x}++;
    ok t_cmp($x, 1, q{increment pnote});
    delete $r->safe_pnotes()->{'x'};

    $x=1;
    $r->pnotes(x=>$x);
    $x++;
    ok t_cmp($r->pnotes('x'), 2, q{original pnotes - wrong behavior});
    delete $r->pnotes()->{'x'};

    $x=1;
    $r->pnotes(x=>$x);
    $r->pnotes->{x}++;
    ok t_cmp($x, 2, q{original pnotes - increment pnote});
    delete $r->pnotes()->{'x'};

    Apache2::SafePnotes->import( 'pnotes' );

    $x=1;
    $r->pnotes(x=>$x);
    $x++;
    ok t_cmp($r->pnotes('x'), 1, q{replaced pnotes});
    delete $r->pnotes()->{'x'};

    $x=1;
    $r->pnotes(x=>$x);
    $r->pnotes->{x}++;
    ok t_cmp($x, 1, q{replaced pnotes - increment pnote});
    delete $r->pnotes()->{'x'};

    Apache2::Const::OK;
}

1;
__END__


