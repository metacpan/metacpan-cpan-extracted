package App::sdif;
use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(usage);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

our $VERSION = "4.16.1";

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

diff -c f1 f2 | cdif

git diff | sdif -n

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

=head2 GIT

Those are sample configurations using B<sdif> family in git
environment.  You need to install B<mecab> command to use B<--mecab>
option.

	~/.gitconfig
		[pager]
		        log  = sdif | less
		        show = sdif | less
		        diff = sdif | less

	~/.sdifrc
		option default -n --margin=4

	~/.cdifrc
		option default --mecab

	~/.profile
		export LESS="-cR"
		export LESSANSIENDCHARS="mK"

You can write everything in ~/.gitconfig:

        log  = sdif -n --margin=4 --mecab | env LESSANSIENDCHARS=mK less -cR
        show = sdif -n --margin=4 --mecab | env LESSANSIENDCHARS=mK less -cR
        diff = sdif -n --margin=4 --mecab | env LESSANSIENDCHARS=mK less -cR

=head1 SEE ALSO

L<sdif>, L<cdif>, L<watchdiff>

L<Getopt::EX>

=head1 LICENSE

Copyright (C) Kazumasa Utashiro.

These commands and libraries are free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

#  LocalWords:  sdif cdif watchdiff diff CPANM cpanm Kaz Utashiro
