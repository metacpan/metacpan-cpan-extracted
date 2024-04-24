package CSAF::Type::Publisher;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
extends 'CSAF::Type::Base';

my @CATEGORIES = ('coordinator', 'discoverer', 'other', 'translator', 'user', 'vendor');

has ['name', 'namespace'] => (is => 'rw', required => 1);

has category => (
    is       => 'rw',
    required => 1,
    isa      => sub { Carp::croak 'Unknown document "category"' unless grep(/$_[0]/, @CATEGORIES) }
);

has ['contact_details', 'issuing_authority'] => (is => 'rw');

sub TO_CSAF {

    my $self = shift;

    my $output = {category => $self->category, name => $self->name, namespace => $self->namespace};

    $output->{contact_details}   = $self->contact_details   if ($self->contact_details);
    $output->{issuing_authority} = $self->issuing_authority if ($self->issuing_authority);

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Publisher

=head1 SYNOPSIS

    use CSAF::Type::Publisher;
    my $type = CSAF::Type::Publisher->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Publisher> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->category

=item $type->contact_details

=item $type->issuing_authority

=item $type->name

=item $type->namespace

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

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
