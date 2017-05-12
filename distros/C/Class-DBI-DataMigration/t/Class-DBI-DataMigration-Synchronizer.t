#!perl -w

use Test::More tests => 4;

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

my $Original_File = 'Synchronizer.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 21 /Users/dan/work/dan/Class-DBI-DataMigration/lib/Class/DBI/DataMigration/Synchronizer.pm
use_ok('Class::DBI::DataMigration::Synchronizer');

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 72 /Users/dan/work/dan/Class-DBI-DataMigration/lib/Class/DBI/DataMigration/Synchronizer.pm
can_ok('Class::DBI::DataMigration::Synchronizer', 'search_criteria');

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 109 /Users/dan/work/dan/Class-DBI-DataMigration/lib/Class/DBI/DataMigration/Synchronizer.pm

push @ARGV, '--table=class1,key1,value1,key2,value2',
'--table=class2,key3,value3', '--table=class3';

ok(Class::DBI::DataMigration::Synchronizer->_initialize);

my $synch = Class::DBI::DataMigration::Synchronizer->new;
is_deeply($synch->search_criteria, 
{
    class1 => {
        key1 => 'value1',
        key2 => 'value2'
    },

    class2 => {
        key3 => 'value3'
    },

    class3 => {}
 }
);


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

