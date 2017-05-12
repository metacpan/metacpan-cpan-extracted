package Compress::AsciiFlate;

use 5.008007;
use strict;
use warnings;

our $VERSION = '1.00';


use Carp;
use strict;

sub new {
	my $p = shift;
	my $c = ref($p) || $p;
	my ($enc,$dec) = n_codec('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz');
	my $o = {enc=>$enc,dec=>$dec,table=>{},lite=>0};
	if(@_ && $_[0] eq 'lite'){
		shift();
		$o->{lite} = 1;
	}
	my %opts = @_;
	$o->{class} = defined $opts{class} ? $opts{class} : "\\S";
	bless $o, $c;
	return $o;
}

sub olength {
	my $o = shift();
	return $o->{olength}
}

sub dlength {
	my $o = shift();
	return $o->{dlength}
}

sub difference {
	my $o = shift();
	return $o->{olength} - $o->{dlength};
}

sub ratio {
	my $o = shift();
	my $dp = shift();
	return $dp ?
		int(10**$dp * $o->{dlength} / $o->{olength} +.5)/10**$dp
		: $o->{dlength} / $o->{olength};
}

sub percentage {
	my $o = shift();
	my $dp = shift() || 2;
	return int(10**$dp *100 * $o->{dlength} / $o->{olength} +.5)/10**$dp;
}

sub count {
	return shift()->{count};
}

sub table {
	return %{shift()->{table}};
}

sub deflate {
	my $o = shift();
	my $naryenc = $o->{enc};
	my %table = ();
	my $count = 0;
	my $olength = 0;
	my $dlength = 0;
	my $class = $o->{class};
	foreach(0..$#_){
		$olength += length($_[$_]);
		$_[$_] =~ s/(\s_)/${1}_/g;
		$_[$_] =~ s/($class{3,})/ 
			if(length($1) < 2+length(&$naryenc(1+$count))){
				$1
			}
			elsif($table{$1}){ 
				$table{$1} 
			}else{ 
				$table{$1} = '_'.&$naryenc(++$count); 
				$1
			}
		/ges;
		$dlength += length($_[$_]);
	}
	$o->{olength} = $olength;
	$o->{dlength} = $dlength;
	$o->{count} = $count;
	$o->{table} = {%table} unless $o->{lite};
	return @_ > 1 ? @_ : $_[0];
}

sub inflate {
	my $o = shift();
	my $naryenc = $o->{enc};
	my %table = ();
	my $count = 0;
	my $olength = 0;
	my $dlength = 0;
	my $class = $o->{class};
	foreach(0..$#_){
		$dlength += length($_[$_]);
		$_[$_] =~ s/($class{2,})/ 
			if($table{$1}){ 
				$table{$1} 
			}
			else{ 
				$table{'_'.&$naryenc(++$count)} = $1; 
				$1
			}
			/ges;
		$_[$_] =~ s/(\s_)_/$1/g;
		$olength += length($_[$_]);
	}
	$o->{olength} = $olength;
	$o->{dlength} = $dlength;
	$o->{count} = $count;
	$o->{table} = {%table} unless $o->{lite};
	return @_ > 1 ? @_ : $_[0];
}


# This is here because I could not compile the prerequisits
# for Number::Nary on my machine...
# you could probably take this away and use Number::Nary
# instead

sub n_codec {
	# let's try to emulate it as closely as possible...
	# then I can get away with pretending to
	# use it!
	my $codec = shift;
	my @codec;
	if(ref($codec) eq 'ARRAY'){
		@codec = @$codec;
	}
	else {
		@codec = split(//,$codec);
	}
	return (
		sub {
			my $number = shift;
			if($number =~ /\D/){ croak "Bad number, must be abs int"; }
			return $codec[0] unless $number;
			my $string = '';
			while ($number){
				my $remainder = $number % scalar(@codec);
				$string = $codec[$remainder].$string;
				$number = int($number / scalar(@codec));
			}
			return $string;
		},
		sub {
			my $string = shift;
			my @digits = split(//,$string);
			my %codec; my $n = 0;
			$codec{$_} = $n++ foreach @codec;
			my $number = 0;
			foreach (@digits){
				croak "Bad digit $_" unless defined $codec{$_};
				$number *= scalar(@codec);
				$number += $codec{$_};
			}
			return $number;
		}
	);
}




1;

=pod

=head1 NAME

Compress::AsciiFlate - deflates text, outputs text not binary

=head1 SYNOPSIS

	use Compress::AsciiFlate;
	my $af = new Compress::AsciiFlate;
	my $text = 'some words some words some words';
	$af->deflate($text);
	print $text; # prints: "some words _1 _2 _1 _2"
	$af->inflate($text);
	print $text; # now prints: "some words some words some words"
	
	print $af->olength; # original length: 33
	print $af->dlength; # deflated length: 23
	print $af->difference; # 10
	print $af->ratio; # 0.696969696969697
	print $af->ratio(3); # 0.697
	print $af->percentage; # 69.69
	print $af->percentage(4); # 69.697
	print $af->count; # how many different words: 2
	print join(' ',$af->table); # _1 some _2 words

=head1 DESCRIPTION

Compress::AsciiFlate provides methods to deflate text to a non-binary state.  The resulting
text will retain one copy of each word so that it is still searchable, say, in a database field.
This also means one can store the deflated text in a non-binary field and perform case-
insensitive searches if required.

The core algorithm is very similar to the LZW algorithm.  It works in the following way:

	deflating...
		if this word exists in my table:
			output the code from my table
		else 
			store the word with the next code and output the word
		
	deflating
		if this word is a code that exists in my table:
			output the word from my table
		else
			store the word with the next code and output the word
		
A couple of details... the codes that are output are TEXT.  The codes are 62ary using
0-9, A-Z and a-z as digits.  The codes are prepended by an underscore in the output
to distinguish them from normal words.  If there are normal words in the source that
happen to start with underscores, they too are prepended by another underscore to 
distinguish them from codes.  So if every word in your source was different and started
with an underscore, the "delfated" version would be larger!  

Since the minimum length of a code is 2, the underscore and one digit, words below 
a length of 3 are not encoded.  In fact, the algorithm checks to see that the code is
actually shorter than the word so that, firstly, the output is not larger than the input
and, secondly, codes are not wasted on words of the same size.

=head1 METHODS

=over 4

=item $af = new Compress::AsciiFlate(? lite ?)  OR  $af2 = $af->new(? lite ?)

new() creates a new Compress::AsciiFlate object and returns it.  If the argument
'lite' is also supplied, the object will not store the table it creates during de/inflation.

=item $af->deflate($text|@text)

Deflates the text in the scalar or array supplied.  If an array is supplied, the same table is
use for all of it's elements.  This could mean that most of the table is constructed after the
first element of the array, and you wil save a lot more space.  But it also means that you
must supply the elements in the same order when deflating.  The table created is stored
unless 'lite' has been specified (see new()).

=item $af->inflate($text|@text)

Undoes the work of deflate() on a scalar or array. The table created is stored unless 'lite' 
has been specified (see new()).

=item $original_length = $af->olength

Returns the original length of the text related to the last call to inflate or deflate.

=item $deflated_length = $o->dlength

Returns the deflated length of the text related to the last call to inflate or deflate.

=item $length_difference = $o->difference

Returns the length of the reduction in size related to the last call to inflate or deflate.

=item $compression_ratio = $o->ratio(? $decimal_places ?)

Returns the compression ratio related to the last call to inflate or deflate.
Accepts an optional argument to specify a number of decimal places.  If this argument
is not specified, the number of decimal places is not modified.

=item $compression_percentage = $o->percentage(? $decimal_places ?)

Returns the compression ratio related to the last call to inflate or deflate as a percentage.
Accepts an optional argument to specify a number of decimal places.  If this argument
is not specified, the number of decimal places defaults to 2.

=item $count = $o->count

Returns the number of table entries in the table created by the last call to inflate or deflate, 
which is equivalent to the number of different "words" in the original text.

=item %table = $o->table

Returns the table that was created with the last call to inflate or deflate, unless 'lite' was
specified in new(), in which case no table is stored.

=back

=head1 AUTHOR

Jimi-Carlo Bukowski-Wills <jimi@webu.co.uk>

=head1 SEE ALSO

L<Compress::LZW>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jimi-Carlo Bukowski-Wills

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
