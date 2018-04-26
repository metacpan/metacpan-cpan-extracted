package CPAN::Test::Dummy::Perl5::UseUnsafeINC::Fail;

use strict;
use 5.008_005;
our $VERSION = '0.04';

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Test::Dummy::Perl5::UseUnsafeINC::Fail - Fails when PERL_USE_UNSAFE_INC is set

=head1 SYNOPSIS

Try to install this with a CPAN client that supports C<x_use_unsafe_inc> in Meta.

=head1 DESCRIPTION

CPAN::Test::Dummy::Perl5::UseUnsafeINC::Fail is a CPAN distribution
that has a failing test that fails when PERL_USE_UNSAFE_INC is set to
a wrong value of 1.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2018- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
