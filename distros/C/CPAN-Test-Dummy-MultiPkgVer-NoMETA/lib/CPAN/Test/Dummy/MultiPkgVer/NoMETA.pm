package CPAN::Test::Dummy::MultiPkgVer::NoMETA;

use strict;
use 5.008_005;
our $VERSION = '0.01';

package CPAN::Test::Dummy::MultiPkgVer::NoMETA::Inner;
our $VERSION = '0.02';

package CPAN::Test::Dummy::MultiPkgVer::NoMETA;

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Test::Dummy::MultiPkgVer::NoMETA - CPAN Test Dummy that has multiple packages in one file with different versions

=head1 SYNOPSIS

  use CPAN::Test::Dummy::MultiPkgVer::NoMETA;

=head1 DESCRIPTION

Test dummy distribution that has one .pm file with multiple packages in it, without C<provides> in META.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CPAN::Test::Dummy::MultiPkgVer>

=cut
