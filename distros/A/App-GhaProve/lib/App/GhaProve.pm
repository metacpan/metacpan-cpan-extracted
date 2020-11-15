use 5.006;
use strict;
use warnings;

package App::GhaProve;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::GhaProve - provides gha-prove app

=head1 ENVIRONMENT

C<< GHA_TESTING_COVER=1 >> or C<< GHA_TESTING_COVER=true >>

Turn on Devel::Cover.

C<< GHA_TESTING_MODE=0 >> or C<< GHA_TESTING_MODE=standard >> 

Run test suite without EXTENDED_TESTING.

C<< GHA_TESTING_MODE=1 >> or C<< GHA_TESTING_MODE=extended >> 

Run test suite with EXTENDED_TESTING=1.

C<< GHA_TESTING_MODE=2 >> or C<< GHA_TESTING_MODE=both >> 

Run test suite twice, using each of the above.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=App-GhaProve>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

