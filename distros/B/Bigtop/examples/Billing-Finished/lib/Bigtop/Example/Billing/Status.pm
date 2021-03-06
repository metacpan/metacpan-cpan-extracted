package Bigtop::Example::Billing::Status;

use strict;

use base 'Bigtop::Example::Billing::GEN::Status';

use Gantry::Plugins::AutoCRUD qw(
    do_add
    do_edit
    do_delete
    form_name
);

use Bigtop::Example::Billing::Model::status qw(
    $STATUS
);
use Bigtop::Example::Billing::Model;
sub schema_base_class { return 'Bigtop::Example::Billing::Model'; }
use Gantry::Plugins::DBIxClassConn qw( get_schema );

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
# This method supplied by Bigtop::Example::Billing::GEN::Status

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
# This method supplied by Bigtop::Example::Billing::GEN::Status


#-----------------------------------------------------------------
# get_model_name( )
#-----------------------------------------------------------------
sub get_model_name {
    return $STATUS;
}

#-----------------------------------------------------------------
# get_orm_helper( )
#-----------------------------------------------------------------
sub get_orm_helper {
    return 'Gantry::Plugins::AutoCRUDHelper::DBIxClass';
}

#-----------------------------------------------------------------
# text_descr( )
#-----------------------------------------------------------------
sub text_descr     {
    return 'status';
}

1;

=head1 NAME

Bigtop::Example::Billing::Status - A controller in the Billing application

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Bigtop::Example::Billing::Status;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/someurl' => 'Bigtop::Example::Billing::Status',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Bigtop::Example::Billing::Status;
    </Perl>

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler Bigtop::Example::Billing::Status
    </Location>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

=item get_model_name

=item text_descr

=item schema_base_class

=item get_orm_helper


=back


=head1 METHODS MIXED IN FROM Bigtop::Example::Billing::GEN::Status

=over 4

=item do_main

=item form


=back


=head1 DEPENDENCIES

    Bigtop::Example::Billing
    Bigtop::Example::Billing::GEN::Status
    Bigtop::Example::Billing::Model::status
    Gantry::Plugins::AutoCRUD

=head1 AUTHOR

Phil Crow

Tim Keefer

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
