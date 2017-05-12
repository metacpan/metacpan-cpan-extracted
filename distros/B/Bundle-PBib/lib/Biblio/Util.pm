# --*-Perl-*--
# $Id: Util.pm 13 2004-11-27 08:58:44Z tandler $
#

=head1 NAME

Biblio::Util - Package Frontend for bp_util (Perl Bibliography Package)

=head1 SYNOPSIS

  use Biblio::Util;

=head1 DESCRIPTION

well, I guess it\'s better if you check the source or the original docs
for now .... sorry ... ;-)

=cut

package Biblio::Util;
use 5.006;
no strict;  # for strange AUTOLOAD method call ...
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 13 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use YYYY;
#use vars qw(@ISA);
#@ISA = qw(YYYY);

# used modules
#use FileHandle;
#use File::Basename;

# used own modules
use Biblio::BP;

=head1 METHODS

=over

=cut

#
#
# some additional helper functions
#
#

=item $bool = ordnumber($text)

Convert ordinal number in text representatin to integer value.
Return undef if $text is no ordinal number.


=cut

our %ordNumbers = qw/
	first	1
	second	2
	third	3
	fourth	4
	fifth	5
	sixth	6
	seventh	7
	eighth	8
	ninth	9
	/;
sub ordnumber { my ($text) = @_;
# return true (the number), if $text is an ordinal number
  # check for number (with optional trailing "." or "st" etc.
  if( $text =~ /^(\d+)(?:\.|st|nd|th)?$/ )
    { return $1 }
  # check for numbers as text (not very elaborated ....)
  return $ordNumbers{lc($text)};
}

=item $defaultCiteKey = defaultCiteKey($rec)

Generate Default CiteKey for record in pbib format.

=cut

sub defaultCiteKey {
	my ($rec, $title_words) = @_;
	my @key;
	
	my $project = $rec->{'Project'};
	if( $project ) {
		push @key, $project;
	} else {
		# get author
		my ($author, $type) = getAuthors($rec);
		#  print STDERR "author: $author ($type) ";
		my @authors = split_names($author, $type);
		#  print Dumper \@authors;
		push @key, last_name($authors[0]) if( @authors );
		#  print STDERR "-> $author\n";
	}
	
	# get year
	my $year = $rec->{'Year'};
	push @key, $year if defined $year;
	
	# get title
	my $title = $rec->{'Title'};
	$title =~ s/\-//ig; # join compond words
	$title =~ s/[^a-z‰ˆ¸ƒ÷‹ﬂ·ÈÌÛ˙‡ËÏÚ˘‚ÍÓÙ˚]/ /ig;
	my @words = split(/\s+/, $title);
	while( @words &&
			(
			! defined $words[0] ||
			lc($words[0]) =~ /^(the|in(side|to)?|on(to)?|for|from|of+|with(out)?|an?|over)$/ ||
			length($words[0]) < 4
			)
		) {
		shift @words;
	}
	$title_words = 1 unless defined $title_words;
	for( my $i = $title_words; $i > 0; $i--) {
		push @key, ucfirst(shift @words) if( @words );
	}
	
	# combine everything ...
	return join("-", @key);
}

=item ($author, $author_type) = getAuthors($rec)

=cut

sub getAuthors {
	my ($rec) = @_;
	# based on bp's genkey
	defined $rec->{'Authors'} &&
		return ($rec->{'Authors'}, 'names');
	defined $rec->{'CorpAuthor'} &&
		return ($rec->{'CorpAuthor'}, 'org');
	defined $rec->{'Editors'} &&
		return ($rec->{'Editors'}, 'names');
	defined $rec->{'Publisher'} &&
		return ($rec->{'Publisher'}, 'org');
	defined $rec->{'Organization'} &&
		return ($rec->{'Organization'}, 'org');
	return ("Anonymous", 'text');
}

=item split_names($names_string, $type)

	$type = 'names': the string contains names
	$type = 'org': the string contains a company
	$type = 'xname': return the advanced name array

=cut

sub split_names {
	my ($names, $type) = @_;
	return () unless defined($names);
	return ($names) if defined($type) && $type !~ /name/i;
	my $xname_flag = 1 if defined($type) && $type eq 'xname';

	my $etal;
	if( $names =~ s/\s+et.?\s+al.*\s*$//i ) {
		$etal = 1;
	}
	# support for bibtex "and others"
	if( $names =~ s/\s+and\s+others\s*$//i ) {
		$etal = 1;
	}
	
	##### ToDo: remove ' and ', or ', and ' etc. -- does this work now?
	# treat all ";" as "," ... in the future, I could think about a more sophisticated 
	# treatment of names that, e.g., allows to explicitely separate
	#  the parts of a name
	# as well similar to bibliographix or bp
	$names =~ s/;/,/g;
	# replace " and " / ", and " / etc. with plain ","
	$names =~ s/(?:\s+|\s*,\s*)and\s+/,/ig;
	# strip spaces around ","
	$names =~ s/\s*,\s*/,/g;
	my @n_arr = split(/\s*,\s*/, $names);
	#  print Dumper @n_arr;
	@n_arr = map(split_nameparts($_, $xname_flag), @n_arr);
	push @n_arr, "et al." if $etal;
	return @n_arr;
}

=item @parts = split_nameparts($name_string, $xname_flag)

	e.g.
	/John/von/Jones/Jr./
	/Ed/Krol/
	/Ludwig/von/Beethoven/
	/Frederick P.//Brooks/Jr./
	/Sandra/Da Campo/		-- a space within the last name
	/Dan R.//Olsen/Jr./		-- middle initial / several firstnames
	i.e.
		1 -> "/Company/"
		2 -> "/Firstnames/Lastname/"
		3 -> hm ... "/Firstnames/von/Lastname/"
		4 -> "/Firstnames/von/Lastname/Jr/"

	if $xname_flag is undef or 0
	return: [firstnames .... "von last, Jr."]
	--> no separate handling of "von" and "Jr." possible.
	--> ["one-name-only"] = company
	--> "et al." = and others

	if $xname_flag is set
	return: [firstnames, [von, last, jr]]	in case 4
	or		[firstnames, [von, last]]		in case 3
	or		[firstnames, [last]]			in case 2
	or		[company]					in case 1

=cut

sub split_nameparts {
	my ($name, $xname_flag) = @_;
	
	# etal handling
	return "et al." if $name eq "others"; #nobody can be named "others" :-)
	return "et al." if $name =~ /"^et\s+al\.?$"/;
	
	### ToDo: use some bibtex heuristic to look for 
	### "jr.", "von", "da" etc.
	return [split(/\s+/, $name)] if $name !~ /^\/.+\/$/;
	
	# parse the formatted name string
	my @parts = split(/\//, $name);
	shift @parts; # the first one is always empty.
#  print STDERR Dumper([@parts]);
	return [] unless @parts; # error, no name. that's strange ...
	my $first = shift(@parts);
	return [$first] unless @parts; # 1: compary name
	my $von = shift(@parts) if scalar(@parts) > 1;	# 3,4: von
	my $jr = pop(@parts) if scalar(@parts) > 1;		# 4: Jr
	my $last = pop(@parts);							# 2,3,4: last
	
#  print STDERR "$name -> ";
#  print STDERR "von: <$von> " if $von;
#  print STDERR "last: <$last> " if $last;
#  print STDERR "jr: <$jr> " if $jr;
#  print STDERR "first(s): <$firsts> ";

	my @firsts = split(/\s+/, $first);

	if( $xname_flag ) {
		return [@firsts, [$von, $last, $jr]];
	}

	# now assemble the name array
	$last = "$von $last" if $von;
	$last = "$last, $jr" if $jr;
#  print STDERR "-> last: <$last>\n";

	return [@firsts, $last];
}

=item @parts = split_namepartsold($name_string)

	/Jones/von/John/Jr./,/Krol/Ed/,/Beethoven/von/Ludwig/
	i.e.
		2 "/" -> "/Company/"
		3 "/" -> "/Lastname/Firstnames/"
		4 "/" -> hm ... "/Lastname/von/Firstnames/"
		5 "/" -> "/Lastname/von/Firstnames/Jr/"

	currently return: [firstnames .... "von last, Jr."]
	--> no separate handling of "von" and "Jr." possible.
	--> ["one-name-only"] = company
	--> ["et al."] = and others

=cut

sub split_namepartsold {
	my ($name) = @_;
	return [split(/\s+/, $name)] if $name !~ /^\/.+\/$/;
	
	# parse the formatted name string
	my @parts = split(/\//, $name);
	shift @parts; # the first one is always empty.
#  print STDERR Dumper([@parts]);
	return [] unless @parts; # error, no name. that's strange ...
	my $last = shift(@parts);
	return [$last] unless @parts; # compary name
	my $von = shift(@parts) if scalar(@parts) > 1;
	my $jr = pop(@parts) if scalar(@parts) > 1;
	
#  print STDERR "$name -> ";
#  print STDERR "von: <$von> " if $von;
#  print STDERR "last: <$last> " if $last;
#  print STDERR "jr: <$jr> " if $jr;
#  print STDERR "first(s): <@parts> ";

	# now assemble the name array
	$last = "$von $last" if $von;
	$last = "$last, $jr" if $jr;
#  print STDERR "-> last: <$last>\n";

	return [split(/\s+/, $parts[0]), $last];
}

sub num_names { my ($names) = @_;
	return scalar(split_names($names));
}
sub first_names { my ($name_array) = @_;
	return undef if $name_array eq "et al.";
	my @names = @{$name_array};
	pop @names;
	return @names;
}
sub first_initials { my ($name_array, $initials_space) = @_;
# $initials_space if true add a space between initials,
#		otherwise they are directly concatenated
	my @first = first_names($name_array);
	return undef unless @first;
	# use each first character as initial and add dot:
	@first = map( substr($_, 0, 1) . '.', @first);
	return @first if wantarray;
	return join($initials_space ? ' ' : '', @first);
}

sub last_name { my ($name_array) = @_;
#  my $num_names = scalar(@{$name_array});
#  return $name_array->[$num_names - 1];
	return "et al." if $name_array eq "et al.";
	my $last = $name_array->[-1];
	return $last unless ref($last) eq 'ARRAY';
	return $last->[1];
}

sub join_and_list {
	my $n = scalar(@_);
	return "@_" if $n < 2;
	return "$_[0] and $_[1]" if $n == 2;
	my $last = pop(@_);
	return join(", ", @_) . ", and $last";
}

sub multi_page_check { my ($pages) = @_;
# return true, if more then one page
	my @pp = split(/[,;:-]/, $pages);
	return scalar(@pp) > 1 || $pages =~ /f$/;
}

=back

=cut


#
#
# bp'util methods
#
#

our $AUTOLOAD;
sub AUTOLOAD {
#  my $self = shift;
  my ($method) = $AUTOLOAD;
  my (@parameters) = @_;
  $method =~ s/.*:://;
  $method = "bp_util'$method";
  &bib'debugs("call method $method", 2);
#print "self = $self call <$method> args: <@parameters>\n";
  &$method(@parameters);
}

1;


__END__

=head1 EXPORT

#
#
# Major functions available for users to call:
#
#
#    bp_util'mname_to_canon($names_string);
#    bp_util'mname_to_canon($names_string, $flag_reverse_author);
#
#    bp_util'name_to_canon($name_string);
#    bp_util'name_to_canon($name_string, $flag_reverse_author);
#
#    bp_util'canon_to_name($name_string);
#    bp_util'canon_to_name($name_string, $how_formatted);
#
#    bp_util'parsename($name_string);
#    bp_util'parsename($name_string, $how_formatted);
#
#    bp_util'parsedate($date_string);
#
#    bp_util'canon_month($month_string);
#
#    bp_util'genkey(%canon_record);
#
#    bp_util'regkey($key);
#


=head1 AUTHOR

Biblio::Util frontend to bp_util by Peter Tandler <pbib@tandlers.de>

# The bp package is written by Dana Jacobsen (dana@acm.org).
# Copyright 1992-1996 by Dana Jacobsen.
#
# Permission is given to use and distribute this package without charge.
# The author will not be liable for any damage caused by the package, nor
# are any warranties implied.

=head1 SEE ALSO

C<bp> package

=head1 HISTORY

$Log: Util.pm,v $
Revision 1.7  2003/12/22 21:51:45  tandler
new function "first_initials" to format first names as initials

Revision 1.6  2003/09/23 11:38:00  tandler
splitnames improved
changed format /// syntax. now: /first/von/last/jr/

Revision 1.5  2003/06/12 22:13:29  tandler
improved split_names()
 - et al. handling
 - support /Jones/von/John/Jr./,/Krol/Ed/,/Beethoven/von/Ludwig/
new join_and_list()

Revision 1.4  2003/05/22 11:48:36  tandler
theoretically it is now possible to use several words of the title for generated default CiteKEys. (not tested ...)

Revision 1.3  2003/02/20 09:24:16  ptandler
improved defaultCiteKey

Revision 1.2  2003/01/27 21:09:19  ptandler
create normailzed CiteKeys for ACM/DL bibtex entries

Revision 1.1  2002/10/11 10:17:22  peter
access bp_util methods and others ...


=cut