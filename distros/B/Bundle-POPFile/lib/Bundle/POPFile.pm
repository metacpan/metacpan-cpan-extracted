package Bundle::POPFile;

$VERSION = '1.02';



1;
__END__

=head1 NAME

Bundle::POPFile - The modules needed by POPFile in one clean bundle

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::POPFile'>

=head1 DESCRIPTION

This bundle will give you all the module dependencies of POPFile L<http://getpopfile.org/>
with a single cpan install command. Please note that no modules for the database
backend are included, except L<DBI>.

=head1 CONTENTS

BerkeleyDB

DBI

Date::Format

Date::Parse

Digest::MD5

Encode

Encode::Guess

File::Copy

File::Find

File::Path

Getopt::Long

HTML::Tagset

HTML::Template

IO::Handle

IO::Select

IO::Socket

IO::Socket::SSL

IO::Socket::Socks

MIME::Base64

MIME::QuotedPrint

Sys::Hostname

Text::Kakasi

XMLRPC::Transport::HTTP



=head1 AUTHOR

Manni Heumann, E<lt>pfbundle AT lxxi.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Manni Heumann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
