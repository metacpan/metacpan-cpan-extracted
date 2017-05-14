use strict;
use warnings;
# ABSTRACT: Converts given English text into Pig Latin
# Delon Newman <delon.newman@gmail.com> Copyright (C) 2007

package App::PigLatin;
use Exporter 'import';
our @EXPORT_OK = qw(translate);

sub translate {
	my $text = shift;
	my $dict = shift || create_dictionary($$text);

	for (keys %$dict) { $$text =~ s/\b$_\b/$dict->{$_}/g }

	$$text;
}

sub create_dictionary {
	my $text = shift;

	$text =~ s/[\,\.\:\;\-\?\!\%\*\#\^\(\)\@\$\+="\[\]{}\\\|\'\/]/ /g;
	my @words = split /[\s\n]+/, $text;
	my %dict; 

	for (@words) {
		next if /\d/;
		next unless $_;
		next if $dict{$_};

		if (starts_with_vowl($_)) { 
			$dict{$_} = $_;
		} else {
			# FIXME: This should exclude y in 
			# cases where it is a vowl
			m/([b-df-hj-np-tv-z]+)/i;
			$dict{$_} = $_ . lc($1);
			$dict{$_} =~ s/$1//i;
		}

		if (/[A-Z]{2,}/) { $dict{$_} .= 'AY' }
		else			 { $dict{$_} .= 'ay' }
		$dict{$_} = ucfirst($dict{$_}) if (/^[A-Z]/);
	}
	
	\%dict;
}

sub _starts_with {
	my $word  = shift;
	my @letters = @_;
	map { return 1 if ($word =~ /^$_/i) } @letters;
	
	0;
}

sub starts_with_vowl {
	my $word  = shift;
	my @vowls = qw{a e i o u};
	
	_starts_with($word, @vowls);
}

sub starts_with_consonant {
	my $word = shift;
	my @consonants = qw{b c d f g h j k l m n p q r s t v w x y z};
	
	_starts_with($word, @consonants);
}

1;
