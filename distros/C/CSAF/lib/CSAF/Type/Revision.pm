package CSAF::Type::Revision;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use CSAF::Util qw(parse_datetime);

extends 'CSAF::Type::Base';

has date           => (is => 'rw', required => 1, coerce => \&parse_datetime);
has legacy_version => (is => 'rw');
has number         => (is => 'rw', required => 1);
has summary        => (is => 'rw', required => 1);

sub TO_CSAF {

    my $self = shift;

    my $output = {date => $self->date, number => $self->number, summary => $self->summary};

    $output->{legacy_version} = $self->legacy_version if ($self->legacy_version);

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Revision

=head1 SYNOPSIS

    use CSAF::Type::Revision;
    my $type = CSAF::Type::Revision->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Revision> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->date

=item $type->legacy_version

=item $type->number

=item $type->summary

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
