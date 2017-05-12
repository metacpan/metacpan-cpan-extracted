package Alt::common::sense::TOBYINK;

use common::sense;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

1;

__END__

=pod

=encoding utf-8

=for stopwords reimplementation

=head1 NAME

Alt::common::sense::TOBYINK - provides a clean-room reimplementation of common::sense

=head1 VERSION

This is Alt::common::sense::TOBYINK 0.001, but it aims at compatibility
with common::sense 3.73.

=head1 SYNOPSIS

   use common::sense;
   
   # your code goes here

=head1 DESCRIPTION

Importing L<common::sense> is roughly equivalent to:

   use utf8;
   use strict qw(vars subs);
   use feature qw(say state switch);
   use feature qw(unicode_strings current_sub fc evalbytes);
   no feature qw(array_base);
   no warnings;
   use warnings qw(FATAL closed threads internal debugging pack
                   portable prototype inplace io pipe unpack malloc
                   deprecated glob digit printf layer
                   reserved taint closure semicolon);
   no warnings qw(exec newline unopened);

Unfortunately the installation process (and to a lesser extent, the
implementation) for L<common::sense> is fairly crazy.

Alt::common::sense::TOBYINK is an L<Alt> implementation of
L<common::sense>. To use it, continue to C<< use common::sense >>
in your code, but to install it, do:

   cpanm Alt::common::sense::TOBYINK

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Alt-common-sense-TOBYINK>.

=head1 SEE ALSO

L<Alt>, L<common::sense>.

Similar:
L<Modern::Perl>,
L<strictures>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

