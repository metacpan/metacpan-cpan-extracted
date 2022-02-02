=encoding utf-8

=head1 NAME

greple -Mjq - greple module to search JSON data with jq

=head1 SYNOPSIS

greple -Mjq --glob JSON-DATA --IN label pattern

=head1 VERSION

Version 0.04

=head1 DESCRIPTION

This is an experimental module for L<App::Greple> to search JSON
formatted text using L<jq(1)> as a backend.

Search top level json object which includes both C<Marvin> and
C<Zaphod> somewhare in its text representation.

    greple -Mjq 'Marvin Zaphod'

You can search object C<.commit.author.name> includes C<Marvin> like this:

    greple -Mjq --IN .commit.author.name Marvin

Search first C<name> field including C<Marvin> under C<.commit>:

    greple -Mjq --IN .commit..name Marvin

Search any C<author.name> field including C<Marvin>:

    greple -Mjq --IN author.name Marvin

Search C<name> is C<Marvin> and C<type> is C<Robot> or C<Android>:

    greple -Mjq --IN name Marvin --IN type 'Robot|Android'

Please be aware that this is just a text matching tool for indented
result of L<jq(1)> command.  So, for example, C<.commit.author>
includes everything under it and it maches C<committer> field name.
Use L<jq(1)> filter for more complex and precise operation.

=head1 CAUTION

L<greple(1)> commands read entire input before processing.  So it
should not be used for gigantic data or inifinite stream.

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

=item B<--NOT> I<label> I<pattern>

Specify negative condition.

=item B<--MUST> I<label> I<pattern>

Specify required condition.  If there is one or more required
condition, all other positive rules move to optional.  They are not
required but highliged if exist.

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

    greple -Mjq --IN name _mina

Search from C<.process.name> label.

    greple -Mjq --IN .process.name _mina

Object C<.process.name> contains C<_mina> and C<.event> contains
C<EXEC>.

    greple -Mjq --IN .process.name _mina --IN .event EXEC

Object C<ppid> is 803 and C<.event> contains C<FORK> or C<EXEC>.

    greple -Mjq --IN ppid 803 --IN event 'FORK|EXEC'

Object C<name> is C<_mina> and C<.event> contains C<CREATE>.

    greple -Mjq --IN name _mina --IN event 'CREATE'

Object C<ancestors> contains C<1132> and C<.event> contains C<EXEC>
with C<arguments> highlighted.

   greple -Mjq --IN ancestors 1132 --IN event EXEC --IN arguments .

Object C<*pid> label contains 803.

    greple -Mjq --IN %pid 803

Object any <path> contains C<_mira> under C<.file> and C<.event>
contains C<WRITE>.

    greple -Mjq --IN .file..path _mina --IN .event WRITE

=head1 TIPS

Use C<--all> option to show entire data.

Use C<--nocolor> option or set C<NO_COLOR=1> to disable colored
output.

Use C<-o> option to show only matched part.

Use C<--blockend=> option to cancel showing block separator.

Sine this module implements original search funciton, L<greple(1)>
B<-i> does not take effect.  Set modifier in regex like
C<(?i)pattern> if you want case-insensitive match.

Use C<-Mjq::debug=> to see actual regex.

Use C<--color=always> and set C<LESSANSIENDCHARS=mK> if you want to
see the output using L<less(1)>.  Put next line in your F<~/.greplerc>
to enable colored output always.

    option default --color=always

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

our $VERSION = "0.04";

use Exporter 'import';
our @EXPORT = qw(&jq_filter);

use App::Greple::Common;
use App::Greple::Regions qw(match_regions merge_regions);
use Data::Dumper;

our $debug;
sub debug { $debug ^= 1 }

my $indent = '  ';
my $indent_re = qr/$indent/;

sub re {
    my $pattern = shift;
    my $re = eval { qr/$pattern/ };
    if ($@) {
	die sprintf("$pattern: pattern error - %s\n",
		    $@ =~ /(.*?(?=;|$))/);
    }
    return $re;
}

sub prefix_regex {
    my $path = shift;
    my @prefix_re;
    my $level = '';
    while ($path =~ s/^([^.\n]*?)(\.+)//) {
	my($label, $dot) = ($1, $2);
	$label =~ s/%/.*/g;
	my $label_re = re($label);
	my $start_with = '';
	my $prefix_re = do {
	    if ($label eq '') {
		length($dot) > 1 ? '' : qr{ ^ (?= $indent_re \S) }xm;
	    } else {
		if (length($dot) == 1) {
		    ## using same capture group name is not a good idea
		    ## so make sure to put just for the one
		    $level      = '?<level>' if $path eq '';
		    $start_with = qr/(?=\S)/;
		}
		qr{
		    ^ (${level} $indent_re*) "$label_re": .* \n
		    (?:
			## single line key-value pair
			\g{-1} $indent_re $start_with .++ \n
		    |
			## indented array/hash
			\g{-1} $indent_re \S .* [\[\{] \n
			(?: \g{-1} $indent_re \s .*+ \n) *+
			\g{-1} $indent_re [\]\}] ,? \n
		    ) *?
		}xm;
	    }
	};
	push @prefix_re, $prefix_re if $prefix_re;
    }
    if ($level eq '') {
	## refering named capture group causes error if it is not used
	## so put dummy expression just to fail
	push @prefix_re, qr/(?<level>(?!))?/;
    }
    @prefix_re
}

sub IN {
    my %opt = @_;
    my $target = delete $opt{&FILELABEL} or die;
    my($label, $pattern) = @opt{qw(label pattern)};
    my $indent_re = qr/  /;
    my @prefix_re = $label =~ s/^((?:.*\.)?)// && prefix_regex($1);
    $label =~ s/%/.*/g;
    my($label_re, $pattern_re) = map re($_), $label, $pattern;
    my $re = qr{
	@prefix_re \K
	^
	(?(<level>) (?= \g{level} $indent_re \S ) )	# required level
	(?<in> [ ]*) "$label_re": [ ]*+			# find given label
	(?: . | \n\g{in} \s++ ) *			# and look for ...
	$pattern_re					# pattern
	(?: . | \n\g{in} (?: \s++ | [\]\}] ) ) *	# and take the rest
    }xm;
    warn "$re\n" if $debug;
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

option --AND --IN

option --MUST \
	--face +E \
	--le +&__PACKAGE__::IN(label=$<shift>,pattern=$<shift>)

option --NOT \
	--le -&__PACKAGE__::IN(label=$<shift>,pattern=$<shift>)
