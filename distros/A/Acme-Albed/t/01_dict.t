use strict;
use Test::More;
use Acme::Albed;

my $albed = Acme::Albed->new;
my $dic = $albed->dict;

# from/to albedian
# die Dumper $dic;
for my $key ( keys %$dic ) {
    my @char_ja = split //, $dic->{$key}->{before};
    my @char_al = split //, $dic->{$key}->{after};
    foreach my $i ( 0 .. $#char_ja ) {
        is( $albed->to_albed( $char_ja[$i] ), $char_al[$i] );
        is( $albed->from_albed( $char_al[$i] ), $char_ja[$i] );
    }
}

# undef
is( $albed->to_albed( undef ), undef );
is( $albed->from_albed( undef ), undef );

# \t\s\n
is( $albed->to_albed(" "), " " );
is( $albed->to_albed("	"), "	" );
is(
    $albed->to_albed( "
" ),
    "
"
);

# Words
for my $key ( keys %$dic ) {
    is ( $albed->to_albed( $dic->{$key}->{before} ) , $dic->{$key}->{after} );
    is ( $albed->from_albed( $dic->{$key}->{after} ) , $dic->{$key}->{before} );
}

done_testing();
