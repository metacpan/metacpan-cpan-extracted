package Business::PaperlessTrans::Request::Role::Money;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;
use MooseX::Types::Common::Numeric  qw( PositiveOrZeroNum );
use MooseX::Types::Locale::Currency qw( CurrencyCode      );

has amount => (
	remote_name => 'Amount',
	isa         => PositiveOrZeroNum,
	is          => 'ro',
	required    => 1,
);

has currency => (
	remote_name => 'Currency',
	isa         => CurrencyCode,
	is          => 'ro',
	required    => 1,
);

1;
# ABSTRACT: Money Attributes

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Request::Role::Money - Money Attributes

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
