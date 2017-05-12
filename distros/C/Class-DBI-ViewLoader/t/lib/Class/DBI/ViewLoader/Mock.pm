package Class::DBI::ViewLoader::Mock;

use strict;
use warnings;

our @ISA = qw( Class::DBI::ViewLoader );

require Class::DBI::Mock;

sub base_class {
    'Class::DBI::Mock';
}

our %db = (
	test_view => [qw(
	    foo
	    bar
	    baz
	)],
	view_two => [qw(
	    blah
	    bleh
	    bluh
	)],
    );

sub get_views { sort keys %db }

sub get_view_cols { @{$db{$_[1]}} }

1;

__END__
