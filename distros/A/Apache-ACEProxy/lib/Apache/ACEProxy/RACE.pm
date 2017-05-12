package Apache::ACEProxy::RACE;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use base qw(Apache::ACEProxy::UTF8_RACE); # backward compatibility

1;
__END__

=head1 NAME

Apache::ACEProxy::RACE - IDN compatible RACE proxy server

=head1 SYNOPSIS

This module is B<deprecated>. Use Apache::ACEProxy::UTF8_RACE instead.

=head1 DESCRIPTION

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module comes with NO WARANTY.

=head1 SEE ALSO

L<Apache::ACEProxy::UTF8_RACE>

=cut
