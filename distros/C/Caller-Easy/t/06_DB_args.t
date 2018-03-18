use strict;
use Test::More 0.98 tests => 3;

use lib 'lib';

use Caller::Easy;

sub Foo {
    for( my $i = 0; CORE::caller($i); $i++ ){
        subtest "For caller($i)" => sub {
            plan tests => 12;
            my $caller = caller($i);
             is $caller->package(), __PACKAGE__,                        # 1
            'succeed to get package name';
            is $caller->filename(), $0, 'succeed to get filename';      # 2
             is $caller->line(), __LINE__ - 4,                          # 3
            'succeed to get line number';

             is $caller->subroutine(), (CORE::caller($i))[3],           # 4
            'succeed to get name of subroutine';
             is $caller->hasargs(), (CORE::caller($i))[4],              # 5
            'succeed to get hasargs';
             is $caller->wantarray(), (CORE::caller($i))[5],            # 6
            'succeed to get wantarray';
             is $caller->evaltext(), (CORE::caller($i))[6],             # 7
            'succeed to get evaltext';
             is $caller->is_require(), (CORE::caller($i))[7],           # 8
            'succeed to get is_require';
             is $caller->hints(), (CORE::caller($i))[8],                # 9
            'succeed to get hints';
             is $caller->bitmask(), (CORE::caller($i))[9],              #10
            'succeed to get bitmask';
             is $caller->hinthash(), (CORE::caller($i))[10],            #11
            'succeed to get hinthash';
            package DB {
                our @args;
                CORE::caller($i);
            }
            is_deeply $caller->args(), \@DB::args,                      #12
            'succeed to get args';
        }
    }

}

sub Bar {
    Foo( 0, 1, 2 );
}

sub Bazz{
    Bar( qw ( a b c ) );
}

Bazz();

done_testing();

