package App::ZofCMS::Plugin::LinkifyText;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use URI::Find::Schemeless;
use HTML::Entities;
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_linkify_text' }
sub _defaults {
    cell => 't',
    key  => 'plug_linkify_text',
    encode_entities => 1,
    new_lines_as_br => 1,
    text => undef,
    callback => sub {
        my $uri = encode_entities $_[0];
        return qq|<a href="$uri">$uri</a>|;
    },
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    if ( ref $conf->{text} eq 'CODE' ) {
        $conf->{text} = $conf->{text}->( $t, $q, $config );
    }

    return
        unless defined $conf->{text}
            and length $conf->{text};

    if ( ref $conf->{text} eq 'ARRAY' ) {
        my @results;
        for ( @{ $conf->{text} } ) {
            push @results, { text => process_text( $conf, $_ ) };
        }
        $t->{ $conf->{cell} }{ $conf->{key} } = \@results;
    }
    elsif ( ref $conf->{text} eq 'REF' ) {
        process_in_place_edits( $conf, $t );
    }
    else {
        $t->{ $conf->{cell} }{ $conf->{key} }
        = process_text( $conf, $conf->{text} );
    }
}

sub process_in_place_edits {
    my ( $conf, $t ) = @_;

    my @text_keys = grep /^text\d*$/, keys %$conf;

    for my $conf_key ( @text_keys ) {
        my $text_ref = ref $conf->{$conf_key} eq 'REF' ?
            ${ $conf->{$conf_key} } : $conf->{$conf_key};

        if ( ref $text_ref eq 'ARRAY' ) {
            my ( $data_key, @text_keys ) = @$text_ref;
            for my $text_hashref ( @{ $t->{t}{$data_key} || [] } ) {
                for ( @text_keys ) {
                    $text_hashref->{$_}
                    = process_text( $conf, $text_hashref->{$_} );
                }
            }
        }
        else {
            $text_ref = $$text_ref
                if ref $text_ref;

            $t->{t}{$text_ref} = process_text( $conf, $t->{t}{$text_ref} );
        }
    }
}

sub process_text {
    my ( $conf, $text ) = @_;

    if ( $conf->{encode_entities} ) {
        encode_entities $text;

        $text =~ s/\r?\n/<br>/g
            if $conf->{new_lines_as_br};
    }

    URI::Find::Schemeless->new( $conf->{callback} )->find( \$text );
    return $text;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::LinkifyText - plugin to convert links in plain text into proper HTML <a> elements

=head1 SYNOPSIS

In ZofCMS Template or Main Config File:

    plugins => [
        qw/LinkifyText/,
    ],

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        encode_entities => 1, # this one and all below are optional; default values are shown
        new_lines_as_br => 1,
        cell => 't',
        key  => 'plug_linkify_text',
        callback => sub {
            my $uri = encode_entities $_[0];
            return qq|<a href="$uri">$uri</a>|;
        },
    },

In HTML::Template template:

    <tmpl_var name='plug_linkify_text'>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means convert
URIs found in plain text into proper <a href=""> HTML elements.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        qw/LinkifyText/,
    ],

B<Mandatory>. You need to include the plugin to the list of plugins to execute.

=head2 C<plug_linkify_text>

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        encode_entities => 1,
        new_lines_as_br => 1,
        cell => 't',
        key  => 'plug_linkify_text',
        callback => sub {
            my $uri = encode_entities $_[0];
            return qq|<a href="$uri">$uri</a>|;
        },
    },

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        encode_entities => 1,
        new_lines_as_br => 1,
        cell => 't',
        key  => 'plug_linkify_text',
        callback => sub {
            my $uri = encode_entities $_[0];
            return qq|<a href="$uri">$uri</a>|;
        },
    },

    plug_linkify_text => sub {
        my ( $t, $q, $config ) = @_;
        return {
            text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        }
    }

B<Mandatory>. Takes a hashref or a subref as a value; individual keys can be set in
both Main Config
File and ZofCMS Template, if the same key set in both, the value in ZofCMS
Template will
take precedence. If subref is specified,
its return value will be assigned to C<plug_linkify_text> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object.
The following keys/values are accepted:

=head3 C<text>

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
    }

    plug_linkify_text => {
        text => [
            qq|http://zoffix.com|,
            qq|foo\nbar\nhaslayout.net|,
        ]
    }

    plug_linkify_text => {
        text => sub {
            my ( $t, $q, $config ) = @_;
            return $q->{text_to_linkify};
        },
    }

    plug_linkify_text => {
        text  => \[ qw/replies  reply_text/ ],
        text2 => 'post_text',
        text3 => [ qw/comments  comment_text  comment_link_text/ ],
    }

B<Pseudo-Mandatory>; if not specified (or C<undef>) plugin will not run.
Takes a wide range of values:

=head4 subref

    plug_linkify_text => {
        text => sub {
            my ( $t, $q, $config ) = @_;
            return $q->{text_to_linkify};
        },
    }

If set to a subref, the sub's C<@_> will contain C<$t>, C<$q>,
and C<$config> (in that order), where C<$t> is ZofCMS Template hashref,
C<$q> is query parameter hashref, and C<$config> is L<App::ZofCMS::Config>
object. The return value from the sub can be any valid value accepted
by the C<text> argument (except the subref) and the plugin will proceed
as if the returned value was assigned to C<text> in the first place
(including the C<undef>, upon which the plugin will stop executing).

=head4 scalar

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
    }

If set to a scalar, the plugin will interpret the scalar as the string
that needs to be linkified (i.e. links in the text changed to HTML links).
Processed string will be stored into C<key> key under C<cell> first-level
key (see the description for these below).

=head4 arraref

    plug_linkify_text => {
        text => [
            qq|http://zoffix.com|,
            qq|http://zoffix.com|,
        ]
    }

    # output:
    $VAR1 = {
        't' => 'plug_linkify_text' => [
            { text => '<a href="http://zoffix.com/">http://zoffix.com/</a>' },
            { text => '<a href="http://zoffix.com/">http://zoffix.com/</a>' },
    };

If set to an arrayref, each element of that arrayref will be taken
as a string that needs to be linkified. The output will be stored
into C<key> key under C<cell> first-level key, and that output will be
an arrayref of hashrefs. Each hashref will have only one key - C<text> -
value of which is the converted text (thus you can use this arrayref
directly in C<< <tmpl_loop> >>)

=head4 a ref of a ref

    plug_linkify_text => {
        text  => \[ qw/replies  reply_text/ ],
        text2 => 'post_text',
        text3 => [ qw/comments  comment_text  comment_link_text/ ],
    }

Lastly, C<text> can be set to a... ref of a ref (bare with me). I think
it's easier to understand the functionality when it's viewed as a
following sequential process:

When C<text> is set to a ref of a ref, the plugin enables the I<inplace>
edit mode. This is as far as this goes, and plugin dereferences this
ref of a ref into an arrayref or a scalarref. Along with a simple scalar,
these entities can be assigned to any I<extra> C<text> keys (see below).
What I<inplace> edit mode means is that C<text> no longer contains direct
strings of text to linkify, but rather an address of where to find,
and edit, those strings.

When I<inplace> mode is turned on, you can tell plugin to linkify
multiple places. In order to specify another address for a string to edit,
simply add another C<text> postfixed with a number (e.g. C<text4>; what
the actual number is does not matter, the key just needs to match
C<qr/^text\d+$/>). The values of all the B<extra> C<text> keys do not have
to be refs of refs, but rather can be either scalars, scalarrefs
or arrayrefs.

A scalar and scalarref have same meaning here, i.e. the scalarref will
be automatically dereferenced into a scalar. A simple scalar tells the
plugin that the value of this scalar is the name of a key inside
C<{t}> ZofCMS Template special key, value of which contains the text to
be linkified. The plugin will directly modify (linkify) that text. This
can be used, for example, when you use L<App::ZofCMS::Plugin::DBI> plugin's
"single" retrieval mode.

The arrayrefs have different meaning. Their purpose is to process
B<arrayrefs of hashrefs> (this will probably conjure up
L<App::ZofCMS::Plugin::DBI> plugin's output in your mind). The first
item in the arrayref represents the name of the key inside the
C<{t}> ZofCMS Template special key's hashref; the value of that key is
the arrayref of hashrefs. All the following (one or more) items in the
arrayref represent hashref keys that point to data to linkify.

Let's take a look at actual code examples. Let's imagine your C<{t}>
special key contains the following arrayref, say, put there by DBI plugin;
this arrayref is referenced by a C<dbi_output> key here. Also in the
example, the C<dbi_output_single> is set to a scalar, a string of text that
we want to linkify:

    dbi_output => [
        { ex => 'foo', ex2 => 'bar' },
        { ex => 'ber', ex2 => 'beer' },
        { ex => 'baz', ex2 => 'craz' },
    ],
    dbi_output_single => 'some random text',

If you want to linkify all the texts inside C<dbi_output>
to which the C<ex> keys point, you'd set C<text> value as
C<< text => \[ qw/dbi_output  ex/ ] >>. If you want to linkify the C<ex2>
data as well, then you'd set C<text> as
C<< text => \[ qw/dbi_output  ex  ex2/ ] >>. Can you guess what the code
to linkify I<all> the text in the example above will be? Here it is:

    # note that we are assigning a REF of an arrayref to the first `text`
    plug_linkify_text => {
        text    => \[
            'dbi_output',  # the key inside {t}
            'ex', 'ex2'    # keys of individual hashrefs that point to data
        ],
        text2   => 'dbi_output_single', # note that we didn't have to make this a ref
    }

    # here's an alternative version that does the same thing:
    plug_linkify_text => {
        text    => \\'dbi_output_single', # note that this is a ref of a ref
        text554 => [  # this now doesn't have to be a ref of a ref
            'dbi_output',  # the key inside {t}
            'ex', 'ex2'    # keys of individual hashrefs that point to data
        ],
    }

=head3 C<encode_entities>

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        encode_entities => 1,
    }

B<Optional>. Takes either true or false values. When set to a true
value, plugin will encode HTML entities in the provided text before
processing URIs. B<Defaults to:> C<1>

=head3 C<new_lines_as_br>

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        new_lines_as_br => 1,
    }

B<Optional>. Applies only when C<encode_entities> (see above) is set
to a true value. Takes either true or false values. When set to
a true value, the plugin will convert anything that matches C</\r?\n/>
into HTML <br> element. B<Defaults to:> C<1>

=head3 C<cell>

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        cell => 't',
    }

B<Optional>. Takes a literal string as a value. Specifies the name
of the B<first-level> key in ZofCMS Template hashref into which to put
the result; this key must point to either an undef value or a hashref.
See C<key> argument below as well.
B<Defaults to:> C<t>

=head3 C<key>

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        key  => 'plug_linkify_text',
    }

B<Optional>. Takes a literal string as a value. Specifies the name
of the B<second-level> key that is inside C<cell> (see above) key -
plugin's output will be stored into this key.
B<Defaults to:> C<plug_linkify_text>

=head3 C<callback>

    plug_linkify_text => {
        text => qq|http://zoffix.com foo\nbar\nhaslayout.net|,
        callback => sub {
            my $uri = encode_entities $_[0];
            return qq|<a href="$uri">$uri</a>|;
        },
    },

B<Optional>. Takes a subref as a value. This subref will be used
as the "callback" sub in L<URI::Find::Schemeless>'s C<find()> method.
See L<URI::Find::Schemeless> for details. B<Defaults to:>

    sub {
        my $uri = encode_entities $_[0];
        return qq|<a href="$uri">$uri</a>|;
    },

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut