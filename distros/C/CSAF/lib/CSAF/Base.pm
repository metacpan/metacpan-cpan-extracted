package CSAF::Base;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use Moo;

around BUILDARGS => sub {

    my ($orig, $class, @args) = @_;

    return {csaf => $args[0]} if @args == 1;
    return $class->$orig(@args);

};

has csaf => (
    is  => 'ro',
    isa => sub {
        Carp::croak 'Must be an instance of "CSAF"' unless ref($_[0]) eq 'CSAF';
    },
    required => 1
);

sub clone {

    my $self  = shift;
    my $clone = {%$self};

    bless $clone, ref $self;
    return $clone;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Base - CSAF base class


=head1 DESCRIPTION

CSAF base class.


=head2 ATTRIBUTES

=over

=item csaf

    $app->csaf(CSAF->new);

=back


=head2 METHODS

=over

=item clone

Clone the object

    my $cloned = $app->clone;

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
