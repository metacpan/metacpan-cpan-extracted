# NAME

Chloro - Form Processing So Easy It Will Knock You Out

# VERSION

version 0.07

# SYNOPSIS

    package MyApp::Form::Login;

    use Moose;
    use Chloro;

    field username => (
        isa      => 'Str',
        required => 1,
    );

    field password => (
        isa      => 'Str',
        required => 1,
    );

    ...

    sub login {
        ...

        my $form = MyApp::Form::Login->new();

        my $resultset = $form->process( params => $submitted_params );

        if ( $resultset->is_valid() ) {
            my $login = $resultset->results();

            # Do something with $login->{username} & $login->{password}
        }
        else {
            # Errors that are not specific to just one field
            my @form_errors = $resultset->form_errors();

            # Errors keyed by specific field names
            my %field_errors = $resultset->field_errors();

            # Do something with these errors
        }
    }

# DESCRIPTION

**This software is still very alpha, and the API may change without warning in
future versions.**

For a walkthrough of all this module's features, see [Chloro::Manual](https://metacpan.org/pod/Chloro::Manual).

Chloro is yet another in a long line of form processing libraries. It differs
from other libraries in that it is entirely focused on defining forms in
programmer terms. Field types are Moose type constraints, not HTML widgets
("Str" not "Select").

Chloro is focused on taking a browser's submission, doing basic validation,
and returning a data structure that you can use for further processing.

Out of the box, it does not talk to your database, nor does it know anything
about rendering HTML. However, it is designed so that these features could be
provided by extensions.

# OVERVIEW

Chloro starts with forms. A form is a class which uses Chloro (and Moose).

    package MyApp::Form::User;

    use Moose;
    use Chloro;

    field username => (
        isa      => 'Str',
        required => 1,
    );

In order to validate data against a form, you instantiate a form object and
call `$form->process()`:

    my $form = MyApp::Form::User->new();
    my $resultset = $form->process( params => $params );

The `$params` are a hash reference where the keys are field names and the
values are field values. Under the hood, you can define a variety of parameter
munging and validation methods, or just use the defaults.

The `process()` method returns a [Chloro::ResultSet](https://metacpan.org/pod/Chloro::ResultSet) object. This object can
tell you whether the submitted parameters were valid. If they weren't, you can
dig into the errors associated with specific fields. You can also define
validations against the form as a whole, and the resultset will have those
errors too.

    if ( $resultset->is_valid() ) {
        ...
    }
    else {
        my $result = $resultset->result_for('username');

        print $_->message() for $result->errors();
    }

If the submission was valid, you can get the results as a hash reference:

    my $hash = $resultset->results();

That's the basic workflow using Chloro.

# MANUAL

If you're new to Chloro, you should start by reading [Chloro::Manual](https://metacpan.org/pod/Chloro::Manual).

# SUPPORT

Bugs may be submitted at [http://rt.cpan.org/Public/Dist/Display.html?Name=Chloro](http://rt.cpan.org/Public/Dist/Display.html?Name=Chloro) or via email to [bug-chloro@rt.cpan.org](mailto:bug-chloro@rt.cpan.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Chloro can be found at [https://github.com/autarch/Chloro](https://github.com/autarch/Chloro).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Robbie Bow <robbie@iannounce.co.uk>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
