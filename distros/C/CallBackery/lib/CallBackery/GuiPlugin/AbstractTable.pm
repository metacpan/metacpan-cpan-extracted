package CallBackery::GuiPlugin::AbstractTable;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);

=head1 NAME

CallBackery::GuiPlugin::AbstractTable - Base Class for a table plugin

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::AbstractTable';

=head1 DESCRIPTION

The base class for reporter reporters.

=cut

use Mojo::Base 'CallBackery::GuiPlugin::AbstractForm';

=head1 ATTRIBUTES

The attributes of the L<CallBackery::GuiPlugin::AbstractForm> class and these:

=cut

has screenCfg => sub {
    my $self = shift;
    my $screen = $self->SUPER::screenCfg;
    $screen->{table} = $self->tableCfg;
    $screen->{type} = 'table';
    return $screen;
};

=head2 tableCfg

a table configuration

 return [
    {
        label => trm('Id'),
        type => 'number',
        flex => 1,
        key => 'id',
        sortable => $self->true,
    },
    {
        label => trm('Date'),
        type => 'str',
        flex => 2
        key => 'date'
    },
    {
        label => trm('Content'),
        type => 'str',
        flex => 8,
        key => 'date'
    },
 ]

=cut

has tableCfg => sub {
    croak "the plugin must define its tableCfg property";
};

=head1 METHODS

All the methods of L<CallBackery::GuiPlugin::AbstractForm> plus:

=cut


=head2 getData ('tableData|tableRowCount',tableDataRequest);

Return the requested table data and pass other types of request on to the upper levels.

=cut

sub getData {
    my $self = shift;
    my $type = shift // '';
    if ($type eq 'tableData'){
        return $self->getTableData(@_);
    }
    elsif ($type eq 'tableRowCount'){
        return $self->getTableRowCount(@_);
    }
    else {
        return $self->SUPER::getData($type,@_);
    }
}

=head2 getTableData({formData=>{},firstRow=>{},lastRow=>{},sortColumn=>'key',sortDesc=>true)

return data appropriate for the remote table widget

=cut

sub getTableData {
    return [{}];
}

=head2 getTableRowCount({formData=>{}})

return the number of rows matching the given formData

=cut

sub getTableRowCount {
    return 0;
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

Copyright (c) 2013 by OETIKER+PARTNER AG. All rights reserved.

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
