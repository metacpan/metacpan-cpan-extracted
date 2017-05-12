use Test::More tests => 9;
use Dancer2::Template::TextTemplate::FakeEngine;

my $e = Dancer2::Template::TextTemplate::FakeEngine->new;

# Ensure that the "safe" features we're going to test are activated:
$e->safe(1);

# disabled to check the current default
#$e->safe_opcodes( [qw[ :default :load ]] );

# Enable "disposable" to compartment tests:
$e->safe_disposable(1);

# Disable "prepend" since it could interfere:
$e->prepend(0);

# Disable "caching" just to be sure:
$e->caching(0);

# Set our own delimiters just in case:
$e->delimiters( [ '{', '}' ] );

### Check that a basic template works
{
    my $template = <<'TEMPLATE_END';
hi
{
    for (1 .. 3) {
        $OUT .= "$_\n";
    }
}bye
TEMPLATE_END

    my $expected = <<'EXPECTED_END';
hi
1
2
3
bye
EXPECTED_END

    is $e->process( \$template ), $expected,
      'basic operations work in (:default + :load) Safe';
}

### Check that forbidden opcodes (for instance "open") are not accessible

my @opcodes = (
    { op => 'open',   tmpl => '{ my $var; open my $fh, ">", \$var }' },
    { op => 'eval',   tmpl => '{ use File::Temp (); File::Temp->newdir }' },
    { op => 'system', tmpl => '{ system("pwd") }' },
    {
        op   => 'mkdir',
        tmpl => '{ mkdir "fail_Dancer2-Template-TextTemplate-t-04_safe.t" }'
    },
);
for my $o (@opcodes) {
    like $e->process( \( $o->{tmpl} ) ),
      qr/'\Q$o->{op}\E.*?' trapped by operation mask\b/,
      qq{"$o->{op}" is trapped};
}

### Check that "safe_disposable" works
my $template = q<{ our $BEE; $BEE eq 'bzz' ? 'again?' : ( $BEE = 'bzz' ) }>;
my @disposable_cases = (
    { disposable => 1, first => 'bzz', second => 'bzz' },
    { disposable => 0, first => 'bzz', second => 'again?' },
);
for my $c (@disposable_cases) {

    $e->safe_disposable( $c->{disposable} );
    my $first  = $e->process( \$template );
    my $second = $e->process( \$template );

    is $first, $c->{first},
      "first pass as expected for 'safe_disposable: $c->{disposable}'";
    is $second, $c->{second},
      "second pass as expected for 'safe_disposable: $c->{disposable}'";
}

1;
