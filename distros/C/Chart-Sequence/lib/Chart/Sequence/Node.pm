package Chart::Sequence::Node;

$VERSION = 0.000_1;

=head1 NAME

Chart::Sequence::Node - What messages are sent to/from

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Chart::Sequence::Object ();
@ISA = qw( Chart::Sequence::Object );

use strict;


sub new {
    my $proto = shift;

    if ( @_ == 1 ) {
        @_ = ( Name => @_ );
    }

    return $proto->SUPER::new( @_ );
}


__PACKAGE__->make_methods(qw(
    number
    _layout_info
));

=head2 METHODS

=over

=item name

Gets/sets a node's name

=item number

Each node is assigned a number when added to a sequence

=cut

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
