package Bundle::MusicBrainz::Server;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::MusicBrainz::Server - Bundled dependancies to run a MusicBrainz Server.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::MusicBrainz::Server'>

=head1 CONTENTS

Bundle::Apache

DBI

Apache::Session::File

Storable

HTML::Mason

String::CRC32

String::Similarity

Unicode::String

XML::DOM

XML::Parser

XML::XQL

XML::XQL::DOM

RDFStore

Digest::SHA1

UUID
 
URI::Escape

Tie::STDERR

=head1 DESCRIPTION

Also need the following but it requires human intervention:

Text::Unaccent	- at least version 1.05: http://www.senga.org/download/unac/Text-Unaccent-1.05.tar.gz

DBD::Pg requires by hand config

=head1 AUTHOR

Jay Jacobs
jayj@cpan.org

=cut
