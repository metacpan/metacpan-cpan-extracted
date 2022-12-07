package Dyn::Call 0.04 {
    use strict;
    use warnings;
    use 5.030;
    use XSLoader;
    XSLoader::load( __PACKAGE__, our $VERSION );
    use parent 'Exporter';
    our %EXPORT_TAGS;
    push @{ $EXPORT_TAGS{vars} }, @{ $EXPORT_TAGS{sigchar} };
    push @{ $EXPORT_TAGS{default} }, @{ $EXPORT_TAGS{call} }, @{ $EXPORT_TAGS{vars} };
    @{ $EXPORT_TAGS{all} } = our @EXPORT_OK = sort map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
}
1;
__END__

=encoding utf-8

=head1 NAME

Dyn::Call - Architecture-, OS- and Compiler-agnostic Function Call Semantics

=head1 SYNOPSIS

    use Dyn::Call qw[:all];
    # ...
    my $cvm = dcNewCallVM( 1024 );
    dcMode( $cvm, 0 );
    dcReset( $cvm );
    dcArgInt( $cvm, 5 );
    dcArgInt( $cvm, 6 );
    dcCallInt( $cvm, $ptr ); #  '5 + 6 == 11';

=head1 DESCRIPTION

Dyn::Call wraps the C<dyncall> CallVM; a state machine which provides low-level
functionality to make foreign function calls from different run-time
environments. The flexibility is constrained by the set of supported types.

Everything listed here may be imported by name, with the given import tag or
with the C<:all> tag.

=head1 Call Virtual Machine (CallVM) Functions

These functions effect the CallVM which manages all aspects of a function call
from configuration, argument passing up the actual function call on the
processor.

You may import functions here by name or with the C<:callvm> tag.

=head2 C<dcNewCallVM( ... )>

    my $cvm = dcNewCallVM( 1024 );

This function creates a new C<CallVM> object, where C<size> specifies the max
size of the internal stack that will be allocated and used to bind arguments
to. You B<must> use L<< C<dcFree( ... )>|/C<dcFree( ... )> >> to properly
destroy the C<CallVM> object.

Expected parameters include:

=over

=item C<size> - stack size

=back

Returns a new C<CallVM> object on success.

=head2 C<dcFree( ... )>

Destroy a CallVM instance.

    dcFree( $cvm );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=back

=head2 C<dcGetError( ... )>

Returns the most recent error state code.

    my $error = dcGetError( $cvm );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=back

Possible error states are listed L<below|/Errors>.

=head2 C<dcMode( ... )>

Sets the calling convention to use.

    dcMode( $cvm, DC_CALL_C_DEFAULT );

Note that some mode/platform combinations don't make any sense (e.g. using a
PowerPC calling convention on a MIPS platform) and are silently ignored.

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<mode> - See list of possible modes L<below|/Modes>

=back

C<DC_CALL_C_DEFAULT> is the default standard C call on the target platform. It
uses the standard C calling convention. C<DC_CALL_C_ELLIPSIS> is used for C
ellipsis calls which allow to build up a variable argument list. On many
platforms, there is only one C calling convention. The X86 platform provides a
rich family of different calling conventions.

=head2 C<dcReset( ... )>

Resets the internal stack of arguments and prepares it for a new call.

This function should be called after setting the call mode (using L<< C<dcMode(
... )>|/C<dcMode( ... )> >>), but prior to binding arguments to the
L<Dyn::Call> VM (except for when setting mode
C<DC_SIGCHAR_CC_ELLIPSIS_VARARGS>, which is used prior to binding varargs of
variadic functions). Use it also when reusing a L<Dyn::Call> VM, as arguments
don't get flushed automatically after a function call invocation.

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=back

Note: you should also call this function after initial creation of the a
L<Dyn::Call> object, as L<< C<dcNewCallVM( ... )>|/C<dcNewCallVM( ... )> >>
doesn't do this, implicitly.

=head1 Argument Binding Functions

These functions are used to bind arguments of the named types to the CallVM
object. Arguments should be bound in left-to-right order regarding the C style
function prototype.

These functions may be imported by name or with the C<:bind> tag.

=head2 C<dcArgBool( ... )>

Pushes a boolean value onto the argument stack.

    dcArgBool( $cvm, 1 ); # or 0, of course

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - a boolean value

=back

=head2 C<dcArgChar( ... )>

Pushes a char value onto the argument stack.

    dcArgChar( $cvm, 'a' );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - a char value

=back

=head2 C<dcArgShort( ... )>

Pushes a short integer value onto the argument stack.

    dcArgShort( $cvm, -500 );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - a short value

=back

=head2 C<dcArgInt( ... )>

Pushes an integer value onto the argument stack.

    dcArgInt( $cvm, -500 );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - an integer value

=back

=head2 C<dcArgLong( ... )>

Pushes a long integer value onto the argument stack.

    dcArgLong( $cvm, -2147483647 );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - an long integer value

=back

=head2 C<dcArgLongLong( ... )>

Pushes a long long integer value onto the argument stack.

    dcArgLongLong( $cvm, -9223372036854775807 );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - an long long integer value

=back

=head2 C<dcArgFloat( ... )>

Pushes a single-precision floating point value onto the argument stack.

    dcArgFloat( $cvm, 3.14 );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - a floating point value

=back

=head2 C<dcArgDouble( ... )>

Pushes a double-precision floating point value onto the argument stack.

    dcArgDouble( $cvm, 3.14 );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - a floating point value

=back

=head2 C<dcArgPointer( ... )>

Pushes a pointer (C<void *>) value onto the argument stack.

    dcArgPointer( $cvm, $struct );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - a pointer

=back

=head2 C<dcArgString( ... )>

Pushes a string (C<char *>) value onto the argument stack.

    dcArgString( $cvm, 'John' );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<arg> - a string

=back

=head1 Call Invocation Functions

These functions call the function specified by C<funcptr> with the arguments
bound to the CallVM and returns. Use the function that corresponds to the
dynamically called function's return value.

After the invocation of the foreign function call, the argument values are
still bound and a second call using the same arguments can be issued. If you
need to clear the argument bindings, you have to reset the CallVM.

These functions may be imported by name or with the C<:call> tag.

=head2 C<dcCallVoid( ... )>

Invokes the function with a the expectations of void return value.

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallBool( ... )>

Invokes the function with the expectations of a boolean return value.

    my $tf = dcCallBool( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallChar( ... )>

Invokes the function with the expectations of a char return value.

    my $char = dcCallChar( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallShort( ... )>

Invokes the function with the expectations of a short return value.

    my $ret = dcCallShort( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallInt( ... )>

Invokes the function with the expectations of a integer return value.

    my $sum = dcCallInt( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallLong( ... )>

Invokes the function with the expectations of a long return value.

    my $val1 = dcCallLong( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallLongLong( ... )>

Invokes the function with the expectations of a long long return value.

    my $val2 = dcCallLongLong( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallFloat( ... )>

Invokes the function with the expectations of a float return value.

    my $f = dcCallFloat( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallDouble( ... )>

Invokes the function with the expectations of a double return value.

    my $num = dcCallDouble( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallPointer( ... )>

Invokes the function with a the expectations of a pointer (C<void *>) return
value.

    my $ptr = dcCallPointer( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head2 C<dcCallString( ... )>

Invokes the function with a string (C<const char *>) return value.

    my $str = dcCallString( $cvm, $funcptr );

Expected parameters include:

=over

=item C<vm> - C<Dyn::Call> object

=item C<funcptr> - function pointer

=back

=head1 Structure Functions

These functions aide in computing the size of a structure. They may be imported
by name or with the C<:struct> tag.

=head2 C<dcNewStruct( ... )>

Creates a new C<DCstruct>.

    my $struct = dcNewStruct( 4, DEFAULT_ALIGNMENT );

Expected parameters include:

=over

=item C<fieldCount> - the number of fields in the structure

=item C<alignment> - L<data structure alignment|https://en.wikipedia.org/wiki/Data_structure_alignment>

=back

=head2 C<dcStructField( ... )>

Adds a new field to the structure.

    dcStructField( $struct, DC_SIGCHAR_INT, DEFAULT_ALIGNMENT, 1 );

Expected parameters include:

=over

=item C<struct> - C<DCstruct>

=item C<type> - Structure type (you may reuse signature values here)

=item C<alignment> - L<data structure alignment|https://en.wikipedia.org/wiki/Data_structure_alignment>

=item C<arrayLength> - number of elements in field

=back

=head2 C<dcSubStruct( ... )>

Nests a structure inside of another.

    dcSubStruct( $struct, 1, DEFAULT_ALIGNMENT, 1 );

Expected parameters include:

=over

=item C<struct> - C<DCstruct>

=item C<fieldCount> - the number of fields in the structure

=item C<alignment> - L<data structure alignment|https://en.wikipedia.org/wiki/Data_structure_alignment>

=item C<arrayLength> - number of elements in field

=back

=head1 Errors

These values are returned by L<< C<dcGetError( ... )>|/C<dcGetError( ... )> >>
and include:

=over

=item C<DC_ERROR_NONE> - No error occurred

=item C<DC_ERROR_UNSUPPORTED_MODE> - Unsupported mode; caused by L<< C<dcMode( ... )>|/C<dcMode( ... )> >>

=back

=head2 Modes

You may set the calling convention to use with L<< C<dcMode( ... )>|/C<dcMode(
... )> >>.

=over

=item C<DC_CALL_C_DEFAULT> - C default function call for current platform

=item C<DC_CALL_C_ELLIPSIS> - C ellipsis function call (named arguments (before '...'))

=item C<DC_CALL_C_ELLIPSIS_VARARGS> - C ellipsis function call (variable/unnamed arguments (after '...'))

=item C<DC_CALL_C_X86_CDECL> - C x86 platforms standard call

=item C<DC_CALL_C_X86_WIN32_STD> - C x86 Windows standard call

=item C<DC_CALL_C_X86_WIN32_FAST_MS> - C x86 Windows Microsoft fast call

=item C<DC_CALL_C_X86_WIN32_FAST_GNU> - C x86 Windows GCC fast call

=item C<DC_CALL_C_X86_WIN32_THIS_MS> - C x86 Windows Microsoft this call

=item C<DC_CALL_C_X86_WIN32_THIS_GNU> - alias for C<DC_CALL_C_X86_CDECL> (GNU this call is identical to cdecl)

=item C<DC_CALL_C_X86_PLAN9> - C x86 Plan9 call

=item C<DC_CALL_C_X64_WIN64> - C x64 Windows standard call

=item C<DC_CALL_C_X64_SYSV> - C x64 System V standard call

=item C<DC_CALL_C_PPC32_DARWIN> - C ppc32 Mac OS X standard call

=item C<DC_CALL_C_PPC32_OSX> - alias for DC_CALL_C_PPC32_DARWIN

=item C<DC_CALL_C_PPC32_SYSV> - C ppc32 SystemV standard call

=item C<DC_CALL_C_PPC32_LINUX> - alias for C<DC_CALL_C_PPC32_SYSV>

=item C<DC_CALL_C_PPC64> - C ppc64 SystemV standard call

=item C<DC_CALL_C_PPC64_LINUX> - alias for C<DC_CALL_C_PPC64>

=item C<DC_CALL_C_ARM_ARM> - C arm call (arm mode)

=item C<DC_CALL_C_ARM_THUMB> - C arm call (thumb mode)

=item C<DC_CALL_C_ARM_ARM_EABI> - C arm eabi call (arm mode)

=item C<DC_CALL_C_ARM_THUMB_EABI> - C arm eabi call (thumb mode)

=item C<DC_CALL_C_ARM_ARMHF> - C arm call (arm hardﬂoat - e.g. raspberry pi)

=item C<DC_CALL_C_ARM64> - C arm64 call (AArch64)

=item C<DC_CALL_C_MIPS32_EABI> - C mips32 eabi call

=item C<DC_CALL_C_MIPS32_PSPSDK> - alias for C<DC_CALL_C_MIPS32_EABI> (deprecated)

=item C<DC_CALL_C_MIPS32_O32> - C mips32 o32 call

=item C<DC_CALL_C_MIPS64_N64> - C mips64 n64 call

=item C<DC_CALL_C_MIPS64_N32> - C mips64 n32 call

=item C<DC_CALL_C_SPARC32> - C sparc32 call

=item C<DC_CALL_C_SPARC64> - C sparc64 call

=item C<DC_CALL_SYS_DEFAULT> - C default syscall for current platform

=item C<DC_CALL_SYS_X86_INT80H_BSD> - C syscall for x86 BSD platforms

=item C<DC_CALL_SYS_X86_INT80H_LINUX> - C syscall for x86 Linux

=item C<DC_CALL_SYS_X64_SYSCALL_SYSV> - C syscall for x64 System V platforms

=item C<DC_CALL_SYS_PPC32> - C syscall for ppc32

=item C<DC_CALL_SYS_PPC64> - C syscall for ppc64

=back

=head2 Signature

=over

=item C<DC_SIGCHAR_VOID>

=item C<DC_SIGCHAR_BOOL>

=item C<DC_SIGCHAR_CHAR>

=item C<DC_SIGCHAR_UCHAR>

=item C<DC_SIGCHAR_SHORT>

=item C<DC_SIGCHAR_USHORT>

=item C<DC_SIGCHAR_INT>

=item C<DC_SIGCHAR_UINT>

=item C<DC_SIGCHAR_LONG>

=item C<DC_SIGCHAR_ULONG>

=item C<DC_SIGCHAR_LONGLONG>

=item C<DC_SIGCHAR_ULONGLONG>

=item C<DC_SIGCHAR_FLOAT>

=item C<DC_SIGCHAR_DOUBLE>

=item C<DC_SIGCHAR_POINTER>

=item C<DC_SIGCHAR_STRING> - in theory same as C<DC_SIGCHAR_POINTER>, but convenient to disambiguate

=item C<DC_SIGCHAR_STRUCT>

=item C<DC_SIGCHAR_ENDARG>  - also works for end struct

=back

=head3 Calling Convention / Mode Signatures

=over

=item C<DC_SIGCHAR_CC_PREFIX>

=item C<DC_SIGCHAR_CC_DEFAULT>

=item C<DC_SIGCHAR_CC_ELLIPSIS>

=item C<DC_SIGCHAR_CC_ELLIPSIS_VARARGS>

=item C<DC_SIGCHAR_CC_CDECL>

=item C<DC_SIGCHAR_CC_STDCALL>

=item C<DC_SIGCHAR_CC_FASTCALL_MS>

=item C<DC_SIGCHAR_CC_FASTCALL_GNU>

=item C<DC_SIGCHAR_CC_THISCALL_MS>

=item C<DC_SIGCHAR_CC_THISCALL_GNU> - GNU C<thiscall>s are C<cdecl>, but keep specific sig char for clarity

=item C<DC_SIGCHAR_CC_ARM_ARM>

=item C<DC_SIGCHAR_CC_ARM_THUMB>

=item C<DC_SIGCHAR_CC_SYSCALL>

=back

=head2 Structures

=over

=item C<DEFAULT_ALIGNMENT> - Default value for data structure alignment

=back

=head1 Memory Functions

See Dyn::Call::Pointer for a list of direct memory manipulation functions which
may be imported with the C<:memory> tag.

=head1 Platform Support

The dyncall library runs on many different platforms and operating systems
(including Windows, Linux, OpenBSD, FreeBSD, macOS, DragonFlyBSD, NetBSD,
Plan9, iOS, Haiku, Nintendo DS, Playstation Portable, Solaris, Minix, Raspberry
Pi, ReactOS, etc.) and processors (x86, x64, arm (arm & thumb mode), arm64,
mips, mips64, ppc32, ppc64, sparc, sparc64, etc.).

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

dyncall OpenBSD FreeBSD macOS DragonFlyBSD NetBSD iOS ReactOS mips mips64 ppc32
ppc64 sparc sparc64 (AArch64) SystemV syscall eabi cdecl CallVM PowerPC
thiscall sig struct

=end stopwords

=cut
