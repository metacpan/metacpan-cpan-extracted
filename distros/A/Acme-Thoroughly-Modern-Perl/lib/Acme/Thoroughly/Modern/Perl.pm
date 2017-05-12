package Acme::Thoroughly::Modern::Perl;

use strict;
use warnings;

our $VERSION = 'v0.4.1';

my @now = localtime();
my $yr  = $now[5] - 100;

# This actually calculates what might be the current minimum version
# for years >= 2010.
my $mver = ( ( $yr - 10 ) * 2 ) + 10;

# just in case there is a boundary case, wrap the test in a do/while
# and step it up as needed.
my $req_str;
do {
    $mver += 2;    # skip over devel releases
    my $verstr = sprintf( "%0.3f", 5 + ( $mver * .001 ) );
    $req_str = "require $verstr";
} while ( eval "$req_str" );

# we need to warn and exit, and NOT die, if we want to more closely emulate
# what is actually printed for a real failue. we exit with 255 because
# that is what perl does. (but override in a test environment since it would
# really suck to have 100% failures on the test matrix!)
unless ( $ENV{ATMP_TEST} ) {
    warn "$@\n";
    exit 255;
}

1;

__END__
=pod

=head1 NAME

Acme::Thoroughly::Modern::Perl - Go where no Perl has gone before!

=head1 SYNOPSIS

  
  use Acme::Thoroughly::Modern::Perl;
  

=head1 DESCRIPTION

This module allows one to not only be on the bleeding edge of Perl, but to
go beyond!

Unlike other modules that attempt to include advanced features, there is
no need to specify a given version or release year. Acme is committed to
making the user experience as simple and error-free as possible and
automatically does all of this for you!

=head1 BUGS

ACME is perfection! (Time machine not included.)

=head1 AUTHOR

Jim Bacon, E<lt>jim@nortx.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jim Bacon

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.010001 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER

Finding a way to use this module, and the consequences of doing so, is the
sole responsibility of the user!

=head1 NOTE

Acme employs the finest technology available to ensure the quality of its
products. There are no user-servicable parts inside. For your own safety,
DO NOT EXAMINE THE CONTENTS OF THIS PACKAGE!

=cut
