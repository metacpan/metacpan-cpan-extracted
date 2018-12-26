#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::PasswordPolicy' );
}

my $module = 'Data::Validate::WithYAML::Plugin::PasswordPolicy';

{
    my @passwords = qw(test q 0 -1 averylongpasswordtocheck A62348$!);
    my @blacklist = (undef, '');

    for my $password ( @passwords ){
        ok( $module->check($password), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3'};
    my @passwords = qw(000 hel tes);
    my @blacklist = (undef, '', 0, 'test', 'averylongpasswordtocheck','A62348$!');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3,'};
    my @passwords = qw(000 hel tes averylongpasswordtocheck A223523$!$);
    my @blacklist = (undef, '', 0, 'AA', 'z7', '&1');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3,5'};
    my @passwords = qw(000 hel tes test teste 7231 38193 A83$! A$!§ !_"$%);
    my @blacklist = (undef, '', 0, 'AA', 'z7', '&1', 124325, 'tester', '31$!$!$"');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3', chars => ['A-Z']};
    my @passwords = qw(AAA BAZ DEF KIL);
    my @blacklist = (undef, '', 0, 'test', 'averylongpasswordtocheck','A62348$!', 'tes', 'AA', 'RZSHSA', 'teester', 123, 1234);

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3,', chars => ['A-z', '1-3']};
    my @passwords = qw(A11 hel1 tAESSD2es averylongpasswordtoc3eck A223523 SH"%d1);
    my @blacklist = (undef, '', 0, 'AA', 'z7', '&1', '235', 'ASF', 'ASFW$"ds');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3,5', chars => 'A-Z'};
    my @passwords = qw(A$!§ AZEVJ aaHH AAA aaA I135);
    my @blacklist = (undef, '', 0, 'AA', 'z7', '&1', 124325, 'tester', '31$!$!$"');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3,5', chars_blacklist => 'A-Z'};
    my @passwords = qw($!§ "$!! aa$$ 123 aaxxs i135);
    my @blacklist = (undef, '', 0, 'AA', 'z7', '&1', 124325, 'tester', '31$!$!$"', 'AAA', 'PEIVA', 'P135');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => '3,5', chars_blacklist => ['A-Z']};
    my @passwords = qw($!§ "$!! aa$$ 123 aaxxs i135);
    my @blacklist = (undef, '', 0, 'AA', 'z7', '&1', 124325, 'tester', '31$!$!$"', 'AAA', 'PEIVA', 'P135');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my @passwords = qw($!§ "$!! aa$$ 123 aaxxs i135);
    my @blacklist = (0, 'AA', 'z7', '&1', 124325, 'tester', '31$!$!$"', 'AAA', 'PEIVA', 'P135');

    for my $password ( @passwords, @blacklist ){
        ok( $module->check($password, {}), "test: $password -> " . flatten($config) );
    }

    ok !$module->check( '', {} );
    ok !$module->check( undef, {} );
}

{
    my @passwords = qw($!§ "$!! aa$$ 123 aaxxs i135);
    my @blacklist = (0, 'AA', 'z7', '&1', 124325, 'tester', '31$!$!$"', 'AAA', 'PEIVA', 'P135');

    for my $password ( @passwords, @blacklist ){
        ok( $module->check($password, { 'x-policy' => {} }), "test: $password -> " . flatten($config) );
    }

    ok !$module->check( '', { 'x-policy' => {} } );
    ok !$module->check( undef, { 'x-policy' => {} } );
}

{
    my $config    = {length => '5'};
    my @passwords = qw($!baz "b$!! aa$-$ 12345 aaxxs ai135);
    my @blacklist = (undef, '', 0, 'AA', 'z7', '&1', 124325, 'tester', '31$!$!$"', 'AAA', 'P135');

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {chars => ['A-Z']};
    my @passwords = qw(A AB AAA BAZ DEF KIL);
    my @blacklist = (undef, '', 0, 'test', 'averylongpasswordtocheck','62348$!', 'tes', 'teester', 123, 1234);

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

{
    my $config    = {length => ','};
    my @passwords = qw($!baz "b$!! aa$-$ 12345 aaxxs ai135);
    my @blacklist = (undef, '', );

    for my $password ( @passwords ){
        ok( $module->check($password, {'x-policy' => $config}), "test: $password -> " . flatten($config) );
    }

    for my $check ( @blacklist ){
        my $retval = $module->check( $check, {'x-policy' => $config} );
        ok( !$retval, "test: $check -> " .  flatten($config) );
    }
}

done_testing();

sub flatten {
    my $data = shift;

    my $string = '';

    if ( ref $data eq 'HASH' ) {
        my @items;

        for my $key ( keys %{$data} ) {
            push @items, "$key => " . flatten( $data->{$key} );
        }

        $string = '{ ' . join( ', ', @items ) . ' }';
    }
    elsif ( ref $data eq 'ARRAY' ) {
        my @items;

        for my $item ( @{$data} ) {
            push @items, flatten( $item );
        }

        $string = '[ ' . join( ', ', @items ) . ' ]';
    }
    else {
        return "'" . $data . "'";
    }

    return $string;
}
