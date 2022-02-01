=encoding utf-8

=head1 NAME

greple -Mjq - greple module for jq frontend

=head1 SYNOPSIS

greple -Mjq --glob JSON-DATA --IN label pattern

=head1 DESCRIPTION

This is an experimental module for L<App::Greple> command to provide
interface for L<jq(1)> command.

You can search object C<.commit.author.name> includes C<Marvin> like this:

    greple -Mjq --IN .commit.author.name Marvin

Search first C<name> field including C<Marvin> under C<.commit>:

    greple -Mjq --IN .commit..name Marvin

Search any C<author.name> field including C<Marvin>:

    greple -Mjq --IN author.name Marvin

Please be aware that this is just a text matching tool for indented
result of L<jq(1)> command.  So, for example, C<.commit.author>
includes everything under it and it maches C<committer> field name.
Use L<jq(1)> filter for more complex and precise operation.

=head1 CAUTION

L<greple(1)> commands read entire input before processing.  So it
should not be used for large amount of data or inifinite stream.

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::jq
    or
    $ curl -sL http://cpanmin.us | perl - App::Greple::jq

=head1 OPTIONS

=over 7

=item B<--IN> I<label> I<pattern>

Search I<pattern> included in I<label> field.

Chacater C<%> can be used as a wildcard in I<label> string.  So
C<%name> matches labels end with C<name>, and C<name%> matches labels
start with C<name>.

If the label is simple string like C<name>, it matches any level of
JSON data.

If the label string contains period (C<.>), it is considered as a
nested labels.  Name C<.name> maches only C<name> label at the top
level.  Name C<process.name> maches only C<name> entry of some
C<process> hash.

If labels are separated by two or more dots (C<..>), they don't have
to have direct relationship.

=back

=head1 LABEL SYNTAX

=over 15

=item B<.file>

C<file> at the top level.

=item B<.file.path>

C<path> under C<.file>.

=item B<.file..path>

C<path> in descendants of C<.file>.

=item B<path>

C<path> at any level.

=item B<file.path>

C<file.path> at any level.

=item B<file..path>

Some C<path> in descendatns of some C<file>.

=item B<%path>

Any labels end with C<path>.

=item B<path%>

Any labels start with C<path>.

=item B<%path%>

Any labels include C<path>.

=back

=head1 EXAMPLES

Search from any C<name> labels.

    greple -Mjq --glob procmon.json --IN name _mina

Search from C<.process.name> label.

    greple -Mjq --glob procmon.json --IN .process.name _mina

Object C<.process.name> contains C<_mina> and C<.event> contains
C<FORK>.

    greple -Mjq --glob procmon.json --IN .process.name _mina --IN .event FORK

Object C<ancestors> contains C<339> and C<.event> contains C<FORK>.

    greple -Mjq --glob procmon.json --IN ancestors 339 --IN event FORK

Object C<*pid> labels contains 803.

    greple -Mjq --glob procmon.json --IN %pid 803

Object any <path> contains C<_mira> under C<.file> and C<.event> contains C<WRITE>.

    greple -Mjq --glob filemon.json --IN .file..path _mina --IN .event WRITE

=head1 TIPS

Use C<--all> option to show entire data.

Use C<--nocolor> option or set C<NO_COLOR=1> to disable colored
output.

Use C<--blockend=> option to cancel showing block separator.

Use C<-o> option to show only matched part.

Sine this module implements original search funciton, L<greple(1)>
B<-i> does not take effect.  Set modifier in regex like
C<(?i)pattern> if you want case-insensitive match.

=head1 SEE ALSO

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://stedolan.github.io/jq/>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::jq;

use 5.014;
use strict;
use warnings;
use Carp;

our $VERSION = "0.03";

use Exporter 'import';
our @EXPORT = qw(&jq_filter);

use App::Greple::Common;
use App::Greple::Regions qw(match_regions merge_regions);
use Data::Dumper;

our $debug;
sub debug { $debug ^= 1 }

my $indent = '  ';
my $indent_re = qr/$indent/;

sub leader_regex {
    my $leader = shift;

    my @lead_re;
    while ($leader =~ s/^([^.\n]*?)(\.+)//) {
	my($lead, $dot) = ($1, $2);
	$lead =~ s/%/.*/g;
	my $start_with = length($dot) > 1 ? '' : qr/(?=\S)/;
	my $lead_re = do {
	    if ($lead eq '') {
		length($dot) > 1 ? '' : qr{ ^ (?= $indent_re \S) }xm;
	    } else {
		##
		## Make capture group <level> if it is required.
		##
		my $level = ($leader eq '' and length($dot) == 1) ? '?<level>' : '';
		qr{
		    ^ (${level} $indent_re*) "$lead": .* \n
		    (?:
			\g{-1} $indent_re $start_with .++ \n
		    |
			# indented array/hash
			\g{-1} $indent_re \S .* [\[\{] \n
			(?: \g{-1} $indent_re \s .*+ \n) *+
			\g{-1} $indent_re [\]\}] ,? \n
		    ) *?
		}xm;
	    }
	};
	push @lead_re, $lead_re if $lead_re;
    }
    unless (grep /\(\?<level>/, @lead_re) {
	push @lead_re, qr/(?<level>(?!))?/; # just to fail
    }
    @lead_re
}

sub IN {
    my %opt = @_;
    my $target = delete $opt{&FILELABEL} or die;
    my($label, $pattern) = @opt{qw(label pattern)};
    my $lead_re = '';
    my $indent_re = qr/  /;
    my @lead_re = $label =~ s/^((?:.*\.)?)// && leader_regex($1);
    $label =~ s/%/.*/g;
    my $re = qr{
	@lead_re \K
	^
	(?(<level>) (?= \g{level} $indent_re \S ) )	# required level
	(?<in> [ ]*) "$label": [ ]*+
	(?: . | \n\g{in} \s++ ) *
	$pattern
	(?: . | \n\g{in} (?: \s++ | [\]\}] ) ) *
    }xm;

    warn Dumper $re if $debug;

    match_regions pattern => $re;
}

1;

__DATA__

define JSON-OBJECTS ^([ ]*)\{(?s:.*?)^\g{-1}\},?\n

option default \
	--json-block --jq-filter

option --jq-filter --if='jq "if type == \"array\" then .[] else . end"'

option --json-block --block JSON-OBJECTS

option --IN \
	--face +E \
	--le &__PACKAGE__::IN(label=$<shift>,pattern=$<shift>)
