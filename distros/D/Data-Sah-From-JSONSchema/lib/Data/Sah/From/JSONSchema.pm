package Data::Sah::From::JSONSchema;

our $DATE = '2015-09-06'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       convert_json_schema_to_sah
               );

sub _clauses_common {
    my ($jsonsch, $sahsch) = @_;
    if (exists $jsonsch->{title}) {
        $sahsch->[1]{summary} = $jsonsch->{title};
    }
    if (exists $jsonsch->{description}) {
        $sahsch->[1]{description} = $jsonsch->{description};
    }
    if (exists $jsonsch->{default}) {
        $sahsch->[1]{default} = $jsonsch->{default};
    }
    # XXX enum/oneOf (which can be specified without 'type')
}

sub _convert_null {
    my $jsonsch = shift;
    my $sahsch = ["undef"];
    _clauses_common($jsonsch, $sahsch);
    $sahsch;
}

sub _clauses_num {
    my ($jsonsch, $sahsch) = @_;
    if (exists $jsonsch->{minimum}) {
        $sahsch->[1]{min} = $jsonsch->{minimum};
    }
    if (exists $jsonsch->{maximum}) {
        $sahsch->[1]{max} = $jsonsch->{maximum};
    }
    if (exists $jsonsch->{exclusiveMinimum}) {
        $sahsch->[1]{xmin} = $jsonsch->{exclusiveMinimum};
    }
    if (exists $jsonsch->{exclusiveMaximum}) {
        $sahsch->[1]{xmax} = $jsonsch->{exclusiveMaximum};
    }
    # XXX in sah, div_by is int only, not num
    if (exists $jsonsch->{multipleOf}) {
        $sahsch->[1]{div_by} = $jsonsch->{multipleOf};
    }
}

sub _convert_number {
    my $jsonsch = shift;
    my $sahsch = ["num", {req=>1}];
    _clauses_common($jsonsch, $sahsch);
    _clauses_num($jsonsch, $sahsch);
    $sahsch;
}

sub _convert_integer {
    my $jsonsch = shift;
    my $sahsch = ["int", {req=>1}];
    _clauses_common($jsonsch, $sahsch);
    _clauses_num($jsonsch, $sahsch);
    $sahsch;
}

sub _convert_boolean {
    my $jsonsch = shift;
    my $sahsch = ["bool", {req=>1}];
    _clauses_common($jsonsch, $sahsch);
    $sahsch;
}

sub _convert_string {
    my $jsonsch = shift;
    my $sahsch = ["str", {req=>1}];
    if (exists $jsonsch->{pattern}) {
        $sahsch->[1]{match} = $jsonsch->{pattern};
    }
    if (exists $jsonsch->{minLength}) {
        $sahsch->[1]{min_len} = $jsonsch->{minLength};
    }
    if (exists $jsonsch->{maxLength}) {
        $sahsch->[1]{max_len} = $jsonsch->{maxLength};
    }
    # XXX format, and builtin formats: date-time (RFC3339 section 5.6), email, hostname, ipv4, ipv6, uri
    $sahsch;
}

sub _convert_array {
    my $jsonsch = shift;
    my $sahsch = ["array", {req=>1}];
    if (exists($jsonsch->{minItems})) {
        $sahsch->[1]{min_len} = $jsonsch->{minItems};
    }
    if (exists($jsonsch->{maxItems})) {
        $sahsch->[1]{max_len} = $jsonsch->{maxItems};
    }
    if (exists($jsonsch->{items})) {
        if (ref($jsonsch->{items}) eq 'ARRAY') {
            $sahsch->[1]{elems} = [];
            my $i = 0;
            for my $el (@{ $jsonsch->{items} }) {
                $sahsch->[1]{elems}[$i] = _convert($el);
                $i++;
            }
            if (exists($jsonsch->{additionalItems}) && !$jsonsch->{additionalItems}) {
                $sahsch->[1]{max_len} = $i;
            }
        } else {
            $sahsch->[1]{of} = _convert($jsonsch->{items});
        }
    }
    # XXX uniqueItems
    $sahsch;
}

sub _convert_object {
    my $jsonsch = shift;
    my $sahsch = ["hash", {req=>1, 'keys.restrict'=>0}];
    if (exists($jsonsch->{minProperties})) {
        $sahsch->[1]{min_len} = $jsonsch->{minProperties};
    }
    if (exists($jsonsch->{maxProperties})) {
        $sahsch->[1]{max_len} = $jsonsch->{maxProperties};
    }
    if (exists $jsonsch->{properties}) {
        $sahsch->[1]{keys} = {};
        for my $k (keys %{ $jsonsch->{properties} }) {
            my $v = $jsonsch->{properties}{$k};
            $sahsch->[1]{keys}{$k} = _convert($v);
        }
    }
    if (exists($jsonsch->{additionalProperties}) && !$jsonsch->{additionalProperties}) {
        $sahsch->[1]{'keys.restrict'} = 1;
    }
    if (exists $jsonsch->{required}) {
        $sahsch->[1]{req_keys} = $jsonsch->{required};
    }
    if (exists $jsonsch->{dependencies}) {
        for my $k (keys %{ $jsonsch->{dependencies} }) {
            my $v = $jsonsch->{dependencies}{$k};
            if (ref($v) eq 'HASH') {
                # XXX schema dependencies
                die "Schema dependencies is not yet supported";
            } else {
                $sahsch->[1]{'req_dep_all&'} //= [];
                for my $d (@$v) {
                    push @{ $sahsch->[1]{'req_dep_all&'} }, [$d, [$k]];
                }
            }
        }
    }
    if (exists $jsonsch->{patternProperties}) {
        $sahsch->[1]{allowed_keys_re} = $jsonsch->{patternProperties};
    }
    $sahsch;
}

sub _convert {
    my $jsonsch = shift;

    ref($jsonsch) eq 'HASH' or die "JSON schema must be a hash";
    my $type = $jsonsch->{type} or die "JSON schema must have a type";
    # XXX type can be an array, e.g. [number, string] which means any one of those
    # XXX $ref instead of type
    # XXX format can be specified without type, implies string
    # XXX enum/oneOf (which can be specified without 'type')
    if ($type eq 'object') {
        _convert_object($jsonsch);
    } elsif ($type eq 'array') {
        _convert_array($jsonsch);
    } elsif ($type eq 'string') {
        _convert_string($jsonsch);
    } elsif ($type eq 'boolean') {
        _convert_boolean($jsonsch);
    } elsif ($type eq 'integer') {
        _convert_integer($jsonsch);
    } elsif ($type eq 'number') {
        _convert_number($jsonsch);
    } elsif ($type eq 'null') {
        _convert_null($jsonsch);
    } else {
        die "Unknown type '$type'";
    }
}

sub convert_json_schema_to_sah {
    _convert(@_);
}

1;
# ABSTRACT: Convert JSON schema to Sah schema

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::From::JSONSchema - Convert JSON schema to Sah schema

=head1 VERSION

This document describes version 0.02 of Data::Sah::From::JSONSchema (from Perl distribution Data-Sah-From-JSONSchema), released on 2015-09-06.

=head1 SYNOPSIS

 use Data::Sah::From::JSONSchema qw(convert_json_schema_to_sah);

 my $jsonsch = {
     description => "a representation of a person, company, organization, or place",
     type => "object",
     required => [qw/familyName givenName/],
     properties => {
         fn => {
             description => "formatted name",
             type => "string",
         },
         familyName => {type => "string"},
         givenName => {type => "string"},
     },
 };
 my $sahsch = convert_json_schema_to_sah($jsonsch);

 # $sahsch will contain something like:
 # [hash => {
 #     description => "a representation of a person, company, organization, or place",
 #     req_keys => ['familyName', 'givenName'],
 #     keys => {
 #         fn => [str => {
 #             description => "formatted name",
 #             req => 1,
 #         }],
 #         familyName => ['str', {req=>1}],
 #         givenName => ['str', {req=>1}],
 #     },
 # }]

=head1 DESCRIPTION

B<EARLY DEVELOPMENT, EXPERIMENTAL.>

Some features are not yet supported: $ref, $schema, id, array's uniqueItems, and
so on.

=head1 FUNCTIONS

=head2 convert_json_schema_to_sah($jsonsch) => ARRAY

Convert JSON schema in C<$jsonsch> (which must be a hash), to a L<Sah> schema.
Dies on failure.

=head1 SEE ALSO

http://json-schema.org/

L<Sah>, L<Data::Sah>

Implementation of JSON Schema in Perl: L<JSON::Schema>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-From-JSONSchema>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-From-JSONSchema>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-From-JSONSchema>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
