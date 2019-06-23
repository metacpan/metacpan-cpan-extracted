package App::sdif;
use 5.014;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(usage);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

our $VERSION = "4.11.1";

use Pod::Usage;

sub usage {
    my $opt = ref($_[0]) eq 'HASH' ? shift : {};
    select STDERR;
    print @_;
    pod2usage(-verbose => 0, -exitval => "NOEXIT");
    print "Version: $VERSION\n";
    exit($opt->{status} // 0);
}

1;

=encoding utf8

=head1 NAME

App::sdif - sdif and family tools, cdif and watchdiff

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

=head1 INSTALL

=head2 CPANM

    $ cpanm App::sdif
    or
    $ curl -sL http://cpanmin.us | perl - App::sdif

=head1 SEE ALSO

L<sdif>, L<cdif>, L<watchdiff>

=head1 LICENSE

Copyright (C) Kazumasa Utashiro.

These commands and libraries are free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

#  LocalWords:  sdif cdif watchdiff diff CPANM cpanm Kaz Utashiro
