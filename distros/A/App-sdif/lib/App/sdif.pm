package App::sdif;
use 5.014;
use strict;
use warnings;

our $VERSION = "3.2.2";

1;

=encoding utf8

=head1 NAME

sdif-tools - sdif and family tools, cdif and watchdiff

=head1 SYNOPSIS

sdif f1 f2

diff f1 f2 | cdif

git diff | sdif --cdif -n

watchdiff df

=head1 DESCRIPTION

B<sdif-tools> are composed by B<sdif> and related tools including
B<cdif> and B<watchdiff>.

B<sdif> prints diff output in side-by-side format.

B<cdif> adds visual effect for diff output, comparing lines in
word-by-word, or character-by-character bases.

B<watchdiff> calls specified command repeatedly, and print the output
with visual effect to emphasize modified part.

See individual manual of each command for detail.

=head1 SEE ALSO

L<sdif>, L<cdif>, L<watchdiff>

=head1 LICENSE

Copyright (C) Kaz Utashiro.

These commands and libraries are free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Kaz Utashiro E<lt>kaz@utashiro.comE<gt>

=cut
