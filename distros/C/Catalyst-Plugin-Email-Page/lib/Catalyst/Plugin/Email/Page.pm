package Catalyst::Plugin::Email::Page;

use warnings;
use strict;
use Catalyst::Request;
use Readonly;
use URI::Escape qw( uri_escape_utf8 );

our $VERSION = '0.26';

Readonly my $address => q{webmaster@example.com};
Readonly my $subject => q{User Report for};
Readonly my $text    => q{Report Page};

sub _construct_url {
    my $c = shift;
    my $page            = $c->request->uri;
    my $email_add       = $c->config->{email_page}{email} || $address;
    my $email_subject   = $c->config->{email_page}{subject} || $subject;
  
    # Only mailto subject needs to be escaped
    my $mailto_subject  = uri_escape_utf8( "$email_subject $page" );
    
    return "mailto:$email_add?subject=$mailto_subject";
}

sub email_page_url {
    my $c = shift;
    my $link       = $c->_construct_url;
    my $link_text  = $c->config->{email_page}{link_text} || $text;
    my $email_link = "<a href=\"$link\">$link_text</a>";
    
    return $email_link;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Catalyst::Plugin::Email::Page - Email your Catalyst page

=head1 VERSION

This document describes Catalyst::Plugin::Email::Page version 0.26


=head1 SYNOPSIS

    use Catalyst::Plugin::Email::Page;

    __PACKAGE__->config->{email_page}{
                   email     = q{webmaster@example.com},
                   subject   = q{User Report for},
                   link_text = q{Report Page},
                };

    # In your Template
    [% c.email_page_url %] 

=head1 DESCRIPTION

This is a simple plugin that lets a developer set and forget e-mail links in Catalyst

=head1 INTERFACE 

=head2 email_page_url

Returns a link in the form of:
mailto:webmaster@example.com?subject=User Report for http://yours.com/ 

The mailto subject is escaped using C<< uri_escape_utf8 >> from
L<URI::Escape> and http://yours.com/ is the current pages uri

=head2 email_page_body

Allows you to e-mail the whole page to someone once you have the right
template. Used the same way as C<< email_page_url >>

To do.

=head2 email_page_anchor

Allows you to e-mail a page anchor. Used the same way as C<< email_page_url >>

To do.

=head2 _construct_url

Internal routine.

Reads in the various configuration settings and constructs the mailto
link. See L<CONFIGURATION AND ENVIRONMENT>

=head1 DIAGNOSTICS

=head2 C<< Can't locate Readonly.pm in @INC (@INC contains: >>

L<Readonly> is required

Install it via the usual ways:

    cpan Readonly
    perl -MCPAN -e shell

=head2 C<< Can't locate URI/Escape.pm in @INC (@INC contains: >>

L<URI::Escape> is required. See above for standard way to install

=head1 CONFIGURATION AND ENVIRONMENT

Catalyst::Plugin::Email::Page requires no configuration files or environment
variables, but you'd best change the C<< mailto >> address.

=head2 Configuring with YAML

Set Configuration to be loaded via Config.yml in YourApp.pm

    use YAML qw(LoadFile);
    use Path::Class 'file';

    __PACKAGE__->config(
        LoadFile(
            file(__PACKAGE__->config->{home}, 'Config.yml')
        )
    );

Settings in Config.yml

    # Email::Page
    email_page:
      email: support@example.com
      subject: Error Report for
      link_text: Report Me

=head1 DEPENDENCIES

L<Readonly>, L<URI::Escape> and of course L<Catalyst>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Initial Bug ID 17248, as reported by CPAN ID DAKKAR

Fixed in version 0.25, which now escapes the mailto subject,
hence the L<URI::Escape> requirement.

Thanks DAKKAR.

Please report any bugs or feature requests to
C<bug-catalyst-plugin-email-page@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 TO DO

Add more methods.

Finish empty ones and add settings for using images instead of link text.

More Tests!

=head1 AUTHOR

Gavin Henry  C<< <ghenry@suretecsystems.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Gavin Henry C<< <ghenry@suretecsystems.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
