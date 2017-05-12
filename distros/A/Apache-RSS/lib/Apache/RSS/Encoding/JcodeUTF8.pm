package Apache::RSS::Encoding::JcodeUTF8;
# $Id: JcodeUTF8.pm,v 1.3 2002/05/30 14:05:15 ikechin Exp $
#
# IKEBE Tomohiro <ikebe@edge.co.jp>
# Livin' On The EDGE, Limited.
# Time-stamp: <2002-05-30 22:20:38 miyagawa>

use strict;
use Jcode;
use base qw(Apache::RSS::Encoding);

sub encode {
    my($self, $str) = @_;
    return Jcode->new(\$str)->utf8;
}

1;

__END__

=head1 NAME 

Apache::RSS::Encoding::JcodeUTF8 - encode Japanese <title>..</title> string to utf8.

=head1 SYNOPSIS

  RSSScanHTMLTitle On
  RSSEncodeHandler Apache::RSS::Encoding::JcodeUTF8

=head1 DESCRIPTION

Apache::RSS HTML encoding Handler.
encode Japanese charset to UTF-8. using L<Jcode>.

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Jcode>

=cut

