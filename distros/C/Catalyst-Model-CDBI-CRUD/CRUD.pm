package Catalyst::Model::CDBI::CRUD;

use strict;
use base 'Catalyst::Model::CDBI';
use Class::DBI::AsForm;
use Class::DBI::FromForm;
use Class::DBI::Plugin::RetrieveAll;

our $VERSION = '0.04';

=head1 NAME

Catalyst::Model::CDBI::CRUD - CRUD CDBI Model Class

=head1 SYNOPSIS

    # lib/MyApp/Model/CDBI.pm
    package MyApp::Model::CDBI;

    use base 'Catalyst::Model::CDBI::CRUD';

    __PACKAGE__->config(
        dsn           => 'dbi:SQLite2:/tmp/myapp.db',
        relationships => 1
    );

    1;

    # lib/MyApp.pm
    package MyApp;

    use Catalyst 'FormValidator';

    __PACKAGE__->config(
        name => 'My Application',
        root => '/home/joeuser/myapp/root'
    );

        sub table : Global {
            my ( $self, $c ) = @_;
            $c->form( optional => [ MyApp::Model::CDBI::Table->columns 
                                  ] ); #see Data::FormValidator
            $c->forward('MyApp::Model::CDBI::Table');
        }
        sub end : Private {
          $c->forward('MyApp::V::TT');
        }  

    1;


=head1 DESCRIPTION

This is a subclass of C<Catalyst::Model::CDBI> with additional CRUD 
methods. Don't forget to copy the base templates to config->root!

*NOTE* This module has been deprecated. See BUGS section below!

=head2 METHODS

=head3 add

Does nothing by default.

=cut

sub add { }

=head3 destroy

Deletes a L<Class::DBI> object.

=cut

sub destroy {
    my ( $self, $c ) = @_;
    $c->stash->{item}->delete;
    $c->stash->{template} = 'list';
}

=head3 do_add

Creates a new L<Class::DBI> object from $c->form.

=cut

sub do_add {
    my ( $self, $c ) = @_;
    $self->create_from_form( $c->form );
    $c->stash->{template} = 'list';
}

=head3 do_edit

Updates a L<Class::DBI> object from $c->form.

=cut

sub do_edit {
    my ( $self, $c ) = @_;
    $c->stash->{item}->update_from_form( $c->form );
    $c->stash->{template} = 'edit';
}

=head3 edit

Does nothing by default.

=cut

sub edit { }

=head3 list

Does nothing by default.

=cut

sub list { }

=head3 process

Dispatches CRUD request to methods.

=cut

sub process {
    my $self   = shift;
    my $c      = shift;
    my $method = shift || 'list';
    $c->stash->{item}     = $self->retrieve( $_[0] ) if defined( $_[0] );
    $c->stash->{template} = $method;
    $c->stash->{class}    = ref $self || $self;
    $self->$method( $c, @_ ) if $self->can($method);
}

=head3 view

Does nothing by default.

=cut

sub view { }

=head1 BUGS

This module is no longer supported by the Catalyst developers. We keep it 
indexed for the sake of existing users, but highly recommend new users to
look at L<Catalyst::Helper::Controller::Scaffold>

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Model::CDBI>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
