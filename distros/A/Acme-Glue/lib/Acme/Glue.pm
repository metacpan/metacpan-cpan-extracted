package Acme::Glue;

use utf8;
use strict;
use warnings;

$Acme::Glue::VERSION = "2021.08";

=encoding utf8

=head1 NAME

Acme::Glue - A placeholder module for code accompanying a Perl photo project

=head1 VERSION

2021.08

=head1 DESCRIPTION

Acme::Glue is the companion Perl module for a Perl photo project, the idea
for the photo project is to have each photo include a small snippet of code.
The code does not have to be Perl, it just has to be something you're quite
fond of for whatever reason.

"Glue" is a series of photos shot at Perl conferences and workshops in Europe
and America. Perl was one of the programming languages that bootstrapped a
lot of internet based companies in the mid/late 1990s and early 2000s. Perl
was considered a “glue” language by some, but has fallen out of favour as
newer languages have taken its place. The title is a metaphor not just for
the language but also for shrinking of the community at the events the photos
are shot at.

=head1 SNIPPETS

Here are the snippets that accompany the photo project

=head2 LEEJO (transform.pl)

    #!/usr/bin/env perl
    #
    # transform an array of hashes into an array of arrays where each array
    # contains the values from the hash sorted by the original hash keys or
    # the passed order of columns (hash slicing)
    my @ordered = $column_order
        ? map { [ @$_{ @{ $column_order } } ] } @{ $chaos }
        : map { [ @$_{sort keys %$_} ] } @{ $chaos };

=head2 LEEJO (hopscotch.p6)

    #!/usr/bin/env perl6

    my @court = (
        [ 'FIN' ],
        [ 9 ,10 ],
        [   8   ],
        [ 6 , 7 ],
        [   5   ],
        [   4   ],
        [ 2 , 3 ],
        [   1   ],
    );

    my $skip = @court.[1..*].pick.pick;
    my @play;

    for @court.reverse -> $hop {
        @play.push( $hop.map( *.subst( /^$skip$/,'🚫' ).list ) );
    }

    say @play.reverse.join( "\n" );

=head2 SLU (MAZE.BAS)

    10 PRINT CHR$(205.5+RND(1));:GOTO 10

=head2 SLU (schwartzian_transform.pl)


    #!/usr/bin/env perl
    # https://en.wikipedia.org/wiki/Schwartzian_transform
    # Sort list of words according to word length

    print "$_\n" foreach
      map  { $_->[0] }
      sort { $a->[1] <=> $b->[1] or $a->[0] cmp $b->[0] }
      map  { [$_, length($_)] }
      qw(demo of schwartzian transform);

=head1 THANKS

Thanks to all who contributed a snippet

=head1 SEE ALSO

L<https://www.formulanon.com/glue>

L<https://www.youtube.com/watch?v=ir6f2SvsXPA&feature=youtu.be&list=PLOOlhkMvt_o4y627mpaCGrO4ughSEeUgb&t=1046>

L<https://leejo.github.io/acme-glue-talk/presentation.html#1>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/acme-glue

All photos © Lee Johnson

=cut

1;
