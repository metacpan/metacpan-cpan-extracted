package Cac::Global;

use 5.006;
use strict;
use warnings;
use bytes;
  
use XSLoader;
XSLoader::load Cac unless $Cac::xs_loaded++; # this is in cacperl.xs :)

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT_OK = ( );
our @EXPORT = qw( &Gset &Ginc &GsetA &GincA &GsetH &GincH &Gseq
                  &Gget &GgetRaise);
our $VERSION = 1.83;

=head1 NAME

Cac::Global - High-performance access to Cache global variables

=head1 SYNOPSIS

use Cac::Global

=head1 Global Access Functions

=over 4

=item Gset $global, [$idx1, $idx2, ... ,] $value

Sets a global in the most efficient way.

Example:

 Gset "xx", 1, "foo", 2; # s ^xx(1,"foo")=2

=item Ginc $global, [$idx1, $idx2, ... ,] $value

Increments a global in the most efficient way.

Example:

 Ginc "xx", 1, "foo", 2; # s ^xx(1,"foo")=^xx(1,"foo")+2

Note: This function does not return anything.
Use Gseq for an atomic increment by one and
a result.

=item GsetA $global, [$idx1, $idx2, ... ,] \@values

Sets globals out of an array. If an array value is undef
it is skipped.

Example:

 GsetA "xx", 1, "foo", [ 0, "seppl", undef, "x" ]

does the following:

 s ^xx(1,"foo",0)=0
 s ^xx(1,"foo",1)="seppl"
 s ^xx(1,"foo",3)="x"

=item GincA $global, [$idx1, $idx2, ..., ] \@values

increments globals

=item GsetH $global, [$idx1, $idx2, ..., ] \%values

Sets globals out of an hash. If a hash value is undef
it is skipped.

Example:

 GsetH "xx", 1, 2, "foo", { 1 => 'one', two => 2 }

 is the same as:

 s ^xx(1,2,"foo",1)="one"
 s ^xx(1,2,"foo","two")=2

=item GincH $global, [$idx1, $idx2, ..., ] \%values

Increments globals out of an hash. If a hash value is undef
it is skipped.

=item Gseq $global [, $idx1, $idx2, ... ]

Increments global by one and returns the value
it has after incrementing.
This is an atomic function.

=item Gget $global [, $idx1, $idx2, ... ]

Fetches a global. If the node is undefined undef is
returned. Use GgetRaise if you want an exception when
accessing an undefined node.

Note: Intersystems refuses to give the author of this
module enough informations to make this function
as fast as possible.

=item GgetRaise $global [, $idx1, $idx2, ... ]

Fetches a global. If the node is undefined an exception
is raised. Use Gget if you want undef instead of an
exception.

Note: Intersystems refuses to give the author of this
module enough informations to make this function
as fast as possible.



=back

=head1 SEE ALSO

L<Cac>, L<Cac::ObjectScript>, L<Cac::Routine>, L<Cac::Util>, L<Cac::Bind>.

=head1 AUTHOR

 Stefan Traby <stefan@hello-penguin.com>
 http://hello-penguin.com

=cut

1;
__END__

