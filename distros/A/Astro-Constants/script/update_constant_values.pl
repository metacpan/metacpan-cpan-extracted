#!/usr/bin/perl -w
#
# Checks the online sources for the values of the constants
# Boyd Duffee, Mar 2020
#
# hard coded to run from top directory and uses only data/PhysicalConstants.xml

use strict;
use autodie;
use Modern::Perl;
use XML::LibXML;
use LWP::Simple;
use List::Util qw/shuffle/;
use HTML::Parser;

#die "Usage: $0 infile outfile" unless @ARGV == 1;

my $TESTING = 0;
my $ONLINE = 1;
my $SLEEP = 0;

my ($n, @values_parsed, @uncertainties_parsed, );
my ($td_flag, $font_flag, $text_flag, $uncertainty_flag) = 0;

my $xml = XML::LibXML->load_xml(location => 'data/PhysicalConstants.xml');
my $nist_parser = HTML::Parser->new(
	start_h => [\&start_nist, "self, tagname, attr"],
	end_h => [\&end_nist, "tagname, attr"],
	text_h => [\&text, "text"],
);

configure_parsers();

for my $constant ( $xml->getElementsByTagName('PhysicalConstant') ) {
	my ($long_name, $old_value, ) = undef;

	for my $name ( $constant->getChildrenByTagName('name') ) {
		$long_name = $name->textContent() if $name->getAttribute('type') eq 'long';
	}

	my $description = $constant->getChildrenByTagName('description')->shift()->textContent();
	for my $value ( $constant->getChildrenByTagName('value') ) {
		if ( $value->hasAttribute('system') ) {
			$old_value = $value->textContent() if $value->getAttribute('system') eq 'MKS';
		}
		else {
			$old_value = $value->textContent();
			next;
		}
		$old_value =~ tr/_//;
	}

	my $precision = $constant->getChildrenByTagName('uncertainty')->shift();
	my $precision_type = $precision->getAttribute('type');
	$precision = $precision->textContent();
	my $source = $constant->getChildrenByTagName('source')->shift();
	my $source_url = $source->getAttribute('url');

	say <<CONST;
$long_name\t$old_value\t$precision\t$precision_type
$description
$source_url
CONST
	#next unless $source_url =~ /physics\.nist\.gov/;
	next if $source_url =~ /wikipedia|jupiterfact/;

	print "Fetch page? [Ynq] ";
	my $ans = <STDIN>;
	next if $ans =~ /n/i;
	last if $ans =~ /q/i;

	my ($new_value, $new_uncertainty) = get_constant_value($source);
	if ( ! defined $new_value ) {
		warn "Couldn't get value for $long_name from $source_url";
	}
	elsif ( $new_value == $old_value ) {
			say "No change";
	}
	else {
    	$new_uncertainty //= '';
		print <<"E";
UPDATE: $old_value \t($precision)
    TO: $new_value \t($new_uncertainty)
E
	}
	last if $TESTING && $TESTING <= ++$n;
	sleep $SLEEP if $SLEEP;
}


exit;

####

sub get_constant_value {
	my ($source) = @_; 
	(@values_parsed, @uncertainties_parsed ) = ();
	
	my $url = $source->getAttribute('url');
	my $selector = $source->getAttribute('selector');
	if ( $url =~ /\.pdf$/ ) {
		warn "Can't scrape PDF documents yet\n";
		return;
	}
	say "Getting $url";
	return 0 unless $ONLINE;
	my $content = get($url);
	return unless $content;

	if ( $url =~ /oeis\.org/ ) {
		my ($value) = $content =~ /\%e \s \w+ \s (\d+\.?\d*)/x;
		print /(\%e.+)/ if /\%e/ && $TESTING;
		return $value;
	}
	elsif ( $url =~ /nist\.gov/ ) {
		$nist_parser->parse($content);
		return extract_value( @values_parsed ),
			extract_value( @uncertainties_parsed );
	}
	else {
		print $content;
	}
}

sub start_nist {
	my ($self, $tag, $attr) = @_;
	$td_flag = 1 if $tag eq 'td';
	$font_flag = 1 if $tag eq 'font';
	return unless $td_flag && $font_flag;
	return if $font_flag && ! $attr->{color} || $attr->{color} ne 'red';
	$text_flag = 1;
}

sub end_nist {
	my ($tag) = @_;
	if ($tag eq 'tr') {
		$uncertainty_flag = 0;
	}
	return unless $tag eq 'td' || $tag eq 'font';
	$td_flag = 0 if $tag eq 'font';
	$font_flag = 0 if $tag eq 'font';
	$text_flag = 0;
}

sub text {
	my ($text, $attr) = @_;
	if ($text_flag) {
		push @values_parsed, $text;
		say "I found $text" if $TESTING;
	}
	if ($uncertainty_flag) {
		push @uncertainties_parsed, $text;
	}
	elsif (@values_parsed && $text =~ /Relative standard uncertainty/) {
		$uncertainty_flag = 1;
	}
	if ($uncertainty_flag) {
		say "TG: $text";
	}
}

sub configure_parsers {
	$nist_parser->ignore_tags('tt', 'b', 'sup');
}

sub extract_value {
	my ($digits, $power, $units) = grep /\w/, @_;

	$power //= ''; $units //= '';
	$digits =~ s/(?:&nbsp;|\s+)//g;
	$power =~ s/(?:&nbsp;|\s+)//g;
	$units =~ s/(?:&nbsp;|\s+)//g;
	print "From $digits, $power, $units, " if $TESTING;
	$digits =~ s/\.{3,}//;	# remove ellipsis pertaining to irrational values

	if ( $digits =~ /exact/ || $power =~ /exact/ || $units =~ /exact/ ) {
		say "Returning 0" if $TESTING;
		say "exact value";
		return 0;
	}
	elsif ( $digits =~ s/x10// ) {
		my $scinotation = join 'e', $digits, $power;
		say "Extracting $scinotation" if $TESTING;
		return $scinotation;
	}
	else {
		say "Extracting $digits" if $TESTING;
		$digits =~ s/^(-?\d+\.?\d*).*/$1/;	# removed units for non-scinotation
		return $digits;
	}
}
