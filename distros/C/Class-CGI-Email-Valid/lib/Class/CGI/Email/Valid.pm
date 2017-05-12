package Class::CGI::Email::Valid;

use base 'Class::CGI::Handler';
use warnings;
use strict;
use Email::Valid;

=head1 NAME

Class::CGI::Email::Valid - Validate email from forms

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Class::CGI handlers => {
     email => 'Class::CGI::Email::Valid',
 };
 my $cgi = Class::CGI->new;
 my $email = $cgi->param('email');

 if ( my %error_for = $cgi->errors ) {
      if ( $error_for{email} ) {
          ...
      }
 }

=head1 DESCRIPTION

Normally we fetch email from forms, run it through C<Email::Valid> or
something similar, untaint it, if necessary, and save it somewhere.  This
class handles the email validation via C<Email::Valid> and optionally handles
untainting.

Unlike other C<Class::CGI> handlers, this handler returns the email address
unchanged; the C<param()> method does not return an object.  If the email
address failed to validate, the error message will be in the error hash
returned by the C<errors> method.  As usual, the error key will be the name of
the param used.

=head1 Basic usage

 use Class::CGI handlers => {
     email_address => 'Class::CGI::Email::Valid',
 };
 my $cgi   = Class::CGI->new;
 my $email = $cgi->param('email_address');

Any parameter name may be validated as an email address.  If the value of the
parameter does not appear to be a valid email address, 
B<the value entered will still be returned>!  This makes it easy to create
"sticky" forms.

=head2 Untainting

This handler does not provide any untainting facilities.  It merely checks
that the email address entered validated with C<Email::Valid>.  This is
because email addresses often get used in the shell and it is very difficult
to ensure that the full range of email addresses allowed are safe for such
use.  It is the responsibility of the programmer to ensure that a valid email
address is safe for such use.

=head2 Overridding the error message

If you prefer, you can override the default error message by setting the
"error" parameter in the C<Class::CGI::args()> hash.
 
 use Class::CGI handlers => {
     email => 'Class::CGI::Email::Valid',
 };
 my $cgi   = Class::CGI->new;
 $cgi->args( email => { error => "You gave me a bad email address, dummy!" } );
 
 my $email = $cgi->param('email');

=cut

sub handle {
    my $self = shift;
    my $cgi = $self->cgi;
    my $param = $self->param;
    my $email = $cgi->raw_param($param);
    my $args  = $cgi->args($param) || {};
    my $error = $args->{error}
      || "The email address did not appear to be valid";
    unless ( Email::Valid->address($email) ) {
        $cgi->add_error( $param, $error );
    }
    return $email;
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-cgi-email-valid@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-CGI-Email-Valid>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Class::CGI::Email::Valid
