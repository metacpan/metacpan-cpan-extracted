package Cac;

use 5.007;
use strict;
use warnings;

our $xs_loaded = 0;

BEGIN {
}
use XSLoader;
eval {
  XSLoader::load Cac unless $Cac::xs_loaded++; # this is in cacperl.xs :)
};
die "\n\nCan't load Cac-XS.\nThis happen when you use a plain Perl that is not embedded in Cache\n"
    ."Use the cperl script provided in the Cache-Perl distribution, loading Cache-Perl without\n"
    ."that will fail in any case\n\n$@" if $@;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Cac ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our @EXPORT = qw(
	&CacEval &CacExecute	&CacHome
);

our %EXPORT_TAGS = ( 'all' => [ @EXPORT ],
                     'highlevel' => [ qw(
                                         _CacAbort _CacContext _CacConvert _CacConvert2                                         
                                         _CacCtrl _CacCvtIn _CacCvt_Out _CacEnd
                                         _CacError _CacErrxlate _CacEval
                                         _CacExecute _CacPrompt _CacSignal _CacStart
                                         _CacType 
                                      )
                                    ],
                     'lowlevel' => [ qw(
                                         _CacCloseOref _CacDoFun _CacDoRtn _CacExtFun
                                         _CacGetProperty _CacGlobalGet _CacGlobalSet
                                         _CacIncrementCountOref _CacInvokeClassMethod
                                         _CacPop _Cac_PopDbl _CacPopInt _CacPopList
                                         _CacPopOref _CacPopStr _CacPopPtr
                                         _CacPushDbl _CacPushFunc _CacPushFuncX
                                         _CacPushGlobal _CacPushGlobalX _CacPushInt
                                         _CacPushList _CacPushMethod _CacPushOref
                                         _CacPushProperty _CacPushPtr _CacPushRtn
                                         _CacPushRtnX _CacPushStr _CacSetProperty
                                         _CacUnPop
                                        )],
      
      );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, @{ $EXPORT_TAGS{'highlevel'} }, @{ $EXPORT_TAGS{'lowlevel'} });

our $VERSION = 1.83;


=head1 NAME

Cac - Integration of Intersystems Cache Database into Perl

=head1 SYNOPSIS

  use Cac qw(:lowlevel :highlevel);
  _CacEval '$ZV'; print _CacConvert();
  
This module and all modules in the Cac::-Domain
require a perl that has Cache fully embedded.
(such a binary is a dual-binary that is a Perl and a Cache
binary at the same time. Usually there is a softlink
(ln -s cache cperl) so you don't need to use cache --perl
anymore, it works the following way:

use:

  o cache --perl [perl options ]    and you start perl with embedded cache
  o cperl [ perl options ]          and you get perl with embedded cache
  o cache [ cache options ]         and you get cache with embedded perl

For backward compatibility with older versions of Cache-Perl

  o cache -perl [ perl options ]
  
is still supported but this feature is deprecated. Use "--perl" instead
of "-perl". 
  
Note: Most of this stuff is the low-level Interface, you normally don't need it,
except maybe CacEval and CacExecute.


  o use Cac::ObjectScript     - for embedded ObjectScript support
  o use Cac::Global           - for high-performance global access (bulk support)
  o use Cac::Routine          - for calling routines and functions
  o use Cac::Bind             - for bidirectional binding of COS Variables to Perl variables
  o use Cac::Util             - for utility functions and helpers


=head1 DESCRIPTION

 * This module provides full access to most Cache call-in functions.
 * You should not use the call-in function without exactly knowing what you are doing
 * These function are not exported by default and prepended by a underscore (that means internal).
 * All functions are perlified - you pass a single string if Cache expects a counted string
 * You don't need to check for errors. Most functions raise exceptions on error: use eval { }; to catch them
 * Only "A" functions are supported, no "W". "W" is NOT Unicode anyway, Intersystems simply lies to you.

=head1 User Interface for Cache Functions

=over 4

=item CacEval $expr

 Evaluates a ObjectScript expression and returns its result
 Exception: yes
 Note: This function is slow because it has to preserve terminal settings

=item CacExecute $stmt

 Executes a ObjectScript command and returns nothing.
 Exception: yes
 Note: This function is slow because it has to preserve terminal settings
 

=back

=head1 Cache Call-In High-Level Functions

The high-level functions can be imported by:
use Cache ':highlevel';

=over 4

=item _CacAbort [ CACHE_CTRLC | CACHE_RESJOB ]

 See Cache specification.
 Exception: Yes
 Note: Don't use it.

=item $ctx = _CacContext()

 See Cache specification.
 Exception: No

=item $value = _CacConvert()

 See Cache specification.
 Exception: Yes
 Note: This function calls CacConvert(CACHE_ASTRING, ...)

=item $value = _CacConvert2()

 This routine uses CacType() to ask for the type of TOS and
 tries to get the value the fastest way possible.

 Exception: Yes

=item _CacCtrl($bitmap)

 See Cache specification
 Exception: Yes

=item $converted = _CacCvtIn($string, $table)

 See Cache specification
 Exception: Yes

=item $converted = _CacCvtOut($string, $table)

 See Cache specification
 Exception: Yes

=item _CacEnd()

 See Cache specification
 Exception: Yes
 Note: You should NEVER EVER call this! even POSIX::_exit(1); is prefered.

=item $error = _CacError()

 See Cache specification
 Exception: Yes (if a double fault happens)
 Note: No need to call this because every error is reported by croak.

=item $errorstring = _CacErrxlate($errornum)

 See Cache specification
 Exception: No (if the call to CacheErrxlate fails, undef is returned)

=item _CacEval $string

 See Cache specification
 Exception: Yes

=item _CacExecute $string

 See Cache specification
 Exception: Yes

=item $prompt = _CacPrompt()

 See Cache specification
 Exception: Yes
 Note: Experts call this functions only by accident. :)

=item _CacSignal $number

 See Cache specification
 Exception: Yes
 Note: Think and you will find out that you don't want it in most cases.

=item _CacStart($flags, $timeout, $princin, $princout)

 See Cache specification
 Exception: Yes
 Note: Don't call it. It's already done. Say simply thanks :)

=item $type = _CacType()

 See Cache specification
 Exception: No (ahm, check the return value for errors)

=back

=head1 Cache Low-Level Call-In Functions

 The low-level functions can be imported by:
 use Cac ':lowlevel';

Use it only IF:

  * you know how to use gdb
  * you want to corrupt the database
  * you never use a condom anyway :)
  * you know what gmngen/checksum/mdate is made for :)

=over 4

=item _CacCloseOref $oref

 See Cache specification
 Exception: Yes

=item _CacDoFun $rflags, $numargs

 See Cache specification
 Exception: Yes, please.

=item _CacDoRtn $rflags, $numargs

 See Cache specification
 Exception: Oui

=item _CacExtFun $rflags, $numargs

 See Cache specification
 Exception: Da

=item _CacGetProperty()

 See Cache specification
 Exception: Yes, sir.

=item _CacGlobalGet $numsubscipt, $die_or_empty

 See Cache specification
 Exception: yup

=item _CacGlobalSet $numsubscript

 See Cache specification
 Exception: yup, on weekends only.

=item _CacIncrementCountOref $oref

 See Cache specification
 Exception: ja

=item _CacInvokeClassMethod $numarg

 See Cache specification
 Exception: si

=item _CacPop $arg

 Not implemented
 Exception: yes

=cut

sub _CacPop($) {
   die "_CacPop not implemented.";
}

=item $val = _CacPopDbl()

 See Cache specification
 Exception: yes

=item $val = _CacPopInt()

 See Cache specification
 Exception: yes

=item $string = _CacPopList()

 Currently not implemented
 Exception: yes

=cut

sub _CacPopList()
{
  die "_CacPopList is currently not implemented - sorry.";
}

=item $oref = _CacPopOref()

 See Cache specification
 Exception: yes

=item $str = _CacPopStr()

 See Cache specification
 Exception: yes

=item $ptr = _CacPopPtr()

 Not Implemented
 Exception: yes

=cut

sub _CacPopPtr() {
   die "_CacPopPtr is currently not implemented";
}

=item _CacPushClassMethod $classname, $methodname, [$flag]/

 See Cache specification
 Exception: /bin/true
 Note: flag defaults to 0

=item _CacPushDbl $double

 See Cache specification
 Exception: yes

=item $rflags = _CacPushFunc $tag, $routine;

 See Cache specification
 Exception: yes

=item $rflags = _CacPushFuncX $tag, $offset, $env, $routine;

 See Cache specification
 Exception: yes

=item _CacPushGlobal $global

 See Cache specification
 Exception: yes

=item _CacPushGlobalX $global, $env

 See Cache specification
 Exception: yes

=item _CacPushInt $i

 See Cache specification
 Exception: yes

=item _CacPushList $string

 See Cache specification
 Exception: yes

=item _CacPushMethod $oref, $methodname, [$flag]

 See Cache specification
 Exception: yes
 Note: $flag defaults to 0

=item _CacPushOref $oref

 See Cache specification
 Exception: yes

=item _CacPushProperty $oref, $property

 See Cache specification
 Exception: yes

=item _CacPushPtr $value

 See Cache specification
 Exception: yes

=item $rflags = _CacPushRtn $tag, $routine

 See Cache specification
 Exception: yes

=item $rflags = _CacPushRtnX $tag, $offset, $env, $routine

 See Cache specification
 Exception: yes

=item _CacPushStr $string

 See Cache specification
 Exception: yes

=item _CacSetProperty()

 See Cache specification
 Exception: yes

=item _CacUnPop()

 See Cache specification
 Exception: yes

=back

=head1 SEE ALSO

L<Cac::ObjectScript>, L<Cac::Global>, L<Cac::Routine>, L<Cac::Util>, L<Cac::Bind>.

=head1 AUTHOR

 Stefan Traby <stefan@hello-penguin.com>
 http://hello-penguin.com

=head1 COPYRIGHT

 Copyright 2001,2003,2004 by KW-Computer Ges.m.b.H Graz, Austria
 Copyright 2001,2002,2003,2004 by Stefan Traby <stefan@hello-penguin.com>

=head1 LICENSE

 This module is licenced under LGPL
 (GNU LESSER GENERAL PUBLIC LICENSE)
 see the LICENSE-file in the toplevel directory of this distribution.

=cut

1;
__END__
