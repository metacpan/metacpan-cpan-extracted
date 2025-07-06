package CSAF::Type::Tracking;

use 5.010001;
use strict;
use warnings;
use utf8;
use version;

use Moo;
use CSAF::Type::Generator;
use CSAF::Type::RevisionHistory;
use CSAF::Util qw(parse_datetime);

extends 'CSAF::Type::Base';

has ['current_release_date', 'initial_release_date'] => (is => 'rw', required => 1, coerce => \&parse_datetime);

has ['id', 'status'] => (is => 'rw', required => 1);

has version => (is => 'rw', required => 1, coerce => sub {"$_[0]"});

has aliases => (is => 'rw', default => sub { [] });

sub generator {
    my ($self, %params) = @_;
    $self->{generator} ||= CSAF::Type::Generator->new(%params);
}

sub revision_history {
    my $self = shift;
    $self->{revision_history} ||= CSAF::Type::RevisionHistory->new(@_);
}

sub TO_CSAF {

    my $self = shift;

    my $output = {
        id                   => $self->id,
        current_release_date => $self->current_release_date,
        initial_release_date => $self->initial_release_date,
        revision_history     => $self->revision_history->TO_CSAF,
        status               => $self->status,
        version              => $self->version,
    };

    $output->{aliases}   = $self->aliases if (@{$self->aliases});
    $output->{generator} = $self->generator;

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Tracking

=head1 SYNOPSIS

    use CSAF::Type::Tracking;
    my $type = CSAF::Type::Tracking->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Tracking> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->aliases

=item $type->current_release_date

=item $type->generator

=item $type->id

=item $type->initial_release_date

=item $type->revision_history

=item $type->status

=item $type->version

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
