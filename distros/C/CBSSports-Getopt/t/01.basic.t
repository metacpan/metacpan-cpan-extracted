use Test::More tests => 7;

BEGIN { use_ok( 'CBSSports::Getopt' ); }

{
    my %opts = GetOptions();
    my $default_opts = {};
    is_deeply( \%opts, $default_opts, 'Defaults set correctly hash' );
}

{
    my $opts = GetOptions();
    my $default_opts = {};
    is_deeply( $opts, $default_opts, 'Defaults set correctly hash ref' );
}

{
    my $opts = GetOptions('t|test');
    my $compare_opts = {};
    is_deeply( $opts, $compare_opts, 'Able to add options' );
}

{
    local @ARGV;
    @ARGV = ('-t');
    my $opts = GetOptions('t|test');
    my $compare_opts = { test => 1 };
    is_deeply( $opts, $compare_opts, 'Pass in boolean option test' );
}

{
    local @ARGV;
    @ARGV = ( '-t', 'string' );
    my $opts = GetOptions('t|test=s');
    my $compare_opts = { test => 'string' };
    is_deeply( $opts, $compare_opts, 'Pass in string option test' );
}

{
    local @ARGV;
    @ARGV = ( '-v', '-v' );
    my $opts = GetOptions();
    my $compare_opts = { verbose => 2 };
    is_deeply( $opts, $compare_opts, 'Verify incrental verbose' );
}

