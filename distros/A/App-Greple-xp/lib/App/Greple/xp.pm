=head1 NAME

App::Greple::xp - extended pattern module

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

greple -Mxp

=head1 DESCRIPTION

This module provides functions those can be used by B<greple> pattern
and region options.

=head1 OPTIONS

=over 7

=item B<--le-pattern> I<file>

=item B<--inside-pattern> I<file>

=item B<--outside-pattern> I<file>

=item B<--include-pattern> I<file>

=item B<--exclude-pattern> I<file>

Read file contents and use each lines as a pattern for options.

=item B<--le-string> I<file>

=item B<--inside-string> I<file>

=item B<--outside-string> I<file>

=item B<--include-string> I<file>

=item B<--exclude-string> I<file>

Almost same as B<*-pattern> option but each line is concidered as a
fixed string rather than regular expression.

=back

=head2 COMMENT

You can insert comment lines in pattern file.  As for fixed string
file, there is no way to write comment.

Lines start with hash mark (C<#>) is ignored as a comment line.

String after double slash (C<//>) is also ignored with preceding
spaces.

=head2 MULTILINE REGEX

Complex pattern can be written on multiple lines as follows.

    (?xxn) \
    ( (?<b>\[) | \@ )   # start with "[" or @             \
    (?<n> [ \d : , ]+)  # sequence of digit, ":", or ","  \
    (?(<b>) \] | )      # closing "]" if start with "["   \
    $                   # EOL

=head2 WILD CARD

Because I<file> parameter is globbed, you can use wild card to give
multiple files.  If nothing matched to the wild card, this option is
simply ignored with no message.

    $ greple -Mxp --exclude-pattern '*.exclude' ...

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/greple>

L<https://github.com/kaz-utashiro/greple-xp>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2019-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package App::Greple::xp;

use v5.14;
use strict;
use warnings;

our $VERSION = "1.01";

use Exporter 'import';
our @EXPORT = qw(&xp_pattern_file);

use open IO => ':utf8';
use App::Greple::Common;
use App::Greple::Regions qw(match_regions merge_regions);
use Data::Dumper;

my @default_opt = (
    hash_comment => 1,
    slash_comment => 1,
    glob => 1,
    fixed => 0,
    );

sub xp_pattern_file {
    my %opt = (@default_opt, @_);
    my $target = delete $opt{&FILELABEL} or die;
    my $file = $opt{file};
    my @files = $opt{glob} ? glob $file : ($file);
    my @r;
    for my $file (@files) {
	open my $fh, $file or die "$file: $!";
	my @p = map s/\\(?=\R)//gr, split /(?<!\\)\R/, do { local $/; <$fh> };
	for my $p (@p) {
	    if ($opt{hash_comment} and !$opt{fixed}) {
		next if $p =~ /^\s*#/;
	    }
	    if ($opt{slash_comment} and !$opt{fixed}) {
		$p =~ s{\s*//.*}{};
	    }
	    next unless $p =~ /\S/;
	    my $re = $opt{fixed} ? qr/\Q$p/ : qr/$p/m;
	    push @r, match_regions pattern => $re;
	}
    }
    merge_regions @r;
}

sub block_match {
    my $grep = shift;
    $grep->{RESULT} = [
	[ [ 0, length ],
	  map {
	      [ $_->[0][0], $_->[0][1], 0, $grep->{callback}->[0] ]
	  } $grep->result
      ] ];
}

1;

__DATA__

option      --le-pattern      --le &xp_pattern_file(file="$<shift>")
option  --inside-pattern  --inside &xp_pattern_file(file="$<shift>")
option --outside-pattern --outside &xp_pattern_file(file="$<shift>")
option --include-pattern --include &xp_pattern_file(file="$<shift>")
option --exclude-pattern --exclude &xp_pattern_file(file="$<shift>")

option      --le-string      --le &xp_pattern_file(fixed,file="$<shift>")
option  --inside-string  --inside &xp_pattern_file(fixed,file="$<shift>")
option --outside-string --outside &xp_pattern_file(fixed,file="$<shift>")
option --include-string --include &xp_pattern_file(fixed,file="$<shift>")
option --exclude-string --exclude &xp_pattern_file(fixed,file="$<shift>")

option --block-match    --postgrep &__PACKAGE__::block_match
