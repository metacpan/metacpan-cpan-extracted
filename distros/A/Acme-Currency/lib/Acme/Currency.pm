
package Acme::Currency;

use 5.006;
use strict;
use warnings;

use vars '$VERSION';
$VERSION = '3.01';

use Filter::Simple;

use vars '$String';
$String = '€';

FILTER_ONLY
 code =>
  sub {
     s/\Q$String\E/\$/g;
};

sub import {
   my $class = shift;
   my $str = shift;
   $String = $str if defined $str and $str !~ /^\s*$/;
}


1;
__END__

=head1 NAME

Acme::Currency - There are other currencies beside $$$

=head1 SYNOPSIS

  use Acme::Currency;
  
  €scalar   = "string\n";
  @array    = 1..10;
  €array[2] = 2;
  
  no Acme::Currency;
  
  print $scalar; # prints "string\n";
  
  use Acme::Currency '¥';
  
  ¥money = '¥1.12';
  @time  = ( ¥money, ¥and_I_mean_it );
  # Just kidding or I wouldn't be writing this.

=head1 ABSTRACT

Why confine yourself to using the American Dollar as scalar-context
sigil? There's a few currencies out there and in the age of
internationalization and Unicode, there is no reason not to use them
for our evil purposes.

=head1 DESCRIPTION

This module uses a source filter to replace every occurrance of a given string
in the source code with the $-sigil. That means using the @ in place of the
Yen symbol should yield interesting arrays. (Or none at that.)

By default, using Acme::Currency will use the € character as the scalar sigil.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Filter::Simple>

New versions on CPAN or http://steffen-mueller.net

=head1 AUTHOR

Steffen Mueller, E<lt>currency-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-205, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
