package Block::NJH;
use strict;
use warnings;

our $VERSION = '0.002';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Block::NJH - Prevent your tests from running on NJH's broken smokers.

=head1 DESCRIPTION

Nigel Horne is trying to do a good thing by providing a lot of smokers to test
perl modules. I thank him for this effort. However his smokers have long been
broken providing bad results. Many distributions are flooded with invalid
failure results. Attempts have been made to get this fixed, but so far they are
still broken.

This module has code that makes it refuse to install on NJH's machines. As a
result you simply need to list this module in your prereq's to block him from
sending bad test reports for your modules.

=head1 SOURCE

The source code repository for Block-NJH can be found at
F<http://github.com/exodist/Block-NJH/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
