package CSAF::Type::CWE;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;

use CSAF::Util::CWE qw(get_weakness_name);

extends 'CSAF::Type::Base';

has id   => (is => 'rw', isa => sub { Carp::croak 'Malformed CWE ID' if ($_[0] !~ /^CWE-\d{0,5}$/) });
has name => (is => 'rw');

sub TO_CSAF {

    my $self = shift;

    my $output = {id => $self->id};

    if (my $name = $self->name) {
        $output->{name} = $name;
    }

    if (!$self->name) {
        $output->{name} = get_weakness_name($self->id);
    }

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::CWE

=head1 SYNOPSIS

    use CSAF::Type::CWE;
    my $type = CSAF::Type::CWE->new( );


=head1 DESCRIPTION

Common Weakness Enumeration (CWE).


=head2 METHODS

L<CSAF::Type::CWE> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->id

=item $type->name

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
