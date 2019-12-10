package App::ZofCMS::Plugin::QuickNote;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use HTML::Template;

sub new { return bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{quicknote};

    my $qn_conf = delete $template->{quicknote};

    $qn_conf->{sender_host} = $config->cgi->remote_host;

    my $html_template = $self->_setup_form( $query );

    if ( defined $query->{quicknote_username}
        and $query->{quicknote_username} eq 'your full name'
    ) {
        my $is_success = $self->_process_note( $qn_conf, $html_template, $query );
        if ( defined $qn_conf->{on_error} and not $is_success ) {
            $template->{t}{ $qn_conf->{on_error} } = 1;
        }

        if ( defined $qn_conf->{on_success} and $is_success ) {
            $template->{t}{ $qn_conf->{on_success} } = 1;
        }
    }

    $template->{t}{quicknote} = $html_template->output;

    return 1;
}

sub _process_note {
    my ( $self, $qn_conf, $template, $query ) = @_;

    $qn_conf->{name_max}        ||= 100;
    $qn_conf->{email_max}       ||= 200;
    $qn_conf->{message_max}     ||= 10000;
    $qn_conf->{must_name}       ||= 0;
    $qn_conf->{must_email}      ||= 0;
    $qn_conf->{must_message}    ||= 1;
    $qn_conf->{on_success}      ||= 'quicknote_success';
    $qn_conf->{success} = 'Your message has been successfuly sent'
        unless defined $qn_conf->{success};

    for ( qw/quicknote_name quicknote_email quicknote_message/ ) {
        $query->{ $_ } = ''
            unless defined $query->{ $_ };
    }

    if ( $qn_conf->{must_name} and not length $query->{quicknote_name} ) {
        $template->param( error => 'Missing parameter <em>Name</em>' );
        return;
    }

    if ( $qn_conf->{must_email} and not length $query->{quicknote_email} ) {
        $template->param( error => 'Missing parameter <em>E-mail</em>' );
        return;
    }

    if ( $qn_conf->{must_message}
        and not length $query->{quicknote_message}
    ) {
        $template->param( error => 'Missing parameter <em>Message</em>' );
        return;
    }

    if ( length( $query->{quicknote_name} ) > $qn_conf->{name_max} ) {
        $template->param(
            error => 'Parameter <em>Name</em> cannot exceed '
            . $qn_conf->{name_max} . ' characters'
        );
        return;
    }

    if ( length( $query->{quicknote_email} ) > $qn_conf->{email_max} ) {
        $template->param(
            error => 'Parameter <em>E-mail</em> cannot exceed '
            . $qn_conf->{email_max} . ' characters'
        );
        return;
    }

    if ( length( $query->{quicknote_message} ) > $qn_conf->{message_max} ) {
        $template->param(
            error => 'Parameter <em>Message</em> cannot exceed '
            . $qn_conf->{message_max} . ' characters'
        );
        return;
    }

    $self->_send_mail( $qn_conf, $query );
    $template->param( success => $qn_conf->{success} );
    return 1;
}

sub _send_mail {
    my ( $self, $qn_conf, $query ) = @_;

    require Mail::Send;
    my $email = Mail::Send->new;

    $qn_conf->{to} = [ $qn_conf->{to} ]
        unless ref $qn_conf->{to};

    $qn_conf->{subject} = 'Quicknote'
        unless defined $qn_conf->{subject};

    $email->to( @{ $qn_conf->{to} } );
    $email->subject( $qn_conf->{subject} );

    my $fh;
    if ( defined $qn_conf->{mailer} ) {
        if ( $qn_conf->{mailer} eq 'testfile' ) {
            $Mail::Mailer::testfile::config{outfile} = 'mailer.testfile';
        }
        $fh = $email->open( $qn_conf->{mailer} );
    }
    else {
        $fh = $email->open;
    }

    print $fh $self->_make_email_body( $qn_conf, $query );

    $fh->close
      or die "couldn't send whole message: $!\n";

    return 1;
}

sub _make_email_body {
    my ( $self, $qn_conf, $query ) = @_;

    my $format = $qn_conf->{format};
    unless ( defined $format ) {
    $format = <<'END_FORMAT';
Quicknote from host {::{host}::} sent on {::{time}::}
Name: {::{name}::}
E-mail: {::{email}::}
Message:
{::{message}::}
END_FORMAT
    }

    for ( qw/quicknote_name quicknote_email quicknote_message/ ) {
        $query->{$_} = 'N/A'
            unless length $query->{$_};
    }

    my $sent_time = localtime;
    $format =~ s/\{::\{time}::}/$sent_time/g;
    $format =~ s/\{::\{host}::}/$qn_conf->{sender_host}/g;
    $format =~ s/\{::\{name}::}/$query->{quicknote_name}/g;
    $format =~ s/\{::\{email}::}/$query->{quicknote_email}/g;
    $format =~ s/\{::\{message}::}/$query->{quicknote_message}/g;

    return $format;
}

sub _setup_form {
    my ( $self, $query ) = @_;
    my $template
    = HTML::Template->new_scalar_ref( \ $self->_form_template );

    $template->param(
        page    => $query->{page},
        name    => $query->{quicknote_name},
        email   => $query->{quicknote_email},
        message => $query->{quicknote_message},
    );

    return $template;
}

sub _form_template {
    return <<'END_FORM';
<tmpl_if name="success">
    <p class="quicknote_success"><tmpl_var name="success"></p>
<tmpl_else>
<form class="quicknote" action="<tmpl_var escape="html" name="action">" method="POST">
<div>
    <tmpl_if name="error">
        <p class="quicknote_error"><tmpl_var name="error"></p>
    </tmpl_if>
    <input type="hidden" name="quicknote_username" value="your full name">
    <input type="hidden" name="page" value="<tmpl_var name="page">">
    <ul>
        <li>
            <label for="quicknote_name">Name:</label
            ><input type="text" name="quicknote_name" id="quicknote_name"
            value="<tmpl_var escape="html" name="name">">
        </li>
        <li>
            <label for="quicknote_email">E-mail: </label
            ><input type="text" name="quicknote_email" id="quicknote_email"
            value="<tmpl_var escape="html" name="email">">
        </li>
        <li>
            <label for="quicknote_message">Message: </label
            ><textarea name="quicknote_message" id="quicknote_message"
            cols="40" rows="10"><tmpl_var escape="html" name="message"></textarea>
        </li>
    </ul>
    <input type="submit" id="quicknote_submit" value="Send">
</div>
</form>
</tmpl_if>
END_FORM
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::QuickNote - drop-in "quicknote" form to email messages from your site

=head1 SYNOPSIS

In your ZofCMS template:

    # basic:
    quicknote => {
        to  => 'me@example.com',
    },

    # juicy
    quicknote => {
        mailer      => 'testfile',
        to          => [ 'foo@example.com', 'bar@example.com'],
        subject     => 'Quicknote from example.com',
        must_name   => 1,
        must_email  => 1,
        must_message => 1,
        name_max    => 20,
        email_max   => 20,
        message_max => 1000,
        success     => 'Your message has been successfuly sent',
        format      => <<'END_FORMAT',
    Quicknote from host {::{host}::} sent on {::{time}::}
    Name: {::{name}::}
    E-mail: {::{email}::}
    Message:
    {::{message}::}
    END_FORMAT
    },

In your L<HTML::Template> template:

    <tmpl_var name="quicknote">

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> which provides means to easily
drop-in a "quicknote" form which asks the user for his/her name, e-mail
address and a message he or she wants to send. After checking all of the
provided values plugin will e-mail the data which the visitor entered to
the address which you specified.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 HTML TEMPLATE

The only thing you'd want to add in your L<HTML::Template> is a
C<< <tmpl_var name="quicknote"> >> the data for this variable will be
put into special key C<{t}>, thus you can stick it in secondary templates.

=head1 USED FIRST-LEVEL ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    {
        plugins => [ qw/QuickNote/ ],
    }

First and obvious is that you'd want to include the plugin in the list
of C<plugins> to run.

=head2 C<quicknote>

    # basic:
    quicknote => {
        to  => 'me@example.com',
    },

    # juicy
    quicknote => {
        mailer      => 'testfile',
        to          => [ 'foo@example.com', 'bar@example.com'],
        subject     => 'Quicknote from example.com',
        must_name   => 1,
        must_email  => 1,
        must_message => 1,
        name_max    => 20,
        email_max   => 20,
        message_max => 1000,
        success     => 'Your message has been successfuly sent',
        format      => <<'END_FORMAT',
    Quicknote from host {::{host}::} sent on {::{time}::}
    Name: {::{name}::}
    E-mail: {::{email}::}
    Message:
    {::{message}::}
    END_FORMAT
    },

The C<quicknote> first-level ZofCMS template key is the only thing you'll
need to use to tell the plugin what to do. The key takes a hashref
as a value. The only mandatory key in that hashref is the C<to> key,
the rest have default values. Possible keys in C<quicknote> hashref are
as follows:

=head3 C<to>

    to => 'me@example.com'

    to => [ 'foo@example.com', 'bar@example.com'],

B<Mandatory>. Takes either a string or an arrayref as a value. Passing the
string is equivalent to passing an arrayref with just one element. Each
element of that arrayref must contain a valid e-mail address, upon
successful completion of the quicknote form by the visitor the data on that
form will be emailed to all of the addresses which you specify here.

=head3 C<mailer>

    mailer => 'testfile',

B<Optional>. Specifies which mailer to use for sending mail.
See documentation for L<Mail::Mailer> for possible mailers. When using the
C<testfile> mailer the file will be located in the same directory your
in which your C<index.pl> file is located. B<By default> plugin will
do the same thing L<Mail::Mailer> will (search for the first
available mailer).

=head3 C<subject>

    subject => 'Quicknote from example.com',

B<Optional>. Specifies the subject line of the quicknote e-mail.
B<Defaults to:> C<Quicknote>

=head3 C<must_name>, C<must_email> and C<must_message>

    must_name   => 1,
    must_email  => 1,
    must_message => 1,

B<Optional>. The C<must_name>, C<must_email> and C<must_message> arguments
specify whether or not the "name", "e-mail" and "message" form fields
are mandatory. When set to a true value indicate that the field is
mandatory. When set to a false value the form field will be filled with
C<N/A> unless specified by the visitor. Visitor will be shown an error
message if he or she did not specify some mandatory field.
B<By default> only the
C<must_message> argument is set to a true value (thus the vistior does
not have to fill in neither the name nor the e-mail).

=head3 C<name_max>, C<email_max> and C<message_max>

    name_max    => 20,
    email_max   => 20,
    message_max => 1000,

B<Optional>. Alike C<must_*> arguments, the
C<name_max>, C<email_max> and C<message_max> specify max lengths of
form fields. Visitor will be shown an error message if any of the
parameters exceed the specified maximum lengths. B<By default> the value
for C<name_max> is C<100>, value for C<email_max> is C<200> and
value for C<message_max> C<10000>

=head3 C<success>

    success => 'Your message has been successfuly sent',

B<Optional>. Specifies the text to display to your visitor when the
quicknote is successfuly sent. B<Defaults to:>
C<'Your message has been successfuly sent'>.

=head3 C<on_success>

    on_success => 'quicknote_success'

B<Optional>. Takes a string as a value that representes a key in C<{t}> special key. When
specified, the plugin will set the C<on_success> key in C<{t}> special key to a true value
when the quicknote has been sent; this can be used to display some special messages
when quick note succeeds. B<Defaults to:> C<quicknote_success>.

=head3 C<on_error>

    on_error => 'quicknote_error'

B<Optional>. Takes a string as a value that representes a key in C<{t}> special key. When
specified, the plugin will set the C<on_error> key in C<{t}> special key to a true value
when the quicknote has not been sent due to some error, e.g. user did not specify mandatory
parameters; this can be used to display some special messages
when quick note fails. B<By default> is not specified.

=head3 C<format>

        format      => <<'END_FORMAT',
    Quicknote from host {::{host}::} sent on {::{time}::}
    Name: {::{name}::}
    E-mail: {::{email}::}
    Message:
    {::{message}::}
    END_FORMAT

B<Optional>. Here you can specify the format of the quicknote e-mail which
plugin will send. The following special sequences will be replaced
by corresponding values:

    {::{host}::}        - the host of the person sending the quicknote
    {::{time}::}        - the time the message was sent ( localtime() )
    {::{name}::}        - the "Name" form field
    {::{email::}        - the "E-mail" form field
    {::{message}::}     - the "Message" form field

B<Default> format is shown above and in SYNOPSIS.

=head1 GENERATED HTML

Below is the HTML code generated by the plugin. Use CSS to style it.

    # on successful send
    <p class="quicknote_success"><tmpl_var name="success"></p>

    # on error
    <p class="quicknote_error"><tmpl_var name="error"></p>


    # the form itself
    <form class="quicknote" action="" method="POST">
    <div>
        <input type="hidden" name="quicknote_username" value="your full name">
        <input type="hidden" name="page" value="index">
        <ul>
            <li>
                <label for="quicknote_name">Name:</label
                ><input type="text" name="quicknote_name" id="quicknote_name"
                value="">
            </li>
            <li>
                <label for="quicknote_email">E-mail: </label
                ><input type="text" name="quicknote_email" id="quicknote_email"
                value="">
            </li>
            <li>
                <label for="quicknote_message">Message: </label
                ><textarea name="quicknote_message" id="quicknote_message"
                cols="40" rows="10"></textarea>
            </li>
        </ul>
        <input type="submit" id="quicknote_submit" value="Send">
    </div>
    </form>

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
