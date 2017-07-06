#!/usr/bin/perl

package Catalyst::Authentication::Store::Htpasswd; # git description: v1.005-4-g2915058
# ABSTRACT: Authen::Htpasswd based user storage/authentication

use base qw/Class::Accessor::Fast/;
use strict;
use warnings;

use Authen::Htpasswd 0.13;
use Catalyst::Authentication::Store::Htpasswd::User;
use Scalar::Util qw/blessed/;

our $VERSION = '1.006';

BEGIN { __PACKAGE__->mk_accessors(qw/file user_field user_class/) }

sub new {
    my ($class, $config, $app, $realm) = @_;

    my $file = delete $config->{file};
    unless (ref $file) {
        my $filename = ($file =~ m|^/|) ? $file : $app->path_to($file)->stringify;
        die("Cannot find htpasswd file: $filename\n") unless (-r $filename);
        $file = Authen::Htpasswd->new($filename);
    }
    $config->{file} = $file;
    $config->{user_class} ||= __PACKAGE__ . '::User';
    $config->{user_field} ||= 'username';

    bless { %$config }, $class;
}

sub find_user {
    my ($self, $authinfo, $c) = @_;
    my $htpasswd_user = $self->file->lookup_user($authinfo->{$self->user_field});
    $self->user_class->new( $self, $htpasswd_user );
}

sub user_supports {
    my $self = shift;

    # this can work as a class method, but in that case you can't have
    # a custom user class
    ref($self) ? $self->user_class->supports(@_)
        : Catalyst::Authentication::Store::Htpasswd::User->supports(@_);
}

sub from_session {
	my ( $self, $c, $id ) = @_;
	$self->find_user( { username => $id } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Authentication::Store::Htpasswd - Authen::Htpasswd based user storage/authentication

=head1 VERSION

version 1.006

=head1 SYNOPSIS

    use Catalyst qw/
      Authentication
    /;

    __PACKAGE__->config(
        authentication => {
            default_realm => 'test',
            realms => {
                test => {
                    credential => {
                        class          => 'Password',
                        password_field => 'password',
                        password_type  => 'self_check',
                    },
                    store => {
                        class => 'Htpasswd',
                        file => 'htpasswd',
                    },
                },
            },
        },
    );

    sub login : Global {
        my ( $self, $c ) = @_;

        $c->authenticate({ username => $c->req->param("login"), password => $c->req->param("password") });
    }

=head1 DESCRIPTION

This plugin uses L<Authen::Htpasswd> to let your application use C<< .htpasswd >>
files for it's authentication storage.

=head1 METHODS

=head2 new

Simple constructor, dies if the htpassword file can't be found

=head2 find_user

Looks up the user, and returns a Catalyst::Authentication::Store::Htpasswd::User object.

=head2 user_supports

Delegates to L<< Catalyst::Authentication::User->supports|Catalyst::Authentication::User/supports >> or an
override in L<user_class|/user_class>.

=head2 from_session

Delegates the user lookup to L<find_user|/find_user>

=head1 CONFIGURATION

=head2 file

The path to the htpasswd file. If the path starts with a slash, then it is assumed to be a fully
qualified path, otherwise the path is fed through C<< $c->path_to >> and so normalised to the
application root.

Alternatively, it is possible to pass in an L<Authen::Htpasswd> object here, and this will be
used as the htpasswd file.

=head2 user_class

Change the user class which this store returns. Defaults to L<Catalyst::Authentication::Store::Htpasswd::User>.
This can be used to add additional functionality to the user class by sub-classing it, but will not normally be
needed.

=head2 user_field

Change the field that the username is found in in the information passed into the call to C<< $c->authenticate() >>.

This defaults to I< username >, and generally you should be able to use the module as shown in the synopsis, however
if you need a different field name then this setting can change the default.

Example:

    __PACKAGE__->config( authentication => { realms => { test => {
                    store => {
                        class => 'Htpasswd',
                        user_field => 'email_address',
                    },
    }}});
    # Later in your code
    $c->authenticate({ email_address => $c->req->param("email"), password => $c->req->param("password") });

=head1 SEE ALSO

L<Authen::Htpasswd>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Authentication-Store-Htpasswd>
(or L<bug-Catalyst-Authentication-Store-Htpasswd@rt.cpan.org|mailto:bug-Catalyst-Authentication-Store-Htpasswd@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst>.

There is also an irc channel available for users of this distribution, at
L<C<#catalyst> on C<irc.perl.org>|irc://irc.perl.org/#catalyst>.

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTORS

=for stopwords David Kamholz Tomas Doran Karen Etheridge Tom Bloor Christopher Hoskin Ilmari Vacklin

=over 4

=item *

David Kamholz <dkamholz@cpan.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Tom Bloor <t.bloor@shadowcat.co.uk>

=item *

Christopher Hoskin <christopher.hoskin@gmail.com>

=item *

Ilmari Vacklin <ilmari.vacklin@cs.helsinki.fi>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2005 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
