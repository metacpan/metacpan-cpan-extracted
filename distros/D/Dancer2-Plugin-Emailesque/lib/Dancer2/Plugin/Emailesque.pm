package Dancer2::Plugin::Emailesque;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Dancer2::Plugin;
use Emailesque ('!email');

=head1 NAME

Dancer2::Plugin::Emailesque - Simple Emailesque support for Dancer2

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Configure your global mailer settings in your config file:

  plugins:
    Emailesque:
      from: me@gmail.com
      # for gmail...
      ssl: 1
      driver: smtp
      host: smtp.googlemail.com
      port: 465
      user: account@gmail.com
      pass: TheMightyPass

In your module

    use Dancer2::Plugin::Emailesque;

And when you need to mail someone:

    email { to => $email_recipient,
            subject => "Your daily mail",
            message => "The mail contents" };

For further configuration or email construction check Emailesque
documentation.

=cut

my $emailesque;

sub _create_emailesque {
    my $settings = plugin_setting;
    $emailesque = Emailesque->new( $settings );
}

on_plugin_import {
    _create_emailesque unless $emailesque;
};

register email => sub {
    my $dsl = shift;
    my $options = shift || {};

    _create_emailesque unless $emailesque;

    $emailesque->send($options);
};

register_plugin;

=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 BUGS

To report any bugs or feature requests access https://github.com/ambs/Dancer2-Plugin-Emailesque

=head1 ACKNOWLEDGEMENTS

IronCamel for the first Dancer::Plugin::Email module, AlNewKirk for Emailesque.

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dancer2::Plugin::Emailesque
