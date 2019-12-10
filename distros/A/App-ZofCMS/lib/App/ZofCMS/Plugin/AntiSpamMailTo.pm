package App::ZofCMS::Plugin::AntiSpamMailTo;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use HTML::Entities;

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $config ) = @_[0,1,3];

    return
        unless $template->{plug_anti_spam_mailto}
            or $config->conf->{plug_anti_spam_mailto};

    my $c_data = delete $config->conf->{plug_anti_spam_mailto};
    my $t_data = delete $template->{plug_anti_spam_mailto};

    my $data;
    if ( defined $c_data and defined $t_data ) {
        if ( ref $c_data ne ref $t_data ) {
            $data = $t_data;
        }
        else {
            $data = ref $t_data eq 'ARRAY'
                ? $data = [ @$t_data, @$c_data ]
                : ref $t_data eq 'HASH'
                    ? $data = { %$c_data, %$t_data }
                    : [ $t_data, $c_data ];
        }
    }
    elsif ( defined $t_data ) {
        $data = $t_data;
    }
    else {
        $data = $c_data;
    }

    if ( ref $data eq 'ARRAY' ) {
        $data = {
            map +( "mailto_$_" => $data->[$_] ),
                0.. $#$data
        };
    }
    elsif ( not ref $data ) {
        $data = { 'mailto' => $data };
    }

    encode_entities $_, '\w\W'
        for values %$data;

    @{ $template->{t} }{ keys %$data } = values %$data;

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::AntiSpamMailTo - "smart" HTML escapes to protect mailto:foo@bar.com links from not-so-smart spam bots

=head1 SYNOPSIS

In your Main Config file or ZofCMS template:

    # include the plugin
    plugins => [ qw/AntiSpamMailTo/ ],

    # then this:
    plug_anti_spam_mailto => 'bar',
    # or this:
    plug_anti_spam_mailto => [ qw/foo bar baz/ ],
    # or this:
    plug_anti_spam_mailto => {
        foo => 'bar',
        baz => 'beer',
    },

In your L<HTML::Template> template:

    <tmpl_var name="mailto">
    # or this:
    <tmpl_var name="mailto_0"> <tmpl_var name="mailto_1"> <tmpl_var name="mailto_2">
    # or this:
    <tmpl_var name="foo"> <tmpl_var name="baz">

=head1 DESCRIPTION

The module is an L<App::ZofCMS> plugin which provides means to deploy a
technique that many
claim to be effective in protecting your
C<< <a href="mailto:foo@bar.com"></a> >> links
from dumb spam bots.

The technique is quite simple (and simple to circumvent, but we are
talking about B<dumb>
spam bots) - the entire contents of C<href=""> attribute are encoded
as HTML entities. Dumb
spam bots miss the C<mailto:> and go their way. As of the day of this
writing, I have about 14 sites that have been using this plugin for
3+ years and I might have received one spam email to the email address
shown by the plugin. Anyway, on to the business.

This documentation assumes you have read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG/ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plug_anti_spam_mailto>

    plug_anti_spam_mailto => 'bar',

    plug_anti_spam_mailto => [ qw/foo bar baz/ ],

    plug_anti_spam_mailto => {
        foo => 'bar',
        baz => 'beer',
    },

The plugin takes it's data from C<plug_anti_spam_mailto> first-level key that is in either
ZofCMS template or config file. The key takes either a string, arrayref or a hashref as its
value. If the key is specified in both main config file and ZofCMS template B<and> the value
is of the same type (string, arrayref or hashref) then both values will be interpreted by
the plugin; in case of the hashref, any duplicate keys will obtain the value assigned to
them in ZofCMS template. B<Note:> if the value is of "type" C<string> specified in B<both>
main config file and ZofCMS template it will interpreted as an arrayref with two elements.
Now I'll tell you why this all matters:

=head3 value is a string

    plug_anti_spam_mailto => 'bar',

When the value is a string then in L<HTML::Template> template you'd access the converted
data via variable C<mailto>, i.e. C<< <tmpl_var name="mailto"> >>

=head3 value is an arrayref or a string in both ZofCMS template and main config file

    plug_anti_spam_mailto => [ qw/foo bar baz/ ],

To access converted data when the value is an arrayref you'd use C<mailto_NUM> where C<NUM>
is the index of the element in the arrayref. In other words, to access value C<bar> in the
example above you'd use C<< <tmpl_var name="mailto_1"> >>

=head3 value is a hashref

    plug_anti_spam_mailto => {
        foo => 'bar',
        baz => 'beer',
    },

You do not have to keep typing C<mailto> to access your converted data. When value is a hashref
the values of that hashref are the data to be converted and the keys are the names of
C<< <tmpl_var name""> >>s into which to stick that data. In the example above, to access
converted data for C<beer> you'd use C<< <tmpl_var name="baz"> >>

=head1 EXAMPLE

ZofCMS template:

    plugins => [ qw/AntiSpamMailTo/ ],
    plug_anti_spam_mailto => 'mailto:john.foo@example.com',

L<HTML::Template> template:

    <a href="<tmpl_var name="mailto">">email to John Foo</a>

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