NAME
====

Arithmetic::PaperAndPencil - simulating paper and pencil techniques for basic arithmetic operations

SYNOPSIS
========

```
use Arithmetic::PaperAndPencil;

my $paper_sheet = Arithmetic::PaperAndPencil->new;
my $x = Arithmetic::PaperAndPencil::Number->new(value => '355000000');
my $y = Arithmetic::PaperAndPencil::Number->new(value => '113');
$paper_sheet->division(dividend => $x, divisor => $y);

my $html = $paper_sheet->html(lang => 'fr', silent => 0, level => 3);
open my $f, '>', 'division.html';
print $f $html;
close $f;

$paper_sheet = Arithmetic::PaperAndPencil->new; # emptying previous content
my $dead = Arithmetic::PaperAndPencil::Number->new(value => 'DEAD', radix => 16);
my $beef = Arithmetic::PaperAndPencil::Number->new(value => 'BEEF', radix => 16);
$paper_sheet->addition($dead, $beef);

$html = $paper_sheet->html(lang => 'fr', silent => 0, level => 3);
open $f, '>', 'addition.html';
print $f $html;
close $f;
```

The first HTML file ends with

```
 355000000|113
 0160     |---
  0470    |3141592
   0180   |
    0670  |
     1050 |
      0330|
       104|
```

and the second one with

```
  DEAD
  BEEF
 -----
 19D9C

```

DESCRIPTION
===========

Arithmetic::PaperAndPencil  is a  module which  allows simulating  the
paper  and  pencil  techniques  for  basic  arithmetic  operations  on
integers: addition, subtraction, multiplication and division, but also
square root extraction and conversion from a radix to another.

Actually, this module is the porting of a similarly-named Raku module.

PATCHES WELCOME
===============

When rendering an operation as HTML, the module displays spoken French
sentences. If you  know the equivalent sentences  in another language,
you can contact  me to add the other language  to the distribution, or
you can even send me a patch. Thank you in advance.

INSTALLATION
============

To install this module, first check that the Perl version in use is 5.38
or higher. If necessary, install a recent version with perlbrew or similar.

Then download  the repository  from Github  or from  CPAN and  run the
following commands:

```
  perl Makefile.PL
  make
  make test
  make install
```

The first non-core prerequisite is
[`Test::Exception`](https://metacpan.org/search?q=test%3A%3Aexception),
which is needed only if you run the extended tests in directory `xt`.

The other non-core prerequisites are
[Test::CheckManifest](https://metacpan.org/pod/Test::CheckManifest),
[Test::Pod::Coverage](https://metacpan.org/pod/Test::Pod::Coverage),
[Pod::Coverage](https://metacpan.org/pod/Pod::Coverage)
and [Test::Pod](Test::Pod)
which are used only if you run the `RELEASE_TESTING` tests.

SUPPORT AND DOCUMENTATION
=========================

After installing, you can find documentation for this module with the
perldoc command.

```
  perldoc Arithmetic::PaperAndPencil
```

You can also look for information at:

* [RT](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Arithmetic-PaperAndPencil),
CPAN's request tracker (report bugs here)

* [CPAN Ratings](https://cpanratings.perl.org/d/Arithmetic-PaperAndPencil)

* [Search CPAN](https://metacpan.org/release/Arithmetic-PaperAndPencil)

You  can find  some  additional documentation  about the  mathematical
topics in the repository for the Raku module:

* [English version](https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-en.md)

* [French version](https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-fr.md)

You can find also some  documentation about the Corinna implementation
in the present repository:

* [English version](https://github.com/jforget/perl-Arithmetic-PaperAndPencil/blob/master/doc/documentation.en.md)

* [French version](https://github.com/jforget/perl-Arithmetic-PaperAndPencil/blob/master/doc/documentation.fr.md)

AUTHOR
======

Jean Forget <J2N-FORGET at orange dot fr>

DEDICATION
==========

This module is dedicated to my  primary school teachers, who taught me
the basics of arithmetics, and even  some advanced features, and to my
secondary  school math  teachers, who  taught me  other advanced  math
concepts and features.

COPYRIGHT AND LICENSE
=====================

Copyright 2024 Jean Forget

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

