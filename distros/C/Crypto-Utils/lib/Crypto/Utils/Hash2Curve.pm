#ABSTRACT: Hash to Curve
package Crypto::Utils::Hash2Curve;

use strict;
use warnings;
use POSIX qw(ceil);

require Exporter;
use Crypto::Utils::OpenSSL;

our @ISA    = qw(Exporter);
our @EXPORT = qw/
  sn2kv
  get_hash2curve_params
  hash_to_field
  map_to_curve
  encode_to_curve
  hash_to_curve
  /;

our @EXPORT_OK = @EXPORT;

our %H2C_CNF = (
    'prime256v1' => {
        k      => 0x80,
        m      => 1,
        'sswu' => {
            z                 => '-10',
            calc_c1_c2_func   => \&calc_c1_c2_for_sswu,
            map_to_curve_func => \&map_to_curve_sswu_straight_line,
        },
    },
);

sub sn2kv {
    my ( $group_name, $param_name ) = @_;
    return $H2C_CNF{$group_name}{$param_name};
}

sub get_hash2curve_params {
    my ( $group_name, $type ) = @_;

    my $ec_params_r = get_ec_params($group_name);

    $ec_params_r->{$_} = $H2C_CNF{$group_name}{$_}
      for keys( %{ $H2C_CNF{$group_name} } );

    if ( $type eq 'sswu' ) {
        my $z = BN_new();
        BN_dec2bn( $z, $H2C_CNF{$group_name}{$type}{z} );

        my $c1 = BN_new();
        my $c2 = BN_new();
        $H2C_CNF{$group_name}{$type}{calc_c1_c2_func}
          ->( $c1, $c2, @{$ec_params_r}{qw/p a b/}, $z, $ec_params_r->{ctx}, );

        @{$ec_params_r}{qw/c1 c2 z/} = ( $c1, $c2, $z );

    }

    $ec_params_r;
} ## end sub get_hash2curve_params

sub hash_to_curve {
    my ( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func,
        $clear_cofactor_flag )
      = @_;

    my $h2c_r = get_hash2curve_params( $group_name, $type );

    #my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

    my $count = 2;

    #my ( $k, $m ) = sn2k_m( $group_name );
    my @res =
      hash_to_field( $msg, $count, $DST, $h2c_r->{p}, $h2c_r->{m}, $h2c_r->{k},
        $hash_name, $expand_message_func );

    my $u0 = $res[0][0];
    my $Q0 =
      map_to_curve( $h2c_r, $group_name, $type, $u0, $clear_cofactor_flag );

    my $u1 = $res[1][0];
    my $Q1 =
      map_to_curve( $h2c_r, $group_name, $type, $u1, $clear_cofactor_flag );

    my $Q = EC_POINT_new( $h2c_r->{group} );
    EC_POINT_add( $h2c_r->{group}, $Q, $Q0, $Q1, $h2c_r->{ctx} );

    return $Q unless ($clear_cofactor_flag);

    my $P = EC_POINT_new( $h2c_r->{group} );
    clear_cofactor( $h2c_r->{group}, $P, $Q, $h2c_r->{ctx} );

    return wantarray ? ( $P, $h2c_r ) : $P;
} ## end sub hash_to_curve

sub encode_to_curve {
    my ( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func,
        $clear_cofactor_flag )
      = @_;

    my $h2c_r = get_hash2curve_params( $group_name, $type );

    #my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

    my $count = 1;

#my ( $k, $m ) = sn2k_m( $group_name );
#my @res = hash_to_field( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func );
    my @res =
      hash_to_field( $msg, $count, $DST, $h2c_r->{p}, $h2c_r->{m}, $h2c_r->{k},
        $hash_name, $expand_message_func );

    my $u = $res[0][0];
    my $P =
      map_to_curve( $h2c_r, $group_name, $type, $u, $clear_cofactor_flag );
    return wantarray ? ( $P, $h2c_r ) : $P;
}

sub map_to_curve {
    my ( $params_ref, $group_name, $type, $u, $clear_cofactor_flag ) = @_;

    #my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

    my $x = BN_new();
    my $y = BN_new();
    $H2C_CNF{$group_name}{$type}{map_to_curve_func}
      ->( @{$params_ref}{qw/c1 c2 p a b z/}, $u, $x, $y, $params_ref->{ctx} );

    ### $u
    my $Q = gen_ec_point( $params_ref->{group}, $x, $y, $clear_cofactor_flag );

    ### $Q

    return $Q;
} ## end sub map_to_curve

sub hash_to_field {
    my ( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func ) =
      @_;

    my $ctx = BN_CTX_new();

    my $L = BN_num_bits($p);
    $L = ceil( ( $L + $k ) / 8 );
    ### $L

    my $len_in_bytes = $count * $m * $L;
    ### len_in_bytes: $len_in_bytes
    my $uniform_bytes =
      $expand_message_func->( $msg, $DST, $len_in_bytes, $hash_name );
    ### uniform_bytes: unpack("H*", $uniform_bytes)

    my @res;
    for my $i ( 0 .. $count - 1 ) {
        my @u;
        for my $j ( 0 .. $m - 1 ) {
            my $elm_offset = $L * ( $j + $i * $m );
            my $tv         = substr( $uniform_bytes, $elm_offset, $L );

            my $tv_bn = BN_new();
            BN_bin2bn( $tv, length($tv), $tv_bn );

            my $reminder = BN_mod( $tv_bn, $p, $ctx );

            push @u, $reminder;
        }
        push @res, \@u;
    }
    return @res;
} ## end sub hash_to_field

1;

__END__

=pod

=encoding utf8

=head1 NAME

Crypto::Utils::Hash2Curve - Hash to Curve functions

=head1 SYNOPSIS

    use Crypto::Utils::Hash2Curve;
    use Crypto::Utils::OpenSSL qw(expand_message_xmd EC_POINT_point2hex);

    my $msg = 'abc';
    my $DST = 'QUUX-V01-CS02-with-P256_XMD:SHA-256_SSWU_RO_';
    my $group_name = "prime256v1";
    my $type = 'sswu';
    
    # Hash to curve point
    my $P = hash_to_curve($msg, $DST, $group_name, $type, 'SHA256', \&expand_message_xmd , 1 );

    my $params_ref = get_hash2curve_params($group_name, $type);
    my $group = $params_ref->{group};
    my $ctx = $params_ref->{ctx};
    my $bn = EC_POINT_point2hex($group, $P, 4, $ctx);
    print $bn, "\n";

=head1 FUNCTIONS

=head2 hash_to_curve

  my $P = hash_to_curve( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );

  my ($P, $group_params_ref)  = hash_to_curve( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );

=head2 encode_to_curve

  my $P = encode_to_curve( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );

  my ($P, $group_params_ref) = encode_to_curve( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );

=head2 get_hash2curve_params

  my $group_params_ref = get_hash2curve_params($group_name, $type);

=head2 map_to_curve

  my $P = map_to_curve( $params_ref, $group_name, $type, $u, $clear_cofactor_flag );

=head2 hash_to_field

  my $res_arr_ref = hash_to_field( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func );

=head2 sn2kv

  my $val = sn2kv($group_name, $param_name);

=cut
