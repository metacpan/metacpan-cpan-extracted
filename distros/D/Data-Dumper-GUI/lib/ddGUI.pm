package ddGUI;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$ddGUI::Window::AUTHORITY = 'cpan:TOBYINK';
	$ddGUI::Window::VERSION   = '0.006';
}

use parent qw( Data::Dumper::GUI );
*EXPORT = *Data::Dumper::GUI::EXPORT;
*Dumper = *Data::Dumper::GUI::Dumper;

1;

__END__

=pod

=encoding utf-8

=for stopwords ddGUI

=head1 NAME

ddGUI - a shorter name for Data::Dumper::GUI

=head1 SYNOPSIS

   use ddGUI;
   
   print Dumper(@variables);

=head1 DESCRIPTION

This is just an empty subclass of L<Data::Dumper::GUI>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Data-Dumper-GUI>.

=head1 SEE ALSO

L<Data::Dumper::GUI>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

