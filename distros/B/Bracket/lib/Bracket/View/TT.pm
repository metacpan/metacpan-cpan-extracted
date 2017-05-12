package Bracket::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    {
        TEMPLATE_EXTENSION => '.tt',
        PRE_PROCESS        => 'lib/config/pre_process.tt',
        WRAPPER            => 'lib/site/wrapper.tt',
    }
);

=head1 NAME

Bracket::View::TT - TT View for Bracket

=head1 DESCRIPTION

TT View for Bracket. 

=head1 AUTHOR

=head1 SEE ALSO

L<Bracket>

Mateu X Hunter

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
