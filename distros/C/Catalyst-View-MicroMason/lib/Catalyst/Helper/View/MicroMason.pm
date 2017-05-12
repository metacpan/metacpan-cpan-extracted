package Catalyst::Helper::View::MicroMason;

use strict;

=head1 NAME

Catalyst::Helper::View::MicroMason - Helper for MicroMason Views

=head1 SYNOPSIS

    script/create.pl view MicroMason MicroMason

=head1 DESCRIPTION

Helper for MicroMason Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Jonas Alves, C<jgda@cpan.org>

=head1 MAINTAINER

The Catalyst Core Team L<http://www.catalystframework.org/>

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::MicroMason';

__PACKAGE__->config(
    # -Filters      : to use |h and |u
    # -ExecuteCache : to cache template output
    # -CompileCache : to cache the templates
    Mixins => [qw( -Filters -CompileCache )], 
);
    
=head1 NAME

[% class %] - MicroMason View Component

=head1 SYNOPSIS

In your end action:

    $c->forward('[% class %]');

=head1 DESCRIPTION

A description of how to use your view, if you're deviating from the
default behavior.

=head1 AUTHOR


=head1 LICENSE

=cut

1; # magic true value
