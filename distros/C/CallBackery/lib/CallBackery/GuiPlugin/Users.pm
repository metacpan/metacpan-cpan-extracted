package CallBackery::GuiPlugin::Users;
use Mojo::Base 'CallBackery::GuiPlugin::AbstractTable';
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);

=head1 NAME

CallBackery::GuiPlugin::Users - User Plugin

=head1 SYNOPSIS

 use CallBackery::GuiPlugin::Users;

=head1 DESCRIPTION

The User Plugin.

=cut


=head1 PROPERTIES

All the methods of L<CallBackery::GuiPlugin::AbstractTable> plus:

=cut

=head2 tableCfg


=cut

has tableCfg => sub {
    my $self = shift;
    return [
        {
            label => trm('UserId'),
            type => 'number',
            width => '1*',
            key => 'cbuser_id',
            sortable => $self->true,
            primary => $self->true,
        },
        {
            label => trm('Username'),
            type => 'string',
            width => '3*',
            key => 'cbuser_login',
            sortable => $self->true,
        },
        {
            label => trm('Given Name'),
            type => 'string',
            width => '4*',
            key => 'cbuser_given',
            sortable => $self->true,
        },
        {
            label => trm('Family Name'),
            type => 'string',
            width => '4*',
            key => 'cbuser_family',
            sortable => $self->true,
        },
        {
            label => trm('Rights'),
            type => 'string',
            sortable => $self->false,
            width => '8*',
            key => 'cbuser_cbrights',
        },
        {
            label => trm('Note'),
            type => 'string',
            width => '8*',
            key => 'cbuser_note',
        },
     ]
};

=head2 actionCfg

=cut

has actionCfg => sub {
    my $self = shift;
    # we must be in admin mode if no user property is set to have be able to prototype all forms variants
    my $admin = ( not $self->user or $self->user->may('admin'));
    return [
        $admin ? ({
            label => trm('Add User'),
            action => 'popup',
            addToContextMenu => $self->true,
            name => 'userFormAdd',
            popupTitle => trm('New User'),
            backend => {
                plugin => 'UserForm',
                config => {
                    type => 'add'
                }
            }
        }) : (),
        {
            label => trm('Edit User'),
            action => 'popup',
            addToContextMenu => $self->true,
            defaultAction => $self->true,
            name => 'userFormEdit',
            popupTitle => trm('Edit User'),
            handler => sub {
                my $args = shift;
                my $id = $args->{selection}{cbuser_id};
                die mkerror(393,"You have to select a user first")
                    if not $id;
            },
            backend => {
                plugin => 'UserForm',
                config => {
                    type => 'edit'
                }
            }
        },
        $admin ? ({
            label => trm('Delete User'),
            action => 'submitVerify',
            addToContextMenu => $self->true,
            question => trm('Do you really want to delete the selected user ?'),
            key => 'delete',
            handler => sub {
                my $args = shift;
                my $id = $args->{selection}{cbuser_id};
                die mkerror(4992,"You have to select a user first")
                    if not $id;
                die mkerror(4993,"You can not delete the user you are logged in with")
                    if $id == $self->user->userId;
                my $db = $self->user->db;

                if ($db->deleteData('cbuser',$id) == 1){
                    return {
                         action => 'reload',
                    };
                }
                die mkerror(4993,"Faild to remove user $id");
            }
        }) : (),
    ];
};

=head1 METHODS

All the methods of L<CallBackery::GuiPlugin::AbstractForm> plus:

=cut


sub currentUserFilter {
    my $self = shift;
    if (not $self->user->may('admin')){
        return 'WHERE cbuser_id = ' . $self->user->mojoSqlDb->dbh->quote($self->user->userId);
    }
    return '';
}

sub getTableRowCount {
    my $self = shift;
    my $args = shift;
    my $db = $self->user->mojoSqlDb;
    if ($self->user->may('admin')){
        return [$db->dbh->selectrow_array('SELECT count(cbuser_id) FROM '
            . $db->dbh->quote_identifier('cbuser'))]->[0];
    }
    return 1;
}

sub getTableData {
    my $self = shift;
    my $args = shift;
    my $db = $self->user->mojoSqlDb;
    my $SORT ='';
    if ($args->{sortColumn}){
        $SORT = 'ORDER BY '.$db->dbh->quote_identifier($args->{sortColumn});
        $SORT .= $args->{sortDesc} ? ' DESC' : ' ASC';
    }
    my $WHERE = '';
    if (not $self->user->may('admin')){
        $WHERE = 'WHERE cbuser_id = ' . $db->dbh->quote($self->user->userId);
    }
    my $userTbl = $db->dbh->quote_identifier('cbuser');
    my $rightTbl = $db->dbh->quote_identifier('cbright');
    my $data = $db->dbh->selectall_arrayref(<<"SQL",{Slice => {}}, $args->{lastRow}-$args->{firstRow},$args->{firstRow});
SELECT cbuser_id,cbuser_login, cbuser_given, cbuser_family, cbuser_note
FROM $userTbl
$WHERE
$SORT
LIMIT ? OFFSET ?
SQL
    my @keys = map { $_->{cbuser_id} } @$data;
    my $keyPh = join ',', map { '?' } @keys;
    my $rightList = $db->dbh->selectall_arrayref(<<"SQL",{Slice => {}}, @keys );
SELECT cbuserright_cbuser,cbright_label FROM cbuserright JOIN $rightTbl ON cbuserright_cbright = cbright_id WHERE cbuserright_cbuser IN ($keyPh)
SQL
    my %rights;
    for (@$rightList){
        push @{$rights{$_->{cbuserright_cbuser}}}, $_->{cbright_label};
    }
    for (@$data){
        $_->{cbuser_cbrights} = join ', ', sort @{$rights{$_->{cbuser_id}}} if ref $rights{$_->{cbuser_id}} eq 'ARRAY';
    }
    return $data;
}


1;
__END__

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 COPYRIGHT

Copyright (c) 2014 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2013-12-16 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
