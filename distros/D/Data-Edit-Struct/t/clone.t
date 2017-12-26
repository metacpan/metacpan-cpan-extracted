#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];
use Storable 'dclone';
use Scalar::Util 'refaddr';

my $src = {
    cow => { says => 'moo',     likes => ['hay'] },
    cat => { says => 'meow',    likes => ['mice'] },
    dog => { says => 'bow wow', likes => ['bones'] },
};

{
    my $dest = [];

    edit(
        insert => {
            dest  => $dest,
            dpath => '/',
            src   => $src,
            stype => 'element',
            spath => '/cat/likes'
        },
    );

    is(
        refaddr( $dest->[0] ),
        refaddr( $src->{cat}{likes} ),
        "no clone; references the same"
    );
}

{
    my $dest = [];

    edit(
        insert => {
            dest  => $dest,
            dpath => '/',
            src   => $src,
            stype => 'element',
            spath => '/cat/likes',
            clone => 1
        },
    );

    isnt(
        refaddr( $dest->[0] ),
        refaddr( $src->{cat}{likes} ),
        "clone; references differ"
    );
}

done_testing;
