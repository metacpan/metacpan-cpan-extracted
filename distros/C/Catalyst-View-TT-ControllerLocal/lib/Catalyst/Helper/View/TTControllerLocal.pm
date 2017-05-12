package Catalyst::Helper::View::TTControllerLocal;

use strict;

=head1 NAME

Catalyst::Helper::View::TTControllerLocal - Helper for TTControllerLocal Views

=head1 SYNOPSIS

    script/create.pl view TT TTControllerLocal



=head1 DESCRIPTION

Helper for TTControllerLocal Views.

=head1 METHODS



=head2 mk_compclass

=cut
sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}





=head1 SEE ALSO

L<Catalyst::View::TT::ControllerLocal>


 
=head1 AUTHOR

Johan Lindstrom, C<johanl@cpan.org>


=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::TT::ControllerLocal';

=head1 NAME

[% class %] - Catalyst Catalyst::View::TT::ControllerLocal View




=head1 SYNOPSIS

See L<[% app %]>



=head1 DESCRIPTION

Catalyst Catalyst::View::TT::ControllerLocal View.



=head1 AUTHOR

[% author %]



=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
