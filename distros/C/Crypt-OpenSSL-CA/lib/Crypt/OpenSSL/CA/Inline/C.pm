#!perl -w
# -*- coding: utf-8; -*-

use strict;
use warnings;

package Crypt::OpenSSL::CA::Inline::C;

=head1 NAME

Crypt::OpenSSL::CA::Inline::C - A bag of XS and L<Inline::C> tricks

=encoding utf8

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  package Crypt::OpenSSL::CA::Foo;

  use Crypt::OpenSSL::CA::Inline::C <<"C_CODE_SAMPLE";
  #include <openssl/x509.h>

  static
  SV* mysub() {
    // Your C code here
  }

  C_CODE_SAMPLE

  # Then maybe some Perl...

  use Crypt::OpenSSL::CA::Inline::C <<"MORE_C_CODE";

  static
  void another() {
    // ...
  }

  MORE_C_CODE

  use Crypt::OpenSSL::CA::Inline::C "__END__";

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

B<This documentation is only useful for people who want to hack
I<Crypt::OpenSSL::CA>. It is of no interest for people who just want
to use the module.>

This package provides L<Inline::C> goodness to L<Crypt::OpenSSL::CA>
during development, plus a few tricks of our own.  The idiom in
L</SYNOPSIS>, used throughout the source code of
L<Crypt::OpenSSL::CA>, recaps them all; noteworthy points are:

=over

=item the C<static>-newline trick

Because the C language doesn't have namespaces, we don't want symbols
named e.g. C<new> appearing in the .so's symbol tables: they could
clash with other symbols defined by Perl, or with each other.
Therefore we have to declare them C<static>, but doing this in the
naïve way would cause L<Inline::C> to purposefully B<not> bind them
with Perl... The winning trick is to put the C<static> word alone on
its line, as demonstrated.

=item the "__END__" pragma

The code in L<Crypt::OpenSSL::CA> must use the following pragma to
signal that it won't attempt to add any L<Inline::C> code after this
point:

   use Crypt::OpenSSL::CA::Inline::C "__END__";

=back

=head2 Standard Library

In addition to the standard library available to XS C code described
in L<Inline::C>, L<perlxstut>, L<perlguts> and L<perlapi>, C code that
compiles itself through I<Crypt::OpenSSL::CA::Inline::C> has access to
the following C functions:

=head3 char0_value

  static inline char* char0_value(SV* string);

Returns the string value of a Perl SV, making sure that it exists and is
zero-terminated beforehand. If C<string> is undef, returns the empty string
(B<not> NULL; see L</char0_value_or_null>). If C<string> is tainted, that makes
no difference; return it, or the empty string, just the same. See
L<perlguts/Working with SVs>, look for the word "Nevertheless" - I assume
there is a macro in Perl's convenience stuff that does exactly that already, but
I don't know it...

=head3 char0_value_or_null

  static inline char* char0_value_or_null(SV* string);

Like L</char0_value>, except that NULL is returned if C<string> is
undef.

=head3 perl_wrap

   static inline SV* perl_wrap(class, pointer);

Creates read-only SV containing the integral value of C<pointer>,
blesses it into class C<class> and returns it as a SV*.  The return
value is an adequate Perl wrapper to stand for C<pointer>, as
demonstrated in L<Inline::C-Cookbook/Object Oriented Inline>.

=head3 perl_unwrap (class, typename, SV*)

The reverse of L</perl_wrap>.  Given a L</perl_wrap>ped SV*, asserts
that it actually contains an object blessed in class C<class> (lest it
C<croak>s), extracts the pointer within same, casts it into
C<typename> and returns it.  This is a macro instead of a static
inline, so as to be able to perform the polymorphic cast.

=head3 openssl_string_to_SV

  static inline SV* openssl_string_to_SV(char* string);

Copies over C<string> to a newly-allocated C<SV*> Perl scalar, and
then frees C<string> using C<OPENSSL_free()>.  Used to transfer
ownership of strings from OpenSSL to Perl, and thereby ensure proper
memory management.

Note to I<Crypt::OpenSSL::CA> hackers: if C<string> is on an OpenSSL
static buffer instead of having been allocated by OpenSSL, this will
SEGV in trying to free() C<string> that was not malloc()'d; in this
case you want to use L<perlapi/XSRETURN_PV> instead or some such.
Check the OpenSSL documentation carefully, and make use of
L<Crypt::OpenSSL::CA::Test/leaks_bytes_ok> to ascertain experimentally
that your code doesn't leak memory.

=head3 openssl_buf_to_SV

   static inline SV* openssl_buf_to_SV(char* string, int length);

Like L</openssl_string_to_SV> except that the length is specified,
which allows for C<string> to not contain null characters or not be
zero-terminated.  Use this form e.g. for ASN.1 buffers returned by
C<i2d_foobar> OpenSSL functions.

=head3 BIO_mem_to_SV

   static inline SV* BIO_mem_to_SV(BIO *bio);

This inline function is intended to be used to return scalar values
(e.g. PEM strings and RSA moduli) constructed by OpenSSL.  Should be
invoked thusly, after having freed all temporary resources except
*bio:

   return BIO_mem_to_SV(bio);

I<BIO_mem_to_SV()> turns bio into a Perl scalar and returns it, or
C<croak()>s trying (hence the requirement not to have any outstanding
memory resources allocated in the caller).  Regardless of the outcome,
C<bio> will be C<BIO_free>()d.

=head2 sslcroak

   static void sslcroak(char *format, ...);

Like L<perlapi/croak>, except that a blessed exception of class
I<Crypt::OpenSSL::CA::Error> is generated.  The OpenSSL error
stack, if any, gets recorded as an array reference inside the
exception structure.

Note to I<Crypt::OpenSSL::CA> hackers: please select the appropriate
routine between I<sslcroak> and I<croak>, depending on whether the
current error condition is being caused by OpenSSL or not; in this way
callers are able to discriminate errors.  Also, don't be fooled into
thinking that C<croak>-style error management acts in the same way in
C and Perl! Because calling C<sslcroak> (or, for that matter,
L<perlapi/croak>) will return control directly to Perl without running
any C code, any and all temporary variables that have been allocated
from C will fail to be de-allocated, thereby causing a memory leak.

Internally, I<sslcroak> works by invoking
L<Crypt::OpenSSL::CA/_sslcroak_callback> several times, using a rough
equivalent of the following pseudo-code:

  _sslcroak_callback("-message", $formattedstring);
  _sslcroak_callback("-openssl", $openssl_errorstring_1);
  _sslcroak_callback("-openssl", $openssl_errorstring_2);
  ...
  _sslcroak_callback("DONE");

where $formattedstring is the C<sprintf>-formatted version of the
arguments passed to I<sslcroak>, and the OpenSSL error strings are
retrieved using B<ERR_get_error(3)> and B<ERR_error_string(3)>.

=head3 parse_RFC3280_time

  static ASN1_TIME* parse_RFC3280_time(char* datetime,
                   char** errmsg, char* sslerrmsg);

Parses C<datetime>, a date in "Zulu" format (that is, yyyymmddhhmmssZ,
with a literal Z at the end), and returns a newly-allocated ASN1_TIME*
structure utilizing a C<utcTime> encoding for dates in the year 2049
or before and C<generalizedTime> for dates in 2050 and after.  RFC3280
dictates that this convention should apply to most date-related fields
in X509 certificates and CRLs (as per sections 4.1.2.5 for certificate
validity periods, and 5.1.2.4 through 5.1.2.6 for CRL validity periods
and certificate revocation times).  By contrast, the C<invalidityDate>
CRL revocation reason extension is always in C<generalizedTime> and
this function should not be used there.

If there is an error, NULL is returned, and one (and only
one) of *errmsg and *sslerrmsg is set to an error string, provided
that they are not NULL.  Caller should thereafter call I<croak> or
L</sslcroak> respectively.

=head3 parse_RFC3280_time_or_croak

  static ASN1_TIME* parse_RFC3280_time_or_croak(char* datetime);

Like L</parse_RFC3280_time> except that it handles its errors itself and
will therefore never return NULL.  The caller should not have an
outstanding temporary variable that must be freed before it returns,
or a memory leak will be created; if this is the case, use the more
clunky L</parse_RFC3280_time> form instead.

=head3 parse_serial

  static ASN1_INTEGER* parse_serial
              (char* hexserial, char** errmsg, char** sslerrmsg);

Parses hexserial, a lowercase, hexadecimal string that starts with
"0x", and returns it as a newly-allocated C<ASN1_INTEGER> structure
that must be freed by caller (with C<ASN1_INTEGER_free>) when done
with it.  If there is an error, NULL is returned, and one (and only
one) of *errmsg and *sslerrmsg is set to an error string, provided
that they are not NULL.  Caller should thereafter call I<croak> or
L</sslcroak> respectively.

=head3 parse_serial_or_croak

  static ASN1_INTEGER* parse_serial_or_croak(char* hexserial);

Like L</parse_serial> except that it handles its errors itself and
will therefore never return NULL.  The caller should not have an
outstanding temporary variable that must be freed before it returns,
or a memory leak will be created; if this is the case, use the more
clunky L</parse_serial> form instead.

=cut

sub _c_boilerplate { <<'C_BOILERPLATE'; }
#include <stdarg.h>         /* For varargs stuff in sslcroak() */
#include <openssl/crypto.h> /* For OPENSSL_free() in openssl_buf_to_SV */
#include <openssl/err.h>    /* For ERR_stuff in sslcroak() */
#include <openssl/pem.h>    /* For BUF_MEM->data dereference in
                               BIO_mem_to_SV(). WTF is this declaration
                               doing in there?! */
#include <openssl/bio.h>    /* Also for BIO_mem_to_SV() */

#include <openssl/opensslv.h>
#if OPENSSL_VERSION_NUMBER < 0x00907000
#error OpenSSL version 0.9.7 or later is required. See comments in CA.pm
#endif

static inline char* char0_value_or_null(SV* perlscalar) {
     if (! SvOK(perlscalar)) { return NULL; }

     STRLEN length;
     SvPV(perlscalar, length);
     SvGROW(perlscalar, length + 1);

     char* retval = SvPV_nolen(perlscalar);
     retval[length] = '\0';
     return retval;
}

static inline char* char0_value(SV* perlscalar) {
     char* retval = char0_value_or_null(perlscalar);
     return ( retval ? retval : "" );
}

static inline SV* perl_wrap(const char* class, void* pointer) {
     SV*      obj = sv_setref_pv(newSV(0), class, pointer);
     if (! obj) { croak("not enough memory"); }
     SvREADONLY_on(SvRV(obj));
     return obj;
}

#define perl_unwrap(class, typename, obj) \
  ((typename) __perl_unwrap(__FILE__, __LINE__, (class), (obj)))

static inline void* __perl_unwrap(const char* file, int line,
                                  const char* class, SV* obj) {
    if (!(sv_isobject(obj) && sv_isa(obj, class))) {
      croak("%s:%d:perl_unwrap: got an invalid "
                "Perl argument (expected an object blessed "
                "in class ``%s'')", file, line, (class));
    }
    return (void *)(intptr_t)SvIV(SvRV(obj));
}

static inline SV* openssl_buf_to_SV(char* string, int length) {
/* Note that a newmortal is not wanted here, even though
 * caller will typically return the SV* to Perl. This is because XS
 * performs some magic of its own for functions that return an SV (as
 * documented in L<perlxs/Returning SVs, AVs and HVs through RETVAL>)
 * and Inline::C leverages that. */
   SV* retval = newSVpv(string, length);
   OPENSSL_free(string);
   return retval;
}

static inline SV* openssl_string_to_SV(char* string) {
   return openssl_buf_to_SV(string, 0);
}

static inline SV* BIO_mem_to_SV(BIO *mem) {
   SV* retval;
   BUF_MEM* buf;

   BIO_get_mem_ptr(mem, &buf);
   if (! buf) {
        BIO_free(mem);
        croak("BIO_get_mem_ptr failed");
   }
   retval = newSVpv(buf->data, 0);
   if (! retval) {
        BIO_free(mem);
        croak("newSVpv failed");
   }
   BIO_free(mem);
   return retval;
}

#define ERRBUFSZ 512
#define THISPACKAGE "Crypt::OpenSSL::CA"
static void sslcroak(char *fmt, ...) {
    va_list ap;                 /* The argument list hiding behind the
                                   hyphens in the protype above */
    dSP;                        /* Required to be able to perform Perl
                                   callbacks */
    char* argv[3];              /* The list of arguments to pass to the
                                   callback */
    char croakbuf[ERRBUFSZ];    /* The buffer to typeset the main error
                                   message into */
    char errbuf[ERRBUFSZ];      /* The buffer to typeset the auxillary error
                                   messages from OpenSSL into */
    SV* dollar_at;              /* Used to probe $@ to see if everything
                                   went well with the callback */
    unsigned long sslerr;       /* Will iterate through the OpenSSL
                                   error stack */

    va_start(ap, fmt);
    vsnprintf(croakbuf, ERRBUFSZ, fmt, ap);
    croakbuf[ERRBUFSZ - 1] = '\0';
    va_end(ap);

    argv[0] = "-message";
    argv[1] = croakbuf;
    argv[2] = NULL;
    call_argv(THISPACKAGE "::_sslcroak_callback", G_DISCARD, argv);

    argv[0] = "-openssl";
    argv[1] = errbuf;
    while( (sslerr = ERR_get_error()) ) {
        ERR_error_string_n(sslerr, errbuf, ERRBUFSZ);
        errbuf[ERRBUFSZ - 1] = '\0';
        call_argv(THISPACKAGE "::_sslcroak_callback", G_DISCARD, argv);
    }
    argv[0] = "DONE";
    argv[1] = NULL;
    call_argv(THISPACKAGE "::_sslcroak_callback", G_DISCARD, argv);

    dollar_at = get_sv("@", FALSE);
    if (dollar_at && sv_isobject(dollar_at)) {
         // Success!
         croak(Nullch);
    } else {
         // Something went bang, revert to the croakbuf.
         croak("%s", croakbuf);
    }
}

/* RFC3280, section 4.1.2.5 */
#define RFC3280_cutoff_date "20500000" "000000"
static ASN1_TIME* parse_RFC3280_time(char* date,
                                     char** errmsg, char** sslerrmsg) {
    int status;
    int is_generalizedtime;
    ASN1_TIME* retval;

    if (strlen(date) != strlen(RFC3280_cutoff_date) + 1) {
         if (errmsg) { *errmsg = "Wrong date length"; }
         return NULL;
    }
    if (date[strlen(RFC3280_cutoff_date)] != 'Z') {
         if (errmsg) { *errmsg = "Wrong date format"; }
         return NULL;
    }

    if (! (retval = ASN1_TIME_new())) {
         if (errmsg) { *errmsg = "ASN1_TIME_new failed"; }
         return NULL;
    }

    is_generalizedtime = (strcmp(date, RFC3280_cutoff_date) > 0);
    if (! (is_generalizedtime ?
           ASN1_GENERALIZEDTIME_set_string(retval, date) :
           ASN1_UTCTIME_set_string(retval, date + 2)) ) {
        ASN1_TIME_free(retval);
        if (errmsg) {
            *errmsg = (is_generalizedtime ?
               "ASN1_GENERALIZEDTIME_set_string failed (bad date format?)" :
               "ASN1_UTCTIME_set_string failed (bad date format?)");
        }
        return NULL;
    }
    return retval;
}

static ASN1_TIME* parse_RFC3280_time_or_croak(char* date) {
    char* plainerr = NULL; char* sslerr = NULL;
    ASN1_INTEGER* retval = NULL;
    if ((retval = parse_RFC3280_time(date, &plainerr, &sslerr))) {
        return retval;
    }
    if (plainerr) { croak("%s", plainerr); }
    if (sslerr) { sslcroak("%s", sslerr); }
    croak("Unknown error in parse_RFC3280_time");
    return NULL; /* Not reached */
}

static ASN1_INTEGER* parse_serial(char* hexserial,
          char** errmsg, char** sslerrmsg) {
    BIGNUM* serial = NULL;
    ASN1_INTEGER* retval;

    if (! (hexserial[0] == '0' && hexserial[1] == 'x')) {
        if (errmsg) {
            *errmsg = "Bad serial string, should start with 0x";
        }
        return NULL;
    }
    if (! BN_hex2bn(&serial, hexserial + 2)) {
        if (sslerrmsg) { *sslerrmsg = "BN_hex2bn failed"; }
        return NULL;
    }
    retval = BN_to_ASN1_INTEGER(serial, NULL);
    BN_free(serial);
    if (! retval) {
        if (sslerrmsg) { *sslerrmsg = "BN_to_ASN1_INTEGER failed"; }
        return NULL;
    }
    return retval;
}

static ASN1_INTEGER* parse_serial_or_croak(char* hexserial) {
    char* plainerr = NULL; char* sslerr = NULL;
    ASN1_INTEGER* retval = NULL;
    if ((retval = parse_serial(hexserial, &plainerr, &sslerr))) {
        return retval;
    }
    if (plainerr) { croak("%s", plainerr); }
    if (sslerr) { sslcroak("%s", sslerr); }
    croak("Unknown error in parse_serial");
    return NULL; /* Not reached */
}

C_BOILERPLATE

=head2 BOOT-time effect

Each C<.so> XS module will be fitted with a C<BOOT> section (see
L<Inline::C/BOOT> which automatically gets executed upon loading it
with L<DynaLoader> or L<XSLoader>. The C<BOOT> section is the same for
all subpackages in L<Crypt::OpenSSL::CA>; it ensures that various
stuff is loaded inside OpenSSL, such as C<ERR_load_crypto_strings()>,
C<OpenSSL_add_all_algorithms()> and all that jazz.  After the boot
code completes, C<$Crypt::OpenSSL::CA::openssl_stuff_loaded> will be
1, so that the following XS modules can skip that when they in turn
get loaded.

=cut

sub _c_boot_section { <<"ENSURE_OPENSSL_STUFF_LOADED" }
    SV* already_loaded = get_sv
      ("Crypt::OpenSSL::CA::openssl_stuff_loaded", 1);
    if (SvOK(already_loaded)) { return; }
    sv_setiv(already_loaded, 1);

    ERR_load_crypto_strings();
    OpenSSL_add_all_algorithms();
ENSURE_OPENSSL_STUFF_LOADED

=head1 INTERNALS

The C<< use Crypt::OpenSSL::CA::Inline::C >> idiom described in
L</SYNOPSIS> is implemented in terms of L<Inline>.

=head3 %c_code

A lexical variable that L</import> uses to accumulate all the C code
submitted by L<Crypt::OpenSSL::CA>.  Keys are package names, and
values are snippets of C.

=cut

my %c_code;

use Inline::C ();

=head3 import ()

Called whenever one of the C<< use Crypt::OpenSSL::CA::Inline::C "foo"
>> pragmas (listed in L</SYNOPSIS>) is seen by Perl; performs the
actual magic of the module.  Stashes everything into L</%c_code>, and
invokes L</compile_everything> at the end.

=cut

sub import {
    my ($class, $c_code) = @_;

    return if ! defined $c_code; # A simple "use"

    return $class->compile_everything if ($c_code eq "__END__");

    my ($package, $file, $line) = caller;
    $c_code{$package} .= sprintf(qq'#line %d "%s"\n', $line + 1, $file)
        . $c_code;
    return;
}

=head3 compile_everything ()

Called when L</the "__END__" pragma> is seen.  Invokes
L<compile_namespace> once for every package (that is, every key in
L</%c_code>), prepending L<_c_boilerplate> each time.

=cut

sub compile_everything {
    my ($class) = @_;
    foreach my $package (keys %c_code) {
        $class->compile_into($package, _c_boilerplate . $c_code{$package},
                             -boot_section => _c_boot_section());
    }
}

=head3 compile_into ($package, $c_code, %named_options)

Compile $c_code and make its functions available as part of $package's
namespace, courtesy to L<Inline::C> magic.  Works by invoking
L<Inline/import> in a tweaked fashion, so as to compile with all
warnings turned into errors (i.e. C<-Wall -Werror>) and to link with
the OpenSSL libraries.  The environment variables are taken into
account (see L</ENVIRONMENT VARIABLES>).

Available named options are:

=over

=item B<< -boot_section => $c_code >>

Adds $c_code to the BOOT section of the generated .so module.

=back

=cut

sub compile_into {
    my ($class, $package, $c_code, %opts) = @_;
    my $compile_params = ($class->full_debugging ?
                          <<'COMPILE_PARAMS_DEBUG' :
    CCFLAGS => "-Wall -Wno-unused -Werror -save-temps",
    OPTIMIZE => "-g",
    CLEAN_AFTER_BUILD => 0,
COMPILE_PARAMS_DEBUG
                          <<'COMPILE_PARAMS_OPTIMIZED');
    OPTIMIZE => "-g -O2",
COMPILE_PARAMS_OPTIMIZED

      my $openssl_params = sprintf('LIBS => "%s -lcrypto -lssl",',
                                   ($ENV{BUILD_OPENSSL_LDFLAGS} or ""));
    if ($ENV{BUILD_OPENSSL_CFLAGS}) {
        $openssl_params .= qq' INC => "$ENV{BUILD_OPENSSL_CFLAGS}",';
    }

    my $version_params =
      ( $Crypt::OpenSSL::CA::VERSION ?
        qq'VERSION => "$Crypt::OpenSSL::CA::VERSION",' : "" );

    my $boot_params = ($opts{-boot_section} ? <<"BOOT_CONFIG" : "");
    BOOT => <<'BOOT_SECTION',
$opts{-boot_section}
BOOT_SECTION
BOOT_CONFIG

    eval <<"FAKE_Inline_C_INVOCATION"; die $@ if $@;
package $package;
use Inline C => Config =>
    NAME => '$package',
$compile_params
    $version_params
    $openssl_params
    $boot_params
;
use Inline C => <<'C_CODE';
$c_code
C_CODE
FAKE_Inline_C_INVOCATION

    return 1;
}

=head3 full_debugging

Returns true iff the environment variable L</FULL_DEBUGGING> is set.

=cut

sub full_debugging { ! ! $ENV{FULL_DEBUGGING} }

=head3 installed_version

Returns what the source code of this module will look like (with POD
and everything) after it is installed.  The installed version is a dud
stub; its L</import> method only loads the XS DLL, and it is no longer
possible to alter the C code once the module has been installed.  The
upside is that in thanks to that, L<Inline> is a dependency only at
compile time.

=begin this_pod_is_not_ours

=cut

sub installed_version { <<'INSTALLED_VERSION' }
#!perl -w

package Crypt::OpenSSL::CA::Inline::C;

use strict;
use XSLoader;

sub import {
    my ($class, $stuff) = @_;
    return if ! defined $stuff;
    return if $stuff eq "__END__";

    my ($package) = caller;
    no strict "refs";
    push @{$package."::ISA"}, qw(XSLoader);
    { no warnings "redefine"; XSLoader::load($package); }
}

=head1 NAME

Crypt::OpenSSL::CA::Inline::C - The Inline magic (or lack thereof) for
Crypt::OpenSSL::CA

=head1 SYNOPSIS

  use Crypt::OpenSSL::CA::Inline::C $and_the_rest_is_ignored;

  # ...

  use Crypt::OpenSSL::CA::Inline::C "__END__";

=head1 DESCRIPTION

This package simply loads the DLLs that contain the parts of
L<Crypt::OpenSSL::CA> that are made of XS code. It is a stubbed-down
version of the full-fledged I<Crypt::OpenSSL::CA::Inline::C> that
replaces the real thing at module install time.

There is more to I<Crypt::OpenSSL::CA::Inline::C>, such as the ability
to dynamically modify and recompile the C code snippets in
I<Crypt::OpenSSL::CA>'s code source. But in order to grasp hold of its
power, you have to use the full source code tarball and not just the
installed version.

=cut

1;

INSTALLED_VERSION

=end this_pod_is_not_ours

=head1 ENVIRONMENT VARIABLES

=head2 FULL_DEBUGGING

Setting this variable to 1 causes the C code to be compiled without
optimization, allowing gdb to dump symbols of static functions with
only one call site (which comprises most of the C code in
L<Crypt::OpenSSL::CA>).  Also, the temporary build files are left
intact if C<FULL_DEBUGGING> is set.

Developpers, please note that in the absence of C<FULL_DEBUGGING>, the
default compiler flags are C<-g -O2>, still allowing for a range of
debugging strategies.  C<FULL_DEBUGGING> should therefore only be set
on a one-shot basis by developpers who have a specific need for it.

=head2 BUILD_OPENSSL_CFLAGS

Contains the CFLAGS to pass so as to compile C code that links against
OpenSSL; eg C<< -I/usr/lib/openssl/include >> or something.  Passed on
to L<Inline::C/INC> by L</compile_everything>.

=head2 BUILD_OPENSSL_LDFLAGS

Contains the LDFLAGS to pass so as to link with the OpenSSL libraries;
eg C<< -L/usr/lib/openssl/lib >> or something.  Passed on to
L<Inline::C/LIBS> by L</compile_everything>.

=head1 SEE ALSO

L<Inline::C>, L<perlxstut>, L<perlguts>, L<perlapi>.

=cut

require My::Tests::Below unless caller();

1;

__END__

=begin internals

=head1 TEST SUITE

=cut

use Test::More "no_plan";
use Test::Group;
use Crypt::OpenSSL::CA::Test qw(errstack_empty_ok
                                cannot_check_SV_leaks leaks_SVs_ok
                                cannot_check_bytes_leaks leaks_bytes_ok);
use Data::Dumper;

test "synopsis" => sub {
    my $idiom = My::Tests::Below->pod_code_snippet("synopsis");

    my $some_c_code = <<"SOME_C_CODE";
return newSVsv(&PL_sv_undef);
SOME_C_CODE

    ok($idiom =~ s/^.*Your C code.*$/$some_c_code/im)
        or die "Bad regexp - *AGAIN!*";
    $idiom .= "mysub();";

    my $result = eval($idiom); die $@ if $@;
    is($result, undef);
};

test 'perl_wrap() and perl_unwrap()' => sub {
    # Also doubles as a learning test for Inline
    use Crypt::OpenSSL::CA::Inline::C <<"C_TEST";
SV* make_bogus_object(int value) {
    int* valueref = malloc(sizeof(int));
    *valueref = value;
    return perl_wrap("bogoclass", valueref);
}

int bogus_object_value(SV* object) {
    int* self = perl_unwrap("bogoclass", int *, object);
    return *self;
}

void free_bogus_object(SV* object) {
    free(perl_unwrap("bogoclass", int *, object));
    SvSetSV(object, &PL_sv_undef);
}

int deref_wrong_class(SV* object) {
    int* self = perl_unwrap("anotherclass", int *, object);
    return *self;
}
C_TEST

    my $object = make_bogus_object(42);
    is(ref($object), "bogoclass");
    like($$object, qr/^-?[1-9][0-9]*$/, "looks like a number in the inside");
    is(bogus_object_value($object), 42);
    eval {
        $$object = 46;
        fail("attempt to modify object should have thrown");
    };
    isnt($@, '', "immutable OK");
    eval {
        deref_wrong_class($object);
        fail("deref_wrong_class should have thrown");
    };
    like($@, qr/[0-9]+.*expected.*anotherclass/);
    free_bogus_object($object); # So that the test doesn't leak
    is($object, undef);
};

test '$c_boilerplate: char0_value()' => sub {
    { package Char0Test; use Crypt::OpenSSL::CA::Inline::C <<"CHAR0_TEST"; }

static
char* TEST_char0_value(SV* scalar_under_test) {
    return char0_value(scalar_under_test);
}

CHAR0_TEST

    is(Char0Test::TEST_char0_value(2 * 12), "24", "char0_value");
    is(do { no warnings "uninitialized"; Char0Test::TEST_char0_value(undef) },
       "", "char0_value shall not SEGV on undef");
};

skip_next_test "Devel::Leak needed" if cannot_check_SV_leaks;
test 'OO and reference counting using $c_boilerplate' => sub {
    # This also doubles as a learning test (for OO style)
    { package Foo; use Crypt::OpenSSL::CA::Inline::C <<"C_TEST"; }
static
SV* new(char* class, int value) {
    int* valueref = malloc(sizeof(int));
    *valueref = value;
    return perl_wrap(class, valueref);
}

static
void DESTROY(SV* object) {
    int* self = perl_unwrap("${\__PACKAGE__}", int *, object);
    free(self);
    // No attempting to alter *object in a DESTROY (causes a warning
    // and is pointless).
}
C_TEST

    local $SIG{__WARN__} = sub { fail }; # Catches errors in DESTROY
    # that actually get turned into warnings

    my $handle;
    leaks_SVs_ok { map { Foo->new($_) } (1..1000) };
};

{ package TestCRoutines; use Crypt::OpenSSL::CA::Inline::C <<"C_TEST"; }
void argh() {
    sslcroak("How are you %s", "gentlemen");
}

// For leak tests
void ulp() {
    char buf[1024];
    memset(buf, (int) 'A', 1023);
    buf[1023] = '\\0';
    sslcroak(buf);
}

int test_parse_RFC3280_time(char* time) {
    char* plainerr = NULL; char* sslerr = NULL;
    ASN1_TIME* asn1time;
    int retval;

    asn1time = parse_RFC3280_time(time, &plainerr, &sslerr);
    if (asn1time) {
        retval = (asn1time->type == V_ASN1_GENERALIZEDTIME ? 1 : 0);
        ASN1_TIME_free(asn1time);
        return retval;
    }
    if (plainerr) { return -1; }
    if (sslerr) { return -2; }
    return -42;
}

void test_parse_RFC3280_time_or_croak(char* time) {
    ASN1_TIME_free(parse_RFC3280_time_or_croak(time));
}

int test_parse_serial(char* serial) {
    char* plainerr = NULL; char* sslerr = NULL;
    ASN1_INTEGER* asn1serial;

    asn1serial = parse_serial(serial, &plainerr, &sslerr);
    if (asn1serial) { ASN1_INTEGER_free(asn1serial); return 0; }
    if (plainerr) { return 1; }
    if (sslerr) { return 2; }
    return 42;
}

void test_parse_serial_or_croak(char* serial) {
    ASN1_INTEGER_free(parse_serial_or_croak(serial));
}

C_TEST


test "sslcroak()" => sub {
    # Implementation lifted from Crypt::OpenSSL::CA so as
    # to sever the circular dependency in tests:
    sub Crypt::OpenSSL::CA::_sslcroak_callback {
        my ($key, $val) = @_;
        if ($key eq "-message") {
            $@ = { -message => $val };
        } elsif ( ($key eq "-openssl") && (ref($@) eq "HASH") ) {
            $@->{-openssl} ||= [];
            push(@{$@->{-openssl}}, $val);
        } elsif ( ($key eq "DONE") && (ref($@) eq "HASH") ) {
            bless($@, "Crypt::OpenSSL::CA::Error");
        } else {
            warn sprintf
                ("Bizarre callback state%s",
                 (Data::Dumper->can("Dumper") ?
                  " " . Data::Dumper::Dumper($@) : ""));
        }
    }

    eval {
        TestCRoutines::argh();
        fail("Should have thrown");
    };
    is(ref($@), "Crypt::OpenSSL::CA::Error") or warn Dumper($@);
    like($@->{-message}, qr/how are you gentlemen/i);

    # Now with genuine OpenSSL barfage.
    errstack_empty_ok();
    use Net::SSLeay;
    is(Net::SSLeay::BIO_new_file("/no/such/file_", "r"), 0);
    eval { TestCRoutines::argh(); fail("should have thrown") };
    is(ref($@), "Crypt::OpenSSL::CA::Error");
    is(ref($@->{-openssl}), "ARRAY");
    cmp_ok(scalar(@{$@->{-openssl}}), ">", 0);
    my ($start_of_errors) = grep { $@->{-openssl}->[$_] =~ m/fopen/ }
        (0..$#{$@->{-openssl}});
    ok(defined($start_of_errors));
    like($@->{-openssl}->[$start_of_errors + 1],
         qr/no such file/); # Also checks that message wasn't truncated

    unless (cannot_check_bytes_leaks) {
        leaks_bytes_ok {
            for(1..200) { eval { TestCRoutines::ulp() }; }
        };
    }
};

test "parse_RFC3280_time" => sub {
    is(TestCRoutines::test_parse_RFC3280_time("20510103103442Z"), 1);
    is(TestCRoutines::test_parse_RFC3280_time("19510103103442Z"), 0);
    TestCRoutines::test_parse_RFC3280_time_or_croak("19510103103442Z");
    eval {
        TestCRoutines::test_parse_RFC3280_time_or_croak("0Z");
        fail("Should have thrown");
    };
};

skip_next_test "Devel::Mallinfo needed" if cannot_check_bytes_leaks;
test "parse_RFC3280_time_or_croak memory leaks" => sub {
    leaks_bytes_ok {
        for(1..10000) {
            eval {
                TestCRoutines::test_parse_RFC3280_time_or_croak("portnawak");
                fail("Should have thrown");
            };
            TestCRoutines::test_parse_RFC3280_time_or_croak("20510103103442Z");
            TestCRoutines::test_parse_RFC3280_time_or_croak("19510103103442Z");
        }
    };
};

test "parse_serial" => sub {
    TestCRoutines::test_parse_serial_or_croak("0xdeadbeef1234");
    pass;
    eval {
        TestCRoutines::test_parse_serial_or_croak("deadbeef1234");
        fail("should have thrown");
    };
    ok(! ref($@), "Plain error expected");
    unlike($@, qr/unknown/i, "proper internal error management");
    is(TestCRoutines::test_parse_serial("0xdeadbeef1234"), 0);
    is(TestCRoutines::test_parse_serial("deadbeef1234"), 1);
};

skip_next_test "Devel::Mallinfo needed" if cannot_check_bytes_leaks;
test "parse_serial memory leaks" => sub {
    leaks_bytes_ok {
        for(1..10000) {
            TestCRoutines::test_parse_serial("0xdeadbeef1234");
            TestCRoutines::test_parse_serial("deadbeef1234");
        }
    };
};

=end internals

=cut

