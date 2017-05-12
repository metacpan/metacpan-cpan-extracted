use 5.008;
use strict;
use warnings;

package Data::Timeline::Formatter;
our $VERSION = '1.100860';
# ABSTRACT: Base class for time line formatters
use parent qw(Class::Accessor::Complex Class::Accessor::Constructor);
__PACKAGE__
    ->mk_constructor
    ->mk_abstract_accessors(qw(format));
1;


__END__
=pod

=head1 NAME

Data::Timeline::Formatter - Base class for time line formatters

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    package Data::Timeline::My::Formatter;
    use base 'Data::Timeline::Formatter';

    sub format {
        # ...
    }

=head1 DESCRIPTION

This class is a base class for formatters. Subclasses need to implement the
format() method, which takes a time line object and outputs it in some way.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Timeline>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Timeline/>.

The development version lives at
L<http://github.com/hanekomu/Data-Timeline/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

