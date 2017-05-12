use Test::More tests => 67;
BEGIN { use_ok 'Algorithm::CheckDigits' };

my $sedol = CheckDigits( 'sedol' );
isa_ok( $sedol, 'Algorithm::CheckDigits' );

my %sedols = (
              228276 => 5,
              232977 => 0,
              406566 => 3,
              557910 => 7,
              585284 => 2,
              710889 => 9,
              B00030 => 0,
              B01841 => 1,
              B0YBKJ => 7,
              B0YBKL => 9,
              B0YBKR => 5,
              B0YBKT => 7,
              B0YBLH => 2,
);

for my $base ( sort keys %sedols )
{
    my $check = $sedols{$base};
    my $full = $base . $check;

    is $sedol->complete( $base ), $full, "$base -> $full";
    ok $sedol->is_valid( $full ), "$full is valid";
    is $sedol->basenumber( $full ), $base,  "$full base is $base";  
    is $sedol->checkdigit( $full ), $check, "$full check is $check";

    my $bad = $base . ($check eq '0' ? '1' : '0');
    ok !$sedol->is_valid( $bad ), "$bad has wrong check digit";
}
