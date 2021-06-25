package Data::FormValidator::EmailValid;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use Email::Valid;

###############################################################################
# Make our methods exportable
###############################################################################
use base qw( Exporter );
our @EXPORT_OK = qw(
    FV_email_filter
    FV_email
    );

###############################################################################
# Version number.
###############################################################################
our $VERSION = '0.09';

###############################################################################
# Subroutine:   FV_email_filter(%options)
# Parameters:   %options    - Options for Email::Valid
###############################################################################
# Filter method which cleans up the given value and returns valid e-mail
# addresses (or nothing, if the value isn't a valid e-mail address).
#
# "Valid" is deemed to mean "looks like an e-mail"; no other tests are done to
# ensure that a valid MX exists or that the address is actually deliverable.
#
# This filter method automatically converts all e-mail addresses to lower-case.
# This behaviour can be disabled by passing through an 'lc=>0' option.
#
# You may also pass through any additional 'Email::Valid' '%options' that you
# want to use; they're handed straight through to 'Email::Valid'.
###############################################################################
sub FV_email_filter {
    my %options = @_;
    # check if we should mangle the e-mail to all lower-case (default yes)
    my $mangle_lc = 1;
    $mangle_lc = delete $options{'lc'} if (exists $options{'lc'});
    # return filter closure
    return sub {
        my $email = shift;
        return Email::Valid->address(
                    '-address'  => $mangle_lc ? lc($email) : $email,
                    '-fudge'    => 1,
                    '-mxcheck'  => 0,
                    %options,
                    );
    };
}

###############################################################################
# Subroutine:   FV_email(%options)
# Parameters:   %options    - Options for Email::Valid
###############################################################################
# Constraint method which checks to see if the value being constrained is a
# valid e-mail address or not.  Returns true if the e-mail address is valid,
# false otherwise.
#
# This differs from the "email" constraint that comes with
# 'Data::FormValidator' in that we not only check to make sure that the e-mail
# looks valid, but also that a valid MX record exists for the address.  No
# other checks are done to ensure that the address is actually deliverable,
# however.
#
# You can also pass through any additional 'Email::Valid' '%options' that you
# want to use; they're handed straight through to 'Email::Valid'.
###############################################################################
sub FV_email {
    my %options = @_;
    return sub {
        my $dfv = shift;
        # get the value we're constraining
        my $val = $dfv->get_current_constraint_value();
        # check for valid e-mail address
        my $rc = Email::Valid->address(
                    '-address'  => $val,
                    '-mxcheck'  => 1,
                    %options,
                    );
        return defined $rc;
    };
}

1;

=for stopwords MX

=head1 NAME

Data::FormValidator::EmailValid - Data::FormValidator e-mail address constraint/filter

=head1 SYNOPSIS

  use Data::FormValidator::EmailValid qw(FV_email_filter FV_email);

  my $results = Data::FormValidator->check(
    {
      'email' => 'Graham TerMarsch <cpan@howlingfrog.com>',
    },
    {
      'required'      => [qw( email )],
      'field_filters' => {
        'email' => FV_email_filter(),
      },
      'constraint_methods' => {
        'email' => FV_email(),
      },
    },
  );

=head1 DESCRIPTION

C<Data::FormValidator::EmailValid> implements a constraint and filter for use
with C<Data::FormValidator> that do e-mail address validation/verification
using C<Email::Valid>.

Although I generally find that I'm using the filter and constraint together,
they've been separated so that you could use just one or the other (e.g. you
may want to constrain on valid e-mail addresses without actually cleaning up or
filtering any of the data provided to you by the user).

=head1 METHODS

=over

=item FV_email_filter(%options)

Filter method which cleans up the given value and returns valid e-mail
addresses (or nothing, if the value isn't a valid e-mail address).

"Valid" is deemed to mean "looks like an e-mail"; no other tests are done
to ensure that a valid MX exists or that the address is actually
deliverable.

This filter method automatically converts all e-mail addresses to
lower-case. This behaviour can be disabled by passing through an
C<lc=E<gt>0> option.

You may also pass through any additional C<Email::Valid> C<%options> that
you want to use; they're handed straight through to C<Email::Valid>.

=item FV_email(%options)

Constraint method which checks to see if the value being constrained is a
valid e-mail address or not. Returns true if the e-mail address is valid,
false otherwise.

This differs from the "email" constraint that comes with
C<Data::FormValidator> in that we not only check to make sure that the
e-mail looks valid, but also that a valid MX record exists for the address.
No other checks are done to ensure that the address is actually
deliverable, however.

You can also pass through any additional C<Email::Valid> C<%options> that
you want to use; they're handed straight through to C<Email::Valid>.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

L<Data::FormValidator>,
L<Email::Valid>.

=cut
