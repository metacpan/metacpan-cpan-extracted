package Class::Accessor::Named;

our $VERSION = '0.009';

use warnings;
use strict;
use Carp;


use Sub::Name qw/subname/;
use Hook::LexWrap qw/wrap/;
use UNIVERSAL::require;
# Module implementation here

foreach my $class (qw(Class::Accessor Class::Accessor::Fast)) {
 $class->require();
    foreach my $func (qw(make_accessor make_ro_accessor make_wo_accessor)) {
    wrap $class. "::" . $func, post => sub {  $_[-1] = subname $_[0] . "::" . $_[1] => $_[-1] };
    }
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Class::Accessor::Named - Better profiling output for Class::Accessor


=head1 SYNOPSIS


    perl -MClass::Accessor::Named your_script.pl

  
=head1 DESCRIPTION

L<Class::Accessor> is a great way to automate the tedious task of generating
accessors and mutators. One small drawback is that due to the details of
the implemenetation, you only get one C<__ANON__> entry in profiling output.
That entry contains all your accessors, which can be a real pain if you're attempting to figure out I<which> of your accessors is being called six billion times.
This module is a development aid which uses L<Hook::LexWrap> and L<Sub::Name>
to talk your accessors into identifying themselves. While it shouldn't add much additional runtime overhead (as it acts only Class::Accessor's generator functions), it has not been designed for production deployment, 


=head1 DEPENDENCIES

This module depends on L<Class::Accessor>, L<UNIVERSAL::require>, L<Hook::LexWrap> and L<Sub::Name>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

This module uses L<Hook::Lexwrap> to alter the behaviour of
L<Class::Accessor> and L<Class::Accessor::Fast>. Due to the nature of
L<Hook::LexWrap>, this B<will> skew your profiling a tiny bit. We could
probably do a little more internals diving and eliminate the dependency
and the deficiency. Patches welcome.


Please report any bugs or feature requests to
C<bug-class-accessor-named@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Jesse Vincent  C<< <jesse@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
