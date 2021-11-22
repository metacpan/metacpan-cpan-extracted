package CallBackery::GuiPlugin::AbstractTable;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);
use Text::CSV;
use Excel::Writer::XLSX;
use Mojo::JSON qw(true false);
use Time::Piece;

=head1 NAME

CallBackery::GuiPlugin::AbstractTable - Base Class for a table plugin

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::AbstractTable';

=head1 DESCRIPTION

The base class for table plugins, derived from CallBackery::GuiPlugin::AbstractForm

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
        sortable => true,
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

=head2 getTableData({formData=>{},firstRow=>{},lastRow=>{},sortColumn=>'key',sortDesc=>true})

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

=head2 makeExportAction(type => 'XLSX', filename => 'export-"now"', label => 'Export')

Create export button.
The default type is XLSX, also available is CSV.

=cut

sub makeExportAction {
    my $self = shift;
    my %args = @_;
    my $type = $args{type} // 'XLSX';
    my $label = $args{label} // trm("Export %1", $type);
    my $filename = $args{filename}
        // localtime->strftime('export-%Y-%m-%d-%H-%M-%S.').lc($type);

    return  {
        label            => $label,
        action           => 'download',
        addToContextMenu => true,
        key              => 'export_csv',
        actionHandler    => sub {
            my $self = shift;
            my $args = shift;
            my $data = $self->getTableData({
                formData => $args,
                firstRow => 0,
                lastRow => $self->getTableRowCount({ formData=>$args })
            });

            # Use the (translated) table headers in row 1.
            # Or the keys if undefined.
            my $loc = CallBackery::Translate->new(localeRoot=>$self->app->home->child("share"));
            $loc->setLocale($self->user->userInfo->{lang} // 'en');
            my $tCfg = $self->tableCfg;

            my @titles = map {
                $_->{label}
                    ? ((ref $_->{label} eq 'CallBackery::Translate')
                        ? $loc->tra($_->{label}[0])
                        : $_->{label})
                    : $_->{key};
            } @$tCfg;

            if ($type eq 'CSV') {
                my $csv = Text::CSV->new;
                $csv->combine(@titles);
                my $csv_str = $csv->string . "\n";
                for my $record (@$data) {
                    $csv->combine(map {
                        my $v = $record->{$_->{key}};
                        if ($_->{type} eq 'date') {
                            $v= localtime($v/1000)->strftime("%Y-%m-%d %H:%M:%S %z");
                        }
                        $v} @$tCfg);
                    $csv_str .= $csv->string . "\n";
                }
                my $asset = Mojo::Asset::Memory->new;
                $asset->add_chunk($csv_str);
                return {
                    asset    => $asset,
                    type     => 'text/csv',
                    filename => $filename,
                }
            }
            elsif ($type eq 'XLSX') {
                open my $xh, '>', \my $xlsx or die "failed to open xlsx fh: $!";
                my $workbook  = Excel::Writer::XLSX->new($xh);
                my $worksheet = $workbook->add_worksheet();

                my $col = 0;
                map {$worksheet->write(0, $col, $_); $col++} @titles;

                my $row = 2;
                my %date_format;
                for my $record (@$data) {
                    $col = 0;
                    for my $tc (@$tCfg) {
                        my $v = $record->{$tc->{key}};
                        if ($tc->{type} eq 'date') {
                            my $fmt = $tc->{format} //'yyyy-mm-dd hh:mm:ss';
                            $date_format{$fmt} //=
                                $workbook->add_format(num_format => $fmt);
                            $worksheet->write_date_time($row,$col,localtime($v/1000)->strftime("%Y-%m-%dT%H:%M:%S"),$date_format{$fmt}) if $v;
                        }
                        else {
                            $worksheet->write($row, $col, $v) if defined $v;
                        }
                        $col++}
                    $row++;
                }

                $workbook->close();
                my $asset = Mojo::Asset::Memory->new;
                $asset->add_chunk($xlsx);
                return {
                    asset    => $asset,
                    type     => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                    filename => $filename,
                }

            }
            else {
                die mkerror(9999, "unknown export type $type");
            }
        }
    };
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
