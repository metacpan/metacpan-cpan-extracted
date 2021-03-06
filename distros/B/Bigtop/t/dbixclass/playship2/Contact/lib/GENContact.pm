# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package GENContact;

use strict;
use warnings;

use Gantry qw{
    -Engine=MP20
    -TemplateEngine=TT
};

use JSON;
use Gantry::Utils::TablePerms;

our @ISA = qw( Gantry );


use Contact::Model;
sub schema_base_class { return 'Contact::Model'; }
use Gantry::Plugins::DBIxClassConn qw( get_schema );

#-----------------------------------------------------------------
# $self->namespace() or Contact->namespace()
#-----------------------------------------------------------------
sub namespace {
    return 'Contact';
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
    $self->stash->view->title( 'Contact' );

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

GENContact - generated support module for Contact

=head1 SYNOPSIS

In Contact:

    use base 'GENContact';

=head1 DESCRIPTION

This module was generated by Bigtop (and IS subject to regeneration) to
provide methods in support of the whole Contact
application.

Contact should inherit from this module.

=head1 METHODS

=over 4

=item schema_base_class

=item namespace

=item init

=item do_main

=item site_links


=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

