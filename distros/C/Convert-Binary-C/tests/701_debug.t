################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C;

$^W = 1;

BEGIN {
  $debug = Convert::Binary::C::feature( 'debug' );
  plan tests => 17;
}

ok( defined $debug );
$dbfile = 'tests/debug.out';

-e $dbfile and unlink $dbfile;

$SIG{__WARN__} = sub { push @warnings, $_[0] };

eval qq{
  use Convert::Binary::C debug => 'all', debugfile => '$dbfile';
};

ok( $@, '' );

if( $debug ) {
  ok( scalar @warnings, 0, "unexpected warning(s)" );
  ok( 1 );  # dummy
}
else {
  ok( scalar @warnings, 1, "wrong number of warnings" );
  ok( $warnings[0], qr/Convert::Binary::C not compiled with debugging support/ );
}

ok( -e $dbfile xor not $debug );
ok( -z $dbfile xor not $debug );

eval { $p = Convert::Binary::C->new };

ok( $@, '' );
ok( ref $p, 'Convert::Binary::C' );

undef $p;

@warnings = ();

eval q{
  use Convert::Binary::C debugfile => '';
};

ok( $@, '', "unexpected error" );
ok( scalar @warnings, 1, "wrong number of warnings" );
ok( $warnings[0], $debug ? qr/Cannot open '', defaulting to stderr/
                         : qr/Convert::Binary::C not compiled with debugging support/ );

ok( -s $dbfile xor not $debug );

@warnings = ();

eval qq{
  import Convert::Binary::C debug => 'foo';
};

if( $debug ) {
  ok( $@, qr/^Unknown debug option 'f'/ );
  ok( scalar @warnings, 0, "unexpected warning(s)" );
  ok( 1 );  # dummy
}
else {
  ok( $@, '', "unexpected error" );
  ok( scalar @warnings, 1, "wrong number of warnings" );
  ok( $warnings[0], qr/Convert::Binary::C not compiled with debugging support/ );
}

@warnings = ();

eval qq{
  import Convert::Binary::C 'debug';
};

ok( $@, qr/^You must pass an even number of module arguments/ );
ok( scalar @warnings, 0, "unexpected warning(s)" );
