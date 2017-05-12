package Apache::RSS::Encoding;
# $Id: Encoding.pm,v 1.3 2002/05/30 14:05:15 ikechin Exp $
#
# IKEBE Tomohiro <ikebe@edge.co.jp>
# Livin' On The EDGE, Limited.
# Time-stamp: <2002-05-30 22:25:45 miyagawa>

use strict;
require Carp;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self;
}

sub encode {
    Carp::croak("ABSTRACT METHOD!!");
}

1;

__END__

=head1 NAME 

Apache::RSS::Encoding - ABSTRACT CLASS.

=head1 SYNOPSIS

  RSSScanHTMLTitle On
  RSSEncodeHandler Apache::RSS::Encoding::JcodeUTF8

=head1 DESCRIPTION

RSS codeset conversion Handler.

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::RSS::Encoding::JcodeUTF8>

=cut
