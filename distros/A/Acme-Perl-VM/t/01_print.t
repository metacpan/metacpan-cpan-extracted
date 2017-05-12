#!perl -w

use strict;
use Test::More tests => 12;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

{
    open local(*STDOUT), '>', \my $buff;
    run_block{
        print 'foo';
    };
    is $buff, 'foo', 'print';

    open *STDOUT, '>', \$buff;
    my $foo = 'foo';
    run_block{
        print "<$foo>";
    };
    is $buff, '<foo>', 'pad_sv & concat';

    open *STDOUT, '>', \$buff;
    my $x   = 1;
    run_block{
        print $x ? 'true' : 'false';
    };
    is $buff, 'true', 'cond_expr';

    open *STDOUT, '>', \$buff;
    $x = 0;
    run_block{
        print $x ? 'true' : 'false';
    };
    is $buff, 'false', 'cond_expr';


    open *STDOUT, '>', \$buff;
    $x   = 1;
    run_block{
        if($x){
            print 'true';
        }
        else{
            print 'false';
        }
    };
    is $buff, 'true', 'enter & leave';

    open *STDOUT, '>', \$buff;
    $x = 0;
    run_block{
        if($x){
            print 'true';
        }
        else{
            print 'false';
        }
    };
    is $buff, 'false', 'enter & leave';
}

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
