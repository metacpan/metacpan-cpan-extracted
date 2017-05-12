package Bundle::WING;

$Bundle::WING::VERSION = '0.11';

1;

=head1 NAME

Bundle::WING - Modules required for the Web IMAP and News Gateway

=head1 DESCRIPTION

WING is an Open Source Apache/mod_perl based system which allows users
to access email held on an IMAP server via any web browser.

WING provides a gateway so that users can access email held on an
IMAP server via any web browser.

This bundle provides all the modules you need except for the two modules
which Malcolm Beattie wrote but did not release to CPAN. One of these
modules will stop being a dependency soon. We're working on it. However,
in the meantime, you can download them from our sourceforge site.

Note that Mail::Cclient and DBD::Pg require configuration, so won't 
automatically install.

=head1 CONTENTS

DBD::Pg

DBI

Data::Dumper

Net::Telnet

Apache::DBI

MD5

MIME::Base64

Term::ReadKey

HTML::Parser

Term::ReadLine::Perl

Bundle::libnet

IO::AtomicFile

Mail::Cclient

Bundle::LWP

Mail::Address

MIME::Parser

Net::DNS

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<WING>, http://web-imap.sourceforge.net/

=cut
