use warnings; use strict;
use Test::More;
my $n_tests;

# Class_A is a conventional hash-based class with two fields one_A and two_A
# Class_B is an Alter-based class with fields of one_B and two_B stored in an
# array.
# Both classes have an init() method that works as a creator when called
# as a class method. There are read-only accessors to the fields

# Class_C is a hybrid class inheriting both Class_A and Class_B
# For tests we set fields one_A and one_B to plain scalars.  two_A
# and two_B are set to hold a reference to the same array.  This identity
# must survive a freeze-thaw cycle by either Data::Dumper or Storable

### Class_A

{
    package Class_A;

    sub init {
        my $obj = shift;
        $obj = bless {}, $obj unless ref $obj;
        $obj->{ one_A} = shift;
        $obj->{ two_A} = shift;
        $obj;
    }

    sub one_A { $_[ 0]->{ one_A} }
    sub two_A { $_[ 0]->{ two_A} }
}

{
    my ( $one, $two) = ( 'haha', []);
    my $ca = Class_A->init( $one, $two);

    is $ca->one_A, $one, "Class_A field 'one_A'";
    is $ca->two_A, $two, "Class_A field 'two_A'";

    BEGIN { $n_tests += 2 }
}

### Class_B
{
    package Class_B;
    use Alter ego => [];

    sub init {
        my $obj = shift;
        $obj = bless \ my( $o), $obj unless ref $obj;
        my $ego = ego( $obj);
        $ego->[ 0] = shift;
        $ego->[ 1] = shift;
        $obj;
    }

    sub one_B { ego( $_[ 0])->[ 0] }
    sub two_B { ego( $_[ 0])->[ 1] }
}

{
    my ( $one, $two) = ( 'haha', []);
    my $cb = Class_B->init( $one, $two);

    is $cb->one_B, $one, "Class_B field 'one_B'";
    is $cb->two_B, $two, "Class_B field 'two_B'";

    BEGIN { $n_tests += 2 }
}

### Class_C
{
    package Class_C;
    use base 'Class_A';
    use base 'Class_B';

    sub init {
        my $obj = shift;
        my ( $one_A, $two_A, $one_B, $two_B) = @_;
        $obj = $obj->Class_A::init() unless ref $obj;
        $obj->Class_A::init( $one_A, $two_A);
        $obj->Class_B::init( $one_B, $two_B);
    }
}

### Basic class functionality, under thread if avalable
{
    my $ref = [];
    my ( $one_A, $two_A) = ( 'haha', $ref);
    my ( $one_B, $two_B) = ( 'hihi', $ref);

    my $cc = Class_C->init( $one_A, $two_A, $one_B, $two_B);

    is $cc->one_A, $one_A, "Class_C field 'one_A'";
    is $cc->two_A, $two_A, "Class_C field 'two_A'";
    is $cc->one_B, $one_B, "Class_C field 'one_B'";
    is $cc->two_B, $two_B, "Class_C field 'two_B'";

    SKIP: {
        use Config;
        skip "No thread support", 5 + 4 unless $Config{ usethreads};
        require threads;
        treads->import if threads->can( 'import');

        my $ans = threads->create(
            sub {
                {
                    one_A         => $cc->one_A,
                    two_A         => $cc->two_A,
                    one_B         => $cc->one_B,
                    two_B         => $cc->two_B,
                    ref_in_thread => $ref,
                };
            }
        )->join;

        my $ref_in_thread = $ans->{ ref_in_thread};

        # Did object data make it into thread?
        isnt $ref_in_thread, $ref, "In thread: ref is different";
        is $ans->{ one_A}, $one_A, "In thread: Class_C field 'one_A'";
        is $ans->{ two_A}, $ref_in_thread, "In thread: Class_C field 'two_A'";
        is $ans->{ one_B}, $one_B, "In thread: Class_C field 'one_B'";
        is $ans->{ two_B}, $ref_in_thread, "In thread: Class_C field 'two_B'";

        # repeat basic tests after thread has run
        is $cc->one_A, $one_A, "After thread: Class_C field 'one_A'";
        is $cc->two_A, $two_A, "After thread: Class_C field 'two_A'";
        is $cc->one_B, $one_B, "After thread: Class_C field 'one_B'";
        is $cc->two_B, $two_B, "After thread: Class_C field 'two_B'";
    } # end of SKIP block
    
    BEGIN { $n_tests += 4 + 5 + 4 }
}

### Storable with STORABLE_attach
# ... if available, otherwise STORABLE_thaw is tested (and again below)

{
    use Storable;
    use constant HAS_ATTACH => 2.14; # first Storable version with attach

    my ( $one_A, $two_A) = ( 'haha', []);
    my ( $one_B, $two_B) = ( 'hihi', $two_A);

    my $cc = Class_C->init( $one_A, $two_A, $one_B, $two_B);
    $Alter::Storable::attaching = 0;
    $Alter::Storable::thawing   = 0;
    my $clone = Storable::thaw( Storable::freeze( $cc));

    my $attach_ok;
    if ( $Storable::VERSION < HAS_ATTACH ) {
        # Storable only recogizese STORABLE_thaw
        ok $Alter::Storable::thawing,    "STORABLE_thaw being used";
        ok !$Alter::Storable::attaching, "STORABLE_attach not used";
        $attach_ok = $Alter::Storable::thawing && !$Alter::Storable::attaching;
    } else {
        # Storable knows about STORABLE_attach
        ok $Alter::Storable::attaching, "STORABLE_attach being used";
        ok !$Alter::Storable::thawing, "STORABLE_thaw not used";
        $attach_ok = !$Alter::Storable::thawing && $Alter::Storable::attaching;
    }
    diag "Storable $Storable::VERSION" unless $attach_ok;

    is $clone->one_A, $one_A, "Cloned one_A (attach)";
    is $clone->one_B, $one_B, "Cloned one_B (attach)";
    isnt $clone->two_A, $two_A, "Cloned ref different (attach)";
    is ref $clone->two_A, 'ARRAY', "Cloned ref type (attach)";
    is $clone->two_B, $clone->two_A, "Cloned ref identity (attach)";

    BEGIN { $n_tests += 7 }
}

### Storable with STORABLE_thaw
{   # reconfig Class_B to use STORABLE_thaw
    package Class_B;
    use Alter qw(STORABLE_thaw STORABLE_freeze);
    our @ISA;
    @ISA = grep !/Storable/ => @ISA; # this makes the difference
}

{
    use Storable;

    my ( $one_A, $two_A) = ( 'haha', []);
    my ( $one_B, $two_B) = ( 'hihi', $two_A);

    my $cc = Class_C->init( $one_A, $two_A, $one_B, $two_B);
    $Alter::Storable::attaching = 0;
    $Alter::Storable::thawing   = 0;
    my $clone = Storable::thaw( Storable::freeze( $cc));

    ok $Alter::Storable::thawing,   "STORABLE_thaw being used";
    ok !$Alter::Storable::attaching, "STORABLE_attach not used";
    is $clone->one_A, $one_A, "Cloned one_A (thaw)";
    is $clone->one_B, $one_B, "Cloned one_B (thaw)";
    isnt $clone->two_A, $two_A, "Cloned ref different (thaw)";
    is ref $clone->two_A, 'ARRAY', "Cloned ref type (thaw)";
    is $clone->two_B, $clone->two_A, "Cloned ref identity (thaw)";

    BEGIN { $n_tests += 7 }
}

### Dumper
{
    use Data::Dumper;

    my ( $one_A, $two_A) = ( 'haha', []);
    my ( $one_B, $two_B) = ( 'hihi', $two_A);

    my $cc = Class_C->init( $one_A, $two_A, $one_B, $two_B);
    my $dump = $cc->Dumper;

#   diag $dump;
    my $image = do {
        my $VAR1;
        eval $dump;
        $VAR1;
    };
    diag "$@" if $@;

    my $body = $image->{ Alter::BODY()};
    my $soul = $image->{ Class_B};
    isa_ok $body, 'Class_C', "Dumper body";
    is ref $soul, "ARRAY", "Dumper soul is hash";
    is $body->{ one_A}, $one_A, "Dumper one_A";
    is $soul->[ 0], $one_B, "Dumper one_B";
    isnt $body->{ two_A}, $two_A, "Dumper evaled ref different";
    is ref $body->{ two_A}, 'ARRAY', "Dumper two_A is array";
    is $soul->[ 1], $body->{ two_A}, "Dumper ref identity";
    BEGIN { $n_tests += 7 }
}

BEGIN { plan tests => $n_tests }
