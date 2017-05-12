package Dancer::Plugin::Auth::Krb5;

our $VERSION = '0.02';

use 5.006;
use strict;
use warnings;

use Authen::Krb5::Simple;
use Dancer ':syntax';
use Dancer::Plugin;

register krb5_auth => sub {
    return Dancer::Plugin::Auth::Krb5->new(@_);
};

sub new {
    my $class = shift;
    my ($user, $pass) = @_;

    my $self = {
        user => '',
        errors => '',
    };
    bless $self, $class;

    my $settings = plugin_setting;

    if ($settings->{realm}){
        $self->{krb} = Authen::Krb5::Simple->new(realm => $settings->{realm});
    }else{
        $self->{errors} = "realm not configured";
        return $self;
    }

    if ($user && $pass){
        $self->{user} = $user;
        if ($self->{krb}->authenticate($user, $pass)){
            session 'user' => {name => $user};
        }else{
            $self->{errors} = $self->{krb}->errstr;
        }
    }else{
        $self->{errors} = "username and password are required";
    }

    return $self;
}

sub user {
    my $self = shift;
    return $self->{user};
}

sub errors {
    my $self = shift;
    return $self->{errors};
}

sub realm {
    my $self = shift;
    return exists $self->{krb} ? $self->{krb}->realm : '';
}

register_plugin;

=head1 NAME

Dancer::Plugin::Auth::Krb5 - kerberos authentication for Dancer web apps

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

    use Dancer::Plugin::Auth::Krb5;

    my $auth = krb5_auth($username, $password);
    if ($auth->errors){
        # auth failed
    }else{
        # auth success
    }

=head1 CONFIGURATION

    session: 'SessionEngine'
    plugins:
        Auth::Krb5:
            realm: 'REALM.DOMAIN.COM'

reference L<Dancer::Session> for 'SessionEngine'

=head1 METHODS

    use Dancer::Plugin::Auth::Krb5;

    my $auth = krb5_auth($username, $password);

=head2 user

    $auth->user;

return username

=cut

=head2 errors

    $auth->errors;

return error message

=cut

=head2 realm

    $auth->realm;

return realm

=cut

=head1 AUTHOR

Hypo Lin, C<< <hlin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-auth-krb5 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Auth-Krb5>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Auth::Krb5


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Auth-Krb5>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Auth-Krb5>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Auth-Krb5>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Auth-Krb5/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Hypo Lin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::Auth::Krb5
