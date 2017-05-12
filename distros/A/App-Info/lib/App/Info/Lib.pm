package App::Info::Lib;

use strict;
use App::Info;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info);
$VERSION = '0.57';

1;
__END__

=head1 NAME

App::Info::Lib - Information about software libraries on a system

=head1 DESCRIPTION

This class is an abstract base class for App::Info subclasses that provide
information about specific software libraries. Its subclasses are required to
implement its interface. See L<App::Info|App::Info> for a complete
description, and L<App::Info::Lib::Iconv|App::Info::Lib::Iconv> for an example
implementation.

=head1 INTERFACE

Currently, App::Info::Lib adds no more methods than those from its parent
class, App::Info.

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/app-info/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/app-info/issues/> or by sending mail to
L<bug-App-Info@rt.cpan.org|mailto:bug-App-Info@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::Lib::Iconv|App::Info::Lib::Iconv>,
L<App::Info::Lib::Expat|App::Info::Lib::Expat>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

