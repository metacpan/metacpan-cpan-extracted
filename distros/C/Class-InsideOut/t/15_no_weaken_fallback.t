use strict;
use lib ".";
use Test::More;

$|++; # keep stdout and stderr in order on Win32

# Devel::Cover doesn't seem to actually track coverage for the hacks
# used here, so we'll skip it.
if ( $ENV{HARNESS_PERL_SWITCHES} &&
     $ENV{HARNESS_PERL_SWITCHES} =~ /Devel::Cover/ ) {
    plan skip_all => 
        "no_weaken_fallback tests not compatible with Devel::Cover";
}

# find what Scalar::Util we have
my $rc = system($^X, '-e', 'use Scalar::Util; Scalar::Util->VERSION(1.2303)');
if ( ! $rc ) {
    plan skip_all => 
        "Your Scalar::Util is XS only";
}

# Overload DynaLoader and XSLoader to fake lack of XS for Scalar::Util
# (which actually calls List::Util)
BEGIN {
    no strict 'refs';
    local $^W;
    require DynaLoader;
    my $bootstrap_orig = *{"DynaLoader::bootstrap"}{CODE};
    *DynaLoader::bootstrap = sub {
        die if $_[0] =~ /(Scalar|List)::Util/;
        goto $bootstrap_orig;
    };
    # XSLoader entered Core in Perl 5.6
    if ( $] >= 5.006 ) {
        require XSLoader;
        my $xsload_orig = *{"XSLoader::load"}{CODE};
        *XSLoader::load = sub {
            die if $_[0] =~ /(Scalar|List)::Util/;
            goto $xsload_orig;
        };
    }
}

plan tests => 3;

#--------------------------------------------------------------------------#

my $class = "t::Object::Trivial";

#--------------------------------------------------------------------------#

my $warning;

{
    local $^W = 1;
    local $SIG{__WARN__} = sub { $warning = shift };
    eval "require $class";
}

is( $@, q{}, 
    "require $class succeeded without XS" 
);
ok( $warning, "caught a warning" );
like( $warning, '/Scalar::Util::weaken/', 
    "Saw warning for Scalar::Util::weaken unavailable"
);
