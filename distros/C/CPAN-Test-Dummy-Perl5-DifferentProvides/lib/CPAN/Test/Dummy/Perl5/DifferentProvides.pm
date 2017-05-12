package CPAN::Test::Dummy::Perl5::DifferentProvides;

use strict;
use 5.008_005;
our $VERSION = '0.01';

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Test::Dummy::Perl5::DifferentProvides - Dist with non-matching provides

=head1 DESCRIPTION

This distribution has a valid C<provides> entry in META.json and
META.yml with mis-matching entries with the C<.pm> files.

=over 4

=item *

CPAN::Test::Dummy::Perl5::DifferentProvides::A exists in the file package, but does not in C<provides>.

=item *

CPAN::Test::Dummy::Perl5::DifferentProvides::B exists in C<provides>, but the file does not exist.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2015- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CPAN::Test::Dummy::Perl5::EmptyProvides>

=cut
