#################################################################
# Functions.pm - internal functions for reading, parsing, arrays
#################################################################
# Original version thanks to Tom Hladish
#
# $Id: Functions.pm,v 1.16 2012/02/07 21:49:27 astoltzfus Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::Functions - Provides private utiliy functions for the module 

=head1 SYNOPSIS

=head1 DESCRIPTION

This package provides private functions that are not object-specific.

=head1 COMMENTS

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) is greatly appreciated. 

=head1 AUTHORS

 Original version by Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.16 $

=head1 METHODS

=cut

package Bio::NEXUS::Functions;

use strict;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Util::Exceptions;
use vars qw(@EXPORT @EXPORT_OK @ISA $VERSION);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;
use Exporter ();

@ISA    = qw ( Exporter );
@EXPORT = qw(
    &_slurp
    &_parse_nexus_words
    &_ntsa
    &_stna
    &_quote_if_needed
    &_nexus_formatted
    &_is_comment
    &_is_number
    &_is_dec_number
    &_sci_to_dec
    &_unique
    &_nonunique
    &_share_elements
    &_fast_in_array
    &_in_array
    &_is_same_array
);

## READING & PARSING FUNCTIONS:

=begin comment

 Name    : _slurp
 Usage   : $file_content = _slurp($filename);
 Function: reads an entire file into memory
 Returns : none
 Args    : file name (string)

=end comment 

=cut

sub _slurp {
    my ($filename) = @_;
    open my $fh, '<', "$filename"
        || Bio::NEXUS::Util::Exceptions::FileError->throw(
    	'error' => "ERROR: Could not open filename <$filename> for input; $!"
    ); 
    my $file_content = do { local ($/); <$fh> };
    return $file_content;
}

=begin comment

 Title   : _parse_nexus_words
 Usage   : $parsed_words = _parse_nexus_words($buffer);
 Function: parse a string of text into "words" (as defined in the NEXUS standard)
 Returns : an array ref of "words" and punctuation marks.  Single-quoted expressions are single "words".  Double quotes are not supported.
 Args    : text buffer
 Notes   : this method has replaced _parse_string_tokens(), which did not conform to the NEXUS standard in all its quirky splendor (particularly with regard to punctuation)

=end comment 

=cut

sub _parse_nexus_words {
    my $buffer = shift;
    if ( not defined $buffer ) {
	    Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => '_parse_nexus_words() requires a text string argument (the text to be parsed)'
    	);
    }
    my @words;
    my ( $word, $in_quotes ) = ( q{}, 0 );

    my @chars         = split( //, $buffer );
    my $comment_level = 0;

    # iterate through the characters
    for ( my $i = 0; $i < @chars; $i++ ) {
        my $char = $chars[$i];
        my $next = $chars[ $i + 1 ];

        if ($comment_level) {  # if we are in a comment already
            $comment_level++ if ( $char eq '[' );
            $comment_level-- if ( $char eq ']' );
            $word .= $char;
        }

        # If we see a quote
        elsif ( $char eq q{'} ) {

            # and we're already inside quotes . . .
            if ($in_quotes) {

                # check to see if this is an escaped (doubled single) quote,
                # (unless we're already at the end of the string to be parsed).
                if ( defined $next && $next eq q{'} ) {

                    # If it is, append it to the current word;
                    $word .= $char;
                }
                else {

                    # otherwise, close off the quoted string
                    $in_quotes--;

                    # Replace spaces with underscores (according to NEXUS, they're equivalent)
                    # 
                    # This may not be correct.  Certainly TreeBASE doesn't like it
                    # when we use both quoted strings and underscores in them
                    $word =~ s/ /_/g;

                    # Push it onto the word list, after
                    # dealing with funny apostrophe business
                    push @words, _ntsa($word);

                    # And clean the slate
                    $word = q{};
                }
            }
            else {

                # If we weren't in quotes before, we are now
                $in_quotes++;
            }
        }
        elsif ($in_quotes) {

            # We're in a quoted string, so anything can be part of the word
            $word .= $char;
        }
        elsif ( $char eq '[' ) {  # hit new comment, level 0 (bug if we just finished one)
            $comment_level++;
            $word .= $char;
        }

        # If we see NEXUS-style punctuation
        elsif ( $char =~ /[\[\]\-(){}\/\\,;:=*"`+<>]/ ) {
        	
            push @words, &_ntsa($word)

                # $word will be q{} if there was a preceding space;
                # otherwise, it will contain some string
                unless $word eq q{};

			# then that counts as a word (we'll deal with pos/neg 
			# numbers later in _rebuild_numbers() if that gets called)
            push @words, $char;
            $word = q{};
        }

        # If we see whitespace
        elsif ( $char =~ /\s/ ) {

            # then we just finished a [probably] normal, space-delimited word
            push @words, &_ntsa($word)

                unless $word eq q{};

            # although we don't want to keep pushing it
            # if there are multiple spaces, so we empty $word
            $word = q{};
        }

        # If $word isn't quoted, and $char is neither punctuation nor whitespace
        else {
            $word .= $char;
        }
    }

    push @words, $word unless $word eq q{};
    return \@words;
}

sub _rebuild_numbers {
    my $words = shift;
    my @new_words;

    # Don't bother checking whether the last word is a '+' or '-'
    for ( my $i = 0; $i < ( @$words - 1 ); $i++ ) {
        my $word = $words->[$i];
        my $next = $words->[ $i + 1 ];    # There will always be a next

        #        my $next_next = defined $words[$i +2] ? $words[$i+2] : q{};
        # There might be a previous
        my $last = $i == 0 ? undef: $words->[ $i - 1 ];

        if ( $word eq '-' || $word eq '+' ) {
            if ( my ( $num, $exp ) = $next =~ /^([\d.]+)(e)?/i ) {
                if ( _is_dec_number($num) ) {
                    $word .= $next;
                    $i++;
                    if ($exp) {

                    }
                }
            }
        }
        else {
            push @new_words, $word;
        }
    }
    return \@new_words;
}

=begin comment

 Title   : _ntsa (nexus to standard apostrophe)
 Usage   : $standard_word = $block->_ntsa($nexus_word);
 Function: change doubled single quotes to single single quotes (apostrophes)
 Returns : a standard english word (or phrase)
 Args    : a nexus "word"
 Notes   : See NEXUS definition of "word" for an explanation
 
=end comment 

=cut

sub _ntsa {
    my $nexus_word = shift;
    $nexus_word =~ s/[^']''[^']/'/g;
    return $nexus_word;
}

=begin comment

 Title   : _stna (standard to nexus apostrophe)
 Usage   : $nexus_word = $block->_stna($standard_word);
 Function: change single single quotes (apostrophes) to double single quotes
 Returns : a nexus "word"
 Args    : a standard english word (or phrase)
 Notes   : See NEXUS definition of "word" for an explanation
 
=end comment 

=cut

sub _stna {
    my $standard_word = shift;
    $standard_word =~ s/[^']'[^']/''/g;
    return $standard_word;
}

=begin comment

 Title   : _quote_if_needed
 Usage   : $string = Bio::NEXUS::Block::_quote_if_needed($string);
 Function: put single quotes around string if it contains spaces or NEXUS punctuation
 Returns : a string, in single quotes if necessary
 Args    : a string
 
=end comment 

=cut

sub _quote_if_needed {
    my $nexus_word = shift;
    if ( $nexus_word =~ /[-\s(){}\[\]\/\\,;:=+*<>`'"]/ ) {
        return "'$nexus_word'";
    }
    else {
        return $nexus_word;
    }
}

=begin comment

 Title   : _nexus_formatted
 Usage   : $string = Bio::NEXUS::Block::_nexus_formatted($string);
 Function: escape apostrophes and quote strings as needed for NEXUS output
 Returns : a string
 Args    : a string
 
=end comment 

=cut

sub _nexus_formatted {
    my $nexus_word = shift;
    $nexus_word = _quote_if_needed( _stna($nexus_word) );
    return $nexus_word;
}

=begin comment

 Name    : _is_comment
 Usage   : $boolean = _is_comment($string);
 Function: tests whether something looks like a comment
 Returns : boolean
 Args    : string to test

=end comment 

=cut

sub _is_comment {
    my ($string) = @_;
    if ( $string =~ /^\[.*\]$/s ) { return 1 }
    else { return 0 }
}

=begin comment

 Title   : _is_dec_number
 Usage   : if ( _is_dec_number($num) ) { do_something() };
 Function: verifies that a number is a normal decimal number (e.g. 3 or 9.41)
 Returns : 1 if $num is a number, otherwise 0
 Args    : a number

=end comment 

=cut

sub _is_dec_number {
    my ($number) = @_;

    return 0 unless defined $number && length $number;

    my $number_regex = qr/^[-+]?                 # positive or negative
                                (?: \d+          # e.g., 523
                                 | \d*[.]\d+     # 3.14 or .45
                                 | \d+[.]\d*     # 212. or 212.0
                                )
                        $/x;

    return 0 unless defined $number && $number =~ $number_regex;

    return 1;
}

=begin comment

 Title   : _is_number
 Usage   : if ( _is_number($num) ) { do_something() };
 Function: verifies that a number is of reasonable form (such as 0.4 or 6.1e2.1)
 Returns : 1 if $num is a number, otherwise 0
 Args    : a number

=end comment 

=cut

sub _is_number {
    my ($number) = @_;

    return 0 unless defined $number && length $number;

    my ( $num, $exp ) = $number =~ /^([^e]+)(?:e([^e]+))?$/i;

    return 0 unless _is_dec_number($num);

    return _is_dec_number($exp) if defined $exp;

    return 1;
}

=begin comment

 Title   : _sci_to_dec
 Usage   : $decimal = _sci_to_dec($scientic_notation);
 Function: Changes scientific notation to decimal notation
 Returns : scalar (a number)
 Args    : scalar (a number), possibly in scientific notation

=end comment 

=cut

sub _sci_to_dec {
    my ($sci_num) = @_;

    $sci_num =~ s/\s//g;
    return $sci_num if _is_dec_number($sci_num);

    my ( $num, $exp ) = $sci_num =~ /^ ([^e]+) e ([^e]+) $/ix;

    return 0 unless ( _is_dec_number($num) && _is_dec_number($exp) );

    my $dec_num = $num * ( 10**$exp );
    return $dec_num;
}

## ARRAY FUNCTIONS:

=begin comment

 Name    : _any
 Usage   :  _any($filename);
 Function: reads an entire file into memory
 Returns : none
 Args    : file name (string)

=end comment 

=cut

sub _unique {
    my (@array) = @_;
    my %seen = ();

    # from perl cookbook.  fast, and preserves order
    my @unique = grep { !$seen{$_}++ } @array;
    return @unique;
}

sub _nonunique {
    my (@array) = @_;
    my %seen = ();
    my @nonunique = grep { $seen{$_}++ } @array;
    return @nonunique;
}

sub _share_elements {
    my ( $array1, $array2 ) = @_;
    for my $element1 (@$array1) {
        if ( &in_array( $array2, $element1 ) ) { return 1; }
    }
    return 0;
}

sub _fast_in_array {
    my ( $array, $element ) = @_;
    for (@$array) {
        if ( $element eq $_ ) {
            return 1;
        }
    }
    return 0;
}

sub _in_array {
    my ( $array, $test ) = @_;
    my $match = 0;
    for (@$array) {
        $match++ if $_ eq $test;
    }
    return $match;
}

sub _is_same_array {
    my ( $array, $test ) = @_;
    return 1 if $array eq $test;
    return 0 unless scalar @$array == scalar @$test;

    my $astr = join '', sort @$array;
    my $tstr = join '', sort @$test;
    return 1 if $astr eq $tstr;
    return 0;
}

1;
