#
# $Id: Output.pm,v 1.5 2005/01/27 23:30:50 scottb Exp $
#

package CGI::CRUD::Output;

use strict;
use CGI::AutoForm;


=pod

=head1 NAME

CGI::CRUD::Output - Virtual base class liaison between CGI::CRUD and a web server

=head1 DESCRIPTION

Virtual base class liaison between CGI::CRUD and a web server. C<output> method must
be overridden. C<form_attrs> will be called during initialization of the $form object
so set custom $form attributes in that method (see L<CGI::AutoForm>).

=cut

# ctor
sub new
{
    my $caller = shift;

    my $class = ref($caller) || $caller;
    my $self = bless({},$class);

    return $self;
}

sub dbh
{
    my ($self) = @_;
    return $self->{dbh};
}

sub perror
{
    my ($self,$msg) = @_;
    return $self->output(qq[<H2>Error:</H2>$msg]);
}

sub param
{
    my ($self,$name) = @_;
    return $self->{q}{$name};
}

sub query
{
    my $self = shift;
    return $self->{q};
}

sub user
{
    my $self = shift;
    return $self->{user};
}

# MUST BE OVERRIDDEN
# subclass should set $self->{tpl_vars}{BODY} and any others which will get passed to the template
sub output
{
}

sub server_error
{
    my ($self) = @_;
    return $self->perror("<EM>Internal Server Error. </EM><BR>Please contact your server administrator");
}

sub graceful_db_fields
{
    my ($self,$form,$table_name,$usage) = @_;
    shift,shift;
    my $rv = $form->db_fields(@_);
    unless ($rv > 0)
    {
        return $self->_ret($rv,$table_name);
    }
    return $rv;
}

sub graceful_add_form_group
{
    my ($self,$form,$usage,$table_name) = @_;
    shift,shift;
    my $rv = $form->add_group(@_);
    unless ($rv > 0)
    {
        return $self->_ret($rv,$table_name);
    }
    return $rv;
}

sub _ret
{
    my ($self,$rv,$table_name) = @_;
    if (!defined($rv))
    {
        $self->server_error();
    }
    elsif ($rv == 0)
    {
        $self->perror("Table [$table_name] does not exist and does not have fields defined in UI_TABLE_COLUMN");
    }
    elsif ($rv == -1)
    {
        $self->perror("At least 1 field in [$table_name] requested a SELECT input control but no mask list was found");
    }
    elsif ($rv == -2)
    {
        $self->perror("Can't remember what this error was");
    }
    elsif ($rv == -3)
    {
        $self->perror("$table_name (or one of its columns) not defined in the database");
    }
    else
    {
        $self->server_error();
    }
    return undef;
}

# Class or instance method
sub form
{
    my $caller = shift;
    my $form = new CGI::AutoForm(@_);
    $caller->form_attrs($form);
    return $form;
}

sub form_attrs
{
}

1;

__END__

=head1 SEE ALSO

L<CGI::CRUD::TableIO>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2007 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

