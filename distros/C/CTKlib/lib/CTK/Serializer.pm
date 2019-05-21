package CTK::Serializer; # $Id: Serializer.pm 212 2019-04-27 18:42:35Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Serializer - Base class for serialization perl structures

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK::Serializer;

    my $sr = new CTK::Serializer( DEFAULT_FORMAT,
            attrs => {
                xml => [
                        { # For serialize
                            RootName   => "request",
                        },
                        { # For deserialize
                            ForceArray => 1,
                            ForceContent => 1,
                        }
                    ],
                json => [
                        { # For serialize
                            utf8 => 0,
                            pretty => 1,
                            allow_nonref => 1,
                            allow_blessed => 1,
                        },
                        { # For deserialize
                            utf8 => 0,
                            allow_nonref => 1,
                            allow_blessed => 1,
                        },
                    ],
            },
        );

    my $doc = $sr->serialize( xml => { foo => 1, bar => 2}, {
            RootName   => "request",
        });
    my $doc = $sr->document;

    my $perl = $sr->deserialize( xml => $doc, {
            ForceArray => 1,
            ForceContent => 1,
        });
    my $perl = $sr->struct;

    my $status = $sr->status; # 0 - Error, 1 - Ok

    my $error = $sr->error;

    my $MIME_type = $sr->content_type;

=head1 DESCRIPTION

This module provides access to serialization mechanism with support extending.
Now allowed to use follows formats of serialization in this base class:
XML, YAML, JSON and "none" for automatic format detecting

=head2 new

    my $sr = new CTK::Serializer( $format );

If specified $format in constructor call then this format sets as default

    my $sr = new CTK::Serializer( $format,
            attrs => {
                format => [
                    {...serialize attr...}, # for serialize
                    {...deserialize attr...},  # for deserialize
                ],
            },
        );

If an attribute is specified, the passed values are substituted for
the call attributes of the corresponding serializer and deserializer

Supported formats:

=over 8

=item C<XML>

XML serialization via XML::Simple module

=item C<JSON>

JSON serialization via JSON (JSON::XS if installed) module

=item C<YAML>

YAML serialization via YAML::XS module

=back

Also exists non-formal format "none".
This format allows serialization in a perl-dump using the Data::Dumper;
deserialization based on the format lookup mechanism based on the data signature.

For Example:

    my $sr = CTK::Serializer();
    my $perl = $sr->deserialize( $doc );

In this example, the format is detecting automatically

=head2 deserialize

    my $perl = $sr->deserialize( $format => $doc, $attrs );
    my $perl = $sr->deserialize( $doc );

The method returns deserialized structure of the document using specified format.
The optional $attrs variable contents attributes of serialization module (hash-ref)

=head2 document, doc

    my $doc = $sr->serialize( $perl );
    my $doc = $sr->document;

This method returns document from last operation serialize or deserialize

=head2 error

    my $error = $sr->error;

Returns current error or NULL value ("") if no errors occurred

=head2 format

    my $format = $sr->format;
    my $format = $sr->format( $new_format );

Format accessor

=head2 content_type

    my $content_type = $sr->content_type;
    my $content_type = $sr->content_type( $format );

Returns MIME-type for format

=head2 get_list

    my @supported_serializers = $sr->get_list;

Returns list of supported serializers (their names)

=head2 lookup

    my $node = $sr->lookup( $format );

Looks for format attributes

=head2 register_serializer

This method uses for extension of this base class. See source code

=head2 serialize

    my $doc = $sr->serialize( $format => $perl, $attrs );
    my $doc = $sr->serialize( $perl );

The method returns serialized document of the structure using specified format.
The optional $attrs variable contents attributes of serialization module (hash-ref)

=head2 stash

For internal use only. See source code

=head2 status

    my $status = $sr->status;

Returns 1 if no errors and 0 if errors occurred

Typical example of use:

    die( $sr->error ) unless $sr->status;

=head2 struct, structure

    my $perl = $sr->deserialize( $doc );
    my $perl = $sr->struct;

This method returns structure from last operation serialize or deserialize

=head1 HISTORY

=over 8

=item B<1.00 Wed Dec 20 07:43:34 2017 GMT>

Init version

=back

See C<Changes> file

=head1 DEPENDENCIES

L<IO::String>, L<JSON>, L<XML::Simple>, L<YAML::XS>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use constant {
        DEFAULT_FORMAT      => "none",
        DEFAULT_SERIALIZER  => "none",
        BLANK   => sub {{
                document=> "",
                status  => 0,
                error   => sprintf("No data %s", shift || __PACKAGE__),
                struct  => undef,
            }},
        ROOTNAME    => 'request',
        XMLDECL     => '<?xml version="1.0" encoding="utf-8"?>',
    };

use Carp;
use IO::String;
use autouse 'Data::Dumper' => qw/Dumper/;

my %serializers = (
        none => {
                name    => DEFAULT_SERIALIZER,
                description => 'Void serializer (Data::Dumper)',
                content_type=> 'text/plain',
                class       => __PACKAGE__,
                match       => undef,
            },
    );

__PACKAGE__->register_serializer ({
    name        => 'json',
    description => "JSON serializer",
    content_type=> 'application/json',
    class       => "CTK::Serializer::JSON",
    match       => qr/^\s*\[*\{/,
});

__PACKAGE__->register_serializer ({
    name        => 'xml',
    description => "XML serializer",
    content_type=> 'application/xml',
    class       => "CTK::Serializer::XML",
    match       => qr/^\s*\</,
});

__PACKAGE__->register_serializer ({
    name        => 'yaml',
    description => "YAML serializer",
    content_type=> 'application/x-yaml',
    class       => "CTK::Serializer::YAML",
    match       => qr/^\s*(\-{3}|\%YAML)/,
});

sub register_serializer {
    my $self = shift;
    my $info = shift;
    return 1 if exists $serializers{$info->{name}};
    $serializers{$info->{name}} = $info;

    return 1;
}

sub new {
    my $class = shift;
    my $format = lc(shift || DEFAULT_SERIALIZER);
    my %args  = @_;

    $args{serializers} = {%serializers};
    my @formats = grep {$_ ne DEFAULT_SERIALIZER} keys %serializers;
    $args{formats} = [@formats];
    croak("Unsupported format name") unless exists $serializers{$format};

    # Attrs
    $args{attrs} ||= {}; # { format => [{...serialize attr...}, {...deserialize attr...}]}
    $args{serialize_attr} = undef; # ...serialise [0]
    $args{deserialize_attr} = undef; # ...deserialise [1]

    # Properties
    $args{format} = $format;
    $args{status} = 1;
    $args{error} = '';
    $args{documnet} = '';
    $args{struct} = undef;

    my $self = bless {%args}, $class;
    $self->_set_attrs($format);
    return $self;
}
sub _set_attrs {
    my $self = shift;
    my $format = shift || return 0;
    my $attrs = $self->{attrs};
    return 0 unless $attrs && ref($attrs) eq 'HASH';
    my $attr = $attrs->{$format};
    return 0 unless $attr && ref($attr) eq 'ARRAY';
    $self->{serialize_attr} = $attr->[0];
    $self->{deserialize_attr} = $attr->[1];
    return 1;
}
sub get_list {
    my $self = shift;
    my $serzs = $self->{serializers};
    return () unless $serzs && ref($serzs) eq 'HASH';
    return(keys(%$serzs));
}
sub lookup {
    my $self = shift;
    my $format = lc(shift || '_none_');
    return $self->{serializers}->{$format} if exists $self->{serializers}->{$format};
    return undef;
}
sub format {
    my $self = shift;
    my $format = shift;
    $self->{format} = lc($format) if defined($format) && $self->lookup($format);
    return $self->{format} || DEFAULT_SERIALIZER;
}
sub content_type {
    my $self = shift;
    my $format = shift // $self->format;
    return undef unless $self->lookup($format);
    return $self->lookup($format)->{content_type};
}
sub error {
    my $self = shift;
    return $self->{error};
}
sub status {
    my $self = shift;
    return $self->{status};
}
sub struct {
    my $self = shift;
    return $self->{struct};
}
sub structure { goto &struct }
sub document {
    my $self = shift;
    return $self->{document};
}
sub doc { goto &document }
sub serialize {
    my $self = shift;
    my $format = $_[0];
    if (defined($format) && !ref($format) && (length($format) < 32) && $self->lookup($format)) {
        $self->{format} = lc(shift);
    } else {
        $format = $self->{format};
    }
    $self->_set_attrs($format);
    my $str = shift;
    my $attr = shift || $self->{serialize_attr};
    $self->stash();
    my %out;
    if (lc($format) eq DEFAULT_SERIALIZER) {
        %out = $self->_serialize($str, $attr);
    } else {
        my $class = $self->lookup($format)->{class};
        %out = $class->_serialize($str, $attr);
    }
    $self->stash(%out);
    return $self->document;
}
sub deserialize {
    my $self = shift;
    my $format = $_[0];
    if (defined($format) && !ref($format) && (length($format) < 32) && $self->lookup($format)) {
        $self->{format} = lc(shift);
    } else {
        $format = $self->{format};
    }
    $self->_set_attrs($format);
    my $doc = shift;
    my $attr = shift || $self->{deserialize_attr};
    $self->stash();
    my %out;
    if (lc($format) eq DEFAULT_SERIALIZER) {
        %out = $self->_deserialize($doc, $attr);
    } else {
        my $class = $self->lookup($format)->{class};
        %out = $class->_deserialize($doc, $attr);
    }
    $self->stash(%out);
    return $self->struct;
}
sub stash {
    my $self = shift;
    my %in = @_;
    undef $self->{document};
    $self->{document} = $in{document} // "";
    undef $self->{struct};
    $self->{struct} = $in{struct} // undef;
    $self->{status} = $in{status} || 0;
    $self->{error} = $in{error} // '';
    return 1;
}
sub _serialize { # Structure -> DUMP
    my $self = shift;
    my $struct = shift || {};
    return (
        document=> Dumper($struct),
        struct  => $struct,
        error   => "",
        status  => 1,
    );
}
sub _deserialize { # ??? -> Structure
    my $self = shift;
    my $doc = shift;
    my $attr = shift || {};

    my $frmt;
    my $frmts = $self->{formats};

    foreach my $k (@$frmts) {
        my $match = $self->lookup($k)->{match};
        next unless $match;
        if ($doc =~ $match) {
            $frmt = $k;
            last;
        }
    }
    if ($frmt) {
        $self->{format} = $frmt;
        $self->_set_attrs($frmt);
        my $class = $self->lookup($frmt)->{class};
        return $class->_deserialize($doc, $self->{deserialize_attr} || $attr);
    }
    my $out = CTK::Serializer::BLANK->(__PACKAGE__);
    $out->{document} = $doc;
    my $io = IO::String->new($doc);
    $out->{struct} = [(<$io>)];
    $out->{error} = ""; # Can't detect format of the document";
    $out->{status} = 1;
    $io->close;
    return %$out;
}

1;

package CTK::Serializer::JSON;
use strict;
use utf8;
use JSON;
#use JSON::XS;
use Try::Tiny;

sub _serialize { # Structure -> JSON
    my $self = shift;
    my $struct = shift || {};
    my $attr = shift || {};
    $attr->{utf8} = 0 unless defined $attr->{utf8};
    $attr->{pretty} = 1 unless defined $attr->{pretty};
 # my $coder = JSON::XS->new->pretty($attr->{pretty}); #->allow_blessed(0)->utf8;
 # $coder = $coder->allow_blessed($attr->{allow_blessed}) if $attr->{allow_blessed};
 # $coder = $coder->allow_nonref($attr->{allow_nonref}) if $attr->{allow_nonref};
 # $coder = $coder->utf8 if $attr->{utf8};
    my $doc = "";
    my $err = "";
    my $stt = 1;
    try {
        $doc = to_json($struct, $attr);
    } catch {
        $err = sprintf("Can't serialize JSON structure: %s", $_);
        $stt = 0;
    };
 #   my $doc = $coder->encode($struct);
    return (
        document=> $doc,
        struct  => $struct,
        error   => $err,
        status  => $stt,
    );
}
sub _deserialize { # JSON -> Structure
    my $self = shift;
    my $json = shift;
    my $attr = shift || {};
    my $out = CTK::Serializer::BLANK->(__PACKAGE__);
    $out->{document} = $json;
    return %$out unless $json;
    $attr->{utf8} = 0 unless defined $attr->{utf8};
    my $struct;
 # my $coder = JSON::XS->new;
 # $coder = $coder->allow_nonref($attr->{allow_nonref}) if $attr->{allow_nonref};
 # $coder = $coder->utf8 if $attr->{utf8};
 #chomp($json);
    try {
        my $in = from_json($json, $attr);
 #       my $in = $coder->decode($json);

        if ($in && ((ref($in) eq 'HASH') || ref($in) eq 'ARRAY')) {
            if (ref($in) eq 'ARRAY') {
                #$out->{struct} = shift(@$in) || {}; # Закоментировал т.к. иногда нужен массив!
                $out->{struct} = $in;
            } else { # HASH
                $out->{struct} = $in;
            }
            $out->{error} = "";
            $out->{status} = 1;
        } else {
            $out->{error} = "Bad JSON format";
        }
    } catch {
        $out->{error} = sprintf("Can't load JSON document: %s", $_);
    };
    return %$out;
}

1;

package CTK::Serializer::XML;
use strict;
use utf8;
use XML::Simple;
use Try::Tiny;

sub _serialize { # Structure -> XML
    my $self = shift;
    my $struct = shift || {};
    my $attr = shift || {};
    my $doc = "";
    my $err = "";
    my $stt = 1;
    try {
        $doc = XMLout($struct, %$attr);
    } catch {
        $err = sprintf("Can't serialize XML structure: %s", $_);
        $stt = 0;
    };
    return (
        document=> $doc,
        struct  => $struct,
        error   => $err,
        status  => $stt,
    );
}
sub _deserialize { # XML -> Structure
    my $self = shift;
    my $xml = shift;
    my $attr = shift || {};
    my $out = CTK::Serializer::BLANK->(__PACKAGE__);
    $out->{document} = $xml;
    return %$out unless $xml;
    return %$out unless $xml =~ /^\s*\<(?!htm)(([?]?xml)|\w+)/;
    my $struct;
    try {
        my $in = XMLin($xml, %$attr);
        if ($in && ((ref($in) eq 'HASH') || ref($in) eq 'ARRAY')) {
            if (ref($in) eq 'ARRAY') {
                $out->{struct} = shift(@$in) || {};
            } else { # HASH
                $out->{struct} = $in;
            }
            $out->{error} = "";
            $out->{status} = 1;
        } else {
            $out->{error} = "Bad XML format";
        }
    } catch {
        $out->{error} = sprintf("Can't load XML document: %s", $_);
    };
    return %$out;
}

1;

package CTK::Serializer::YAML;
use strict;
use utf8;
use YAML::XS;
use Try::Tiny;

sub _serialize { # Structure -> YAML
    my $self = shift;
    my $struct = shift || {};
    my $doc = "";
    my $err = "";
    my $stt = 1;
    try {
        $doc = Dump($struct);
    } catch {
        $err = sprintf("Can't serialize YAML structure: %s", $_);
        $stt = 0;
    };
    return (
        document=> $doc,
        struct  => $struct,
        error   => $err,
        status  => $stt,
    );
}
sub _deserialize { # YAML -> Structure
    my $self = shift;
    my $yaml = shift;
    my $out = CTK::Serializer::BLANK->();
    $out->{document} = $yaml;
    return %$out unless $yaml;
    my $struct;
    try {
        my $in = Load($yaml);
        if ($in && ((ref($in) eq 'HASH') || ref($in) eq 'ARRAY')) {
            if (ref($in) eq 'ARRAY') {
                #$out->{struct} = shift(@$in) || {};
                $out->{struct} = $in;
            } else { # HASH
                $out->{struct} = $in;
            }
            $out->{error} = "";
            $out->{status} = 1;
        } else {
            $out->{error} = "Bad YAML format";
        }
    } catch {
        $out->{error} = sprintf("Can't load YAML document: %s", $_);
    };
    return %$out;
}

1;

__END__
