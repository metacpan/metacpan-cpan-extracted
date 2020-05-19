################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 41 }

$SIG{__WARN__} = sub { push @warn, $_[0] };
sub chkwarn {
  my $fail = 0;
  if( @warn != @_ ) {
    print "# wrong number of warnings (got ", scalar @warn,
                               ", expected ", scalar @_, ")\n";
    $fail++;
  }
  for my $ix ( 0 .. $#_ ) {
    my $e = $_[$ix];
    my $w = $warn[$ix];
    unless( $w =~ ref($e) ? $e : qr/\Q$e\E/ ) {
      print "# wrong warning, expected $e, got $w\n";
      $fail++;
    }
  }
  if( $fail ) { print "# $_" for @warn }
  ok( $fail, 0, "warnings check failed" );
  @warn = ();
}

$c = Convert::Binary::C->new( ByteOrder => 'BigEndian', IntSize => 4 );
$c->parse("typedef unsigned int u_32;");

$ref  = pack "N*", 1000000, 5000000, 3000000, 4000000;
$data = pack "N*", 1000000, 2000000, 3000000, 4000000;

$x = eval { $c->unpack('u_32', $data) };
ok($@, '');
ok($x, 1000000);
chkwarn();

$x = eval { $c->unpack('u_32', substr $data, 0, 4) };
ok($@, '');
ok($x, 1000000);
chkwarn();

$x = eval { $c->unpack('u_32', substr $data, 4) };
ok($@, '');
ok($x, 2000000);
chkwarn();

$x = eval { $c->unpack('u_32', substr $data, 8, 4) };
ok($@, '');
ok($x, 3000000);
chkwarn();

$x = eval { $c->unpack('u_32', substr $data, 8, 3) };
ok($@, '');
ok(not defined $x);
chkwarn(qr/Data too short/);

$x = $data;
eval { substr($x, 4, 4) = $c->pack('u_32', 5000000) };
ok($@, '');
ok($x, $ref);
chkwarn();

$x = eval { $c->pack('u_32', 5000000, substr($data, 4, 4)) };
ok($@, '');
ok($x, pack('N', 5000000));
chkwarn();

$x = $data;
eval { $c->pack('u_32', 5000000, substr($x, 4, 4)) };
ok($@, '');
ok($x, $ref);
chkwarn();

eval { $c->pack('u_32', 5000000, substr('Hello World', 4, 4)) };
ok($@, qr/Modification of a read-only value attempted/);
chkwarn();

$x = $data;
eval { $c->pack('u_32', 5000000, substr($x, 4)) };
ok($@, '');
ok($x, $ref);
chkwarn();

$x = $data;
eval { $c->pack('u_32', 5000000, substr($x, 4, 0)) };
ok($@, '');
ok($x, pack('N*', 1000000, 5000000, 2000000, 3000000, 4000000));
chkwarn();


for my $ix (0 .. 2) {
  my $r = eval { $c->unpack('u_32', substr $data, ($ix+1)*$c->sizeof('u_32')) };
  ok($@, '');
  ok($r, (unpack "N*", $data)[$ix+1]);
  chkwarn();
}
