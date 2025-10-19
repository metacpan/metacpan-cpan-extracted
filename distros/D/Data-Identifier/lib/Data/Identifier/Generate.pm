# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Generate;

use v5.20;
use strict;
use warnings;

use Carp;
use Encode qw(encode);
use Digest;

use Data::Identifier;

use constant {
    NS_GTE                              => '90355e77-6942-4d82-a0b6-3a6de65bf948',

    WK_UNSIGNED_INTEGER_GENERATOR       => '53863a15-68d4-448d-bd69-a9b19289a191',
    WK_SIGNED_INTEGER_GENERATOR         => 'e8aa9e01-8d37-4b4b-8899-42ca0a2a906f',
    WK_UNICODE_CHARACTER_GENERATOR      => 'd74f8c35-bcb8-465c-9a77-01010e8ed25c',
    WK_RGB_COLOUR_GENERATOR             => '55febcc4-6655-4397-ae3d-2353b5856b34',
    WK_DATE_GENERATOR                   => '97b7f241-e1c5-4f02-ae3c-8e31e501e1dc',
    WK_MULTIPLICITY_GENERATOR           => '19659233-0a22-412c-bdf1-8ee9f8fc4086',
    WK_MINIMUM_MULTIPLICITY_GENERATOR   => '5ec197c3-1406-467c-96c7-4b1a6ec2c5c9',
};


our $VERSION = v0.19;

my %_multiplicity_prefix = (
    total   => '4.1',
    minimum => '4.3',
);

my %_multiplicity_names = (
    0 => 'noone',
    1 => 'solo',
    2 => 'duo',
    3 => 'trio',
);

my %_multiplicity_generators = (
    total   => WK_MULTIPLICITY_GENERATOR,
    minimum => WK_MINIMUM_MULTIPLICITY_GENERATOR,
);

my %_gte_simple_profiles = (
    'ab332382-a6f8-4a24-914d-5f823dd866c1' => {
        namespace       => 'a13377a3-88d4-484e-90a8-245afb22a793',
        order           => 'MFHCSmfhcs',
        case_folding    => undef,
        strip_slash     => undef,
        strip_spaces    => undef,
    },
    'e537db94-85b9-4125-972a-cc2ea1fdf51d' => {
        namespace       => '52f20647-1dc7-4234-81ad-0639ab6cef60',
        order           => 'FAfa',
        case_folding    => undef,
        strip_slash     => undef,
        strip_spaces    => undef,
    },
    '60764502-18cb-41c9-8531-e4c8b43140b9' => {
        namespace       => '1e2edf8d-d459-47cb-9d6e-0690f404fadf',
        order           => 'MFHCSmfhcs',
        case_folding    => undef,
        strip_slash     => undef,
        strip_spaces    => undef,
    },
    '5aad9d75-7020-41a4-8ec6-2bf09566f985' => {
        namespace       => 'fc9741b4-2ac7-412b-9d36-2b675fc0482b',
        order           => 'NDTBndtb',
        case_folding    => undef,
        strip_slash     => undef,
        strip_spaces    => undef,
    },
);


#@returns Data::Identifier
sub integer {
    my ($pkg, $request, %opts) = @_;
    $opts{request}      = $request;
    $opts{style}        = 'integer-based';
    $opts{namespace}    = Data::Identifier->NS_INT();
    $opts{displayname}//= $request;
    $opts{generator}    = $request >= 0 ? WK_UNSIGNED_INTEGER_GENERATOR : WK_SIGNED_INTEGER_GENERATOR;

    return $pkg->generic(%opts);
}


sub unicode_character {
    my ($pkg, $type, $request, %opts) = @_;
    my $unicode_cp;
    my $unicode_cp_str;

    if ($type eq 'unicode') {
        if ($request =~ /^[Uu]\+([0-9a-fA-F]+)$/) {
            $unicode_cp = hex($1);
        } else {
            $unicode_cp = int($request);
        }
    } elsif ($type eq 'ascii') {
        $unicode_cp = int($request);
        croak 'US-ASCII character out of range: '.$unicode_cp if $unicode_cp < 0 || $unicode_cp > 0x7F;
    } elsif ($type eq 'raw') {
        croak 'Raw value is not exactly one character long' unless length($request) == 1;
        $unicode_cp = ord($request);
    }

    croak 'Unicode character out of range: '.$unicode_cp if $unicode_cp < 0 || $unicode_cp > 0x10FFFF;

    $unicode_cp_str = sprintf('U+%04X', $unicode_cp);

    if ($unicode_cp == 0xFFFC || $unicode_cp == 0xFFFD || $unicode_cp == 0xFEFF || $unicode_cp == 0xFFFE) {
        croak 'Rejected use of special character: '.$unicode_cp_str unless $opts{allow_special};
    }

    return Data::Identifier->new(unicodecp => $unicode_cp_str, displayname => $opts{displayname}, generator => WK_UNICODE_CHARACTER_GENERATOR, request => $unicode_cp_str);
}


#@returns Data::Identifier
sub colour {
    my ($pkg, $colour, %opts) = @_;
    $opts{request}      = $colour;
    $opts{style}        = 'colour';
    $opts{namespace}    = '88d3944f-a13b-4e35-89eb-e3c1fbe53e76';
    $opts{generator}    = WK_RGB_COLOUR_GENERATOR;
    return $pkg->generic(%opts);
}


#@returns Data::Identifier
sub date {
    my ($pkg, $request, %opts) = @_;
    my ($year, $month, $day);
    my $precision;

    if (ref($request)) {
        if (eval {$request->can('epoch')}) {
            $request = $request->epoch;
        } else {
            return $pkg->date(scalar($request->()), %opts);
        }
    }

    ($year, $month, $day) = $request =~ /^([12][0-9]{3})(?:-([01][0-9])(?:-([0-3][0-9]))?)?Z$/;

    unless (length($year // '') == 4) {
        if ($request eq 'now' || $request eq 'today') {
            $request = time();
        } elsif ($request =~ /^(?:0|-?[1-9][0-9]*)$/) {
            $request = int($request);
            if ($request > 32503680000) {
                croak 'Unlikely far date given. Likely miliseconds are passed as seconds?';
            }
        } else {
            croak 'Invalid format';
        }

        (undef,undef,undef,$day,$month,$year) = gmtime($request);
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

    $precision = $opts{precision} // ($day ? 'day' : undef) // ($month ? 'month' : undef) // 'year';
    if ($precision eq 'day' && $day) {
        $request = sprintf('%04u-%02u-%02uZ', $year, $month, $day);
    } elsif ($precision eq 'month' && $month) {
        $request = sprintf('%04u-%02uZ', $year, $month);
    } elsif ($precision eq 'year' && $year) {
        $request = sprintf('%04uZ', $year);
    } else {
        croak 'Bad precision: '.$precision;
    }

    $opts{request}      = $request;
    $opts{input}      //= $request; # force raw value!
    $opts{style}        = undef;
    $opts{namespace}    = Data::Identifier->NS_DATE();
    $opts{displayname}//= $request;
    $opts{generator}    = WK_DATE_GENERATOR;

    return $pkg->generic(%opts);
}


sub multiplicity {
    my ($pkg, $subtype, $request, %opts) = @_;
    my $prefix = $_multiplicity_prefix{$subtype} // croak 'Invalid subtype: '.$subtype;
    my $identifier;
    my $oid;

    croak 'Invalid value: '.$request unless $request eq '0' || $request =~ /^[1-9][0-9]*$/;

    $oid = '1.3.6.1.4.1.46942.16.2.'.$prefix.'.'.$request;

    $opts{request}      = $request;
    $opts{input}        = $prefix.'.'.$request;
    $opts{namespace}    = NS_GTE;
    $opts{displayname}//= $_multiplicity_names{$request};
    $opts{displayname}//= $request;
    $opts{generator}    = $_multiplicity_generators{$subtype};
    $identifier = $pkg->generic(%opts);

    $identifier->{id_cache} //= {};
    $identifier->{id_cache}->{Data::Identifier->WK_OID} //= $oid;

    if (defined $_multiplicity_names{$request}) {
        $identifier->register;
    }

    return $identifier;
}


sub gte_simple {
    my ($pkg, $profile, $request, %opts) = @_;
    my %order;
    my $normal;

    croak 'Called in list context' if wantarray;

    $profile = $profile->ise if eval {$profile->can('ise')};
    $profile = $_gte_simple_profiles{$profile} // $profile;

    {
        my $i = 0;
        %order = map {$_ => $i++} split(//, $profile->{order});
    }

    if (defined(my $folding = $profile->{case_folding})) {
        if ($folding eq 'none') {
            # no-op
        } elsif ($folding eq 'upper') {
            $request = uc($request);
        } elsif ($folding eq 'lower') {
            $request = lc($request);
        } else {
            croak 'Unsupported/invalid folding rule: '.$folding;
        }
    }

    if ($profile->{strip_slash}) {
        $request =~ s#/+##g;
    }

    if ($profile->{strip_spaces}) {
        $request =~ s#\s+##g;
    }

    $normal = join('',
        sort {$order{$a} <=> $order{$b}}
        map {croak 'Invalid input element: '.$_ unless defined $order{$_}; $_}
        split //, $request);

    if (defined(my $info = delete $opts{info})) {
        $info->{count}   = length($normal);
        $info->{request} = $normal;
    }

    $opts{input}        = $normal;
    $opts{request}      = $normal;
    $opts{namespace}  //= $profile->{namespace};
    $opts{displayname}//= $normal;
    return $pkg->generic(%opts);
}


#@returns Data::Identifier
sub generic {
    my ($pkg, %opts) = @_;

    if (defined(my $type)) {
        $opts{namespace} //= $type->namespace;
    }

    if (defined(my $style = $opts{style}) && defined(my $request = $opts{request})) {
        if ($style eq 'integer-based') {
            croak 'Invalid request' unless $request =~ /^(?:0|-?[1-9][0-9]*)$/;
            $opts{input} //= $request;
        } elsif ($style eq 'id-based') {
            my ($input, $name);

            if (($input, $name) = $request =~ /^(#?[a-zA-Z0-9\-\.\+]+) (.+)$/) {
                # noop
            } elsif (($input) = $request =~ /^(#?[a-zA-Z0-9\-\.\+]+)$/) {
                $name = undef;
            } else {
                croak 'Invalid format, expected: "id name", or "id", got: '.$request;
            }

            $opts{input} //= lc($input);
            $opts{displayname} //= $name;

        } elsif ($style eq 'name-based') {
            $opts{input} //= encode('UTF-8', $request);
            $opts{displayname} //= $request;
        } elsif ($style eq 'tag-based') {
            if (ref($request)) {
                my $identifier = Data::Identifier->new(from => $request);
                $opts{input} //= $identifier->uuid;
                $opts{displayname} //= $identifier->{displayname}; # steal the raw value here.
            } elsif ($request =~ Data::Identifier->RE_UUID) {
                $opts{input} //= $request;
            } else {
                croak 'Invalid format for tag-based generator: '.$request;
            }
        } elsif ($style eq 'tagcombiner') {
            if (ref($request) eq 'ARRAY') {
                my %uuids;

                foreach my $entry (@{$request}) {
                    if (ref($entry)) {
                        $uuids{Data::Identifier->new(from => $entry)->uuid} = undef;
                    } elsif ($entry =~ Data::Identifier->RE_UUID) {
                        $uuids{$entry} = undef;
                    } else {
                        croak 'Invalid format for tag-based generator: '.$entry;
                    }
                }

                croak 'Less than two tags being combined' unless scalar(keys %uuids) > 1;

                $opts{input} //= join(',', sort keys %uuids);
            } else {
                croak 'Invalid request for tagcombiner generator: '.$request;
            }
        } elsif ($style eq 'colour') {
            if (defined $request) {
                my $req = lc($request);

                $req = sprintf('#%s%s%s', $1 x 6, $2 x 6, $3 x 6) if $req =~ /^#([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/;

                if ($req =~ /^#[a-f0-9]{36}$/) {
                    $opts{input} //= $req;
                } else {
                    croak 'Bad format for colour';
                }
            }
        } else {
            croak 'Style not supported: '.$style;
        }
    }

    croak 'No valid style/request or input is provided' unless defined $opts{input};

    {
        my $ns = ref($opts{namespace}) ? $opts{namespace}->uuid(no_defaults => 1) : $opts{namespace};
        my $uuid = $pkg->_uuid_v5($ns, $opts{input});
        my $tag = Data::Identifier->new(uuid => $uuid, displayname => $opts{displayname});
        $tag->{$_} //= $opts{$_} foreach qw(generator request);
        $tag->{generator} = Data::Identifier->new(from => $tag->{generator}) if defined($tag->{generator}) && !ref($tag->{generator});
        return $tag;
    }
}

# ---- Private helpers ----

sub _available_module {
    my (@modules) = @_;
    state $tried = {};

    foreach my $module (@modules) {
        if (exists $tried->{$module}) {
            next unless $tried->{$module};
            return $module;
        } else {
            my $res = eval {
                my $modname = $module =~ s#::#/#gr;
                require $modname.'.pm';
                1;
            };
            $tried->{$module} = $res;
            return $module if $res;
        }
    }

    croak 'Found none of modules ['.join(', ', @modules).']';
}

sub _finish {
    my ($raw, $version) = @_;
    substr($raw, 6, 1, chr((ord(substr($raw, 6, 1)) & 0x0F) | ($version << 4)));
    substr($raw, 8, 1, chr((ord(substr($raw, 8, 1)) & 0x3F) | 0x80));
    return join('-', unpack('H8H4H4H4H12', $raw));
}

sub _random {
    my ($pkg, %opts) = @_;
    my $sources = $opts{sources} // (state $default_sources = [qw(Crypt::URandom UUID4::Tiny Math::Random::Secure UUID::URandom UUID::Tiny::Patch::UseMRS)]);
    my $source = _available_module(@{$sources});
    my $raw;

    # Secure:
    if ($source eq 'Crypt::URandom') {
        $raw = Crypt::URandom::urandom(16);
    } elsif ($source eq 'UUID4::Tiny') {
        return UUID4::Tiny::create_uuid_string();
    } elsif ($source eq 'Math::Random::Secure') {
        $raw = join('', map {chr Math::Random::Secure::irand(256)} 0..15);
    } elsif ($source eq 'UUID::URandom') {
        return UUID::URandom::create_uuid_string();
    } elsif ($source eq 'UUID::Tiny::Patch::UseMRS') {
        return UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_RANDOM());

    # Insecure:
    } elsif ($source eq 'UUID::Tiny') {
        return UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_RANDOM());
    } elsif ($source eq 'Data::UUID') {
        require Data::UUID;
        return Data::UUID->create_str;
        #} elsif ($source eq '') {
    } else {
        croak 'Invalid/unsupported source';
    }

    if (defined($raw) && length($raw) == 16) {
        return _finish($raw, 4);
    }

    croak 'Bug!';
}

sub _uuid_v5 {
    my ($pkg, $ns, $data) = @_;
    my $digest = Digest->new('SHA-1');

    $ns = $ns->uuid(no_defaults => 1) if ref $ns;

    $ns = pack('H*', $ns =~ tr/-//dr);

    croak 'Invalid namespace given' unless length($ns) == 16;

    $digest->add($ns);
    $digest->add($data);

    return _finish(substr($digest->digest, 0, 16), 5);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Generate - format independent identifier object

=head1 VERSION

version v0.19

=head1 SYNOPSIS

    use Data::Identifier::Generate;

This module allows generation of instances of L<Data::Identifier> from common non-identifier values.
For generation of UUIDs from identifier values see L<Data::Identifier/uuid>.
The generated identifiers are of type UUID.

This can be used standalone if only an identifier for the given value is needed or as part of a generation logic.

The methods of this module might perform (limited and quick) checks for validity of the given data.
If a request is found invalid the method C<die>s.
However it is in the responsibility of the caller to ensure the data is correct. Any checks by this module
are solely meant as a last resort to finding obvious errors.

The method may also perform auto-correction. This may for example the case a obsolete value is passed and a
more current value is known.

See also:
L<Data::TagDB::Factory>.

=head1 METHODS

=head2 integer

    my Data::Identifier $identifier = Data::Identifier::Generate->integer($int [, %opts] );

Creates an identifier for the given integer.

The following options (all optional) are supported:

=over

=item C<displayname>

The displayname as to be used for the identifier.
This is the same as defined by L<Data::Identifier/new>.

Defaults to the passed number.

=back

=head2 unicode_character

    my Data::Identifier $identifier = Data::Identifier::Generate->unicode_character($type => $request [, %opts] );
    # e.g.:
    my Data::Identifier $identifier = Data::Identifier::Generate->unicode_character(unicode => 0x1F981);
    # or:
    my Data::Identifier $identifier = Data::Identifier::Generate->unicode_character(unicode => 'U+1F981');

Creates an identifier for the given unicode character.

The following types are supported:

=over

=item C<unicode>

The unicode code point as a number (e.g. C<0x1F981>) or as in the standard format (e.g. C<'U+1F981'>).

=item C<ascii>

The US-ASCII code point (e.g. C<65>).

=item C<raw>

A perl string with exactly one character. The character is

=back

The following options (all optional) are supported:

=over

=item C<allow_special>

If special characters are allowed.
This setting is a protection against false results,
specifically with C<REPLACEMENT CHARACTER> and similar characters.

Defaults to false.

=item C<displayname>

The displayname as to be used for the identifier.
This is the same as defined by L<Data::Identifier/new>.

Defaults to the data from the request.

=back

=head2 colour

    my Data::Identifier $identifier = Data::Identifier::Generate->colour($colour [, %opts ] );
    # e.g.:
    my Data::Identifier $identifier = Data::Identifier::Generate->colour('#decc9c');

Generates an identifier for a given colour.
Currently the colour must be given as a string in form C<#RRGGBB>.

The following options (all optional) are supported:

=over

=item C<displayname>

The displayname as to be used for the identifier.
This is the same as defined by L<Data::Identifier/new>.

Defaults to the data from the request.

=back

=head2 date

    my Data::Identifier $identifier = Data::Identifier::Generate->date($date [, %opts ] );

Generates an identifier for a given date.

The date must be one of the following:
A string (in form C<YYYYZ>, C<YYYY-MMZ>, or C<YYYY-MM-DDZ>) representing a gregorian date,
a number representing the time as a UNIX epoch (see L<perlfunc/time>, L<perlvar/$^T>),
a blessed object that provides C<epoch> such as L<DateTime>,
or the special values C<now> or C<today>.

B<Note:>
When dates are passed in string/ISO 8601 format they must refer to UTC and have the correct suffix C<Z>.
If you have timestamps in other timezones than UTC convert them to an epoch first and pass them as epoch.
The standard module L<DateTime> might be of help with that.
B<Just appending C<Z> to timestamps in local time or passing timestamps without the C<Z> suffix will result in wrong results!>

B<Note:>
This function currently only supports 4-digit gregorian dates.
Therfore only values for the years 1583 to 9999 (inclusive) can be calculated.

Also if the value is passed in anything but the string form the limits of L<perlfunc/gmtime> apply.
This also means that this function is year 2038 safe if C<gmtime> is.
In this case the range is also limited to the year 2999 to detect common programming errors
(the time passed as milliseconds rather than seconds).

The following options (all optional) are supported:

=over

=item C<displayname>

The displayname as to be used for the identifier.
This is the same as defined by L<Data::Identifier/new>.

Defaults to the passed date formatted as ISO 8601.

=item C<precision>

The precision to use for the identifier.
One of C<year>, C<month>, and C<day>.

Defaults to the highest possible precision available with the given date.

=back

=head2 multiplicity

    my Data::Identifier $identifier = Data::Identifier::Generate->multiplicity($subtype => $number, %opts);
    # e.g.:
    my Data::Identifier $identifier = Data::Identifier::Generate->multiplicity(minimum => 5);

(since v0.13)

Generates an identifier for a specific number of entities to be used with e.g. the C<tagpool-tagged-as> relation.
This type of identifier should be avoided if a better relation can be used.

There are currently two subtypes defined:

=over

=item C<total>

The total number of entities in a given work.
This includes background characters and entities often not noticed (e.g. flies).

It its B<strongly recommended not> to use this type unless the value can be proven.
It is recommended to use C<minimum> when in doubt.

=item C<minimum>

The minimum number of entities in a given work.
It is safe to set this to a lower value than the actual value.
E.g. tag a file with this type of identifier and only count foreground characters.

=back

The following options (all optional) are supported:

=over

=item C<displayname>

The displayname as to be used for the identifier.
This is the same as defined by L<Data::Identifier/new>.

Defaults to a name from a build in list or C<$number> if no entry is found.

=back

=head2 gte_simple

    my Data::Identifier $identifier = Data::Identifier::Generate->gte_simple($profile => $request, %opts);

(since v0.13)

Generates an identifier using simple GTE rules.
This method must not be called in list context.

This is an B<experimental> method. It may be changed, renamed, or removed without notice.

The profile is a hashref with the parameters for the profile or
the name of a well known profile or
an L<Data::Identifier> of a well known profile.
Other types might also be supported.

Currently this module does not define any well known profiles.

If it is a hashref it contains the following keys:

=over

=item C<case_folding>

Optional. The case folding rule to use. One of C<undef> or C<'none'>, C<'upper'>, and C<'lower'>.
This is applied to the request as first part of normalisation.
See also L<perlfunc/uc>, L<perlfunc/lc>, and L<perlfunc/fc>.

Defaults to C<undef>.

=item C<generator>

Optional. The same as the C<generator> option of L</generic>.

=item C<namespace>

Required. The same as the C<namespace> option of L</generic>.

=item C<order>

Required. The normal order of the subelements. This is used as part of normalisation.
The value is a string with each character being a single element.

=item C<strip_slash>

Optional. Strip all slashes (C</>) from the request as part of normalisation.

Defaults to false.

=item C<strip_spaces>

Optional. Strip all spaces (C<\s>) from the request as part of normalisation.

Defaults to false.

=back

The following, all optional, options are supported:

=over

=item C<info>

This is an B<experimental> option.
It holds a hashref that is used to pass information on the generated identifier back to the caller.

=back

=head2 generic

    my Data::Identifier $identifier = Data::Identifier::Generate->generate(%opts);

This provides a most generic interface for generation. B<It should be avoided in in favour of more specific ones.>

The following options are supported:

=over

=item C<displayname>

The displayname as to be used for the identifier.
This is the same as defined by L<Data::Identifier/new>.

This option is optional.

=item C<generator>

The identifier for this generator.
This is the same as defined by L<Data::Identifier/new>.

This option is optional.

=item C<input>

The raw input for the generator. Must be a string of raw bytes.

This option is to be avoided in favour of C<request>,
Exactly one of C<input> or C<request> must be given.

=item C<namespace>

The namespace to use. Must be an L<Data::Identifier> or raw UUID.

This option is optional if C<type> is passed with the C<type> holding an namespace.
See also L<Data::Identifier/namespace>.

=item C<request>

The request to be passed to the generator. The type and range of this value depends on
C<style> which must be provided longside C<request>.

Exactly one of C<request> or C<input> must be given.

=item C<style>

The style to be used by the generator.

Currently supported: C<integer-based>, C<id-based>, C<name-based>, C<tag-based>, C<tagcombiner>, C<colour>.

This option is required unless C<input> is provided.

For C<tag-based> the request must be a raw UUID, a L<Data::Identifier>, or anything L<Data::Identifier/new> takes via C<from>.

For C<tagcombiner> the request must be an array reference with each element of a type supported by C<tag-based>.
The array must also include at least two distinct identifiers.

=item C<type>

The type of the identifier to be passed via C<request>.

Must be a L<Data::Identifier>.

This is optional.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
