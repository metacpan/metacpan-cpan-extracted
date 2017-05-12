package Unprepared;
our $VERSION = '1.100840';

# this package doesn't define a prepare_comparable
sub new { bless { value => 123 }, shift }
1;
