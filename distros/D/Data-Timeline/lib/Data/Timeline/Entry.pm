use 5.008;
use strict;
use warnings;

package Data::Timeline::Entry;
our $VERSION = '1.100860';
# ABSTRACT: A time line entry
use parent qw(Class::Accessor::Complex Class::Accessor::Constructor);
__PACKAGE__
    ->mk_constructor
    ->mk_scalar_accessors(qw(timestamp type description));
1;


__END__
=pod

=head1 NAME

Data::Timeline::Entry - A time line entry

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    my $entry = Data::Timeline::Entry->new(
        timestamp   => '...',
        type        => '...',
        description => '...',
    );

=head1 DESCRIPTION

This class represents a time line entry. An entry has a timestamp, a type and
a description. The timestamp needs to be a L<DateTime> object. The type is
freely definable, but you need to be consistent. If you want to display
multiple time lines side-by-side you probably need to define the entry type
for each column. The description is a string that says what this entry is
about.

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

