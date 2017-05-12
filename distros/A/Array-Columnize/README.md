Columnize - format an Array as a Column-aligned String
============================================================================

In showing long lists, sometimes one would prefer to see the values
arranged and aligned in columns. Some examples include listing methods of
an object, listing debugger commands, or showing a numeric array with data
aligned.

Setup
-----

    use Array::Columnize;

Simple data example 
-------------------

    print columnize(['a','b','c','d'], {displaywidth=>4}), "\n";
produces:

    a  c
    b  d

With numeric data
-----------------

    my $data_ref = [80..120];
    print columnize($data_ref, {ljust = 0}) ;

produces:

    80  83  86  89  92  95   98  101  104  107  110  113  116  119
    81  84  87  90  93  96   99  102  105  108  111  114  117  120
    82  85  88  91  94  97  100  103  106  109  112  115  118

while:

    print columnize($data_ref, {ljust = 0, arrange_vertical = 0}) ;

produces:

     80   81   82   83   84   85   86   87   88   89
     90   91   92   93   94   95   96   97   98   99
    100  101  102  103  104  105  106  107  108  109
    110  111  112  113  114  115  116  117  118  119
    120

And 

    $num_ary = [1..30];
    puts columnize $num_ary, 
    {displaywidth => 18, 
		    {arrange_array => 1, ljust =>0, displaywidth => 70});

produces:

    ( 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15
     16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30)

With String data
----------------

    @ary = qw(bibrons golden madascar leopard mourning suras tokay);
    print columnize(\@ary, {displaywidth => 18});

produces: 

    bibrons   mourning
    golden    suras   
    madascar  tokay   
    leopard 

    puts columnize \@ary, {displaywidth => 18, colsep => ' | '};

produces:

    bibrons  | mourning
    golden   | suras   
    madascar | tokay   
    leopard 


Credits
-------

This is adapted from my [Ruby gem of the same name](https://github.com/rocky/columnize).

Other stuff
-----------

Author:   Rocky Bernstein <rocky@cpan.org>

License:  Copyright (c) 2011, 2012 Rocky Bernstein

Warranty
--------

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
