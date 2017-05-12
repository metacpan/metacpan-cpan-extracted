package Business::PayPal::EWP;

use 5.006001;
use strict;
use warnings;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw(SignAndEncrypt) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION='1.03';
our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Business::PayPal::EWP', $VERSION);

sub SignAndEncrypt {
    my $formdata=shift;
    my $key=shift;
    my $cert=shift;
    my $ppcert=shift;

    # Reformat
    #$formdata=~s/,/\n/g;

    # Encrypt and sign
    my $retval = Business::PayPal::EWP::SignAndEncryptCImpl($formdata,$key,$cert,$ppcert,0);

    return $retval;
}

1;

__END__

=head1 NAME

Business::PayPal::EWP - Perl extension for PayPal's Encrypted Website Payments

=head1 SYNOPSIS

  use Business::PayPal::EWP qw(SignAndEncrypt);
  ...
  my $form=<<EOS;
  cert_id=123ABC
  cmd=_xclick
  business=...
  EOS

  my $cert="/path/to/mycert.crt";
  my $key="/path/to/mycert.key";
  my $ppcert="/path/to/paypalcert.pem";

  my $encrypted=SignAndEncrypt($form,$key,$cert,$ppcert);

  print <<EOF;

  <form action="https://www.paypal.com/cgi-bin/webscr" method="post">
  <input type="hidden" name="cmd" value="_s-xclick" />
  <input type="image" src="https://www.paypal.com/en_US/i/btn/x-click-but23.gif"
  border="0" name="submit" alt="Make payments with PayPal - it's fast, free and
  secure!" /><input type="hidden" name="encrypted" value="$encrypted" /></form>

  EOF

=head1 DESCRIPTION

This module wraps the sample C++/C# code which PayPal provides for working with
Encrypted Web Payments.  It contains a single function, SignAndEncrypt which takes
the plaintext form code, private key file, public key file, and PayPal's public
certificate, and will return the signed and encrypted code needed by paypal.

=head1 AUTHOR AND COPYRIGHT

  Copyright (c) 2004, 2005 Issac Goldstand E<lt>margol@beamartyr.netE<gt> - All rights reserved.
  Copyright (c) 2009 Thomas Busch (current maintainer)

This library includes code copied from PayPal's sample code.  More information
about those projects' authors can be found at the respective project websites.

This library is free software. It can be redistributed and/or modified
under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::SSLeay>, L<CGI>, L<Business::PayPal>

Also, see PayPal's documentation at http://www.paypal.com/cgi-bin/webscr?cmd=p/xcl/rec/ewp-intro-outside

=cut


