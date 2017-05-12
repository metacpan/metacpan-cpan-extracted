package Algorithm::FloodControl::Backend::Cache::Memcached;

use utf8;
use strict;
use warnings;

use Params::Validate qw/:all/;
use base 'Algorithm::FloodControl::Backend';

our ($VERSION) = '$Revision: 2609 $' =~ m{ \$Revision: \s+ (\S+) }mx;

=head2 increment

=cut

sub increment {
    my ( $self )       = @_;
    my $is_added   = $self->storage->add( $self->_tail_name, 0 );    # If it does not exists
    my $last_value = 0;
    if ( ! $is_added ) {
        $last_value = $self->storage->incr( $self->_tail_name );
    }
    $self->storage->set( $self->_item_name($last_value) => time + $self->expires, $self->expires );
    return $last_value;
}

=head2 clear

=cut

sub clear {
    my ($self) = @_;
    return $self->storage->delete( $self->_tail_name );
}

=head2 get_item

=cut

sub get_item {
    my $self = shift;
    my $item = shift;
    return $self->storage->get( $self->_item_name($item) );
}

sub _last_number {
    my $self = shift;
    return $self->storage->get( $self->_tail_name );
}

sub _tail_name {
    my $self = shift;
    return $self->prefix . "_end";
}

sub _item_name {
    my $self = shift;
    my $item = shift;
    return $self->prefix . "_$item";
}

1;


__END__

=head1 NAME

=head1 DESCRIPTION



=head1 BUGS

=head1 NOTES

=head1 AUTHOR

Andrey Kostenko (), <andrey@kostenko.name>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

01.11.2008 14:49:11 MSK

=cut

