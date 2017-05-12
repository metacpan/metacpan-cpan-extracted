package Business::PaperlessTrans::Response::ProcessCard;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;
extends 'Business::PaperlessTrans::Response';

with qw(
	Business::PaperlessTrans::Response::Role::Authorization
	Business::PaperlessTrans::Response::Role::IsApproved
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Process Card Response

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Response::ProcessCard - Process Card Response

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
