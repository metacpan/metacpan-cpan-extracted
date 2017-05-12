package Array::PrintCols::EastAsian;
use 5.010;
use strict;
use warnings;
use utf8;

use Carp;
use Encode;
use Data::Validator;
use Term::ReadKey;
use Text::VisualWidth::PP;
$Text::VisualWidth::PP::EastAsian = 1;
use parent qw/ Exporter /;

our $VERSION = '0.07';

our @EXPORT    = qw/ format_cols print_cols pretty_print_cols /;
our @EXPORT_OK = qw/ _max _min _validate _align /;

sub _max {
    my @array = @_;
    my $max   = shift @array;
    foreach (@array) {
        if ( $max < $_ ) { $max = $_; }
    }
    return $max;
}

sub _min {
    my @array = @_;
    my $min   = shift @array;
    foreach (@array) {
        if ( $min > $_ ) { $min = $_; }
    }
    return $min;
}

sub _validate {
    my ( $array, $options ) = @_;
    if ( !defined $options ) { $options = {}; }
    state $rules = Data::Validator->new(
        array  => { isa => 'ArrayRef' },
        gap    => { isa => 'Int', default => 0 },
        column => { isa => 'Int', optional => 1 },
        width  => { isa => 'Int', optional => 1 },
        align  => { isa => 'Str', default => 'left' },
        encode => { isa => 'Str', default => 'utf-8' },
    )->with('Sequenced');
    my $args = $rules->validate( $array, $options );
    if ( $args->{gap} < 0 ) { croak 'Gap option should be a integer greater than or equal 1.'; }
    if ( exists $args->{column} && $args->{column} <= 0 ) { croak 'Column option should be a integer greater than 0.'; }
    if ( exists $args->{width}  && $args->{width} <= 0 )  { croak 'Width option should be a integer greater than 0.'; }
    if ( !( $args->{align} =~ m/^(left|center|right)$/i ) ) {
        croak 'Align option should be left, center, or right.';
    }
    return $args;
}

sub _align {
    my $args    = shift;
    my @length  = map { Text::VisualWidth::PP::width $_ } @{ $args->{array} };
    my $max_len = _max(@length);
    my ( @formatted_array, $space );
    for ( 0 .. $#{ $args->{array} } ) {
        $space = $max_len - $length[$_];
        if ( $args->{align} =~ m/^left$/i )  { push @formatted_array, $args->{array}->[$_] . q{ } x $space; }
        if ( $args->{align} =~ m/^right$/i ) { push @formatted_array, q{ } x $space . $args->{array}->[$_]; }
        if ( $args->{align} =~ m/^center$/i ) {
            my $half_space = int $space / 2;
            push @formatted_array, q{ } x $half_space . $args->{array}->[$_] . q{ } x ( $space - $half_space );
        }
    }
    return \@formatted_array;
}

sub format_cols {
    my ( $array, $options ) = @_;
    my $args = _validate( $array, $options );
    return _align($args);
}

sub print_cols {
    my ( $array, $options ) = @_;
    my $args            = _validate( $array, $options );
    my $formatted_array = _align($args);
    my $gap             = $args->{gap};
    my $encode          = $args->{encode};
    my $column;
    if ( exists $args->{column} ) { $column = $args->{column}; }
    if ( exists $args->{width} ) {
        my $element_width = Text::VisualWidth::PP::width $formatted_array->[0];
        $column = _max( 1, int 1 + ( $args->{width} - $element_width ) / ( $element_width + $gap ) );
        if ( exists $args->{column} ) { $column = _min( $args->{column}, $column ); }
    }
    if ( !$column ) { $column = $#{$formatted_array} + 1; }

    my ( $str, $encoded_str ) = q{};
    for ( 0 .. $#{$formatted_array} ) {
        if ( $_ % $column ) {
            $str = $str . q{ } x $gap;
        }
        else {
            if ($str) { $str = $str . "\n"; }
        }
        $str = $str . $formatted_array->[$_];
    }
    $str = $str . "\n";
    $encoded_str = encode $encode, $str;
    print $encoded_str;
    return;
}

sub pretty_print_cols {
    my ( $array, $options ) = @_;
    my $gap    = $options->{gap}    // 1;
    my $align  = $options->{align}  // 'left';
    my $encode = $options->{encode} // 'utf-8';
    my $terminal_width;
    if ( $^O =~ /Win32/i ) {
        $terminal_width = ( GetTerminalSize <STDOUT> )[0];
    }
    else {
        $terminal_width = (GetTerminalSize)[0];
    }
    if ( $terminal_width =~ /^\d+$/ && $terminal_width != 0 ) {
        print_cols( $array, { 'gap' => $gap, 'width' => $terminal_width, 'align' => $align, 'encode' => $encode } );
    }
    else {
        print_cols( $array, { 'gap' => $gap, 'align' => $align, 'encode' => $encode } );
    }
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Array::PrintCols::EastAsian - Print or format space-fill array elements with aligning vertically with multibyte characters.

=head1 VERSION

This document describes Array::PrintCols::EastAsian version 0.07.

=head1 SYNOPSIS

    use Array::PrintCols::EastAsian;

    my @motorcycles = (
        'GSX1300Rハヤブサ', 'ZZR1400', 'CBR1100XXスーパーブラックバード',
        'K1300S', 'GSX-R1000', 'ニンジャZX-10R', 'CBR1000RR', 'S1000RR'
    );

    # get an array which has space-fill elements
    my @formatted_array = @{ format_cols( \@motorcycles ) };

    # print array elements with aligning vertically
    print_cols( \@motorcycles );

    # print array elements with aligning vertically and fitting the window width like Linux "ls" command
    pretty_print_cols( \@motorcycles );

=head1 DESCRIPTION

Array::PrintCols::EastAsian is yet another module which can print and format space-fill array elements with aligning vertically.

=head1 INTERFACE

=head2 C<< format_cols($array_ref : ArrayRef, $options : HashRef) >>

This is a method getting an array which has space-fill elements.

Valid options for this method are as follows:

C<< align => $align : Str (left|center|right) >>

Set text alignment. Align option should be left, center, or right. Default value is left.

=head2 C<< print_cols($array_ref : ArrayRef, $options : HashRef) >>

This is a method printing array elements with aligning vertically.

Valid options for this method are as follows:

C<< gap => $gap : Int >>

Set the number or space between array elements. Gap option should be a integer greater than or equal 1. Default value is 0.

C<< column => $column : Int >>

Set the number of column. Column option should be a integer greater than 0.

C<< width => $width : Int >>

Set width for printing. Width option should be a integer greater than 0.

C<< align => $align : Str >>

Set text alignment. Align option should be left, center, or right. Default value is left.

C<< encode => $encode : Str >>

Set text encoding for printing. Encode option should be a valid encoding. Default value is utf-8.

=head2 C<< pretty_print_cols($array_ref : ArrayRef, $options : HashRef) >>

This is a method printing array elements with aligning vertically and fitting the window width like Linux "ls" command.

Valid options for this method are as follows:

C<< gap => $gap : Int >>

Set the number or space between array elements. Gap option should be a integer greater than or equal 1. Default value is 1.

C<< align => $align : Str >>

Set text alignment. Align option should be left, center, or right. Default value is left.

C<< encode => $encode : Str >>

Set text encoding for printing. Encode option should be a valid encoding. Default value is utf-8.

=head1 DEPENDENCIES

Perl 5.10 or later.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the GitHub issues  at L<https://github.com/zoncoen/Array-PrintCols-EastAsian/issues>.

=head1 SEE ALSO

L<Array::PrintCols>

L<Term::ReadKey>

L<Text::VisualWidth::PP>

=head1 LICENSE AND COPYRIGHT

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

zoncoen E<lt>zoncoen@gmail.comE<gt>

=cut

