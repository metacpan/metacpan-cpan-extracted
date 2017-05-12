# -*- perl -*-

#
# $Rev$
#

use strict;

my $script = <<'SCRIPT';
~startperl~ -w

use strict;

use DBI::Shell;
my $sh = DBI::Shell->new(@ARGV)->run;
exit(0);

__END__

=head1 NAME

dbish	- Interactive command shell for the Perl DBI

=head1 SYNOPSIS

  dbish <options> dsn [user [password]]

=head1 DESCRIPTION

This tool is a command wrapper for the DBI::Shell perl module.
See L<DBI::Shell(3)> for full details.

=head1 SEE ALSO

L<DBI::Shell(3)>, L<DBI(3)>

=cut
SCRIPT

use Config;

my $file = __FILE__; $file =~ s/\.PL$//;

$script =~ s/\~(\w+)\~/$Config{$1}/eg;
if (!(open(FILE, ">$file"))  ||
    !(print FILE $script)  ||
    !(close(FILE))) {
    die "Error while writing $file: $!\n";
}
print "Extracted $file from ",__FILE__," with variable substitutions.\n";

# end
#
# $Log: dbish.PL,v $
# Revision 11.91  2002/12/13 23:44:56  tlowery
# Fixed version numbers
#
# Revision 11.6  2002/10/28 02:49:57  tlowery
# Release 11.6
#
# Revision 11.5  2002/04/17 15:03:16  tlowery
# Added the begining of column_info support.
#
# Revision 11.4  2002/04/09 10:52:12  tlowery
# Continued to improve support for formatting.  Added more tests.
#
# Revision 11.3  2002/01/02 03:14:59  tlowery
# Modified to include new formats.
#
# Changed displaymode to format.
#
# Cleaned up a number of "undefined" messages.
#
# Revision 11.2  2001/10/29 15:56:00  tlowery
# Added timing tests.
# Added go with empty buffer gets the last command and executes.
# Added support for negative numbers with get.
# Fixed undef warnings from histories.
#
# Revision 1.3  2001/04/06 09:32:22  tlowery
#
# Added CVS tags.
#
#
