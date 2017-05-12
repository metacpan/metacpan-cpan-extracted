#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 57;

use Business::OnlinePayment;

{    # fake test driver 1 (no submit method)

    package Business::OnlinePayment::MOCK1;
    use strict;
    use warnings;
    use base qw(Business::OnlinePayment);
}

{    # fake test driver 2 (with submit method that dies)

    package Business::OnlinePayment::MOCK2;
    use base qw(Business::OnlinePayment::MOCK1);
    sub submit { my $self = shift; die("in processor submit\n"); }
}

{    # fake test driver 3 (with submit method)

    package Business::OnlinePayment::MOCK3;
    use base qw(Business::OnlinePayment::MOCK1);
    sub submit { my $self = shift; return 1; }
}

my $package = "Business::OnlinePayment";
my @drivers = qw(MOCK1 MOCK2 MOCK3);
my $driver  = $drivers[0];

# trick to make use() happy (called in Business::OnlinePayment->new)
foreach my $drv (@drivers) {
    $INC{"Business/OnlinePayment/${drv}.pm"} = "testing";
}

{    # new
    can_ok( $package, qw(new) );
    my $obj;

    eval { $obj = $package->new(); };
    like( $@, qr/^unspecified processor/, "new() without a processor croaks" );

    eval { $obj = $package->new("__BOP BOGUS PROCESSOR__"); };
    like( $@, qr/^unknown processor/,
        "new() with an unknown processor croaks" );

    $obj = $package->new($driver);
    isa_ok( $obj, $package );
    isa_ok( $obj, $package . "::" . $driver );

    # build_subs(%fields)
    can_ok(
        $obj, qw(
          authorization
          error_message
          failure_status
          fraud_detect
          is_success
          maximum_risk
          path
          port
          require_avs
          result_code
          server
          server_response
          test_transaction
          transaction_type
          )
    );

    # new (via build_subs) automatically creates accessors for arguments
    $obj = $package->new( $driver, "proc1" => "value1" );
    can_ok( $package, "proc1" );
    can_ok( $obj,     "proc1" );

    # new (via build_subs) automatically creates accessors for arguments
    $obj = $package->new( $driver, qw(key1 v1 Key2 v2 -Key3 v3 --KEY4 v4) );
    can_ok( $package, qw(key1 key2 key3 key4) );
    can_ok( $obj,     qw(key1 key2 key3 key4) );

    # new makes all accessors lowercase and removes leading dash(es)
    is( $obj->key1, "v1", "value of key1   (method key1) is v1" );
    is( $obj->key2, "v2", "value of Key2   (method key2) is v2" );
    is( $obj->key3, "v3", "value of -Key3  (method key3) is v3" );
    is( $obj->key4, "v4", "value of --KEY4 (method key4) is v4" );
}

# XXX
# {    # _risk_detect }

{    # _pre_submit

    my $s_orig = Business::OnlinePayment::MOCK3->can("submit");
    is( ref $s_orig, "CODE", "MOCK3 submit code ref $s_orig" );

    # test to ensure we do not go recursive when wrapping submit
    my $obj1   = $package->new("MOCK3");
    my $s_new1 = $obj1->can("submit");

    isnt( $s_new1, $s_orig, "MOCK3 submit code ref $s_new1 (wrapped)" );
    is( $obj1->submit, "1", "MOCK3(obj1) submit returns 1" );

    my $obj2   = $package->new("MOCK3");
    my $s_new2 = $obj2->can("submit");
    is( $obj2->submit, "1", "MOCK3(obj2) submit returns 1" );
}

{    # content
    my $obj;

    $obj = $package->new($driver);
    can_ok( $package, qw(content) );
    can_ok( $obj,     qw(content) );

    is( $obj->content, (), "default content is empty" );

    my %data = qw(k1 v1 type test -k2 v2 K3 v3);
    is_deeply( { $obj->content(%data) }, \%data, "content is set properly" );
    is( $obj->transaction_type, "test", "content sets transaction_type" );

    %data = ( type => undef );
    is_deeply( { $obj->content(%data) }, \%data, "content with type=>undef" );
    is( $obj->transaction_type, "test", "transaction_type not reset" );
}

{    # required_fields
    my $obj = $package->new($driver);
    can_ok( $package, qw(required_fields) );
    can_ok( $obj,     qw(required_fields) );

    is( $obj->required_fields, 0, "no required fields" );

    eval { $obj->required_fields("field1"); };
    like( $@, qr/^missing required field/, "missing required_fields croaks" );
}

{    # get_fields
    my $obj = $package->new($driver);
    can_ok( $package, qw(get_fields) );
    can_ok( $obj,     qw(get_fields) );

    my %data = ( a => 1, b => 2, c => undef, d => 4 );
    $obj->content(%data);

    my ( @want, %get );

    @want = qw(a b);
    %get = map { $_ => $data{$_} } @want;
    is_deeply( { $obj->get_fields(@want) },
        \%get, "get_fields with defined vals" );

    @want = qw(a c d);
    %get = map { defined $data{$_} ? ( $_ => $data{$_} ) : () } @want;

    is_deeply( { $obj->get_fields(@want) },
        \%get, "get_fields does not get fields with undef values" );
}

{    # remap_fields
    my $obj = $package->new($driver);
    can_ok( $package, qw(remap_fields) );
    can_ok( $obj,     qw(remap_fields) );

    my %data = ( a => 1, b => 2, c => undef, d => 4 );
    $obj->content(%data);

    my %map = ( a => "Aa", d => "Dd" );
    my %get = ( a => 1, Aa => 1, b => 2, c => undef, d => 4, Dd => 4 );

    $obj->remap_fields(%map);
    is_deeply( { $obj->content }, \%get, "remap_fields" );
}

{    # submit
    my $obj = $package->new($driver);
    can_ok( $package, qw(submit) );
    can_ok( $obj,     qw(submit) );

    eval { $obj->submit; };
    like( $@, qr/^Processor subclass did not /, "missing submit() croaks" );
    isnt( $obj->can("submit"), $package->can("submit"), "submit changed" );

    my $mock2 = $package->new("MOCK2");
    can_ok( $mock2, qw(submit) );

    isnt( $mock2->can("submit"), $package->can("submit"), "submit changed" );
    eval { $mock2->submit; };
    like( $@, qr/^in processor submit/, "processor submit() is called" );
}

{    # dump_contents
    my $obj = $package->new($driver);
    can_ok( $package, qw(dump_contents) );
    can_ok( $obj,     qw(dump_contents) );
}

{    # build_subs
    my $obj;

    $obj = $package->new($driver);
    can_ok( $package, qw(build_subs) );
    can_ok( $obj,     qw(build_subs) );

    # build_subs creates accessors for arguments
    my %data = qw(key1 v1 Key2 v2 -Key3 v3 --KEY4 v4);
    my @subs =
      sort { lc( ( $a =~ /(\w+)/ )[0] ) cmp lc( ( $b =~ /(\w+)/ )[0] ) }
      keys %data;

    $obj->build_subs(@subs);

    # perl does not allow dashes ("-") in subroutine names
    foreach my $sub (@subs) {
        if ( $sub !~ /^\w+/ ) {
            is( ref $package->can($sub), "", "$package can NOT $sub" );
            is( ref $obj->can($sub),     "", ref($obj) . " can NOT $sub" );
        }
        else {
            can_ok( $package, $sub );
            can_ok( $obj,     $sub );
            $obj->$sub( $data{$sub} );
            is( $obj->$sub, $data{$sub}, "$sub accessor returns $data{$sub}" );
        }
    }
}
