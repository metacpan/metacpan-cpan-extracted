use warnings; use strict;
use Test::More;

my $n_tests;

use Alter qw( alter ego);

# diag "The Alter::corona() function";
{
    use Symbol;
    use Scalar::Util qw( reftype weaken);
    
    our @obs;
    BEGIN { @obs = ( \ do { my $o }, [], {}, gensym, sub {}, \ []) }

    # create corona for all types
    for my $obj ( @obs ) {
        my $type = reftype $obj;
        my $crown = Alter::corona( $obj);
        is reftype( $crown), 'HASH', "got corona for $type";
    }

    # check that corona fails for invalid objects
    eval { Alter::corona( undef) };
    like $@, qr/Alter:/, "corona( undef) dies";
    eval { Alter::corona( 'abc') };
    like $@, qr/^Alter:/, "corona('abc') dies (non-ref)";
    eval { Alter::corona( \ 123) };
    like $@, qr/^Alter:/, "corona(\\ 123) dies (read-only)";

    # see if the corona is garbage-collected
    my $obj = [];
    # pure perl implementation needs destructor
    bless $obj, 'Alter::Destructor' unless Alter::is_xs();
    my $crown = Alter::corona( $obj);
    weaken $crown;
    is reftype( $crown), "HASH", "got a corona";
    undef $obj;
    is $crown, undef, "corona garbage-collected";

    BEGIN { $n_tests += @obs + 3 + 2 }
}

# diag "The alter() and ego() functions";
{
    my $obj = {};
    my %ego_tab;
    my %access_tab;

    # normal behavior
    {
        package One;
        my $class = __PACKAGE__;
        my $ego = [];
        $ego_tab{ $class} = $ego;
        $access_tab{ $class} = sub { main::ego shift }; # deposit accessor code
        my $res = main::alter( $obj, $ego);
        main::is $res, $obj, "alter() in class '$class' accepted";
        $res = main::ego( $obj);
        main::is $res, $ego, "ego() retrieves ego in class '$class'";
    }

    {
        package Two;
        my $class = __PACKAGE__;
        my $ego = {};
        $ego_tab{ $class} = $ego;
        $access_tab{ $class} = sub { main::ego shift }; # deposit accessor code
        my $res = main::alter( $obj, $ego);
        main::is $res, $obj, "alter() in class '$class' accepted";
        $res = main::ego( $obj);
        main::is $res, $ego, "ego() retrieves ego in class '$class'";
    }
    my %ret_tab;
    {
        package One;
        $ret_tab{ +__PACKAGE__} = main::ego $obj;
    }
    {
        package Two;
        $ret_tab{ +__PACKAGE__} = main::ego $obj;
    }
    for my $class ( qw( One Two) ) {
        is $ret_tab{ $class}, $ego_tab{ $class},
            "Class dependent retrieval for class '$class'";
        is $access_tab{ $class}->( $obj), $ego_tab{ $class},
            "Accessor retrieval for class '$class'";
    }
    BEGIN { $n_tests += 8 }

    # marginal behavior
    eval { alter( 'abc', 0) };
    like $@, qr/Alter:/, "alter( non-ref) dies";
    eval { alter( \ 123, 0) };
    like $@, qr/Alter:/, "alter( \\ read-only) dies";
    eval 'alter()'; # prototyping, catch at compile time
    like $@, qr/^Not enough arguments/, "alter() prototype active";
    eval { &alter( '') }; # protoyping disabled, catch at run time
    like $@, qr/^Usage/, "&alter() dies with one argument";
    eval { &alter() };
    like $@, qr/^Usage/, "&alter() dies without arguments";

    eval { ego( 'abc') };
    like $@, qr/Alter:/, "ego( non-ref) dies";
    eval { ego( \ 123) };
    like $@, qr/Alter:/, "ego( \\ read-only) dies";
    my @res = ego( []);
    ok @res == 1 && ! defined $res[ 0], "ego(uncommitted_obj) returns undef";
    eval 'ego()';
    like $@, qr/^Not enough arguments/, "ego() prototype active";
    eval { &ego() };
    like $@, qr/^Usage/, "&ego() dies without arguments";

    BEGIN { $n_tests += 10 }
}

# diag "Autovivifying behavior";
{
    use Scalar::Util qw( reftype);
    use Symbol;
    my $obj = \ do { my $o };
    our ( @supported, @unsupported);
    BEGIN {
        @supported = (
            \ do { my $o }, # scalar
            [],             # array
            {},             # hash
        );
        @unsupported = (
            gensym(),       # glob (glob is disabled)
            sub {},         # code
        );
    }
    my $template = <<"EOC";
        package Class_TYPE;
        use Alter 'alter', ego => 'TYPE';
        sub access_ego { ego( shift) }
EOC
    for my $type ( map reftype( $_) => @supported ) {
        ( my $code = $template) =~ s/TYPE/$type/g;
        no warnings "redefine";
        eval $code;
        die $@ if $@;
    }
    for my $type ( map reftype( $_) => @unsupported ) {
        ( my $code = $template) =~ s/TYPE/$type/g;
        eval $code;
        like $@, qr/not exported/, "Unsupported type '$type' rejected";
    }
    for ( @supported ) {
        my $type = reftype $_;
        my $class = "Class_$type";
        my $meth = $class->can( 'access_ego');
        my $ans = $obj->$meth;
        is reftype $ans, $type, "Autovivification with type '$type'";
    }
    for my $type ( 'NONE' ) {
        package Class_NONE;
        use Alter ego => {};       # switch to anything
        use Alter ego => 'NOAUTO'; # switch off again
        my $obj = bless [];
        main::is ego( $obj), undef, "No autovivification with type '$type'";
    }
    BEGIN { $n_tests += @unsupported + @supported + 1 }
}

# diag "The keywords -dumper and -storable";
# only checking the effect on @ISA here, actual function checked in 03_class.t
{
    {
        package A1;
        Alter->import( '-dumper');
        Alter->import( 'Dumper');

        package A2;
        Alter->import( '-storable');
        Alter->import( 'STORABLE_freeze');

        package B;
        Alter->import();
        Alter->import(); # only first one pushes
    }
    is grep( $_ eq 'Alter::Dumper', @A1::ISA), 0,
        "'-dumper' etc. don't push 'Alter::Dumper'";
    is grep( $_ eq 'Alter::Storable', @A2::ISA), 0,
        "'-storable' etc. don't push 'Alter::Storable'";
    is grep( $_ eq 'Alter::Dumper', @B::ISA), 1,
        "plain use pushes 'Alter::Dumper'";
    is grep( $_ eq 'Alter::Storable', @B::ISA), 1,
        "plain use pushes 'Alter::Storable'";
    if ( Alter::is_xs() ) {
        is grep( $_ eq 'Alter::Destructor', @B::ISA), 0,
            "plain use doesn't push 'Alter::Destructor' with XS"
    } else {
        is grep( $_ eq 'Alter::Destructor', @B::ISA), 1,
            "plain use pushes 'Alter::Destructor' with pure-perl"
    }

    BEGIN { $n_tests += 5 }
}

BEGIN { plan tests => $n_tests }
