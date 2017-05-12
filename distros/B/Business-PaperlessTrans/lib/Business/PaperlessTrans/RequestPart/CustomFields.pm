package Business::PaperlessTrans::RequestPart::CustomFields;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;
extends 'MooseY::RemoteHelper::MessagePart';
with 'MooseX::RemoteHelper::CompositeSerialization';

use MooseX::Types::Common::String qw( NonEmptySimpleStr );

foreach my $i ( 1..30 ) {
	has "field_$i" => (
		remote_name => "Field_$i",
		isa         => NonEmptySimpleStr,
		is          => 'ro',
	);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: CustomFields

__END__

=pod

=head1 NAME

Business::PaperlessTrans::RequestPart::CustomFields - CustomFields

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
