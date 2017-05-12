package Data::AMF::Header;
use Any::Moose;

has name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has must_understand => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has value => (
    is => 'rw',
);

has version => (
    is  => 'rw',
    isa => 'Int',
);

no Any::Moose;

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Data::AMF::Header - AMF message header

=head1 ACCESSORS

=head2 name

=head2 must_understand

=head2 value

=head2 version

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
