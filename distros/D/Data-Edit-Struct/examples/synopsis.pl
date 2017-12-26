#!/usr/bin/perlperl

use strict;
use warnings;

use Data::Edit::Struct qw[ edit ];


my $src  = { foo => 9, bar => 2 };
my $dest = { foo => 1, bar => [22] };

edit(
    replace => {
        src   => $src,
        spath => '/foo',
        dest  => $dest,
        dpath => '/foo'
    } );

edit(
    insert => {
        src   => $src,
        spath => '/bar',
        dest  => $dest,
        dpath => '/bar'
    } );

# $dest = { foo => 9, bar => [ 2, 22 ] }
