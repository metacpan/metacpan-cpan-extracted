package App::optex::textconv;

use 5.014;
use strict;
use warnings;

our $VERSION = "0.02";

=encoding utf-8

=head1 NAME

textconv - optex module to replace document file by its text contents

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

optex command -Mtextconv

=head1 DESCRIPTION

This module replaces several sort of filenames by node representing
its text information.  File itself is not altered.

For example, you can check the text difference between MS word files
like this:

    $ optex diff -Mtextconv OLD.docx NEW.docx

If you have symbolic link named B<diff> to B<optex>, and following
setting in your F<~/.optex.d/diff.rc>:

    option default --textconv
    option --textconv -Mtextconv $<move>

Next command simply produces the same result.

    $ diff OLD.docx NEW.docx

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/optex>
L<https://github.com/kaz-utashiro/optex-textconv>

=head1 LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

use utf8;
use Encode;
use Data::Dumper;
use List::Util qw(first);

my($mod, $argv);
sub initialize {
    ($mod, $argv) = @_;
    textconv();
}

sub argv (&) {
    my $sub = shift;
    @$argv = $sub->(@$argv);
}

use App::optex::textconv::msdoc;
my @converter = (
    [ qr/\.docx$/    => \&App::optex::textconv::msdoc::to_text ],
    [ qr/\.pptx$/    => \&App::optex::textconv::msdoc::to_text ],
    [ qr/\.xlsx$/    => \&App::optex::textconv::msdoc::to_text ],
    [ qr/\.pdf$/i    => "pdftotext -nopgbrk \"%s\" -" ],
    [ qr/\.jpe?g$/i  => "exif \"%s\"" ],
    [ qr[^https?://] => "w3m -dump \"%s\"" ],
    );

sub converter {
    my $filename = shift;
    if (my $ent = first { $filename =~ $_->[0] } @converter) {
	return $ent->[1];
    }
    undef;
}

sub exec_command {
    my($format, $file) = @_;
    my $exec = sprintf $format, $file;
    qx($exec);
}

use App::optex::Tmpfile;

my @persist;

sub textconv {
    argv {
      ARGV:
	for (@_) {
	    # check file existence
	    do {{
		m[^https?://] and last; # skip URL
		-f or next ARGV;
	    }};
	    my($suffix) = map { lc } /\.(\w+)$/x;
	    my $func = do {
		if (my $converter = converter($_)) {
		    if (ref $converter eq 'CODE') {
			$converter;
		    }
		    else {
			sub { exec_command $converter, $_ };
		    }
		}
		elsif ($suffix) {
		    my $module = __PACKAGE__ . "::$suffix";
		    eval "use $module";
		    next if $@;
		    "${module}::to_text";
		} else {
		    next;
		}
	    };
	    my $tmp = $persist[@persist] = new App::optex::Tmpfile;
	    no strict 'refs';
	    $tmp->write(&$func($_))->rewind;
	    $_ = $tmp->path;
	}
	@_;
    };
}

1;
