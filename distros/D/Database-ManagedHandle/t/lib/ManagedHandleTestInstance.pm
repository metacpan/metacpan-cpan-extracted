package ManagedHandleTestInstance;
use strict;
use warnings;
use Database::ManagedHandle;

sub new {
    my ($class) = @_;
    return bless { mh => Database::ManagedHandle->instance() }, $class;
}
1;
