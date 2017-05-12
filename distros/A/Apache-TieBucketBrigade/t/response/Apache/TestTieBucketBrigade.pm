package Apache::TestTieBucketBrigade;

use 5.006001;

use strict;
use warnings FATAL => 'all';

use Apache::Connection ();
use APR::Bucket ();
use APR::Brigade ();
use APR::Util ();
use Apache::Const -compile => qw(OK);
use Apache::TieBucketBrigade;

our $VERSION = '0.02';

sub handler {
    my $c = shift;
    my $FH = Apache::TieBucketBrigade->new_tie($c);
    my @stuff = <$FH>;
    print $FH uc( join '', @stuff );
    Apache::OK;
}

1;
__END__

=pod

=head1 NAME

Apache::TestTieBucketBrigade - Tests Apache::TieBucketBrigade takes a bunch of
stuff in then writes it back upcased

=head1 SYNOPSIS

unh - read the code

=head1 DESCRIPTION

It tests stuff.  I suppose you could use it as an example of building things
with Apache::TieBucketBrigade.  This would be cooler if I actually new how
to test mod_perl protocol handlers.  For now, put something like the following
in httpd.conf

Listen localhost:8013

<VirtualHost localhost:8013>

      PerlModule                   Apache::TestTieBucketBrigade
      PerlProcessConnectionHandler Apache::TestTieBucketBrigade

</VirtualHost>

restart apache and hope for the best.  Telnet to locahost:8013 type some stuff
in and see if it comes back upcased.

=head2 EXPORT

None


=head1 SEE ALSO

Apache::TieBucketBrigade
IO::Stringy
mod_perl
IO::Handle

=head1 AUTHOR

mock E<lt>mock@obscurity.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Will Whittaker and Ken Simpson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
