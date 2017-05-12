package CPAN::Test::Dummy::Perl5::Deps::UndefModule;

use strict;
use 5.008_005;
our $VERSION = '0.01';

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Test::Dummy::Perl5::Deps::UndefModule - Dummy test module with a dependency on module with undef version

=head1 DESCRIPTION

CPAN::Test::Dummy::Perl5::Deps::UndefModule has a runtime dependency
on L<CPAN::Test::Dummy::Perl5::VersionBump::Undef> whose version is
undef across all release versions.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2016- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CPAN::Test::Dummy::Perl5::VersionBump>

=cut
