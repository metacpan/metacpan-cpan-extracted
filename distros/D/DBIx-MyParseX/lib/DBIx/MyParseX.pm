package DBIx::MyParseX;
    our $VERSION = '0.06';

use 5.008008;
use strict;
use warnings;
use DBIx::MyParse;
use DBIx::MyParseX::Query;
use DBIx::MyParseX::Item;

use base 'DBIx::MyParse';

# Preloaded methods go here.

1;
__END__

=head1 NAME

DBIx::MyParseX - Extensions to DBIx::MyParse

=head1 SYNOPSIS

  use DBIx::MyParseX;

=head1 DESCRIPTION

This extension provides exteneded functionality to Philip Stoev's
very useful DBIx::MyParse module.  

See L<DBIx::MyParseX::Query> and L<DBIx::MyParseX::Item> for 
documentation on these extensions.


=head1 EXPORT

None by default.


=head1 SEE ALSO

L<DBIx::MyParse>

L<DBIx::MyParseX::Query> extensions to L<DBIx::MyParse::Query>

L<DBIx::MyParseX::Item> extensions to L<DBIx::MyParse::Item>

L<http://www.opendatagroup.com>


=head1 AUTHOR

Christopher Brown, E<lt>ctbrown@cpan.org<gt>


=head1 COPYRIGHT & LICENSE

Copyright 2008 by Open Data Group 

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public Licence.

=cut
