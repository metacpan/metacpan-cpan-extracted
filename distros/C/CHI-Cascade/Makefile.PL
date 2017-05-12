use strict;
use warnings;

use inc::Module::Install;

name 'CHI-Cascade';
abstract 'A cache dependencies (principles of operation of make utility)';

author 'Perlover <perlover@perlover.com>';
version_from 'lib/CHI/Cascade.pm';
auto_set_repository;
license 'perl';
perl_version 5.010;

requires 'CHI';
requires 'Time::HiRes';
requires 'Scalar::Util';
requires 'parent';
requires 'Time::Duration::Parse';

build_requires 'Test::More';
build_requires 'Test::Base';
build_requires 'Storable';

clean_files 't/memcached*.pid t/memcached*.socket';

WriteAll();

package MY;

sub distdir {
    my $inherited = shift->SUPER::distdir(@_);
    $inherited =~ s/^(create_distdir\s.*)/$& README/m;
    $inherited .= "README : lib/CHI/Cascade.pm\n\tperldoc -t lib/CHI/Cascade.pm > README\n";
    return $inherited;
}
