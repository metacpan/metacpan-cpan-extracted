package CSAF::Type::Acknowledgment;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
extends 'CSAF::Type::Base';

has names        => (is => 'rw', isa => \&_check_isa_array, default => sub { [] });
has urls         => (is => 'rw', isa => \&_check_isa_array, default => sub { [] });
has summary      => (is => 'rw');
has organization => (is => 'rw');

sub _check_isa_array {
    Carp::croak 'must be an array' if (ref $_[0] ne 'ARRAY');
}

sub TO_CSAF {

    my $self = shift;

    my $output = {};

    $output->{summary}      = $self->summary      if ($self->summary);
    $output->{organization} = $self->organization if ($self->organization);

    $output->{names} = $self->names if (@{$self->names});
    $output->{urls}  = $self->urls  if (@{$self->urls});

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Acknowledgment

=head1 SYNOPSIS

    use CSAF::Type::Acknowledgment;
    my $type = CSAF::Type::Acknowledgment->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Acknowledgment> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->names

=item $type->organization

=item $type->summary

=item $type->urls

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
