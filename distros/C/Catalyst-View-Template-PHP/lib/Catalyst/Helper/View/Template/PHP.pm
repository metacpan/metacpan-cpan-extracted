package Catalyst::Helper::View::Template::PHP;

use strict;
use warnings;

our $VERSION = '0.04';

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

1;

=head1 NAME

Catalyst::Helper::View::PHP - Helper for Catalyst Template::PHP view

=head1 SYNOPSIS

    script/myapp_create.pl view PHP Template::PHP

=head1 DESCRIPTION

Creates and initializes a view class in your L<Catalyst> application
that subclasses L<Catalyst::View::Template::PHP>, allowing you to 
use PHP as a templating system.

=head1 METHODS

=head2 mk_compclass

=head1 SEE ALSO

L<Catalyst::View::Template::PHP>, L<Catalyst::View::Helper>, L<PHP>

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or
modify it under the same terms as perl itself.

=cut

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;
use Moose;
extends 'Catalyst::View::Template::PHP';

# sub preprocess {
#     my ($self, $c, $params) = @_;
#     ...
#     return $params;
# }

# sub postprocess {
#     my ($self, $c, $output) = @_;
#     ...
#     return $output;
# }

=head1 NAME

[% class %] - Template::PHP View Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

View component for using PHP as a templating system
within L<[% app %]>.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut
