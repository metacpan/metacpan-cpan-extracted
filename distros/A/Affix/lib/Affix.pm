package Affix v1.0.6 {    # 'FFI' is my middle name!

    #~ |-----------------------------------|-----------------------------------||
    #~ |--------------------------4---5~---|--4--------------------------------||
    #~ |--7~\-----4---44-/777--------------|------7/4~-------------------------||
    #~ |-----------------------------------|-----------------------------------||
    use v5.40;
    use vars               qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
    use warnings::register qw[Type];
    use feature            qw[class];
    no warnings qw[experimental::class experimental::try];
    use Carp                  qw[];
    use Config                qw[%Config];
    use File::Spec::Functions qw[rel2abs canonpath curdir path catdir];
    use File::Basename        qw[basename dirname];
    use File::Find            qw[find];
    use File::Temp            qw[tempdir];
    #
    my $okay = 0;
    #
    BEGIN {
        use XSLoader;
        $DynaLoad::dl_debug = $DynaLoad::dl_debug = 1;
        $okay               = XSLoader::load();
        my $platform
            = 'Affix::Platform::' .
            ( ( $^O eq 'MSWin32' ) ? 'Windows' :
                $^O eq 'darwin'                                                                   ? 'MacOS' :
                ( $^O eq 'freebsd' || $^O eq 'openbsd' || $^O eq 'netbsd' || $^O eq 'dragonfly' ) ? 'BSD' :
                'Unix' );

        #~ warn $platform;
        #~ use base $platform;
        eval 'use ' . $platform . ' qw[:all];';
        $@ && die $@;
        our @ISA = ($platform);
    }

    #~ $EXPORT_TAGS{pin}    = [qw[pin unpin]];
    #~ $EXPORT_TAGS{memory} = [
    #~ qw[ affix wrap pin unpin
    #~ cast
    #~ errno getwinerror
    #~ malloc calloc realloc free
    #~ memchr memcmp memset memcpy memmove
    #~ sizeof offsetof alignof
    #~ raw hexdump],
    #~ ];
    push @{ $EXPORT_TAGS{lib} }, qw[libm libc];
    $EXPORT_TAGS{types} = [
        qw[ typedef
            Void Bool
            Char UChar SChar WChar
            Short UShort
            Int UInt
            Long ULong
            LongLong ULongLong
            Float Double LongDouble
            Int8 SInt8 UInt8 Int16 SInt16 UInt16 Int32 SInt32 UInt32 Int64 SInt64 UInt64 Int128 SInt128 UInt128
            Float32 Float64
            Size_t SSize_t
            String WString
            Pointer Array Struct Union Enum Callback CodeRef Complex Vector
            Packed VarArgs
            SV
            File PerlIO
            StringList
            Buffer SockAddr
            M256 M256d M512 M512d M512i
        ]
    ];
    {
        my %seen;
        push @{ $EXPORT_TAGS{default} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} } for qw[core types lib];
    }
    {
        my %seen;
        push @{ $EXPORT_TAGS{all} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} } for keys %EXPORT_TAGS;
    }
    #
    @EXPORT    = sort @{ $EXPORT_TAGS{default} };    # XXX: Don't do this...
    @EXPORT_OK = sort @{ $EXPORT_TAGS{all} };
    #
    sub libm() { CORE::state $m //= find_library('m'); $m }
    sub libc() { CORE::state $c //= find_library('c'); $c }
    #
    our $OS = $^O;
    my $is_win = $OS eq 'MSWin32';
    my $is_mac = $OS eq 'darwin';
    my $is_bsd = $OS =~ /bsd/;
    my $is_sun = $OS =~ /(solaris|sunos)/;
    #
    sub locate_libs ( $lib, $version //= () ) {
        $lib =~ s[^lib][];
        my $ver;
        if ( defined $version ) {
            require version;
            $ver = version->parse($version);
        }

        #~ warn $lib;
        #~ warn $version;
        #~ warn "Win: $is_win";
        #~ warn "Mac: $is_mac";
        #~ warn "BSD: $is_bsd";
        #~ warn "Sun: $is_sun";
        CORE::state $libdirs;
        if ( !defined $libdirs ) {
            if ($is_win) {
                require Win32;
                $libdirs = [ Win32::GetFolderPath( Win32::CSIDL_SYSTEM() ) . '/', Win32::GetFolderPath( Win32::CSIDL_WINDOWS() ) . '/', ];
            }
            else {
                $libdirs = [
                    ( split ' ', $Config{libsdirs} ),
                    map { warn $ENV{$_}; split /[:;]/, ( $ENV{$_} ) }
                        grep { $ENV{$_} } qw[LD_LIBRARY_PATH DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH]
                ];
            }
            no warnings qw[once];
            require DynaLoader;
            $libdirs = [
                grep { -d $_ } map { rel2abs($_) } qw[. ./lib ~/lib /usr/local/lib /usr/lib /lib /usr/lib/system], @DynaLoader::dl_library_path,
                @$libdirs
            ];
        }
        CORE::state $regex;
        if ( !defined $regex ) {
            $regex = $is_win ?
                qr/^
        (?:lib)?(?<name>\w+)
        (?:[_-](?<version>[0-9\-\._]+))?_*
        \.$Config{so}
        $/ix :
                $is_mac ?
                qr/^
        (?:lib)?(?<name>\w+)
        (?:\.(?<version>[0-9]+(?:\.[0-9]+)*))?
        \.(?:so|dylib|bundle)
        $/x :    # assume *BSD or linux
                qr/^
        (?:lib)?(?<name>\w+)
        \.$Config{so}
        (?:\.(?<version>[0-9]+(?:\.[0-9]+)*))?
        $/x;
        }
        my %store;

        #~ warn join ', ', @$libdirs;
        my %_seen;
        find(
            0 ?
                sub {    # This is rather slow...
                warn $File::Find::name;
                return if $store{ basename $File::Find::name };

                #~ return if $_seen{basename $File::Find::name}++;
                return if !-e $File::Find::name;
                warn basename $File::Find::name;
                warn;
                $File::Find::prune = 1 if !grep { canonpath $_ eq canonpath $File::Find::name } @$libdirs;
                /$regex/ or return;
                warn;
                $+{name} eq $lib or return;
                warn;
                my $lib_ver;
                $lib_ver = version->parse( $+{version} ) if defined $+{version};
                $store{ canonpath $File::Find::name } = { %+, path => $File::Find::name, ( defined $lib_ver ? ( version => $lib_ver ) : () ) }
                    if ( defined($ver) && defined($lib_ver) ? $lib_ver == $ver : 1 );
                } :
                sub {
                $File::Find::prune = 1 if !grep { canonpath $_ eq canonpath $File::Find::name } @$libdirs;

                #~ return                 if -d $_;
                return unless $_ =~ $regex;
                return unless defined $+{name};
                return unless $+{name} eq $lib;
                return unless -B $File::Find::name;
                my $lib_ver;
                $lib_ver = version->parse( $+{version} ) if defined $+{version};
                return unless ( defined $lib_ver && defined($ver) ? $ver == $lib_ver : 1 );

                #~ use Data::Dump;
                #~ warn $File::Find::name;
                #~ ddx %+;
                $store{ canonpath $File::Find::name } //= { %+, path => $File::Find::name, ( defined $lib_ver ? ( version => $lib_ver ) : () ) };
                },
            @$libdirs
        );
        values %store;
    }

    sub locate_lib( $name, $version //= () ) {
        return $name if $name && -B $name;
        CORE::state $cache //= {};
        return $cache->{$name}{ $version // '' }->{path} if defined $cache->{$name}{ $version // '' };
        if ( !$version ) {
            return $cache->{$name}{''}{path} = rel2abs($name)                       if -B rel2abs($name);
            return $cache->{$name}{''}{path} = rel2abs( $name . '.' . $Config{so} ) if -B rel2abs( $name . '.' . $Config{so} );
        }
        my $libname = basename $name;
        $libname =~ s/^lib//;
        $libname =~ s/\..*$//;
        return $cache->{$libname}{ $version // '' }->{path} if defined $cache->{$libname}{ $version // '' };
        my @libs = locate_libs( $name, $version );

        #~ warn;
        #~ use Data::Dump;
        #~ warn join ', ', @_;
        #~ ddx \@_;
        #~ ddx $cache;
        if (@libs) {
            ( $cache->{$name}{ $version // '' } ) = @libs;
            return $cache->{$name}{ $version // '' }->{path};
        }
        ();
    }

    # Regex to heuristically identify if a string is a valid infix type signature.
    # Matches primitives, pointers (*), arrays ([), structs ({), unions (<), named types (@), etc.
    my $IS_TYPE = qr{^
        (?:
            (?:
                void|bool|
                [usw]?char|
                u?short|
                u?int|
                u?long(?:long)?|
                float|double|longdouble|
                s?size_t|
                s?int\d+|uint\d+|
                float\d+|
                m\d+[a-z]*
            )\b
            |
            e:|c\[|v\[|
            \*|\[|\{|\!|<|\(|@
        )
    }x;

    # Abstract
    sub Void ()       {'void'}
    sub Bool ()       {'bool'}
    sub Char ()       {'char'}
    sub UChar()       {'uchar'}
    sub SChar()       {'char'}
    sub WChar()       {'uint16'}
    sub Short ()      {'short'}
    sub UShort ()     {'ushort'}
    sub Int ()        {'int'}
    sub UInt ()       {'uint'}
    sub Long ()       {'long'}
    sub ULong ()      {'ulong'}
    sub LongLong ()   {'longlong'}
    sub ULongLong ()  {'ulonglong'}
    sub Float ()      {'float'}
    sub Double ()     {'double'}
    sub LongDouble () {'longdouble'}
    sub Size_t ()     {'size_t'}
    sub SSize_t ()    {'ssize_t'}

    # Fixed-width
    sub SInt8()    {'sint8'}
    sub Int8()     {'sint8'}
    sub UInt8()    {'uint8'}
    sub SInt16()   {'sint16'}
    sub Int16()    {'sint16'}
    sub UInt16()   {'uint16'}
    sub SInt32()   {'sint32'}
    sub Int32()    {'sint32'}
    sub UInt32()   {'uint32'}
    sub SInt64()   {'sint64'}
    sub Int64()    {'sint64'}
    sub UInt64()   {'uint64'}
    sub SInt128()  {'sint128'}
    sub Int128()   {'sint128'}
    sub UInt128()  {'uint128'}
    sub Float32()  {'float32'}
    sub Float64 () {'float64'}
    sub Char8()    {'char8_t'}
    sub Char16()   {'char16_t'}
    sub Char32()   {'char32_t'}

    # SIMD aliases
    sub M256 ()  {'m256'}
    sub M256d () {'m256d'}
    sub M512 ()  {'m512'}
    sub M512d () {'m512d'}
    sub M512i () {'m512i'}

    # Composites
    sub Pointer : prototype($) {
        my $t = ref( $_[0] ) ? $_[0]->[0] : $_[0];
        Affix::Type::Pointer->new( subtype => $t );
    }

    # Struct[ id => Int, score => Double ] -> {id:int,score:double}
    sub Struct : prototype($) { Affix::Type::Struct->new( members => $_[0] ) }

    # Union[ i => Int, f => Float ] -> <i:int,f:float>
    sub Union : prototype($) { Affix::Type::Union->new( members => $_[0] ) }

    sub Array : prototype($) {
        my ( $type, $size ) = @{ $_[0] };
        Affix::Type::Array->new( type => $type, count => $size );
    }

    # Callback[ [Int, Int] => Void ] -> (int,int)->void
    # Callback[ [String, VarArgs, Int] => Void ] -> (*char;int)->void
    sub Callback : prototype($) {
        my $args = $_[0];
        Affix::Type::Callback->new( params => $args->[0], ret => $args->[1] );
    }

    # Complex[ Double ] -> c[double]
    sub Complex : prototype($) {
        my $type = ref( $_[0] ) ? $_[0]->[0] : $_[0];
        return "c[$type]";
    }

    # Vector[ 4, Float ] -> v[4:float]
    sub Vector : prototype($) {
        my ( $size, $type ) = @{ $_[0] };
        return "v[$size:$type]";
    }

    # Enum[ Int ] -> e:int
    # Enum[ [ K=>V, ... ], Int ] -> e:int (We ignore the values for the signature)
    sub Enum : prototype($) {
        my $args = $_[0];
        return Affix::Type::Enum->new( elements => $args, type => Int() );
    }

    sub IntEnum : prototype($) {
        my $args = $_[0];
        return Affix::Type::Enum->new( elements => $args, type => Int() );
    }

    sub CharEnum : prototype($) {
        my $args = $_[0];
        return Affix::Type::Enum->new( elements => $args, type => Char() );
    }

    sub UIntEnum : prototype($) {
        my $args = $_[0];
        return Affix::Type::Enum->new( elements => $args, type => UInt() );
    }

    # Packed[ Struct[...] ]        -> !{...}
    # Packed( 4, [ Struct[...] ] ) -> !4:{...}
    sub Packed : prototype($) {
        if ( @_ == 2 && !ref( $_[0] ) ) {
            my ( $align, $content ) = @_;
            my $agg = ref($content) eq 'ARRAY' ? _build_aggregate( $content, '{%s}' ) : $content;
            return "!$align:$agg";
        }
        my $content = $_[0];
        my $agg     = ref($content) eq 'ARRAY' ? _build_aggregate( $content, '{%s}' ) : $content;
        return "!$agg";
    }

    # Special marker for Variadic functions
    sub VarArgs () {';'}

    # Semantic aliases and convienient types
    sub String ()     {'*char'}
    sub WString ()    {'*ushort'}
    sub SV()          {'@SV'}
    sub File ()       {'@File'}
    sub PerlIO ()     {'@PerlIO'}
    sub StringList () {'@StringList'}
    sub Buffer ()     {'@Buffer'}
    sub SockAddr ()   {'@SockAddr'}

    # Helper for Struct/Union to handle "Name => Type" syntax
    sub _build_aggregate {
        my ( $args, $wrapper ) = @_;
        my @parts;
        for ( my $i = 0; $i < @$args; $i++ ) {
            my $curr = $args->[$i];
            my $next = $args->[ $i + 1 ];

            # Heuristic: If current is NOT a type, and next IS a type, treat as Key => Value
            if ( defined $next && $curr !~ $IS_TYPE && $next =~ $IS_TYPE ) {
                push @parts, "$curr:$next";
                $i++;    # Skip the type
            }
            else {
                # Anonymous member
                push @parts, $curr;
            }
        }
        my $content = join( ',', @parts );
        return sprintf( $wrapper, $content );
    }
    {

        sub typedef ( $name, $type //= () ) {
            ( my $clean_name = $name ) =~ s/^@//;

            # Handle Forward Declarations: typedef 'Node';
            if ( !defined $type ) {    # Register forward decl with XS
                Affix::_typedef($clean_name);
            }
            else {
                # Handle Enum Constants (Pure Perl Logic)
                if ( builtin::blessed($type) && $type->isa('Affix::Type::Enum') ) {
                    my ( $const_map, $val_map ) = $type->resolve();
                    my $pkg = caller;
                    no strict 'refs';
                    while ( my ( $const_name, $val ) = each %$const_map ) {

                        # TODO: builtin::export_lexically
                        # Install enum values as constants: STATE_IDLE() -> 0
                        *{"${pkg}::${const_name}"} = sub () {$val};
                    }

                    # Register values map for Dualvar support in XS
                    Affix::_register_enum_values( $clean_name, $val_map );
                }

                # Register Definition with XS
                # The object stringifies to its signature (e.g. "e:int" or "{...}")
                Affix::_typedef("$clean_name = $type");
            }

            # Install Type Constructor: MachineState() -> Ref object
            my $pkg = caller;
            {
                no strict 'refs';

                # Avoid redefining if it exists (though arguably typedef SHOULD redefine)
                if ( !defined &{"${pkg}::${name}"} ) {
                    *{"${pkg}::${name}"} = sub {
                        return '@' . $clean_name;
                    };
                }
            }
            return 1;
        }
        class Affix::Type v0.12.0 {
            use overload
                '""' => sub { shift->signature() },
            fallback => 1;
            method signature {...}
        };

        class Affix::Type::Reference : isa(Affix::Type) {
            field $name : param;
            method signature { '@' . $name }
        };

        class Affix::Type::Enum : isa(Affix::Type) {
            use Carp;
            field $elements : param;
            field $type : param //= Affix::Int();

            # Lazy-built cache for values
            field $values_map;
            field $const_map;
            method signature() { return 'e:' . $type; }

            method resolve() {
                return ( $const_map, $values_map ) if defined $values_map;
                $const_map  = {};    # Name -> Int
                $values_map = {};    # Int  -> Name
                my $counter = 0;
                for my $item (@$elements) {
                    my ( $name, $final_val );

                    # Determine Name and Raw Value Source
                    if ( !ref $item ) {

                        # Case: 'NAME' (Auto-increment)
                        $name      = $item;
                        $final_val = $counter;
                    }
                    elsif ( ref $item eq 'ARRAY' ) {

                        # Case: [ NAME => VALUE ]
                        my $raw_val;
                        ( $name, $raw_val ) = @$item;

                        # Calculate Value
                        if ( $raw_val =~ /^-?\d+$/ ) {

                            # Literal Integer
                            $final_val = $raw_val;
                        }
                        elsif ( $raw_val =~ /^0x[0-9a-fA-F]+$/ ) {

                            # Literal Hex
                            $final_val = hex($raw_val);
                        }
                        else {
                            # Calculated String (e.g., "FLAG_A | FLAG_B")
                            $final_val = $self->_calculate_expr( $raw_val, $const_map );
                        }
                    }
                    else {
                        Carp::croak("Enum elements must be Strings or [Name => Value] ArrayRefs");
                    }

                    # Store and Increment
                    $const_map->{$name} = $final_val;

                    # Only map value->name if not already mapped (first name for a value wins in C usually)
                    $values_map->{$final_val} //= $name;
                    $counter = $final_val + 1;
                }
                return ( $const_map, $values_map );
            }

            # Shunting-yard algorithm
            # Handles: + - * / % << >> | & ^ ~ ! ( ) && || == != < <= > >= ? :
            method _calculate_expr( $expr, $lookup ) {
                use integer;    # Force signed integer arithmetic to match C enums. This ensures ~0 becomes -1, not 18446744073709551615.

                # Tokenize: Split on operators
                # Regex matches:
                # - Multi-char ops: << >> && || == != <= >=
                # - Single-char ops: + - * / % | & ^ ~ ! ( ) ? : < >
                # - Numbers (hex/dec)
                # - Identifiers
                my @tokens = $expr =~ /(0x[0-9a-fA-F]+|\d+|[a-zA-Z_]\w*|<<|>>|&&|\|\||==|!=|<=|>=|[+\-*\/%|&^~!?:()<>])/g;

                # Resolve Identifiers
                for my $t (@tokens) {
                    next if $t =~ /^(?:<<|>>|&&|\|\||==|!=|<=|>=|[+\-*\/%|&^~!?:()<>])$/;
                    next if $t =~ /^\d+$/;
                    next if $t =~ /^0x/;
                    if ( exists $lookup->{$t} ) {
                        $t = $lookup->{$t};
                    }
                    else {
                        # Provide a cleaner error message
                        Carp::croak("Enum definition error: Unknown symbol '$t' in expression '$expr'");
                    }

                    # Convert hex strings to numbers immediately if found
                    $t = hex($t) if $t =~ /^0x/;
                }

                # Shunting-yard
                my @output_queue;
                my @op_stack;

                # Precedence and Associativity (1=Left, 0=Right)
                my %prec = (
                    '*'          => [ 13, 1 ],
                    '/'          => [ 13, 1 ],
                    '%'          => [ 13, 1 ],
                    '+'          => [ 12, 1 ],
                    '-'          => [ 12, 1 ],
                    '<<'         => [ 11, 1 ],
                    '>>'         => [ 11, 1 ],
                    '<'          => [ 10, 1 ],
                    '<='         => [ 10, 1 ],
                    '>'          => [ 10, 1 ],
                    '>='         => [ 10, 1 ],
                    '=='         => [ 9,  1 ],
                    '!='         => [ 9,  1 ],
                    '&'          => [ 8,  1 ],
                    '^'          => [ 7,  1 ],
                    '|'          => [ 6,  1 ],
                    '&&'         => [ 5,  1 ],
                    '||'         => [ 4,  1 ],
                    '?'          => [ 3,  0 ],
                    ':'          => [ 3,  0 ],                                                                    # Ternary
                    'unary_plus' => [ 14, 0 ], 'unary_minus' => [ 14, 0 ], '!' => [ 14, 0 ], '~' => [ 14, 0 ],    # Unary
                    '('          => [ -1, 0 ],
                );
                my $expect_unary = 1;
                for my $token (@tokens) {
                    if ( $token =~ /^\d+$/ ) {
                        push @output_queue, $token;
                        $expect_unary = 0;
                    }
                    elsif ( $token eq '(' ) {
                        push @op_stack, $token;
                        $expect_unary = 1;
                    }
                    elsif ( $token eq ')' ) {
                        while ( @op_stack && $op_stack[-1] ne '(' ) {
                            push @output_queue, pop @op_stack;
                        }
                        pop @op_stack;    # Discard '('
                        $expect_unary = 0;
                    }
                    elsif ( $token eq '?' ) {    # Ternary Start
                        while ( @op_stack && $op_stack[-1] ne '(' && $prec{ $op_stack[-1] }[0] > $prec{$token}[0] ) {
                            push @output_queue, pop @op_stack;
                        }
                        push @op_stack, $token;
                        $expect_unary = 1;
                    }
                    elsif ( $token eq ':' ) {    # Ternary Mid
                        while ( @op_stack && $op_stack[-1] ne '?' ) {
                            push @output_queue, pop @op_stack;
                        }

                        # Don't pop '?' yet, we need it for the final evaluation
                        $expect_unary = 1;
                    }
                    else {
                        # Handle Unary Operators
                        if ( $expect_unary && ( $token eq '+' || $token eq '-' || $token eq '!' || $token eq '~' ) ) {
                            $token = $token eq '+' ? 'unary_plus' : $token eq '-' ? 'unary_minus' : $token;
                        }
                        elsif ( !exists $prec{$token} ) {
                            Carp::croak("Unknown token '$token'");
                        }
                        my $p1    = $prec{$token}[0];
                        my $assoc = $prec{$token}[1];
                        while (@op_stack) {
                            my $top = $op_stack[-1];
                            last if $top eq '(';
                            my $p2 = $prec{$top}[0];
                            if ( ( $assoc == 1 && $p1 <= $p2 ) || ( $assoc == 0 && $p1 < $p2 ) ) {
                                push @output_queue, pop @op_stack;
                            }
                            else {
                                last;
                            }
                        }
                        push @op_stack, $token;
                        $expect_unary = 1;
                    }
                }
                push @output_queue, pop @op_stack while @op_stack;

                # RPN Evaluator
                my @stack;
                for my $token (@output_queue) {
                    if ( $token =~ /^\d+$/ ) {
                        push @stack, $token;
                    }
                    elsif ( $token eq 'unary_plus' ) {    # No-op
                    }
                    elsif ( $token eq 'unary_minus' ) {
                        push @stack, -( pop @stack );
                    }
                    elsif ( $token eq '!' ) {
                        push @stack, int( !( pop @stack ) );
                    }
                    elsif ( $token eq '~' ) {
                        push @stack, ~( pop @stack );
                    }
                    elsif ( $token eq '?' ) {             # Ternary Op: stack is [cond, true_val, false_val]
                        my $false_val = pop @stack;
                        my $true_val  = pop @stack;
                        my $cond      = pop @stack;
                        push @stack, $cond ? $true_val : $false_val;
                    }
                    else {
                        my $b = pop @stack;
                        my $a = pop @stack;
                        if    ( $token eq '+' )  { push @stack, $a + $b; }
                        elsif ( $token eq '-' )  { push @stack, $a - $b; }
                        elsif ( $token eq '*' )  { push @stack, $a * $b; }
                        elsif ( $token eq '/' )  { push @stack, int( $a / $b ); }
                        elsif ( $token eq '%' )  { push @stack, $a % $b; }
                        elsif ( $token eq '<<' ) { push @stack, $a << $b; }
                        elsif ( $token eq '>>' ) { push @stack, $a >> $b; }
                        elsif ( $token eq '|' )  { push @stack, $a | $b; }
                        elsif ( $token eq '&' )  { push @stack, $a & $b; }
                        elsif ( $token eq '^' )  { push @stack, $a ^ $b; }
                        elsif ( $token eq '==' ) { push @stack, int( $a == $b ); }
                        elsif ( $token eq '!=' ) { push @stack, int( $a != $b ); }
                        elsif ( $token eq '<' )  { push @stack, int( $a < $b ); }
                        elsif ( $token eq '<=' ) { push @stack, int( $a <= $b ); }
                        elsif ( $token eq '>' )  { push @stack, int( $a > $b ); }
                        elsif ( $token eq '>=' ) { push @stack, int( $a >= $b ); }
                        elsif ( $token eq '&&' ) { push @stack, int( $a && $b ); }
                        elsif ( $token eq '||' ) { push @stack, int( $a || $b ); }
                    }
                }
                return $stack[0];
            }
        }

        class Affix::Type::Aggregate : isa(Affix::Type) {
            field $members : param;                      # ArrayRef of [ Name => Type, ... ]
            field $kind : param //= __CLASS__->_KIND;    # '{%s}' or '<%s>'

            method signature() {
                my @parts;

                # Iterate pairs
                for ( my $i = 0; $i < @$members; $i++ ) {
                    my $curr = $members->[$i];
                    my $next = $members->[ $i + 1 ];

                    # Heuristic: Key => Value detection
                    # If $next looks like a type (or is a Type object), treat $curr as name
                    if ( defined $next && $self->_is_type($next) && !$self->_is_type($curr) ) {
                        push @parts, "$curr:$next";
                        $i++;
                    }
                    else {
                        push @parts, "$curr";
                    }
                }
                return sprintf( $kind, join( ',', @parts ) );
            }

            method _is_type($thing) {
                return 1 if builtin::blessed($thing) && $thing->isa('Affix::Type');

                # Fallback regex for raw strings
                return $thing =~ qr{^
                    (?:
                        (?:
                            void|bool|
                            [usw]?char|
                            u?short|
                            u?int|
                            u?long(?:long)?|
                            float|double|longdouble|
                            s?size_t|
                            s?int\d+|uint\d+|
                            float\d+|
                            m\d+[a-z]*
                        )\b
                        |
                        e:|c\[|v\[|
                        \*|\[|\{|\!|<|\(|@
                    )
                }x;
            }
        }

        class Affix::Type::Struct : isa(Affix::Type::Aggregate) {
            use constant _KIND => '{%s}';
        }

        class Affix::Type::Union : isa(Affix::Type::Aggregate) {
            use constant _KIND => '<%s>';
        }

        class Affix::Type::Array : isa(Affix::Type) {
            field $type  : param;
            field $count : param;

            method signature() {
                my $c = $count // '?';
                return "[$c:$type]";
            }
        }

        class Affix::Type::Pointer : isa(Affix::Type) {
            field $subtype : param;

            method signature() {
                return '*' . ( $subtype // 'void' );
            }
        }

        class Affix::Type::Callback : isa(Affix::Type) {
            field $params : param;    # ArrayRef
            field $ret    : param;

            method signature() {
                my $args = join( ',', @$params );

                # Handle varargs marker placement if present
                $args =~ s/,\;,/;/g;
                $args =~ s/,\;$/;/;
                return "*(($args)->$ret)";
            }
        }
    }
}
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.
