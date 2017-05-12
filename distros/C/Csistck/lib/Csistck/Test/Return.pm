package Csistck::Test::Return;

use 5.010;
use strict;
use warnings;

=head1 METHODS

=head2 new([desc => undef, msg => undef, repair => 0, resp => 0])

TODO document arguments

=cut

sub new {
    my $class = shift;

    bless {
        desc => "Unidentified test return",
        msg => undef,
        repair => 0,
        resp => 0,
        @_
    }, $class;
}

sub desc { shift->{desc}; }
sub msg { shift->{msg}; }
sub resp { shift->{resp}; }
sub ret { resp(@_); }
sub repair { shift->{repair}; }

# Some sugar functions
sub passed { (shift->resp != 0); }
sub failed { (shift->resp == 0); }

# Return if repair operation
sub is_repair { (shift->repair != 0); }
sub is_check { (shift->repair == 0); }

1;
