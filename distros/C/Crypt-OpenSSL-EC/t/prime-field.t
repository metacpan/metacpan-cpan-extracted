# Based on openssl 1.0.1 test/ectest.c  prime_field_tests()
use strict;
use warnings;

use Test::More tests => 263;
use Crypt::OpenSSL::Bignum::CTX;

BEGIN { use_ok('Crypt::OpenSSL::EC') };

&prime_field_tests();

sub prime_field_tests()
{
    my $ctx = Crypt::OpenSSL::Bignum::CTX->new();
    ok($ctx);

    my $p = Crypt::OpenSSL::Bignum->new_from_hex('17');
    ok($p);
    ok($p->to_decimal() eq '23');

    my $a = Crypt::OpenSSL::Bignum->new_from_hex('1');
    ok($a);
    ok($a->to_decimal() eq '1');

    my $b = Crypt::OpenSSL::Bignum->new_from_hex('1');
    ok($b);
    ok($b->to_decimal() eq '1');

    my $method = Crypt::OpenSSL::EC::EC_GFp_mont_method();
    ok($method);

    my $group = Crypt::OpenSSL::EC::EC_GROUP::new($method);
    ok($group);

    # Caution: this fails on some OpenSSLs, eg on Fedora 13 where EC2M are not available
    ok($group->set_curve_GFp($p, $a, $b, $ctx));

    my $tmp = Crypt::OpenSSL::EC::EC_GROUP::new($group->method_of());
    ok($tmp);

    ok($tmp->copy($group));

    ok($group->get_curve_GFp($p, $a, $b, $ctx));

#    print "Curve defined by Weierstrass equation\n     y^2 = x^3 + a*x + b  (mod 0x" . $p->to_hex() . ")\n a = 0x" . $a->to_hex() . "\n b = 0x" . $b->to_hex() . "\n";
    $Crypt::OpenSSL::EC::trace = 1;
    Crypt::OpenSSL::EC::print_errs();

    my $P = Crypt::OpenSSL::EC::EC_POINT::new($group);
    ok($P);
    my $Q = Crypt::OpenSSL::EC::EC_POINT::new($group);
    ok($Q);
    my $R = Crypt::OpenSSL::EC::EC_POINT::new($group);
    ok($R);

    ok(Crypt::OpenSSL::EC::EC_POINT::set_to_infinity($group, $P));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $P));
    my $buf = "\0";
    ok(Crypt::OpenSSL::EC::EC_POINT::oct2point($group, $Q, $buf, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::add($group, $P, $P, $Q, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $P));

    my $x = Crypt::OpenSSL::Bignum->new_from_hex('D');
    ok($x);
    my $y = Crypt::OpenSSL::Bignum->new_from_decimal('0');
    ok($y);
    my $z = Crypt::OpenSSL::Bignum->new_from_decimal('0');
    ok($z);

    ok(Crypt::OpenSSL::EC::EC_POINT::set_compressed_coordinates_GFp($group, $Q, $x, 1, $ctx)) ;
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $Q, $ctx));


#    print "A cyclic subgroup\n";

    my $k;
    for ($k = 100; $k > 0; $k--)
    {
	if (Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $P))
	{
#	    print "point at infinity\n";
	}
	else
	{
	    ok(Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $P, $x, $y, $ctx));
#	    print "    x = 0x" . $x->to_hex() . ", y = 0x" . $y->to_hex() . "\n";
	}
	ok($R->copy($P));
	ok(Crypt::OpenSSL::EC::EC_POINT::add($group, $P, $P, $Q, $ctx)) ;
	last if Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $P);
    }
    ok($k > 0);

    ok(Crypt::OpenSSL::EC::EC_POINT::add($group, $P, $Q, $R, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $P));


    $buf = Crypt::OpenSSL::EC::EC_POINT::point2oct($group, $Q, &Crypt::OpenSSL::EC::POINT_CONVERSION_COMPRESSED, $ctx);
    ok(length $buf);
    ok(Crypt::OpenSSL::EC::EC_POINT::oct2point($group, $P, $buf, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::cmp($group, $P, $Q, $ctx) == 0);
#    print "Generator as octet string, compressed form:\n     " . unpack('H*', $buf) . "\n";
    ok($buf eq pack('H*', '030d'));

    $buf = Crypt::OpenSSL::EC::EC_POINT::point2oct($group, $Q, &Crypt::OpenSSL::EC::POINT_CONVERSION_UNCOMPRESSED, $ctx);
    ok(length $buf);
    ok(Crypt::OpenSSL::EC::EC_POINT::oct2point($group, $P, $buf, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::cmp($group, $P, $Q, $ctx) == 0);
#    print "Generator as octet string, uncompressed form:\n     " . unpack('H*', $buf) . "\n";
    ok($buf eq pack('H*', '040d07'));

    $buf = Crypt::OpenSSL::EC::EC_POINT::point2oct($group, $Q, &Crypt::OpenSSL::EC::POINT_CONVERSION_HYBRID, $ctx);
    ok(length $buf);
    ok(Crypt::OpenSSL::EC::EC_POINT::oct2point($group, $P, $buf, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::cmp($group, $P, $Q, $ctx) == 0);
#    print "Generator as octet string, hybrid form:\n     " . unpack('H*', $buf) . "\n";
    ok($buf eq pack('H*', '070d07'));

    ok(Crypt::OpenSSL::EC::EC_POINT::get_Jprojective_coordinates_GFp($group, $R, $x, $y, $z, $ctx));
#    print "A representation of the inverse of that generator in\nJacobian projective coordinates:\n     X = 0x" .$x->to_hex() . " Y = 0x" . $y->to_hex() . " Z = 0x" . $z->to_hex() . "\n";

    $p = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFF');
    $a = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFC');
    $b = Crypt::OpenSSL::Bignum->new_from_hex('1C97BEFC54BD7A8B65ACF89F81D4D4ADC565FA45');

    ok($group->set_curve_GFp($p, $a, $b, $ctx));

    $x = Crypt::OpenSSL::Bignum->new_from_hex('4A96B5688EF573284664698968C38BB913CBFC82');
    $y = Crypt::OpenSSL::Bignum->new_from_hex('23a628553168947d59dcc912042351377ac5fb32');

    ok(Crypt::OpenSSL::EC::EC_POINT::set_affine_coordinates_GFp($group, $P, $x, $y, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $P, $ctx)) ;

    $z = Crypt::OpenSSL::Bignum->new_from_hex('0100000000000000000001F4C8F927AED3CA752257');
    ok($group->set_generator($P, $z, Crypt::OpenSSL::Bignum->one()));

    ok(Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $P, $x, $y, $ctx));

#    print "SEC2 curve secp160r1 -- Generator:\n     x = 0x" . $x->to_hex() . "\n     y = 0x" . $y->to_hex() . "\n";

    # G_y value taken from the standard:
    ok($y->to_hex() eq uc('23a628553168947d59dcc912042351377ac5fb32'));

    ok($group->get_degree() == 160);

    group_order_tests($group);

    my $P_160 = Crypt::OpenSSL::EC::EC_GROUP::new($group->method_of());
    ok($P_160);
    ok($P_160->copy($group));

    # Curve P-192 (FIPS PUB 186-2, App. 6)
    $p = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF');
    # cant test BN_is_prime_ex
    $a = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC');
    $b = Crypt::OpenSSL::Bignum->new_from_hex('64210519E59C80E70FA7E9AB72243049FEB8DEECC146B9B1');
    ok($group->set_curve_GFp($p, $a, $b, $ctx));

    $x = Crypt::OpenSSL::Bignum->new_from_hex('188DA80EB03090F67CBF20EB43A18800F4FF0AFD82FF1012');
    ok(Crypt::OpenSSL::EC::EC_POINT::set_compressed_coordinates_GFp($group, $P, $x, 1, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $P, $ctx));
    $z = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831');
    ok($group->set_generator($P, $z, Crypt::OpenSSL::Bignum->one()));

    ok(Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $P, $x, $y, $ctx));
#    print "NIST curve P-192 -- Generator:\n     x = 0x" . $x->to_hex() . "\n     y = 0x" . $y->to_hex() . "\n";
    ok($y->to_hex() eq uc('07192B95FFC8DA78631011ED6B24CDD573F977A11E794811'));
    ok($group->get_degree() == 192);

    group_order_tests($group);

    my $P_192 = Crypt::OpenSSL::EC::EC_GROUP::new($group->method_of());
    ok($P_192);
    ok($P_192->copy($group));

    # Curve P-224 (FIPS PUB 186-2, App. 6)

    $p = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001');
    # cant test BN_is_prime_ex
    $a = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE');
    $b = Crypt::OpenSSL::Bignum->new_from_hex('B4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4');
    ok($group->set_curve_GFp($p, $a, $b, $ctx));

    $x = Crypt::OpenSSL::Bignum->new_from_hex('B70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21');
    ok(Crypt::OpenSSL::EC::EC_POINT::set_compressed_coordinates_GFp($group, $P, $x, 0, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $P, $ctx));
    $z = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D');
    ok($group->set_generator($P, $z, Crypt::OpenSSL::Bignum->one()));

    ok(Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $P, $x, $y, $ctx));
#    print "NIST curve P-224 -- Generator:\n     x = 0x" . $x->to_hex() . "\n     y = 0x" . $y->to_hex() . "\n";
    ok($y->to_hex() eq uc('BD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34'));
    ok($group->get_degree() == 224);

    group_order_tests($group);

    my $P_224 = Crypt::OpenSSL::EC::EC_GROUP::new($group->method_of());
    ok($P_224);
    ok($P_224->copy($group));


    # Curve P-256 (FIPS PUB 186-2, App. 6)

    $p = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF');
# cant test BN_is_prime_ex
    $a = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC');
    $b = Crypt::OpenSSL::Bignum->new_from_hex('5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B');
    ok($group->set_curve_GFp($p, $a, $b, $ctx));

    $x = Crypt::OpenSSL::Bignum->new_from_hex('6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296');
    ok(Crypt::OpenSSL::EC::EC_POINT::set_compressed_coordinates_GFp($group, $P, $x, 1, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $P, $ctx));
    $z = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551');
    ok($group->set_generator($P, $z, Crypt::OpenSSL::Bignum->one()));

    ok(Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $P, $x, $y, $ctx));
#    print "NIST curve P-256 -- Generator:\n     x = 0x" . $x->to_hex() . "\n     y = 0x" . $y->to_hex() . "\n";
    ok($y->to_hex() eq uc('4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5'));
    ok($group->get_degree() == 256);

    group_order_tests($group);

    my $P_256 = Crypt::OpenSSL::EC::EC_GROUP::new($group->method_of());
    ok($P_256);
    ok($P_256->copy($group));

    # Curve P-384 (FIPS PUB 186-2, App. 6)

    $p = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFF');
# cant test BN_is_prime_ex
    $a = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFC');
    $b = Crypt::OpenSSL::Bignum->new_from_hex('B3312FA7E23EE7E4988E056BE3F82D19181D9C6EFE8141120314088F5013875AC656398D8A2ED19D2A85C8EDD3EC2AEF');
    ok($group->set_curve_GFp($p, $a, $b, $ctx));

    $x = Crypt::OpenSSL::Bignum->new_from_hex('AA87CA22BE8B05378EB1C71EF320AD746E1D3B628BA79B9859F741E082542A385502F25DBF55296C3A545E3872760AB7');
    ok(Crypt::OpenSSL::EC::EC_POINT::set_compressed_coordinates_GFp($group, $P, $x, 1, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $P, $ctx));
    $z = Crypt::OpenSSL::Bignum->new_from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7634D81F4372DDF581A0DB248B0A77AECEC196ACCC52973');
    ok($group->set_generator($P, $z, Crypt::OpenSSL::Bignum->one()));

    ok(Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $P, $x, $y, $ctx));
#    print "NIST curve P-384 -- Generator:\n     x = 0x" . $x->to_hex() . "\n     y = 0x" . $y->to_hex() . "\n";
    ok($y->to_hex() eq uc('3617DE4A96262C6F5D9E98BF9292DC29F8F41DBD289A147CE9DA3113B5F0B8C00A60B1CE1D7E819D7A431D7C90EA0E5F'));
    ok($group->get_degree() == 384);

    group_order_tests($group);

    my $P_384 = Crypt::OpenSSL::EC::EC_GROUP::new($group->method_of());
    ok($P_384);
    ok($P_384->copy($group));

    # Curve P-521 (FIPS PUB 186-2, App. 6)

    $p = Crypt::OpenSSL::Bignum->new_from_hex('1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
# cant test BN_is_prime_ex
    $a = Crypt::OpenSSL::Bignum->new_from_hex('1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC');
    $b = Crypt::OpenSSL::Bignum->new_from_hex('051953EB9618E1C9A1F929A21A0B68540EEA2DA725B99B315F3B8B489918EF109E156193951EC7E937B1652C0BD3BB1BF073573DF883D2C34F1EF451FD46B503F00');
    ok($group->set_curve_GFp($p, $a, $b, $ctx));

    $x = Crypt::OpenSSL::Bignum->new_from_hex('C6858E06B70404E9CD9E3ECB662395B4429C648139053FB521F828AF606B4D3DBAA14B5E77EFE75928FE1DC127A2FFA8DE3348B3C1856A429BF97E7E31C2E5BD66');
    ok(Crypt::OpenSSL::EC::EC_POINT::set_compressed_coordinates_GFp($group, $P, $x, 0, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $P, $ctx));
    $z = Crypt::OpenSSL::Bignum->new_from_hex('1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409');
    ok($group->set_generator($P, $z, Crypt::OpenSSL::Bignum->one()));

    ok(Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $P, $x, $y, $ctx));
#    print "NIST curve P-521 -- Generator:\n     x = 0x" . $x->to_hex() . "\n     y = 0x" . $y->to_hex() . "\n";
    ok($y->to_hex() eq uc('011839296A789A3BC0045C8A5FB42C7D1BD998F54449579B446817AFBD17273E662C97EE72995EF42640C550B9013FAD0761353C7086A272C24088BE94769FD16650'));
    ok($group->get_degree() == 521);

    group_order_tests($group);

    my $P_521 = Crypt::OpenSSL::EC::EC_GROUP::new($group->method_of());
    ok($P_521);
    ok($P_521->copy($group));


    # more tests using the last curve

    ok($Q->copy($P));
    ok(!Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $Q));
    ok(Crypt::OpenSSL::EC::EC_POINT::dbl($group, $P, $P, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_on_curve($group, $P, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::invert($group, $Q, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::add($group, $R, $P, $Q, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::add($group, $R, $R, $Q, $ctx)) ;
    ok(Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $R));

    # REVISIT: EC_POINTs_mul not yet implemented

}

sub group_order_tests
{
    my ($group) = @_;
    my $n1 = Crypt::OpenSSL::Bignum->one();
    ok($n1);
    
    my $n2 = Crypt::OpenSSL::Bignum->one();
    ok($n2);
    
    my $order = Crypt::OpenSSL::Bignum->zero();
    ok($order);
    
    my $dummy1 = Crypt::OpenSSL::Bignum->one();
    ok($dummy1);
    my $dummy2 = Crypt::OpenSSL::Bignum->one();
    ok($dummy2);
    
    my $ctx = Crypt::OpenSSL::Bignum::CTX->new();
    ok($ctx);

    my $P = Crypt::OpenSSL::EC::EC_POINT::new($group);
    ok($P);

    my $Q = Crypt::OpenSSL::EC::EC_POINT::new($group);
    ok($Q);

    ok($group->get_order($order, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::mul($group, $Q, $order, \0, \0, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $Q));

    ok($group->precompute_mult($ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::mul($group, $Q, $order, \0, \0, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::is_at_infinity($group, $Q));

    # n1 = 1 - order
    ok($n1->sub($n1, $order));
    ok(Crypt::OpenSSL::EC::EC_POINT::mul($group, $Q, \0, $P, $n1, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::cmp($group, $Q, $P, $ctx) == 0);

    # n2 = 1 + order 
    $n2 = $order->add(Crypt::OpenSSL::Bignum->one());
    ok($n2);
    ok(Crypt::OpenSSL::EC::EC_POINT::mul($group, $Q, \0, $P, $n2, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::cmp($group, $Q, $P, $ctx) == 0);

    $n2 = $n2->mul($n1, $ctx);
    ok($n2);
    ok(Crypt::OpenSSL::EC::EC_POINT::mul($group, $Q, \0, $P, $n2, $ctx));
    ok(Crypt::OpenSSL::EC::EC_POINT::cmp($group, $Q, $P, $ctx) == 0);

    
}
1
