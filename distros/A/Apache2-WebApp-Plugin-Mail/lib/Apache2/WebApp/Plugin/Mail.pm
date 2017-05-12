#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::Mail - Plugin providing mail delivery methods
#
#  DESCRIPTION
#  Methods for sending template based multi-format e-mail.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::Mail;

use strict;
use base 'Apache2::WebApp::Plugin';
use MIME::Lite::TT;
use MIME::Lite::TT::HTML;
use Params::Validate qw( :all );

our $VERSION = 0.09;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# send_text( \%controller, \%data )
#
# Send a template based (text) message.

sub send_text {
    my ( $self, $c, $data_ref )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF },
          { type => HASHREF }
          );

    my $msg = MIME::Lite::TT->new(
        From        => $data_ref->{from} || $c->config->{project_email},
        To          => $data_ref->{to},
        Subject     => $data_ref->{subject},
        Template    => $data_ref->{template}->{file},
        TmplParams  => $data_ref->{template}->{vars},
        TmplOptions => {
            INCLUDE_PATH => $c->config->{template_include_path}
        },
      );

    $msg->send();
}

#----------------------------------------------------------------------------+
# send_html( \%controller, \%data )
#
# Send a template based (HTML/Text) multi-formatted message.

sub send_html {
    my ( $self, $c, $data_ref )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF },
          { type => HASHREF }
          );

    my $msg = MIME::Lite::TT::HTML->new(
        From        => $data_ref->{from} || $c->config->{project_email},
        To          => $data_ref->{to},
        Subject     => $data_ref->{subject},
        Encoding    => 'quoted-printable',
        Charset     => 'utf8',
        Template    => {
            html => $data_ref->{template}->{file}->{html},
            text => $data_ref->{template}->{file}->{txt},
        },
        TmplParams  => $data_ref->{template}->{vars},
        TmplOptions => {
            INCLUDE_PATH => $c->config->{template_include_path}
        },
      );

    $msg->send;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# _init(\%params)
#
# Return a reference of $self to the caller.

sub _init {
    my ( $self, $params ) = @_;
    return $self;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Plugin::Mail - Plugin providing mail delivery methods

=head1 SYNOPSIS

  my $obj = $c->plugin('Mail')->method( ... );     # Apache2::WebApp::Plugin::Mail->method()

    or

  $c->plugin('Mail')->method( ... );

=head1 DESCRIPTION

Methods for sending template based multi-format e-mail.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  MIME::Lite
  MIME::Lite::TT
  MIME::Lite::TT::HTML
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-Mail-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::Mail'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::Mail
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 OBJECT METHODS

=head2 send_text

Send a template based (text) message.

  $c->plugin('Mail')->send_text( $c,
      {
          from     => 'this@domain.com',
          to       => 'that@domain.com',
          subject  => 'RE: Your subject',
          template => {
              file => 'msg_body_text.eml',
              vars => \%tt_hash,
          }
      }
    );

=head2 send_html

Send a template based (HTML/Text) multi-formatted message.

  $c->plugin('Mail')->send_html( $c, 
      {         
          from     => 'this@domain.com',
          to       => 'that@domain.com,
          subject  => 'RE: Your subject',
          template => {
              file => { 
                  html => 'msg_body_html.eml',
                  txt  => 'msg_body_text.eml',
              },        
              vars => \%tt_hash,
          }         
      }         
    );

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<MIME::Lite>, L<MIME::Lite::TT>,
L<MIME::Lite::TT::HTML>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
