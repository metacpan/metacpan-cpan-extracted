package CPAN::Test::Dummy::Perl5::VersionDeclare;

use strict;
use 5.008_005;
use version; our $VERSION = version->declare('v0.0.1');

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Test::Dummy::Perl5::VersionDeclare - Dummy CPAN distribution with $VERSION delcared with version.pm

=head1 SYNOPSIS

  use CPAN::Test::Dummy::Perl5::VersionDeclare;

=head1 DESCRIPTION

CPAN::Test::Dummy::Perl5::VersionDeclare is a dummy CPAN distribution with:

  use version; our $VERSION = version->declare('v0.0.1');

in its VERSION line.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
