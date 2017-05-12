package Dancer2::Serializer::JSONMaybeXS;

use Moo;
use JSON::MaybeXS ();

our $VERSION = '0.003';

with 'Dancer2::Core::Role::Serializer';

has '+content_type' => ( default => sub {'application/json;charset=UTF-8'} );

sub BUILD {
	warnings::warnif('deprecated',
		'Dancer2::Serializer::JSONMaybeXS is deprecated and should no longer be used');
}

sub serialize {
	my ($self, $entity, $options) = @_;
	
	my $config = $self->config;
	
	foreach (keys %$config) {
		$options->{$_} = $config->{$_} unless exists $options->{$_};
	}
	
	$options->{utf8} = 1 if !defined $options->{utf8};
	
	JSON::MaybeXS->new($options)->encode($entity);
}

sub deserialize {
	my ($self, $entity, $options) = @_;
	
	$options->{utf8} = 1 if !defined $options->{utf8};
	JSON::MaybeXS->new($options)->decode($entity);
}

1;

=head1 NAME

Dancer2::Serializer::JSONMaybeXS - (DEPRECATED) Serializer for handling JSON data

=head1 SYNOPSIS

 use Dancer2;
 set serializer => 'JSONMaybeXS';

=head1 DESCRIPTION

This is a DEPRECATED serializer engine for the L<Dancer2> web framework.
L<Dancer2> now uses L<JSON::MaybeXS> natively in the default
L<Dancer2::Serializer::JSON> (as of version C<0.201000>), so this module is no
longer needed.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Dancer2::Serializer::JSON>
