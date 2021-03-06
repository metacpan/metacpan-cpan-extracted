# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package GENBlog;

use strict;

use Gantry qw{ -TemplateEngine=TT };

use JSON;
use Gantry::Utils::TablePerms;

our @ISA = qw( Gantry );



#-----------------------------------------------------------------
# $self->namespace() or Blog->namespace()
#-----------------------------------------------------------------
sub namespace {
    return 'Blog';
}

##-----------------------------------------------------------------
## $self->init( $r )
##-----------------------------------------------------------------
#sub init {
#    my ( $self, $r ) = @_;
#
#    # process SUPER's init code
#    $self->SUPER::init( $r );
#
#} # END init


#-----------------------------------------------------------------
# $self->do_main( )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'main.tt' );
    $self->stash->view->title( '' );

    $self->stash->view->data( { pages => $self->site_links() } );
} # END do_main

#-----------------------------------------------------------------
# $self->site_links( )
#-----------------------------------------------------------------
sub site_links {
    my $self = shift;

    return [
    ];
} # END site_links

1;

=head1 NAME

GENBlog - generated support module for Blog

=head1 SYNOPSIS

In Blog:

    use base 'GENBlog';

=head1 DESCRIPTION

This module was generated by Bigtop (and IS subject to regeneration) to
provide methods in support of the whole Blog
application.

Blog should inherit from this module.

=head1 METHODS

=over 4

=item init


=back

=head1 AUTHOR

Phil Crow, E<lt>mail@example.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Phil Crow

All rights reserved.

=cut

