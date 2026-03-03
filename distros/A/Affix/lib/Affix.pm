package Affix v1.0.8 {    # 'FFI' is my middle name!

    #~ |-----------------------------------|-----------------------------------||
    #~ |--------------------------4---5~---|--4--------------------------------||
    #~ |--7~\-----4---44-/777--------------|------7/4~-------------------------||
    #~ |-----------------------------------|-----------------------------------||
    use v5.40;
    use Exporter           qw[import];
    use vars               qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
    use warnings::register qw[Type];
    no warnings qw[experimental::try];
    use Carp                  qw[];
    use Config                qw[%Config];
    use File::Spec::Functions qw[rel2abs canonpath curdir path catdir];
    use File::Basename        qw[basename dirname];
    use File::Find            qw[find];
    use File::Temp            qw[tempdir];
    my $okay = 0;

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
    push @{ $EXPORT_TAGS{lib} }, qw[libm libc];
    $EXPORT_TAGS{types} = [
        qw[ typedef
            Void Bool
            Char UChar SChar WChar
            Short UShort
            Int UInt
            Long ULong
            LongLong ULongLong
            Float16 Float Double LongDouble
            Int8 SInt8 UInt8 Int16 SInt16 UInt16 Int32 SInt32 UInt32 Int64 SInt64 UInt64 Int128 SInt128 UInt128
            Float32 Float64
            Size_t SSize_t
            String WString
            Pointer Array LiveArray Struct LiveStruct Union Enum Callback CodeRef Complex Vector
            ThisCall attach_destructor
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

    sub attach_destructor ( $pin, $destructor, $lib //= () ) {
        Affix::_attach_destructor( $pin, $destructor, $lib );
    }
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
                    map { split /[:;]/, ( $ENV{$_} ) } grep { $ENV{$_} } qw[LD_LIBRARY_PATH DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH]
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
    $/x :
                qr/^
    (?:lib)?(?<name>\w+)
    \.$Config{so}
    (?:\.(?<version>[0-9]+(?:\.[0-9]+)*))?
    $/x;
        }
        my %store;
        find(
            sub {
                $File::Find::prune = 1 if !grep { canonpath $_ eq canonpath $File::Find::name } @$libdirs;
                return unless $_ =~ $regex;
                return unless defined $+{name};
                return unless $+{name} eq $lib;
                return unless -B $File::Find::name;
                my $lib_ver;
                $lib_ver = version->parse( $+{version} ) if defined $+{version};
                return unless ( defined $lib_ver && defined($ver) ? $ver == $lib_ver : 1 );
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

    sub _is_type ($thing) {
        return 1 if builtin::blessed($thing) && $thing->isa('Affix::Type');
        return 0 if !defined $thing || ref $thing;

        # Strictly check for signature characters
        return 1 if $thing =~ /^[\*\[\{\!<@]/;

        # Primitive types must match exactly or be followed by a delimiter
        return 1
            if $thing
            =~ /^(?:void|bool|[usw]?char|u?short|u?int|u?long(?:long)?|float|double|longdouble|s?size_t|s?int\d+|uint\d+|float\d+|m\d+[a-z]*)$/;
        return 0;
    }

    # Abstract
    sub Void ()       { Affix::Type::Primitive->new( name => 'void' ) }
    sub Bool ()       { Affix::Type::Primitive->new( name => 'bool' ) }
    sub Char ()       { Affix::Type::Primitive->new( name => 'char' ) }
    sub UChar()       { Affix::Type::Primitive->new( name => 'uchar' ) }
    sub SChar()       { Affix::Type::Primitive->new( name => 'char' ) }
    sub WChar()       { Affix::Type::Primitive->new( name => 'uint16' ) }
    sub Short ()      { Affix::Type::Primitive->new( name => 'short' ) }
    sub UShort ()     { Affix::Type::Primitive->new( name => 'ushort' ) }
    sub Int ()        { Affix::Type::Primitive->new( name => 'int' ) }
    sub UInt ()       { Affix::Type::Primitive->new( name => 'uint' ) }
    sub Long ()       { Affix::Type::Primitive->new( name => 'long' ) }
    sub ULong ()      { Affix::Type::Primitive->new( name => 'ulong' ) }
    sub LongLong ()   { Affix::Type::Primitive->new( name => 'longlong' ) }
    sub ULongLong ()  { Affix::Type::Primitive->new( name => 'ulonglong' ) }
    sub Float ()      { Affix::Type::Primitive->new( name => 'float' ) }
    sub Double ()     { Affix::Type::Primitive->new( name => 'double' ) }
    sub LongDouble () { Affix::Type::Primitive->new( name => 'longdouble' ) }
    sub Size_t ()     { Affix::Type::Primitive->new( name => 'size_t' ) }
    sub SSize_t ()    { Affix::Type::Primitive->new( name => 'ssize_t' ) }

    # Fixed-width
    sub SInt8()    { Affix::Type::Primitive->new( name => 'sint8' ) }
    sub Int8()     { Affix::Type::Primitive->new( name => 'sint8' ) }
    sub UInt8()    { Affix::Type::Primitive->new( name => 'uint8' ) }
    sub SInt16()   { Affix::Type::Primitive->new( name => 'sint16' ) }
    sub Int16()    { Affix::Type::Primitive->new( name => 'sint16' ) }
    sub UInt16()   { Affix::Type::Primitive->new( name => 'uint16' ) }
    sub SInt32()   { Affix::Type::Primitive->new( name => 'sint32' ) }
    sub Int32()    { Affix::Type::Primitive->new( name => 'sint32' ) }
    sub UInt32()   { Affix::Type::Primitive->new( name => 'uint32' ) }
    sub SInt64()   { Affix::Type::Primitive->new( name => 'sint64' ) }
    sub Int64()    { Affix::Type::Primitive->new( name => 'sint64' ) }
    sub UInt64()   { Affix::Type::Primitive->new( name => 'uint64' ) }
    sub SInt128()  { Affix::Type::Primitive->new( name => 'sint128' ) }
    sub Int128()   { Affix::Type::Primitive->new( name => 'sint128' ) }
    sub UInt128()  { Affix::Type::Primitive->new( name => 'uint128' ) }
    sub Float16()  { Affix::Type::Primitive->new( name => 'float16' ) }
    sub Float32()  { Affix::Type::Primitive->new( name => 'float32' ) }
    sub Float64 () { Affix::Type::Primitive->new( name => 'float64' ) }
    sub Char8()    { Affix::Type::Primitive->new( name => 'char8_t' ) }
    sub Char16()   { Affix::Type::Primitive->new( name => 'char16_t' ) }
    sub Char32()   { Affix::Type::Primitive->new( name => 'char32_t' ) }

    # SIMD aliases
    sub M256 ()  { Affix::Type::Primitive->new( name => 'm256' ) }
    sub M256d () { Affix::Type::Primitive->new( name => 'm256d' ) }
    sub M512 ()  { Affix::Type::Primitive->new( name => 'm512' ) }
    sub M512d () { Affix::Type::Primitive->new( name => 'm512d' ) }
    sub M512i () { Affix::Type::Primitive->new( name => 'm512i' ) }

    # Composites
    sub Pointer : prototype($) {
        my $t = ref( $_[0] ) ? $_[0]->[0] : $_[0];
        Affix::Type::Pointer->new( subtype => $t );
    }
    sub Struct : prototype($) { Affix::Type::Struct->new( members => $_[0] ) }

    sub LiveStruct : prototype($) {
        my $s = $_[0];
        $s = $s->()     if ref($s) eq 'CODE';
        $s = Struct($s) if ref($s) eq 'ARRAY';
        $s = "$s"       if builtin::blessed($s) && $s->isa('Affix::Type');
        return '+' . $s;
    }

    # Union[ i => Int, f => Float ] -> <i:int,f:float>
    sub Union : prototype($) { Affix::Type::Union->new( members => $_[0] ) }

    sub Array : prototype($) {
        my ( $type, $size ) = @{ $_[0] };
        return Affix::Type::Array->new( type => $type, count => $size );
    }

    sub LiveArray : prototype($) {
        my ( $type, $size ) = @{ $_[0] };
        return Pointer [ Array [ $type, $size ] ];
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

    sub ThisCall : prototype($) {
        my $cb = $_[0];
        if ( builtin::blessed($cb) && $cb->isa('Affix::Type::Callback') ) {

            # Prepend 'this' pointer
            unshift @{ $cb->params }, Pointer [Void];
            return $cb;
        }
        elsif ( !ref $cb && $cb =~ /^\*\(\((.*)\)->(.*)\)$/ ) {
            my ( $args, $ret ) = ( $1, $2 );
            $args = $args ? "*void,$args" : "*void";
            return "*(($args)->$ret)";
        }
        return $cb;
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
            if ( defined $next &&
                ( !ref($curr) || !builtin::blessed($curr) || !$curr->isa('Affix::Type') ) &&
                builtin::blessed($next) &&
                $next->isa('Affix::Type') ) {
                push @parts, "$curr:$next";
                $i++;
            }
            else {
                push @parts, "$curr";
            }
        }
        my $content = join( ',', @parts );
        return sprintf( $wrapper, $content );
    }

    sub typedef ( $name, $type //= () ) {
        ( my $clean_name = $name ) =~ s/^@//;
        if ( !defined $type ) {
            Affix::_typedef($clean_name);
        }
        else {
            if ( builtin::blessed($type) && $type->isa('Affix::Type::Enum') ) {
                my ( $const_map, $val_map ) = $type->resolve();
                my $pkg = caller;
                no strict 'refs';
                while ( my ( $const_name, $val ) = each %$const_map ) {
                    *{"${pkg}::${const_name}"} = sub () {$val};
                }
                &Affix::_register_enum_values( $clean_name, $val_map, $const_map );
            }
            if ( builtin::blessed($type) && $type->isa('Affix::Type') ) {
                Affix::_typedef("$clean_name = $type");
            }
            else {
                if ( $type =~ /^@/ ) {
                    Affix::_typedef($type);
                }
                else {
                    Affix::_typedef("$clean_name = $type");
                }
            }
        }
        my $pkg = caller;
        {
            no strict 'refs';
            if ( !defined &{"${pkg}::${name}"} ) {
                *{"${pkg}::${name}"} = sub {
                    return Affix::Type::Reference->new( name => $clean_name );
                };
            }
        }
        return 1;
    }
    package    #
        Affix::Type {
        use overload '""' => sub { shift->signature() }, fallback => 1;
        sub new       { my ( $class, %args ) = @_; bless \%args, $class }
        sub signature { die "Abstract method" }
    }
    package    #
        Affix::Type::Reference {
        our @ISA = qw[Affix::Type];
        sub signature { '@' . shift->{name} }
    }
    package    #
        Affix::Type::Primitive {
        our @ISA = qw[Affix::Type];
        use overload
            '|'      => sub { Affix::Type::Bitfield->new( type => $_[0], width => $_[1] ) },
            '""'     => sub { shift->signature() },
            fallback => 1;
        sub signature { shift->{name} }
    }
    package    #
        Affix::Type::Bitfield {
        our @ISA = qw[Affix::Type];
        sub signature { my $self = shift; $self->{type}->signature . ':' . $self->{width} }
    }
    package    #
        Affix::Type::Enum {
        our @ISA = qw[Affix::Type];
        use Carp;
        sub signature { 'e:' . shift->{type} }

        sub resolve {
            my $self = shift;
            return ( $self->{const_map}, $self->{values_map} ) if defined $self->{values_map};
            $self->{const_map}  = {};
            $self->{values_map} = {};
            my $counter = 0;
            for my $item ( @{ $self->{elements} } ) {
                my ( $name, $final_val );
                if ( !ref $item ) {
                    $name      = $item;
                    $final_val = $counter;
                }
                elsif ( ref $item eq 'ARRAY' ) {
                    my $raw_val;
                    ( $name, $raw_val ) = @$item;
                    if ( $raw_val =~ /^-?\d+$/ ) {
                        $final_val = $raw_val;
                    }
                    elsif ( $raw_val =~ /^0x[0-9a-fA-F]+$/ ) {
                        $final_val = hex($raw_val);
                    }
                    else {
                        $final_val = $self->_calculate_expr( $raw_val, $self->{const_map} );
                    }
                }
                else {
                    Carp::croak("Enum elements must be Strings or [Name => Value] ArrayRefs");
                }
                $self->{const_map}->{$name} = $final_val;
                $self->{values_map}->{$final_val} //= $name;
                $counter = $final_val + 1;
            }
            return ( $self->{const_map}, $self->{values_map} );
        }

        sub _calculate_expr {
            my ( $self, $expr, $lookup ) = @_;
            use integer;
            my @tokens = $expr =~ /(0x[0-9a-fA-F]+|\d+|[a-zA-Z_]\w*|<<|>>|&&|\|\||==|!=|<=|>=|[+\-*\/%|&^~!?:()<>])/g;
            for my $t (@tokens) {
                next if $t =~ /^(?:<<|>>|&&|\|\||==|!=|<=|>=|[+\-*\/%|&^~!?:()<>])$/;
                next if $t =~ /^\d+$/;
                next if $t =~ /^0x/;
                if ( exists $lookup->{$t} ) {
                    $t = $lookup->{$t};
                }
                else {
                    Carp::croak("Enum definition error: Unknown symbol '$t' in expression '$expr'");
                }
                $t = hex($t) if $t =~ /^0x/;
            }
            my @output_queue;
            my @op_stack;
            my %prec = (
                '*'           => [ 13, 1 ],
                '/'           => [ 13, 1 ],
                '%'           => [ 13, 1 ],
                '+'           => [ 12, 1 ],
                '-'           => [ 12, 1 ],
                '<<'          => [ 11, 1 ],
                '>>'          => [ 11, 1 ],
                '<'           => [ 10, 1 ],
                '<='          => [ 10, 1 ],
                '>'           => [ 10, 1 ],
                '>='          => [ 10, 1 ],
                '=='          => [ 9,  1 ],
                '!='          => [ 9,  1 ],
                '&'           => [ 8,  1 ],
                '^'           => [ 7,  1 ],
                '|'           => [ 6,  1 ],
                '&&'          => [ 5,  1 ],
                '||'          => [ 4,  1 ],
                '?'           => [ 3,  0 ],
                ':'           => [ 3,  0 ],
                'unary_plus'  => [ 14, 0 ],
                'unary_minus' => [ 14, 0 ],
                '!'           => [ 14, 0 ],
                '~'           => [ 14, 0 ],
                '('           => [ -1, 0 ],
            );
            my $expect_unary = 1;
            for my $token (@tokens) {
                if    ( $token =~ /^\d+$/ ) { push @output_queue, $token; $expect_unary = 0; }
                elsif ( $token eq '(' )     { push @op_stack,     $token; $expect_unary = 1; }
                elsif ( $token eq ')' ) {
                    while ( @op_stack && $op_stack[-1] ne '(' ) { push @output_queue, pop @op_stack; }
                    pop @op_stack;
                    $expect_unary = 0;
                }
                elsif ( $token eq '?' ) {
                    while ( @op_stack && $op_stack[-1] ne '(' && $prec{ $op_stack[-1] }[0] > $prec{$token}[0] ) { push @output_queue, pop @op_stack; }
                    push @op_stack, $token;
                    $expect_unary = 1;
                }
                elsif ( $token eq ':' ) {
                    while ( @op_stack && $op_stack[-1] ne '?' ) { push @output_queue, pop @op_stack; }
                    $expect_unary = 1;
                }
                else {
                    if ( $expect_unary && ( $token eq '+' || $token eq '-' || $token eq '!' || $token eq '~' ) ) {
                        $token = $token eq '+' ? 'unary_plus' : $token eq '-' ? 'unary_minus' : $token;
                    }
                    elsif ( !exists $prec{$token} ) { Carp::croak("Unknown token '$token'"); }
                    my $p1    = $prec{$token}[0];
                    my $assoc = $prec{$token}[1];
                    while (@op_stack) {
                        my $top = $op_stack[-1];
                        last if $top eq '(';
                        my $p2 = $prec{$top}[0];
                        if ( ( $assoc == 1 && $p1 <= $p2 ) || ( $assoc == 0 && $p1 < $p2 ) ) { push @output_queue, pop @op_stack; }
                        else                                                                 { last; }
                    }
                    push @op_stack, $token;
                    $expect_unary = 1;
                }
            }
            push @output_queue, pop @op_stack while @op_stack;
            my @stack;
            for my $token (@output_queue) {
                if    ( $token =~ /^\d+$/ )       { push @stack, $token; }
                elsif ( $token eq 'unary_plus' )  { }
                elsif ( $token eq 'unary_minus' ) { push @stack, -( pop @stack ); }
                elsif ( $token eq '!' )           { push @stack, int( !( pop @stack ) ); }
                elsif ( $token eq '~' )           { push @stack, ~( pop @stack ); }
                elsif ( $token eq '?' )           { my $f = pop @stack; my $t = pop @stack; my $c = pop @stack; push @stack, $c ? $t : $f; }
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
    package    #
        Affix::Type::Aggregate {
        our @ISA = qw[Affix::Type];

        sub signature {
            my $self    = shift;
            my $members = $self->{members};
            my $kind    = $self->{kind} // '{%s}';
            my @parts;
            for ( my $i = 0; $i < @$members; $i++ ) {
                my $curr = $members->[$i];
                my $next = $members->[ $i + 1 ];
                if ( defined $next &&
                    builtin::blessed($next)   &&
                    $next->isa('Affix::Type') &&
                    ( !builtin::blessed($curr) || !$curr->isa('Affix::Type') ) ) {
                    my $name = $curr;
                    my $type = $next;
                    $i++;
                    my $width = $members->[ $i + 1 ];
                    if ( defined $width && !ref($width) && $width =~ /^\d+$/ ) { push @parts, "$name:$type:$width"; $i++; }
                    else                                                       { push @parts, "$name:$type"; }
                }
                else { push @parts, "$curr"; }
            }
            return sprintf( $kind, join( ',', @parts ) );
        }
    }
    package    #
        Affix::Type::Struct {
        our @ISA = qw[Affix::Type::Aggregate];
        sub new { my $class = shift; my %args = @_; $args{kind} = '{%s}'; bless \%args, $class }
    }
    package    #
        Affix::Type::Union {
        our @ISA = qw[Affix::Type::Aggregate];
        sub new { my $class = shift; my %args = @_; $args{kind} = '<%s>'; bless \%args, $class }
    }
    package    #
        Affix::Type::Array {
        our @ISA = qw[Affix::Type];
        sub signature { my $self = shift; my $c = $self->{count} // '?'; return "[$c:" . $self->{type} . "]"; }
    }
    package    #
        Affix::Type::Pointer {
        our @ISA = qw[Affix::Type];
        sub signature { '*' . ( shift->{subtype} // 'void' ) }
    }
    package    #
        Affix::Type::Callback {
        our @ISA = qw[Affix::Type];
        sub params { shift->{params} }

        sub signature {
            my $self = shift;
            my @args = map { builtin::blessed($_) ? $_->signature : $_ } @{ $self->{params} };
            my $args = join( ',', @args );
            $args =~ s/,\;,/;/g;
            $args =~ s/,\;$/;/;
            my $r = builtin::blessed( $self->{ret} ) ? $self->{ret}->signature : $self->{ret};
            return "*(($args)->$r)";
        }
    }
    package    #
        Affix::Pointer {
        use v5.40;
        use overload '""' => \&address, '@{}' => \&_as_array, '%{}' => \&_as_hash, fallback => 1;
        sub address           { Affix::address(shift) }
        sub type              { Affix::_pin_type(shift) }
        sub element_type      { Affix::_pin_element_type(shift) }
        sub size              { Affix::_pin_size(shift) }
        sub count             { Affix::_pin_count(shift) }
        sub cast              { Affix::cast( shift, shift ) }
        sub _as_array         { my $self = shift; my @proxy; tie @proxy, 'Affix::Pointer::TiedArray', $self; return \@proxy; }
        sub _as_hash          { my $self = shift; my %proxy; tie %proxy, 'Affix::Pointer::TiedHash',  $self; return \%proxy; }
        sub attach_destructor { my ( $self, $destructor, $lib ) = @_; Affix::attach_destructor( $self, $destructor, $lib ); }
    }
    package    #
        Affix::Pointer::TiedHash {
        use v5.40;
        sub TIEHASH  { my ( $class, $ptr ) = @_; my $obj = $ptr->cast( "+" . $ptr->element_type ); return $obj; }
        sub FETCH    { my ( $self, $key ) = @_; return $self->{$key}; }
        sub STORE    { my ( $self, $key, $val ) = @_; $self->{$key} = $val; }
        sub EXISTS   { my ( $self, $key ) = @_; return exists $self->{$key}; }
        sub FIRSTKEY { my ($self) = @_; keys %$self; return each %$self; }
        sub NEXTKEY  { my ( $self, $last ) = @_; return each %$self; }
        sub SCALAR   { my ($self) = @_; return scalar %$self; }
        };
    package    #
        Affix::Pointer::TiedArray {
        use v5.40;
        sub TIEARRAY  { bless { pin => $_[1] }, $_[0] }
        sub FETCH     { my ( $self, $index ) = @_; Affix::_pin_get_at( $self->{pin}, $index ); }
        sub STORE     { my ( $self, $index, $value ) = @_; Affix::_pin_set_at( $self->{pin}, $index, $value ); }
        sub FETCHSIZE { my $self = shift; Affix::_pin_count( $self->{pin} ) // 0x7FFFFFFF; }
        sub EXISTS    { my ( $self, $index ) = @_; my $count = Affix::_pin_count( $self->{pin} ); return defined($count) ? ( $index < $count ) : 1; }
        sub DELETE    { die "Cannot delete elements from a C array" }
        sub CLEAR     { die "Cannot clear a C array" }
        };
    package    #
        Affix::Live {
        use v5.40;
        sub new      { my ( $class, $ref ) = @_; return bless $ref // {}, $class; }
        sub FETCH    { my ( $self, $key ) = @_; return $self->{$key}; }
        sub STORE    { my ( $self, $key, $val ) = @_; $self->{$key} = $val; }
        sub EXISTS   { my ( $self, $key ) = @_; return exists $self->{$key}; }
        sub FIRSTKEY { my ($self) = @_; keys %$self; return each %$self; }
        sub NEXTKEY  { my ( $self, $last ) = @_; return each %$self; }
        sub SCALAR   { my ($self) = @_; return scalar %$self; }
    }
};
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.
