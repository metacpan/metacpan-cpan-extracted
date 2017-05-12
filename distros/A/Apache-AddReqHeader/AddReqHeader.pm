package Apache::AddReqHeader;

use strict;
use Apache::Constants qw(:common);
use Apache::Request;

use vars qw($VERSION);
$VERSION = '0.01';

sub handler {
    my $r = Apache::Request->instance(shift);
    my %param = split(/\s*(?:=>|,)\s*/, $r->dir_config('AddReqHeaderParam'));
    $r->header_in($param{$_} => $r->param($_)) for (keys %param);
    return OK;
}

1;
__END__

=head1 NAME

Apache::AddReqHeader - Add the value of form parameter to HTTP Request Header

=head1 SYNOPSIS

  # in httpd.conf
  PerlSetVar AddReqHeaderParam uid=>X-UID,sid=>X-Session-Id
  PerlInitHandler Apache::AddReqHeader

=head1 DESCRIPTION

Apache::AddReqHeader sets the value of form parameter to HTTP Request Header.
Please set up the form parameter name and the name at the time of adding
to HTTP Request Header in hash style using PerlSetVar directive.

=head1 CAUTION

Apache::Request object twice within the same request -
the symptoms being that the second Apache::Request
object will not contain the form parameters because
they have already been read and parsed.
Since -- Phase after this It is necessary to use Apache::Request->instance().

=head1 AUTHOR

Satoshi Tanimoto E<lt>tanimoto@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache>, L<Apache::Request>

=cut
