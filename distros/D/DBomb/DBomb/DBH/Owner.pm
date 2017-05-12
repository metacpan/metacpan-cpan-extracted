package DBomb::DBH::Owner;

=head1 NAME

DBomb::DBH::Owner - A class that has $dbh data.

=cut

## Note: Decide carefully when to use __PACKAGE__ and when to use $class.

use strict;
use warnings;
use Carp::Assert;
use base qw(Class::Data::Inheritable);
our $VERSION = '$Revision: 1.3 $';


## Grabs from the writer pool. For code that doesn't know what it needs.
__PACKAGE__->mk_classdata('dbh');

__PACKAGE__->mk_classdata('_dbh_reader_pool');
__PACKAGE__->mk_classdata('_dbh_writer_pool');


## TODO

## accessor wrapper around the pool.
sub dbh_reader {
    die "Not implemented";
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $pool;

    if (@_){
    }

}

sub dbh_writer {
    die "Not implemented";
}


1;
__END__
