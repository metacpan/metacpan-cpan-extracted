use strict;
use lib ".";
use Test::More;

# keep stdout and stderr in order on Win32

BEGIN {
    $|=1; 
    my $oldfh = select(STDERR); $| = 1; select($oldfh);
}

#--------------------------------------------------------------------------#

my $class = "t::Object::HookedTT";
my $properties = {
    $class => {
        integer   => "public",
        uppercase => "public",
        word      => "public",
        list      => "public",
        reverser  => "public",
        write_only => "public",
    },
};

    
my ($o, @got, $got);

BEGIN {
    my $has_tt = eval 'use 5.008003; require Type::Tiny;';
    $has_tt or plan skip_all => 'test requires Perl 5.8.3 and Type::Tiny';
}

#--------------------------------------------------------------------------#

plan tests => 20;

require_ok( $class );

is_deeply( Class::InsideOut::_properties( $class ), 
           $properties,
    "$class has/inherited its expected properties"
);

ok( ($o = $class->new()) && $o->isa($class),
    "Creating a $class object"
);

#--------------------------------------------------------------------------#

eval { $o->integer(3.14) };
my $err = $@;
like( $err, '/integer\(\) value "3.14" did not pass type constraint "Int"/i',
    "integer(3.14) dies"
);

eval { $o->integer(42) };
is( $@, q{},
    "integer(42) lives"
);
is( $o->integer, 42,
    "integer() == 42"
);

#--------------------------------------------------------------------------#

eval { $o->word("^^^^") };
like( $@, '/word\(\) value "\^\^\^\^" did not pass type constraint/i',
    "word(^^^^) dies"
);
eval { $o->word("apple") };
is( $@, q{},
    "word(apple) lives"
);
is( $o->word, 'apple',
    "word() eq 'apple'"
);

#--------------------------------------------------------------------------#

eval { $o->uppercase("banana") };
is( $@, q{},
    "uppercase(banana) lives"
);
is( $o->uppercase, 'BANANA',
    "uppercase() eq 'BANANA'"
);

#--------------------------------------------------------------------------#

# list(@array)

eval { $o->list(qw(foo bar bam)) };
is( $@, q{},
    "list(qw(foo bar bam)) lives"
);
is_deeply( [ $o->list ], [qw(foo bar bam)],
    "list() gives qw(foo bar bam)"
);

# list(\@array)

eval { $o->list( [qw(foo bar bam)] ) };
is( $@, q{},
    "list( [qw(foo bar bam)] ) lives"
);
is_deeply( [ $o->list ], [qw(foo bar bam)],
    "list() gives qw(foo bar bam)"
);

#--------------------------------------------------------------------------#

eval { $o->reverser(qw(foo bar bam)) };
is( $@, q{},
    "reverser(qw(foo bar bam)) lives"
);

# reverser in list context
@got = $o->reverser;
is_deeply( \@got, [qw(bam bar foo)],
    "reverser() in list context gives qw(bam bar foo)"
);

# reverser in scalar context
$got = $o->reverser;
is( $got, 'mabraboof',
    "reverser() in scalar context gives mabraboof"
);

#--------------------------------------------------------------------------#

eval { $o->write_only( 23 ) };
is( $@, q{},
    "write_only lives on write"
);

eval { $got = $o->write_only() };
like( $@, '/write_only\(\) is write-only at/i',
    "write only dies on write (and was caught)"
);

