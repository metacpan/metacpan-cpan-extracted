#!/usr/bin/perl -w

#
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.
#
# $Id: Validator.pm,v 1.48 2003/02/05 17:18:38 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick::Validator;
use strict;

require    Exporter;
our @ISA = qw( Exporter );
our @EXPORT  = qw( 
    do_validation_routine
    parse_validation_routine
    call_user_validation
    call_fm_validation

    get_validation_attribute
    validate_field 
    validate_page 
    validate_all 
    list_error_messages
    errors

    nonblank
    integer 
    number 
    word 
    date 

    maxlength 
    minlength
    exactlength 
    lengthrange

    url 
    username 
    password
    domain_name 
    ip_number
    email_simple
    mac_address

    US_state 
    US_zipcode 
    iso_country_code

    credit_card_number 
    credit_card_expiry
);


use CGI::FormMagick::Validator::Basic;
use CGI::FormMagick::Validator::Length;
use CGI::FormMagick::Validator::Network;
use CGI::FormMagick::Validator::Geography;
use CGI::FormMagick::Validator::Business;

use CGI::FormMagick::Sub;

=pod

=head1 NAME

CGI::FormMagick::Validator - validate data from FormMagick forms

=head1 SYNOPSIS

use CGI::FormMagick;

=head1 DESCRIPTION

This module provides some common validation routines.  Validation
routines return the string "OK" if they succeed, or a descriptive
message if they fail.

=for testing
BEGIN: {
    use CGI::FormMagick;
    use CGI::FormMagick::Validator;
    use CGI;
    use vars qw($fm);
}
$fm = CGI::FormMagick->new(type => 'file', source => 't/simple.xml');
$fm->parse_xml(); # suck in structure without display()ing

=head2 Validation routines provided:

See the following for information on categories of validation we've
provided:

=over 4

=item *

L<CGI::FormMagick::Validator::Basic>

=item *

L<CGI::FormMagick::Validator::Length>

=item *

L<CGI::FormMagick::Validator::Network>

=item *

L<CGI::FormMagick::Validator::Geography>

=item *

L<CGI::FormMagick::Validator::Business>

=back


=head2 Using more than one validation routine per field

You can use multiple validation routines like this:

    value="foo" validation="my_routine, my_other_routine"

However, there are some requirements on formatting to make sure that
FormMagick can parse what you've given it.

=over 4

=item *

Parens are optional on subroutines with no args.  C<my_routine> is
equivalent to C<my_routine()>.

=item *

You B<MUST> put a comma then a space between routine names, eg
C<my_routine, my_other_routine> B<NOT> C<my_routine,my_other_routine>.

=item *

You B<MUST NOT> put a space between args to a routine, eg
C<my_routine(1,2,3)> B<NOT> C<my_routine(1, 2, 3)>.

=back

This will be fixed to be more flexible in a later release.

=head2 Making your own routines

FormMagick's validation routines may be overridden and others may be added on 
a per-application basis.  To do this, simply define a subroutine in your
CGI script that works in a similar way to the routines provided by
CGI::FormMagick::Validator and use its name in the validation attribute 
in your XML.

The arguments passed to the validation routine are the value of the
field (to be validated) and any subsequent arguments given in the
validation attribute.  For example:

    value="foo" validation="my_routine"
    ===> my_routine(foo)

    value="foo" validation="my_routine(42)"
    ===> my_routine(foo, 42)

The latter type of validation routine is useful for routines like
C<minlength()> and C<lengthrange()> which come with
CGI::FormMagick::Validator.

Here's an example routine that you might write:

    sub my_grep {
        my $data = shift;
        my @list = @_;
        if (grep /$data/, @list) {
            return "OK" 
        } else {
            return "That's not one of: @list"
        }
    }


=pod

=head1 SECURITY CONSIDERATIONS AND METHODS FOR MANUAL VALIDATION

If you use page post-event or pre-event routines which perform code
which is in any way based on user input, your application may be
susceptible to a security exploit.

The exploit can occur as follows:

Imagine you have an application with three pages.  Page 1 has fields A,
B and C.  Page 2 has fields D, E and F.  Page 3 has fields G, H and I.

The user fills in page 1 and the data FOR THAT PAGE is validated before 
they're allowed to move on to page 2.  When they fill in page 2, the
data FOR THAT PAGE is validated before they can move on.  Ditto for page
3.  

If the user saves a copy of page 2 and edits it to contain an extra
field, "A", with an invalid value, then submits that page back to
FormMagick, the added field "A" will NOT be validated.

This is because FormMagick relies on the XML description of the page to
know what fields to validate.  Only the current page's fields are
validated, until the very end when all the fields are revalidated one
last time before the form post-event is run.  This means that we don't
suffer the load of validating everything every time, and it will work
fine for most applications.

However, if you need to run page post-event or pre-event routines that
rely on previous pages' data, you should validate it manually in your
post-event or pre-event routine.  The following methods are used
internally by FormMagick for its validation, but may also be useful to
developers.

Note: this stuff may be buggy.  Please let us know how you go with it.

=head2 $fm->validate_field($fieldname | $fieldref)

This routine allows you to validate a specific field by hand if you need
to.  It returns an arrayref containing a list of error messages if 
validation fails, or the string "OK" on success.

Examples of use:

This is how you'd probably call it from your script:

  if ($fm->validate_field("credit_card_number") eq "OK")) { }

FormMagick uses references to a field object, internally:

  if ($fm->validate_field($fieldref) eq "OK")) { }

(that's so that FormMagick can easily loop through the fields in a page;
you shouldn't need to do that)

If you want to do something with the error messages returned:

    my $errors = $fm->validate_field($field);
    if (ref $errors) {
        foreach my $e (@$errors) {
            do_something();
        }
    } else {
        # it's OK
    }

=begin testing
local $fm->{cgi};  # we're going to mess with the CGI fields

my $field = {
    validation =>  'nonblank',
    id          => 'testfield',
    label       => 'Test Field',
};

my $goodcgi = CGI->new( { testfield => 'testing' } );
$fm->{cgi} = $goodcgi;
is($fm->validate_field($field), "OK", "Test a single field");

my $badcgi  = CGI->new( { testfield => '' } );
$fm->{cgi} = $badcgi;
isnt($fm->validate_field($field), "OK", "Test a single field");
is(ref($fm->validate_field($field)), ARRAY, "return an arrayref");

TODO: {
    local $TODO = "Make validate_field accept a fieldname instead of a fieldref";
    is($fm->validate_field("firstname"), "OK", "validate_field accepts field names");
}

=end testing

=cut

sub validate_field {
    my ($self, $field) = @_; 
  
    if (not ref $field) {
        return undef; # TODO: make this take fieldnames, not just fieldrefs.
    }

    my $validation = $self->get_validation_attribute($field);
    my $fieldname  = $field->{id};
    my $fieldlabel = $field->{label} || "";
    my $fielddata  = $self->{cgi}->param($fieldname);

    $self->debug_msg('Validating field ' . (defined $fieldname ? $fieldname : ''));

    # just skip everything else if there's no validation to do.
    return "OK" unless $validation;

    my @results;
    # XXX argh! this split statement requires that we write validators like 
    # "lengthrange(4, 10), word" like "lengthrange(4,10), word" in order to 
    # work. Eeek. That's not how this should work. But it was even
    # more broken before (I changed a * to a +). 
    # OTOH, I'm not sure it's fixed now. --srl

    my @validation_routines = split( /,\s+/, $validation);
    # $self->debug_msg("Going to perform these validation routines: @validation_routines");

    foreach my $v (@validation_routines) {
        my ($validator, $arg) = $self->parse_validation_routine($v);
        my $result = $self->do_validation_routine($validator, $fielddata, $arg);

        push (@results, $result) if $result ne "OK";

        # for multiple errors, put semicolons between the errors before
        # shoving them in a hash to return.    

    }

    if (@results) {
        return \@results;
    } else {
        return "OK";
    }
}

=head2 get_validation_attribute($field)

A tiny little routine which, given a field hashref (as seen in
validate_field() will give you the value of the validation attribute
from that field.

This was split out to make it easy to have a subclass add validation
routines by overriding this function.

=begin testing

can_ok($fm, "get_validation_attribute");

my $field = {
    validation =>  'nonblank',
    id          => 'testfield',
    label       => 'Test Field',
};

is($fm->get_validation_attribute($field), "nonblank", "get_validation_attribute");

=end testing

=cut

sub get_validation_attribute {
    my ($fm, $field) = @_;
    return $field->{validation};
}

=pod

=head2 $fm->validate_page($number | $name)

This routine allows you to validate a single page worth of fields.  It
can accept either a page number (counting from zero) or a page name. 

This routine returns a hash of errors, with the keys being the names of
fields which have errors and the values being the error messages.  An
empty hash means no errors.

The routine will return undef if it can't figure out what page you want.

Examples:

    my %errors = $fm->validate_page(3);
    my %errors = $fm->validate_page("CreditCardDetails");
    if (%errors) { ... }

=begin testing

local $fm->{cgi} = CGI->new( { 
    firstname => 'testing',     # this is known-good
    lastname => '',             # bad. should be nonblank.
    long => "abc",              # bad. should be long.
    short => "abcdefghijk",     # bad. should be short.
} );

my @pagenames = ("Personal", "More", "More again");
foreach (0..2) {
    my %errors = $fm->validate_page($_);
    is(scalar keys %errors, $_, "Test page '$_' with $_ known errors");
    my %name_errors = $fm->validate_page($pagenames[$_]);
    is(scalar keys %name_errors, $_, "Test erroring page '$pagenames[$_]'");
}

$fm->{cgi} = CGI->new( { 
    firstname => 'willy',
    lastname => 'wonka',
    long => "abcdefg",
    short => "abc",
} );

foreach (@pagenames) {
    my %errors = $fm->validate_page($_);
    is(scalar keys %errors, 0, "Test page '$_' without errors");
}

ok(!defined $fm->validate_page("abcde"), "Validate page returns undef for a non-page");
ok(!defined $fm->validate_page(),        "Validate page returns undef no args");

=end testing

=cut

sub validate_page {
    my ($self, $param) = @_;

    return undef unless defined $param;

    my $page_index;     # what page number is this?

    my $is_integer_like;
    {
        local $^W = 0;
        $is_integer_like = int($param) eq $param;
    }
    if ($is_integer_like) {
        $page_index = $param;
    } else {
        $page_index = $self->get_page_by_name($param);
    }
    return undef unless defined $page_index;

    $self->debug_msg("Validating page $page_index.");

    my %errors;
 
    my $this_page = $self->form->{pages}->[$page_index];

    foreach my $field (@{$this_page->{fields}}) {
        my $result = $self->validate_field($field);
        unless ($result eq "OK") {
            $errors{$field->{label}} = $result;
        }
    } 

    my $howmany = (keys %errors);
    $self->debug_msg("Done validating page $page_index.  Found $howmany errors.");
  
    $self->{errors} = \%errors;
    return %errors;
}

=pod

=head2 $fm->validate_all()

This routine goes through all the pages that have been visited (using
FormMagick's built-in page stack to keep track of which these are) and
runs C<validate_page()> on each of them.

Returns a hash of all errors, and set $self->{errors} when done.

=begin testing

local $fm->{cgi} = CGI->new( { 
    firstname => 'testing',     # this is known-good
    lastname => '',             # bad. should be nonblank.
    long => "abc",              # bad. should be long.
    short => "abcdefghijk",     # bad. should be short.
} );

local $fm->{page_stack} = "0,1";
local $fm->{page_number} = 2;

my %errors = $fm->validate_all();
is(scalar keys %errors, 3, "Test all pages at once.");

=end testing

=cut

sub validate_all {
    my ($self) = @_;

    my %errors;

    $self->debug_msg("Validating all form input.");

    # Walk through all the pages on the stack and make sure
    # the data for their fields is still valid
    foreach my $pagenum ( (split(/,/, $self->{page_stack})), $self->{page_number} ) {
        # add the errors from this page to the errors from any other pages
        %errors = ( %errors, $self->validate_page($pagenum) );
    }

    $self->{errors} = \%errors;
        return %errors;
}


=pod

=head1 DEVELOPER METHODS

The following methods are probably not of interest to anyone except
developers of FormMagick


=head2 parse_validation_routine ($validation_routine_name)

parse the name of a validation routine into its name and its parameters.
returns a 2-element list, $validator and $arg.

=for testing
my @rv = $fm->parse_validation_routine("foo(1,2)");
is($rv[0], "foo", "Pick up validation routine name");
is($rv[1], "1,2", "Pick up validation routine args");

=cut

sub parse_validation_routine {
    my ($self, $validation_routine_name) = @_;
    
    my ($validator, $arg) = ($validation_routine_name =~ 
        m/
        ^       # start of string
        (\w+)   # a word (--> $validator)
        (?:     # non-capturing (to group the (.*))
        \(      # literal paren
        (.*)    # whatever's inside the paren (--> $arg)
        \)      # literal close paren
        )?      # (.*) is optional (zero or one of them)
        $       # end of string
        /x );

    return ($validator, $arg);
}

=pod

=head2 do_validation_routine ($self, $validator, $fielddata, $args)

Runs validation functions with arguments.  Looks first for a user
routine, then for a builtin, then if it can't find either it just kinda
shrugs and says "OK".

Returns "OK" if validation is successful, or the error message returned
by the validation routine otherwise.

=begin testing

sub user1 {
    return "OK";
}

is($fm->do_validation_routine("nonblank", "abc"), "OK", 
    "Find builtin validation routine");
is($fm->do_validation_routine("user1", "abc"), "OK", 
    "Find user validation routine");
{
    local $^W = 0;
    is($fm->do_validation_routine("nosuchthing", "abc"), "OK", 
        "Default to OK if you can't find a validation routine");
}

=end testing

=cut

sub do_validation_routine {
    my ($self, $validator, $fielddata, $args) = @_;
    $fielddata ||= "";
    my $result;

    my $cp = $self->{calling_package};

    # TODO: this could use some documentation.
    # TODO: It could also use CGI::FormMagick::Sub::exists() directly?
    $result = 
        $self->call_user_validation($validator, $fielddata, $args) ||
        $self->call_fm_validation  ($validator, $fielddata, $args);

    if (!$result) {
        warn "Couldn't find validator $validator\n" if $^W;
        $result = "OK";   # if we can't figure it out, just go with OK
    }

    $self->debug_msg("Validation result is $result");
    return $result;
}

=head2 $fm->call_user_validation_routine($routine, $data, $args)

Calls the user's validation routine, in the calling package (usually
main).

=begin testing
sub usertest_ok {
    shift;
    return "OK";
}

sub usertest_data {
    shift;
    return shift;
}

sub usertest_arg1 {
    shift;
    return $_[1];
}

sub usertest_arg2 {
    shift;
    return $_[2];
}

is($fm->call_user_validation("usertest_ok",   "", ""),    "OK",
    "Call a simple user validation routine");
is($fm->call_user_validation("usertest_data", "FOO", ""), "FOO",
    "Call a user validation routine with data");
is($fm->call_user_validation("usertest_arg1", "", "bar"), "bar",
    "Call a user validation routine with one arg");
is($fm->call_user_validation("usertest_arg2", "", "bar,baz"), "baz",
    "Call a user validation routine with two args");

=end testing

=cut

sub call_user_validation {
    my ($self, $validator, $data, $args) = @_;

    my %sub = (
        package => $self->{calling_package},
        sub => $validator,
        args => [ $self, $data ],
        comma_delimited_args => $args,
    );

    CGI::FormMagick::Sub::exists(%sub) or return undef;
    return CGI::FormMagick::Sub::call(%sub);
}

=head2 $fm->call_fm_validation($routine, $data, $args)

Calls a builtin validation routine in CGI::FormMagick::Validator.

=begin testing

is($fm->call_fm_validation("nonblank", "abc", ""),    "OK",
    "Call a simple builtin validation routine");
isnt($fm->call_fm_validation("nonblank", "", ""),    "OK",
    "Call a simple builtin validation routine");
is($fm->call_fm_validation("minlength", "abc", "2"),    "OK",
    "Call a builtin validation routine with args");
is($fm->call_fm_validation("lengthrange", "abc", "1,3"),    "OK",
    "Call a builtin validation routine with multiple args");

=end testing

=cut


sub call_fm_validation {
    my ($self, $validator, $data, $args) = @_;
    my %sub = (
        package => 'CGI::FormMagick::Validator',
        sub => $validator,
        args => [ $self, $data ],
        comma_delimited_args => $args,
    );

    CGI::FormMagick::Sub::exists(%sub) or return undef;

    return CGI::FormMagick::Sub::call(%sub);
}



=pod

=head2 list_error_messages()

prints a list of error messages caused by validation failures

=cut

sub list_error_messages {
    my $self = shift;
    print qq(<div class="error">\n);
    print qq(<h3>Errors</h3>\n);
    print "<ul>";

    foreach my $field (keys %{$self->{errors}}) {
        print "<li>$field: $self->{errors}->{$field}\n";
    }
    print "</ul></div>\n";
}


sub errors {
    my $self = shift;
    if ($self->{errors}) {
        return %{$self->{errors}};
    } else {
        return ();
    }
}


=pod

=head1 SEE ALSO

The main perldoc for CGI::FormMagick

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

return 1;
