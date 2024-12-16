use warnings;
use 5.020;
use true;
use experimental qw( signatures );

package Data::Section::Pluggable::Role::FormatContentPlugin 0.04 {

    # ABSTRACT: Plugin role for Data::Section::Writer

    use Role::Tiny;
    requires 'extensions';
    requires 'format_content';

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Pluggable::Role::FormatContentPlugin - Plugin role for Data::Section::Writer

=head1 VERSION

version 0.04

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
