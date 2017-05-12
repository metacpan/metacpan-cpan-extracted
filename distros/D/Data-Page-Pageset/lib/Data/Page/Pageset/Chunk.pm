package Data::Page::Pageset::Chunk;
use Carp;
use strict;
use base 'Class::Accessor::Fast';
use overload
	'""'     => sub { shift->as_string };

__PACKAGE__->mk_accessors( qw( first last pages is_current ) );

our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my $class = shift;
	my @array = @_;

	my $self = bless {}, $class;
	$self->first( $array[0] );
	$self->last( $array[-1] );
	$self->pages( $#array + 1 );
	$self->is_current(0);

	return $self;
}

sub middle {
	my $self = shift;
	my $pages = $self->pages;
	$pages++ if $pages % 2;
	return $self->first + $pages / 2;
}

sub as_string {
	my $self = shift;
	my $sep = shift || '-';
	my $string = ( $self->first == $self->last )
		? $self->first
		: join ("$sep", $self->first, $self->last );
	return $string;
}
1;
