package CLI::Numbers::Hack;

use 5.006;
use strict;
use warnings;

=head1 NAME

CLI::Numbers::Hack - commands for handling a bunch of numbers for `finding denominator', `N-th min/max', `cumulative sum' and so on.
=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';


=head1 SYNOPSIS

PROVIDED COMMAND LINE INTERFACE programs : 
  
  1. nums -- an expansion of the Unix/Linux command `seq'. 
  2. cumsum -- shows the cumulative sum for a sequence of numbers separated by line ends.
  3. minmax -- shows the N-th minimums and N-th maximums of a number sequence.
  4. denomfind -- helps to find the common denominator from bunch of decimals. Useful to find N of a questionnaire results.
  4. rounding -- outputs the rounded numbers. (The name of this command would change in the future.. )
  5. zeropad -- outputs the zero-padded numbers.
  6. meanvar -- shows the mean (average) and the variance of a sequence of numbers.
  7. quantile -- shows the quantile values.

  All programs provides help-manual that is availble such as by "cumsum --help". 
  If you want to see only "switch options", do "cumsum --help opt(ions)". 
  Sorry the most part of the manual is written only in Japanese.

  Some commands are immature in user interface (such as `denomfind') (the the version number is low)
  but the author just want to provide these commands above for some good usage. 


=head1 LICENSE AND COPYRIGHT

Copyright 2018 "Toshiyuki Shimono".

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of CLI::Numbers::Hack
