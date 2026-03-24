# Common-CodingTools

## DESCRIPTION

Common programming tools with friendly constants and functions that should have been included with Perl in the first place.

## SYNOPSIS

```
 ## Global Tag
 # :all

 ## Constants Tags
 # :contants
 # :boolean
 # :toggle
 # :activity
 # :health
 # :expiration
 # :cleanliness
 # :emotion
 # :success
 # :want
 # :pi

 ## Functions Tags
 # :functions
 # :file
 # :trim
 # :schwartz
 # :weird

 use Common::CodingTools qw(:all);
```
## AUTHOR

Richard Kelsch <rich@rk-internet.com>

## VERSION

Version 2.03 (March 23, 2026)

## INSTALLATION

To install this module, run the following commands:

```bash
           perl Makefile.PL
           make
           make test
    [sudo] make install
```
# BRIEF DOCUMENTATION

The following is only a subset of the actual documentation.  Use ```perldoc Common::CodingTools``` or ```man Common::CodingTools``` for the full documentation. 

## IMPORT CONSTANTS

### Positive Constants

* ACTIVE
* CLEAN
* EXPIRED
* HAPPY
* HEALTHY
* ON
* SUCCESS
* SUCCEEDED
* SUCCESSFUL
* TRUE
* WANTED

### Negative Constants

* ANGRY
* DIRTY
* FAIL
* FAILED
* FAILURE
* FALSE
* INACTIVE
* NOTEXPIRED
* OFF
* SAD
* UNHEALTHY
* UNWANTED

## INPORT FUNCTIONS

* center
* ltrim
* schwartzian_sort
* slurp_file
* rtrim
* tfirst
* trim
* uc_lc

## INPORT TAGS

### Constants

* :all
* :activity
* :boolean
* :cleanliness
* :constants
* :emotion
* :expiration
* :functions
* :health
* :pi
* :success
* :toggle
* :want

### Functions

* :file
* :schwartz
* :string
* :trim
* :weird

## FUNCTIONS

* **slurp_file**

  Reads in a text file and returns the contents of that file as a single string.  It returns undef if the file is not found.
  ```
  my $string = slurp_file('/file/name');
  ```
* **ltrim**

  Removes any spaces at the beginning of a string (the left side).
  ```
  my $result = ltrim($string);
  ```
* **rtrim**

  Removes any spaces at the end of a string (the right side).
  ```
  my $result = rtrim($string);
  ```
* **trim**

  Removes any spaces at the beginning and ending of a string.
  ```
  my $result = trim($string);
  ```
* **center**

  Centers a string, padding with leading spaces, in the middle of the given width.
  ```
  my $result = center($string,80); # Centers text for an 80 column display
  ```
* **uc_lc**

  Changes text to annoying "leet-speak".
  ```
  my $result = uc_lc($string, 1); # Second parameter determines whether to start with upper or lower-case.  You can leave out that parameter for a random pick.
  ```
* **schwartzian_sort**

  Sorts a rather large list with the very fast Swartzian sort.  It returns either an array or a reference to an array, depending on how it was called.
  ```
  my @sorted = schwartzian_sort(@unsorted); # Schwaertian sort is heavily stack intensive, but it's fast.
  ```
  or
  ```
  my $sorted = schwartzian_sort(\@unsorted);
  ```
* **tfirst**

  Change text into "title ready" text with each word capitalized.
  ```
  my $title = tfirst($string);
  ```
  For example:

  ```
  my $before = 'this is a string I want to turn into a title-ready string';

  my $title = tfirst($before);

  # $title is now 'This Is a String I Want To Turn Into a Title-ready String'
  ```

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

 perldoc Common::CodingTools

You can also look for information at:

* CPAN Ratings:  [http://cpanratings.perl.org/d/Common-CodingTools](http://cpanratings.perl.org/d/Common-CodingTools)

* Search CPAN:  [http://search.cpan.org/dist/Common-CodingTools/](https://metacpan.org/dist/Common-CodingTools)

* GitHub:  [https://github.com/richcsst](https://github.com/richcsst)

## COPYRIGHT

Copyright (C) 2016-2026 Richard Kelsch,

All Rights Reserved

## LICENSES

### Perl Artistic License 2.0

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

### MIT License

The **tfirst** routine only, is under the MIT license as "TitleCase".

http://www.opensource.org/licenses/mit-license.php
