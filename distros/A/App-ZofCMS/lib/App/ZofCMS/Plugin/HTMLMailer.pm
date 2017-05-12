package App::ZofCMS::Plugin::HTMLMailer;

use warnings;
use strict;
use base 'App::ZofCMS::Plugin::Base';
use MIME::Lite;
use HTML::Template;
use File::Spec::Functions (qw/catfile/);

our $VERSION = '1.001007'; # VERSION

sub _key { 'plug_htmlmailer' }

sub _defaults {
    return (
        #to                      => [ qw/foo@bar.com ber@bar.com/ ],
        #template                => 'mail_templates/new-forum-post.tmpl',

        subject                 => '',
        template_dir            => undef,
        precode                 => undef,
        mime_lite_params        => undef,
        from                    => undef,
        cc                      => undef,
        bcc                     => undef,
        template_params         => undef,
        html_template_object    => undef,
    );
}

sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    for ( qw/to  bcc  cc / ) {
        $conf->{$_} = $conf->{$_}->( $t, $q, $config )
            if ref $conf->{$_} eq 'CODE';

        $conf->{$_} = [ $conf->{$_} ]
            if ref $conf->{$_} ne 'ARRAY'
                and defined $conf->{$_}
                and length $conf->{$_};
    }

    $conf->{attach} = $conf->{attach}->( $t, $q, $config )
            if ref $conf->{attach} eq 'CODE';

    $conf->{attach} = [ $conf->{attach} ]
        if $conf->{attach}
            and ref $conf->{attach}[0] ne 'ARRAY';

    return
        unless @{ $conf->{to} || [] }
            and (
                ( defined $conf->{template} and length $conf->{template} )
                or defined $conf->{html_template_object}
            );

    if ( ref $conf->{precode} eq 'CODE' ) {
        $conf->{precode}->( $t, $q, $config, $conf );
    }

    my $temp = $conf->{html_template_object}
    || HTML::Template->new(
        filename => (
            ( defined $conf->{template_dir}
                and length $conf->{template_dir}
            ) ? catfile( $conf->{template_dir}, $conf->{template} )
            : $conf->{template_dir},
        ),
        die_on_bad_params => 0,
    );

    $conf->{template_params} = $conf->{template_params}->( $t, $q, $config )
        if ref $conf->{template_params} eq 'CODE';

    $temp->param( @{ $conf->{template_params} } )
        if @{ $conf->{template_params} || [] };

    my $msg = MIME::Lite->new (
        Subject => $conf->{subject},
        ( defined $conf->{from} ? ( From => $conf->{from} ) : (), ),
        To      => ( join ',', @{ $conf->{to} } ),
        ( ( defined $conf->{bcc} ) ? ( Bcc => ( join ',', @{ $conf->{bcc} } ), ) : () ),
        ( ( defined $conf->{cc} ) ? ( cc => ( join ',', @{ $conf->{cc} } ), ) : () ),
        Type    => 'text/html',
        Data    => $temp->output,
    );

    for ( @{ $conf->{attach} || [] } ) {
        $msg->attach( @$_ );
    }

    MIME::Lite->send( @{ $conf->{mime_lite_params} } )
        if $conf->{mime_lite_params};

    $msg->send;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::HTMLMailer - ZofCMS plugin for sending HTML email

=head1 SYNOPSIS

    plugins => [
        { HTMLMailer => 2000, },
    ],

    plug_htmlmailer => {
        to          => 'cpan@zoffix.com',
        template    => 'email-template.tmpl',

        # everything below is optional
        template_params => [
            foo => 'bar',
            baz => 'ber',
        ],
        subject         => 'Test Subject',
        from            => 'Zoffix Znet <any.mail@fake.com>',
        cc              => 'foo@bar.com',
        bcc             => [ 'agent42@fbi.com', 'foo@bar2.com' ],
        template_dir    => 'mail-templates',
        precode         => sub {
            my ( $t, $q, $config, $plug_conf ) = @_;
            # run some code
        },
        mime_lite_params => [
            'smtp',
            'srvmail',
            Auth   => [ 'FOOBAR/foos', 'p4ss' ],
        ],
        html_template_object => HTML::Template->new(
            filename            => 'mail-templates/email-template.tmpl',
            die_on_bad_params   => 0,
        ),
        attach => [
            Type     => 'image/gif',
            Path     => 'aaa000123.gif',
            Filename => 'logo.gif',
            Disposition => 'attachment'
        ],
    },

=head1 DESCRIPTION

The module is a ZofCMS plugin that provides means to easily create an
email from an L<HTML::Template> template, fill it, and email it as an HTML
email.

This documentation assumes you've read
L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    plugins => [ qw/HTMLMailer/ ],

First and obvious, you need to stick C<HTMLMailer> in the list of your
plugins.

=head2 C<plug_htmlmailer>

    plug_htmlmailer => {
        to          => 'cpan@zoffix.com',
        template    => 'email-template.tmpl',

        # everything below is optional
        template_params => [
            foo => 'bar',
            baz => 'ber',
        ],
        subject         => 'Test Subject',
        from            => 'Zoffix Znet <any.mail@fake.com>',
        cc              => 'foo@bar.com',
        bcc             => [ 'agent42@fbi.com', 'foo@bar2.com' ],
        template_dir    => 'mail-templates',
        precode         => sub {
            my ( $t, $q, $config, $plug_conf ) = @_;
            # run some code
        },
        mime_lite_params => [
            'smtp',
            'srvmail',
            Auth   => [ 'FOOBAR/foos', 'p4ss' ],
        ],
        html_template_object => HTML::Template->new(
            filename            => 'mail-templates/email-template.tmpl',
            die_on_bad_params   => 0,
        ),
    },

B<Mandatory>. Takes either a hashref or a subref as a value. If subref is
specified, its return value will be assigned to C<plug_htmlmailer> as if
it was already there. If sub returns an C<undef>, then plugin will stop
further processing. The C<@_> of the subref will contain (in that order):
ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Possible keys/values for the hashref
are as follows:

=head3 C<to>

    plug_htmlmailer => {
        to => 'foo@bar.com',
    ...

    plug_htmlmailer => {
        to => [ 'foo@bar.com', 'ber@bar.com', ],
    ...

    plug_htmlmailer => {
        to => sub {
            my ( $t, $q, $config ) = @_;
            return [ 'foo@bar.com', 'ber@bar.com', ];
        }
    ...

B<Mandatory>. Specifies the email address(es) to which to send the email.
Takes a scalar, an arrayref or a subref as a value. If a scalar is
specified, plugin will create a single-item arrayref with it; if an
arrayref is specified, each of its items will be interpreted as an
email address to which to send email. If a subref is specified, its return
value will be assigned to the C<to> key and its C<@_> array will contain:
C<$t>, C<$q>, C<$config> (in that order) where C<$t> is ZofCMS Template
hashref, C<$q> is the query parameter hashref and C<$config> is the
L<App::ZofCMS::Config> object. B<Default:> if the C<to> key is not defined
(or the subref to which it's set returns undef) then the plugin will stop
further processing.

=head3 C<cc>

    plug_htmlmailer => {
        cc => 'foo@bar.com',
    ...

    plug_htmlmailer => {
        cc => [ 'foo@bar.com', 'ber@bar.com', ],
    ...

    plug_htmlmailer => {
        cc => sub {
            my ( $t, $q, $config ) = @_;
            return [ 'foo@bar.com', 'ber@bar.com', ];
        }
    ...

B<Optional>. Specifies "Cc" (carbon copy) email address(es) to which to send the email.
Takes a scalar, an arrayref or a subref as a value. If a scalar is
specified, plugin will create a single-item arrayref with it; if an
arrayref is specified, each of its items will be interpreted as an
email address to which to send email. If a subref is specified, its return
value will be assigned to the C<cc> key and its C<@_> array will contain:
C<$t>, C<$q>, C<$config> (in that order) where C<$t> is ZofCMS Template
hashref, C<$q> is the query parameter hashref and C<$config> is the
L<App::ZofCMS::Config> object. B<Default:> not specified

=head3 C<bcc>

    plug_htmlmailer => {
        bcc => 'foo@bar.com',
    ...

    plug_htmlmailer => {
        bcc => [ 'foo@bar.com', 'ber@bar.com', ],
    ...

    plug_htmlmailer => {
        bcc => sub {
            my ( $t, $q, $config ) = @_;
            return [ 'foo@bar.com', 'ber@bar.com', ];
        }
    ...

B<Optional>. Specifies "Bcc" (blind carbon copy) email address(es)
to which to send the email.
Takes a scalar, an arrayref or a subref as a value. If a scalar is
specified, plugin will create a single-item arrayref with it; if an
arrayref is specified, each of its items will be interpreted as an
email address to which to send email. If a subref is specified, its return
value will be assigned to the C<bcc> key and its C<@_> array will contain:
C<$t>, C<$q>, C<$config> (in that order) where C<$t> is ZofCMS Template
hashref, C<$q> is the query parameter hashref and C<$config> is the
L<App::ZofCMS::Config> object. B<Default:> not specified

=head3 C<template>

    plug_htmlmailer => {
        template => 'email-template.tmpl',
    ...

B<Mandatory, unless> C<html_template_object> B<(see below) is specified>.
Takes a scalar as a value that represents the location of the
L<HTML::Template> template to use as the body of your email. If relative
path is specified, it will be relative to the location of C<index.pl> file.
B<Note:> if C<template_dir> is specified, it will be prepended to whatever
you specify here.

=head3 C<template_params>

    plug_htmlmailer => {
        template_params => [
            foo => 'bar',
            baz => 'ber',
        ],
    ...

    plug_htmlmailer => {
        template_params => sub {
            my ( $t, $q, $config ) = @_:
            return [ foo => 'bar', ];
        }
    ...

B<Optional>. Specifies key/value parameters for L<HTML::Template>'s
C<param()> method; this will be called on the L<HTML::Template> template
of your email body (specified by C<template> argument).
Takes an arrayref or a subref as a value. If subref is
specified, its C<@_> will contain C<$t>, C<$q>, and C<$config> (in that
order), where C<$t> is ZofCMS Template hashref, C<$q> is query parameter
hashref, and C<$config> is L<App::ZofCMS::Config> object. The subref must
return either an arrayref or an C<undef> (or empty list), and that will be
assigned to C<template_params> as a true value. B<By default> is not
specified.

=head3 C<subject>

    plug_htmlmailer => {
        subject => 'Test Subject',
    ...

B<Optional>. Takes a scalar as a value that specifies the subject line
of your email. B<Default:> empty string.

=head3 C<from>

    plug_htmlmailer => {
        from => 'Zoffix Znet <any.mail@fake.com>',
    ...

B<Optional>. Takes a scalar as a value that specifies the C<From> field
for your email. If not specified, the plugin will simply not set the
C<From> argument in L<MIME::Lite>'s C<new()> method (which is what
this plugin uses under the hood). See L<MIME::Lite>'s docs for more
description. B<By default> is not specified.

=head3 C<template_dir>

    plug_htmlmailer => {
        template_dir => 'mail-templates',
    ...

B<Optional>. Takes a scalar as a value. If specified, takes either an
absolute or relative path to the directory that contains all your
L<HTML::Template> email templates (see C<template> above for more info). If
relative path is specified, it will be relative to the C<index.pl> file.
The purpose of this argument is to simply have a shortcut to save you the
trouble of specifying the directory every time you use C<template>.
B<By default> is not specified.

=head3 C<precode>

    plug_htmlmailer => {
        precode => sub {
            my ( $t, $q, $config, $plug_conf ) = @_;
            # run some code
        },
    ...

B<Optional>. Takes a subref as a value. This is just an "insertion point",
a place to run a piece of code if you really have to. The C<@_> of the
subref will contain C<$t>, C<$q>, C<$config>, and C<$plug_conf> (in that
order), where C<$t> is ZofCMS Template hashref, C<$q> is query parameters
hashref, C<$config> is L<App::ZofCMS::Config> object, and C<$plug_conf>
is the configuration hashref of this plugin (that is the
C<plug_htmlmailer> hashref). You can use C<$plug_conf> to stick modified
configuration arguments to the I<current run> of this plugin (modifications
will not be saved past current run stage). The subref will be executed
B<after> the C<to> argument is processed, but before anything else is
done. B<Note:> if C<to> is not set (or set to subref that returns undef)
then the C<precode> subref will B<NOT> be executed at all. B<By default>
is not specified.

=head3 C<mime_lite_params>

    plug_htmlmailer => {
        mime_lite_params => [
            'smtp',
            'srvmail',
            Auth   => [ 'FOOBAR/foos', 'p4ss' ],
        ],
    ...

B<Optional>. Takes an arrayref as a value. If specified, the arrayref
will be directly dereferenced into C<< MIME::Lite->send() >>. Here you
can set any special send arguments you need; see L<MIME::Lite> docs for
more info. B<By default> is not specified.

=head3 C<html_template_object>

    plug_htmlmailer => {
        html_template_object => HTML::Template->new(
            filename            => 'mail-templates/email-template.tmpl',
            die_on_bad_params   => 0,
        ),
    ...

B<Optional>. Takes an L<HTML::Template> object (or something that behaves
like one). If specified, the C<template> and C<template_dir> arguments
will be ignored and the object you specify will be used instead. B<Note:>
the default L<HTML::Template> object (used when C<html_template_object>
is B<not> specified) has C<die_on_bad_params> argument set to a false
value; using C<html_template_object> you can change that.
B<By default> is not specified.

=head3 C<attach>

    plug_htmlmailer => {
        attach => [
            Type     => 'image/gif',
            Path     => 'aaa000123.gif',
            Filename => 'logo.gif',
            Disposition => 'attachment'
        ],
    ...

    plug_htmlmailer => {
        attach => [
            [
                Type     => 'image/gif',
                Path     => 'aaa000123.gif',
                Filename => 'logo1.gif',
                Disposition => 'attachment'
            ],
            [
                Type     => 'TEXT',
                Data     => "Here's the GIF file you wanted"
            ],
        ],
    ...

    plug_htmlmailer => {
        attach => sub {
            my ( $t, $q, $config ) = @_;
            return [
                Type     => 'TEXT',
                Data     => "Here's the GIF file you wanted"
            ];
        }
    ...

B<Optional>. Provides access to the C<attach> method of L<MIME::Lite>, e.g.
gives you an ability to attach files to your emails.
Takes an arrayref, an arrayref of arrayrefs, or a subref as a value. If an arrayref is
specified, plugin will create a single-item arrayref with it (so it'll be nested); if an
arrayref of arrayrefs is specified, each of its arrayrefs will be interpreted as a
list of arguments to pass to C<attach> method. If a subref is specified, its return
value will be assigned to the C<attach> key and its C<@_> array will contain:
C<$t>, C<$q>, C<$config> (in that order) where C<$t> is ZofCMS Template
hashref, C<$q> is the query parameter hashref and C<$config> is the
L<App::ZofCMS::Config> object. B<Default:> not specified

=head1 OUTPUT

This plugin doesn't produce any output and doesn't set any keys.

=head1 A WARNING ABOUT ERRORS

This plugin doesn't have any error handling. The behaviour is completely
undefined in cases of: invalid email addresses, improper or
insufficient C<mime_lite_params> values, no C<from> set, etc. For example,
on my system, not specifying any C<mime_lite_params> makes it look
like plugin is not running at all. If things go awry: copy the plugin's
code into your projects dir
(C<zofcms_helper --nocore --site YOUR_PROJECT --plugins HTMLMailer>) and
mess around with code to see what's wrong (the code would be located in
C<YOUR_PROJECT_site/App/ZofCMS/Plugin/HTMLMailer.pm>)

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