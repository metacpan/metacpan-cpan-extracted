package Archive::BagIt::Base;
use strict;
use warnings;
use Moo;
extends "Archive::BagIt";
our $VERSION = '0.098'; # VERSION
# ABSTRACT: deprecated, used for backwards compatibility


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Base - deprecated, used for backwards compatibility

=head1 VERSION

version 0.098

=head1 NAME

Archive::BagIt::Base - only for backwards compatibility needed

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Andreas Romeyke <cpan@andreas.romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Rob Schmidt <rjeschmi@gmail.com>, William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
