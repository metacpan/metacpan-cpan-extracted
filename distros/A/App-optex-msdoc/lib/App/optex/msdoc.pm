package App::optex::msdoc;

use 5.014;
use strict;
use warnings;

our $VERSION = "0.05";

=encoding utf-8

=head1 NAME

msdoc - module to replace MS document by its text contents

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

optex command -Mmsdoc

=head1 NOTICE

There is more general successor version of this module.
Use L<https://github.com/kaz-utashiro/optex-textconv>.

=head1 DESCRIPTION

This module replaces argument which terminate with I<.docx>, I<pptx>
or I<xlsx> files by node representing its text information.  File
itself is not altered.

For example, you can check the text difference between MS word files
like this:

    $ optex diff -Mmsdoc OLD.docx NEW.docx

If you have symbolic link named B<diff> to B<optex>, and following
setting in your F<~/.optex.d/diff.rc>:

    option default --msdoc
    option --msdoc -Mmsdoc $<move>

Next command simply produces the same result.

    $ diff OLD.docx NEW.docx

Text data is extracted by B<greple> command with B<-Mmsdoc> module,
and above command is almost equivalent to below bash command using
process substitution.

    $ diff <(greple -Mmsdoc --dump OLD.docx) \
           <(greple -Mmsdoc --dump NEW.docx)

=head1 ENVIRONMENT

This version experimentally support other converter program.  If the
environment variable B<OPTEX_MSDOC_CONVERTER> is set, it is used
instead of B<greple>.  Choose one from B<greple>, B<pandoc> or
B<tika>.

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/optex-msdoc>

It is possible to use other data conversion program, like L<pandoc> or
L<Apache Tika>.  Feel to free to modify this module.  I'm reluctant to
use them, because they work quite leisurely.

L<https://github.com/kaz-utashiro/optex-textconv>

=head1 LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

package App::optex::msdoc;

use utf8;
use Encode;
use Data::Dumper;

my($mod, $argv);
sub initialize {
    ($mod, $argv) = @_;
    msdoc();
}

sub argv (&) {
    my $sub = shift;
    @$argv = $sub->(@$argv);
}

my %converter = (
    'greple' => "greple -Mmsdoc --dump \"%s\"",
    'pandoc' => "pandoc -t plain \"%s\"",
    'tika'   => "tika --text \"%s\"",
    );

my $converter_default = 'greple';

my $converter = $ENV{OPTEX_MSDOC_CONVERTER} || $converter_default;

sub to_text {
    my $file = shift;
    my $format = $converter{$converter};
    my $exec = sprintf $format, $file;
    qx($exec);
}

use App::optex::Tmpfile;

my @persist;

sub msdoc {
    argv {
	for (@_) {
	    my($suffix) = /\.(docx|pptx|xlsx)$/x or next;
	    -f $_ or next;
	    my $tmp = new App::optex::Tmpfile;
	    $tmp->write(to_text($_))->rewind;
	    push @persist, $tmp;
	    $_ = $tmp->path;
	}
	@_;
    };
}

1;

__DATA__

##
## GIT_EXTERNAL_DIFF is called with 7 parameters:
##    path old-file old-hex old-mode new-file new-hex new-mode
##    0    1        2       3        4        5       6
##
option --git-external-diff $<copy(1,1)> $<copy(4,1)> $<remove>

#  LocalWords:  msdoc optex docx pptx xlsx diff greple pandoc tika
#  LocalWords:  Kazumasa Utashiro
