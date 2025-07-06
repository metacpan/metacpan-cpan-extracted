package CSAF::Type::Distribution;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Type::TLP;

use Moo;
extends 'CSAF::Type::Base';

has text => (is => 'rw');

sub tlp {
    my ($self, %params) = @_;
    $self->{tlp} ||= CSAF::Type::TLP->new(%params);
}

sub TO_CSAF {

    my $self = shift;

    my $output = {tlp => $self->tlp};

    $output->{text} = $self->text if ($self->text);

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::Distribution

=head1 SYNOPSIS

    use CSAF::Type::Distribution;
    my $type = CSAF::Type::Distribution->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::Distribution> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->text

=item $type->tlp

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
