package CPAN::Test::Dummy::MultiPkgVer;
use strict;
use 5.008_001;
our $VERSION = '0.01';

package CPAN::Test::Dummy::MultiPkgVer::Inner;
our $VERSION = '0.10';

package CPAN::Test::Dummy::MultiPkgVer;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

CPAN::Test::Dummy::MultiPkgVer - CPAN Test Dummy that has multiple packages in one file with different versions

=head1 DESCRIPTION

CPAN::Test::Dummy::MultiPkgVer is a test dummy distribution to test MetaCPAN query with multiple versions in one .pm file.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
