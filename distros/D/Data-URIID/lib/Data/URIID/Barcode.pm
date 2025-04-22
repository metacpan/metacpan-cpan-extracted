# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Barcode;

use v5.16;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(weaken);

our $VERSION = v0.16;

use parent 'Data::URIID::Base';

use constant {map {$_ => []} qw(TYPE_UNKNOWN TYPE_OTHER TYPE_QRCODE TYPE_EAN13 TYPE_EAN8)};

my %_type_info = (
    TYPE_UNKNOWN()  => {
        type    => TYPE_UNKNOWN,
        special => 1,
    },
    TYPE_OTHER()    => {
        type    => TYPE_OTHER,
        special => 1,
    },
    TYPE_QRCODE()   => {
        type    => TYPE_QRCODE,
        aliases => [qw(qrcode qr-code)],
    },
    TYPE_EAN13()    => {
        type    => TYPE_EAN13,
        aliases => [qw(ean13 ean-13)],
    },
    TYPE_EAN8()     => {
        type    => TYPE_EAN8,
        aliases => [qw(ean8 ean-8)],
    },
);



sub sheet {
    my ($pkg, %opts) = @_;
    my $from        = delete $opts{from};
    my $filename    = delete $opts{filename};
    my $template    = delete $opts{template};
    my $values      = delete $opts{values};
    my $filter_type = delete $opts{filter_type};
    my $filter_data = delete $opts{filter_data};
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

    if (defined $filter_type) {
        @res = grep {$_->{barcode}->has_type($filter_type)} @res;
    }

    if (defined $filter_data) {
        if (ref($filter_data) eq 'CODE') {
            @res = grep {$filter_data->($_->{barcode}->{data})} @res;
        } else {
            @res = grep {$_->{barcode}->{data} =~ $filter_data} @res;
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

    if (ref($type) && !exists $_type_info{$type}) {
        foreach my $t (@{$type}) {
            return 1 if $self->{type} == $t;
        }
    }

    return $self->{type} == $type;
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
            $img->write(file => $filename, type => 'png');
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


sub type_info {
    my ($self, @args) = @_;
    state $aliases;
    my @ret;

    unless (defined $aliases) {
        $aliases = {};
        foreach my $info (values %_type_info) {
            my $type = $info->{type};
            my $list = $info->{aliases} //= [];
            $aliases->{fc($_)} = $type foreach @{$list};

            $info->{special} //= undef;
        }
    }

    if (!scalar(@args) && ref($self)) {
        @args = ($self->type);
    }

    if (!scalar(@args)) {
        @args = keys %_type_info;
    }

    foreach my $arg (@args) {
        my $info = $_type_info{$arg} // $aliases->{fc($arg)} // croak 'No such type: '.$arg;
        push(@ret, {%{$info}});
    }

    if (wantarray) {
        return @ret;
    } else {
        croak 'Wrong number of results for scalar context' unless scalar(@ret) == 1;
        return $ret[0];
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

version v0.16

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

=item C<filter_type>

Filters the barcodes based on their type.
This takes the same values as L</has_type>.

This value might also be used to hint any scanners.

=item C<filter_data>

Filters the barcodes based on their data.
This is a regex or a function (coderef).

If it's a function the data of the barcode is passed as first argument.
All other arguments are undefined by this version and later versions may define values for them.

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

=item C<type>

The type of the barcode to be used with C<values>.

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
    # or:
    my $bool = $barcode->has_type([Data::URIID::Barcode->TYPE_*, ...]);

Returns whether or not this barcode is of the given type.

If the type is given as an arrayref then it is checked if the type matches any of the elements.

No options are supported. However the options C<default>, and C<no_defaults> are ignored.

=head2 render

    $barcode->render(filename => ...);

Render the barcode as a image file.

B<Experimental:>
This method is experimental. It may change completly or may be removed on future versions.

B<Note:>
Currently this method exports as PNG. Later versions might support other formats.

=head2 type_info

    my @info    = Data::URIID::Barcode->type_info;
    # or:
    my @info    = Data::URIID::Barcode->type_info($type0, $type1, ...);
    # or:
    my $info    = Data::URIID::Barcode->type_info($type);
    # or:
    my $info    = $barcode->type_info;

Returns information on a barcode type.
If called in list context returns a list.
If called in scalar context returns the only one result (or C<die>s if there is not exactly one result).

Takes a list of C<TYPE_*> constants as arguments.
If the provided value is not a C<TYPE_*> constant the value is checked against an internal alias list.
If no types are given, returns information for all known types (if called on the package) or
for the type of the current barcode (if called on an instance).

Each element returned is an hash reference containing the following keys:

=over

=item C<type>

The value of the C<TYPE_*> constant.

=item C<special>

Whether the type is a special one (not a real barcode type).
Such include C<TYPE_OTHER>, and C<TYPE_UNKNOWN>.
Later versions of this module might add more special types.

=item C<aliases>

An arrayref with alias names for the given type.
B<Note:> This list might be empty.

=back

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
