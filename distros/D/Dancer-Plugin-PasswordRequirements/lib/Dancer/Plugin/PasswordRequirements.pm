package Dancer::Plugin::PasswordRequirements;

use strict;

use Dancer ':syntax';
use Dancer::Plugin;
use Data::Password::Simple;

=head1 NAME

Dancer::Plugin::PasswordRequirements - Configurable password complexity testing

=head1 DESCRIPTION

This module provides a wrapper around Data::Password::Simple, and impliments its
functionality. 

When this plugin is in use D::P::Simple object is retained within
Dancer for improved performance, please be aware of the memory footprint
implications when using the dictionary check function with large dictionaries.

The development of this module is maintained at 
C<https://github.com/Abablabab/Dancer-Plugin-PasswordRequirements>

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Dancer::Plugin::PasswordRequirements;

The module is now ready to use, although not good for much.
Data::Password::Simple will use its default configuration for password
complexity (no dictionary checking, 6c minimum password length).

    get '/acceptable_password' => sub {
        return password_check(params->{word}) ? "yes" : "no";
    };

If we want to we can construct a new D::P::Simple object using a new set of
parameters. This will replace the existing object. 

    password_construct(
        length     => 6,
        dictionary => '/usr/share/dict/words',
    );

Or we can access the existing D::P::Simple object directly, and make use of existing
mutators and accessors.

    my $dps = password_dps_ref;
    $dps->length(8);

=cut

my $DPS;
sub INIT{
    $DPS = Data::Password::Simple->new();
}

=head1 EXPORTED KEYWORDS

=head2 password_construct 

Replaces the current internal Data::Password::Simple object with one constructed
with the given key => value list of parameters. 

See the documentation for Data::Password::Simple::new for more information.

=cut

register 'password_construct' => sub {

    $DPS = Data::Password::Simple->new( @_ );

};

=head2 password_check

A wrapper for D::P::Simple::check.

In scalar context returns true if the password passes the check, false
otherwise.

In list context returns a boolean result, and a hash containing details of
password check results. 

See the documentation for Data::Password::Simple::check for more information.

=cut

register 'password_check' => sub {

    return @$DPS->check(shift);

};

=head2 password_dps_ref

Returns the D::P::Simple object ref stored internally. 

B<Note> that D::P::Simple is not thread-safe. So modifications while being accessed
by other Dancer workers may have odd effects. 

=cut

register 'password_dps_ref' => sub {
    
    return $DPS;
    
};

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-dancer-plugin-passwordrequirements at rt.cpan.org>, 
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-PasswordRequirements>.
I will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::PasswordRequirements

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-PasswordRequirements>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-PasswordRequirements>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-PasswordRequirements>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-PasswordRequirements/>

=back

=head1 AUTHOR

    Ross Hayes
    CPAN ID: Abablabab
    ross@abablabab.co.uk
    http://metacpan.org/author/ABABLABAB

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Data::Password::Simple
Dancer
Dancer::Plugin

=cut

1;
