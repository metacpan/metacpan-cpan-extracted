# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Barcode;

use strict;
use warnings;

use Carp;
use Scalar::Util qw(weaken);

our $VERSION = v0.15;

use parent 'Data::URIID::Base';

use constant {
    TYPE_UNKNOWN    => ':unknown',
    TYPE_OTHER      => ':other',
    TYPE_QRCODE     => 'qrcode',
    TYPE_EAN13      => 'ean-13',
    TYPE_EAN8       => 'ean-8',
};



sub sheet {
    my ($pkg, %opts) = @_;
    my $from     = delete $opts{from};
    my $filename = delete $opts{filename};
    my $template = delete $opts{template};
    my $values   = delete $opts{values};
    my %pass_opts;
    my @res;
    my $done;

    foreach my $key (qw(extractor type)) {
        $pass_opts{$key} = delete $opts{$key} // next;;
    }

    if (!defined($from) && defined($values)) {
        @res = map {{barcode => $_, quality => 0.001}}
               map {$pkg->new(%pass_opts, ref($_) ? (from => $_) : (data => sprintf($template // '%s', $_)))}
               @{$values};
               $done = 1;
    } elsif (!defined($from) && defined($filename)) {
        require Image::Magick;
        $from = Image::Magick->new();
        $from->Read($filename) && croak 'Cannot read file';
    }

    croak 'Stray options passed' if scalar keys %opts;

    unless ($done) {
        croak 'No from given' unless defined $from;

        if ($from->isa('Image::Magick')) {
            require Barcode::ZBar;

            my $raw = $from->ImageToBlob(magick => 'GRAY', depth => 8);
            my ($col, $rows) = $from->Get(qw(columns rows));
            my $scanner = Barcode::ZBar::ImageScanner->new();

            $from = Barcode::ZBar::Image->new();
            $from->set_format('Y800');
            $from->set_size($col, $rows);
            $from->set_data($raw);

            $scanner->parse_config("enable");

            $scanner->scan_image($from);
        }

        if ($from->isa('Barcode::ZBar::Image')) {
            my $max_quality;

            foreach my $symbol ($from->get_symbols()) {
                my $raw_type = $symbol->get_type;
                my $raw_data = $symbol->get_data;
                my $raw_quality = $symbol->get_quality;
                my $type;

                if ($raw_type eq $symbol->QRCODE) {
                    $type = TYPE_QRCODE;
                } elsif ($raw_type eq $symbol->EAN13) {
                    $type = TYPE_EAN13;
                } elsif ($raw_type eq $symbol->EAN8) {
                    $type = TYPE_EAN8;
                }

                $type //= TYPE_OTHER;

                $max_quality = $raw_quality if !defined($max_quality) || $max_quality < $raw_quality;
                push(@res, {
                        barcode => $pkg->new(%pass_opts, type => $type, data => $raw_data),
                        _raw_ => $symbol,
                    });
            }

            foreach my $res (@res) {
                my $symbol = delete $res->{_raw_};
                $res->{quality} = $symbol->get_quality / $max_quality;
            }
        } else {
            croak 'From of invalid/unsupported type';
        }
    }

    if (wantarray) {
        return map {$_->{barcode}} @res;
    } else {
        my $max_length;

        croak 'No code found' unless scalar @res;

        foreach my $res (@res) {
            my $barcode = $res->{barcode};
            my $length = length($barcode->data);
            $max_length = $length if !defined($max_length) || $max_length < $length;
        }

        foreach my $res (@res) {
            my $barcode = $res->{barcode};
            $res->{quality} *= $barcode->_quality_by_type * (length($barcode->data) / $max_length);
        }

        return (sort {$b->{quality} <=> $a->{quality}} @res)[0]{barcode};
    }
}


sub new {
    my ($pkg, %opts) = @_;
    my __PACKAGE__ $self;

    if (defined(my $from = delete($opts{from}))) {
        $self = eval {$pkg->sheet(from => $from)};
        return $self if defined $self;

        if (eval {$from->isa('Data::URIID::Base')}) {
            $opts{extractor} //= $from->extractor(default => undef);
        }

        if (eval {$from->isa('Data::URIID::Result')}) {
            $opts{data} //= $from->url->as_string;
            $opts{type} //= TYPE_QRCODE;
        } elsif (eval {$from->isa('Data::URIID::Base')}) {
            $opts{data} //= $from->ise;
            $opts{type} //= TYPE_QRCODE;
        } elsif (eval {$from->isa('Data::Identifier')}) {
            $opts{data} //= $from->ise;
            $opts{type} //= TYPE_QRCODE;
        } elsif (eval {$from->isa('URI')}) {
            $opts{data} //= $from->as_string;
            $opts{type} //= TYPE_QRCODE;
        } else {
            croak 'Unsupported/invalid from type';
        }
    }

    croak 'No type given' unless defined $opts{type};
    croak 'No data given' unless defined $opts{data};

    weaken($opts{extractor});

    $self = bless \%opts, $pkg;

    return $self;
}


sub data {
    my ($self, %opts) = @_;
    delete $opts{default};
    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;

    return $self->{data};
}


sub type {
    my ($self, %opts) = @_;
    delete $opts{default};
    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;

    return $self->{type};
}


sub has_type {
    my ($self, $type, %opts) = @_;
    delete $opts{default};
    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;
    croak 'No type passed' unless defined $type;

    return $self->{type} eq $type;
}


sub render {
    my ($self, %opts) = @_;
    my $filename = delete $opts{filename};
    my $success;

    croak 'Stray options passed' if scalar keys %opts;

    eval {
        if ($self->has_type(TYPE_QRCODE)) {
            require Imager::QRCode;

            my $qrcode = Imager::QRCode->new(level => 'H');
            my $img = $qrcode->plot($self->data);
            $img->write(file => $filename, tyoe => 'png');
            $success = 1;
        }
    };

    unless ($success) {
        eval {
            require GD::Barcode;

            my $type;

            if ($self->has_type(TYPE_QRCODE)) {
                $type = 'QRcode';
            } elsif ($self->has_type(TYPE_EAN13)) {
                $type = 'EAN13';
            } elsif ($self->has_type(TYPE_EAN8)) {
                $type = 'EAN8';
            }

            if (defined $type) {
                my $code = GD::Barcode->new($type => $self->data);
                my $plot = $code->plot;
                my ($width, $height) = $plot->getBounds();
                my $image = GD::Image->new($width * 3, $height * 3, 0);

                $image->copyResized($plot, 0, 0, 0, 0, $width * 3, $height * 3, $width, $height);

                open(my $out, '>', $filename) or croak $!;
                $out->binmode;
                $out->print($image->png);
                $success = 1;
            }
        };
    }

    unless ($success) {
        croak 'Code not supported';
    }
}


# --- Overrides for Data::URIID::Base ---
sub ise {
    my ($self, @args) = @_;

    unless (exists $self->{ise}) {
        $self->{result} //= eval {$self->_as_lookup([$self])};

        if (defined $self->{result}) {
            $self->{ise} = $self->{result}->ise;
        } else {
            # we have no extractor, still try a few basic things:
            if ($self->has_type(TYPE_QRCODE)) {
                my $data = $self->data;

                if ($data =~ /^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/ || $data =~ /^[1-3](?:\.(?:0|[1-9][0-9]*))+$/) {
                    $self->{ise} = lc($data);
                } elsif ($data =~ m#^https://uriid\.org/#) {
                    $self->{ise} = eval {Data::Identifier->new(ise => $data)->ise};
                }
            }
        }
    }

    return $self->SUPER::ise(@args);
}

sub displayname {
    my ($self, %args) = @_;

    unless (exists $self->{displayname}) {
        $self->{displayname} = undef; # break any loops.

        eval { $self->ise(%args) }; # preload objects.

        $self->{displayname} //= $self->{result}->displayname(%args) if defined $self->{result};
        $self->{displayname} //= $self->as('Data::Identifier')->displayname(%args) if defined $self->{ise};
    }

    return $self->{displayname} if defined $self->{displayname};

    return $self->SUPER::displayname(%args);
}

# ---- Private helpers ----

sub _quality_by_type {
    my ($self) = @_;

    return 1 if $self->has_type(TYPE_QRCODE);
    return 0.01;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Barcode - Extractor for identifiers from URIs

=head1 VERSION

version v0.15

=head1 SYNOPSIS

    use Data::URIID::Barcode;

    my Data::URIID::Barcode $barcode = Data::URIID::Barcode->new(type => ..., data => ..., [ %opts ] );
    # or:
    my Data::URIID::Barcode $barcode = Data::URIID::Barcode->new(from => ..., [ %opts ] );

This module represents a single barcode.

This package inherits from L<Data::URIID::Base>.

=head1 METHODS

=head2 sheet

    my @barcodes = Data::URIID::Barcode->sheet(%opts);
    # or:
    my $barcode  = Data::URIID::Barcode->sheet(%opts);

    # e.g.:
    my @barcodes = Data::URIID::Barcode->sheet(filename => 'bla.jpg');
    # or:
    my @barcodes = Data::URIID::Barcode->sheet(type => Data::URIID::Barcode->TYPE_QRCODE, template => 'IDX-%03u', values => [0 .. 9]);

Creates a set of barcode objects from a sheet.

When called in scalar context returns the best result (best for a metric not further defined, which may also change in later versions)
or C<die>s if none was found.

B<Experimental:>
This method is currently experimental. It might change at any time.

The following options are supported:

=over

=item C<filename>

A file to read from.

=item C<from>

A perl object to use.
If given C<values> must be C<undef>.

=item C<values>

A list (arrayref) of values to be used as data barcodes to be generated.
If given C<from> must be C<undef>.

=item C<template>

A template (see L<perlfunc/sprintf>) that is applied to each value in C<values>.

Defaults to no transformation.
If defined, must not be used with values that are references.

=back

=head2 new

    my Data::URIID::Barcode $barcode = Data::URIID::Barcode->new(type => ..., data => ..., [ %opts ] );
    # or:
    my Data::URIID::Barcode $barcode = Data::URIID::Barcode->new(from => ..., [ %opts ] );

This method creates a new barcode object.

The following options are supported:

=over

=item C<data>

The raw data of the barcode.

=item C<extractor>

optionally, an instance of L<Data::URIID>.

=item C<from>

optionally, an instance of another object to read the values from.
Depending on the given object the non-optional values might become optional.

Currently the following types are supported:
L<Data::URIID::Base>,
L<Data::Identifier>,
L<URI>.
Other types might be supported as well.

=item C<type>

The type of the barcode. One of C<TYPE_*>.
Future versions of this module might improve this definition.

=back

=head2 data

    my $data = $barcode->data;

Returns the data of the barcode.

The returned value might differ from the value passed to L</new> as it might have been normalised, decoded (character set), or otherwise altered.

No options are supported. However the options C<default>, and C<no_defaults> are ignored.

=head2 type

    my $type = $barcode->type;

Returns the type of the barcode.

The returned value might differ from the value passed to L</new> as it might have been normalised, replaced with a cached reference, or otherwise altered.

No options are supported. However the options C<default>, and C<no_defaults> are ignored.

See L</has_type> for a more convenient method.

=head2 has_type

    my $bool = $barcode->has_type(Data::URIID::Barcode->TYPE_*);

Returns whether or not this barcode is of the given type.

No options are supported. However the options C<default>, and C<no_defaults> are ignored.

=head2 render

    $barcode->render(filename => ...);

Render the barcode as a image file.

B<Experimental:>
This method is experimental. It may change completly or may be removed on future versions.

B<Note:>
Currently this method exports as PNG. Later versions might support other formats.

=head1 TYPES

This module supports a number of types of barcodes.

B<Note:>
This module does not define the type or value the C<TYPE_*> constants have.
Future versions of this module might change this at any release.
Always use the type constants.

=head2 TYPE_UNKNOWN

The type of the barcode is unknown.
This might be used if e.g. the scanner software does not tell.
However this limits the set of features this module can provide.

=head2 TYPE_OTHER

The type of barcode is known, but not supported by this module.
Future versions of this module might implement the given type.

=head2 TYPE_QRCODE

A QR-Code.

=head2 TYPE_EAN13

A EAN-13 code commonly found on products.

=head2 TYPE_EAN8

A EAN-8 code commonly found on products in small packages.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
