# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with icon text

package Data::IconText;

use v5.20;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(looks_like_number weaken);

use overload '""' => sub {$_[0]->as_string};

our $VERSION = v0.01;

my %_types = (
    db          => 'Data::TagDB',
    extractor   => 'Data::URIID',
    fii         => 'File::Information',
    store       => 'File::FStore',
);

my %_for_version = (
    v0.01 => {
        default_unicode => 0x2370, # U+2370 APL FUNCTIONAL SYMBOL QUAD QUESTION
        media_type => {
            text  => 0x270D,
            audio => 0x266B,
            video => 0x2707,
            image => 0x1F5BB,
        },
        media_subtype => {
            'application/pdf'                           => 0x1F5BA,
            'application/vnd.oasis.opendocument.text'   => 0x1F5CE,
        },
        special => {
            directory           => 0x1F5C0,
            parent_directory    => 0x2B11,
            regular             => 0x2299,
            regular_not_in_pool => 0x2298,
        },
    },
);

my %_type_to_special = (
    '577c3095-922b-4569-805d-a5df94686b35' => 'directory',
    'e6d6bb07-1a6a-46f6-8c18-5aa6ea24d7cb' => 'regular',
);



sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {for_version => (delete($opts{for_version}) // $VERSION)}, $pkg;
    my $for_version_info = $self->_find_for_version_info;
    my @mimetypes;

    if (defined(my $unicode = delete $opts{unicode})) {
        if (looks_like_number($unicode)) {
            $self->{unicode} //= int($unicode);
        } elsif ($unicode =~ /^U\+([0-9a-fA-F]{4,7})$/) {
            $self->{unicode} //= hex($1);
        } else {
            croak 'Passed unicode value is in wrong format';
        }
    }

    if (defined(my $raw = delete $opts{raw})) {
        croak 'Raw has wrong length' unless length($raw) == 1;
        $self->{unicode} //= ord($raw);
    }

    if (defined(my $for = delete $opts{for})) {
        unless (ref $for) {
            require Data::Identifier;

            $for = Data::Identifier->new(from => $for);
        }

        if ($for->isa('Data::URIID::Base') && !$for->isa('Data::URIID::Result')) {
            $for = $for->as('Data::Identifier');
        }

        if ($for->isa('Data::Identifier')) {
            if (defined(my $db = $opts{db})) {
                my $f = eval { $db->tag_by_id($for) };
                $for = $f if defined $f;
            }
        }

        if ($for->isa('Data::Identifier')) {
            if (defined(my $store = $opts{store})) {
                my $f = eval {$store->query(ise => $for)};
                $for = $f if defined $f;
            }
        }

        if ($for->isa('Data::Identifier')) {
            if (defined(my $fii = $opts{fii})) {
                my $f = eval {$fii->for_identifier($for)};
                $for = $f if defined $f;
            }
        }

        if ($for->isa('Data::Identifier')) {
            if (defined(my $extractor = $opts{extractor})) {
                my $f = $extractor->lookup($for);
                $for = $f if defined $f;
            }
        }

        if ($for->isa('File::FStore::File')) {
            my $v;

            push(@mimetypes, $v) if defined($v = eval {$for->get(properties => 'mediasubtype')});
            $opts{special} //= 'regular';
        } elsif ($for->isa('File::Information::Base')) {
            my $type;
            my $v;

            push(@mimetypes, $v) if defined($v = $for->get('mediatype', default => undef));

            unless (defined($opts{special})) {
                require File::Spec;

                if ($for->get('link_basename', default => '') eq File::Spec->updir) {
                    $opts{special} //= 'parent-directory';
                }
            }

            unless (defined($opts{special})) {
                $type   = $for->get('tagpool_inode_type', default => undef, as => 'uuid');
                $type //= eval { $for->inode->get('tagpool_inode_type', default => undef, as => 'uuid') };

                $opts{special} //= $_type_to_special{$type} if defined $type;
            }
        } elsif ($for->isa('Data::TagDB::Tag')) {
            require Encode;

            my $icontext = $for->icontext(default => undef);
            $self->{unicode} //= ord(Encode::decode('UTF-8' => $icontext)) if defined $icontext;
        } elsif ($for->isa('Data::URIID::Result')) {
            my $icontext = $for->attribute('icon_text', default => undef);
            $self->{unicode} //= ord($icontext) if defined $icontext;
        } else {
            croak 'Invalid object passed for "for"';
        }
    }

    {
        my $v;

        push(@mimetypes, $v)      if defined($v = delete($opts{mediasubtype}));
        push(@mimetypes, $v.'/*') if defined($v = delete($opts{mediatype}));
        push(@mimetypes, $v)      if defined($v = delete($opts{mimetype}));

        foreach my $mimetype (@mimetypes) {
            $mimetype = lc($mimetype);

            $self->{unicode} //= $for_version_info->{media_subtype}{$mimetype};
            $self->{unicode} //= $for_version_info->{media_type}{$1} if $mimetype =~ m#^([a-z]+)/#;

            last if defined $self->{unicode};
        }
    }

    if (defined(my $special = delete $opts{special})) {
        $self->{unicode} //= $for_version_info->{special}{$special =~ s/-/_/gr};
    }

    $self->{unicode} //= $for_version_info->{default_unicode};

    # Attach subobjects:
    $self->attach(map {$_ => delete $opts{$_}} keys(%_types), 'weak');

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub unicode {
    my ($self, @args) = @_;

    croak 'Stray options passed' if scalar @args;

    return $self->{unicode};
}


sub as_string {
    my ($self, @args) = @_;

    croak 'Stray options passed' if scalar @args;

    return chr($self->{unicode});
}


sub for_version {
    my ($self, @args) = @_;

    croak 'Stray options passed' if scalar @args;

    return $self->{for_version};
}


sub as {
    my ($self, $as, %opts) = @_;

    require Data::Identifier::Generate;
    $self->{identifier} //= Data::Identifier::Generate->unicode_character(unicode => $self->{unicode});

    $opts{$_} //= $self->{$_} foreach keys %_types;

    return $self->{identifier}->as($as, %opts);
}


sub ise {
    my ($self, %opts) = @_;

    return ($self->{identifier} // $self->as('Data::Identifier'))->ise(%opts);
}


sub attach {
    my ($self, %opts) = @_;
    my $weak = delete $opts{weak};

    foreach my $key (keys %_types) {
        my $v = delete $opts{$key};
        next unless defined $v;
        croak 'Invalid type for key: '.$key unless eval {$v->isa($_types{$key})};
        $self->{$key} //= $v;
        croak 'Missmatch for key: '.$key unless $self->{$key} == $v;
        weaken($self->{$key}) if $weak;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}

# ---- Private helpers ----
sub _find_for_version_info {
    my ($self) = @_;
    my $for_version = $self->for_version;
    my $ret = $_for_version{$for_version};

    return $ret if defined $ret;

    if ($for_version le $VERSION) {
        foreach my $version (sort {$b cmp $a} keys %_for_version) {
            return $_for_version{$version} if $version le $for_version;
        }
    }

    croak 'Unsupported version given: '.sprintf("v%u.%u", unpack("cc", $for_version));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::IconText - Work with icon text

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Data::IconText;

Allows icon text (single character text icons) to be handled in a nice way.

=head1 METHODS

=head2 new

    my Data::IconText $icontext = Data::IconText->new(unicode => 0x1F981);
    # or:
    my Data::IconText $icontext = Data::IconText->new(raw => 'X');

Creates a new icon text object.

The icon text is tried to calculate from the options in the following order (first one wins):
C<unicode>, C<raw>, C<for>, C<mediasubtype>, C<mediatype>, C<mimetype>, C<special>.
If none is found a fallback is used.

The following options are supported.

=over

=item C<unicode>

The unicode value (e.g. C<0x1F981>). May also be a string in standard format (e.g. C<'U+1F981'>).

=item C<raw>

The character as a raw perl string. Must be exactly one character long.

=item C<for>

An object to find the icon text for.
Currently supported are objects of the following packages:
L<File::FStore::File>,
L<File::Information::Base>,
L<Data::TagDB::Tag>,
L<Data::URIID::Base>,
L<Data::Identifier>.

If the value is a plain string it is tried to be converted to a L<Data::Identifier> first.

If a L<Data::Identifier> is passed, a lookup is performed using the passed subobjects.

=item C<mediasubtype>

The media subtype (e.g. C<audio/flac>). Only values assigned by IANA are valid.

=item C<mediatype>

The media type (e.g. C<audio>). Only values assigned by IANA are valid.

=item C<mimetype>

A low quality value that I<looks like> a mediasubtype (e.g. provided via HTTP's C<Content-type> or by type guessing modules).

=item C<special>

One of: C<directory>, C<parent-directory>, C<regular>, C<regular-not-in-pool>.

=item C<for_version>

The version of this module to use the rules for calculation of the icon text from.
Defaults to the current version of this module.
If a given version is not supported, this method C<die>s.

=back

Additionally subobjects can be attached:

=over

=item C<db>

A L<Data::TagDB> object.

=item C<extractor>

A L<Data::URIID> object.

=item C<fii>

A L<File::Information> object.

=item C<store>

A L<File::FStore> object.

=item C<weak>

Marks the value for all subobjects as weak.
If only a specific one needs needs to be weaken use L</attach>.

=back

=head2 unicode

    my $unicode = $icontext->unicode;

This returns the numeric unicode value (e.g. 0x1F981) of the icon text.

=head2 as_string

    my $str = $icontext->as_string;

Gets the icon text as a perl string.

=head2 for_version

    my $version = $icontext->for_version;

The version of this module from which the rules where used.

=head2 as

    my $xxx = $icontext->as($as, %opts);

This is a proxy for L<Data::Identifier/as>.

This method automatically adds all attached subobjects (if not given via C<%opts>).

=head2 ise

    my $ise = $icontext->ise(%opts);

THis is a proxy for L<Data::Identifier/ise>.

=head2 attach

    $icontext->attach(key => $obj, ...);
    # or:
    $icontext->attach(key => $obj, ..., weak => 1);

Attaches objects of the given type.
Takes the same list of objects as L</new>.

If an object is allready attached for the given key this method C<die>s unless the object is actually the same.

If C<weak> is set to a true value the object reference becomes weak.

Returns itself.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
