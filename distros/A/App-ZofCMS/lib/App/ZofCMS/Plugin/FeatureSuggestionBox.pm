package App::ZofCMS::Plugin::FeatureSuggestionBox;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use HTML::Template;
use HTML::Entities;
use MIME::Lite;

sub _key { 'plug_feature_suggestion_box' }
sub _defaults {
    return (
#         from                => undef,
#         email_template      => email_template(),
#         to                  => undef,
        user_name           => sub { $_[0]->{d}{user}{name} },
        user_email          => sub { $_[0]->{d}{user}{email} },
        subject             => 'Feature Suggestion',
        no_identification   => 1,
        submit_button       => q|<input type="submit" class="submit_button"|
                                    . q| value="Send">|,
#         mime_lite_params    => [
#             'smtp',
#             'foosmail',
#             Auth   => [ 'foos/bars', 'p4ss' ],
#         ],
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    for ( qw/to  user_name  user_email/ ) {
        $conf->{$_} = $conf->{$_}->( $t, $q, $config )
            if ref $conf->{$_} eq 'CODE';
    }

    return
        unless $conf->{to};

    $self->{Q_PAGE} = ( $q->{dir} || '' ) . ( $q->{page} || '' );
    $self->{CONF}   = $conf;
    $self->{Q}      = $q;
    $self->{T}      = $t;

    if ( $q->{plugfsb_send} ) {
        $self->_check_suggestion
            and $self->_send_suggestion;
    }

    $t->{t}{plug_feature_suggestion_box_form} = $self->_make_form;
}

sub _send_suggestion {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};

    my $template = HTML::Template->new(
        die_on_bad_params => 0,
        ref $conf->{email_template}
            ? ( filename => ${ $conf->{email_template} } )
            : _has_value( $conf->{email_template} )
                ? ( scalarref => \ $conf->{email_template} )
                : ( scalarref => \ _email_template()        )
    );

    my $suggestion = encode_entities $q->{plugfsb_suggestion};
    $suggestion =~ s/\r?\n/<br>/g;

    my $name = _has_value( $conf->{user_name} )
    ? $conf->{user_name} : $q->{plugfsb_name};

    my $email = _has_value( $conf->{user_email} )
    ? $conf->{user_email} : $q->{plugfsb_email};

    $template->param(
        name        => $name,
        email       => $email,
        suggestion  => $suggestion,
        has_name    => _has_value( $name  ),
        has_email   => _has_value( $email ),
    );

    my $msg = MIME::Lite->new (
        Subject => $conf->{subject},
        ( defined $conf->{from} ? ( From => $conf->{from} ) : (), ),
        To      => $conf->{to},
        Type    => 'text/html',
        Data    => $template->output,
    );

    MIME::Lite->send( @{ $conf->{mime_lite_params} } )
        if $conf->{mime_lite_params};

    $msg->send;

    $self->{SEND_SUCCESS} = 1;
    $self->{T}{t}{plug_feature_suggestion_box_sent} = 1;
}

sub _check_suggestion {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};

    return $self->_set_error('You must fill in your name')
        if not $conf->{no_identification}
            and not _has_value( $q->{plugfsb_name} );

    return $self->_set_error('"Your name" cannot be longer than 200 characters')
        if not $conf->{no_identification}
            and length( $q->{plugfsb_name} ) > 200;

    return $self->_set_error('You must fill in your email address')
        if not $conf->{no_identification}
            and not _has_value( $q->{plugfsb_email} );

    return $self->_set_error('"Your email" cannot be longer than 300 characters')
        if not $conf->{no_identification}
            and length( $q->{plugfsb_email} ) > 300;

    return $self->_set_error('You must fill in your suggestion')
        if not _has_value( $q->{plugfsb_suggestion} );

    return $self->_set_error('"Your suggestion" cannot be longer than 300,000 characters')
        if length( $q->{plugfsb_suggestion} ) > 300000;

    return 1;
}

sub _make_form {
    my $self = shift;
    my $conf = $self->{CONF};
    my $q    = $self->{Q};

    my $template = HTML::Template->new_scalar_ref(
        \ $self->_get_form_html_template,
        die_on_bad_params => 0,
    );

    $template->param(
        page            => $self->{Q_PAGE},
        error           => $self->{ERROR},
        send_success    => $self->{SEND_SUCCESS},
        (
            map +( $_ => $q->{"plugfsb_$_"} ),
                qw/name  email  suggestion/,
        ),
        (
            map +( $_ => $conf->{$_} ),
                qw/submit_button  no_identification/,
        ),
    );

    return $template->output;
}

sub _set_error {
    my $self = shift;
    $self->{ERROR} = shift;
    return;
}

sub _has_value {
    my $v = shift;
    return 1
        if defined $v and length $v;

    return 0;
}

sub _email_template {
    return <<'END_HTML';
<h1>Feature Suggestion</h1>

<dl>
    <tmpl_if name='has_name'>
        <dt>From:</dt>
            <dd><tmpl_var escape='html' name='name'></dd>
    </tmpl_if>

    <tmpl_if name='has_email'>
        <dt>Email:</dt>
            <dd><a href="mailto:<tmpl_var escape='html' name='email'>"><tmpl_var escape='html' name='email'></a></dd>
    </tmpl_if>

    <dt>Suggestion:</dt>
        <dd><tmpl_var name='suggestion'></dd>
</dl>
END_HTML
}

sub _get_form_html_template {
    return <<'END_HTML';
<tmpl_if name="send_success">
    <p class="success-message">Successfully sent.</p>
<tmpl_else>
    <form action="" method="POST" id="plugfsb_form">
    <div>
        <input type="hidden" name="page" value="<tmpl_var escape='html' name='page'>">
        <input type="hidden" name="plugfsb_send" value="1">

        <tmpl_if name="error">
            <p class="error"><tmpl_var escape='html' name='error'></p>
        </tmpl_if>

        <ul>
            <tmpl_unless name="no_identification">
                <li><label for="plugfsb_name">Your name:</label
                    ><input type="text" class="input_text"
                        name="plugfsb_name" id="plugfsb_name"
                        value="<tmpl_var escape='html' name='name'>"></li>
                <li><label for="plugfsb_email">Your email:</label
                    ><input type="text" class="input_text"
                        name="plugfsb_email" id="plugfsb_email"
                        value="<tmpl_var escape='html' name='email'>"></li>
            </tmpl_unless>
            <li><label for="plugfsb_suggestion" class="textarea_label">Your suggestion:</label
                ><textarea id="plugfsb_suggestion" cols="60" rows="5"
                    name="plugfsb_suggestion"
                ><tmpl_var escape='html' name='suggestion'></textarea></li>
        </ul>

        <tmpl_var name='submit_button'>
    </div>
    </form>
</tmpl_if>
END_HTML
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FeatureSuggestionBox - ZofCMS plugin that provides a feature suggestion box for your site

=head1 SYNOPSIS

In your L<HTML::Template> template:

    <tmpl_var name='plug_feature_suggestion_box_form'>

In your ZofCMS Template:

    plugins => [ qw/FeatureSuggestionBox/, ],

    plug_feature_suggestion_box => {
        to => 'foo@bar.com',

        # this one has a default; see EMAIL TEMPLATE
        email_template    => 'blah blah',

        # everything below is optional; defaults are shown
        no_identification => 1,
        from              => undef,
        user_name         => sub { $_[0]->{d}{user}{name} },
        user_email        => sub { $_[0]->{d}{user}{email} },
        subject           => 'Feature Suggestion',
        mime_lite_params  => undef,
        submit_button => q|<input type="submit" class="submit_button"|
                            . q| value="Send">|,
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that gives you a "feature
suggestion box". It is a form where a user can type up a suggestion
and, once submitted, that suggestion will arrive in your email inbox.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        { FeatureSuggestionBox => 2000 },
    ],

B<Mandatory>. You need to include the plugin in the list of plugins to execute.

=head2 C<plug_feature_suggestion_box>

    plug_feature_suggestion_box => {
        to => 'foo@bar.com',

        # this one has a default; see EMAIL TEMPLATE
        email_template    => 'blah blah',

        # everything below is optional; defaults are shown
        no_identification => 1,
        from              => undef,
        user_name         => sub { $_[0]->{d}{user}{name} },
        user_email        => sub { $_[0]->{d}{user}{email} },
        subject           => 'Feature Suggestion',
        mime_lite_params  => undef,
        submit_button => q|<input type="submit" class="submit_button"|
                            . q| value="Send">|,
    },

    # or
    plug_feature_suggestion_box => sub {
        my ( $t, $q, $config ) = @_;

        return $t->{hashref_to_assign_instead_of_this_sub};
    },

B<Mandatory>. Takes either a hashref or a subref as a value.
If subref is specified, its return value will be assigned to
C<plug_feature_suggestion_box> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the
subref will contain C<$t>, C<$q>, and C<$config> (in that order): where
C<$t> is ZofCMS Tempalate hashref, C<$q> is query parameters hashref,
and C<$config> is L<App::ZofCMS::Config> object. Possible keys/values
for the hashref are as follows:

=head3 C<to>

    plug_feature_suggestion_box => {
        to => 'foo@bar.com',
    ...

    plug_feature_suggestion_box => {
        to => sub {
            my ( $t, $q, $config ) = @_;
            return 'foo@meow.com';
        }
    ...

B<Mandatory>. Takes a scalar or a subref as a value. Specifies one or more
email addresses to which to send feature suggestion. Separate multiple
addresses with a comma(,). If subref is specified, its return value will
be assigned to C<to>, as if it were already there. Plugin will stop
executing if C<to> is not specified, or if the subref returns an C<undef>
or an empty list. In its C<@_> the subref will have C<$t>, C<$q>, and
C<$config> (in that order): where C<$t> is ZofCMS Tempalate hashref, C<$q>
is query parameters hashref, and C<$config> is L<App::ZofCMS::Config>
object.

=head3 C<email_template>

    plug_feature_suggestion_box => {
        email_template => 'blah blah',
    ...

    plug_feature_suggestion_box => {
        email_template => \'template.tmpl',
    ...

B<Optional>. Takes a scalar or a scalarref as a value. If a scalar is
specified it will be interpreted as an L<HTML::Template> template
for use for the email (containing feature suggestion) body. If a scalarref
is specified, it will be taken as a filename pointing to the file containing
L<HTML::Template> for the email. If relative path is specified, it will
be relative to C<index.pl> file. For template variables as well as
the default email template see L<EMAIL TEMPLATE> section below.

=head3 C<no_identification>

    plug_feature_suggestion_box => {
        no_identification => 1,
    ...

B<Optional>. Takes either true or false values. If a I<false> value is set,
plugin's form will have three fields for the user to fill out:
C<name>, C<email>, and C<suggestion>. If set to a true value, the
C<name> and C<email> fields will be suppressed, and the user will be
presented only with a single box to fill out, the C<suggestion>.
B<Defaults to:> C<1> (name/email are disabled)

=head3 C<from>

    plug_feature_suggestion_box => {
        from => undef,
    ...

    plug_feature_suggestion_box => {
        from => 'Zoffix Znet <cpan@zoffix.com>',
    ...

B<Optional>. Takes a scalar as a value that specifies the C<From> field for
the email. If not specified, the plugin will simply not set the C<From>
argument in L<MIME::Lite>'s C<new()> method (which is what this plugin uses
under the hood). See L<MIME::Lite>'s docs for more description.
B<Defaults to:> C<undef> (not specified)

=head3 C<user_name>

    plug_feature_suggestion_box => {
        user_name => sub { $_[0]->{d}{user}{name} },
    ...

    plug_feature_suggestion_box => {
        user_name => 'Zoffix Znet',
    ...

B<Optional>. Takes a subref or a scalar as a value. The value of this
argument will be present in the email indicating submitter's name.
Applies regardless of C<no_identification> argument's value. If specified,
the value will override whatever the user enters in the C<Your name>
field.

If subref is specified, its return value will be assigned to
C<user_name>, as if it were already there. In its C<@_> the subref will
have C<$t>, C<$q>, and C<$config> (in that order): where C<$t> is ZofCMS
Tempalate hashref, C<$q> is query parameters hashref, and C<$config> is
L<App::ZofCMS::Config> object.
B<Defaults to:> C<< sub { $_[0]->{d}{user}{name} } >>

=head3 C<user_email>

    plug_feature_suggestion_box => {
        user_email => sub { $_[0]->{d}{user}{email} },
    ...

    plug_feature_suggestion_box => {
        user_email => 'cpan@zoffix.com,
    ...

B<Optional>. Takes a subref or a scalar as a value. The value of this
argument will be present in the email indicating submitter's email address.
Applies regardless of C<no_identification> argument's value. If specified,
the value will override whatever the user enters in the C<Your email>
field.

If subref is specified, its return value will be assigned to
C<user_email>, as if it were already there. In its C<@_> the subref will
have C<$t>, C<$q>, and C<$config> (in that order): where C<$t> is ZofCMS
Tempalate hashref, C<$q> is query parameters hashref, and C<$config> is
L<App::ZofCMS::Config> object.
B<Defaults to:> C<< sub { $_[0]->{d}{user}{email} } >>

=head3 C<subject>

    plug_feature_suggestion_box => {
        subject => 'Feature Suggestion',
    ...

B<Optional>. Takes a scalar as a value. The value will become the
subject of the email. B<Defaults to:> C<Feature Suggestion>

=head3 C<mime_lite_params>

    plug_feature_suggestion_box => {
        mime_lite_params => undef,
    ...

    plug_feature_suggestion_box => {
        mime_lite_params => [
            'smtp',
            'foosmail',
            Auth   => [ 'foos/bars', 'p4ss' ],
        ],
    ...

B<Optional>. Takes an arrayref as a value.
If specified, the arrayref will be directly dereferenced into
C<< MIME::Lite->send() >>. Here you can set any special send arguments you
need; see L<MIME::Lite> docs for more info. B<Note:> if the plugin refuses
to send email, it could well be that you need to set some
C<mime_lite_params>; on my box, without anything set, the plugin behaves
as if everything went through fine, but no email arrives.
B<Defaults to:> C<undef> (not specified)

=head3 C<submit_button>

    plug_feature_suggestion_box => {
        submit_button => q|<input type="submit" class="submit_button"|
                            . q| value="Send">|,
    ...

B<Optional>. Takes HTML code as a value. This code represents the
submit button in the feature suggestion form. This, for example, allows
you to use image buttons instead of regular ones. Also, feel free to use
this as the insertion point for any extra HTML form you need in this form.
B<Defaults to:>
C<< <input type="submit" class="submit_button" value="Send"> >>

=head1 C<HTML::Template> TEMPLATE VARIABLES

    <tmpl_var name='plug_feature_suggestion_box_form'>

    <tmpl_if name='plug_feature_suggestion_box_sent'>
        <p>Yey! :)</p>
    </tmpl_if>

=head2 C<plug_feature_suggestion_box_for>

    <tmpl_var name='plug_feature_suggestion_box_form'>

This variable will contain either the feature suggestion form or a
success message if that form was successfully submitted.

=head2 C<plug_feature_suggestion_box_sent>

    <tmpl_if name='plug_feature_suggestion_box_sent'>
        <p>Yey! :)</p>
    </tmpl_if>

This will be set to true if the form has been successfully submitted.

=head1 EMAIL TEMPLATE

If C<email_template> argument is not specified, the plugin will use its
default email template shown here:

    <h1>Feature Suggestion</h1>

    <dl>
        <tmpl_if name='has_name'>
            <dt>From:</dt>
                <dd><tmpl_var escape='html' name='name'></dd>
        </tmpl_if>

        <tmpl_if name='has_email'>
            <dt>Email:</dt>
                <dd><a href="mailto:<tmpl_var escape='html'
                    name='email'>"
                    ><tmpl_var escape='html' name='email'></a></dd>
        </tmpl_if>

        <dt>Suggestion:</dt>
            <dd><tmpl_var name='suggestion'></dd>
    </dl>

The L<HTML::Template> template variables available here as as follows:

=head2 C<< <tmpl_var escape='html' name='name'> >>

    From: <tmpl_var escape='html' name='name'>

If C<user_name> argument is specified, this variable will contain its value.
Otherwise, it will either contain what the user specifies in the
C<Your name> field in the form, or won't be set at all.

=head2 C<< <tmpl_var escape='html' name='email'> >>

    Email: <tmpl_var escape='html' name='email'>

If C<user_email> argument is specified, this variable will contain its
value. Otherwise, it will either contain what the user specifies in the
C<Your email> field in the form, or won't be set at all.

=head2 C<< <tmpl_var name='suggestion'> >>

    Suggestion: <tmpl_var name='suggestion'>

This variable will contain what the user types in the C<Suggestion> box
in the form. B<Note:> HTML entities will be escaped here and new
lines replaced with C<< <br> >> elements; thus, do not use C<escape="html">
C<< <tmpl_var> >> attribute here.

=head2 C<< <tmpl_if name='has_name'> >>

    <tmpl_if name='has_name'>
        I HAS NAME!!!
    </tmpl_if>

Set to a true value if either C<user_name> argument is set to something,
or the user fills the C<Your name> field in the form.

=head2 C<< <tmpl_if name='has_email'> >>

    <tmpl_if name='has_email'>
        I HAS EMAIL!!!
    </tmpl_if>

Set to a true value if either C<user_email> argument is set to something,
or the user fills the C<Your emails> field in the form.

=head1 GENERATED FORM

Examples below show the form with three fields. If C<no_identitification>
argument is set to a true value, the C<Your name> and C<Your email>
fields (altogether with C<< <li> >> elements that contain them) won't be
present.

The C<page> hidden C<< <input> >> element's value is obtained by the plugin
automatically.

=head2 Default view

    <form action="" method="POST" id="plugfsb_form">
    <div>
        <input type="hidden" name="page" value="/index">
        <input type="hidden" name="plugfsb_send" value="1">

        <ul>
            <li><label for="plugfsb_name">Your name:</label
                ><input type="text" class="input_text"
                    name="plugfsb_name" id="plugfsb_name"
                    value=""></li>
            <li><label for="plugfsb_email">Your email:</label
                ><input type="text" class="input_text"
                    name="plugfsb_email" id="plugfsb_email"
                    value=""></li>
            <li><label for="plugfsb_suggestion"
                class="textarea_label">Your suggestion:</label
                ><textarea id="plugfsb_suggestion" cols="60" rows="5"
                    name="plugfsb_suggestion"
                ></textarea></li>
        </ul>

        <input type="submit" class="submit_button" value="Send">
    </div>
    </form>

=head2 An error occured

    <form action="" method="POST" id="plugfsb_form">
    <div>
        <input type="hidden" name="page" value="/index">
        <input type="hidden" name="plugfsb_send" value="1">

        <p class="error">You must fill in your name</p>

        <ul>
            <li><label for="plugfsb_name">Your name:</label
                ><input type="text" class="input_text"
                    name="plugfsb_name" id="plugfsb_name"
                    value=""></li>
            <li><label for="plugfsb_email">Your email:</label
                ><input type="text" class="input_text"
                    name="plugfsb_email" id="plugfsb_email"
                    value=""></li>
            <li><label for="plugfsb_suggestion"
                class="textarea_label">Your suggestion:</label
                ><textarea id="plugfsb_suggestion" cols="60" rows="5"
                    name="plugfsb_suggestion"
                ></textarea></li>
        </ul>

        <input type="submit" class="submit_button" value="Send">
    </div>
    </form>

=head2 Feature successfully submitted

    <p class="success-message">Successfully sent.</p>

=head1 REQUIRED MODULES

Plugin requires these modules/versions:

    App::ZofCMS::Plugin::Base => 0.0106,
    HTML::Template            => 2.9,
    HTML::Entities            => 1.35,
    MIME::Lite                => 3.027,

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