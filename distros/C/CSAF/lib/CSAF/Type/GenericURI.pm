package CSAF::Type::GenericURI;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
extends 'CSAF::Type::Base';

has uri       => (is => 'rw', required => 1);
has namespace => (is => 'rw', required => 1);


sub TO_CSAF {
    my $self = shift;
    return {uri => $self->uri, namespace => $self->namespace};
}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::GenericURI

=head1 SYNOPSIS

    use CSAF::Type::GenericURI;
    my $type = CSAF::Type::GenericURI->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::GenericURI> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->namespace

=item $type->uri

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
