package DDG::Request;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: A request to DuckDuckGo itself, so the query itself and parameter around the query defining him
$DDG::Request::VERSION = '1018';
use Moo;
use utf8;


#
# QUERY
#
###############################


has query_raw => (
	is => 'ro',
	required => 1,
);

my $whitespaces = qr{\s+};
my $whitespaces_matches = qr{($whitespaces)};
my $whitespaces_dashes = qr{[\s\-]+};
my $non_alphanumeric_ascii = qr{[\x00-\x1f\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x81\x{a7}]+};


has query_raw_parts => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query_raw_parts',
);
sub _build_query_raw_parts {
	[
		split(/$whitespaces_matches/,shift->query_raw)
	]
}


has query_parts => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query_parts',
);
sub _build_query_parts {
	my $x;
	[
		grep { ( $x += length ) < 500 } # 500 matches the internal query max
		grep { ! /$whitespaces/ } 
		grep { length }
		@{shift->query_raw_parts}
	]
}


has query_parts_lc => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query_parts_lc',
);
sub _build_query_parts_lc {
	[
		map { lc }
		@{shift->query_parts}
	]
}


has triggers => (
	is => 'ro',
	lazy => 1,
	builder => '_build_triggers',
);
sub _build_triggers {
	my ( $self ) = @_;
	my @parts = @{$self->query_raw_parts};
	return {} if not scalar @parts;
	my $x = $parts[0] eq '' ? 2 : 0;
	my %triggers;
	for ($x..(scalar @parts-1)) {
		unless ($_ % 2) {
			$triggers{$_} = $self->generate_triggers($parts[$_]);
		}
	}
	return \%triggers;
}


sub generate_triggers {
	my $part = lc $_[1];
	my %parts;
	++$parts{$part};
	$part =~ s/^!//go && ++$parts{$part};
	$part =~ s/\?$//go && ++$parts{$part};
	# Look for non-word characters, except single quotes, e.g. can't, John's
	if ($part =~ /[^\w']/o) {
		# The split could be part of the if but it would leave single quotes
		# in the resulting terms.
		my @boundary_words = split /\W+/o, $part ;
		++$parts{$_} for @boundary_words;
		++$parts{join('', @boundary_words)};
		++$parts{join(' ', @boundary_words)};
	}
	return [keys %parts];
}


has remainder => (
    is => 'rwp',
	lazy => 1
);

sub generate_remainder {
	my ( $self, $from_pos, $to_pos ) = @_;
	$to_pos = $from_pos unless defined $to_pos;
	my @query_raw_parts = @{$self->query_raw_parts};
	my $max = scalar @query_raw_parts-1;
	my $remainder = '';
	if ( $to_pos < $max && ( $from_pos == 0 || ( $from_pos == 2 && $query_raw_parts[0] eq '' ) ) ) {
		$remainder = join('',@query_raw_parts[$to_pos+1..$max]);
		$remainder =~ s/^\s//;
	} elsif ( $max % 2 ? $to_pos == $max-1 : $to_pos == $max ) {
		$remainder = join('',@query_raw_parts[0..$from_pos-1]);
		$remainder =~ s/\s$//;
	} else {
		my $left_remainder = join('',@query_raw_parts[0..$from_pos-1]);
		my $right_remainder = join('',@query_raw_parts[$to_pos+1..$max]);
		$left_remainder =~ s/\s$//;
		$right_remainder =~ s/^\s//;
		$remainder = $left_remainder.' '.$right_remainder;
	}
	$self->_set_remainder($remainder);
	return $remainder;
}


has matched_trigger => (
	is => 'ro',
	lazy => 1,
	builder => 1
);

sub _build_matched_trigger {
	my $self = shift;

	my $r = $self->remainder || '';
	my $qr = $self->query_raw;
	$qr =~ s/\s*\Q$r\E\s*//i;
	return $qr;
}


has query => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query',
);
sub _build_query {
	join(' ',@{shift->query_parts})
}


has query_lc => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query_lc',
);
sub _build_query_lc {
	lc(shift->query)
}


has query_nowhitespace => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query_nowhitespace',
);
sub _build_query_nowhitespace {
	for (shift->query) {
		s/$whitespaces//g;
		return $_;
	}
}


has query_nowhitespace_nodash => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query_nowhitespace_nodash',
);
sub _build_query_nowhitespace_nodash {
	for (shift->query) {
		s/$whitespaces_dashes//g;
		return $_;
	}
}


has query_clean => (
	is => 'ro',
	lazy => 1,
	builder => '_build_query_clean',
);
sub _build_query_clean {
	for (shift->query_lc) {
		s/$non_alphanumeric_ascii//g;
		s/$whitespaces/ /g;
		return $_;
	}
}


has words => (
	is => 'ro',
	lazy => 1,
	builder => '_build_words',
);
sub _build_words {
	[
		grep { length }
		split(/$whitespaces/,shift->query_clean)
	]
}


has wordcount => (
	is => 'ro',
	lazy => 1,
	builder => '_build_wordcount',
);
sub _build_wordcount { scalar @{shift->words} }


has seen_plugins => (
	is => 'rw',
	lazy => 1,
	builder => '_build_seen_plugins',
);
sub _build_seen_plugins {[]}

#
# LANGUAGE / LOCATION / IP
#
###############################

# DDG::Language TODO
has language => (
	#isa => 'DDG::Language',
	is => 'ro',
	predicate => 'has_language',
);
sub lang { shift->language }

has location => (
	#isa => 'DDG::Location',
	is => 'ro',
	predicate => 'has_location',
);
sub loc { shift->location }

1;

__END__

=pod

=head1 NAME

DDG::Request - A request to DuckDuckGo itself, so the query itself and parameter around the query defining him

=head1 VERSION

version 1018

=head1 SYNOPSIS

  my $req = DDG::Request->new( query_raw => "Peter PAUL AND MARY!" );
  print $req->query_clean; # "peter paul and mary"

=head1 DESCRIPTION

This is the main request class which reflects a query and all parameter that
are relevant for plugins to work with the request. It does not reflect a web
request itself to DuckDuckGo, for this we have internal classes. The request
class is the abstracted level all services can independently work with, on any
medium, so also on the L<API|http://duckduckgo.com/api.html>, or via console
based tests without web environment. This class is also base for run on a
L<DDG::Block>.

Beside the information of the query itself, a L<DDG::Request> can also contain
the language, the region and the geo location (which is calculated out of the
IP).

=head1 ATTRIBUTES

=head2 query_raw

This is the only required attribute. It is the query in the most raw form. If
the query is given over special ways (like coming out of a hard url like
L<https://duckduckgo.com/Star_Trek_Voyager>), then those most get converted to
the text that is normally shown on the query line then, before given to
L</query_raw>.

=head2 query_raw_parts

This attribute gets generated out of the L</query_raw>, which gets split into
all whitespace and non-whitespace content. For example the query:

  DDG::Request->new( query_raw => "A++    B++" );

would give you the following arrayref on L</query_raw_parts>:

  [
    'A++',
    '    ',
    'B++',
  ]

It preserves the exactly content of the query also the current amount of
whitespaces. Always the even index positions of the arrayref is the non
whitespace content. So if you have the query:

  DDG::Request->new( query_raw => "  A++    B++  " );

leads to this L</query_raw_parts> to fulfill this:

  [
    '',
    '  '
    'A++',
    '    ',
    'B++',
    '  ',
  ]

=head2 query_parts

This functions filters out the whitespace parts and empty parts of
L</query_raw_parts>.

=head2 query_parts_lc

This takes the arrayref of L</query_parts> and makes a lowercase arrayref
version of it.

=head2 triggers

Triggers generate a hashref construction which makes it very easy to parse a
query very effective through the accessing it word by word and so just
analyzing against as less combinations as possible.

It uses L</query_raw_parts> for this, but ignores the whitespace parts. Then it
passes every part through L</generate_triggers> which gives back all possible
variants of the specific given part.

=head2 matched_trigger

Uses L</remainder> and L</query_raw> to derive the trigger.  Will only
work when using the remainder handle.

=head2 query

Takes L</query_parts> and join them with one space.

=head2 query_lc

Takes L</query> and lowercases it.

=head2 query_nowhitespace

Takes L</query> and removes all whitespaces.

=head2 query_nowhitespace_nodash

Takes L</query> and removes all whitespaces and dashes.

=head2 query_clean

Takes L</query_lc> and removes all whitespaces and all non alphanumeric ascii.

=head2 words

Takes L</query_clean> and generates an arrayref of the non-whitespace parts.

=head2 wordcount

Is the count of the elements in L</words>

=head2 seen_plugins

This array contains all the plugins which already worked with this request.
This means all the plugins which are triggered. If they gave back a result or
not, doesn't matter here. This list is used by L<DDG::Block/allow_duplicate>.

=head1 METHODS

=head2 generate_triggers

This function takes a part of L</query_raw_parts> and generates all possible
variants of it, also doing some magic with dash given words to give both
single or combined without dash or only with space. For specific analyze what
triggers are generated out of a part please read the function.

=head2 generate_remainder

The method takes 2 index positions of L</query_raw_parts> to give out the other
parts of the query which is ot between them, so removes those parts and
generates out of the rest again a string which can be given to a plugin for
example.

It doesnt check which one is bigger, the first one must always be lower then
the second one given. You can also just give one index position.

When called will set the remainder attribute for later use, e.g. L</matched_trigger>.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
