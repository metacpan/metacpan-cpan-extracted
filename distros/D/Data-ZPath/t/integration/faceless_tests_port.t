use Test2::V0;
use Test2::Require::Module 'CBOR::Free';
use Test2::Require::Module 'JSON::PP';
use Test2::Require::Module 'XML::LibXML';

use CBOR::Free;
use Data::Dumper;
use Data::ZPath;
use JSON::PP qw(decode_json);
use Scalar::Util qw(looks_like_number blessed);
use XML::LibXML;

my $tests_file = 't/share/tests.txt';
ok( -f $tests_file, 'upstream tests.txt exists in repository' ) or BAIL_OUT( 'missing tests file' );

open my $fh, '<', $tests_file or die "Unable to read $tests_file: $!";
my @lines = <$fh>;
close $fh;

my %roots;
my $mode;
my $current_case_mode;
my $buffer = '';
my @cases;

for my $idx ( 0 .. $#lines ) {
    my $line = $lines[$idx];
    chomp $line;

    if ( $line =~ /^---- BEGIN\s+(\w+)/ ) {
        $mode = uc $1;
        $current_case_mode = $mode;
        $buffer = '';
        next;
    }

    if ( defined $mode and $line =~ /^---- END/ ) {
        if ( $mode eq 'JSON' ) {
            $roots{JSON} = decode_json( $buffer );
        }
        elsif ( $mode eq 'XML' ) {
            $roots{XML} = XML::LibXML->load_xml( string => $buffer );
        }
        elsif ( $mode eq 'CBOR' ) {
            # tests.txt doesn't even contain real CBOR
            $roots{CBOR} = {
                tagged => CBOR::Free::Tagged->new(123, "John"),
                1      => 5,
            };
        }
        $mode = undef;
        next;
    }

    if ( defined $mode ) {
        $buffer .= "$line\n";
        next;
    }

    next if $line =~ /^\s*$/;
    next if $line =~ /^\s*#/;

    my ( $expr, $expect ) = split /\t+/, $line, 2;
    next unless defined $expr and defined $expect;

    $expr =~ s/^\s+|\s+$//g;
    $expect =~ s/\s+#.*$//;
    $expect =~ s/^\s+|\s+$//g;

    next unless length $expr;
    next unless length $expect;

    if ( $expect eq 'true' or $expect eq 'false' or $expect eq 'null' ) {
        $expect .= '()';
    }

    push @cases, {
        line    => $idx + 1,
        mode    => $current_case_mode,
        expr    => $expr,
        expect    => $expect,
    };
}

ok( scalar( @cases ) > 0, 'parsed cases from tests.txt' );

use Data::Dumper;
do {
    local $Data::Dumper::Sortkeys = 1;
#    my $node = Data::ZPath::Node->from_root( $roots{XML} );
#    diag Dumper( $node->dump );
};

for my $case ( @cases ) {
    my $label = sprintf '[%s:%d] %s => %s',
        $case->{mode},
        $case->{line},
        $case->{expr},
        $case->{expect};

    subtest $label => sub {
        if ( $case->{expect} eq 'ERROR' ) {
            like(
                dies { _run_expr( $case, { %roots, error => !!1 } ) },
                qr/.+/,
                'expression throws error'
            );
            return;
        }

        if ( $case->{expect} eq 'NULL' ) {
            my @actual = _run_expr( $case, \%roots, 'expr' );
            is( \@actual, [], 'no results found' );
            return;
        }

        my @actual   = _run_expr( $case, \%roots, 'expr' );
        my @expected = _run_expr( $case, \%roots, 'expect' );

        no warnings 'uninitialized';
        is( [ sort @actual ], [ sort @expected ], 'result tokens match upstream expectation' );
    };
}

done_testing;

sub _run_expr {
    my ( $case, $roots, $key ) = @_;
    $key ||= 'expr';
    my $root = $roots->{ $case->{mode} };
    my @raw;

    local $SIG{ALRM} = sub { fail "timed out"; die "timed out" };
    alarm 3;

    local $@;
    my $ok = eval {
        my $path = Data::ZPath->new( $case->{$key} );
        @raw = $path->evaluate( $root );
        1;
    };
    if (not $ok) {
        my $e = $@;
        diag "EXCEPTION FOR @{[ uc($key) ]}: $e" unless $roots->{error};
        die $e;
    }

    alarm 0;

    return map {
        my $val = $_->value;
        blessed($val) ? $_->string_value : $val;
    } @raw;
}
