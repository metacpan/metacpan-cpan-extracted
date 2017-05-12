#!perl -w

use Test::More tests => 5;

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'Mapper.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 158 /Users/dan/work/dan/Class-DBI-DataMigration/lib/Class/DBI/DataMigration/Mapper.pm

use_ok('Class::DBI::DataMigration::Mapper');
can_ok('Class::DBI::DataMigration::Mapper', 'map');
can_ok('Class::DBI::DataMigration::Mapper', 'mappings');
can_ok('Class::DBI::DataMigration::Mapper', 'target_keys');
can_ok('Class::DBI::DataMigration::Mapper', 'target_cdbi_class');


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

