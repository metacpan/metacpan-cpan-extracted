package CSAF::Type::Threat;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Util qw(parse_datetime);

use Moo;
extends 'CSAF::Type::Base';


has category    => (is => 'rw', required => 1);
has date        => (is => 'rw', coerce   => \&parse_datetime);
has details     => (is => 'rw', required => 1);
has group_ids   => (is => 'rw', default  => sub { [] });
has product_ids => (is => 'rw', default  => sub { [] });


sub TO_CSAF {

    my $self = shift;

    my $output = {category => $self->category, details => $self->details};

    $output->{date}        = $self->date        if ($self->date);
    $output->{group_ids}   = $self->group_ids   if (@{$self->group_ids});
    $output->{product_ids} = $self->product_ids if (@{$self->product_ids});

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Threat

=head1 SYNOPSIS

    use CSAF::Type::Threat;
    my $type = CSAF::Type::Threat->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Threat> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->category

=item $type->date

=item $type->details

=item $type->group_ids

=item $type->product_ids

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
