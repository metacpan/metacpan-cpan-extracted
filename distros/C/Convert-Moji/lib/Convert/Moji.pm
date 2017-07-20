package Convert::Moji;

use warnings;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/make_regex length_one unambiguous/;

use Carp;

our $VERSION = '0.10';

# Load a converter from a file and return a hash reference containing
# the left/right pairs.

sub load_convertor
{
    my ($file) = @_;
    my $file_in;
    if (! open $file_in, "<:encoding(utf8)", $file) {
	carp "Could not open '$file' for reading: $!";
	return;
    }
    my %converter;
    while (my $line = <$file_in>) {
	chomp $line;
	my ($left, $right) = split /\s+/, $line;
	$converter{$left} = $right;
    }
    close $file_in or croak "Could not close '$file': $!";
    return \%converter;
}

sub length_one
{
    for (@_) {
	return if !/^.$/;
    }
    return 1;
}

sub make_regex
{
    my @inputs = @_;
    # Quote any special characters. We could also do this with join
    # '\E|\Q', but the regexes then become even longer.
    @inputs = map {quotemeta} @inputs;
    if (length_one (@inputs)) {
	return '(['.(join '', @inputs).'])';
    }
    else {
	# Sorting is essential, otherwise shorter characters match before
	# longer ones, causing errors if the shorter character is part of
	# a longer one.
	return '('.join ('|',sort { length($b) <=> length($a) } @inputs).')';
    }
}

sub unambiguous
{
    my ($table) = @_;
    my %inverted;
    for (keys %$table) {
	my $v = $$table{$_};
	return if $inverted{$v};
	$inverted{$v} = $_;
    }
    # Is not ambiguous
    return 1;
}

# If the table is unambiguous, we can use Perl's built-in "reverse"
# function. However, if the table is ambiguous, "reverse" will lose
# information. The method applied here is to make a hash with the
# values of $table as keys and the values are array references.

sub ambiguous_reverse
{
    my ($table) = @_;
    my %inverted;
    for (keys %$table) {
	my $val = $table->{$_};
	push @{$inverted{$val}}, $_;
    }
    for (keys %inverted) {
	@{$inverted{$_}} = sort @{$inverted{$_}};
    }
    return \%inverted;
}

# Callback

sub split_match
{
    my ($erter, $input, $convert_type) = @_;
    if (! $convert_type) {
	$convert_type = 'first';
    }
    my $lhs = $erter->{rhs};
    my $rhs = $erter->{out2in};
    if (!$convert_type || $convert_type eq 'first') {
	$input =~ s/$lhs/$$rhs{$1}->[0]/eg;
	return $input;
    }
    elsif ($convert_type eq 'random') {
	my $size = @$rhs;
	$input =~ s/$lhs/$$rhs{$1}->[int rand $size]/eg;
	return $input;
    }
    elsif ($convert_type eq 'all' || $convert_type eq 'all_joined') {
	my @output = grep {length($_) > 0} (split /$lhs/, $input);
	for my $o (@output) {
	    if ($o =~ /$lhs/) {
		$o = $$rhs{$1};
	    }
	}
	if ($convert_type eq 'all') {
	    return \@output;
	}
        else {
	    return join ('',map {ref($_) eq 'ARRAY' ? "[@$_]" : $_} @output);
	}
    }
    else {
	carp "Unknown convert_type $convert_type";
    }
}

# Attach a table to a Convert::Moji object.

sub table
{
    my ($table, $noinvert) = @_;
    my $erter = {};
    $erter->{type} = "table";
    $erter->{in2out} = $table;
    my @keys = keys %$table;
    my @values = values %$table;
    $erter->{lhs} = make_regex @keys;
    if (!$noinvert) {
	$erter->{unambiguous} = unambiguous($table);
	if ($erter->{unambiguous}) {
	    my %out2in_table = reverse %{$table};
	    $erter->{out2in} = \%out2in_table;
	}
	else {
	    $erter->{out2in} = ambiguous_reverse ($table);
	    @values = keys %{$erter->{out2in}};
	}
	$erter->{rhs} = make_regex @values;
    }
    return $erter;
}

# Make a converter from a tr instruction.

sub tr_erter
{
    my ($lhs, $rhs) = @_;
    my $erter = {};
    $erter->{type} = "tr";
    $erter->{lhs} = $lhs;
    $erter->{rhs} = $rhs;
    return $erter;
}

# Add a code-based converter

sub code
{
    my ($convert, $invert) = @_;
    my $erter = {};
    $erter->{type} = "code";
    $erter->{convert} = $convert;
    $erter->{invert} = $invert;
    return $erter;
}

sub new
{
    my ($package, @conversions) = @_;
    my $conv = {};
    bless $conv;
    $conv->{erter} = [];
    $conv->{erters} = 0;
    for my $c (@conversions) {
	my $noinvert;
	my $erter;
	if ($c->[0] eq "oneway") {
	    shift @$c;
	    $noinvert = 1;
	}
	if ($c->[0] eq "table") {
	    $erter = table ($c->[1], $noinvert);
	}
	elsif ($c->[0] eq "file") {
	    my $file = $c->[1];
	    my $table = Convert::Moji::load_convertor ($file);
	    return if !$table;
	    $erter = table ($table, $noinvert);
	}
	elsif ($c->[0] eq 'tr') {
	    $erter = tr_erter ($c->[1], $c->[2]);
	}
	elsif ($c->[0] eq 'code') {
	    $erter = code ($c->[1], $c->[2]);
	    if (!$c->[2]) {
		$noinvert = 1;
	    }
	}
	my $o = $conv->{erters};
	$conv->{erter}->[$o] = $erter;
	$conv->{noinvert}->[$o] = $noinvert;
	$conv->{erters}++;
    }
    return $conv;
}

sub convert
{
    my ($conv, $input) = @_;
    for (my $i = 0; $i < $conv->{erters}; $i++) {
	my $erter = $conv->{erter}->[$i];
	if ($erter->{type} eq "table") {
	    my $lhs = $erter->{lhs};
	    my $rhs = $erter->{in2out};
	    $input =~ s/$lhs/$$rhs{$1}/g;
	}
        elsif ($erter->{type} eq 'tr') {
	    my $lhs = $erter->{lhs};
	    my $rhs = $erter->{rhs};
	    eval ("\$input =~ tr/$lhs/$rhs/");
	}
        elsif ($erter->{type} eq 'code') {
	    $_ = $input;
	    $input = &{$erter->{convert}};
	}
    }
    return $input;
}

sub invert
{
    my ($conv, $input, $convert_type) = @_;
    for (my $i = $conv->{erters} - 1; $i >= 0; $i--) {
	next if $conv->{noinvert}->[$i];
	my $erter = $conv->{erter}->[$i];
	if ($erter->{type} eq "table") {
	    if ($erter->{unambiguous}) {
		my $lhs = $erter->{rhs};
		my $rhs = $erter->{out2in};
		$input =~ s/$lhs/$$rhs{$1}/g;
	    }
            else {
		$input = split_match ($erter, $input, $convert_type);
	    }
	}
        elsif ($erter->{type} eq 'tr') {
	    my $lhs = $erter->{rhs};
	    my $rhs = $erter->{lhs};
	    eval ("\$input =~ tr/$lhs/$rhs/");
	}
        elsif ($erter->{type} eq 'code') {
	    $_ = $input;
	    $input = &{$erter->{invert}};
	}
    }
    return $input;
}

1;



