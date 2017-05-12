package Bundle::SQL::Translator;

# ----------------------------------------------------------------------
# $Id$ 
# ----------------------------------------------------------------------
# Bundle::SQL::Translator - a Bundle for SQL::Translator
# Copyright (C) 2003 darren chamberlain <darren@cpan.org>
# ----------------------------------------------------------------------

use strict;
use vars qw($VERSION $REVISION);

$VERSION = "1.00";
$REVISION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;


1;
__END__

=head1 NAME

Bundle::SQL::Translator - a Bundle for SQL::Translator

=head1 SYNOPSIS

    perl -MCPAN -e install Bundle::SQL::Translator

=head1 DESCRIPTION

C<Bundle::SQL::Translator> provides a bundle to install all C<SQL::Translator>
prerequisites.  Note that installing this bundle requires the C<gd> library
from L<http://www.boutell.com/gd/|http://www.boutell.com/gd/>.

=head1 CONTENTS

Class::Base

File::Basename

File::Spec

GD

GraphViz

IO::Dir

IO::File

IO::Scalar

Parse::RecDescent   1.94

Pod::Usage

Spreadsheet::ParseExcel

Template    2.10

Test::More

Test::Exception

Text::ParseWords

Text::RecordParser  0.02

XML::Writer

XML::XPath  1.13

=head1 SUPPORT

C<Bundle::SQL::Translator> is supported by the author.

=head1 VERSION

This is C<Bundle::SQL::Translator>, revision $Revision$.

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2003 darren chamberlain

This library is free software; you may distribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Perl>, L<SQL::Translator>
