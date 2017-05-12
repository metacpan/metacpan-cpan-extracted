[![Build Status](https://travis-ci.org/zoncoen/Array-PrintCols-EastAsian.png?branch=master)](https://travis-ci.org/zoncoen/Array-PrintCols-EastAsian) [![Coverage Status](https://coveralls.io/repos/zoncoen/Array-PrintCols-EastAsian/badge.png?branch=master)](https://coveralls.io/r/zoncoen/Array-PrintCols-EastAsian?branch=master)
# NAME

Array::PrintCols::EastAsian - Print or format space-fill array elements with aligning vertically with multibyte characters.

# VERSION

This document describes Array::PrintCols::EastAsian version 0.07.

# SYNOPSIS

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

# DESCRIPTION

Array::PrintCols::EastAsian is yet another module which can print and format space-fill array elements with aligning vertically.

# INTERFACE

## `format_cols($array_ref : ArrayRef, $options : HashRef)`

This is a method getting an array which has space-fill elements.

Valid options for this method are as follows:

`align => $align : Str (left|center|right)`

Set text alignment. Align option should be left, center, or right. Default value is left.

## `print_cols($array_ref : ArrayRef, $options : HashRef)`

This is a method printing array elements with aligning vertically.

Valid options for this method are as follows:

`gap => $gap : Int`

Set the number or space between array elements. Gap option should be a integer greater than or equal 1. Default value is 0.

`column => $column : Int`

Set the number of column. Column option should be a integer greater than 0.

`width => $width : Int`

Set width for printing. Width option should be a integer greater than 0.

`align => $align : Str`

Set text alignment. Align option should be left, center, or right. Default value is left.

`encode => $encode : Str`

Set text encoding for printing. Encode option should be a valid encoding. Default value is utf-8.

## `pretty_print_cols($array_ref : ArrayRef, $options : HashRef)`

This is a method printing array elements with aligning vertically and fitting the window width like Linux "ls" command.

Valid options for this method are as follows:

`gap => $gap : Int`

Set the number or space between array elements. Gap option should be a integer greater than or equal 1. Default value is 1.

`align => $align : Str`

Set text alignment. Align option should be left, center, or right. Default value is left.

`encode => $encode : Str`

Set text encoding for printing. Encode option should be a valid encoding. Default value is utf-8.

# DEPENDENCIES

Perl 5.10 or later.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the GitHub issues  at [https://github.com/zoncoen/Array-PrintCols-EastAsian/issues](https://github.com/zoncoen/Array-PrintCols-EastAsian/issues).

# SEE ALSO

[Array::PrintCols](https://metacpan.org/pod/Array::PrintCols)

[Term::ReadKey](https://metacpan.org/pod/Term::ReadKey)

[Text::VisualWidth::PP](https://metacpan.org/pod/Text::VisualWidth::PP)

# LICENSE AND COPYRIGHT

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

zoncoen <zoncoen@gmail.com>
