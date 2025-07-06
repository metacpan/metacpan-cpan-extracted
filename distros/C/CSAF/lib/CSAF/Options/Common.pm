package CSAF::Options::Common;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
with 'CSAF::Util::Options';

use constant TRUE  => !!1;
use constant FALSE => !!0;

has publisher_category        => (is => 'rw');
has publisher_name            => (is => 'rw');
has publisher_namespace       => (is => 'rw');
has publisher_contact_details => (is => 'rw');

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Options::Common - CSAF::Common configurator

=head1 SYNOPSIS

    use CSAF::Options::Common;
    my $options = CSAF::Options::Common->new( );

    $options->configure(

    );


=head1 DESCRIPTION

L<CSAF::Options::Common> is a configurator of L<CSAF>.


=head2 METHODS

L<CSAF::Options::Common> inherits all methods from L<CSAF::Util::Options>.


=head2 ATTRIBUTES

=over

=item publisher_category

=item publisher_name

=item publisher_namespace

=item publisher_contact_details


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
