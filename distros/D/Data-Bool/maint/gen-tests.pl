#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;

use Path::Class qw(file);

sub try_module_code {
    my $m = shift;
    return qq{eval { require $m };\nplan skip_all => "$m needed for this test" if \$@;};
}

for my $m (qw(Types::Serialiser JSON::PP Cpanel::JSON::XS)) {
    for (qw(t/02-basic.t t/03-is-bool.t t/04-to-bool.t)) {
        my $t = file($_);

        my $d   = $m =~ s/::/-/gr;
        my $try = try_module_code($m);

        {    # Before
            my $content = $t->slurp =~ s/(^use Types::Bool.*$)/$try\n$1/mr;

            my $n = file( 't', join( '-', 'before', $d, $t->basename ) );
            $n->parent->mkpath unless -e $n->parent;
            $n->spew($content);
            say $n;
        }

        {    # After
            my $content = $t->slurp =~ s/(^use Types::Bool.*$)/$1\n$try/mr;

            my $n = file( 't', join( '-', 'after', $d, $t->basename ) );
            $n->parent->mkpath unless -e $n->parent;
            $n->spew($content);
            say $n;
        }

    }
}
