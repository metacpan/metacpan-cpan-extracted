package Catalyst::Helper::View::PDF::Reuse;

use strict;

=head1 NAME

Catalyst::Helper::View::PDF::Reuse - Helper for PDF::Reuse Views

=head1 SYNOPSIS

To create a PDF::Reuse view in your Catalyst application, enter the following command:

 script/myapp_create.pl view PDF::Reuse PDF::Reuse

Then in MyApp.pm, add a configuration item for the View::PDF::Reuse include path:

 __PACKAGE__->config('View::PDF::Reuse' => {
   INCLUDE_PATH => __PACKAGE__->path_to('root','templates')
 });

=head1 DESCRIPTION

Helper for PDF::Reuse Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 AUTHOR

Jon Allen, L<jj@jonallen.info>

=head1 SEE ALSO

L<Catalyst::View::PDF::Reuse>

Penny's Arcade Open Source - L<http://www.pennysarcade.co.uk/opensource>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Penny's Arcade Limited, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::PDF::Reuse';

=head1 NAME

[% class %] - PDF::Reuse View for [% app %]

=head1 DESCRIPTION

PDF::Reuse View for [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
