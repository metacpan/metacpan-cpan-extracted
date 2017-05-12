
package Business::BR::Biz;

use 5;
use strict;
use warnings;

our $VERSION = '0.00_09';

1;

__END__

=head1 NAME

Business::BR::Biz - DEPRECATED (was: Modules for Brazilian business-related subjects)

=head1 SYNOPSIS

  use Business::BR::Biz; # does nothing, it is here because of POD and $VERSION

=head1 DESCRIPTION

This module was a placeholder for the overview of the 'biz-br' 
distribution, now called 'Business-BR-Ids'. Soon we will get rid
of it, by moving the introductory documentation contained here 
to Business::BR::Ids.

=head2 EXPORT

None by default. 

=head1 TESTING CORRECTNESS

Among the functionalities to be made available in this distribution,
we'll have tests for correctness of typical identification numbers
and codes.

I<To be correct> will mean here to satisfy certain easily computed
rules. For example, a CPF number is correct if it is 11-digits-long
and satisfy two check equations which validate the check digits.

The modules C<Business::BR::*> will provide subroutines C<test_*>
for testing the correctness of such concepts. 

To be I<correct> does not mean that an identification number or code
had been I<verified> to stand for some real entry, like an actual 
Brazilian taxpayer citizen in the case of CPF. This would require
access to government databases which may or may not be available
in a public basis. And besides, to I<verify> something
will not be I<easily computed> in general, implying access to
databases and applying specialized rules.

Here we'll be trying to stick to a consistent terminology
and 'correct' will always be used for validity against syntactical
forms and shallow semantics. In turn, 'verified' will be used 
for telling if an entity really makes sense in the real world. 
This convention is purely arbitrary and for the sake of
being formal in some way. Terms like 'test', 'verify', 'check',
'validate', 'correct', 'valid' are often used interchangeably
in colloquial prose.

=head1 EXAMPLES

As a rule, the documentation and tests choose correct
identification codes which are verified to be invalid by the time
of the distribution update. That is, in Business::BR::CPF,
the mentioned correct CPF number '390.533.447-05' is correct,
but doesn't actually exist in government databases.


=head1 SEE ALSO

As you might have guessed, this is not the first Perl distribution
to approach this kind of functionality. Take a look at

  http://search.cpan.org/search?module=Brasil::Checar::CPF
  http://search.cpan.org/search?module=Brasil::Checar::CGC
  http://search.cpan.org/~mamawe/Algorithm-CheckDigits-0.38/CheckDigits/M11_004.pm

If you want to find out about the namespace L<Business::BR>,
follow the link.

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-BR-Ids

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
