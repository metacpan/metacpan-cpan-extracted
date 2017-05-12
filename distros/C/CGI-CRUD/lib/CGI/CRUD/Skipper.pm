#
# $Id: Skipper.pm,v 1.3 2005/01/27 21:33:26 rsandberg Exp $
#

package CGI::CRUD::Skipper;

use strict;
use CGI::CRUD::SkipperOutput;
use CGI::CRUD::TableIO;
use CGI::AutoForm;
use DBIx::IO::Table;

use constant OK => 0;

@CGI::CRUD::Skipper::ISA = (qw(CGI::CRUD::TableIO));

my $table_field = {
    FIELD_NAME => 'TABLE_NAME',
    INPUT_CONTROL_TYPE => 'SELECT',
    HEADING => 'Table Name',
    DATATYPE => 'CHAR',
    REQUIRED => 'Y',
    INSERTABLE => 'Y',
};

my $action_field = {
    FIELD_NAME => 'ACTION',
    INPUT_CONTROL_TYPE => 'RADIO',
    DEFAULT_VALUE => 'IR',
    HEADING => 'Operation',
    DATATYPE => 'CHAR',
    REQUIRED => 'Y',
    INSERTABLE => 'Y',
};
my $action_picklist = [
    { ID => 'IR', MASK => 'Insert', },
    { ID => 'SR', MASK => 'Search/Edit', },
];


=pod

=head1 NAME

CGI::CRUD::Skipper - Generic implementation of CGI::CRUD::TableIO

=head1 DESCRIPTION

A concrete subclass of CGI::CRUD::TableIO to provide a vanilla web front-end to your RDBMS. It performs auto-discovery of your schema
and data dictionary, just plug it in and go - you can customize and code later.

Naming conventions that bear any similarity to the famous TV star Muddy Mudskipper (having made several special appearances on "The Ren and Stimpy Show") are purely co-incidental.

=cut


sub handler
{
    my $r = new CGI::CRUD::SkipperOutput(@_) or return OK;

    my $self = __PACKAGE__->new($r->dbh());

    $self->handle_req($r);

    return OK;
}

sub handle_req
{
    my ($self,$r) = @_;

    $self->{action} = $ENV{CRUDDY_URI_PREFIX}.$r->{apache}->uri() if $ENV{MOD_PERL};
    
    my $query = $r->query();
    #$query->{'__SDAT_TAB_ACTION.TABLE_NAME'} = uc($query->{'__SDAT_TAB_ACTION.TABLE_NAME'}) if exists($query->{'__SDAT_TAB_ACTION.TABLE_NAME'});
    my $action = $r->param('__SDAT_TAB_ACTION.ACTION') || '';

    # Set other vars to be substituted into CGI::FastTemplate
    $r->{tpl_vars}{HOME_URL} = $self->{action};

    if ($r->param('__SDAT_TAB_ACTION.RESTART'))
    {
        $self->request_action($r);
    }
    elsif ($action eq 'IR')
    {
        $self->insert_req($r);
    }
    elsif ($action eq 'ID')
    {
        $self->insert_data($r);
    }
    elsif ($action eq 'SR')
    {
        $self->search_req($r);
    }
    elsif ($action eq 'SD')
    {
        $self->search_results($r);
    }
    elsif ($action eq 'UR')
    {
        $self->update_req($r);
    }
    elsif ($action eq 'UD')
    {
        $self->update_data($r);
    }
    elsif ($action eq 'DR')
    {
        $self->delete_req($r);
    }
    else
    {
        $self->request_action($r);
    }
}

sub request_action
{
    my ($self,$r) = @_;
    my $dbh = $r->dbh();
    my $form = $r->form($dbh);
    $form->heading("Database Operations");
    $form->action($self->{action});
    $form->submit_value('Continue');
    $form->add_group('INSERTABLE',undef,'Choose a table and an operation to perform on that table','__SDAT_TAB_ACTION');

    unless (defined($self->{table_picklist}))
    {
        my $table_names = DBIx::IO::Table->existing_table_names($dbh);
        ref($table_names) or ($r->server_error(),return undef);
        my @tp = ();
        foreach my $table_name (@$table_names)
        {
            push(@tp,{ID => $table_name, MASK => $table_name});
        }
        $tp[0] = {ID => 'NO TABLES FOUND', MASK => 'NO TABLES FOUND'} unless @tp;
        $self->{table_picklist} = \@tp;
    }

    my $rv;
    unless ($rv = $form->add_field($table_field,$self->{table_picklist}))
    {
        defined($rv) or ($r->server_error(),return undef);
        $r->perror("Table list unavailable");
        return $rv;
    }
    $form->add_field($action_field,$action_picklist);
    $r->output($form->prepare($r->query()));
}

1;

__END__

=head1 BUGS

No known bugs.

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

