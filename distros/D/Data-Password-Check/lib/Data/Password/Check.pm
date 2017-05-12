package Data::Password::Check;
use strict;
use warnings;
use Carp;

our $VERSION = '0.08';

=head1 NAME

Data::Password::Check - sanity check passwords

=head1 DESCRIPTION

Users can be lazy. If you're a perl programmer this is a good thing. If you're
choosing a password this is a bad thing.

This module performs some sanity checks on passwords. Details on checks than
can be performed are described below.

=head1 SYNOPSIS

Basic use of the module is as follows:

  use Data::Password::Check;

  # check a password
  my $pwcheck = Data::Password::Check->check({
    'password' => $some_password
  });

  # did we have any errors?
  if ($pwcheck->has_errors) {
    # print the errors
      print(
       join("\n", @{ $pwcheck->error_list }),
       "\n"
      );
  }

=cut

=head1 PUBLIC METHODS

These methods are publically available. Use them to your heart's content.

=head2 check($proto,$options)

This is the main function for this module. You must pass one mandatory value in
the $options hash-reference - a password:

  # check a password
  $result = Data::Password::Check->check({'password' => $pwd_to_check});

There are other options that may be passed to invoke further password tests if
required:

=over 4

=item * tests

set this to a list of test names to replace the list of tests performed by the module

e.g. tests =E<gt> [ 'length' ] will make the module perfoem the length check only

=item * tests_append

set this to a list of additional tests to perform. This is useful if you want
to call more tests than are in the default list, or to include your own tests
when inheriting from this module.

e.g. test =E<gt> [ 'mytest1', 'mytest2' ] will make the module perform two
extra tests (assuming they exist) mytest1 and mytest2.

=back

=cut
sub check($$) {
    my ($proto, $options) = @_;
    my ($self, $class);

    $class = ref($proto) || $proto;
    $self = {};
    bless $self, $class;

    # make sure $options is a hash-reference
    unless (ref($options) eq 'HASH') {
        Carp::carp("You need to pass a hash-reference of options to check()");
        return undef;
    }

    # make sure we at least have a password value
    unless (exists $options->{'password'}) {
        Carp::carp("You need to supply a password to check()!");
        return undef;
    }

    # store the password so it's easier to refer to
    # (i.e. $self->{'password'} rather than $self->{'options'}{'password'})
    $self->{'password'} = $options->{'password'};

    # make a copy of the incomong options
    $self->{'options'} = $options;

    # perform the password checks
    $self->_do_checks;

    return $self;
}

=head2 has_errors($class)

This function is used to determine if there were any errors found while sanity
checking the supplied password. It does not return the errors themselves.

Returns B<1> if there were errors, B<0> otherwise

=cut
sub has_errors($) {
    my ($self) = @_;
    return (exists $self->{'_error_count'} and $self->{'_error_count'} > 0);
}

=head2 error_list($class)

This function returns an array-reference to a list of the error messages.
If there are no errors B<undef> is returned.

=cut
sub error_list($) {
    my ($self) = @_;
    if ($self->has_errors) {
        return $self->{'_errors'};
    }

    return undef;
}


=head1 AVAILABLE CHECKS

By default the module will perform all checks listed below. You can limit the
number of checks by passing a list of desired tests via the B<tests> option
when calling check(). e.g.

  Data::Password::Check->check({
    ...
    'tests' => [ 'length' ], # check only that the password meets a minimum-length requirement
    ...
  });

=cut

=head2 alphanumeric_only

Make sure the password only contains a-z, A-Z and 0-9 characters.

=cut
sub _check_alphanumeric_only($) {
    my ($self) = @_;

    # make sure the password only contains alphanumeric characters
    unless ($self->{'password'} =~ /^[[:alnum:]]+$/) {
        $self->_add_error("Your password may only contain alphanumeric characters (A-Z, a-z and 0-9)");
    }
}

=head2 alphanumeric

Make sure the password contains one of each from the following sets: a-z, A-Z and 0-9

=cut
sub _check_alphanumeric($) {
    my ($self) = @_;

    # make sure the password contains one lower case and one uppercase character, and one digit - at least
    # tr// seems the best way (at the moment) to check this requirement
    unless (
        ($self->{'password'} =~ tr/a-z//) and
        ($self->{'password'} =~ tr/A-Z//) and
        ($self->{'password'} =~ tr/0-9//) ) {
        $self->_add_error("Your password must contain mixed-case letters and numbers");
    }
}

=head2 length

Make sure the password it at least 6 characters long. If B<min_length> was passed
as an option to check(), this value will be used instead, assuming it's a
positive integer.

=cut
sub _check_length($) {
    my ($self) = @_;
    my $min_length = 6;

    # does the user want a different length
    if (exists $self->{'options'}{'min_length'} and not defined $self->{'options'}{'min_length'}) {
        # issue a warning
        Carp::cluck("min_length argument must be a defined value");
        # return undef
        return undef;
    }
    elsif (exists $self->{'options'}{'min_length'} and defined $self->{'options'}{'min_length'}) {
        # is it a positive, on-zero, integer?
        if ($self->{'options'}{'min_length'} =~ /^[1-9]\d*$/) {
            $min_length = $self->{'options'}{'min_length'};
        }
        else {
            # issue a warning
            Carp::cluck("min_length argument [$self->{'options'}{'min_length'} isn't a positive, non-zero, integer");
            # return undef
            return undef;
        }
    }

    # if password is undefined, set it to '', so we aren't comparing undef with anything 
    unless (defined $self->{'password'}) {
        $self->{'password'} = '';
    }

    # now we can check that the password meets the minimum length requirement
    if (length($self->{'password'}) >= $min_length) {
        return 1;
    }
    else {
        # store a failure message
        $self->_add_error("The password must be at least $min_length characters");
    }
}

=head2 mixed_case

Make sure the password is mixes case, i.e. not all lower case, nor all upper case

=cut
sub _check_mixed_case($) {
    my ($self) = @_;

    # does the password contain at least one lowercase and one uppercase character?
    unless ($self->{'password'} =~ /(?:[A-Z].*[a-z]|[a-z].*[A-Z])/) {
        $self->_add_error("Your password must contain a mixture of lower and upper-case letters");
    }
}

=head2 diverse_characters

Make sure the password is contains a diversity of character group types
(uppercase, lower case, digits, symbols). By default, at least one character
group must be present in the password (which any password will satisfy -
override this to invoke the test). If B<diversity_required> was passed
as an option to check(), this value will be used instead.

=cut
sub _check_diverse_characters($) {
    my ($self) = @_;
    my $diversity_required = 1;
    # does the user want a different diversity?
    if (exists $self->{'options'}{'diversity_required'} and not defined $self->{'options'}{'diversity_required'}) {
        # issue a warning
        Carp::cluck("diversity_required argument must be a defined value");
        return undef;
    }
    elsif (exists $self->{'options'}{'diversity_required'} and defined $self->{'options'}{'diversity_required'}) {
        # is it in range?
        if ($self->{'options'}{'diversity_required'} =~ /^[1-4]\d*$/) {
            $diversity_required = $self->{'options'}{'diversity_required'};
        }
        else {
            # issue a warning
            Carp::cluck("diversity_required argument [$self->{'options'}{'diversity_required'} isn't in the range 1-4");
            return undef;
        }
    }
    
    my $group_count = 0;
    foreach my $pattern (qw([A-Z] [a-z] [0-9] [^A-Za-z0-9]))
    {
        if ($self->{'password'} =~ /$pattern/) {
            $group_count++;
        }
    }
    
    # Are enough character groups used to satisfy diversity requirements?
    if ($group_count < $diversity_required) {
        $self->_add_error("Your password must contain a good mix of character types, from at least $diversity_required of the following categories: Uppercase letters, lowercase letters, numeral, symbols.");
    }
}

=head2 silly

Make sure the password isn't a known silly word (e.g 'password' is a bad choice
for a password).

The default list contains I<qwerty>, and I<password> only. You may choose to
replace this list of words or to add your own to the end of the list.

If you wish to B<replace> the list of silly-words, you should pass them in via
the options when calling check(), as 'silly_words'. e.g.

  Data::Password::Check->check({
    ...
    'silly_words' => [ 'my', 'silly', 'words' ],
    ...
  });

If you would like to add words to the existing list, you should pass them in
via the 'silly_words_append' option when calling check(). e.g.

  Data::Password::Check->check({
    ...
    'silly_words_append' => [ 'more', 'silly', 'words' ],
    ...
  });

All matching is case-insensitive, and if you choose to append words, duplicates
will be omitted.

=cut
sub _check_silly($) {
    my ($self) = @_;
    # default words we don't want people to use as passwords
    my @silly_words = qw{
        password
        qwerty
    };
    # does the user want to REPLACE the current list of words
    if (exists $self->{'options'}{'silly_words'}) {
        # is it an array-ref?
        if (ref($self->{'options'}{'silly_words'}) eq 'ARRAY') {
            # override the default checks
            @silly_words = @{ $self->{'options'}{'silly_words'} };
        }
        else {
            Carp::carp("The 'silly_words' option must be an array-reference. Continuing with default list.");
        }
    }

    # does the user want to ADD to the existing list of word
    if (exists $self->{'options'}{'silly_words_append'}) {
        # is it an array-ref?
        if (ref($self->{'options'}{'silly_words_append'}) eq 'ARRAY') {
            # push the words onto the end of the list
            # make sure we don't already have the word
            foreach my $append (@{ $self->{'options'}{'silly_words_append'} }) {
                unless ( grep { /^$append$/ } @silly_words ) {
                    push @silly_words, $append;
                }
            }
        }
        else {
            Carp::carp("The 'silly_words' option must be an array-reference. Continuing with default list.");
        }
    }

    # now we loop through the silly_words and make sure our password doesn't match them
    foreach my $silly (@silly_words) {
        # do a case-insensitive match, but look for the whole string
        if ($self->{'password'} =~ /^$silly$/i) {
            $self->_add_error("You may not use '$self->{'password'}' as your password");
        }
    }
}

=head2 repeated

Make sure the password isn't a single character repeated, e.g. 'aaaaaaaaaa'.

=cut
sub _check_repeated($) {
    my ($self) = @_;

    # is the password made up of the same character repeated?
    if ($self->{'password'} =~ /^(.)\1+$/) {
        $self->_add_error("You cannot use a single repeated character as a password");
    }
}


=head1 PRIVATE METHODS

These methods are private to this module. If you choose to use them outside the
module, all bets are off.

=head2 _do_checks($self)

This function calls each required test in turn. It's an internal function
called within check().

=cut
sub _do_checks($) {
    my ($self) = @_;
    my (@checks, $fn, $custom_checks);

    # the list of checks to make
    @checks = qw(
        length
        mixed_case
        silly
        repeated
    );
    # custom_checks defaults to false
    $custom_checks = 0;

    # allow the user to override the list of checks
    # we require the 'tests' option to exist, and to be an array-reference
    if (exists $self->{'options'}{'tests'}) {
        if (ref($self->{'options'}{'tests'}) eq 'ARRAY') {
            # override the default checks
            @checks = @{ $self->{'options'}{'tests'} };
            # set the custom_checks flag
            $custom_checks = 1;
        }
        else {
            Carp::carp("The 'tests' option must be an array-reference. Continuing with default tests.");
        }
    }

    # allow the user to override the list of checks
    # we require the 'tests' option to exist, and to be an array-reference
    if (exists $self->{'options'}{'append_tests'}) {
        if (ref($self->{'options'}{'append_tests'}) eq 'ARRAY') {
            # override the default checks
            @checks = (@checks, @{ $self->{'options'}{'append_tests'} });
            # set the custom_checks flag
            $custom_checks = 1;
        }
        else {
            Carp::carp("The 'append_tests' option must be an array-reference. Continuing with default tests.");
        }
    }

    # loop through the checks we would like to do
    foreach my $test (@checks) {
        # set the name of the function we'd like to call
        my $fn = "_check_${test}";
        # if we can run the function, do so
        if ($self->can("_check_${test}")) {
            unless (defined $self->$fn) {
                # make a note that we skipped the test
                push @{ $self->{'skipped_tests'} }, $test;
                Carp::carp("skipped test '$test' due to errors") if $self->{'DEBUG'};
            };
        }
        # otherwise warn that we're trying to call something
        # that we can't find
        else {
            # warn or carp, depending on whether we've got a custom
            # list of tests
            if ($custom_checks) {
                Carp::carp("The are no password checks available for '$test'");
            }
            else {
                warn "no such password check function: $fn()";
            }
        }
    }
}

=head2 _add_error($class,$message)

This function is used to add an error message to the internal store.
The errors can later be retrieved using the B<error_list()> method.

=cut
sub _add_error($$) {
    my ($self, $message) = @_;

    # increase the count of errors we've added
    $self->{'_error_count'} ++;

    # add the error message to a list of messages
    push @{ $self->{'_errors'} }, $message;
}

=head2 _skipped_test($class,$testname)

This function exists so that it's possible to work out if a test was skipped
because "something went wrong" - usually because of an invalid option passed in
via the check() options.

This function was written to enable some tests in the "make test" phase of
installing the module.

=cut
sub _skipped_test($$) {
    my ($self, $testname) = @_;

    # do we have a list of skipped tests?
    if (exists $self->{'skipped_tests'}) {
        # does $testname exist in the list?
        if (grep { /^$testname$/ } @{ $self->{'skipped_tests'} }) {
            return 1;
        }
    }

    # no indication that we skipped the test
    return 0;
}

=head1 AUTHOR

Chisel Wright C<< <chiselwright@berlios.de> >>

=head1 CONTRIBUTORS

Dermot McNally C<< CPANID: DERMOT >>

=head1 PROJECT HOMEPAGE

This project can be found at BerliOS:
L<http://developer.berlios.de/projects/d-p-check/>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2005-2007 by Chisel Wright

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

# be true
1;

__END__
vim: ts=8 sts=4 et sw=4 sr sta
