package App::xkcdpass;
our $VERSION = "0.1";

=head1 NAME

App::xkcdpass

=head1 SYNOPSIS

    user:~ xkcdpass
    correct horse battery staple

=head1

There are a few clever web services which provide random passwords based on the
infamous XKCD comic scheme, but the problem is that none of the ones this
author has seen use HTTPS. What's the utility in a password that the whole
world saw when you first got it?

This is a thin wrapper around Crypt::XkcdPassword to make it stupid simple to
generate these passwords locally.

=head1 DEPENDENCIES

perl 5.10 or later

=over 2

=item *

App::Run

=item *

Crypt::XkcdPassword

=head1 Meta

=head2 License

Same as Perl

=head2 Author

Gatlin Johnson <rokenrol@gmail.com>

=head1 Why?

Because C<perl -MCrypt::XkcdPassword -Mfeature="say" -e 'say
Crypt::XkcdPassword->make_password'> is cumbersome.

=cut

1;
