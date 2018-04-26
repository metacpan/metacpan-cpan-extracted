package CPAN::Test::Dummy::Perl5::UseUnsafeINC::One;

use strict;
use 5.008_005;
our $VERSION = '0.01';

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Test::Dummy::Perl5::UseUnsafeINC::One - x_use_unsafe_inc 1

=head1 SYNOPSIS

Try to install on perl 5.26+ with a real CPAN client.

=head1 DESCRIPTION

CPAN::Test::Dummy::Perl5::UseUnsafeINC::One is a CPAN test distribtion
that sets x_use_unsafe_inc to 1, so that the distribution can load
modules from the current directory (.) without adding it to C<@INC>
path.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2018- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
