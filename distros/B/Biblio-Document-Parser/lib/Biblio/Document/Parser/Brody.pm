package Biblio::Document::Parser::Brody;

######################################################################
#
# Biblio::Document::Parser::Brody; 
#
######################################################################
#
#  Reference Parser by Tim Brody <tdb01r@ecs.soton.ac.uk>
#
#  This file is part of ParaCite Tools (http://paracite.eprints.org/developers/) 
#
#  Copyright (c) 2002 University of Southampton, UK. SO17 1BJ.
#
#  ParaTools is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  ParaTools is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with ParaTools; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
######################################################################

=pod

=head1 NAME

Biblio::Document::Parser::Brody

=head1 DESCRIPTION

Module that parses reference strings from a document. Relies on a reference section starting with a title "References", "Bibliography", or "Cited". Seperates references by prefixed number (e.g. "[1]" or "1.") or by year (e.g. "Smith, J (1992)").

=head1 SYNOPSIS

	use Biblio::Document::Parser::Brody;

	my $parser = new Biblio::Document::Parser::Brody();

	my @refs = $parser->parse(\*FILE_IO);
	my @refs = $parser->parse($str);

=head1 METHODS

=cut

use strict;

use Carp;
use vars qw($DEBUG $RE_BOR $RE_EOR $RE_NAME_CHARS $RE_NAME $RE_NAME_LIST_CHARS $MAX_SIZE);

# Set up the input/output appropriately
#use open IN => ':encoding(latin1)', OUT => ':utf8';

$MAX_SIZE = 1024*2000; # 2MB

$RE_BOR = qr/^[^a-z]*(?:references(?:\s+cited)?)|(?:bibliography)[^a-z]*$/i;
$RE_EOR = qr/^\s*(?:\d+\.?\s*)*(?:acknowledge?ment)|(?:footnote)|(?:appendix)|(?:abbreviation)|(?:glossary)|(?:figure)[^\n]{0,10}\s*$/i;
$RE_NAME_CHARS = qr/[a-zA-Z`'\-]/;
$RE_NAME_LIST_CHARS = qr/[a-zA-Z,\.;\(\)\-\s\&'`]/;
$RE_NAME = qr/(?:[a-zA-Z`'\-]{4,7}, *(?:[a-zA-Z]\. *)+)/;

=pod

=over 4

=item $p = Biblio::Document::Parser::Brody->new([-debug=>1])

Constructor method for class.

=cut

sub new {
	my ($class,%args) = @_;
	$DEBUG = $args{-debug};
	return bless {}, $class;
}

=pod

=item @refs = $p->parse($str)

Parses a string $str and returns a list of unstructured reference strings.

=cut

sub parse {
	my $self = shift @_;
	my $arg = shift @_;
	my $BIBL = '';

	# UNIVERSAL::isa($arg,"IO::Handle") doesn't work?
	if( ref($arg) ) {
		read($arg,$BIBL,$MAX_SIZE) or croak "Error reading from file handle: $!\n";
	} else {
		$BIBL = join('',$arg,@_);
	}

	croak "No data to parse\n" unless length($BIBL);

	$BIBL =~ s/\f/\n\n/sg;

	my %HEADERS;

	while( $BIBL =~ /(?:\n[\r[:blank:]]*){2}([^\n]{0,40}\w+[^\n]{0,40})(?:\n[\r[:blank:]]*){3}/osg ) {
		$HEADERS{header_to_regexp($1)}++;
	}

	if( %HEADERS ) {
		my @regexps = sort { $HEADERS{$b} <=> $HEADERS{$a} } keys %HEADERS;
		my $regexp = $regexps[0];
		if( $HEADERS{$regexp} > 3 ) {
			my $c = $BIBL =~ s/(?:\n[\r[:blank:]]*){2}(?:$regexp)(?:\n[\r[:blank:]]*){3}/\n\n/sg;
			warn "Applying regexp: $regexp ($HEADERS{$regexp} original matches) Removed $c header/footers using ($HEADERS{$regexp} original matches): $regexp\n" if $DEBUG;
		} else {
			warn "Not enough matching header/footers were found\n" if $DEBUG;
		}
	} else {
		warn "No header/footers were found\n" if $DEBUG;
	}

	# Kill any bad chars
#	local *lat2uni = convertor( 'latin1', 'utf8' );
#	lat2uni(\$BIBL);

#	if( $BIBL =~ /$RE_BOR/mi ) {
#		$BIBL = $';
#	} else {
#		croak "FATAL: Unable to find reference section\n";
#	}


	my @REFS;

	# Attempt to find the reference section
	while( !@REFS && ($BIBL =~ /$RE_BOR/mi) && ($BIBL = $') ) {
		my $c = 0;

		# Count the number of occurences of [\d] over the next 2k of data or so
		my $buffer = substr($BIBL, 0, 2048);
		$c = 0;
		while($buffer =~ m/^\s*\[\d+\]/mog) { last if ++$c == 5 }
		if( $c >= 5 ) {
	warn "Style = numbered square ([1])\n" if $DEBUG;
			last if (@REFS = &style_numbered_square($BIBL));
		}

		# How about 1. notation
	#	$buffer = substr($BIBL, 0, 2046);
		$c = 0;
		while($buffer =~ m/^\s*(\d+)\./mog) { last if ++$c == 5 }
		if( $c >= 5 ) {
	warn "Style = numbered (1.)\n" if $DEBUG;
	#		$BIBL =~ s/^\s*(\d+)\./\[$1\]/mg;
			last if (@REFS = &style_numbered($BIBL));
		}

		# Now we're getting desperate - hopefully its a name list followed by year
		# $buffer = substr($BIBL, 0, 2048);
		$c = 0;
		while($buffer =~ m/^$RE_NAME_LIST_CHARS{10,40}[^\d\-]19|20\d{2}[^\d\-]/mog) { last if ++$c == 5 }
		if( $c >= 5 ) {
	warn "Style = years\n" if $DEBUG;
			last if (@REFS = &style_years($BIBL));
		}

#		if( @REFS ) {
#			last;
#		} elsif( $BIBL =~ /$RE_BOR/mi ) {
#	warn "Skipping section ...\n" if $DEBUG;
#			$BIBL = $';
#		} else {
#			last;
#		}
	}

	for( my $i = 0; $i < @REFS; $i++ ) {
		my $ref = $REFS[$i] or next;
#		$REFS[$i] = "[" . ($i+1) . "] " . unicode_string($ref);
		$REFS[$i] = "[" . ($i+1) . "] " . $ref;
	}

	return grep { defined($_) && length($_) } @REFS;
}

#my ($BIBL, $buffer);
#$BIBL = '';

#my $lc = 0;

#die "FATAL: Input has gone beyond $MAX_SIZE byte limit" if read(STDIN,$BIBL,$MAX_SIZE) == $MAX_SIZE;

#die "Empty input" unless length($BIBL);

#while( read(STDIN,$buffer,4096) ) {
#	$BIBL .= $buffer;
#	die "FATAL: Input has gone beyond $MAX_SIZE bytes limit" if length($BIBL) > $MAX_SIZE;
#}


#while( <> ) {
#	s/\f/\n\n/sg;
#	$BIBL = $_ . $BIBL;
#	die "FATAL: Input has gone beyond $MAX_SIZE bytes limit" if length($BIBL) > $MAX_SIZE;
#	if( $_ =~ /^(?:\n\s*){3}/ ) {
#		# Regexp matches for the end of the string are *really* bad performance
#		# Lines are in reverse order!
#		if( $BIBL =~ /^(?:\n\s*){3}([^\n]{0,40}\w+[^\n]{0,40})(?:\n\s*){2}/os ) {
#			$HEADERS{header_to_regexp($1)}++;
#		}
#	}
#}

# Put the lines back in-order
#my @lines = split(/\n/,$BIBL);
#$BIBL = '';
#for(@lines) {
#	$BIBL = $_ . "\n" . $BIBL;
#}

# Read in the document
#while( read(STDIN,$buffer,4096) ) {
#	if( length($BIBL) > $MAX_SIZE ) {
#		die "FATAL: Input has gone beyond $MAX_SIZE Bytes limit\n";
#	}
#	$BIBL .= $buffer;
#}

#print "Ref section:\n", $BIBL;

# Change to utf8
#use utf8;

#### REMAINING FUNCTIONS ARE INTERNAL OR DEPRECATED ####

sub end_of_references {
	my $ref = shift;
	if( $$ref =~ /${RE_EOR}/im ||
	    $$ref =~ /^\s*acknowledgements:/im ) {
		$$ref = $`;
		return 1;
	}
	if( $$ref =~ /(?:\s*\n){3,}/s ) {
		$$ref = $`;
		return 1;
	}
	if( length($$ref) > 1024 ) {
		return 1;
	}
	return 0;
}

sub style_numbered {
	my @REFS = split(/^\s*(\d+\.)/m, shift);

	shift @REFS while (@REFS && ($REFS[0] !~ /^\d+\./ || substr($REFS[0],0,-1) != 1));

	my $i = 2;
	while( $i < @REFS ) {
		if( $REFS[$i] =~ /^\d+\./ ) {
			my $val = substr($REFS[$i],0,-1);
			if( $val != ($i/2)+1 ) {
				$REFS[$i-1] .= splice(@REFS,$i,1);
			} else {
				$i+=2;
			}
		} else {
			$REFS[$i-1] .= splice(@REFS,$i,1);
		}
		if( end_of_references(\$REFS[$i-1]) ) {
			splice(@REFS,$i);
		}
	}

	for( my $i = 0; $i < @REFS; $i++ ) {
		$REFS[$i] .= splice(@REFS,$i+1,1);
		$REFS[$i] =~ s/\s+/ /sg;
		$REFS[$i] =~ s/^\s+//;
		$REFS[$i] =~ s/\s+$//;
	}

	@REFS;
}

sub style_numbered_square {
	my $BIBL = shift;

	# Split the bibliography
	$BIBL =~ /(?=\[\d+\])/;
	my @REFS = split(/^\s*\[(\d+)\]/m, $') or return ();
	shift @REFS unless $REFS[0];


	# Make sure there is a "value" to go with a reference number
#	for( my $i = 0; $i < @REFS; $i+=2 ) {
#		if( $REFS[$i+1] =~ /\[\d+\]/ ) {
#			splice(@REFS,$i+1,0,'');
#		}
#	}

	# If there is a large reference its probably the end of the bibliography
	for( my $i = 10; $i < @REFS; $i++ ) {
		if( length($REFS[$i]) > 1024 ) {
			splice(@REFS, $i+1);
			$REFS[$i] = substr($REFS[$i],0,1024) . " RUNAWAY_REFERENCE_DETECTED ";
		}
	}

	# Add any out-of-order chunks to the previous reference value
	my $last = 0;
	my $max = 0;
	for( my $i = 0; $i < @REFS; $i+=2 ) {
		my $n = $REFS[$i];
#		$n =~ s/\D//g;
		$max = $n if $n > $max;
		if( $n == $last+1 ) {
			$last++;
			next;
		} else {
			# Join this out-of-order chunk onto the previous ref.
			$REFS[$i-1] .= splice(@REFS,$i,2);
		}
	}

	# Remove any trailing garbage
	splice(@REFS, $last*2, -1);
	
	# Presumably there is a gap between the last reference and any trailing junk
	$REFS[$#REFS] =~ s/(\r?\n){2}.*//s;
	
	# Prettify the references
	for( my $i = 1; $i < @REFS; $i+=2 ) {
		$REFS[$i] =~ s/[\r\n]+/ /sg;
		$REFS[$i] =~ s/^\s+//sg;
		$REFS[$i] =~ s/\s+$//sg;
	}
	
	# Get rid of the numbering
	for( my $i = 0; $i < @REFS; $i++ ) {
#		$REFS[$i] = $REFS[$i+1];
		splice(@REFS,$i,2,$REFS[$i+1]);
	}

	return @REFS;
}

sub style_years {
	my $BIBL = shift;

	$BIBL =~ s/^\s+//sg;

	# Convert very long lines of spaces into a return
	$BIBL =~ s/ {70} */\n/sg;

	my @REFS;

	# Lets try splitting on a blank line
	@REFS = split(/((?:\s*\n){2})/, $BIBL);

	shift @REFS while (@REFS && $REFS[0] !~ /^$RE_NAME_LIST_CHARS+\d{4}\D/);

	# That didn't work, lets split on left-aligned things (where the next line(s) are blank or indented)
	if( !@REFS || length($REFS[0]) > 300 ) {
		@REFS = split(/\n[ ]{0,2}((?:(?:\S$RE_NAME_LIST_CHARS{10,})|$RE_NAME[^\d\-])\d{4}[^\d\-][^\n]+)/, $BIBL);
		shift @REFS while (@REFS && $REFS[0] !~ /^$RE_NAME_LIST_CHARS{10,}\d{4}\D/s);

#return @REFS;

		for( my $i = 1; $i < @REFS; $i++ ) {
			if( end_of_references(\$REFS[$i]) ) {
				splice(@REFS,$i+1);
			# Indented
			} elsif( $REFS[$i] =~ /^\s* {5}|\t/m ) {
				$REFS[$i-1] .= splice(@REFS,$i,1);
			}
		}
	} else {
		for( my $i = 1; $i < @REFS; $i++ ) {
			if( end_of_references(\$REFS[$i]) ) {
				splice(@REFS,$i+1);
			}
		}
	}

	# If we find what looks like the end of the reference section, discard the trailing rubbish
#	for( my $i = 0; $i < @REFS; $i++ ) {
#		if( end_of_references(\$REFS[$i]) ) {
#			splice(@REFS,$i+1);
#		} elsif( $BIBL =~ /(\r?\n){3}/s ) {
#			$REFS[$i] = $`;
#			splice(@REFS,$i+1);
#		}
#	}

	unless( @REFS ) {
		warn "Unable to split year-based references\n";
		return ();
	}

	# Remove heavily indented lines following a blank line
	for( my $i = 1; $i < @REFS; $i++ ) {
		if( $REFS[$i-1] !~ /\S/ && $REFS[$i] =~ /^\s{40}/ ) {
			splice(@REFS,$i,1);
			$i--;
		}
	}

	# Join refs with the previous reference if they are very short or are quite short and don't start with ...(year)
	for( my $i = 1; $i < @REFS; $i++ ) {
		my $l = $REFS[$i];
		$l =~ s/\s+//sg;
		if( (length($l) < 30) ||
		    (length($l) < 50 && $REFS[$i] !~ /^$RE_NAME_LIST_CHARS{10,40}[^\d\-](\d{4})[^\d\-]/s) ) {
			$REFS[$i-1] .= $REFS[$i];
			splice(@REFS,$i,1);
			$i--;
		}
	}

	# If we find 3 sequential references without years near the beginning we probably have trailing garbage
	my $lc = 0;
	for( my $i = 10; $i < @REFS; $i++ ) {
		if( $REFS[$i] =~ /^\D{10,50}19|20\d{2}/s ) {
			$lc = 0;
		} else {
			$lc++;
		}
		if( $lc == 3 ) {
			splice(@REFS,$i-2);
		}
	}

	# Remove lines without any numbers that are quite long (excluding spaces)
	for( my $i = 0; $i < @REFS; $i++ ) {
		my $l = $REFS[$i];
		$l =~ s/\s+//sg;
		if( length($l) > 100 && $REFS[$i] !~ /\d/ ) {
			splice(@REFS,$i,1);
		}
	}

	# Prettify
	map { $_ =~ s/\s+/ /sg; $_ =~ s/^\s+//; $_ =~ s/\s+$//s; } @REFS;

# This doesn't work - names are too icky
	# Now go back in and split anything that looks like name, x (year)
#	for( my $i = 0; $i < @REFS; $i++ ) {
#		my @srefs = grep { $_ =~ /\S/ } split(/((?:[a-zA-Z\-\'\.]+\s*,\s*[a-zA-Z\.]+.{0,7})+\d{4}\b)/, $REFS[$i]);
#		next unless @srefs > 2;
#print "Split reference:\n",
#	(map { "PART: \"$_\"\n" } @srefs), "\n";
#	}
#die;

	return @REFS;
}

sub header_to_regexp {
	my $header = shift;
	$header =~ s/([\\\|\(\)\[\]\.\*\+\?\{\}])/\\$1/g;
       	$header =~ s/\s+/\\s+/g;
       	$header =~ s/\d+/\\d+/g;
	return $header;
       	return q/(?:\n\s*){3}(/.$header.q/)(?:\n\s*){2}/;
}

#sub unicode_string {
#	$_ = shift();
#	s/[\x00-\x08\x0b-\x0c\x0e-\x1f]//sg;
#	s/([\x80-\xff])/sprintf("&#x%04x;",ord($1))/seg;
#	return $_;
#}

1;

__END__

=back

=head1 AUTHOR

Written by Tim Brody <tdb01r@ecs.soton.ac.uk>
