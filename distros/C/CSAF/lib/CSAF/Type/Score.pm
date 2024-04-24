package CSAF::Type::Score;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use CSAF::Type::CVSS3;
use CSAF::Type::CVSS2;

extends 'CSAF::Type::Base';

has products => (is => 'rw', default => sub { [] });
has cvss_v2  => (is => 'ro', coerce  => sub { CSAF::Type::CVSS2->new(shift) });
has cvss_v3  => (is => 'ro', coerce  => sub { CSAF::Type::CVSS3->new(shift) });

sub TO_CSAF {

    my $self = shift;

    my $output = {};

    $output->{products} = $self->products if (@{$self->products});

    $output->{cvss_v3} = $self->cvss_v3 if (defined $self->{cvss_v3});
    $output->{cvss_v2} = $self->cvss_v2 if (defined $self->{cvss_v2});

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Score

=head1 SYNOPSIS

    use CSAF::Type::Score;
    my $type = CSAF::Type::Score->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Score> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->cvss_v2

=item $type->cvss_v3

=item $type->products

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
