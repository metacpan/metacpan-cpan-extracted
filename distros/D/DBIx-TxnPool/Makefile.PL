use strict;
use warnings;

use inc::Module::Install;

name 'DBIx-TxnPool';
abstract 'Massive SQL updates by means of transactions with the deadlock & signal solution';

author 'Perlover <perlover@perlover.com>';
license 'perl';
version_from 'lib/DBIx/TxnPool.pm';

requires 'Try::Tiny';
requires 'Signal::Mask';
requires 'Carp';
requires 'Exporter'      => 5.57;
requires 'DBI';
requires 'DBD::mysql';

auto_set_repository;
author_tests('xt');

# makemaker_args(
#     PREREQ_FATAL => 1
# );

WriteAll();

package MY;

sub distdir {
    my $inherited = shift->SUPER::distdir(@_);
    $inherited =~ s/^(create_distdir\s.*)/$& README/m;
    $inherited .= "README : lib/DBIx/TxnPool.pm\n\tperldoc -t lib/DBIx/TxnPool.pm > README\n";
    return $inherited;
}
