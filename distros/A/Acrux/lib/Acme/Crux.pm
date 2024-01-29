package Acme::Crux;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Crux - The CTK::App of the next generation

=head1 SYNOPSIS

    use Acme::Crux;

=head1 DESCRIPTION

The CTK::App of the next generation

=head2 new

    my $app = Acme::Crux->new(
        ...
    );

=head1 ATTRIBUTES

This class implements the following attributes

=head2 foo

    foo => 'bar',

This attribute sets ...

=head1 METHODS

This class implements the following methods

=head2 again

This method is called immediately after creating the instance and returns it

B<NOTE:> Internal use only for subclasses!

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<CTK>, L<CTK::App>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.01';

use Carp qw/carp croak/;
use Cwd qw/getcwd/;

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

    my $self = bless {
        foo         => $args->{foo} // '',
    }, $class;
    return $self->again(%$args);
}
sub again { shift }

1;

__END__
