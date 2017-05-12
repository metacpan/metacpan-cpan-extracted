# Format an Array as an Array of String aligned in columns.
#
# == Summary
# Format a list into a single string with embedded newlines.
# On printing the string the columns are aligned.
#
#  See documentation for Columnize.columnize below.
#
# == License
#
# Columnize is copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
#
# All rights reserved.  You can redistribute and/or modify it under
# the same terms as Perl.
#
# Adapted from the routine of the same name in Ruby.

package Array::Columnize;
use strict;
use Exporter;
use warnings;
use lib '..';

use Array::Columnize::columnize;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw/ Exporter /;
@EXPORT = qw(columnize);

# Add or remove  _01 when we want testing.
use version; $VERSION = '1.04';

unless (caller) {
    # Demo code
    print "This is version: $Array::Columnize::VERSION\n";
    print columnize([1,2,3,4], {displaywidth=>4}), "\n";
    my $data_ref = [80..120];
    print columnize($data_ref, {ljust => 0}) ;
    print columnize($data_ref, {ljust => 0, arrange_vertical => 0}) ;
    my @ary = qw(bibrons golden madascar leopard mourning suras tokay);
    print columnize(\@ary, {displaywidth => 18});
}

'Just another Perl module';
__END__
=encoding utf8

=head1 NAME

Array::Columnize - arrange list data in columns.

=head1 SYNOPSIS

    use Array::Columnize;
    print columnize($array_ref, $optional_hash_or_hash_ref);

=head1 DESCRIPTION

In showing long lists, sometimes one would prefer to see the values
arranged and aligned in columns. Some examples include listing methods of
an object, listing debugger commands, or showing a numeric array with data
aligned.

=head2 OPTIONS

=over

=item displaywidth

the line display width used in calculating how to align columns

=item colfmt

What format specifier to use in sprintf to stringify list entries. The
default is none.

=item colsep

String to insert between columns. The default is two spaces, oe space
just wasn't enough.

the column separator

=item lineprefix

=item linesuffix

=item termadjust

=item arrange_array

=item ladjust

whether to left justify text instead of right justify. The default is true

=back

=head1 EXAMPLES

=head2 Simple data example

    print columnize(['a','b','c','d'], {displaywidth=>4});

produces:

    a  c
    b  d

=head2 With numeric data

    my $array_ref = [80..120];
    print columnize($array_ref, {ljust => 0}) ;

produces:

    80  83  86  89  92  95   98  101  104  107  110  113  116  119
    81  84  87  90  93  96   99  102  105  108  111  114  117  120
    82  85  88  91  94  97  100  103  106  109  112  115  118

while:

    print columnize($array_ref, {ljust => 0, arrange_vertical => 0}) ;

produces:

     80   81   82   83   84   85   86   87   88   89
     90   91   92   93   94   95   96   97   98   99
    100  101  102  103  104  105  106  107  108  109
    110  111  112  113  114  115  116  117  118  119
    120

And

    my $array_ref = [1..30];
    print columnize($array_ref,
		    {arrange_array => 1, ljust => 0, displaywidth => 70});

produces:

   ( 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30)

=head2 With String data

    @ary = qw(bibrons golden madascar leopard mourning suras tokay);
    print columnize(\@ary, {displaywidth => 18});

produces:

    bibrons   mourning
    golden    suras
    madascar  tokay
    leopard

    print columnize \@ary, {displaywidth => 18, colsep => ' | '};

produces:

    bibrons  | mourning
    golden   | suras
    madascar | tokay
    leopard

=head1 AUTHOR

Rocky Bernstein, C<< rocky@cpan.org >>

=head1 BUGS

Please report any bugs or feature requests through the web interface
at L<https://github.com/rocky/Perl-Array-Columnize/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Array::Columnize

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Array-Columnize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Array-Columnize>

=item * Github request tracker

L<https://github.com/rocky/Perl-Array-Columnize/issues>

=item * Search CPAN

L<http://search.cpan.org/dist/Array-Columnize>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011, 2012 Rocky Bernstein.

=head2 LICENSE

Same terms as Perl.

=cut
