package Data::Frame::Class;

# ABSTRACT: For creating classes in Data::Frame

use Data::Frame::Setup ();

sub import {
    my ( $class, @tags ) = @_;
    Data::Frame::Setup->_import( scalar(caller), qw(:class), @tags );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Class - For creating classes in Data::Frame

=head1 VERSION

version 0.0045

=head1 SYNOPSIS

    use Data::Frame::Class;

=head1 DESCRIPTION

C<use Data::Frame::Class ...;> is equivalent of 

    use Data::Frame::Setup qw(:class), ...;

=head1 SEE ALSO

L<Data::Frame::Setup>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
