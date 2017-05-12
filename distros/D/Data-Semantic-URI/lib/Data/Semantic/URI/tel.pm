use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::tel;
our $VERSION = '1.100850';
# ABSTRACT: Semantic data class for tel URIs
use parent qw(Data::Semantic::URI);
use constant REGEXP_KEYS => qw(URI tel);
1;


__END__
=pod

=for stopwords tel

=head1 NAME

Data::Semantic::URI::tel - Semantic data class for tel URIs

=head1 VERSION

version 1.100850

=head1 SYNOPSIS

    my $obj = Data::Semantic::URI::tel->new;
    if ($obj->is_valid('...')) {
       #  ...
    }

=head1 WARNING

This class is unfinished. I've released the distribution nevertheless because
it already contains other usable classes and so I can get CPAN tester results
early.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Semantic-URI>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Semantic-URI/>.

The development version lives at
L<http://github.com/hanekomu/Data-Semantic-URI/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

