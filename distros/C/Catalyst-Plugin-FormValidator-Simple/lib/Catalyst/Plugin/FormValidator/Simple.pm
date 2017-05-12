package Catalyst::Plugin::FormValidator::Simple;
use strict;
use base qw/Catalyst::Plugin::FormValidator/;
# doesn't use parent module at all, but this is required for Catalyst::Plugin::FillInForm

use MRO::Compat;
require FormValidator::Simple;

our $VERSION = '0.15';

sub setup {
    my $self = shift;
    $self->maybe::next::method(@_);
    my $setting = $self->config->{validator};
    my $plugins = $setting && exists $setting->{plugins}
        ? $setting->{plugins}
        : [];
        FormValidator::Simple->import(@$plugins);
    if ( $setting && exists $setting->{messages} ) {
        FormValidator::Simple->set_messages( $setting->{messages} );
    }
    if ( $setting && exists $setting->{options} ) {
        FormValidator::Simple->set_option( %{ $setting->{options} } );
    }
    if ( $setting && exists $setting->{message_format} ) {
        FormValidator::Simple->set_message_format( $setting->{message_format} );
    }
    if ( $setting && exists $setting->{message_decode_from} ) {
        FormValidator::Simple->set_message_decode_from( $setting->{message_decode_from} );
    }
}

sub prepare {
    my $c = shift;
    $c = $c->maybe::next::method(@_);
    $c->{validator} = FormValidator::Simple->new;
    return $c;
}

sub form {
    my $c = shift;
    if ($_[0]) {
        my $form = $_[1] ? [@_] : $_[0];
        $c->{validator}->check($c->req, $form);
    }
    return $c->{validator}->results;
}

sub set_invalid_form {
    my $c = shift;
    $c->{validator}->set_invalid(@_);
    return $c->{validator}->results;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::FormValidator::Simple - Validator for Catalyst with FormValidator::Simple

=head1 SYNOPSIS

    use Catalyst qw/FormValidator::Simple FillInForm/;

    # set option
    MyApp->config->{validator} = {
        plugins => ['CreditCard', 'Japanese'],
        options => { charset => 'euc'},
    }

in your controller

    sub defaulti : Private {

        my ($self, $c) = @_;

        $c->form(
            param1 => [qw/NOT_BLANK ASCII/, [qw/LENGTH 4 10/]],
            param2 => [qw/NOT_BLANK/, [qw/JLENGTH 4 10/]],
            mail1  => [qw/NOT_BLANK EMAIL_LOOSE/],
            mail2  => [qw/NOT_BLANK EMAIL_LOOSE/],
            { mail => [qw/mail1 mail2/] } => ['DUPLICATION'],
        );

        print $c->form->valid('param1');

        if ( some condition... ) {

            $c->form(
                other_param => [qw/NOT_INT/],
            );
        }

        if ( some condition... ) {

            # set your original invalid type.
            $c->set_invalid_form( param3 => 'MY_ERROR' );

        }

        if ( $c->form->has_error ) {
            
            if ( $c->form->missing('param1') ) {
                ...
            }

            if ( $c->form->invalid( param1 => 'ASCII' ) ) {
                ...
            }

            if ( $c->form->invalid( param3 => 'MY_ERROR' ) ) {
                ...
            }

        }
    }

=head1 DESCRIPTION

This plugin allows you to validate request parameters with FormValidator::Simple.
See L<FormValidator::Simple> for more information.

This behaves like as L<Catalyst::Plugin::FormValidator>.

=head1 CONFIGURATION

set config with 'validator' key.

    MyApp->config->{validator} = { ... };

or

    MyApp->config(
        validator => { ... },
    );

=head2 PLUGINS

If you want to use some plugins for FormValidator::Simple, you can set like following.

    MyApp->config(
        validator => {
            plugins => [qw/Japanese CreditCard DBIC::Unique/],
        },
    );

In this example, FormValidator::Simple::Plugin::Japanese, FormValidator::Simple::Plugin::CreditCard,
and FormValidator::Simple::Plugin::DBIC::Unique are loaded.

=head2 OPTIONS

When you set some options needed by specific validations, do like this.

    MyApp->config(
        validator => {
            plugins => [qw/Japanese CreditCard DBIC::Unique/],
            options => {
                charset => 'euc',
                dbic_base_class => 'MyApp::Model::DBIC',
            },
        },
    );

'charset' is necessary for Plugin::Japanese, and 'dbic_cbase_class' is used in Plugin::DBIC::Unique.

=head1 VALIDATION

use 'form' method, see L<FormValidator::Simple> in detail.

    sub do_add : Local {
        my ( $self, $c ) = @_;

        # execute validation.
        $c->form(
            name  => [qw/NOT_BLANK ASCII/,       [qw/LENGTH 0 20/] ],
            email => [qw/NOT_BLANK EMAIL_LOOSE/, [qw/LENGTH 0 20/] ],
            { unique => [qw/name email/] } => [qw/DBIC_UNIQUE User name email/],
        );

        if ( ... ) {

            # execute validation one more time in specific condition.
            $c->form(
                ...                 
            );

        }

        # See Catalyst::Plugin::RequestToken for '$c->validate_token'
        if ( $c->validate_token ) {

            # you can force to set invalid data.
            $c->set_invalid_form( token => 'TOKEN' );

        }

        # check result.
        # you can pick up result-object with 'form' method

        my $result = $c->form;

        if ( $result->has_error ) {

        # this is same as
        # if ( $result->has_missing or $result->has_invalid )

            $c->detach('add');

        }

    }

=head1 HANDLING SUCCESSFUL RESULT

After it passes all validations, you may wanna put input-data into database.
It's a elegant way to use [ L<Class::DBI> and L<Class::DBI::FromForm> ] or [ L<DBIx::Class> and L<DBIx::Class::WebForm> ].

    sub do_add : Local {
        my ( $self, $c ) = @_;

        $c->form(
            name  => [qw/NOT_BLANK/],
            email => [qw/NOT_BLANK/],
        );

        my $result = $c->form;
        if ( $result->has_error ) {
            $c->detach('add');
        }

        my $user = MyProj::Model::DBIC::User->create_from_form($result);
        
        # this behaves like this...
        # MyProj::Model::DBIC::User->create({
        #    name  => $result->valid('name'),
        #    email => $result->valid('email'),
        # });
        #
        # if the key exists as the table's column, set the value with 'valid'
    }

Here, I explain about 'valid' method. If the value indicated with key-name passes validations,
You can get the data with 'valid',

    my $result = $c->form(
        name  => [qw/NOT_BLANK/],
        email => [qw/NOT_BLANK/],
    ); 

    print $result->valid('name');

    print $result->valid('email');

But, this is for only single key validation normally.

    my $result = $c->form(
        name => [qw/NOT_BLANK/], # single key validation
        { mail_dup => [qw/email email2/] } => ['DUPLICATION'] # multiple keys one
    );

    print $result->valid('name'); # print out the value of 'name'

    print $result->valid('mail_dup'); # no value.

There are exceptions. These are 'DATETIME', 'DATE'.

    my $result = $c->form(
        { created_on => [qw/created_year created_month created_day/] }
        =>
        [qw/DATETIME/],
    );

    print $result->valid('created_on'); #print out datetime string like "2005-11-23 00:00:00".

If you set some class around datetime in configuration. It returns object of the class you indicate.
You can choose from L<Time::Piece> and L<DateTime>. For example...

    MyApp->config(
        validator => {
            plugins => [...],
            options => {
                datetime_class => 'Time::Piece',
            },
        },
    );

or

    MyApp->config(
        validator => {
            plugins => [...],
            options => {
                datetime_class => 'DateTime',
                time_zone      => 'Asia/Tokyo',
            },
        },
    );

then

    my $result = $c->form(
        { created_on => [qw/created_year created_month created_day/] }
        =>
        [qw/DATETIME/],
    );

    my $dt = $result->valid('created_on');

    print $dt->ymd;

    MyProj::Model::CDBI::User->create_from_form($result);

This may be useful when you define 'has_a' relation for datetime columns.
For example, in your table class inherits 'Class::DBI'

    __PACKAGE__->has_a( created_on => 'DateTime',
        inflate => ...,
        deflate => ...,
    );

And see also L<Class::DBI::Plugin::TimePiece>, L<Class::DBI::Plugin::DateTime>.

=head1 MESSAGE HANDLING

in template file, you can handle it in detail.

    [% IF c.form.has_error %]
    <p>Input Error</p>
    <ul>
    [% IF c.form.missing('name') %]
    <li>input name!</li>
    [% END %]
    [% IF c.form.invalid('name') %]
    <li>name is wrong</li>
    [% END %]
    [% IF c.form.invalid('name', 'ASCII') %]
    <li>input name with ascii code.</li>
    [% END %]
    [% IF c.form.invalid('name', 'LENGTH') %]
    <li>wrong length for name.</li>
    [% END %]
    </ul>
    [% END %]

or, make it more easy.

    [% IF c.form.has_error %]
    <p>Input Error</p>
    <ul>
    [% FOREACH key IN c.form.error %]
        [% FOREACH type IN c.form.error(key) %]
        <li>Invalid: [% key %] - [% type %]</li>
        [% END %]
    [% END %]
    </li>
    [% END %]

And you can also use messages configuration as hash reference.

    MyApp->config(
        validator => {
            plugins  => [...],
            messages => {
                user => {
                    name => {
                        NOT_BLANK => 'Input name!',
                        ASCII     => 'Input name with ascii code!',
                    },
                    email => {
                        DEFAULT   => 'email is wrong.!',
                        NOT_BLANK => 'input email.!'
                    },
                },
                company => {
                    name => {
                        NOT_BLANK => 'Input name!',
                    },
                },
            },
        },
    );

or YAML file. set file name

    MyApp->config(
        validator => {
            plugins  => [...],
            messages => 'conf/messages.yml',
        },
    );

and prepare yaml file like following,

    DEFAULT:
        name:
            DEFAULT: name is invalid
    user:
        name:
            NOT_BLANK: Input name!
            ASCII: Input name with ascii code!
        email:
            DEFAULT: Email is wrong!
            NOT_BLANK: Input email!
    company:
        name:
            NOT_BLANK: Input name!

the format is...

    Action1_Name:
        Key1_Name:
            Validation1_Name: Message
            Validation2_Name: Message
        Key2_Name:
            Validation1_Name: Message
    Action2_Name:
        Key1_Name:
            ...
        
After messages configuration, call messages() method from result-object.
and set action-name as argument.

    [% IF c.form.has_error %]
    <ul>
        [% FOREACH message IN c.form.messages('user') %]
        <li>[% message %]</li>
        [% END %]
    </ul>
    [% END %]

you can set each message format

    MyApp->config(
        validator => {
            messages => 'messages.yml',  
            message_format => '<p>%s</p>'
        },
    );

    [% IF c.form.has_error %]
        [% c.form.messages('user').join("\n") %]
    [% END %]

=head1 SEE ALSO

L<FormValidator::Simple>

L<Catalyst>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright(C) 2005 by Lyo Kato

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

