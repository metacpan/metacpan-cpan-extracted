package Affix 0.10 {    # 'FFI' is my middle name!
    use strict;
    use warnings;
    no warnings 'redefine';
    use File::Spec::Functions qw[rel2abs canonpath curdir path];
    use File::Basename        qw[dirname];
    use File::Find            qw[find];
    use Config;
    use Sub::Util qw[subname];
    use Text::ParseWords;
    use Carp qw[];
    use vars qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
    use XSLoader;
    my $ok = XSLoader::load();
    END { _shutdown() if $ok; }
    #
    use parent 'Exporter';
    @EXPORT_OK          = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
    $EXPORT_TAGS{'all'} = \@EXPORT_OK;    # When you want to import everything

    #@{ $EXPORT_TAGS{'enum'} }             # Merge these under a single tag
    #    = sort map { defined $EXPORT_TAGS{$_} ? @{ $EXPORT_TAGS{$_} } : () }
    #    qw[types?]
    #    if 1 < scalar keys %EXPORT_TAGS;
    @EXPORT    # Export these tags (if prepended w/ ':') or functions by default
        = sort map { m[^:(.+)] ? @{ $EXPORT_TAGS{$1} } : $_ } qw[:default :types]
        if keys %EXPORT_TAGS > 1;
    @{ $EXPORT_TAGS{all} } = our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
    #
    my %_delay;

    sub AUTOLOAD {
        my $self = $_[0];           # Not shift, using goto.
        my $sub  = our $AUTOLOAD;
        if ( defined $_delay{$sub} ) {

            #warn 'Wrapping ' . $sub;
            #use Data::Dump;
            #ddx $_delay{$sub};
            my $template = qq'package %s {use Affix qw[:types]; sub{%s}->(); }';
            my $sig      = eval sprintf $template, $_delay{$sub}[0], $_delay{$sub}[4];
            Carp::croak $@ if $@;
            my $ret = eval sprintf $template, $_delay{$sub}[0], $_delay{$sub}[5];
            Carp::croak $@ if $@;

            #use Data::Dump;
            #ddx $_delay{$sub};
            #~ ddx locate_lib( $_delay{$sub}[1], $_delay{$sub}[2] );
            my $lib
                = defined $_delay{$sub}[1] ?
                scalar locate_lib( $_delay{$sub}[1], $_delay{$sub}[2] ) :
                undef;

            #~ use Data::Dump;
            #~ ddx [
            #~ $lib, (
            #~ $_delay{$sub}[3] eq $_delay{$sub}[6] ? $_delay{$sub}[3] :
            #~ [ $_delay{$sub}[3], $_delay{$sub}[6] ]
            #~ ),
            #~ $sig, $ret
            #~ ];
            my $cv = affix(
                $lib, (
                    $_delay{$sub}[3] eq $_delay{$sub}[6] ? $_delay{$sub}[3] :
                        [ $_delay{$sub}[3], $_delay{$sub}[6] ]
                ),
                $sig, $ret
            );
            Carp::croak 'Undefined subroutine &' . $_delay{$sub}[6] unless $cv;
            delete $_delay{$sub} if defined $_delay{$sub};
            return &$cv;
        }

        #~ elsif ( my $code = $self->can('SUPER::AUTOLOAD') ) {
        #~ return goto &$code;
        #~ }
        elsif ( $sub =~ /DESTROY$/ ) {
            return;
        }
        Carp::croak("Undefined subroutine &$sub called");
    }
    #
    sub MODIFY_CODE_ATTRIBUTES {
        my ( $package, $code, @attributes ) = @_;

        #use Data::Dump;
        #ddx \@_;
        my ( $library, $library_version, $signature, $return, $symbol, $full_name );
        for my $attribute (@attributes) {
            if ( $attribute =~ m[^Native(?:\(\s*(.+)\s*\)\s*)?$] ) {
                ( $library, $library_version ) = Text::ParseWords::parse_line( '\s*,\s*', 1, $1 );
                $library //= ();

                #warn $library;
                #warn $library_version;
                $library_version //= 0;
            }
            elsif ( $attribute =~ m[^Symbol\(\s*(['"])?\s*(.+)\s*\1\s*\)$] ) {
                $symbol = $2;
            }

           #elsif ( $attribute =~ m[^Signature\s*?\(\s*(.+?)?(?:\s*=>\s*(\w+)?)?\s*\)$] ) { # pretty
            elsif ( $attribute =~ m[^Signature\(\s*(\[.*\])\s*=>\s*(.*)\)$] ) {    # pretty
                $signature = $1;
                $return    = $2;
            }
            else { return $attribute }
        }
        $signature //= '[]';
        $return    //= 'Void';
        $full_name = subname $code;    #$library, $library_version,
        if ( !grep { !defined } $full_name ) {
            if ( !defined $symbol ) {
                $full_name =~ m[::(.*?)$];
                $symbol = $1;
            }

            #use Data::Dump;
            #ddx [
            #    $package,   $library, $library_version, $symbol,
            #    $signature, $return,  $full_name
            #];
            if ( defined &{$full_name} ) {    #no strict 'refs';

                # TODO: call this defined sub and pass the wrapped symbol and then the passed args
                #...;
                return affix(
                    locate_lib( $library, $library_version ),
                    ( $symbol eq $full_name ? $symbol : [ $symbol, $full_name ] ),
                    $signature, $return
                );
            }
            $_delay{$full_name}
                = [ $package, $library, $library_version, $symbol, $signature, $return,
                $full_name ];
        }
        return;
    }
    our $OS = $^O;

    sub locate_lib {
        my ( $name, $version ) = @_;
        CORE::state $_lib_cache;
        ( $name, $version ) = @$name if ref $name eq 'ARRAY';
        {
            my $i   = -1;
            my $pkg = __PACKAGE__;
            ($pkg) = caller( ++$i ) while $pkg eq __PACKAGE__;    # Dig out of the hole first
            my $ok = $pkg->can($name);
            $name = $ok->() if $ok;
        }
        $name // return ();                                       # NULL
        return $name if -e $name;
        return $2    if $name =~ m[{\s*(['"])(.+)\1\s*}];

        #$name = eval $name;
        $name =~ s[['"]][]g;
        #
        ($version) = version->parse($version)->stringify =~ m[^v?(.+)$];

        # warn $version;
        $version = $version ? qr[\.${version}] : qr/([\.\d]*)?/;
        if ( !defined $_lib_cache->{ $name . ';' . ( $version // '' ) } ) {
            if ( $OS eq 'MSWin32' ) {
                my $p;
                $name =~ s[\.dll$][];
                if ( -e $name . '.dll' ) {
                    $p = rel2abs canonpath( $name . '.dll' );
                }
                else {
                    require Win32;

# https://docs.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order#search-order-for-desktop-applications
                    my @dirs = grep {-d} (
                        dirname( rel2abs($^X) ),                                # 1. exe dir
                        Win32::GetFolderPath( Win32::CSIDL_SYSTEM() ),          # 2. sys dir
                        Win32::GetFolderPath( Win32::CSIDL_WINDOWS() ),         # 4. win dir
                        rel2abs(curdir),                                        # 5. cwd
                        path(),                                                 # 6. $ENV{PATH}
                        map { split /[:;]/, ( $ENV{$_} ) } grep { $ENV{$_} }    # X. User defined
                            qw[LD_LIBRARY_PATH DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH]
                    );
                    my @retval;

                    #warn $_ for sort { lc $a cmp lc $b } @dirs;
                    find(
                        {   wanted => sub {
                                $File::Find::prune = 1
                                    if !grep { $_ eq $File::Find::name } @dirs;    # no depth
                                push @retval, $_ if m{[/\\]${name}(-${version})?\.dll$}i;
                            },
                            no_chdir => 1
                        },
                        @dirs
                    );
                    return if !@retval;
                    $p = rel2abs pop @retval;
                }
                $_lib_cache->{ $name . ';' . ( $version // '' ) } = $p;
            }
            elsif ( $OS eq 'darwin' ) {
                my $p;
                if    ( -f $name . '.so' )     { $p = rel2abs $name . '.so' }
                elsif ( -f $name . '.dylib' )  { $p = rel2abs $name . '.dylib' }
                elsif ( -f $name . '.bundle' ) { $p = rel2abs $name . '.bundle' }
                elsif ( $name =~ /\.so$/ )     { $p = rel2abs $name }
                else {
# https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/UsingDynamicLibraries.html
                    my @dirs = grep { -d $_ } (
                        dirname( rel2abs($^X) ),    # 0. exe dir
                        rel2abs(curdir),            # 0. cwd
                        path(),                     # 0. $ENV{PATH}
                        map { rel2abs($_) }
                            qw[. ./lib/ ~/lib /usr/local/lib /usr/lib /System/Library/dyld/],
                        map      { split /[:;]/, ( $ENV{$_} ) }
                            grep { $ENV{$_} }
                            qw[LD_LIBRARY_PATH LC_LOAD_DYLIB DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH]
                    );
                    my @retval;
                    find(
                        {   wanted => sub {
                                $File::Find::prune = 1
                                    if !grep { $_ eq $File::Find::name } @dirs;    # no depth
                                push @retval, $_
                                    if /\b(?:lib)?${name}${version}\.(so|bundle|dylib)$/;
                            },
                            no_chdir => 1
                        },
                        @dirs
                    );
                    return if !@retval;
                    $p = rel2abs pop @retval;
                }
                $p = readlink $p if -l $p;
                $_lib_cache->{ $name . ';' . ( $version // '' ) } = $p;
            }
            else {
                my $p;
                if    ( -f $name )                     { $p = rel2abs $name }
                elsif ( -f $name . '.' . $Config{so} ) { $p = rel2abs $name . '.' . $Config{so} }
                else {
                    my $ext = $Config{so};
                    my @libs;

               # warn $name . '.' . $ext . $version;
               #\b(?:lib)?${name}(?:-[\d\.]+)?\.${ext}${version}
               #my @lines = map { [/^\t(.+)\s\((.+)\)\s+=>\s+(.+)$/] }
               #    grep {/\b(?:lib)?${name}(?:-[\d\.]+)?\.${ext}(?:\.${version})?$/} `ldconfig -p`;
               #push @retval, map { $_->[2] } grep { -f $_->[2] } @lines;
                    my @dirs = grep { -d $_ } (
                        dirname( rel2abs($^X) ),    # 0. exe dir
                        rel2abs(curdir),            # 0. cwd
                        path(),                     # 0. $ENV{PATH}
                        map { rel2abs($_) }
                            qw[. ./lib ~/lib /usr/local/lib /usr/lib /lib64 /lib /System/Library/dyld],
                        map      { split /[:;]/, ( $ENV{$_} ) }
                            grep { $ENV{$_} }
                            qw[LD_LIBRARY_PATH DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH]
                    );
                    my @retval;
                    find(
                        {   wanted => sub {
                                $File::Find::prune = 1
                                    if !grep { $_ eq $File::Find::name } @dirs;    # no depth
                                push @retval, $_
                                    if /\b(?:lib)?${name}(?:-[\d\.]+)?\.${ext}${version}$/;
                                push @retval, $_ if /\b(?:lib)?${name}(?:-[\d\.]+)?\.${ext}$/;
                            },
                            no_chdir => 1
                        },
                        @dirs
                    );
                    return if !@retval;
                    $p = rel2abs pop @retval;
                }
                $p = readlink $p if -l $p;
                $_lib_cache->{ $name . ';' . ( $version // '' ) } = rel2abs $p;
            }
        }
        return $_lib_cache->{ $name . ';' . ( $version // '' ) }
            // Carp::croak( 'Cannot locate symbol: ' . $name );
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

Affix - A Foreign Function Interface eXtension

=head1 SYNOPSIS

    use Affix;

    # bind to exported function
    affix( 'libfoo', 'bar', [Str, Float] => Double );
    print bar( 'Baz', 3.14 );

    # bind to exported function but with sugar
    sub bar : Native('libfoo') : Signature([Str, Float] => Double);
    print bar( 'Baz', 10.9 );

    # wrap an exported function in a code reference
    my $bar = wrap( 'libfoo', 'bar', [Str, Float] => Double );
    print $bar->( 'Baz', 3.14 );

    # bind an exported value to a Perl value
    pin( my $ver, 'libfoo', 'VERSION', Int );

=head1 DESCRIPTION

Affix is a wrapper around L<dyncall|https://dyncall.org/>.

Note: This is experimental software and is subject to change as long as this
disclaimer is here.

=head1 Basic Usage

The basic API here is rather simple but not lacking in power.

=head2 C<affix( ... )>

    affix( 'C:\Windows\System32\user32.dll', 'pow', [Double, Double] => Double );
    warn pow( 3, 5 );

    affix( 'foo', ['foo', 'foobar'] => [ Str ] );
    foobar( 'Hello' );

Attaches a given symbol in a named perl sub.

Parameters include:

=over

=item C<$lib>

path of the library as a string or pointer returned by L<< C<dlLoadLibrary( ...
)>|Dyn::Load/C<dlLoadLibrary( ... )> >>

=item C<$symbol_name>

the name of the symbol to call

Optionally, you may provide an array reference with the symbol's name and the
name of the subroutine

=item C<$parameters>

signature defining argument types in an array

=item C<$return>

optional return type

default is C<Void>

=back

Returns a code reference on success.

=head2 C<wrap( ... )>

Creates a wrapper around a given symbol in a given library.

    my $pow = wrap( 'C:\Windows\System32\user32.dll', 'pow', [Double, Double] => Double );
    warn $pow->(5, 10); # 5**10

Parameters include:

=over

=item C<$lib>

pointer returned by L<< C<dlLoadLibrary( ... )>|Dyn::Load/C<dlLoadLibrary( ...
)> >> or the path of the library as a string

=item C<$symbol_name>

the name of the symbol to call

=item C<$parameters>

signature defining argument types in an array

=item C<$return>

return type

=back

C<wrap( ... )> behaves exactly like C<affix( ... )> but returns an anonymous
subroutine.

=head1 C<:Native> CODE attribute

All the sugar is right here in the :Native code attribute. This API is inspired
by L<Raku's C<native> trait|https://docs.raku.org/language/nativecall>.

A simple example would look like this:

    use Affix;
    sub some_argless_function :Native('something');
    some_argless_function();

The first line imports various code attributes and types. The next line looks
like a relatively ordinary Perl sub declaration--with a twist. We use the
C<:Native> attribute in order to specify that the sub is actually defined in a
native library. The platform-specific extension (e.g., .so or .dll), as well as
any customary prefixes (e.g., lib) will be added for you.

The first time you call "some_argless_function", the "libsomething" will be
loaded and the "some_argless_function" will be located in it. A call will then
be made. Subsequent calls will be faster, since the symbol handle is retained.

Of course, most functions take arguments or return values--but everything else
that you can do is just adding to this simple pattern of declaring a Perl sub,
naming it after the symbol you want to call and marking it with the
C<:Native>-related attributes.

Except in the case you are using your own compiled libraries, or any other kind
of bundled library, shared libraries are versioned, i.e., they will be in a
file C<libfoo.so.x.y.z>, and this shared library will be symlinked to
C<libfoo.so.x>. By default, Affix will pick up that file if it's the only
existing one. This is why it's safer, and advisable, to always include a
version, this way:

    sub some_argless_function :Native('foo', v1.2.3)

Please check L<the section on the ABIE<sol>API version|/ABI/API version> for
more information.

=head2 Changing names

Sometimes you want the name of your Perl subroutine to be different from the
name used in the library you're loading. Maybe the name is long or has
different casing or is otherwise cumbersome within the context of the module
you are trying to create.

Affix provides the C<:Symbol> attribute for you to specify the name of the
native routine in your library that may be different from your Perl subroutine
name.

    package Foo;
    use Affix;
    sub init :Native('foo') :Symbol('FOO_INIT');

Inside of C<libfoo> there is a routine called C<FOO_INIT> but, since we're
creating a module called C<Foo> and we'd rather call the routine as
C<Foo::init> (instead of C<Foo::FOO_INIT>), we use the symbol trait to specify
the name of the symbol in C<libfoo> and call the subroutine whatever we want
(C<init> in this case).

=head2 Passing and returning values

Normal Perl signatures do not convey the type of arguments a native function
expects and what it returns so you must define them with our final attribute:
C<:Signature>

    use Affix;
    sub add :Native("calculator") :Signature([Int, Int] => Int);

Here, we have declared that the function takes two 32-bit integers and returns
a 32-bit integer. You can find the other types that you may pass L<further down
this page|/Types>.

=head1 Signatures

Affix's advisory signatures are required to give us a little hint about what we
should expect.

    [ Int, ArrayRef[ Int, 100 ], Str ] => Int

Arguments are defined in a list: C<[ Int, ArrayRef[ Char, 5 ], Str ]>

The return value comes next: C<Int>

To call the function with such a signature, your Perl would look like this:

    mh $int = func( 500, [ 'a', 'b', 'x', '4', 'H' ], 'Test');

See the aptly named sections entitled L<Types|/Types> for more on the possible
types and L<Calling Conventions/Calling Conventions> for flags that may also be
defined as part of your signature.

=head1 Library Paths and Names

The C<:Native> attribute, C<affix( ... )>, and C<wrap( ... )> all accept the
library name, the full path, or a subroutine returning either of the two. When
using the library name, the name is assumed to be prepended with lib and
appended with C<.so> (or just appended with C<.dll> on Windows), and will be
searched for in the paths in the C<LD_LIBRARY_PATH> (C<PATH> on Windows)
environment variable.

You can also put an incomplete path like C<'./foo'> and Affix will
automatically put the right extension according to the platform specification.
If you wish to suppress this expansion, simply pass the string as the body of a
block.

    sub bar :Native({ './lib/Non Standard Naming Scheme' });

B<BE CAREFUL>: the C<:Native> attribute and constant might be evaluated at
compile time.

=head2 ABI/API version

If you write C<:Native('foo')>, Affix will search C<libfoo.so> under Unix like
system (C<libfoo.dynlib> on macOS, C<foo.dll> on Windows). In most modern
system it will require you or the user of your module to install the
development package because it's recommended to always provide an API/ABI
version to a shared library, so C<libfoo.so> ends often being a symbolic link
provided only by a development package.

To avoid that, the C<:Native> attribute allows you to specify the API/ABI
version. It can be a full version or just a part of it. (Try to stick to Major
version, some BSD code does not care for Minor.)

    use Affix;
    sub foo1 :Native('foo', v1); # Will try to load libfoo.so.1
    sub foo2 :Native('foo', v1.2.3); # Will try to load libfoo.so.1.2.3

    sub pow : Native('m', v6) : Signature([Double, Double] => Double);

=head2 Calling into the standard library

If you want to call a function that's already loaded, either from the standard
library or from your own program, you can omit the library value or pass and
explicit C<undef>.

For example on a UNIX-like operating system, you could use the following code
to print the home directory of the current user:

    use Affix;
    use Data::Dumper;
    typedef PwStruct => Struct [
        name  => Str,     # username
        pass  => Str,     # hashed pass if shadow db isn't in use
        uuid  => UInt,    # user
        guid  => UInt,    # group
        gecos => Str,     # real name
        dir   => Str,     # ~/
        shell => Str      # bash, etc.
    ];
    sub getuid : Native : Signature([]=>Int);
    sub getpwuid : Native : Signature([Int]=>Pointer[PwStruct]);
    my $data = main::getpwuid( getuid() );
    print Dumper( ptr2sv( $data, Pointer [ PwStruct() ] ) );

=head1 Exported Variables

Variables exported by a library - also names "global" or "extern" variables -
can be accessed using C<pin( ... )>.

=head2 C<pin( ... )>

    pin( $errno, 'libc', 'errno', Int );
    print $errno;
    $errno = 0;

This code applies magic to C<$error> that binds it to the integer variable
named "errno" as exported by the L<libc> library.

Expected parameters include:

=over

=item C<$var>

Perl scalar that will be bound to the exported variable.

=item C<$lib>

pointer returned by L<< C<dlLoadLibrary( ... )>|Dyn::Load/C<dlLoadLibrary( ...
)> >> or the path of the library as a string

=item C<$symbol_name>

the name of the exported variable

=item C<$type>

type that data will be coerced in or out of as required

=back

This is likely broken on BSD. Patches welcome.

=head1 Memory Functions

To help toss raw data around, some standard memory related functions are
exposed here. You may import them by name or with the C<:memory> or C<:all>
tags.

=head2 C<malloc( ... )>

    my $ptr = malloc( $size );

Allocates C<$size> bytes of uninitialized storage.

=head2 C<calloc( ... )>

    my $ptr = calloc( $num, $size );

Allocates memory for an array of C<$num> objects of C<$size> and initializes
all bytes in the allocated storage to zero.

=head2 C<realloc( ... )>

    $ptr = realloc( $ptr, $new_size );

Reallocates the given area of memory. It must be previously allocated by
C<malloc( ... )>, C<calloc( ... )>, or C<realloc( ... )> and not yet freed with
a call to C<free( ... )> or C<realloc( ... )>. Otherwise, the results are
undefined.

=head2 C<free( ... )>

    free( $ptr );

Deallocates the space previously allocated by C<malloc( ... )>, C<calloc( ...
)>, or C<realloc( ... )>.

=head2 C<memchr( ... )>

    memchr( $ptr, $ch, $count );

Finds the first occurrence of C<$ch> in the initial C<$count> bytes (each
interpreted as unsigned char) of the object pointed to by C<$ptr>.

=head2 C<memcmp( ... )>

    my $cmp = memcmp( $lhs, $rhs, $count );

Compares the first C<$count> bytes of the objects pointed to by C<$lhs> and
C<$rhs>. The comparison is done lexicographically.

=head2 C<memset( ... )>

    memset( $dest, $ch, $count );

Copies the value C<$ch> into each of the first C<$count> characters of the
object pointed to by C<$dest>.

=head2 C<memcpy( ... )>

    memcpy( $dest, $src, $count );

Copies C<$count> characters from the object pointed to by C<$src> to the object
pointed to by C<$dest>.

=head2 C<memmove( ... )>

    memmove( $dest, $src, $count );

Copies C<$count> characters from the object pointed to by C<$src> to the object
pointed to by C<$dest>.

=head2 C<sizeof( ... )>

    my $size = sizeof( Int );
    my $size1 = sizeof( Struct[ name => Str, age => Int ] );

Returns the size, in bytes, of the L<type|/Types> passed to it.

=head2 C<offsetof( ... )>

    my $struct = Struct[ name => Str, age => Int ];
    my $offset = offsetof( $struct, 'age' );

Returns the offset, in bytes, from the beginning of a structure including
padding, if any.

=head1 Utility Functions

Here's some thin cushions for the rougher edges of wrapping libraries.

They may be imported by name for now but might be renamed, removed, or changed
in the future.

=head2 C<cast( ... )>

    my $hash = cast( $ptr, Struct[i => Int, ... ] );

This function will parse a pointer into a given target type.

The source pointer would have normally been obtained from a call to a native
subroutine that returned a pointer, a lvalue pointer to a native subroutine,
or, as part of a C<Struct[ ... ]>.

=head2 C<DumpHex( ... )>

    DumpHex( $ptr, $length );

Dumps C<$length> bytes of raw data from a given point in memory.

This is a debugging function that probably shouldn't find its way into your
code and might not be public in the future.

=head1 Types

Raku offers a set of native types with a fixed, and known, representation in
memory but this is Perl so we need to do the work ourselves with a pseudo-type
system. Affix supports the fundamental types (void, int, etc.), aggregates
(struct, array, union), and .

=head2 Fundamental Types with Native Representation

    Affix       C99                   Rust    C#          pack()  Raku
    ----------------------------------------------------------------------------
    Void        void                  ->()    void/NULL   -
    Bool        _Bool                 bool    bool        -       bool
    Char        int8_t                i8      sbyte       c       int8
    UChar       uint8_t               u8      byte        C       byte, uint8
    Short       int16_t               i16     short       s       int16
    UShort      uint16_t              u16     ushort      S       uint16
    Int         int32_t               i32     int         i       int32
    UInt        uint32_t              u32     uint        I       uint32
    Long        int64_t               i64     long        l       int64, long
    ULong       uint64_t              u64     ulong       L       uint64, ulong
    LongLong    -/long long           i128                q       longlong
    ULongLong   -/unsigned long long  u128                Q       ulonglong
    Float       float                 f32                 f       num32
    Double      double                f64                 d       num64
    SSize_t     SSize_t                                           SSize_t
    Size_t      size_t                                            size_t
    Str         char *
    WStr        wchar_t

Given sizes are minimums measured in bits

=head3 C<Void>

The C<Void> type corresponds to the C C<void> type. It is generally found in
typed pointers representing the equivalent to the C<void *> pointer in C.

    sub malloc :Native :Signature([Size_t] => Pointer[Void]);
    my $data = malloc( 32 );

As the example shows, it's represented by a parameterized C<Pointer[ ... ]>
type, using as parameter whatever the original pointer is pointing to (in this
case, C<void>). This role represents native pointers, and can be used wherever
they need to be represented in a Perl script.

In addition, you may place a C<Void> in your signature to skip a passed
argument.

=head3 C<Bool>

Boolean type may only have room for one of two values: C<true> or C<false>.

=head3 C<Char>

Signed character. It's guaranteed to have a width of at least 8 bits.

Pointers (C<Pointer[Char]>) might be better expressed with a C<Str>.

=head3 C<UChar>

Unsigned character. It's guaranteed to have a width of at least 8 bits.

=head3 C<Short>

Signed short integer. It's guaranteed to have a width of at least 16 bits.

=head3 C<UShort>

Unsigned short integer. It's guaranteed to have a width of at least 16 bits.

=head3 C<Int>

Basic signed integer type.

It's guaranteed to have a width of at least 16 bits. However, on 32/64 bit
systems it is almost exclusively guaranteed to have width of at least 32 bits.

=head3 C<UInt>

Basic unsigned integer type.

It's guaranteed to have a width of at least 16 bits. However, on 32/64 bit
systems it is almost exclusively guaranteed to have width of at least 32 bits.

=head3 C<Long>

Signed long integer type. It's guaranteed to have a width of at least 32 bits.

=head3 C<ULong>

Unsigned long integer type. It's guaranteed to have a width of at least 32
bits.

=head3 C<LongLong>

Signed long long integer type. It's guaranteed to have a width of at least 64
bits.

=head3 C<ULongLong>

Unsigned long long integer type. It's guaranteed to have a width of at least 64
bits.

=head3 C<Float>

L<Single precision floating-point
type|https://en.wikipedia.org/wiki/Single-precision_floating-point_format>.

=head3 C<Double>

L<Double precision floating-point
type|https://en.wikipedia.org/wiki/Double-precision_floating-point_format>.

=head3 C<SSize_t>

Signed integer type.

=head3 C<Size_t>

Unsigned integer type often expected as the result of C<sizeof> or C<offsetof>
but can be found elsewhere.

=head2 C<Str>

Automatically handle null terminated character pointers with this rather than
trying using C<Pointer[Char]> and doing it yourself.

You'll learn a bit more about C<Pointer[...]> and other parameterized types in
the next section.

=head2 C<WStr>

A null-terminated wide string is a sequence of valid wide characters, ending
with a null character.

=head1 Parameterized Types

Some types must be provided with more context data.

=head2 C<Pointer[ ... ]>

    Pointer[Int]  ~~ int *
    Pointer[Void] ~~ void *

Create pointers to (almost) all other defined types including C<Struct> and
C<Void>.

To handle a pointer to an object, see L<InstanceOf>.

Void pointers (C<Pointer[Void]>) might be created with C<malloc> and other
memory related functions.

=begin future

=head2 C<Aggregate>

This is currently undefined and reserved for possible future use.

=end future

=head2 C<Struct[ ... ]>

    Struct[                    struct {
        dob => Struct[              struct {
            year  => Int,               int year;
            month => Int,   ~~          int month;
            day   => Int                int day;
        ],                          } dob;
        name => Str,                char *name;
        wId  => Long                long wId;
    ];                          };

A struct consists of a sequence of members with storage allocated in an ordered
sequence (as opposed to C<Union>, which is a type consisting of a sequence of
members where storage overlaps).

A C struct that looks like this:

    struct {
        char *make;
        char *model;
        int   year;
    };

...would be defined this way:

    Struct[
        make  => Str,
        model => Str,
        year  => Int
    ];

All fundamental and aggregate types may be found inside of a C<Struct>.

=head2 C<ArrayRef[ ... ]>

The elements of the array must pass the additional size constraint.

An array length must be given:

    ArrayRef[Int, 5];   # int arr[5]
    ArrayRef[Any, 20];  # SV * arr[20]
    ArrayRef[Char, 5];  # char arr[5]
    ArrayRef[Str, 10];  # char *arr[10]

=head2 C<Union[ ... ]>

A union is a type consisting of a sequence of members with overlapping storage
(as opposed to C<Struct>, which is a type consisting of a sequence of members
whose storage is allocated in an ordered sequence).

The value of at most one of the members can be stored in a union at any one
time and the union is only as big as necessary to hold its largest member
(additional unnamed trailing padding may also be added). The other members are
allocated in the same bytes as part of that largest member.

A C union that looks like this:

    union {
        char  c[5];
        float f;
    };

...would be defined this way:

    Union[
        c => ArrayRef[Char, 5],
        f => Float
    ];

=head2 C<CodeRef[ ... ]>

A value where C<ref($value)> equals C<CODE>. This would be how callbacks are
defined.

The argument list and return value must be defined. For example,
C<CodeRef[[Int, Int]=>Int]> ~~ C<typedef int (*fuc)(int a, int b);>; that is to
say our function accepts two integers and returns an integer.

    CodeRef[[] => Void];                # typedef void (*function)();
    CodeRef[[Pointer[Int]] => Int];     # typedef Int (*function)(int * a);
    CodeRef[[Str, Int] => Struct[...]]; # typedef struct Person (*function)(chat * name, int age);

=head2 C<InstanceOf[ ... ]>

    InstanceOf['Some::Class']

A blessed object of a certain type. When used as an lvalue, the result is
properly blessed. As an rvalue, the reference is checked to be a subclass of
the given package.

=head2 C<Any>

Anything you dump here will be passed along unmodified. We hand off a pointer
to the C<SV*> perl gives us without copying it.

=head2 C<Enum[ ... ]>

The value of an C<Enum> is defined by its underlying type which includes
C<Int>, C<Char>, etc.

This type is declared with an list of strings.

    Enum[ 'ALPHA', 'BETA' ];
    # ALPHA = 0
    # BETA  = 1

Unless an enumeration constant is defined in an array reference, its value is
the value one greater than the value of the previous enumerator in the same
enumeration. The value of the first enumerator (if it is not defined) is zero.

    Enum[ 'A', 'B', [C => 10], 'D', [E => 1], 'F', [G => 'F + C'] ];
    # A = 0
    # B = 1
    # C = 10
    # D = 11
    # E = 1
    # F = 2
    # G = 12

    Enum[ [ one => 'a' ], 'two', [ 'three' => 'one' ] ]
    # one   = a
    # two   = b
    # three = a

As you can see, enum values may allude to earlier defined values and even basic
arithmetic is supported.

Additionally, if you C<typedef> the enum into a given namespace, you may refer
to elements by name. They are defined as dualvars so that works:

    typedef color => Enum[ 'RED', 'GREEN', 'BLUE' ];
    print color::RED();     # RED
    print int color::RED(); # 0

=head2 C<IntEnum[ ... ]>

Same as C<Enum>.

=head2 C<UIntEnum[ ... ]>

C<Enum> but with unsigned integers.

=head2 C<CharEnum[ ... ]>

C<Enum> but with signed chars.

=head1 Calling Conventions

Handle with care! Using these without understanding them can break your code!

Refer to L<the dyncall manual|https://dyncall.org/docs/manual/manualse11.html>,
L<http://www.angelcode.com/dev/callconv/callconv.html>,
L<https://en.wikipedia.org/wiki/Calling_convention>, and your local
university's Comp Sci department for a deeper explanation.

Anyway, here are the current options:

=over

=item C<CC_DEFAULT>

=item C<CC_THISCALL>

=item C<CC_ELLIPSIS>

=item C<CC_ELLIPSIS_VARARGS>

=item C<CC_CDECL>

=item C<CC_STDCALL>

=item C<CC_FASTCALL_MS>

=item C<CC_FASTCALL_GNU>

=item C<CC_THISCALL_MS>

=item C<CC_THISCALL_GNU>

=item C<CC_ARM_ARM>

=item C<CC_ARM_THUMB>

=item C<CC_SYSCALL>

=back

When used in L<signatures/Signatures>, most of these cause the internal
argument stack to be reset. The exception is C<CC_ELLIPSIS_VARARGS> which is
used prior to binding varargs of variadic functions.

=head1 Examples

The best example of use might be L<LibUI>. Brief examples will be found in
C<eg/>. Very short examples might find their way here.

=head2 Microsoft Windows

Here is an example of a Windows API call:

    use Affix;
    sub MessageBoxA :Native('user32') :Signature([Int, Str, Str, Int] => Int);
    MessageBoxA(0, "We have NativeCall", "ohai", 64);

=head2 Short tutorial on calling a C function

This is an example for calling a standard function and using the returned
information.

C<getaddrinfo> is a POSIX standard function for obtaining network information
about a network node, e.g., C<google.com>. It is an interesting function to
look at because it illustrates a number of the elements of Affix.

The Linux manual provides the following information about the C callable
function:

    int getaddrinfo(const char *node, const char *service,
       const struct addrinfo *hints,
       struct addrinfo **res);

The function returns a response code 0 for success and 1 for error. The data
are extracted from a linked list of C<addrinfo> elements, with the first
element pointed to by C<res>.

From the table of Affix types we know that an C<int> is C<Int>. We also know
that a C<char *> is best expressed with C<Str>. But C<addrinfo> is a structure,
which means we will need to write our own type class. However, the function
declaration is straightforward:

    TODO

=head1 Features

Not all features of dyncall are supported on all platforms, for those, the
underlying library defines macros you can use to detect support. These values
are exposed under the C<Affix::Feature> package:

=over

=item C<Affix::Feature::Syscall()>

If true, your platform supports a syscall calling conventions.

=item C<Affix::Feature::AggrByVal()>

If true, your platform supports passing around aggregates (struct, union) by
value.

=back

=head1 See Also

Check out L<FFI::Platypus> for a more robust and mature FFI

Examples found in C<eg/>.

L<LibUI> for a larger demo project based on Affix

L<Types::Standard> for the inspiration of the advisory types system.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

dyncall OpenBSD FreeBSD macOS DragonFlyBSD NetBSD iOS ReactOS mips mips64 ppc32
ppc64 sparc sparc64 co-existing varargs variadic struct enum eXtension rvalue
dualvars libsomething versioned errno syscall

=end stopwords

=cut
