#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', # Test2::V0 etc.
                  qw/bug displaystr fmt_codestring timed_run
                     mycheckeq_literal mycheck @quotes
                     $debug/;

use Scalar::Util qw(refaddr);
use List::Util qw(shuffle);
use Math::BigInt;

use Data::Dumper::Interp qw/:all alvis addrvis_digits addrvis_forget/;
$Data::Dumper::Interp::Foldwidth = 0;  # no folding

#$Data::Dumper::Interp::Debug = 1;

my $addrvis_re = qr/[A-Za-z][:\w]*\<\d+:[\da-fA-F]+\>/;

use threads;
use threads::shared;

my $href = { "zort" => 12345 };
my $unshared_var = 111;
my $ref_to_unshared = \$unshared_var;
my $shared_var :shared = 222;
my $ref_to_shared = \$shared_var;

my $shared_cloned_var = shared_clone $href;


like(dvis('dvis: $ref_to_unshared $ref_to_shared $shared_cloned_var $href'),
     "dvis: ref_to_unshared=\\111 ref_to_shared=\\222 shared_cloned_var={zort => 12345} href={zort => 12345}");

addrvis_digits(10);

note "dvisr(ref_to_unshared) = ",visnew->dvisr('$ref_to_unshared'), "\n";
note "dvisr(ref_to_shared) = ",visnew->dvisr('$ref_to_shared'), "\n";
note "addrvis(ref_to_unshared) = ",u(addrvis($ref_to_unshared)), "\n";
note "addrvis(ref_to_shared) = ",u(addrvis($ref_to_shared)), "\n";
note "addrvis(shared_cloned_var) = ",u(addrvis($shared_cloned_var)), "\n";
note "addrvis(href) = ",u(addrvis($href)), "\n";

my $unshared_re = qr/\<\d{10}:[a-fA-F0-9]{10}\>/;
my $shared_re   = qr/\<\Q${\Data::Dumper::Interp::_ADDRVIS_SHARED_MARK}\E\d{10}:[a-fA-F0-9]{10}\>/;

like(visnew->Refaddr(1)->ivis('$ref_to_unshared'), qr/\A${unshared_re}\\111\z/);
like(visnew->Refaddr(1)->dvis('$ref_to_unshared'), qr/\Aref_to_unshared=${unshared_re}\\111\z/);

like(visnew->Refaddr(1)->dvis('$ref_to_shared'), qr/\Aref_to_shared=${shared_re}\\222\z/);

like(visnew->Refaddr(1)->dvis('$ref_to_unshared $ref_to_shared'), qr/\Aref_to_unshared=${unshared_re}\\111 ref_to_shared=${shared_re}\\222\z/);

like(visnew->Refaddr(1)->dvis('dvis: $ref_to_unshared $ref_to_shared $shared_cloned_var'),
  qr/\Advis: ref_to_unshared=${unshared_re}\\111 ref_to_shared=${shared_re}\\222 shared_cloned_var=${shared_re}\{.*\}\z/);

like(visnew->dvisr('dvis: $shared_cloned_var $href'),
     qr/\Advis: shared_cloned_var=${shared_re}\{zort => 12345\} href=${unshared_re}\{zort => 12345\}\z/);

done_testing();

exit 0;
