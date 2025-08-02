package App::Greple::PwBlock;

use strict;
use warnings;
use utf8;

use List::Util qw(sum reduce);
use Data::Dumper;
use Getopt::EX::Colormap qw(colorize);
use Getopt::EX::Config qw(config);

sub new {
    my $class = shift;
    my $obj = bless {
	orig   => "",
	masked => "",
	id     => {},
	pw     => {},
	matrix => {},
    }, $class;

    $obj->parse(shift) if @_;

    $obj;
}

sub id {
    my $obj = shift;
    my $label = shift;
    exists $obj->{id}{$label} ? $obj->{id}{$label} : undef;
}

sub pw {
    my $obj = shift;
    my $label = shift;
    exists $obj->{pw}{$label} ? $obj->{pw}{$label} : undef;
}

sub cell {
    my $obj = shift;
    my($col, $row) = @_;
    if (length $col > 1) {
	($col, $row) = split //, $col;
    }
    return undef if not defined $obj->{matrix}{$col};
    $obj->matrix->{$col}{$row};
}

sub any {
    my $obj = shift;
    my $label = shift;
    $obj->id($label) // $obj->pw($label) // $obj->cell(uc $label);
}

sub orig   { $_[0]->{orig}   }
sub masked { $_[0]->{masked} }
sub matrix { $_[0]->{matrix} }


sub parse {
    my $obj = shift;
    $obj->{orig} = $obj->{masked} = shift;
    $obj->parse_matrix if config('parse_matrix');
    $obj->parse_pw if config('parse_pw');
    $obj->parse_id if config('parse_id');
    $obj;
}
    
sub make_pattern {
    my $opt = ref $_[0] eq 'HASH' ? shift : {};
    use English;
    local $LIST_SEPARATOR = '|';
    my @match = @_;
    my @except = qw(INPUT);
    push @except, @{$opt->{IGNORE}} if $opt->{IGNORE};
    qr{ ^\s*+ (?!@except) .*? (?:@match)\w*[:=]? [\ \t]* \K ( .* ) }mxi;
}

# Getopt::EX::Config support
our $config = Getopt::EX::Config->new(
    parse_matrix    => 1,
    parse_id        => 1,
    parse_pw        => 1,
    id_keys         => join(' ', 
        qw(ID ACCOUNT USER CODE NUMBER URL),
        qw(ユーザ アカウント コード 番号),
        ),
    id_chars        => '[\w\.\-\@]',
    id_color        => 'K/455',
    id_label_color  => 'S;C/555',
    pw_keys         => join(' ',
        qw(PASS PIN),
        qw(パス 暗証),
        ),
    pw_chars        => '\S',
    pw_color        => 'K/545',
    pw_label_color  => 'S;M/555',
    pw_blackout     => 1,
);

sub parse_id {
    shift->parse_xx(
	hash => 'id',
	pattern => make_pattern(split /\s+/, config('id_keys')),
	chars => config('id_chars'),
	start_label => '0',
	label_format => '[%s]',
	color => config('id_color'),
	label_color => config('id_label_color'),
	blackout => 0,
	);
}		   

sub parse_pw {
    shift->parse_xx(
	hash => 'pw',
	pattern => make_pattern({IGNORE => [ 'URL' ]}, split /\s+/, config('pw_keys')),
	chars => config('pw_chars'),
	start_label => 'a',
	label_format => '[%s]',
	color => config('pw_color'),
	label_color => config('pw_label_color'),
	blackout => config('pw_blackout'),
	);
}		   

sub parse_xx {
    my $obj = shift;
    my %opt = @_;
    my %hash;
    $obj->{$opt{hash}} = \%hash;

    my $label_id = $opt{start_label};
    my $chars = qr/$opt{chars}/;
    $obj->{masked} =~ s{ (?!.*\e) $opt{pattern} }{
	local $_ = $1;
	s{ (?| ()    (https?://[^\s{}|\\\^\[\]\`]+)	# URL
	     | ([(]) ([^)]+)(\))	# ( text )
	     | ()    ($chars+) )	#   text
	}{
	    my($pre, $match, $post) = ($1, $2, $3 // '');
	    $hash{$label_id} = $match;
	    my $label = sprintf $opt{label_format}, $label_id++;
	    if ($opt{blackout}) {
		if ($opt{blackout} > 1) {
		    $match = 'x' x $opt{blackout};
		} else {
		    my $char = $opt{blackout_char} // 'x';
		    $match =~ s/./$char/g;
		}
	    }
	    $label = colorize($opt{label_color}, $label) if $opt{label_color};
	    $match = colorize($opt{color}, $match) if $opt{color};
	    $pre . $label . $match . $post;
	}xge;
	$_;
    }igex;

    $obj;
}

sub parse_matrix {
    my $obj = shift;
    my @area = guess_matrix_area($obj->{masked});
    my %matrix;
    $obj->{matrix} = \%matrix;

    for my $area (@area) {
	my $start = $area->[0];
	my $len = $area->[1] - $start;
	my $matrix = substr($obj->{masked}, $start, $len);
	$matrix =~ s{ \b (?<index>\d) \W+ \K (?<chars>.*) $}{
	    my $index = $+{index};
	    my $chars = $+{chars};
	    my $col = 'A';
	    $chars =~ s{(\S+)}{
		my $cell = $1;
		$matrix{$col}{$index} = $cell;
		$col++;
		$cell =~ s/./x/g;
		colorize('D;R', $cell);
	    }ge;
	    $chars;
	}xmge;
	substr($obj->{masked}, $start, $len) = $matrix;
	last; # process 1st segment only
    }

    $obj;
}
    
sub guess_matrix_area {
    my $text   = shift;
    my @text   = $text =~ /(.*\n|.+\z)/g;
    my @length = map { length } @text;
    my @words  = map { [ /(\w+)/g ] } @text;
    my @one    = map { [ grep { length == 1 } @$_ ] } @words;
    my @two    = map { [ grep { length == 2 } @$_ ] } @words;
    my @more   = map { [ grep { length >= 3 } @$_ ] } @words;
    my $series = 5;

    map  { [ sum(@length[0 .. $_->[0]]) - $length[$->[0]],
	     sum(@length[0 .. $_->[1]]) ] }
    sort { $b->[1] - $b->[0] <=> $a->[1] - $a->[0] }
    grep { $_->[0] + $series - 1 <= $_->[1] }
    map  { defined $_ ? ref $_ ? @$_ : [$_, $_] : () }
    reduce {
	my $r = ref $a eq 'ARRAY' ? $a : [ [$a, $a] ];
	my $l = $r->[-1][1];
	if ($l + 1 == $b
	    and @{$one[$l]} == @{$one[$b]}
	    and @{$two[$l]} == @{$two[$b]}
	    ) {
	    $r->[-1][1] = $b;
	} else {
	    push @$r, [ $b, $b ];
	}
	$r;
    }
    grep { $one[$_][0] =~ /\d/ }
    grep { @{$one[$_]} >= 10 || @{$two[$_]} >= 5 and @{$more[$_]} == 0 }
    0 .. $#text;
}

1;

=encoding utf-8

=head1 NAME

App::Greple::PwBlock - Password and ID information block parser for greple

=head1 SYNOPSIS

    use App::Greple::PwBlock;
    
    # Create a new PwBlock object
    my $pb = App::Greple::PwBlock->new($text);
    
    # Access parsed information
    my $id = $pb->id('0');      # Get ID by label
    my $pw = $pb->pw('a');      # Get password by label
    my $cell = $pb->cell('A', 0); # Get matrix cell value
    
    # Configuration
    use App::Greple::PwBlock qw(config);
    config('id_keys', 'LOGIN EMAIL USER ACCOUNT');
    config('pw_blackout', 0);

=head1 DESCRIPTION

B<App::Greple::PwBlock> is a specialized parser for extracting and managing 
password and ID information from text blocks. It provides intelligent 
pattern recognition for common credential formats and includes support 
for random number matrices used by banking systems.

The module uses L<Getopt::EX::Config> for centralized parameter management,
allowing configuration of parsing behavior, display colors, and keyword 
patterns.

=head1 METHODS

=over 4

=item B<new>([I<text>])

Creates a new PwBlock object. If I<text> is provided, it will be parsed
immediately.

    my $pb = App::Greple::PwBlock->new($credential_text);

=item B<parse>(I<text>)

Parses the given text to extract ID, password, and matrix information.
This method is called automatically by B<new> if text is provided.

    $pb->parse($text);

=item B<id>(I<label>)

Returns the ID value associated with the given label. Labels are assigned
automatically during parsing (e.g., '0', '1', '2', ...).

    my $username = $pb->id('0');

=item B<pw>(I<label>)

Returns the password value associated with the given label. Labels are 
assigned automatically during parsing (e.g., 'a', 'b', 'c', ...).

    my $password = $pb->pw('a');

=item B<cell>(I<column>, I<row>)

Returns the value from a matrix cell at the specified column and row.
Useful for banking security matrices.

    my $value = $pb->cell('E', 3);  # Column E, Row 3

=item B<any>(I<label>)

Returns any value (ID, password, or matrix cell) associated with the label.
This is a convenient method that checks all types.

    my $value = $pb->any('a');

=item B<orig>()

Returns the original unparsed text.

=item B<masked>()

Returns the text with passwords masked according to the B<pw_blackout> setting.

=item B<matrix>()

Returns a hash reference containing the parsed matrix data.

=back

=head1 CONFIGURATION

This module uses L<Getopt::EX::Config> for parameter management. Configuration
can be accessed using the B<config> function:

    use App::Greple::PwBlock qw(config);

=head2 Available Parameters

=over 4

=item B<parse_matrix> (boolean, default: 1)

Enable or disable matrix parsing.

=item B<parse_id> (boolean, default: 1)

Enable or disable ID field parsing.

=item B<parse_pw> (boolean, default: 1)

Enable or disable password field parsing.

=item B<id_keys> (string, default: "ID ACCOUNT USER CODE NUMBER URL ユーザ アカウント コード 番号")

Space-separated list of keywords that identify ID fields.

=item B<id_chars> (string, default: "[\w\.\-\@]")

Regular expression character class for valid ID characters.

=item B<id_color> (string, default: "K/455")

Color specification for ID values in output.

=item B<id_label_color> (string, default: "S;C/555")

Color specification for ID labels in output.

=item B<pw_keys> (string, default: "PASS PIN パス 暗証")

Space-separated list of keywords that identify password fields.

=item B<pw_chars> (string, default: "\S")

Regular expression character class for valid password characters.

=item B<pw_color> (string, default: "K/545")

Color specification for password values in output.

=item B<pw_label_color> (string, default: "S;M/555")

Color specification for password labels in output.

=item B<pw_blackout> (boolean, default: 1)

When enabled, passwords are masked in the output for security.

=back

=head2 Configuration Examples

    # Customize ID keywords
    config('id_keys', 'LOGIN EMAIL USERNAME ACCOUNT');
    
    # Disable password masking
    config('pw_blackout', 0);
    
    # Add custom password keywords
    config('pw_keys', 'PASS PASSWORD PIN SECRET TOKEN');

=head1 MATRIX SUPPORT

The module can automatically detect and parse random number matrices 
commonly used by banking systems for security:

    | A B C D E F G H I J
  --+--------------------
  0 | Y W 0 B 8 P 4 C Z H
  1 | M 0 6 I K U C 8 6 Z
  2 | 7 N R E Y 1 9 3 G 5

Access matrix values using:

    my $value = $pb->cell('E', 3);  # Gets the value at column E, row 3

=head1 SEE ALSO

L<App::Greple::pw>, L<Getopt::EX::Config>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2017-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
