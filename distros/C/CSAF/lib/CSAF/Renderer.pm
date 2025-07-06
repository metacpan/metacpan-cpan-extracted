package CSAF::Renderer;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;

use CSAF::Renderer::JSON;
use CSAF::Renderer::HTML;

use Moo;
extends 'CSAF::Renderer::Base';

sub render {

    my ($self, %options) = @_;

    my $format = delete $options{'format'} || 'json';

    my $renderer = {
        json => sub { CSAF::Renderer::JSON->new($self->csaf) },
        html => sub { CSAF::Renderer::HTML->new($self->csaf) },
    };

    if (defined $renderer->{lc $format}) {
        return $renderer->{lc $format}->()->render(%options);
    }

    Carp::croak 'Unknown render format';

}

1;


__END__

=encoding utf-8

=head1 NAME

CSAF::Renderer - CSAF Renderer Front-end

=head1 SYNOPSIS

    use CSAF::Renderer;
    my $renderer = CSAF::Renderer->new( csaf => $csaf );

    my $html = $renderer->render(format => 'html');


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Renderer> inherits all methods from L<CSAF::Renderer::Base> and implements the following new ones.

=over

=item $renderer->render ( [%options] )

Render a CSAF document.

Available options:

=over

=item format

Specify the render format (B<json> default, B<html>).

=back

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

