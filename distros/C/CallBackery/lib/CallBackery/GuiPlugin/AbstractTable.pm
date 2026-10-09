package CallBackery::GuiPlugin::AbstractTable;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);
use Text::CSV;
use Excel::Writer::XLSX;
use Compress::Zlib ();
use File::Temp ();
use Mojo::Asset::Memory;
use Mojo::JSON qw(true false);
use Mojo::Util qw(encode);
use Time::Piece;

# Text::QRCode is only pulled in when an export actually asks for a qrCode
# column, so that installations which never export QR codes do not have to
# carry libqrencode. See _qrEncoder below.
my $QR_ENCODER;

# how _qrPng renders a matrix, and how large the result appears in the sheet
my $QR_MODULE_SIZE = 4;      # pixels per qr module
my $QR_QUIET_ZONE  = 4;      # modules of mandatory light border
my $QR_DEFAULT_SIZE = 100;   # pixels the image is scaled to in the cell

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

=head2 _exportColumnPlan($tableCfg,$extraCols)

Merge the extra export columns into the table configuration and return the
resulting list of output columns. Each element is either

 { col => $tableCfgEntry }

for a normal data column, or

 { extra => $extraColSpec }

for a generated one. The C<insertAfter> indices of all extra columns refer to
the original C<$tableCfg>, so several extra columns cannot shift each other
around.

=cut

my %EXTRA_COL_TYPE = (qrCode => 1);

sub _exportColumnPlan {
    my $self = shift;
    my $tCfg = shift;
    my $extraCols = shift // [];

    my %insertAfter;
    for my $extra (@$extraCols) {
        my $type = $extra->{type} // '';
        die mkerror(9930, "unknown extra export column type '$type'")
            unless $EXTRA_COL_TYPE{$type};

        my $content = $extra->{content};
        die mkerror(9931, "extra export column of type '$type' has no content")
            unless defined $content;

        my $idx = $extra->{insertAfter};
        if (defined $idx) {
            die mkerror(9932,
                "insertAfter $idx of extra export column is out of range")
                if $idx !~ /^\d+$/ or $idx > $#$tCfg;
        }
        elsif (ref $content eq 'CODE') {
            die mkerror(9933,
                "an extra export column with a code reference content "
                ."requires an explicit insertAfter");
        }

        # the column the content is taken from, if there is one. It supplies
        # the default label, and with no insertAfter also the position.
        my ($srcIdx);
        if (ref $content ne 'CODE') {
            ($srcIdx) = grep { ($tCfg->[$_]{key} // '') eq $content } 0..$#$tCfg;
        }
        if (not defined $idx) {
            die mkerror(9934,
                "no table column with key '$content' to attach an extra "
                ."export column to")
                unless defined $srcIdx;
            $idx = $srcIdx;
        }
        push @{$insertAfter{$idx}}, { extra => $extra, srcIdx => $srcIdx };
    }

    my @plan;
    for my $i (0..$#$tCfg) {
        push @plan, { col => $tCfg->[$i] };
        push @plan, @{$insertAfter{$i} // []};
    }
    return \@plan;
}

=head2 _qrEncoder()

Return a shared L<Text::QRCode> instance, loading the module on first use.

=cut

sub _qrEncoder {
    $QR_ENCODER //= do {
        eval { require Text::QRCode; 1 }
            or die mkerror(9935,
                "exporting QR codes requires the Text::QRCode module: $@");
        Text::QRCode->new;
    };
    return $QR_ENCODER;
}

=head2 _qrPng($matrix,$moduleSize,$quietZone)

Render a L<Text::QRCode> matrix (rows of C<*> and C<space>) into a 1 bit
greyscale PNG and return it as a byte string. C<$moduleSize> is the edge
length of one QR module in pixels (default 4) and C<$quietZone> the width of
the mandatory light border in modules (default 4).

Writing the PNG by hand keeps this free of any image library.

=cut

sub _qrPng {
    my $self = shift;
    my $matrix = shift;
    my $moduleSize = shift // $QR_MODULE_SIZE;
    my $quietZone = shift // $QR_QUIET_ZONE;

    my $modules = scalar @$matrix;
    my $side = ($modules + 2 * $quietZone) * $moduleSize;
    my $padding = (8 - $side % 8) % 8;

    # 0 is dark and 1 is light in a 1 bit greyscale image. The padding bits at
    # the end of a scanline are ignored by the decoder, light keeps them tidy.
    my $blank = pack 'B*', '1' x ($side + $padding);
    my $quiet = '1' x ($quietZone * $moduleSize);

    my $raw = "\0$blank" x ($quietZone * $moduleSize);
    for my $row (@$matrix) {
        my $bits = $quiet
            . join('', map { ($_ eq '*' ? '0' : '1') x $moduleSize } @$row)
            . $quiet . '1' x $padding;
        my $line = "\0" . pack('B*', $bits);
        $raw .= $line x $moduleSize;
    }
    $raw .= "\0$blank" x ($quietZone * $moduleSize);

    my $chunk = sub {
        my ($type, $data) = @_;
        return pack('N', length $data) . $type . $data
            . pack('N', Compress::Zlib::crc32($type . $data));
    };

    return "\x89PNG\r\n\x1a\n"
        . $chunk->('IHDR', pack('N N C C C C C', $side, $side, 1, 0, 0, 0, 0))
        . $chunk->('IDAT', Compress::Zlib::compress($raw))
        . $chunk->('IEND', '');
}

=head2 makeExportAction(type => 'XLSX', filename => 'export-"now"', label => 'Export')

Create export button.
The default type is XLSX, also available is CSV.

An XLSX export can carry extra generated columns next to the table data:

 $self->makeExportAction(
     type      => 'XLSX',
     extraCols => [
         {   type        => 'qrCode',
             content     => 'serial',
             insertAfter => 1,
             label       => trm('QR'),
             size        => 100,
         },
     ],
 );

Every entry adds one column and takes these keys:

=over

=item type

The kind of column to generate. Only C<qrCode> exists so far. It embeds the
content as a QR code image.

=item content

Where the content comes from: either the key of a field in the table data, or
a code reference which is called with the record hash reference and returns
the string to encode. A record whose content is undefined or empty gets no
image.

=item insertAfter

Optional. The zero based index in L</tableCfg> the new column is placed after.
The indices of all extra columns refer to the original L</tableCfg>, so
several extra columns cannot shift each other around. Without it the column
follows the column named by C<content>, which is therefore mandatory for a
code reference content.

=item label

Optional column heading, translated like any other label. It defaults to the
heading of the column named by C<content>.

=item size

Optional edge length of the image in pixels, 100 by default. The row height
and the column width are adjusted to fit.

=back

C<extraCols> is ignored for a CSV export, which has nowhere to put an image.

A C<qrCode> column needs L<Text::QRCode>, which is loaded on first use so that
installations without QR code exports do not have to carry it.

=cut

# The rule xtr() applies in the frontend: an array is a message to
# translate, anything else is data. That covers a trm() made in this process
# and one that crossed JSON on its way here -- a status some other system
# reported, say -- which is a plain array by now. Handed to the writer as it
# was, the first came out in English and the second as "ARRAY(0x...)" in a
# csv, while Excel::Writer::XLSX spread it over the following cells and left
# the bare "%1" standing in this one. Arguments are rendered first, so a
# nested message gets its own msgid translated before it is substituted.
sub _renderMessage {
    my $loc = shift;
    my $value = shift;
    return $value
        unless ref $value eq 'CallBackery::Translate'
            or ref $value eq 'ARRAY';
    my ($str,@args) = @$value;
    return '' unless defined $str and $str ne '';
    return $loc->tra($str, map { _renderMessage($loc, $_) // '' } @args);
}

sub makeExportAction {
    my $self = shift;
    my %args = @_;
    my $type = $args{type} // 'XLSX';
    my $extraCols = $args{extraCols};
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

            my $tra = sub { _renderMessage($loc, shift) };

            my @titles = map { $tra->($_->{label}) // $_->{key} } @$tCfg;

            if ($type eq 'CSV') {
                # Without binary mode Text::CSV refuses a line break or any
                # character outside ASCII, and combine() then leaves an
                # empty string behind: the row went missing without a word.
                my $csv = Text::CSV->new({ binary => 1 });
                my $line = sub {
                    $csv->combine(@_)
                        or die mkerror(9938, "failed to write csv line: "
                            . $csv->error_diag);
                    return $csv->string . "\n";
                };
                my $csv_str = $line->(@titles);
                for my $record (@$data) {
                    $csv_str .= $line->(map {
                        my $v = $record->{$_->{key}};
                        # an empty date is an empty cell, as in the xlsx
                        # export, not the start of 1970
                        if ($_->{type} eq 'date' and $v) {
                            $v= localtime($v/1000)->strftime("%Y-%m-%d %H:%M:%S %z");
                        }
                        $tra->($v)} @$tCfg);
                }
                my $asset = Mojo::Asset::Memory->new;
                # an asset holds bytes; the text has to be encoded first
                $asset->add_chunk(encode('UTF-8', $csv_str));
                return {
                    asset    => $asset,
                    type     => 'text/csv; charset=UTF-8',
                    filename => $filename,
                }
            }
            elsif ($type eq 'XLSX') {
                # a spreadsheet is the only export that can hold images, so
                # the extra columns exist here and are ignored for CSV
                my $plan = $self->_exportColumnPlan($tCfg, $extraCols);

                open my $xh, '>', \my $xlsx or die "failed to open xlsx fh: $!";
                my $workbook  = Excel::Writer::XLSX->new($xh);
                my $worksheet = $workbook->add_worksheet();

                my $col = 0;
                for my $p (@$plan) {
                    if (my $tc = $p->{col}) {
                        $worksheet->write(0, $col, $tra->($tc->{label}) // $tc->{key});
                    }
                    else {
                        my $size = $p->{extra}{size} // $QR_DEFAULT_SIZE;
                        my $src = defined $p->{srcIdx} ? $tCfg->[$p->{srcIdx}] : undef;
                        $worksheet->write(0, $col,
                            $tra->($p->{extra}{label})
                                // ($src ? $tra->($src->{label}) // $src->{key} : ''));
                        # excel measures column width in characters of the
                        # default font, which is 7 pixels wide
                        $worksheet->set_column($col, $col, ($size + 5) / 7);
                    }
                    $col++;
                }

                # Excel::Writer::XLSX only reads images from disk, and only
                # when the workbook is closed, so the directory has to outlive
                # the loop below
                my $tmpDir;
                my $qrCount = 0;
                my %qrCache;

                my $row = 2;
                my %date_format;
                for my $record (@$data) {
                    $col = 0;
                    my $rowSize = 0;
                    for my $p (@$plan) {
                        if (my $tc = $p->{col}) {
                            my $v = $record->{$tc->{key}};
                            if ($tc->{type} eq 'date') {
                                my $fmt = $tc->{format} //'yyyy-mm-dd hh:mm:ss';
                                $date_format{$fmt} //=
                                    $workbook->add_format(num_format => $fmt);
                                $worksheet->write_date_time($row,$col,localtime($v/1000)->strftime("%Y-%m-%dT%H:%M:%S"),$date_format{$fmt}) if $v;
                            }
                            else {
                                $v = $tra->($v);
                                $worksheet->write($row, $col, $v) if defined $v;
                            }
                        }
                        else {
                            my $extra = $p->{extra};
                            my $content = $extra->{content};
                            my $text = ref $content eq 'CODE'
                                ? $content->($record)
                                : $record->{$content};
                            if (defined $text and $text ne '') {
                                my $size = $extra->{size} // $QR_DEFAULT_SIZE;
                                $tmpDir //= File::Temp->newdir;
                                my $qr = $qrCache{$text} //= do {
                                    # a qr code has a capacity limit, and
                                    # Text::QRCode reports going over it with
                                    # a bare XS error
                                    my $matrix = eval {
                                        $self->_qrEncoder->plot($text) }
                                        or die mkerror(9937,
                                            "cannot encode '"
                                            .(length($text) > 40
                                                ? substr($text,0,40).'...'
                                                : $text)
                                            ."' as a QR code: $@");
                                    my $path = $tmpDir->dirname
                                        . '/qr-' . $qrCount++ . '.png';
                                    open my $fh, '>:raw', $path
                                        or die mkerror(9936,
                                            "failed to open $path: $!");
                                    print $fh $self->_qrPng($matrix);
                                    close $fh;
                                    {   path => $path,
                                        # what _qrPng made of it
                                        px => (scalar(@$matrix) + 2 * $QR_QUIET_ZONE)
                                            * $QR_MODULE_SIZE,
                                    };
                                };
                                # excel scales an image against its natural
                                # size at 96 dpi
                                my $scale = $size / $qr->{px};
                                $worksheet->insert_image($row, $col, $qr->{path}, {
                                    x_scale  => $scale,
                                    y_scale  => $scale,
                                    x_offset => 2,
                                    y_offset => 2,
                                });
                                $rowSize = $size if $size > $rowSize;
                            }
                        }
                        $col++;
                    }
                    # a point is 3/4 of a pixel
                    $worksheet->set_row($row, ($rowSize + 6) * 0.75) if $rowSize;
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
