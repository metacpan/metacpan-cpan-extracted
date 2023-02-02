package App::Greple::xlate;

our $VERSION = "0.03";

=encoding utf-8

=head1 NAME

App::Greple::xlate - translation support module for greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 DESCRIPTION

B<Greple> B<xlate> module find text blocks and replace them by the
translated text.  Currently only DeepL service is supported by the
B<xlate::deepl> module.

If you want to translate normal text block in L<pod> style document,
use B<greple> command with C<xlate::deepl> and C<perl> module like
this:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pattern C<^(\w.*\n)+> means consecutive lines starting with
alpha-numeric letter.  This command show the area to be translated.
Option B<--all> is used to produce entire text.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Then add C<--xlate> option to translate the selected area.  It will
find and replace them by the B<deepl> command output.

By default, original and translated text is printed in the conflict
marker format compatible with L<git(1)>.  Using C<ifdef> format, you
can get desired part by L<unifdef(1)> command easily.  Format can be
specified by B<--xlate-format> option.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

If you want to translate entire text, use B<--match-entire> option.
This is a short-cut to specify the pattern matches entire text
C<(?s).*>.

=head1 OPTIONS

=over 7

=item B<--xlate>

Invoke the translation process for each matched area.

Without this option, B<greple> behaves as a normal search command.  So
you can check which part of the file will be subject of the
translation before invoking actual work.

Command result goes to standard out, so redirect to file if necessary,
or consider to use L<App::Greple::update> module.

=item B<--xlate-engine>=I<engine>

Specify the translation engine to be used.  You don't have to use this
option because module C<xlate::deepl> declares it as
C<--xlate-engine=deepl>.

=item B<--xlate-to> (Default: C<JA>)

Specify the target language.  You can get available languages by
C<deepl languages> command when using B<DeepL> engine.

=item B<--xlate-format>=I<format> (Default: conflict)

Specify the output format for original and translated text.

=over 4

=item B<conflict>

Print original and translated text in L<git(1)> conflict marker format.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

You can recover the original file by next L<sed(1)> command.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Print original and translated text in L<cpp(1)> C<#ifdef> format.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

You can retrieve only Japanese text by the B<unifdef> command:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Print original and translated text separated by single blank line.

=item B<none>

If the format is C<none> or unkown, only translated text is printed.

=back

=item B<-->[B<no->]B<xlate-progress> (Default: True)

See the tranlsation result in real time in the STDERR output.

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Fold converted text by the specified width.  Default width is 70 and
can be set by B<--xlate-fold-width> option.  Four columns are reserved
for run-in operation, so each line could hold 74 characters at most.

=item B<--match-entire>

Set the whole text of the file as a target area.

=back

=head1 CACHE OPTIONS

B<xlate> module can store cached text of translation for each file and
read it before execution to eliminate the overhead of asking to
server.  With the default cache strategy C<auto>, it maintains cache
data only when the cache file exists for target file.  If the
corresponding cache file does not exist, it does not create it.

=over 7

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Maintain cache file if it exists.

=item C<create>

Create empty cache file and exit.

=item C<always>, C<yes>, C<1>

Maintain cache anyway as far as the target is normal file.

=item C<never>, C<no>, C<0>

Never use cache file even if it exists.

=item C<accumulate>

By default behavior, unused data is removed from cache file.  If you
don't want to remove them and keep in the file, use C<accumulate>.

=back

=item --xlate-batch-update

Update cache for all non-existent data in batch mode.  This is much
more efficient than normal operation.

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Set your authentication key for DeepL service.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python library and CLI command.

=item L<App::Greple>

See the B<greple> manual for the detail about target text pattern.
Use B<--inside>, B<--outside>, B<--include>, B<--exclude> options to
limit the matching area.

=item L<App::Greple::update>

You can use C<-Mupdate> module to modify files by the result of
B<greple> command.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;

use Data::Dumper;

use JSON;
use Text::ANSI::Fold ':constants';
use App::cdif::Command;

our $xlate_engine;
our $show_progress = 1;
our $output_format = 'conflict';
our $collapse_spaces = 1;
our $squash_newlines = 1;
our $lang_from = 'ORIGINAL';
our $lang_to = 'JA';
our $fold_line = 0;
our $fold_width = 70;
our $auth_key;
our $cache_method //= $ENV{GREPLE_XLATE_CACHE} || 'auto';
our $dryrun = 0;

my $current_file;

our %formatter = (
    none => undef,
    conflict => sub {
	join '',
	    "<<<<<<< $lang_from\n",
	    $_[0],
	    "=======\n",
	    $_[1],
	    ">>>>>>> $lang_to\n";
    },
    ifdef => sub {
	join '',
	    #ifdef $lang_from\n",
	    $_[0],
	    "#endif\n",
	    "#ifdef $lang_to\n",
	    $_[1],
	    "#endif\n";
    },
    space   => sub { join "\n", @_ },
    discard => sub { '' },
    );

my $old_cache = {};
my $new_cache = {};
my $xlate_cache_update;
my $xlate_called;

sub prologue {
    if (defined $cache_method) {
	if ($cache_method eq '') {
	    $cache_method = 'auto';
	}
	if (lc $cache_method eq 'accumulate') {
	    $new_cache = $old_cache;
	}
	if ($cache_method =~ /^(no|never)/i) {
	    $cache_method = '';
	}
    }
    if ($xlate_engine) {
	my $mod = __PACKAGE__ . "::$xlate_engine";
	if (eval "require $mod") {
	    $mod->import;
	} else {
	    die "Engine $xlate_engine is not available.\n";
	}
	no strict 'refs';
	${"$mod\::lang_from"} = $lang_from;
	${"$mod\::lang_to"} = $lang_to;
	*XLATE = \&{"$mod\::xlate"};
	if (not defined &XLATE) {
	    die "No \"xlate\" function in $mod.\n";
	}
    }
}

sub translate_anyway {
    my $from = shift;

    print STDERR "From:\n", $from =~ s/^/\t< /mgr
	if $show_progress;

    return $from if $dryrun;

    my $to = &XLATE($from);

    print STDERR "To:\n", $to =~ s/^/\t> /mgr, "\n\n"
	if $show_progress;

    return $to;
}

sub translate {
    goto &translate_anyway unless $cache_method;
    my $text = shift;
    $new_cache->{$text} //= delete $old_cache->{$text} // do {
	if ($cache_method eq 'batch') {
	    '';
	} else {
	    $xlate_cache_update++;
	    translate_anyway $text;
	}
    };
}

sub fold_lines {
    state $fold = Text::ANSI::Fold->new(
	width     => $fold_width,
	boundary  => 'word',
	linebreak => LINEBREAK_ALL,
	runin     => 4,
	runout    => 4,
	);
    join "\n", $fold->text($_[0])->chops;
}

sub xlate {
    my %args = @_;
    my $orig = $_;
    $orig .= "\n" unless $orig =~ /\n\z/;

    my $source = $orig;
    if ($collapse_spaces) {
	$source =~ s{^.+(?:\n.+)*}{
	    ${^MATCH} =~ s/\A\s+|\s+\z//gr =~ s/\s+/ /gr
	}pmge;
    }

    $xlate_called++;
    $_ = translate $source;
    $_ =~ s/\n\n+/\n/g if $squash_newlines;
    $_ = fold_lines $_ if $fold_line;

    if (state $formatter = $formatter{$output_format}) {
	return $formatter->($orig, $_);
    } else {
	return $_;
    }
}

sub cache_file {
    my $file = "$current_file.xlate-$xlate_engine-$lang_to.json";
    if ($cache_method eq 'auto') {
	-f $file ? $file : undef;
    } else {
	if ($cache_method and -f $current_file) {
	    $file;
	} else {
	    undef;
	}
    }
}

sub read_cache {
    my $file = shift;
    %$new_cache = %$old_cache = ();
    if (open my $fh, $file) {
	my $json = do { local $/; <$fh> };
	my $hash = $json eq '' ? {} : decode_json $json;
	%$old_cache = %$hash;
	warn "read cache from $file\n";
    }
}

sub write_cache {
    return if $dryrun;
    my $file = shift;
    if (open my $fh, '>', $file) {
	my $json = encode_json $new_cache;
	print $fh $json;
	warn "write cache to $file\n";
    }
}

sub before {
    my %args = @_;
    $current_file = delete $args{&::FILELABEL} or die;
    $xlate_cache_update = 0;
    if (not defined $xlate_engine) {
	die "Select translation engine.\n";
    }
    if (my $cache = cache_file) {
	if ($cache_method eq 'create') {
	    unless (-f $cache) {
		open my $fh, '>', $cache or die "$cache: $!\n";
		warn "created $cache\n";
		print $fh "{}\n";
	    }
	    die "skip $current_file";
	}
	read_cache $cache;
    }
}

sub batch_update {

    my @from = @_;

    print STDERR "From:\n", map s/^/\t< /r, @from
	if $show_progress;

    my @to = &XLATE(@_);

    print STDERR "To:\n", map s/^/\t> /r, @to
	if $show_progress;

    die "Unmatched response: @to" if @_ != @to;

    for my $i (0 .. $#_) {
	$xlate_cache_update++;
	$new_cache->{$_[$i]} = $to[$i];
    }

}

sub after {
    if (my $cache = cache_file) {
	if ($cache_method eq 'batch') {
	    if (my @from = grep { $new_cache->{$_} eq '' } keys %$new_cache) {
		batch_update @from;
	    }
	}
	if ($xlate_cache_update or %$old_cache) {
	    write_cache $cache;
	}
    }
}

1;

__DATA__

builtin xlate-progress!    $show_progress
builtin xlate-format=s     $output_format
builtin xlate-fold!        $fold_line
builtin xlate-fold-width=i $fold_width
builtin xlate-from=s       $lang_from
builtin xlate-to=s         $lang_to
builtin xlate-cache:s      $cache_method
builtin xlate-engine=s     $xlate_engine
builtin xlate-dryrun       $dryrun

builtin deepl-auth-key=s   $__PACKAGE__::deepl::auth_key

option default \
	--face +E --ci=A \
	--prologue &__PACKAGE__::prologue

option --xlate \
	--begin &__PACKAGE__::before \
	--end   &__PACKAGE__::after \
	--cm    &__PACKAGE__::xlate

option --xlate-batch-update \
	--xlate-cache=batch \
	--xlate-format=discard \
	--xlate

option --match-entire    --re '\A(?s).+\z'
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
