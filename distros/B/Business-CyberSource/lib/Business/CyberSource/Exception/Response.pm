package Business::CyberSource::Exception::Response;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
use namespace::autoclean;
use MooseX::Aliases;
extends 'Business::CyberSource::Exception';
with 'Business::CyberSource::Response::Role::Base',
	'Business::CyberSource::Role::Traceable' => {
	-excludes => [qw( trace )]
};

sub _build_message {
	my $self = shift;
	return $self->decision . ' ' . $self->reason_text;
}

has '+value' => (
	default => sub { return $_[0]->reason_code },
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: response thrown as an object because of ERROR state

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Exception::Response - response thrown as an object because of ERROR state

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Try::Tiny;
	use Safe::Isa;

	try { ... }
	catch {
		if ( $_->$_does('Business::CyberSource::Response::Role::Base) )
			# log reason_text
		}
	};

=head1 DESCRIPTION

do not catch this object, should Moose provide an exception role at some
point, we will remove this class in favor of applying the role to
L<Business::CyberSource::Response> instead catch
L<Business::CyberSource::Response::Role::Base>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
