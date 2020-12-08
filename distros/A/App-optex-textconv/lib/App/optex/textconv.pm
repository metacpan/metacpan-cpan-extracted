package App::optex::textconv;

our $VERSION = '0.11';

use v5.14;
use warnings;
use Encode;

=encoding utf-8

=head1 NAME

textconv - optex module to replace document file by its text contents

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

optex command -Mtextconv

optex command -Mtc (alias module)

optex command -Mtextconv::load=pandoc

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

=head1 MICROSOFT DOCUMENTS

Microsoft office document in XML format (.docx, .pptx, .xlsx) is
converted to plain text by original code implemented in
C<App::optex::textconv::msdoc> module.  Algorithm used in this module
is extremely simple, and consequently runs fast.

Two module are included in this distribution to use other external
converter program, B<pandoc> and B<tika>, those implement much more
serious algorithm.  They can be invoked by calling B<load> function
with module declaration like:

    optex -Mtextconv::load=pandoc

    optex -Mtextconv::load=tika

=head1 INSTALL

=head2 CPANM

    $ cpanm App::optex::textconv
    or
    $ curl -sL http://cpanmin.us | perl - App::optex::textconv

=head2 GIT

These are sample configurations using L<App::optex::textconv> in git
environment.

	~/.gitconfig
		[diff "msdoc"]
			textconv = optex -Mtextconv cat
		[diff "pdf"]
			textconv = optex -Mtextconv cat
		[diff "jpg"]
			textconv = optex -Mtextconv cat

	~/.config/git/attributes
		*.docx   diff=msdoc
		*.pptx   diff=msdoc
		*.xlmx   diff=msdoc
		*.pdf    diff=pdf
		*.jpg    diff=jpg

About other GIT related setting, see
L<https://github.com/kaz-utashiro/sdif-tools>.

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/optex>

L<https://github.com/kaz-utashiro/optex-textconv>

L<https://qiita.com/kaz-utashiro/items/23fd825bd325240592c2>

L<https://github.com/kaz-utashiro/sdif-tools>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2019-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Data::Dumper;
use List::Util 1.45 qw(first);

our @CONVERTER;
use App::optex::textconv::default;
use App::optex::textconv::msdoc;

my($mod, $argv);
sub initialize {
    ($mod, $argv) = @_;
}

sub finalize {
    textconv();
}

sub argv (&) {
    my $sub = shift;
    @$argv = $sub->(@$argv);
}

sub hit {
    local $_ = shift;
    my $check = shift;
    if (ref $check eq 'CODE') {
	$check->();
    } else {
	/$check/;
    }
}

sub converter {
    my $filename = shift;
    if (my $ent = first { hit $filename, $_->[0] } @CONVERTER) {
	return $ent->[1];
    }
    undef;
}

sub exec_command {
    my($format, $file) = @_;
    my $exec = sprintf $format, $file;
    qx($exec);
}

sub load_module {
    my $name = shift;
    my $module = __PACKAGE__ . "::$name";
    eval "use $module";
    if ($@) {
	warn $@ unless $@ =~ /Can't locate/;
	return 0;
    }
    $module;
}

sub load {
    while (my($mod, $val) = splice(@_, 0, 2)) {
	load_module $mod if $val;
    }
}

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
		if (my $converter = converter $_) {
		    if (ref $converter eq 'CODE') {
			$converter;
		    }
		    else {
			sub { exec_command $converter, $_ };
		    }
		}
		elsif ($suffix) {
		    state %loaded;
		    my $state = \$loaded{$suffix};
		    my $to_text = join '::', __PACKAGE__, $suffix, 'to_text';
		    if (not defined $$state) {
			$$state = 0;
			load_module $suffix or next;
			$$state = 1 if defined &{$to_text};
			redo;
		    } elsif ($$state) {
			$to_text;
		    } else {
			next;
		    }
		} else {
		    next;
		}
	    };
	    use App::optex::Tmpfile;
	    my $tmp = $persist[@persist] = App::optex::Tmpfile->new;
	    my $data = do {
		no strict 'refs';
		use charnames ':full';
		local $_ = decode 'utf8', &$func($_);
		s/[\p{Private_Use}\p{Unassigned}]/\N{GETA MARK}/g;
		encode 'utf8', $_;
	    };
	    $_ = $tmp->write($data)->rewind->path;
	}
	@_;
    };
}

1;

__DATA__

#  LocalWords:  docx pptx xlsx pandoc tika
