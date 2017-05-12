package Apache::Usertrack;
use strict;
use Apache::Constants;
use Time::HiRes;
use integer;

$Apache::Usertrack::revision = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/o);
$Apache::Usertrack::VERSION = '0.03';

sub make_cookie {
  my $r = shift;
  my $remotename = $r->connection->remote_host || $r->connection->remote_ip;
  my ($secs, $msecs) = Time::HiRes::gettimeofday;
  $msecs /= 1000;
  my $cookie = "Apache=$remotename.$$"."$secs$msecs; path=/";
  $r->notes("cookie", $cookie);
  $r->err_headers_out->add("Set-Cookie" => $cookie);
  return OK;
}
 
sub handler {
  my $r = shift;
  return DECLINED unless ($r->dir_config('Usertrack'));
  if (my $cookies = $r->header_in("Cookie")) {
	if (my $cookie = ($cookies =~ m/Apache=([^\s;]+)/)[0]) {
	  $r->notes("cookie", $cookie);
	  return DECLINED;  # Theres already a cookie, no new one
	}
  }
  return make_cookie($r);
}

1;

__END__

=head1 NAME

Apache::Usertrack - Emulate the mod_usertrack apache module

=head1 SYNOPSIS

  PerlFixupHandler Apache::Usertrack

  PerlSetVar Usertrack On

=head1 PREREQUISITES

This module uses the Time::HiRes module.

=head1 DESCRIPTION

To be written. :-)

=head1 BUGS / TODO

We don't do expire stuff yet.

Documentation.

Support for systems without gettimeofday.

Patches are most welcome! :-)  See mod_usertrack.c in the
<apachedist>/src/modules/standard/ directory for 'the original'
it's quite simpel C code!

=head1 AUTHOR

Copyright (C) 1998, Ask Bjoern Hansen <ask@netcetera.dk>. All rights
reserved. This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), mod_perl(3)

=cut









