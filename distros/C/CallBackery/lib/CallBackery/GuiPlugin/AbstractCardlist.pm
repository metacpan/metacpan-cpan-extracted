package CallBackery::GuiPlugin::AbstractCardlist;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);
use Mojo::JSON qw(true false);
use POSIX qw(strftime);

=head1 NAME

CallBackery::GuiPlugin::AbstractCardlist - Base class for a cardlist plugin

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::AbstractCardlist';

=head1 DESCRIPTION

The base class for cardlist plugins, derived from CallBackery::GuiPlugin::AbstractTable

=cut

use Mojo::Base 'CallBackery::GuiPlugin::AbstractTable';

=head1 ATTRIBUTES

The attributes of the L<CallBackery::GuiPlugin::AbstractTable> class and these:

=cut

has screenCfg => sub {
    my $self = shift;
    my $screen = $self->SUPER::screenCfg;
    $screen->{type}         = 'cardlist';
    $screen->{updateAction} = 'updateCard';
    $screen->{cardCfg}      = $self->cardCfg;
    return $screen;
};

=head2 cardCfg

Configuration of the card list cards

 return [
     layout => {
         class => 'qx.ui.layout.Grid',
         setFunctions => {
             setColumnFlex => [
                 [ 0, 1 ],
                 [ 5, 1 ],
             ],
             setColumnWidth => [
                 [ 5, 200 ],
             ],
             setColumnAlign => [
                 [ 5, 'right', 'bottom' ],
             ],
             setSpacingX => [ [20], ],
             setSpacingY => [ [3],  ],
         },
     },
     form => [
         {
             label => {
                 addSet => { row => 0, column => 0, },
                 set => {
                     value => trm('Type'),
                 },
             },
             field => {
                 addSet => { row => 1, column => 0, },
                 class  => 'qx.ui.form.TextField',
                 key    => 'oatkg_label',
                 set    => { width => 100, readOnly => true },
             },
         },
     ],
 ];

=cut

has cardCfg => sub {
    die mkerror(3456, trm("cardCfg must be defined in child plugin class"));
};

=head2 tableCfg

is not used for card plugins, use cardCfg instead.

=cut

has 'tableCfg';

=head1 METHODS

All the methods of L<CallBackery::GuiPlugin::AbstractTable> plus:

=cut

=head2 getData ('allCardData');

Return the requested card data and pass other types of request on to the upper levels.

allCardData() can either return an array ref of card data or a hash ref

{
  data => [], # card data
  info => {}, # Qooxdoo qx.ui.basic.Label properties
}

in which case a label is shown between the action toolbar and the card list.
Sending an undefined info entry removes the label.

=cut

sub getData {
    my $self = shift;
    my $call = shift // '';

    if ($call eq 'getAllCardData') {
        my $parentFormData = shift;
        return $self->getAllCardData($parentFormData, @_);
    }
    elsif ($call eq 'allCardData') {
        # backward compatibility with previously broken CardList.js implementation
        $self->log->warn("allCardData() is deprecated, use getAllCardData() instead");
        return $self->allCardData(@_);
    }
    else {
        return $self->SUPER::getData($call, @_);
    }
}


=head2 getAllCardData(parentFormData, { currentFormData => data }, @_)

return data appropriate for the card list widget

=cut

sub getAllCardData {
    my $self = shift;
    state $warned = 0;
    if (not $warned) {
        $self->log->warn("getAllCardData() must be overridden");
        $self->log->warn("Calling deprecated method allCardData(), you should use getAllCardData() instead.");
        $warned = 1;
    }
    return $self->allCardData(@_);
}


=head2 allCardData()

deprecated, return data appropriate for the card list widget

=cut

sub allCardData {
    my $self = shift;
    $self->log->warn("allCardData() is deprecated, use getAllCardData() instead");
    return [{}];
}


=head2 makeExportAction(type => 'XLSX', filename => 'export-"now"', label => 'Export')

Create export button. Not yet implemented for card plugins.

=cut

sub makeExportAction {
    die mkerror(999, "makeExportAction() not yet implemented for card plugins");
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

Copyright (c) 2013-2020 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>

=head1 HISTORY

 2020-09-01 fz 1.0 first version

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
