package CSAF::Type::Reference;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
extends 'CSAF::Type::Base';

my @CATEGORIES = ('self', 'external');

has summary => (is => 'rw', required => 1);
has url     => (is => 'rw', required => 1);

has category =>
    (is => 'rw', isa => sub { Carp::croak 'Unknown reference "category"' unless grep(/$_[0]/, @CATEGORIES) });

sub TO_CSAF {

    my $self = shift;

    my $output = {summary => $self->summary, url => $self->url};

    $output->{category} = $self->category if ($self->category);

    return $output;

}


1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Reference

=head1 SYNOPSIS

    use CSAF::Type::Reference;
    my $type = CSAF::Type::Reference->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Reference> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->category

=item $type->summary

=item $type->url

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
