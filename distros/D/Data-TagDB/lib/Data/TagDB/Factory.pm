# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Factory;

use v5.10;
use strict;
use warnings;

use Carp;
use Encode;

use Data::Identifier::Generate;

use parent 'Data::TagDB::WeakBaseObject';

use constant NS_DATE => 'fc43fbba-b959-4882-b4c8-90a288b7d416';
use constant RE_UUID => qr/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/;

our $VERSION = v0.09;



sub db {
    my ($self) = @_;
    return $self->{db};
}


sub cache {
    my ($self) = @_;
    return $self->{cache};
}


sub wk {
    my ($self) = @_;
    return $self->{wk} //= $self->db->wk;
}


sub create_namespace {
    my ($self, $ns, $tagname) = @_;
    my Data::TagDB::Cache $cache = $self->cache;
    my Data::TagDB $db;
    my Data::TagDB::WellKnown $wk;
    my Data::TagDB::Tag $tag;

    $tag = $cache->_get_by_key(__PACKAGE__, ns => $ns);
    return $tag if defined $tag;

    $db = $self->db;
    $wk = $self->wk;

    $tag = $db->create_tag([$wk->uuid => $ns], [$wk->tagname(1) => $tagname]);
    $db->create_relation(tag => $tag, relation => $wk->has_type(1), related => $wk->namespace(1));

    $cache->_add_by_key(__PACKAGE__, ns => $ns => $tag);

    return $tag;
}


sub create_generator {
    my ($self, %opts) = @_;
    my Data::TagDB::Cache $cache = $self->cache;
    my Data::TagDB $db;
    my Data::TagDB::WellKnown $wk;
    my Data::TagDB::Tag $tag;
    my $uuid = $opts{uuid} || croak 'No UUID given for this generator. Currently all generators require an UUID.';

    $tag = $cache->_get_by_key(__PACKAGE__, gen => $uuid);
    return $tag if defined $tag;

    $db = $self->db;
    $wk = $self->wk;

    $tag = $db->create_tag([$wk->uuid => $uuid], [$wk->tagname(1) => $opts{tagname}]);
    $db->create_relation(tag => $tag, relation => $wk->has_type(1), related => $wk->generator(1));

    if (defined $opts{ns}) {
        my Data::TagDB::Tag $ns = eval {$opts{ns}->isa('Data::TagDB::Tag')} ? $opts{ns} : $self->create_namespace($opts{ns});
        $db->create_relation(tag => $tag, relation => $wk->using_namespace(1), related => $ns);
        $tag->attribute(using_namespace => set => $ns);
    }

    if (defined $opts{for_type}) {
        $db->create_relation(tag => $tag, relation => $wk->for_type(1), related => $opts{for_type});
        $tag->attribute(for_type => set => $opts{for_type});
    }

    foreach my $key (qw(style copy_names)) {
        if (defined $opts{$key}) {
            $tag->attribute('generator_'.$key => set => $opts{$key});
        }
    }

    $cache->_add_by_key(__PACKAGE__, gen => $uuid => $tag);

    return $tag;
}


sub create_wikidata {
    my ($self, $qid) = @_;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $self->wk;
    my Data::TagDB::Tag $ns = $self->create_namespace('9e10aca7-4a99-43ac-9368-6cbfa43636df' => 'Wikidata-namespace');
    my ($type) = $qid =~ /^([QPL])[1-9][0-9]*$/;
    my %opts;

    if ($type eq 'Q') {
        $opts{generator} = $self->create_generator(
            uuid        => '710412ba-dafd-4eca-91eb-4501e717af8f',
            tagname     => 'Wikidata-item-generator',
            ns          => $ns,
            for_type    => $db->create_tag([$wk->uuid => 'b1dfb9f7-1c56-4c33-8a0b-a3e9a9c9f707'], [$wk->tagname => 'Wikidata-item']),
            style       => 'id-based',
        );
    } elsif ($type eq 'P') {
        $opts{generator} = $self->create_generator(
            uuid        => '8a3c765a-6b86-49ab-a369-2ef6ce761308',
            tagname     => 'Wikidata-property-generator',
            ns          => $ns,
            for_type    => $db->create_tag([$wk->uuid => 'cb05df0a-e949-42ef-9f59-66df784b0410'], [$wk->tagname => 'Wikidata-property']),
            style       => 'id-based',
        );
    } elsif ($type eq 'L') {
        # TODO: Needs generator definition. However basic generation works without.
    } else {
        croak 'Unsupported qid: '.$qid;
    }

    return $self->generate(%opts, ns => $ns, style => 'id-based', request => $qid);
}


sub create_integer {
    my ($self, $int) = @_;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $self->wk;
    my Data::TagDB::Tag $ns = $self->create_namespace('5dd8ddbb-13a8-4d6c-9264-36e6dd6f9c99' => 'integer-namespace');
    my %opts;

    croak 'Invalid integer: '.$int unless $int =~ /^[\+\-]?[0-9]+$/;
    $int = int($int);

    if ($int > 0) {
        $opts{generator} = $self->create_generator(
            uuid        => '53863a15-68d4-448d-bd69-a9b19289a191',
            tagname     => 'unsigned-integer-generator',
            ns          => $ns,
            for_type    => $db->create_tag([$wk->uuid => 'dea3782c-6bcb-4ce9-8a39-f8dab399d75d'], [$wk->tagname => 'unsigned-integer']),
            style       => 'integer-based',
        );
    } else {
        $opts{generator} = $self->create_generator(
            uuid        => 'e8aa9e01-8d37-4b4b-8899-42ca0a2a906f',
            tagname     => 'signed-integer-generator',
            ns          => $ns,
            for_type    => $db->create_tag([$wk->uuid => 'd191954d-b30d-4d3b-94ea-babadb2f2901'], [$wk->tagname => 'signed-integer']),
            style       => 'integer-based',
        );
    }

    {
        my Data::TagDB::Tag $tag = $self->generate(%opts, ns => $ns, style => 'integer-based', request => $int);

        unless ($int & 1) {
            $db->create_relation(tag => $tag, relation => $wk->has_prime_factor(1), related => $wk->two(1));
        }

        return $tag;
    }
}


sub create_character {
    my $self;
    my %data;
    my $unicode_cp;
    my $unicode_cp_str;

    if (scalar(@_) == 2) {
        ($self, $data{unicode}) = @_;
    } else {
        ($self, %data) = @_;
    }

    if (defined $data{unicode}) {
        if ($data{unicode} =~ /^[Uu]\+([0-9a-fA-F]+)$/) {
            $unicode_cp = hex($1);
        } else {
            $unicode_cp = int($data{unicode});
        }
    } elsif (defined $data{ascii}) {
        $unicode_cp = int($data{ascii});
        croak 'US-ASCII character out of range: '.$unicode_cp if $unicode_cp > 0x7F;
    } elsif (defined $data{raw}) {
        croak 'Raw value is not exactly one character long' unless length($data{raw}) == 1;
        $unicode_cp = ord($data{raw});
    }

    croak 'Unicode character out of range: '.$unicode_cp if $unicode_cp < 0 || $unicode_cp > 0x10FFFF;

    $unicode_cp_str = sprintf('U+%04X', $unicode_cp);

    {
        my Data::TagDB $db = $self->db;
        my Data::TagDB::WellKnown $wk = $self->wk;
        my Data::TagDB::Tag $asi = $wk->also_shares_identifier;
        my Data::TagDB::Tag $ns = $self->create_namespace('132aa723-a373-48bf-a88d-69f1e00f00cf' => 'unicode-character-namespace');
        my Data::TagDB::Tag $tag;
        my %opts;

        require charnames;

        $opts{generator} = $self->create_generator(
            uuid        => 'd74f8c35-bcb8-465c-9a77-01010e8ed25c',
            tagname     => 'unicode-character-generator',
            ns          => $ns,
            for_type    => $db->create_tag([$wk->uuid => '5ee5f216-5e7a-443b-a234-db5c032d4710'], [$wk->tagname => 'unicode-character']),
            style       => 'id-based',
        );

        $tag = $self->generate(%opts, ns => $ns, style => 'id-based', request => $unicode_cp_str);

        $db->create_metadata(tag => $tag, relation => $asi, type => $wk->unicode_code_point(1), data_raw => $unicode_cp_str);
        if ($unicode_cp <= 0x7F) {
            $db->create_metadata(tag => $tag, relation => $asi, type => $wk->ascii_code_point(1), data_raw => $unicode_cp);
        }
        if ($unicode_cp > 0x20 && $unicode_cp < 0x7F) {
            $db->create_metadata(tag => $tag, relation => $asi, type => $wk->tagname(1), data_raw => chr($unicode_cp));
        }
        $db->create_metadata(tag => $tag, relation => $asi, type => $wk->tagname(1), data_raw => charnames::viacode($unicode_cp));

        return $tag;
    }
}


sub create_colour {
    my ($self, $colour) = @_;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $self->wk;
    my Data::TagDB::Tag $ns = $self->create_namespace('88d3944f-a13b-4e35-89eb-e3c1fbe53e76');
    my Data::TagDB::Tag $tag;
    my $rgb;
    my %opts;

    if (ref $colour) {
        # If it's a ref but not blessed we don't care if it fails
        if ($colour->isa('Data::URIID::Colour')) {
            $colour = $colour->rgb;
        } elsif ($colour->isa('Color::Library::Color')) {
            $colour = $colour->css;
        } elsif ($colour->isa('Graphics::Color::RGB')) {
            $colour = $colour->as_css_hex;
        } else {
            croak 'Unsupported type';
        }
    }

    # Check basic format first, then normalise
    croak 'Colour is in invalid format' unless $colour =~ /^#[0-9a-fA-F]+$/;

    # Normalise
    $colour = lc($colour);
    $colour = "#$1$1$2$2$3$3" if $colour =~ /^#([0-9a-f])([0-9a-f])([0-9a-f])$/;
    $rgb    = uc($colour) if $colour =~ /^#[0-9a-f]{6}$/;
    $colour = sprintf('#%s%s%s', $1 x 6, $2 x 6, $3 x 6) if $colour =~ /^#([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/;

    # And do a funal check
    croak 'Invalid colour value' unless $colour =~ /^#[0-9a-f]{36}$/;

    $opts{generator} = $self->create_generator(
        uuid        => '55febcc4-6655-4397-ae3d-2353b5856b34',
        tagname     => 'rgb-colour-generator',
        ns          => $ns,
        for_type    => $db->create_tag([$wk->uuid => '5f281982-f9b8-4203-8c62-fb951a5989cc'], [$wk->tagname => 'rgb-colour']),
        style       => 'id-based',
    );

    $tag = $self->generate(%opts, ns => $ns, style => 'id-based', input => $colour);

    $db->create_metadata(tag => $tag, relation => $wk->has_colour_value(1), data_raw => $rgb) if defined $rgb;

    return $tag;
}


sub create_date {
    my ($self, $in, %opts) = @_;
    my ($year, $month, $day);
    state $precision_to_int = {year => 0, month => 1, day => 2};
    state $int_to_precision = {map {$precision_to_int->{$_} => $_} keys %{$precision_to_int}};
    my $min_precision = $precision_to_int->{$opts{min_precision} || $opts{precision} || 'year'};
    my $max_precision = $precision_to_int->{$opts{max_precision} || $opts{precision} || 'day'};
    my $req;

    if (!defined($min_precision) || !defined($max_precision) || $max_precision < $min_precision) {
        croak 'Invalid precision option';
    }

    if (ref($in)) {
        if (eval {$in->can('epoch')}) {
            $in = $in->epoch;
        } else {
            return $self->create_date(scalar($in->()), %opts);
        }
    }

    ($year, $month, $day) = $in =~ /^([12][0-9]{3})(?:-([01][0-9])(?:-([0-3][0-9]))?)?Z$/;

    unless (length($year // '') == 4) {
        if ($in eq 'now' || $in eq 'today') {
            $in = time();
        } elsif ($in =~ /^[1-9][0-9]*$/) {
            $in = int($in);
            if ($in > 32503680000) {
                croak 'Unlikely far date given. Likely miliseconds are passed as seconds?';
            }
        } else {
            croak 'Invalid format';
        }

        (undef,undef,undef,$day,$month,$year) = gmtime($in);
        $year  += 1900;
        $month += 1;
    }

    foreach my $entry ($year, $month, $day) {
        $entry = int($entry // 0);
    }

    croak 'Invalid year'  if $year  && ($year  < 1583 || $year  > 9999);
    croak 'Invalid month' if $month && ($month < 1    || $month > 12);
    croak 'Invalid day'   if $day   && ($day   < 1    || $day   > 31);

    $month  = 0 unless $year;
    $day    = 0 unless $month;

    for (my $precision = $max_precision; !defined($req) && $precision >= $min_precision; $precision--) {
        my $precision_name = $int_to_precision->{$precision};
        if ($precision_name eq 'day' && $day) {
            $req = sprintf('%04u-%02u-%02uZ', $year, $month, $day);
        } elsif ($precision_name eq 'month' && $month) {
            $req = sprintf('%04u-%02uZ', $year, $month);
        } elsif ($precision_name eq 'year' && $year) {
            $req = sprintf('%04uZ', $year);
        }
    }

    croak 'Cannot generate request at required precision' unless defined $req;;

    return $self->generate(ns => NS_DATE, style => 'date', input => $req, request => $req,
        generator => $self->create_generator(
            uuid        => '97b7f241-e1c5-4f02-ae3c-8e31e501e1dc',
            tagname     => 'gregorian-date-generator',
            ns          => NS_DATE,
            style       => 'date',
            for_type    => $self->db->create_tag([$self->wk->uuid => 'a414c87d-efe0-4376-8eae-66aefa78cf92'], [$self->wk->tagname => 'gregorian-date']),
        ),
    );
}


sub generate {
    my ($self, %opts) = @_;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $self->wk;
    my Data::TagDB::Tag $tagname = $wk->tagname(1);
    my Data::TagDB::Tag $tag;
    my Data::TagDB::Tag $gen_tag = $opts{generator};
    my Data::TagDB::Tag $ns_tag;
    my $ns_uuid;
    my $input = $opts{input};
    my $request = $opts{request};
    my @tagnames = ($opts{tagname});
    my $style = $opts{style};
    my $uuid;

    if (defined $opts{ns}) {
        if (eval {$opts{ns}->isa('Data::TagDB::Tag')}) {
            $ns_tag = $opts{ns};
        } else {
            $ns_tag = $self->create_namespace($opts{ns});
            $ns_uuid = $opts{ns};
        }
    }

    if (!defined($ns_uuid) && !defined($ns_tag) && defined($gen_tag)) {
        $ns_tag = $gen_tag->attribute('using_namespace');
    }

    if (!defined($ns_uuid) && defined($ns_tag)) {
        $ns_uuid = $ns_tag->uuid;
    }

    if (defined $gen_tag) {
        $style            ||= $gen_tag->attribute('generator_style');
        $opts{copy_names} ||= $gen_tag->attribute('generator_copy_names');
    }

    croak 'No namespace provided (directly or indirectly)' unless defined $ns_uuid;

    croak 'No style defined' unless defined $style;

    if (defined($request) && !defined($input)) {
        # mimetype
        # date
        # gte
        # gte-simple
        if ($style eq 'name-based') {
            $input = encode('UTF-8', $request);
            push(@tagnames, $request);
        } elsif ($style eq 'id-based') {
            my $name;

            if (($input, $name) = $request =~ /^(#?[a-zA-Z0-9\-\.\+]+) (.+)$/) {
                # noop
            } elsif (($input) = $request =~ /^(#?[a-zA-Z0-9\-\.\+]+)$/) {
                $name = undef;
            } else {
                croak 'Invalid format, expected: "id name", or "id", got: '.$request;
            }

            $input = lc($input);
        } elsif ($style eq 'integer-based') {
            croak 'Invalid integer' unless $request =~ /^-?[0-9]+$/;
            $input = int($request);
        } elsif ($style eq 'tag-based') {
            unless (ref $request) {
                croak 'Invalid UUID: '.$request unless $request =~ RE_UUID;
                $request = $db->create_tag([$wk->uuid => $request]);
            }

            $input = $request->uuid;

            if ($opts{copy_names}) {
                push(@tagnames, $db->metadata(tag => $request, relation => $wk->also_shares_identifier, type => $tagname)->collect('data_raw'));
            }

            $request = $input;
        } elsif ($style eq 'tagcombiner') {
            my @uuids;

            unless (ref $request) {
                $request = [split /--/, $request];
            }

            foreach my $entry (@{$request}) {
                $entry = $db->create_tag([$wk->uuid => $entry]) unless ref $entry;
            }

            @uuids = sort map {$_->uuid} @{$request};

            $input = join(',', @uuids);
            $request = join('--', @uuids);
        } else {
            croak 'Unsupported generator style: '.$style;
        }
    }

    croak 'No input' unless defined $input;

    $uuid = Data::Identifier::Generate->generic(namespace => $ns_uuid, input => $input)->uuid;

    $tag = $db->create_tag([$wk->uuid => $uuid], [(map {$tagname => $_} @tagnames)]);

    if (defined $request) {
        $db->create_metadata(tag => $tag, relation => $wk->generator_request(1), data_raw => $request);
    }

    if ($gen_tag) {
        my Data::TagDB::Tag $for_type = $gen_tag->attribute('for_type');

        $db->create_relation(tag => $tag, relation => $wk->generated_by(1), related => $gen_tag);
        $db->create_relation(tag => $tag, relation => $wk->has_type(1), related => $for_type) if defined $for_type;
    }

    return $tag;
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;

    $opts{cache} //= $opts{db}->create_cache;

    return $pkg->SUPER::_new(%opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Factory - Work with Tag databases

=head1 VERSION

version v0.09

=head1 SYNOPSIS

    use Data::TagDB;

    my Data::TagDB::Factory $factory = $db->factory;

This module is used to create tags from other data. It is useful specifically when importing data
or creating standard objects.

B<Note:> This module requires write access to the database. In addition to the requested tags it may
inject some well known tags (such as for types).

=head1 METHODS

=head2 db

    my Data::TagDB $db = $factory->db;

Returns the current L<Data::TagDB> object.

=head2 cache

    my Data::TagDB::Cache $cache = $factory->cache;

Returns the L<Data::TagDB::Cache> object used by this factory.

=head2 wk

    my Data::TagDB::WellKnown $wk = $factory->wk;

This is a proxy for L<Data::TagDB/wk>.

=head2 create_namespace

    my Data::TagDB::Tag $tag = $factory->create_namespace($uuid, $tagname);

This creates a new namespace tag. Optionally C<$tagname> can be given to set a tagname.

=head2 create_generator

    my Data::TagDB::Tag $tag = $factory->create_generator(%opts);

Creates a generator tag.

The following options are supported:

=over

=item C<uuid> (required)

The UUID of the generator.

=item C<tagname>

A tagname for the generator.

=item C<ns>

The namespace used by the generator. Can be a UUID or a L<Data::TagDB::Tag>.

=item C<for_type>

The type this generator is generating tags of.

=back

=head2 create_wikidata

    my Data::TagDB::Tag $tag = $factory->create_wikidata($qid);
    # e.g.:
    my Data::TagDB::Tag $tag = $factory->create_wikidata('Q2');

Generates a tag for Wikidata item (Q), property (P), or lexeme (L).

=head2 create_integer

    my Data::TagDB::Tag $tag = $factory->create_integer($int);
    # e.g.:
    my Data::TagDB::Tag $tag = $factory->create_integer(5);

Generates a tag for an integer (positive or negative).

=head2 create_character

    my Data::TagDB::Tag $tag = $factory->create_character($unicode_code_point);
    # or:
    my Data::TagDB::Tag $tag = $factory->create_character($type => $value);
    # e.g.:
    my Data::TagDB::Tag $tag = $factory->create_integer('U+1F981');
    # or:
    my Data::TagDB::Tag $tag = $factory->create_integer(0x1F981);
    # or:
    my Data::TagDB::Tag $tag = $factory->create_integer(raw => 'A');

Creates a tag for a character.

The code point may be passed in different ways.
If no type is given C<unicode> is assumed. The following types are supported:

=over

=item C<unicode>

The Unicode code point either in standard C<U+xxxx> notation or as a numerical value.

=item C<ascii>

The value as an US-ASCII code. The code is checked to be within the limits of US-ASCII.

=item C<raw>

The value as a raw string. Note that this requires the passed value to be a Perl unicode string.
This may also result in unexpected behaviour if the passed value is composed of multiple unicode code points.
This can for example be the case when modifiers are used with some code points.

=back

=head2 create_colour

    my Data::TagDB::Tag $tag = $factory->create_colour($colour);
    # e.g.:
    my Data::TagDB::Tag $tag = $factory->create_colour('#c0c0c0');
    # or:
    my Data::URIID::Colour $colour = ...;
    my Data::TagDB::Tag $tag = $factory->create_colour($colour);

Creates a tag for a colour.
The passed colour must be in hash-and-hex format or a valid colour object
from one of the supported modules.

Currently L<Data::URIID::Colour>, L<Color::Library::Color>, and L<Graphics::Color::RGB> are supported.

=head2 create_date

    my Data::TagDB::Tag $tag = $factory->create_date($date, %opts);
    # e.g.:
    my Data::TagDB::Tag $tag = $factory->create_date('2024-06-20Z');
    # or:
    my Data::TagDB::Tag $tag = $factory->create_date('today');
    # or:
    my Data::TagDB::Tag $tag = $factory->create_date($^T);

Takes a date and converts it to a tag. The date may be in ISO-8601 format with the time zone given as UTC (C<Z>),
an integer being the UNIX epoch, an object that implements an C<epoch> method (such as L<DateTime>), a code reference
to a sub returning any thing from this list, or the special string C<now>, or C<today>.

Options are:

=over

=item C<min_precision>

The minimum required precision. Defaults to the value of C<precision> or the C<year>.

=item C<max_precision>

The maximum allowed precision. Defaults to the value of C<precision> or the C<day>.

=item C<precision>

The default value for C<min_precision>, and C<max_precision>. Most often only this option is set to force
a specific precision.

=back

Valid precision values are: C<year>, C<month>, C<day>.

=head2 generate

    my Data::TagDB::Tag $tag = $factory->generate(%opts);

This is the generic generation method.
Calling this method directly should be avoided in in favour of calling on of the C<create_...> methods.

The following options are supported:

=over

=item C<tagname>

A tagname for the generator.

=item C<ns>

The namespace used by the generator. Can be a UUID or a L<Data::TagDB::Tag>.

=item C<generator>

The generator to use. If this generator contains all the required data many of the other values may be skipped.

=item C<input>

The input to the hashing function. This should be avoided to be used. C<$request> is the preferred option.

=item C<request>

The generator request.

=item C<style>

The style of the generator. Also know as it's type.

=item C<copy_names>

Whether or not to copy tagnames.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
