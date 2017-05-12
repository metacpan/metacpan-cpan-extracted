package Catalyst::Helper::View::Mason2;
BEGIN {
  $Catalyst::Helper::View::Mason2::VERSION = '0.03';
}
use strict;
use warnings;

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

1;




=pod

=head1 NAME

Catalyst::Helper::View::Mason2 - Helper for Mason 2.x Views

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    script/create.pl view Mason2 Mason2

=head1 DESCRIPTION

Helper for Mason 2.x Views.

=head1 METHODS

=head2 mk_compclass

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__

__compclass__
package [% class %];

use strict;
use warnings;
use base qw(Catalyst::View::Mason2);

__PACKAGE__->config();
