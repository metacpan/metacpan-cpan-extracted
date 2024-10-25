package Data::Frame::Rlike;
$Data::Frame::Rlike::VERSION = '0.006003';
use strict;
use warnings;

use Data::Frame::Util qw(dataframe factor logical);

use parent qw(Exporter::Tiny);
our @EXPORT = qw(dataframe factor logical);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Rlike

=head1 VERSION

version 0.006003

=head1 DESCRIPTION

This module is superceded by L<Data::Frame::Util>.

=head1 SEE ALSO

L<Data::Frame::Util>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2022 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
