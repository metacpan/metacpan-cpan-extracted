package Data::Transpose::EmailValid;

use strict;
use warnings;
use Email::Valid;
use Moo;
extends 'Data::Transpose::Validator::Base';
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Data::Transpose::EmailValid - Perl extension to check if a mail is valid (with some autocorrection)

=head1 SYNOPSIS

  use Data::Transpose::EmailValid;

  my $email = Data::Transpose::EmailValid->new;

  ok($email->is_valid("user@domain.tld"), "Mail is valid");

  ok(!$email->is_valid("user_e;@domain.tld"), "Mail is not valid");

  warn $email->reason; # output the reason of the failure

=head1 DESCRIPTION

This module check if the mail is valid, using the L<Email::Valid>
module. It also provides some additional methods.

=head2 AUTO CORRECTION

This validator corrects common mistakes automatically:

=over 4

=item

C<.ocm> instead of C<.com> as top level domain for C<aol.com>,
C<gmail.com>, C<hotmail.com> and C<yahoo.com>, e.g. C<tp@gmail.ocm>.

=item

Double dots before top level domain, e.g. C<tp@linuxia..de>.

=back

Please suggest further auto correction examples to us.

=head1 METHODS

=head2 new

Constructor. It doesn't accept any arguments.

=cut

has _email_valid => (is => 'ro',
                     isa => Object,
                     default => sub {
                         return Email::Valid->new(
                                                  -fudge   => 1,
                                                  -mxcheck => 1,
                                                 );
                     });

has input => (is => 'rwp',
              isa => Maybe[Str]);

has output => (is => 'rwp',
               isa => Maybe[Str]);


=head2 input

Accessor to the input email string.

=head2 output

Accessor to the output email string.

=head2 reset_all 

Clear all the internal data

=cut


sub reset_all {
    my $self = shift;
    $self->reset_errors;
    $self->_set_input(undef);
    $self->_set_output(undef);
}

=head2 $obj->is_valid($emailstring);

Returns the email passed if valid, false underwise.

=cut


sub is_valid {
    return if @_ == 1;

    my ($self, $email) = @_;

    # overwrite old data
    $self->reset_all;

    $self->_set_input($email);

    # correct common typos # Maybe add an option for this?
    $email = $self->_autocorrect;

    # do validation
    $email = $self->_email_valid->address($email);
    unless ($email) {
        $self->error($self->_email_valid->details);
        return;
    }

    $self->_set_output($email);
    return $email;
}

=head2 $obj->email

Returns the last checked email.

=cut

sub email  { shift->output }

=head2 $obj->reason

Returns the reason of the failure of the last check, false if it was
successful.

=cut


sub reason { shift->error }

=head2 $obj->suggestion

This module implements some basic autocorrection. Calling ->suggestion
after a successfull test, will return the suggested value if the input
was different from the output, false otherwise.

=cut

sub suggestion {
    my ($self) = @_;
    return if $self->error;

    if ($self->input ne $self->output) {
        return $self->output;
    }

    return;
}


sub _autocorrect {
    my $self = shift;
    my $email = $self->input;
    # trim
    $email =~ s/^\s+//;
    $email =~ s/\s+$//;
    # .ocm -> .com
    foreach (qw/aol gmail hotmail yahoo/) {
        $email =~ s/\b$_\.ocm$/$_.com/;
    }
    # double dots in domain part
    $email =~ s/\.\.(\w+)$/.$1/;

    # setting the error breaks the retrocompatibility
    # $self->error("typo?");
    return $email;
}

=head1 AUTHOR

Uwe Voelker <uwe@uwevoelker.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2016 Uwe Voelker <uwe@uwevoelker.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;

