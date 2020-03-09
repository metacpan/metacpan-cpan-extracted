package Data::Tersify::perldb;

use strict;
use warnings;

use Data::Tersify;

=head1 NAME

Data::Tersify::perldb - override the standard perl debugger's behaviour

=head1 SYNOPSIS

 # In your .perldb file
 use Data::Tersify::perldb;

 # The x command now automatically passes data through
 # Data::Tersify::tersify

=head1 DESCRIPTION

This is a very simple convenience module that implements a DB::afterinit
method that patches the x command so it effectively means
C<x Data::Tersify::tersify(...)> instead. Import it from your .perldb
file to have the output of x tersified automatically.

If you already have a DB::afterinit method, or would prefer other things
to be tersified, just cut and paste the appropriate code.

Many thanks to Ovid, whose
L<.perldb file|https://gist.github.com/Ovid/919234335d7fc27fca3ec63e6f3782ce>
was an inspiration and a useful guide.

=cut

sub DB::afterinit {
    $DB::alias{x} = 's/^ x \s (.+) /x Data::Tersify::tersify_many($1)/x';
}

1;
