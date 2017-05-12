package Apache::AxKit::Provider::RDBMS::DBCacheAdapter;

use Carp;

sub new {
    my $class = shift;

    my $self = { apache => shift };

    return bless $self, $class;
}

sub mtime {
    carp "You have to implement this method by the subclass";
}

1;
