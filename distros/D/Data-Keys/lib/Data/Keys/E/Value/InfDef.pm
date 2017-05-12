package Data::Keys::E::Value::InfDef;

=head1 NAME

Data::Keys::E::Value::InfDef - inflate/deflate values

=head1 SYNOPSIS

    use Date::Keys;
	my $dk = Data::Keys->new(
		'base_dir'    => '/folder/full/of/json/files',
		'extend_with' => ['Store::Dir', 'Value::InfDef'],
		'inflate'     => sub { JSON::Util->decode($_[0]) },
		'deflate'     => sub { JSON::Util->encode($_[0]) },
	);

	my %data = %{$dk->get('abcd.json')};
	$dk->set('abcd.json', \%data);

=head1 DESCRIPTION

Uses callback to automatically inflate and deflate.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;

=head1 PROPERTIES

=head2 inflate

Callback executed with C<get> value.

=head2 deflate

Callback executed with C<set> value.

=cut

has 'inflate'     => ( isa => 'CodeRef',  is => 'rw', );
has 'deflate'     => ( isa => 'CodeRef',  is => 'rw', );

requires('get', 'set');

around 'get' => sub {
	my $get   = shift;
	my $self  = shift;
	my $key   = shift;

	my $value = $self->$get($key);
	return undef if not defined $value;
	return $self->inflate->($value, $self, $key);
};

around 'set' => sub {
	my $set   = shift;
	my $self  = shift;
	my $key   = shift;
	my $value = shift;
	
    # if value is undef, remove the file
    return $self->$set($key)
		if (not defined $value);
	return $self->$set($key, $self->deflate->($value, $self, $key));
};

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
