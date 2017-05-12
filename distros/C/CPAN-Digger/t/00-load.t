use strict;
use warnings;

use Test::More;

plan tests => 1;

use CPAN::Digger;
use CPAN::Digger::Index;

my $d = CPAN::Digger->new;
isa_ok( $d, 'CPAN::Digger' );

# Test cases for unzip and process files:

# Exception:
# Wide character in subroutine entry at /home/gabor/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/MongoDB/Collection.pm line 379.


# fail in the unzip

# open in the current directory and not in a subdirectory (e.g.
#         cpan/authors/id/J/JW/JWIEGLEY/Pilot-0.4.tar.gz )

# could not sanitize file name:
# Easy WML 0.1
# from cpan/authors/id/C/CA/CARTER/Easy-WML-0.1.tar.gz


# tar: Log-WithCallbacks-1.00/lib/Log: Cannot mkdir: Permission denied
# mv: cannot open `WWW-Search-NCBI-PubMed-0.01/lib/WWW/Search/NCBI/PubMed/article_to_html.xslt' for reading: Permission denied
# mv: cannot stat `Math-Modular-SquareRoot-1.001/Build.PL': Permission denied
# Can't chdir('Math-Modular-SquareRoot-1.001'): Permission denied

# tar: File-Storage-Stat-0.02/t/testfile: implausibly old time stamp 1970-01-01 02:00:00

# tar: Ignoring unknown extended header keyword `MPE.RECORDSIZE'
# tar: Ignoring unknown extended header keyword `MPE.FILECODE'
# tar: Ignoring unknown extended header keyword `MPE.FILELIMIT'

# cpan/authors/id/C/CM/CMORRIS/Parse-Extract-Net-MAC48-0.01.tar.gz
# has symlinks in the t/ directory
#
# as an additional directory inside:
# Deep-Hash-Utils-0.01

# tar: Removing leading `Array-Sort-0.02/..' from member names
# mv: cannot stat `Math-Disarrange-List-1.004/Build.PL': Permission denied

# mv: cannot stat `Opener': No such file or directory
# mv: cannot stat `chat': No such file or directory
# mv: cannot stat `0.7': No such file or directory
