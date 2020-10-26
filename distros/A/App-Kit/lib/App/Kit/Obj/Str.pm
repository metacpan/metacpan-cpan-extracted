package App::Kit::Obj::Str;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

our $VERSION = '0.1';

sub portable_crlf {
    return "\015\012";    # "\r\n" is not portable
}

sub zero_but_true { return "0E0"; }

Sub::Defer::defer_sub __PACKAGE__ . '::bytes_size' => sub {
    require String::UnicodeUTF8;
    return sub {
        shift;
        goto &String::UnicodeUTF8::bytes_size;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::char_count' => sub {
    require String::UnicodeUTF8;
    return sub {
        shift;
        goto &String::UnicodeUTF8::char_count;
    };
};

has prefix => (
    is   => 'rw',
    lazy => 1,
    isa  => sub {
        die "prefix must be at least 1 character"      unless length( $_[0] ) > 0;
        die "prefix can only contain A-Z and 0-9"      unless $_[0] =~ m/\A[A-Za-z0-9]+\z/;
        die "prefix can not be more than 6 characters" unless length( $_[0] ) < 7;
    },
    default => sub { return 'appkit' },
);

Sub::Defer::defer_sub __PACKAGE__ . '::rand' => sub {
    require Data::Rand;
    return sub {
        shift;
        goto &Data::Rand::rand_data_string;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::yaml_to_ref' => sub {
    require YAML::Syck;
    return sub {
        my ( $self, $yaml ) = @_;

        # See fs->yaml_read
        local $YAML::Syck::ImplicitTyping = 0;
        return YAML::Syck::Load($yaml);    # already does ♥ instead of \xe2\x99\xa5 (i.e. so no need for String::UnicodeUTF8::unescape_utf8() like w/ the YAML above)
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::ref_to_yaml' => sub {
    require YAML::Syck;
    return sub {
        my ( $self, $ref ) = @_;

        # See fs->yaml_write

        local $YAML::Syck::ImplicitTyping = 0;
        local $YAML::Syck::SingleQuote    = 1;    # to keep from arbitrary quoting/unquoting (to help make diff's cleaner)
        local $YAML::Syck::SortKeys       = 1;    # to make diff's cleaner

        return YAML::Syck::Dump($ref);            # as of at least v1.27 it writes the characters without \x escaping so no need to String::UnicodeUTF8::unescape_utf8 the result
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::json_to_ref' => sub {
    require JSON::Syck;
    return sub {
        shift;
        goto &JSON::Syck::Load;                   # already does ♥ instead of \xe2\x99\xa5 (i.e. so no need for String::UnicodeUTF8::unescape_utf8() like w/ the YAML above)
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::ref_to_json' => sub {
    require JSON::Syck;
    return sub {
        shift;
        goto &JSON::Syck::Dump;                   # already does ♥ instead of \xe2\x99\xa5 (i.e. so no need for String::UnicodeUTF8::unescape_utf8() like w/ the YAML above)
    };
};

sub ref_to_jsonp {
    my ( $app, $ref, $function ) = @_;
    $function ||= 'jsonp_callback';
    return if $function =~ m/[^0-9a-zA-Z_]/;
    return $function . '(' . $app->ref_to_json($ref) . ');';
}

Sub::Defer::defer_sub __PACKAGE__ . '::sha512' => sub {
    require Digest::SHA;
    return sub {
        shift;
        goto &Digest::SHA::sha512_hex;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::trim' => sub {
    require String::UnicodeUTF8;

    # regex is made from the Unicode code points from: `unichars '\p{WhiteSpace}'` (sans SPACE and NO-BREAK SPACE)
    my $disallowed_whitespace = qr/(?:\x09|\x0a|\x0b|\x0c|\x0d|\xc2\x85|\xe1\x9a\x80|\xe1\xa0\x8e|\xe2\x80\x80|\xe2\x80\x81|\xe2\x80\x82|\xe2\x80\x83|\xe2\x80\x84|\xe2\x80\x85|\xe2\x80\x86|\xe2\x80\x87|\xe2\x80\x88|\xe2\x80\x89|\xe2\x80\x8a|\xe2\x80\xa8|\xe2\x80\xa9|\xe2\x80\xaf|\xe2\x81\x9f|\xe3\x80\x80)/;

    # regex is made from the Unicode code points from: `uninames invisible`
    my $invisible = qr/(?:\xe2\x80\x8b|\xe2\x81\xa2|\xe2\x81\xa3|\xe2\x81\xa4)/;

    # regex is made from the Unicode code points from: `unichars '\p{Control}'`
    my $control =
      qr/(?:\x00|\x01|\x02|\x03|\x04|\x05|\x06|\x07|\x08|\x09|\x0a|\x0b|\x0c|\x0d|\x0e|\x0f|\x10|\x11|\x12|\x13|\x14|\x15|\x16|\x17|\x18|\x19|\x1a|\x1b|\x1c|\x1d|\x1e|\x1f|\x7f|\xc2\x80|\xc2\x81|\xc2\x82|\xc2\x83|\xc2\x84|\xc2\x85|\xc2\x86|\xc2\x87|\xc2\x88|\xc2\x89|\xc2\x8a|\xc2\x8b|\xc2\x8c|\xc2\x8d|\xc2\x8e|\xc2\x8f|\xc2\x90|\xc2\x91|\xc2\x92|\xc2\x93|\xc2\x94|\xc2\x95|\xc2\x96|\xc2\x97|\xc2\x98|\xc2\x99|\xc2\x9a|\xc2\x9b|\xc2\x9c|\xc2\x9d|\xc2\x9e|\xc2\x9f)/;

    return sub {
        my ( $str, $string, $collapse ) = @_;

        my $is_unicode = String::UnicodeUTF8::is_unicode($string);

        $string = String::UnicodeUTF8::get_utf8($string);

        $string =~ s/(?:$disallowed_whitespace|$invisible|$control)+//g;
        $string =~ s/^(?:\x20|\xc2\xa0)+//;
        $string =~ s/(?:\x20|\xc2\xa0)+$//;

        $string =~ s/(?:\x20|\xc2\xa0){2,}/ /g if $collapse;

        return $is_unicode ? String::UnicodeUTF8::get_unicode($string) : $string;
    };
};

sub epoch {
    return time;
}

sub attrs {
    my ( $str, $attr_hr, $ignore ) = @_;
    return '' if !keys %{$attr_hr};
    return ' ' . join(
        ' ',
        map { exists $ignore->{$_} ? () : !defined $attr_hr->{$_} ? $_ : $_ . '="' . $str->escape_html( $attr_hr->{$_} ) . '"' }
          keys %{$attr_hr}

    );
}

Sub::Defer::defer_sub __PACKAGE__ . '::escape_html' => sub {
    require HTML::Escape;
    return sub {
        shift;
        goto &HTML::Escape::escape_html;
    };
};

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Obj::Str - string utility object

=head1 VERSION

This document describes App::Kit::Obj::Str version 0.1

=head1 SYNOPSIS

    my $str = App::Kit::Obj::Str->new();
    $str->char_count(…)

=head1 DESCRIPTION

string utility object

=head1 INTERFACE

=head2 new()

Returns the object. takes one optional attribute, “prefix”.

“prefix” is intended to be used as your app’s prefix string (e.g. a database's table names).

The default is “appkit”.

Currently it must be between 1 and 6 characters and the characters can only be A-Z, a-z, 0-9.

=head2 char_count()

Lazy wrapper of L<String::UnicodeUTF8>’s char_count().

=head2 bytes_size()

Lazy wrapper of L<String::UnicodeUTF8>’s bytes_size().

=head2 prefix()

Get/Set the prefix attribute.

=head2 portable_crlf()

Returns a portable CRLF. (i.e. \r\n is not portable)

=head2 zero_but_true()

Returns a zero-but-true string.

=head2 rand()

Returns a random string.

1st arg is the number of items (default 32).

2nd arg is the array ref of items (default 0 .. 9 and upper and lower case a-z)

Lazy wrapper of wrapper L<Data::Rand>’s rand_data_string().

=head2 yaml_to_ref()

Lazy wrapper of L<YAML::Syck>’s Load().

=head2 ref_to_yaml()

Lazy wrapper of L<YAML::Syck>’s Dump().

=head2 json_to_ref()

Lazy wrapper of L<JSON::Syck>’s Load().

=head2 ref_to_json()

Lazy wrapper of L<JSON::Syck>’s Dump().

=head2 ref_to_jsonp()

Like ref_to_json() but pads it. The function name defaults to “jsonp_callback” but can be given as a second argument.

return()’s if you give it a function name with anything besides [0-9a-zA-Z_].

=head2 trim()

Takes a string (unicode or utf8 bytes)

and returns a version of it with all unicode whitespace (except space and non-break-space), invisible, and control characters removed and also leading and trailing space/non-break-space removed

A second boolean argument (default false) will collapse multiple space/non-break-space sequences down to a single space.

=head2 sha512()

Lazy wrapper of L<Digest::SHA>’s sha512_hex().

=head2 epoch()

Takes no arguments, returns the current epoch.

=head2 attrs()

Take a hashref of attributes to stringify. There will be a leading space (to avoid extra space in output/logic in template use).

If the value is undef then only the name is output (e.g. for HTML5-osh boolean attributes). The values are HTML escaped.

If order matters build them from multiple calls in the order you want.

    $str->attrs({class=>"foo bar", required=>undef}) # ' class="foo bar" required'

Takes a second optional argument that is a lookup hashref of attributes to ignore.

    $str->attrs({class=>"foo bar", required=>undef}, {class=>1}) # ' required'

=head2 escape_html()

Lazy wrapper of L<HTML::Escape>’s escape_html().

=head1 DIAGNOSTICS

Setting the prefix to an invalid value can result in an error that is descriptive of the problem.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<String::UnicodeUTF8>

L<Data::Rand>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
