package Catalyst::Controller::RateLimit::Queue;

use utf8;
use strict;
use warnings;

# $Id: Queue.pm 17 2008-10-30 14:34:47Z gugu $
# $Source$
# $HeadURL: file:///var/svn/cps/trunk/lib/Catalyst/Controller/RateLimit/Queue.pm $

our ($VERSION) = '$Revision: 17 $' =~ m{ \$Revision: \s+ (\S+) }mx;

use Params::Validate qw/:all/;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/cache expires prefix/);

sub new {
    my ($class, @params )  = @_;
    my %params = validate @params,
      {
        cache   => { type => OBJECT },
        expires => { regex => qr/^\d+$/mx },
        prefix  => { type  => SCALAR }
      };
    return $class->SUPER::new( \%params );
}

sub append {
    my ( $self, $data )       = @_;
    my $is_added   = $self->cache->add( $self->_tail_name, 0 );    # If it does not exists
    my $last_value = 0;
    if ( ! $is_added ) {
        $last_value = $self->cache->incr( $self->_tail_name );
    }
    $self->cache->set( $self->_item_name($last_value) => $data, $self->expires );
    return $data;
}

sub clear {
    my ($self) = @_;
    return $self->cache->delete( $self->_tail_name );
}

sub size {
    my $self   = shift;
    my $size   = 0;
    my $number = $self->_last_number;
    if ( ! defined $number ) {
        return $size;
    }
    while ( defined $self->get_item($number) ) {
        $size++;
        $number--;
    }
    return $size;
}

sub get_item {
    my $self = shift;
    my $item = shift;
    return $self->cache->get( $self->_item_name($item) );
}

sub _last_number {
    my $self = shift;
    return $self->cache->get( $self->_tail_name );
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

Catalyst::Controller::RateLimit::Queue

=head1 DESCRIPTION

Internal Module. Do not use it directly.

=head1 METHODS

=head2 new( cache => $cache, prefix => 'prefix', expires => 60 )

=head2 append( $data )

=head2 clear()

=head2 get_item( $number )

=head2 size()

=head1 BUGS

There are no bugs in this excellent module, only features (: 

=head1 NOTES

=head1 AUTHOR

Andrey Kostenko <andrey@kostenko.name>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

21.10.2008 19:29:45 MSD

=cut

