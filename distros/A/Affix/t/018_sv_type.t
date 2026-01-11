use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
use Affix::Build;
use Config;
use ExtUtils::Embed;
#
diag $Config{shrpenv};
diag '$Config{useshrplib} claims to be ' . $Config{useshrplib};
$Config{useshrplib} eq 'true' || exit skip_all 'Cannot embed perl in a shared lib without building a shared libperl.';
eval {
    # See https://metacpan.org/release/RJBS/perl-5.36.0/view/INSTALL#Building-a-shared-Perl-library
    #
    # Compile C Library 1 (Basic Operations)
    my $lib
        = compile_ok( <<~'END', { cflags => ExtUtils::Embed::ccopts() . ' ' . ExtUtils::Embed::perl_inc(), ldflags => ExtUtils::Embed::ldopts(1) } );
        #include "std.h"
        //ext: .c
        #undef warn
        #include <EXTERN.h>
        #include <perl.h>
        static PerlInterpreter *my_perl;

        #define NO_XSLOCKS
        #include <XSUB.h>

        // Takes an SV*, increments it if it's an integer
        DLLEXPORT void inc_sv(SV* sv) {
            if (SvIOK(sv)) {
                int val = SvIV(sv);
                sv_setiv(sv, val + 1);
            }
        }

        // Returns a new SV* (Mortal)
        DLLEXPORT SV* make_sv(int val) {
            return sv_2mortal(newSViv(val));
        }
        END

    # Test Argument Passing (SV)
    # The signature "SV" maps to "SV*" in C because Affix detects the "SV" type name
    isa_ok my $inc = wrap( $lib, 'inc_sv', [ Pointer [SV] ] => Void ), ['Affix'];
    my $val = 10;
    $inc->($val);
    is $val, 11, 'Passed SV to C, modified in place';

    # Test Return Value (SV)
    isa_ok my $make = wrap( $lib, 'make_sv', [Int] => Pointer [SV] ), ['Affix'];
    my $res = $make->(42);
    is $res, 42, 'Received SV from C';

    # Test within Callbacks
    # Define a callback type that accepts and returns an SV*
    typedef CallbackSV => Callback [ [ Pointer [SV] ] => Pointer [SV] ];

    # We need a C function that takes this callback
    my $lib2
        = compile_ok( <<~'END', { cflags => ExtUtils::Embed::ccopts() . ' ' . ExtUtils::Embed::perl_inc(), ldflags => ExtUtils::Embed::ldopts(1) } );
        #include "std.h"
        //ext: .c
        #undef warn
        #include <EXTERN.h>
        #include <perl.h>
        static PerlInterpreter *my_perl;

        #define NO_XSLOCKS
        #include <XSUB.h>

        // Define a C function pointer type that matches the signature:
        // Pointer[SV] -> Pointer[SV]  ==  SV* (*)(SV*)
        typedef SV* (*cb_t)(SV*);

        DLLEXPORT int call_perl(cb_t cb, int val) {
            // Create a mortal SV to pass to the callback
            SV* arg = sv_2mortal(newSViv(val));

            // INVOKE THE CALLBACK DIRECTLY as a C function.
            // Do NOT use call_sv(); Affix handles the Perl context switching inside the trampoline 'cb'.
            SV* ret = cb(arg);

            // Extract the integer value from the returned SV
            return SvIV(ret);
        }
        END

    # Wrap the C function. Affix will automatically generate a trampoline for the coderef passed as 'cb'.
    isa_ok my $caller = wrap( $lib2, 'call_perl', [ CallbackSV(), Int ] => Int ), ['Affix'];
    my $cb = sub ($sv) {

        # Verify we received a scalar
        return $sv * 2;
    };
    is $caller->( $cb, 5 ), 10, 'Roundtrip SV through Callback';
};
done_testing;
