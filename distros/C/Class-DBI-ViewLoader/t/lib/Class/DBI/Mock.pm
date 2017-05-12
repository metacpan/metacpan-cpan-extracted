package Class::DBI::Mock;

use strict;
use warnings;

use base qw( Class::DBI );

use DBD::Mock;

# provide dummy data conforming to Class::DBI::ViewLoader::Mock's test_view
# view.
our @data = (
	{ # This row should evaluate as true
	    foo => 1,
	    bar => 1,
	    baz => 1,
	},
	{ # As should this
	    foo => 1,
	    bar => undef,
	    baz => 1,
	},
	{ # This one should be false
	    foo => undef,
	    bar => undef,
	    baz => undef
	}
    );

sub retrieve_all {
    my $class = shift;
    my $data = [ @data ];

    return $class->_my_iterator->new($class, $data);
}

1;

__END__
