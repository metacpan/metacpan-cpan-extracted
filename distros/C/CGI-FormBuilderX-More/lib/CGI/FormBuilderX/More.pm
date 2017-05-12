package CGI::FormBuilderX::More;

use warnings;
use strict;

=head1 NAME

CGI::FormBuilderX::More - Additional input gathering/interrogating functionality for CGI::FormBuilder 

=head1 VERSION

Version 0.020

=cut

our $VERSION = '0.020';

=head1 SYNOPSIS

    use CGI::FormBuilderX::More;

    my $form = CGI::FormBuilderX::More( ... );

    if ($form->pressed("edit")) {
        my $input = $form->input_slice(qw/title description/);
        # $input is { title => ..., description => ... } *ONLY*
        ...
    }
    elsif ($form->pressed("view") && ! $form->missing("section")) {
        # The paramter "section" is defined and is not ''
        ...
    }

    print $form->render;

    ...

    # Using the alternative, subroutine-driven, validation

    my $form = CGI::FormBuilderX::More( ..., validate => sub {
        my ($form, $error) = @_;

        if (! exists $_{username}) {
            $error->("username is required"); # Register the error
        }
        elsif ($_{username} =~ m/\W/) {
            $error->("username is malformed"); # A username was given but it's bad
        }

        if (! exists $_{password}) {
            $error->("password is required"); # Another error...
        }

        return if $error->(); # See if we've accumulated any errors

        unless (&authenticate({ $form->input_slice(qw/username password/) })) {
            $error->("no such username or incorrect password");
        }
    });

    if ($form->validate) {

    }
    else {

    }

=head1 DESCRIPTION

CGI::FormBuilderX::More extends CGI::FormBuilder by adding some convenience methods. Specifically,
it adds methods for generating param lists, generating param hash slices, determining whether a param is "missing",
and finding out which submit button was pressed.

=head1 EXPORT

=head2 missing( <value> )

Returns 1 if <value> is not defined or the empty string ('')
Returns 0 otherwise

Note, the number 0 is NOT a "missing" value

=cut

use base qw/CGI::FormBuilder/;

use CGI::FormBuilderX::More::InputTie;

use Sub::Exporter -setup => {
    exports => [
        missing => sub { return sub {
            return ! defined $_[0] || $_[0] eq '';
        } },
    ],
};

sub _attribute($) {
    return "_CGI_FBX_M_$_[0]";
}

=head1 METHODS

=head2 CGI::FormBuilderX::More->new( ... )

Returns a new CGI::FormBuilderX::More object

Configure exactly as you would a normal CGI::FormBuilder object

=cut

sub new {
    my $class = shift;

    my $hash;
    if (@_ == 1 && ref $_[0] eq "HASH") {
        $hash = $_[0];
    }
    elsif (@_ > 1) {
        $hash = { @_ };
    }

    my $self;
    if ($hash) {
        my $validate;
        if ($hash->{validate} && ref $hash->{validate} eq "CODE") {
            $validate = delete $hash->{validate};
        }
        $self = $class->SUPER::new($hash);
        $self->{_attribute("validate")} = $validate;
    }
    else {
        $self = $class->SUPER::new(@_);
    }
    
    return $self;
}

=head2 pressed( <name> )

Returns the value of ->param(_submit_<name>) if _submit_<name> exists and has a value

If not, then returns the value of ->param("_submit_<name>.x") if "_submit_<name>.x" exists and has a value

If <name> is not given, then it will use the form's default submit name to check.

To suppress the automatic prefixing of <name> with "_submit", simply prefix a "+" to <name>

If <name> already has a "_submit" prefix, then none will be applied.

Otherwise, returns undef

Essentially, you can use this method to find out which button the user pressed. This method does not require
any javascript on the client side to work

It checks "_submit_<name>.x" because for image buttons, some browsers only submit the .x and .y values of where the user
pressed.

=cut

sub pressed {
    my $self = shift;

    my ($name, $default);
    if (! @_) {
        $name = $self->submitname;
        $default = 1;
    }
    else {
        $name = shift;
        if (defined $name && length $name) {
            $name = "_submit_$name" unless $name =~ m/^_submit/i || $name =~ s/^\+//;
        }
        else {
            $name = $self->submitname;
        }
    }

    for ($name, "$name.x") {
        if (defined (my $value = $self->input_fetch($_))) {
            return $value || '0E0';
        }
    }

    return $self->submitted if $default;

    return undef;
}

=head2 missing( <name> )

Returns 1 if value of the param <name> is not defined or the empty string ('')
Returns 0 otherwise

Note, the number 0 is NOT a "missing" value

    value       missing
    =====       =======
    "xyzzy"     no
    0           no
    1           no
    ""          yes
    undef       yes

=cut

sub missing {
    my $self = shift;
    my $name = shift;
    my $value = $self->input_fetch($name);

    return 0 if $value;
    return 1 if ! defined $value;
    return 1 if $value eq '';
    return 0; # value is 0
}

=head2 input ( <name>, <name>, ..., <name> )

Returns a list of values based on the param names given

By default, this method will "collapse" multi-value params into the first
value of the param. If you'd prefer an array reference of multi-value params
instead, pass the option { all => 1 } as the first argument (a hash reference).

=cut

sub input {
    my $self = shift;
    return $self->input_fetch(@_) if wantarray && 1 == @_ && ! ref $_[0];

    my $control = {};
    $control = shift if ref $_[0] && ref $_[0] eq "HASH";
    my $all = 0;
    $all = $control->{all} if exists $control->{all};

    my @names = map { ref eq 'ARRAY' ? @$_ : $_ } @_;

    my @params;
    if ($all) {
        for (@names) {
            my @param = $self->input_fetch($_);
            push @params, 1 == @param ? $param[0] : \@param;
        }
    }
    else {
        for (@names) {
            push @params, scalar $self->input_fetch($_);
        }
    }
    return wantarray ? @params : $params[0];
}

=head2 input_slice( <name>, <name>, ..., <name> )

Returns a hash of key/value pairs based on the param names given

By default, this method will "collapse" multi-value params into the first
value of the param. If you'd prefer an array reference of multi-value params
instead, pass the option { all => 1 } as the first argument (a hash reference).

=cut

sub input_slice {
    my $self = shift;
    my $control = {};
    $control = shift if ref $_[0] && ref $_[0] eq "HASH";
    my $all = 0;
    $all = $control->{all} if exists $control->{all};

    my @names = map { ref eq 'ARRAY' ? @$_ : $_ } @_;

    my %slice;
    if ($all) {
        %slice = map { my @param = $self->input_fetch($_); ($_ => 1 == @param ? $param[0] : \@param) } @names;
    }
    else {
        %slice = map { ($_ => scalar $self->input_fetch($_)) } @names;
    }

    return wantarray ? %slice : \%slice;
}

=head2 input_slice_to( <hash>, <name>, <name>, ..., <name> )

The behavior of this method is similar to C<input_slice>, except instead of returning a new hash, it will modify
the hash passed in as the first argument.

Returns the original hash passed in

=cut

sub input_slice_to {
    my $self = shift;
    my $hash = shift;
    my $slice = { $self->input_slice(@_) };
    $hash->{$_} = $slice->{$_} for keys %$slice;
    return $hash;
}

=head2 input_param( <name> )

In list context, returns the all the param values associated with <name>
In scalar context, returns only the first param value associated with <name>

The main difference between C<input_param> and C<input> is that C<input_param> only accepts a single argument
AND C<input_param> addresses the param object directly, while C<input> will access the internal C<input_fetch>/C<input_store> hash 

=cut

sub input_param {
    my $self = shift;
    my @param = $self->{params}->param($_[0]);
    return wantarray ? @param : shift @param;
}

=head2 validate( [<code>] )

In CGI::FormBuilderX::More, we overload to the validate method to offer different behavior. This different
behavior is conditional, and depends on the optional first argument, or the value of C<validate> passed in to C<new>.

If either the first argument or ->new( validate => ... ) is a code reference then $form->validate takes on different behavior:

    1. %_ is tied() to the form's input parameters
    2. An error subroutine for recoding errors is passed through as the first argument to the validation subroutine
    3. Any additional arguments to validate are passed through to the validation subroutine
    4. The errors are available via $form->errors, which is a list reference
    5. The errors are also available in the prepared version of $form (e.g. for template rendering)
    6. $form->validate returns true or false depending on whether any errors were encountered

Here is an example validation subroutine:

    sub {
        my ($form, $error) = @_;

        if (! exists $_{username}) {
            $error->("username is required"); # Register the error
        }
        elsif ($_{username} =~ m/\W/) {
            $error->("username is malformed"); # A username was given but it's bad
        }

        if (! exists $_{password}) {
            $error->("password is required"); # Another error...
        }

        return if $error->(); # See if we've accumulated any errors

        unless (&authenticate({ $form->input_slice(qw/username password/) })) {
            $error->("no such username or incorrect password");
        }
    }

=cut

sub validate {
    my $self = shift;
    my $code;
    if ($_[0] && ref $_[0] eq "CODE") {
        $code = shift;
    }
    elsif ($code = $self->{_attribute("validate")}) {
    }
    else {
        return $self->SUPER::validate(@_);
    }
    local %_;
    $self->input_tie(\%_);
    my @errors;
    my $error = sub {
        return @errors ? 1 : 0 unless @_;
        push @errors, @_;
    };
    eval {
        $code->($self, $error, @_);
    };
    {
        my $error = $@;
        untie %_;
        die $error if $error;
    }
    $self->{_attribute("errors")} = \@errors;
    return scalar @errors ? 0 : 1;
}

=head2 input_tie( <hash> )

Given a hash reference, C<input_tie> will tie the hash to form input. That is,
accessing a hash entry is actually accessing the corresponding form param.
Currently, only STORE, FETCH, and EXISTS are implemented.

    my %hash;
    $form->input_tie(\%hash);

    my $value = $hash{username}; # Actually does: $form->input_fetch("username");

    $hash{password} = "12345"; # Actually does: $form->input_store(password => "12345");

    return unless exists $hash{extra}; # Actually does: ! $form->missing("extra");
                                       # Which checks to see if "extra" is defined and a non-empty string.

=cut

sub input_tie {
    my $self = shift;
    my $hash = shift;
    tie %$hash, "CGI::FormBuilderX::More::InputTie", $self;
    return $hash;
}

=head2 input_fetch( <key> )

Given a key, C<input_fetch> will return the value of first
an internal attribute stash, and then request paramters (via C<input_param>).

This allows you get/set values in the form without affecting the underlying request param.

In array context, the entire value list is returned. In scalar context, only the first value is returned.

=cut

sub input_fetch {
    my $self = shift;
    my $key = shift;
    if (exists $self->{_attribute("input")}->{$key}) {
        my @param = @{ $self->{_attribute("input")}->{$key} };
        return wantarray ? @param : shift @param;
    }
    else {
        return $self->input_param($key);
    }
}

=head2 input_store( <key>, <value>, <value>, ..., <value> )

Given a key and some values, C<input_store> will store the values (as an array reference)
in an internal attribute stash.

This allows you get/set values in the form without affecting the underlying request param.

=cut

sub input_store {
    my $self = shift;
    my $key = shift;
    my @values = 1 == @_ && ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;
    $self->{_attribute("input")}->{$key} = \@values;
}

=head2 errors

In scalar context, returns an array reference of errors found during validation, if any.
In list context, returns the same, but as a list.

=cut

sub errors {
    my $self = shift;
    if (@_) {
        my @errors = 1 == @_ && ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;
        $self->{_attribute("errors")} = \@errors;
    }

    my $errors = $self->{_attribute("errors")} || [];
    return wantarray ? @$errors : [ @$errors ];
}

=head2 prepare

Prepares a hash containing information about the state of the form and returns it.

Essentially, returns the same as CGI::FormBuilder->prepare, with the addition of C<errors>, which is
a list of any errors found during validation.

Returns a hash reference in scalar context, and a key/value list in array context.

=cut

sub prepare {
    my $self = shift;
    my $prepare = $self->SUPER::prepare(@_);
    $prepare->{errors} = $self->errors;
    return wantarray ? %$prepare : $prepare;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-formbuilderx-more at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-FormBuilderX-More>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::FormBuilderX::More


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-FormBuilderX-More>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-FormBuilderX-More>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-FormBuilderX-More>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-FormBuilderX-More>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CGI::FormBuilderX::More
