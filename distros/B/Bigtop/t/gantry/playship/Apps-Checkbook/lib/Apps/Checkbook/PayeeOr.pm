package Apps::Checkbook::PayeeOr;

use strict;
use warnings;

use base 'Apps::Checkbook::GEN::PayeeOr';

use Gantry::Plugins::CRUD;

use SomePackage::SomeModule;

use ExportingModule qw(
    sample
    $EXPORTS
);


use Apps::Checkbook::Model::payee qw(
    $PAYEE
);

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
# This method inherited from Apps::Checkbook::GEN::PayeeOr

my $my_crud = Gantry::Plugins::CRUD->new(
    add_action      => \&my_crud_add,
    edit_action     => \&my_crud_edit,
    delete_action   => \&my_crud_delete,
    form            => __PACKAGE__->can( 'my_crud_form' ),
    redirect        => \&my_crud_redirect,
    text_descr      => 'Payee/Payor',
);

#-----------------------------------------------------------------
# $self->my_crud_redirect( $data )
# The generated version mimics the default behavior, feel free
# to delete the redirect key from the constructor call for $crud
# and this sub.
#-----------------------------------------------------------------
sub my_crud_redirect {
    my ( $self, $data ) = @_;
    return $self->location;
}

#-------------------------------------------------
# $self->do_add( )
#-------------------------------------------------
sub do_add {
    my $self = shift;

    $my_crud->add( $self, { data => \@_ } );
}

#-------------------------------------------------
# $self->my_crud_add( $params, $data )
#-------------------------------------------------
sub my_crud_add {
    my ( $self, $params, $data ) = @_;

    # make a new row in the $PAYEE table using data from $params
    # remember to add commit if needed

    $PAYEE->gupdate_or_create( $self, $params );
}

#-------------------------------------------------
# $self->do_delete( $doomed_id, $confirm )
#-------------------------------------------------
sub do_delete {
    my ( $self, $doomed_id, $confirm ) = @_;

    my $row = $PAYEE->gfind( $self, $doomed_id );

    $my_crud->delete( $self, $confirm, { row => $row } );
}

#-------------------------------------------------
# $self->my_crud_delete( $data )
#-------------------------------------------------
sub my_crud_delete {
    my ( $self, $data ) = @_;

    # fish the id (or the actual row) from the data hash
    # delete it
    # remember to add commit if needed

    $data->{ row }->delete;
}

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    my $row = $PAYEE->gfind( $self, $id );

    $my_crud->edit( $self, { row => $row } );
}

#-------------------------------------------------
# $self->my_crud_edit( $param, $data )
#-------------------------------------------------
sub my_crud_edit {
    my( $self, $params, $data ) = @_;

    # retrieve the row from the data hash
    # update the row
    # remember to add commit if needed

    $data->{row}->update( $params );
}

#-----------------------------------------------------------------
# $self->my_crud_form( $data )
#-----------------------------------------------------------------
# This method inherited from Apps::Checkbook::GEN::PayeeOr

my $crud = Gantry::Plugins::CRUD->new(
    add_action      => \&crud_add,
    edit_action     => \&crud_edit,
    delete_action   => \&crud_delete,
    form            => __PACKAGE__->can( '_form' ),
    redirect        => \&crud_redirect,
    text_descr      => 'Payee/Payor',
);

#-----------------------------------------------------------------
# $self->crud_redirect( $data )
# The generated version mimics the default behavior, feel free
# to delete the redirect key from the constructor call for $crud
# and this sub.
#-----------------------------------------------------------------
sub crud_redirect {
    my ( $self, $data ) = @_;
    return $self->location;
}

#-------------------------------------------------
# $self->do_add( )
#-------------------------------------------------
sub do_add {
    my $self = shift;

    $crud->add( $self, { data => \@_ } );
}

#-------------------------------------------------
# $self->crud_add( $params, $data )
#-------------------------------------------------
sub crud_add {
    my ( $self, $params, $data ) = @_;

    # make a new row in the $PAYEE table using data from $params
    # remember to add commit if needed

    $PAYEE->gupdate_or_create( $self, $params );
}

#-------------------------------------------------
# $self->do_delete( $doomed_id, $confirm )
#-------------------------------------------------
sub do_delete {
    my ( $self, $doomed_id, $confirm ) = @_;

    my $row = $PAYEE->gfind( $self, $doomed_id );

    $crud->delete( $self, $confirm, { row => $row } );
}

#-------------------------------------------------
# $self->crud_delete( $data )
#-------------------------------------------------
sub crud_delete {
    my ( $self, $data ) = @_;

    # fish the id (or the actual row) from the data hash
    # delete it
    # remember to add commit if needed

    $data->{ row }->delete;
}

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    my $row = $PAYEE->gfind( $self, $id );

    $crud->edit( $self, { row => $row } );
}

#-------------------------------------------------
# $self->crud_edit( $param, $data )
#-------------------------------------------------
sub crud_edit {
    my( $self, $params, $data ) = @_;

    # retrieve the row from the data hash
    # update the row
    # remember to add commit if needed

    $data->{row}->update( $params );
}

#-----------------------------------------------------------------
# $self->_form( $data )
#-----------------------------------------------------------------
# This method inherited from Apps::Checkbook::GEN::PayeeOr

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
# This method inherited from Apps::Checkbook::GEN::PayeeOr

#-----------------------------------------------------------------
# $self->do_members(  )
#-----------------------------------------------------------------
sub do_members {
    my ( $self ) = @_;
} # END do_members


1;

=head1 NAME

Apps::Checkbook::PayeeOr - A controller in the Apps::Checkbook application

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Apps::Checkbook::PayeeOr;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/someurl' => 'Apps::Checkbook::PayeeOr',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Apps::Checkbook::PayeeOr;
    </Perl>

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler Apps::Checkbook::PayeeOr
    </Location>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

=item do_members

=item get_model_name

=item text_descr

=item my_crud_redirect

=item do_add

=item my_crud_add

=item do_delete

=item my_crud_delete

=item do_edit

=item my_crud_edit

=item crud_redirect

=item do_add

=item crud_add

=item do_delete

=item crud_delete

=item do_edit

=item crud_edit


=back


=head1 METHODS INHERITED FROM Apps::Checkbook::GEN::PayeeOr

=over 4

=item do_main

=item my_crud_form

=item _form

=item form


=back


=head1 DEPENDENCIES

    Apps::Checkbook
    Apps::Checkbook::GEN::PayeeOr
    SomePackage::SomeModule
    ExportingModule
    Apps::Checkbook::Model::payee
    Gantry::Plugins::CRUD

=head1 AUTHOR

Somebody Somewhere, E<lt>somebody@example.comE<gt>

Somebody Else

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Somebody Somewhere

All rights reserved.

=cut
