package Catalyst::Controller::View;

use strict;
use warnings;
use base 'Catalyst::Controller';

our $VERSION = 0.01;

=head1 NAME

Catalyst::Controller::View - Catalyst Controller that directly delegates to View

=head1 SYNOPSIS

    package MyApp::Controller::View;
    use strict;
    use warnings;
    use base 'Catalyst::Controller::View';

=head1 DESCRIPTION

A Catalyst Controller that delegates to View class directly, for convienent
purpose.

=head1 METHODS

=head2 default

The default action. It sets C<$c->stash->{template}> to the path given by the
URI unless there is no such file under C<root> directory.

For instance, suppose your C<MyApp::Controller::View> class is a subclass of
C<Catalyst::Controller::View>, when the incoming path is
C</view/foo/bar.html>, then C<$c->stash->{template}> has the value
C</view/foo/bar.html> if the file C<root/view/foo/bar.html> exists.

=cut

sub default : Private {
   my ( $self, $c ) = @_;
   my $f = $c->path_to('root', @{$c->req->args});
   $c->stash->{template} = $f->relative($c->path_to('root')) .""
       if -f "$f";
}

=head1 AUTHOR

Liu Kang-min <gugod@gugod.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
