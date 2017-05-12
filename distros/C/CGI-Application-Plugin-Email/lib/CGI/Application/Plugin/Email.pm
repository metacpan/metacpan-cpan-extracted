package CGI::Application::Plugin::Email;


=head1 NAME

CGI::Application::Plugin::Email - Lazy loaded Email

=head1 SYNOPSIS

Just a little wrapper around Email::Stuff. Useful to add easy emailing
functionality without loading having to load the library unless it's actually
called.

    use CGI::Application::Plugin::Email qw( :std );

Creating a new Email::Stuff object:-

  $email = $self->Email->new;

If you aren't happy with importing a method named C<Email> into your namespace
then you can choose the method name:-

    use CGI::Application::Plugin::Email ( ':std', { method => 'EmailStuff' } );

Creating a new Email::Stuff object:-

  $email = $self->EmailStuff->new;


=head1 DESCRIPTION

This module is a wrapper around C<Email::Stuff>.
The only real benefit is the lazy loading so that Email::Stuff isn't loaded with
every request. This makes it a good option for scripts running through CGI.

=head1 Methods

=head2 Email

This is the object that gets exported.
See L</SYNOPSIS>

=head1 Export groups

Only an Email:::Stuff object can be exported. It's not exported by default,
but this module is pretty useless without it. You can choose the name of the
method that invokes the object.

:std exports:-

    Email

=head1 FAQ

=head2 How do I send email?

View the L<Email::Stuff> documentation on how to use the returned email object
to send mail.

=head2 Why?

Emailing can be a pain, wanted a quick and easy way of doing it. Email::Stuff
provides that, but I didn't want it slowing down my cgi requests that didn't
actually use it. Also there were no CGI::Application plugins for sending email,
so a plugin providing an easy path to emailing for new people seemed a good
idea :)

=head1 Thanks to:-

L<Email::Stuff>

Adam Kennedy for creating Email::Stuff and for making sure it had Pure Perl
dependency options when I asked him :)

=head1 Come join the bestest Perl group in the World!

Bristol and Bath Perl moungers is renowned for being the friendliest Perl group
in the world. You don't have to be from the UK to join, everyone is welcome on
the list:-
L<http://perl.bristolbath.org>

=head1 AUTHOR

Lyle Hopkins ;)

=cut



use strict;
use warnings;
use Carp;

use vars qw ( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = ();

%EXPORT_TAGS = (
    std => [],
);

$VERSION = '0.01';

my $email;

sub import {
    $email = new__ CGI::Application::Plugin::Email::guts;
    my $exportmethod = 'Email';
    if ( ref $_[ $#_ ] eq 'HASH' ) {
        my $attrib = pop @_;
        $exportmethod = $attrib->{method} if ( $attrib->{method} );
    }#if
    ### Check name if legal
    unless ( $exportmethod =~ /^[0-9a-z_]+$/i ) {
        croak( "Illegal export method name" );
    }#unless
    push( @EXPORT_OK, $exportmethod );
    push( @{ $EXPORT_TAGS{std} }, $exportmethod );

    {
        no strict 'refs';
        *{ $exportmethod } = sub {
            unless ( $email->{params}->{__loaded} ) {
                $email->__LoadEmail();
            }#unless
            return $email;
        }#sub
    }#block

    CGI::Application::Plugin::Email->export_to_level(1, @_);
}#sub



package CGI::Application::Plugin::Email::guts;


sub new__ {
    my $class = shift;
    my $obj = {};
    bless( $obj, $class );
    return $obj;
}#sub


sub new {
    shift;
    return Email::Stuff->new( @_ );
}#sub


sub __LoadEmail {
    require Email::Stuff;
    import Email::Stuff;
}#sub


1;
