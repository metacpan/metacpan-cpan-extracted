use v5.40;
use blib;
use Affix::Wrap;
use Test2::Tools::Affix qw[:all];
use Path::Tiny;

#~ use Capture::Tiny qw[capture];
# Determine if Clang is available
my $CLANG_AVAIL = do {
    my ( undef, undef, $exit ) = capture { system 'clang', '--version' };
    $exit == 0;
};

sub spew_files ( $dir, %files ) {
    $dir->child($_)->spew_utf8( $files{$_} ) for keys %files;
    $dir;
}

sub run_tests_for_driver ( $driver_class, $label ) {
    subtest 'Driver: ' . $label => sub {
        subtest 'Preprocessor & Defines' => sub {
            my $dir = Path::Tiny->tempdir;
            spew_files(
                $dir,
                'defs.h' => <<'EOF',
/** @brief Buffer Size */
#define BUF_SIZE 1024
#define API_NAME "MyLib"
#define CALC_VAL (10 + 20)
EOF
                'main.c' => '#include "defs.h"'
            );
            my $parser = $driver_class->new( project_files => [ $dir->child('defs.h')->stringify ] );
            my @objs   = $parser->parse( $dir->child('main.c')->stringify, [ $dir->stringify ] );
            my ($buf)  = grep { $_->name eq 'BUF_SIZE' } @objs;
            ok( $buf, 'Found BUF_SIZE' );
            is( $buf->value, '1024', 'BUF_SIZE value' );
            like( $buf->doc, qr/Buffer Size/, 'BUF_SIZE doc' );
            my ($calc) = grep { $_->name eq 'CALC_VAL' } @objs;
            ok( $calc, 'Found CALC_VAL' );

            # affix_type should quote expressions: '(10 + 20)' -> "'(10 + 20)'" or similar
            like( $calc->affix_type, qr/'?\(10 \+ 20\)'?/, 'Expression quoted in affix_type' );
        };
        subtest 'Records (Structs & Unions)' => sub {
            my $dir = Path::Tiny->tempdir;
            spew_files(
                $dir,
                'structs.h' => <<'EOF',
/** @brief A Point */
typedef struct {
    int x;
    int y;
} Point;

typedef struct {
    int id;
    union {
        int i;
        float f;
    } payload;
} Packet;
EOF
                'main.c' => '#include "structs.h"'
            );
            my $parser = $driver_class->new( project_files => [ $dir->child('structs.h')->stringify ] );
            my @objs   = $parser->parse( $dir->child('main.c')->stringify, [ $dir->stringify ] );

            # Check Point (Expect Typedef -> Struct)
            my ($pt_td) = grep { $_->name eq 'Point' && $_->isa('Affix::Wrap::Typedef') } @objs;
            ok( $pt_td, 'Found Point Typedef' );
            my $pt = $pt_td->underlying;
            isa_ok( $pt, ['Affix::Wrap::Struct'], 'Underlying is Struct' );
            like( $pt_td->doc, qr/A Point/, 'Point doc found on typedef' );
            is( $pt->members->[0]->name,             'x',   'Member x name' );
            is( $pt->members->[0]->type->affix_type, 'Int', 'Member x is Int' );

            # Check Packet
            my ($pkt_td) = grep { $_->name eq 'Packet' } @objs;
            my $pkt = $pkt_td->underlying;
            ok( $pkt, 'Found Packet Struct' );
            is( $pkt->members->[0]->name, 'id',      'Member 0: id' );
            is( $pkt->members->[1]->name, 'payload', 'Member 1: payload' );

            # Check Nested Union
            my $u_mem = $pkt->members->[1];

            # The member type is technically empty/void in C AST often, but it has a definition
            ok( $u_mem->definition, 'Payload has definition' );
            my $u = $u_mem->definition;
            if ($u) {
                is( $u->tag,                            'union', 'Payload is union tag' );
                is( $u->members->[0]->name,             'i',     'Union mem 0: i' );
                is( $u->members->[1]->type->affix_type, 'Float', 'Union mem 1 is Float' );
                like( $u->affix_type, qr/^Union\[/, 'Generates Union[...] signature' );
            }
        };
        subtest Enums => sub {
            my $dir = Path::Tiny->tempdir;
            spew_files(
                $dir,
                'enums.h' => <<'EOF',
enum State {
    IDLE,
    RUNNING = 5,
    STOPPED
};
EOF
                'main.c' => '#include "enums.h"'
            );
            my $parser = $driver_class->new( project_files => [ $dir->child('enums.h')->stringify ] );
            my @objs   = $parser->parse( $dir->child('main.c')->stringify, [ $dir->stringify ] );
            my ($st)   = grep { $_->name eq 'State' } @objs;
            ok( $st, 'Found State enum' );
            my $c = $st->underlying->constants;
            is( $c->[0]{name},  'IDLE',    'IDLE' );
            is( $c->[1]{name},  'RUNNING', 'RUNNING' );
            is( $c->[1]{value}, 5,         'RUNNING=5' );

            # STOPPED should be 6 (implicit) or undefined depending on driver logic,
            # but current logic calculates it or leaves it to C.
            # Let's check the affix_type string generation
            my $sig = $st->affix_type;
            like( $sig, qr/IDLE/,         'IDLE in sig' );
            like( $sig, qr/RUNNING => 5/, 'RUNNING in sig' );
        };
        subtest 'Functions & Variables' => sub {
            my $dir = Path::Tiny->tempdir;
            spew_files(
                $dir,
                'funcs.h' => <<'EOF',
int calc(int a);
extern double global_val;
void cb_test(void (*callback)(int));
EOF
                'main.c' => '#include "funcs.h"'
            );
            my $parser = $driver_class->new( project_files => [ $dir->child('funcs.h')->stringify ] );
            my @objs   = $parser->parse( $dir->child('main.c')->stringify, [] );

            # Function
            my ($f1) = grep { $_->name eq 'calc' } @objs;
            ok( $f1, 'Found function calc' );
            is( $f1->ret->affix_type, 'Int', 'Ret Int' );
            is( $f1->args->[0]->name, 'a',   'Arg name a' );

            # Variable
            my ($var) = grep { $_->name eq 'global_val' } @objs;
            ok( $var, 'Found global_val' );
            isa_ok( $var, ['Affix::Wrap::Variable'] );
            is( $var->type->affix_type, 'Double', 'Variable is Double' );

            # CodeRef / Callback
            my ($cb_func) = grep { $_->name eq 'cb_test' } @objs;
            ok( $cb_func, 'Found cb_test' );
            my $arg0 = $cb_func->args->[0];
            isa_ok( $arg0->type, ['Affix::Wrap::Type::CodeRef'], 'Arg is CodeRef' );
            if ( $arg0->type->isa('Affix::Wrap::Type::CodeRef') ) {
                is( $arg0->type->ret->affix_type,         'Void',                    'Callback returns Void' );
                is( $arg0->type->params->[0]->affix_type, 'Int',                     'Callback takes Int' );
                is( $arg0->type->affix_type,              'Callback[[Int] => Void]', 'Signature matches' );
            }
        };
        subtest 'Complex Types' => sub {
            my $dir = Path::Tiny->tempdir;
            spew_files(
                $dir,
                'edge.h' => <<'EOF',
typedef struct {
    int data[16];
    char* name;
    float matrix[4][4];
} Buffer;
EOF
                'main.c' => '#include "edge.h"'
            );
            my $parser   = $driver_class->new( project_files => [ $dir->child('edge.h')->stringify ] );
            my @objs     = $parser->parse( $dir->child('main.c')->stringify, [ $dir->stringify ] );
            my ($buf_td) = grep { $_->name eq 'Buffer' } @objs;
            ok $buf_td, 'Found Buffer Typedef';
            my $buf = $buf_td->underlying;
            if ($buf) {
                my $m0 = $buf->members->[0];    # int data[16]
                isa_ok( $m0->type, ['Affix::Wrap::Type::Array'], 'Member 0 is Array' );
                is( $m0->type->count,      16,               'Array count 16' );
                is( $m0->type->affix_type, 'Array[Int, 16]', 'Affix Sig: Array[Int, 16]' );
                my $m1 = $buf->members->[1];    # char* name
                isa_ok( $m1->type, ['Affix::Wrap::Type::Pointer'], 'Member 1 is Pointer' );
                is( $m1->type->affix_type, 'Pointer[Char]', 'Affix Sig: Pointer[Char]' );
                my $m2 = $buf->members->[2];    # float matrix[4][4]
                isa_ok( $m2->type, ['Affix::Wrap::Type::Array'], 'Member 2 is Array' );
                is( $m2->type->affix_type, 'Array[Array[Float, 4], 4]', '2D Array Affix Sig' );
            }
        };
        subtest 'Compile -> Bind -> Affix' => sub {
            use v5.40;
            use Affix;
            use Affix::Build;
            use Affix::Wrap;
            #
            my $src = <<~'';
                //ext: .c
                int return_six() { return 6; }

            my $dir = Path::Tiny->tempdir;
            spew_files( $dir, 'main.c' => $src );
            my $lib = compile_ok($src);
            my $pkg = $driver_class eq 'Affix::Wrap::Driver::Clang' ? 'Testing_clang' : 'Testing_regex';
            #
            my $binder = Affix::Wrap->new(
                driver       => $driver_class->new( project_files => [ $dir->child('main.c')->stringify ] ),
                include_dirs => [ './t/src', 'src', 'C:\Users\S\Documents\GitHub\Affix.pm\t\src' ]
            );
            $binder->wrap( $lib, $pkg );
            #
            is $pkg->can('return_six')->(), 6, 'returned 6';
        };
    };
}
run_tests_for_driver( 'Affix::Wrap::Driver::Clang', 'Clang System' ) if $CLANG_AVAIL;
run_tests_for_driver( 'Affix::Wrap::Driver::Regex', 'Regex System (Fallback)' );
done_testing();
