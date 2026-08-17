package Affix::Wrap v1.2.5 {
    use v5.40;
    use feature 'class';
    no warnings 'experimental::class';
    no warnings 'experimental::builtin';
    use Path::Tiny;
    use Capture::Tiny qw[capture];
    use JSON::PP;
    use File::Basename qw[basename];
    use Carp           qw[];
    use Affix          qw[];
    #
    class    #
        Affix::Wrap::Type {
        use Affix qw[Void];
        field $name     : reader : param //= 'void';
        field $is_const : reader : param //= 0;
        method to_string { ( $is_const ? 'const ' : '' ) . $self->name }
        use overload '""' => 'to_string', fallback => 1;

        # Factory method to parse a C type string into objects
        sub parse ( $class, $t ) {
            return $class->new( name => 'void' ) unless defined $t;

            # Cleanup
            $t =~ s/__attribute__\s*\(\(.*\)\)//g;
            $t =~ s/\b(restrict|volatile)\b//g;
            $t =~ s/^\s+|\s+$//g;

            # Function Pointers: Ret (*)(Args)
            if ( $t =~ /^(.+?)\s*\(\*\)\s*\((.*)\)$/ ) {
                my ( $ret_str, $args_str ) = ( $1, $2 );
                my @args;
                if ( $args_str ne '' && $args_str ne 'void' ) {

                    # Simple split; for complex nested pointers, Clang driver is preferred
                    @args = map { $class->parse($_) } split( /\s*,\s*/, $args_str );
                }
                return Affix::Wrap::Type::CodeRef->new( ret => $class->parse($ret_str), params => \@args );
            }

            # Arrays: Type[N]
            if ( $t =~ /^(.*)\s*\[(\d+)\]$/ ) {
                return Affix::Wrap::Type::Array->new( of => $class->parse($1), count => $2 );
            }

            # Pointers: Type * [const]
            # We match the outermost pointer and its trailing const qualifier
            if ( $t =~ /^(.*)\s*\*\s*(const)?$/ ) {
                my ( $inner, $is_ptr_const ) = ( $1, $2 );
                return Affix::Wrap::Type::Pointer->new( of => $class->parse($inner), is_const => ( $is_ptr_const ? 1 : 0 ) );
            }

            # Base Types: [const] Name
            # Only strip the const if it's at this level
            my $const = ( $t =~ s/\bconst\b//g ) ? 1 : 0;
            $t =~ s/^\s+|\s+$//g;
            return $class->new( name => $t, is_const => $const );
        }

        sub _type_map ( $self //= () ) {
            state $type_map = {
                void                 => 'Void',
                bool                 => 'Bool',
                short                => 'Short',
                'unsigned short'     => 'UShort',
                char                 => 'Char',
                'signed char'        => 'SChar',
                'unsigned char'      => 'UChar',
                int                  => 'Int',
                'unsigned int'       => 'UInt',
                long                 => 'Long',
                'unsigned long'      => 'ULong',
                'long long'          => 'LongLong',
                'unsigned long long' => 'ULongLong',
                float                => 'Float',
                double               => 'Double',
                'long double'        => 'LongDouble',

                # Extended stdint.h
                int8_t    => 'Int8',
                sint8_t   => 'SInt8',
                uint8_t   => 'UInt8',
                int16_t   => 'Int16',
                sint16_t  => 'SInt16',
                uint16_t  => 'UInt16',
                int32_t   => 'Int32',
                sint32_t  => 'SInt32',
                uint32_t  => 'UInt32',
                int64_t   => 'Int64',
                sint64_t  => 'SInt64',
                uint64_t  => 'UInt64',
                int128_t  => 'Int128',
                sint128_t => 'SInt128',
                uint128_t => 'UInt128',

                # Fast & Least stdint.h types
                uint_fast8_t   => 'UInt8',
                int_fast8_t    => 'Int8',
                uint_fast16_t  => 'UInt16',
                int_fast16_t   => 'Int16',
                uint_fast32_t  => 'UInt32',
                int_fast32_t   => 'Int32',
                uint_fast64_t  => 'UInt64',
                int_fast64_t   => 'Int64',
                uint_least8_t  => 'UInt8',
                int_least8_t   => 'Int8',
                uint_least16_t => 'UInt16',
                int_least16_t  => 'Int16',
                uint_least32_t => 'UInt32',
                int_least32_t  => 'Int32',
                uint_least64_t => 'UInt64',
                int_least64_t  => 'Int64',

                # Architecture specific
                size_t    => 'Size_t',
                ssize_t   => 'SSize_t',
                ptrdiff_t => 'SSize_t',
                intptr_t  => 'SSize_t',
                uintptr_t => 'Size_t',
                off_t     => 'SSize_t',
                pid_t     => 'Int',
                wchar_t   => 'WChar',
                time_t    => 'Int64',

                # Variadic
                '...'               => 'VarArgs',
                va_list             => 'VarArgs',
                '__builtin_va_list' => 'VarArgs',

                # Standard library structures mapped to pointers
                'char[]'    => 'String',
                'file*'     => 'File',
                file        => 'Void',
                jmp_buf     => 'Void',
                _jbtype     => 'Void',
                tm          => 'Void',
                'struct tm' => 'Void'
            };
            return $type_map;
        }

        method _clean_name {
            my $t = $self->name;
            $t =~ s/^(?:struct|union|enum)\s+//;
            $t =~ s/\s*\*+$//;
            $t =~ s/^\s+|\s+$//g;
            return $t;
        }

        method affix_type {
            my $clean = $self->_clean_name;
            my $map   = $self->_type_map;
            my $key   = lc $clean;

            # Get the CamelCase Perl sub name (e.g. 'Int', 'Double', or the cleaned Custom Name with parens)
            my $out = exists $map->{$key} ? $map->{$key} : ( $clean =~ /^[a-zA-Z_]\w*$/ ? "$clean()" : 'Void' );

            # Apply Const wrapper if this level is qualified
            return $is_const ? "Const[$out]" : $out;
        }

        method affix {
            use Affix qw[Void Const];
            my $clean = lc $self->_clean_name;
            my $map   = $self->_type_map;
            my $res;
            if ( exists $map->{$clean} ) {
                my $mapped = $map->{$clean};
                no strict 'refs';
                my $fn = "Affix::$mapped";
                $res = defined &{$fn} ? $fn->() : "\@$mapped";
            }
            else {
                my $raw_name = $self->_clean_name;
                $res = ( $raw_name =~ /^[a-z_]\w*$/i ) ? "\@$raw_name" : Void();
            }
            return $is_const ? Const [$res] : $res;
        }
    }
    class    #
        Affix::Wrap::Type::Pointer : isa(Affix::Wrap::Type) {
        use Affix qw[Pointer Const];
        field $of : reader : param;
        method name { $of->name . '*' }

        method affix_type {
            my $res = 'Pointer[' . $of->affix_type . ']';
            return $self->is_const ? "Const[$res]" : $res;
        }

        method affix {
            my $res = Pointer [ $of->affix ];
            return $self->is_const ? Const [$res] : $res;
        }
        };
    class    #
        Affix::Wrap::Type::Array : isa(Affix::Wrap::Type) {
        use Affix qw[Array];
        field $of    : reader : param;
        field $count : reader : param;
        method name       { $of->name . '[' . $count . ']' }
        method affix_type { 'Array[' . $of->affix_type . ', ' . $count . ']' }
        method affix      { Array [ $of->affix, $count ] }
        };
    class    #
        Affix::Wrap::Type::CodeRef : isa(Affix::Wrap::Type) {
        use Affix qw[Callback];
        field $ret    : reader : param;
        field $params : reader : param;    # ArrayRef of Types

        method name {
            sprintf '%s (*)(%s)', $ret->name, join( ', ', map { $_->name } @$params );
        }

        method affix_type {
            sprintf 'Callback[[%s] => %s]', join( ', ', map { $_->affix_type } @$params ), $ret->affix_type;
        }

        method affix {
            Callback [ [ map { $_->affix } @$params ], $ret->affix ];
        }
        };
    class    #
        Affix::Wrap::Argument {
        field $type : reader : param;
        field $name : reader : param //= '';
        method to_string { length($name) ? $type->to_string . ' ' . $name : $type->to_string }
        use overload '""' => 'to_string', fallback => 1;
        method affix_type { $type->affix_type }
        method affix      { $type->affix }
    }
    class    #
        Affix::Wrap::Entity {
        field $name         : reader : param //= '';
        field $doc          : reader : param //= ();
        field $file         : reader : param //= '';
        field $line         : reader : param //= 0;
        field $end_line     : reader : param //= 0;
        field $start_offset : reader : param //= 0;
        field $end_offset   : reader : param //= 0;
        field $is_merged    : reader = 0;
        field $doc_data = undef;
        method mark_merged { $is_merged = 1 }
        method _base($p)   { return '' unless defined $p; $p =~ s{^.*[/\\]}{}; return $p }

        method describe {
            return sprintf '[%s] %s (%s:%d)', __CLASS__ =~ s/^Affix::Wrap:://r, $name, $self->_base($file), $line;
        }

        # Helper to convert Doxygen/Markdown to POD
        method _format_pod($text) {
            $text =~ s/^\s+|\s+$//g;
            $text =~ s/`([^`]+)`/C<$1>/g;                     # Code blocks: `code` -> C<code>
            $text =~ s/\*\*([^*]+)\*\*/B<$1>/g;               # Bold: **text** -> B<text>
            $text =~ s/\*([^*]+)\*/I<$1>/g;                   # Italic: *text* -> I<text>
            $text =~ s/\[([^\]]+)\]\(([^)]+)\)/L<$1|$2>/g;    # Links: [foo](bar) -> L<foo|bar>
            return $text;
        }

        method parse_doc () {
            return $doc_data if defined $doc_data;
            my $raw           = $doc // '';
            my $data          = { brief => '', desc => '', params => {}, return => '', };
            my @lines         = split /\n/, $raw;
            my $current_tag   = 'desc';
            my $current_param = undef;
            foreach my $line (@lines) {
                $line =~ s/^\s+|\s+$//g;
                next unless length $line;
                if ( $line =~ /^[@\\]brief\s+(.*)/ ) {
                    $data->{brief} = $1;
                    $current_tag = 'brief';
                }
                elsif ( $line =~ /^[@\\]param(?:\[.*?\])?\s+(\w+)\s+(.*)/ ) {
                    $data->{params}{$1} = $2;
                    $current_param      = $1;
                    $current_tag        = 'param';
                }
                elsif ( $line =~ /^[@\\]returns?\s+(.*)/ ) {
                    $data->{return} = $1;
                    $current_tag = 'return';
                }
                elsif ( $line =~ /^[@\\](\w+)\s*(.*)/ ) {
                    my $tag = ucfirst($1);
                    $data->{desc} .= "\n\nB<$tag:> $2";
                    $current_tag = 'desc';
                }
                else {
                    if    ( $current_tag eq 'brief' )                           { $data->{brief}                  .= ' ' . $line; }
                    elsif ( $current_tag eq 'param' && defined $current_param ) { $data->{params}{$current_param} .= ' ' . $line; }
                    elsif ( $current_tag eq 'return' )                          { $data->{return}                 .= ' ' . $line; }
                    else                                                        { $data->{desc} .= ( length( $data->{desc} ) ? "\n" : '' ) . $line; }
                }
            }
            if ( length( $data->{brief} ) == 0 && length( $data->{desc} ) > 0 ) {
                if ( $data->{desc} =~ s/^(.+?\.)\s+//s ) { $data->{brief} = $1; }
            }
            return $doc_data = $data;
        }

        method pod {
            my $d   = $self->parse_doc;
            my $out = '=head2 ' . $self->name . "\n\n";
            $out .= $self->_format_pod( $d->{brief} ) . "\n\n" if length $d->{brief};
            $out .= $self->_format_pod( $d->{desc} ) . "\n\n"  if length $d->{desc};

            # Format parameters
            if ( keys %{ $d->{params} } ) {
                $out .= "=over\n\n";
                my @param_names = sort keys %{ $d->{params} };

                # If we have args metadata (e.g. Function), use it for ordering
                if ( $self->can('args') && ref( $self->args ) eq 'ARRAY' ) {
                    @param_names = map { $_->name } grep { exists $d->{params}{ $_->name } } @{ $self->args };

                    # Fallback for params documented but not in signature (rare but possible in C macros/varargs)
                    my %seen = map { $_ => 1 } @param_names;
                    push @param_names, grep { !$seen{$_} } sort keys %{ $d->{params} };
                }
                for my $name (@param_names) {
                    $out .= "=item C<$name>\n\n" . $self->_format_pod( $d->{params}{$name} ) . "\n\n";
                }
                $out .= "=back\n\n";
            }

            # Format return value
            if ( length $d->{return} ) {
                $out .= "B<Returns:> " . $self->_format_pod( $d->{return} ) . "\n\n";
            }
            $out;
        }
        method affix( $lib //= (), $pkg //= () ) { return undef }
    }
    class    #
        Affix::Wrap::Member {
        use Affix qw[Void];
        field $name       : reader : param //= '';
        field $type       : reader : param //= '';
        field $doc        : reader : param //= ();
        field $definition : reader : param //= ();

        method affix_type {
            return $definition->affix_type if defined $definition;
            return $type->affix_type;
        }

        method affix {
            return $definition->affix if defined $definition;
            return $type->affix       if builtin::blessed($type);

            # Fallback: if it's just a string, wrap it in a Reference object
            return Affix::Type::Reference->new( name => $type =~ s/^@//r ) if defined $type;
            return Affix::Void();
        }
    }
    class    #
        Affix::Wrap::Macro : isa(Affix::Wrap::Entity) {
        field $value : reader : param //= ();
        method set_value ($v) { $value = $v }

        method affix_type {
            my $v = $self->value // return '';

            # Sanitize C string concatenations in macros (e.g. "a" "b" -> "ab")
            $v =~ s/"\s+"//g;

            # Strip outer quotes from C string literals
            if    ( $v =~ /^"(.*)"$/ ) { $v = $1; $v =~ s/\\(.)/$1/g; }
            elsif ( $v =~ /^'(.*)'$/ ) { $v = $1; }

            # Protect against Perl-internal reserved names (starting with __)
            # and macros containing unresolved C calls or backslashes
            if ( $self->name =~ /^__/ || $v =~ /[\\()]/ ) {
                return '# use constant ' . $self->name . " => $v";
            }
            if ( $v =~ /^-?(?:0x[\da-fA-F]+|\d+(?:\.\d+)?)$/ ) {
                return sprintf 'use constant %s => %s', $self->name, $v;
            }
            $v =~ s/'/\\'/g;
            return "use constant " . $self->name . " => '$v'";
        }

        method affix ( $lib //= (), $pkg //= () ) {
            if ( $pkg && defined $value && length $value ) {
                my $val = $value;
                if ( $val =~ /^"(.*)"$/ || $val =~ /^'(.*)'$/ ) { $val = $1; }
                if ( $pkg =~ /^[a-zA-Z_]\w*(::\w+)*$/ && $self->name =~ /^[a-zA-Z_]\w*$/ ) {
                    no strict 'refs';
                    no warnings 'redefine';
                    *{ "${pkg}::" . $self->name } = sub () {$val};
                }
            }
            sub () {$value};
        }
        };
    class    #
        Affix::Wrap::Variable : isa(Affix::Wrap::Entity) {
        field $type : reader : param;

        method affix_type {

            # Safely declare the package var, then attempt to pin it
            sprintf "our \$%s;\n    try { Affix::pin(\$%s, \$lib, '%s', %s) } catch(\$e) { }", $self->name, $self->name, $self->name,
                $type->affix_type;
        }

        method affix ( $lib, $pkg //= () ) {
            my $var;
            try {
                Affix::pin( $var, $lib, $self->name, $type->affix );
            }
            catch ($e) {

                # Symbol missing; that's fine
            }
            return $var;
        }
        };
    class    #
        Affix::Wrap::Typedef : isa(Affix::Wrap::Entity) {
        field $underlying : reader : param;

        method affix_type {

            # Return ONLY the underlying expression (e.g. 'Int' or 'Struct[...]')
            # This prevents the "typedef 'name' => typedef 'name' => ..." recursion.
            return $underlying->affix_type;
        }

        method affix ( $lib //= (), $pkg //= () ) {

            # If the underlying is a complex type (Struct/Enum), we want to return
            # that object so the batch gets "@Name = {body}"
            # If it's another Typedef, we return a Reference to prevent infinite recursion.
            my $t = $underlying->affix;
            if ( $underlying isa Affix::Wrap::Typedef ) {
                return Affix::Type::Reference->new( name => $underlying->name ) . '()';
            }
            return $t . '( )';
        }
        }
        #
        class    #
        Affix::Wrap::Struct : isa(Affix::Wrap::Entity) {
        field $tag     : reader : param //= 'struct';
        field $members : reader : param //= [];

        method affix_type {
            my $type_name = $tag eq 'union' ? 'Union' : 'Struct';
            sprintf '%s[ %s ]', $type_name, join( ', ', map { $_->name . ' => ' . $_->affix_type } @$members );
        }

        method affix ( $lib //= (), $pkg //= () ) {
            use Affix qw[Struct Union];
            return ( $tag eq 'union' ) ? Union [ map { $_->name, $_->affix } @$members ] : Struct [ map { $_->name, $_->affix } @$members ];
        }
        };
    class    #
        Affix::Wrap::Enum : isa(Affix::Wrap::Entity) {
        field $constants : reader : param //= [];

        method affix_type {
            my @defs;
            for my $c (@$constants) {
                my $v = $c->{value};
                if ( !defined $v ) { push @defs, "'$c->{name}'"; next; }
                $v = "'$v'" if $v !~ /^-?\d+$/;
                push @defs, sprintf( "[ %s => %s ]", $c->{name}, $v );
            }

            # Return only the expression
            return sprintf 'Enum[ %s ]', join( ', ', @defs );
        }

        method perl_constants {
            my @out;
            for my $c (@$constants) {
                my $v = $c->{value};
                $v = "'$v'" if defined $v && $v !~ /^-?\d+$/;
                $v //= 0;
                push @out, "sub $c->{name} () { $v }";
            }
            return join( "\n    ", @out );
        }

        method affix ( $lib //= (), $pkg //= () ) {
            use Affix qw[Enum];
            my @defs;
            for my $c (@$constants) {
                if ( !defined $c->{value} ) { push @defs, $c->{name}; next; }
                push @defs, [ $c->{name}, $c->{value} ];
            }
            my $type = Enum [@defs];
            if ( $pkg && $self->name && $self->name ne '(anonymous)' ) {
                my ( $const_map, $val_map ) = $type->resolve();
                no strict 'refs';
                while ( my ( $const_name, $val ) = each %$const_map ) {
                    next unless $const_name =~ /^[a-zA-Z_]\w*$/;
                    *{"${pkg}::${const_name}"} = sub () {$val};
                }
            }
            return $type;
        }
        };
    class    #
        Affix::Wrap::Function : isa(Affix::Wrap::Entity) {
        use Carp qw[];
        use Affix qw[CodeRef];
        field $ret          : reader : param;
        field $args         : reader : param //= [];
        field $mangled_name : reader : param //= ();

        method affix_type {
            my $sym = $self->name;
            if ( defined $self->mangled_name && $self->mangled_name ne $self->name ) {
                $sym = $self->mangled_name;

                # Mach-O prepends a leading underscore to C symbols (e.g., _return_six)
                # but dlsym expects the source-level name without it.
                $sym = $self->name if $sym eq '_' . $self->name;
            }
            sprintf "affix \$lib, %s => [%s], %s",
                ( $sym ne $self->name ? ( sprintf q[[%s => '%s']], $sym, $self->name ) : ( sprintf q['%s'], $self->name ) ),
                join( ', ', map { $_->affix_type } @$args ), $ret->affix_type;
        }

        method affix ( $lib, $pkg //= () ) {
            if ($lib) {
                my $arg_types = [ map { $_->affix } @$args ];
                my $_lib      = Affix::load_library($lib);
                my $ret_type  = $ret->affix;
                if ($pkg) {
                    no strict 'refs';
                    no warnings 'redefine';
                    Affix::affix(
                        $lib,
                        [   (
                                defined $self->mangled_name &&
                                    $self->mangled_name ne $self->name &&
                                    Affix::find_symbol( $_lib, $self->mangled_name ) ? $self->mangled_name : $self->name
                            ),
                            $pkg . '::' . $self->name
                        ],
                        $arg_types,
                        $ret_type
                    ) // Carp::carp Affix::errno();
                }
                else {
                    Affix::affix(
                        $lib,
                        defined $self->mangled_name &&
                            $self->mangled_name ne $self->name &&
                            Affix::find_symbol( $lib, $self->mangled_name ) ? [ $self->mangled_name, $self->name ] : $self->name,
                        $arg_types,
                        $ret_type
                    ) // Carp::carp Affix::errno();
                }
            }
        }
        method affix_ret { $ret->affix_type }

        method affix_args {
            [ map { $_->affix_type } @$args ]
        }
        method call_ret { $ret->affix }

        method call_args {
            [ map { $_->affix } @$args ]
        }
        } class    #
        Affix::Wrap::Driver::Clang {
        use Config;
        field $project_files : param : reader;
        field $allowed_files  = {};
        field $project_dirs   = [];
        field $paths_seen     = {};
        field $file_cache     = {};
        field $last_seen_file = undef;
        field $clang //= 'clang';
        method _basename ($path) { return '' unless defined $path; $path =~ s{^.*[/\\]}{}; return lc($path); }

        method _normalize ($path) {
            return '' unless defined $path && length $path;
            my $abs = Path::Tiny::path($path)->absolute->stringify;
            $abs =~ s{\\}{/}g;
            return $abs;
        }
        ADJUST {
            my %seen_dirs;
            for my $f (@$project_files) {
                next unless defined $f && length $f;
                my $abs = $self->_normalize($f);
                next unless length $abs;
                $allowed_files->{$abs} = 1;
                my $dir = Path::Tiny::path($abs)->parent->stringify;
                $dir =~ s{\\}{/}g;
                unless ( $seen_dirs{$dir}++ ) { push @$project_dirs, $dir; }
            }
        }

        method parse ( $entry_point, $include_dirs //= [] ) {
            if ( !defined $entry_point || !length $entry_point ) {
                ($entry_point) = grep { defined $_ && length $_ } @$project_files;
            }
            return () unless defined $entry_point && length $entry_point;
            my $ep_abs = $self->_normalize($entry_point);
            return () unless length $ep_abs;
            $allowed_files->{$ep_abs} = 1;
            $last_seen_file = $ep_abs;
            my $ep_dir = Path::Tiny::path($ep_abs)->parent->stringify;
            $ep_dir =~ s{\\}{/}g;
            my $found = 0;

            for my $pd (@$project_dirs) {
                if ( $ep_dir eq $pd ) { $found = 1; last; }
            }
            push @$project_dirs, $ep_dir unless $found;
            my @includes = map { "-I" . $self->_normalize($_) } @$include_dirs;
            for my $d (@$project_dirs) { push @includes, "-I$d"; }
            my @cmd = (
                $clang,                 '-target',         $self->_get_triple(),             '-Xclang',
                '-ast-dump=json',       '-Xclang',         '-detailed-preprocessing-record', '-fsyntax-only',
                '-fparse-all-comments', '-Wno-everything', @includes,                        $ep_abs
            );
            my ( $stdout, $stderr, $exit ) = Capture::Tiny::capture { system(@cmd); };
            if ( $exit != 0 )               { die "Clang Error:\n$stderr"; }
            if ( $stdout =~ /^.*?(\{.*)/s ) { $stdout = $1; }
            my $ast = JSON::PP::decode_json($stdout);
            my @objects;
            $self->_walk( $ast, \@objects, $ep_abs );
            $self->_scan_macros_fallback( \@objects );
            $self->_merge_typedefs( \@objects );
            $self->_wrap_named_types( \@objects );

            #~ @objects = sort { ( $a->file cmp $b->file ) || ( $a->start_offset <=> $b->start_offset ) } @objects;
            @objects;
        }

        method _walk( $node, $acc, $current_file ) {
            return unless ref $node eq 'HASH';
            my $kind      = $node->{kind} // 'Unknown';
            my $node_file = $self->_get_node_file($node);
            if ($node_file) {
                $current_file   = $self->_normalize($node_file);
                $last_seen_file = $current_file;
            }
            elsif ( defined $last_seen_file ) { $current_file = $last_seen_file; }
            if    ( $self->_is_valid_file($current_file) && !$node->{isImplicit} ) {
                if ( $kind eq 'MacroDefinitionRecord' ) {
                    if ( $node->{range} ) { $self->_macro( $node, $acc, $current_file ); }
                }
                elsif ( $kind eq 'TypedefDecl' ) { $self->_typedef( $node, $acc, $current_file ); }
                elsif ( $kind eq 'RecordDecl' || $kind eq 'CXXRecordDecl' ) {
                    $self->_record( $node, $acc, $current_file );
                    return;
                }
                elsif ( $kind eq 'EnumDecl' ) {
                    $self->_enum( $node, $acc, $current_file );
                    return;
                }
                elsif ( $kind eq 'VarDecl' ) {
                    if ( ( $node->{storageClass} // '' ) ne 'static' ) { $self->_var( $node, $acc, $current_file ); }
                }
                elsif ( $kind eq 'FunctionDecl' ) {
                    $self->_func( $node, $acc, $current_file );
                    return;
                }
                elsif ( $kind eq 'BuiltinType' ) { return; }
            }
            if ( $node->{inner} ) {
                for ( @{ $node->{inner} } ) { $self->_walk( $_, $acc, $current_file ); }
            }
        }

        method _is_valid_file ($f) {
            return 0 unless defined $f && length $f;
            return 0 if $f =~ m{^/usr/(include|lib|share|local/include)};
            return 0 if $f =~ m{^/System/Library};
            return 1 if $allowed_files->{$f};
            for my $dir (@$project_dirs) {
                return 1 if index( $f, $dir ) == 0 && ( length($f) == length($dir) || substr( $f, length($dir), 1 ) eq '/' );
            }
            return 0;
        }

        method _get_node_file($node) {
            my $loc = $node->{loc};
            return undef unless $loc;
            my $f;
            if ( ref($loc) eq 'HASH' ) {
                $f = $loc->{presumedLoc}{file} || $loc->{expansionLoc}{file} || $loc->{spellingLoc}{file} || $loc->{file};
            }
            if ( !$f && $node->{range} && $node->{range}{begin} ) {
                my $b = $node->{range}{begin};
                $f = $b->{presumedLoc}{file} || $b->{expansionLoc}{file} || $b->{spellingLoc}{file} || $b->{file};
            }
            return undef unless $f;
            $f =~ s{\\}{/}g;
            $paths_seen->{$f}++;
            return $f;
        }

        method _meta($n) {
            my $s        = $n->{range}{begin}{offset} // 0;
            my $e        = $n->{range}{end}{offset}   // 0;
            my $line     = 0;
            my $end_line = 0;
            if ( ref( $n->{loc} ) eq 'HASH' ) { $line = $n->{loc}{presumedLoc}{line} || $n->{loc}{line}; }
            $line ||= $n->{range}{begin}{line} // 0;
            if ( $n->{range}{end} ) {
                $end_line = $n->{range}{end}{presumedLoc}{line} || $n->{range}{end}{line} || $n->{range}{end}{expansionLoc}{line} || $line;
            }
            else { $end_line = $line; }
            return ( $s, $e, $line, $end_line );
        }

        method _doc_w_trail( $f, $s, $e ) {
            my $d = $self->_extract_doc( $f, $s );
            my $t = $self->_extract_trailing( $f, $e );
            return $d unless defined $t && length $t;
            return $t unless defined $d && length $d;
            return "$d\n$t";
        }

        method _macro( $n, $acc, $f ) {
            my ( $s, $e, $l, $el ) = $self->_meta($n);
            my $val = $self->_extract_macro_val( $n, $f );
            push @$acc,
                Affix::Wrap::Macro->new(
                name         => $n->{name},
                file         => $f,
                line         => $l,
                end_line     => $el,
                value        => $val,
                doc          => $self->_extract_doc( $f, $s ),
                start_offset => $s,
                end_offset   => $e
                );
        }

        method _typedef( $n, $acc, $f ) {
            my ( $s, $e, $l, $el ) = $self->_meta($n);
            push @$acc,
                Affix::Wrap::Typedef->new(
                name         => $n->{name},
                file         => $f,
                line         => $l,
                end_line     => $el,
                underlying   => Affix::Wrap::Type->parse( $n->{type}{qualType} ),
                doc          => $self->_doc_w_trail( $f, $s, $e ),
                start_offset => $s,
                end_offset   => $e
                );
        }

        method _record( $n, $acc, $f ) {
            my ( $s, $e, $l, $el ) = $self->_meta($n);
            my $m_list = $self->_extract_members( $n, $f );
            return unless ( $n->{name} || @$m_list );
            my $tag = $n->{tagUsed} // 'struct';
            push @$acc,
                Affix::Wrap::Struct->new(
                name         => $n->{name} // '(anonymous)',
                tag          => $tag,
                file         => $f,
                line         => $l,
                end_line     => $el,
                members      => $m_list,
                doc          => $self->_doc_w_trail( $f, $s, $e ),
                start_offset => $s,
                end_offset   => $e
                );
        }

        method _extract_members( $n, $f ) {
            my @members;
            return \@members unless $n->{inner};
            my @pending_anonymous_records;
            for my $child ( @{ $n->{inner} } ) {
                my $kind = $child->{kind} // '';
                if ( $kind eq 'RecordDecl' || $kind eq 'CXXRecordDecl' ) {
                    my $sub_members = $self->_extract_members( $child, $f );
                    my $rec         = Affix::Wrap::Struct->new(
                        name     => $child->{name}    // '',
                        tag      => $child->{tagUsed} // 'struct',
                        file     => $f,
                        line     => $child->{loc}{line} // 0,
                        end_line => $child->{loc}{line} // 0,
                        members  => $sub_members,
                        doc      => undef
                    );
                    my $name = $child->{name} // '';
                    if ( $name eq '' ) { push @pending_anonymous_records, $rec; }
                }
                elsif ( $kind eq 'FieldDecl' ) {
                    my $name     = $child->{name} // '';
                    my $raw_type = $child->{type}{qualType};
                    my $type_obj = Affix::Wrap::Type->parse($raw_type);
                    my $def      = undef;
                    if (@pending_anonymous_records) { $def = pop @pending_anonymous_records; }
                    my $f_offset = $child->{range}{begin}{offset};
                    my $f_end    = $child->{range}{end}{offset};
                    my $f_doc    = $self->_doc_w_trail( $f, $f_offset, $f_end );
                    push @members, Affix::Wrap::Member->new( name => $name, type => $type_obj, doc => $f_doc, definition => $def );
                }
            }
            return \@members;
        }

        method _enum( $n, $acc, $f ) {
            my ( $s, $e, $l, $el ) = $self->_meta($n);
            my @c;
            my $cnt = 0;
            my $src = $self->_get_content($f);
            for my $ch ( @{ $n->{inner} } ) {
                if ( ( $ch->{kind} // '' ) eq 'EnumConstantDecl' ) {
                    my $name = $ch->{name};
                    my $val  = undef;
                    my $off  = $ch->{range}{begin}{offset};
                    if ( defined $off ) {
                        my $chunk = substr( $src, $off );
                        if ( $chunk =~ /^\s*\Q$name\E\s*(?:=\s*(.*?))?\s*(?:,|}|$)/s ) {
                            $val = $1;
                            if ( defined $val ) {
                                $val =~ s/\/\/.*$//mg;
                                $val =~ s/\/\*.*?\*\///sg;
                                $val =~ s/^\s+|\s+$//g;
                            }
                        }
                    }

                    # Fallback calc for next value
                    if ( defined $val && $val =~ /^-?\d+$/ ) {
                        $cnt = $val + 1;
                    }
                    else {
                        if ( !defined $val ) { $val = $cnt; }
                        $cnt++;    # Approximation for symbolic
                    }
                    push @c, { name => $name, value => $val };
                }
            }
            push @$acc,
                Affix::Wrap::Enum->new(
                name         => $n->{name} // '(anonymous)',
                file         => $f,
                line         => $l,
                end_line     => $el,
                constants    => \@c,
                doc          => $self->_doc_w_trail( $f, $s, $e ),
                start_offset => $s,
                end_offset   => $e
                );
        }

        method _var( $n, $acc, $f ) {
            my ( $s, $e, $l, $el ) = $self->_meta($n);
            push @$acc,
                Affix::Wrap::Variable->new(
                name         => $n->{name},
                file         => $f,
                line         => $l,
                end_line     => $el,
                type         => Affix::Wrap::Type->parse( $n->{type}{qualType} ),
                doc          => $self->_doc_w_trail( $f, $s, $e ),
                start_offset => $s,
                end_offset   => $e
                );
        }

        method _func( $n, $acc, $f ) {
            return if ( $n->{storageClass} // '' ) eq 'static';
            my ( $s, $e, $l, $el ) = $self->_meta($n);
            my $ret_str = $n->{type}{qualType};
            $ret_str =~ s/\(.*\)//;
            my $ret_obj = Affix::Wrap::Type->parse($ret_str);
            my @args;
            for ( @{ $n->{inner} } ) {
                if ( ( $_->{kind} // '' ) eq 'ParmVarDecl' ) {
                    my $pt = Affix::Wrap::Type->parse( $_->{type}{qualType} );
                    my $pn = $_->{name} // '';
                    push @args, Affix::Wrap::Argument->new( type => $pt, name => $pn );
                }
            }
            push @args, Affix::Wrap::Argument->new( type => Affix::Wrap::Type->new( name => '...' ) ) if $n->{variadic};
            push @$acc,
                Affix::Wrap::Function->new(
                name         => $n->{name},
                mangled_name => $n->{mangledName},
                file         => $f,
                line         => $l,
                end_line     => $el,
                ret          => $ret_obj,
                args         => \@args,
                doc          => $self->_doc_w_trail( $f, $s, $e ),
                start_offset => $s,
                end_offset   => $e
                );
        }

        method _get_content($f) {
            my $abs = $self->_normalize($f);
            return $file_cache->{$abs} if exists $file_cache->{$abs};
            if ( -e $abs ) { return $file_cache->{$abs} = Path::Tiny::path($abs)->slurp_utf8; }
            return '';
        }

        method _extract_doc( $f, $off ) {
            return undef unless defined $off;
            my $content = $self->_get_content($f);
            return undef unless length($content);
            my $pre   = substr( $content, 0, $off );
            my @lines = split /\n/, $pre;
            my @d;
            my $cap = 0;
            while ( my $line = pop @lines ) {
                next if !$cap && $line =~ /^\s*$/;
                if    ( $line =~ /\*\/\s*$/ ) { $cap = 1; }
                elsif ( $line =~ /^\s*\/\// ) { $cap = 1; }
                if    ($cap) {
                    unshift @d, $line;
                    last if $line =~ /^\s*\/\*/;
                    if ( $line =~ /^\s*\/\// && ( !@lines || $lines[-1] !~ /^\s*\/\// ) ) { last; }
                }
                else { last; }
            }
            return undef unless @d;
            my $t = join( "\n", @d );
            $t =~ s/^\s*\/\*\*?//mg;
            $t =~ s/\s*\*\/$//mg;
            $t =~ s/^\s*\*\s?//mg;
            $t =~ s/^\s*\/\/\s?//mg;
            $t =~ s/^\s+|\s+$//g;
            return $t;
        }

        method _extract_trailing( $f, $off ) {
            return '' unless defined $off;
            my $content = $self->_get_content($f);
            return '' unless length($content);
            my $post   = substr( $content, $off );
            my ($line) = split /\R/, $post, 2;
            return '' unless defined $line;
            if ( $line =~ /\/\/(.*)$/ ) {
                my $c = $1;
                $c =~ s/^\s+|\s+$//g;
                return $c;
            }
            return '';
        }

        method _extract_raw( $f, $s, $e ) {
            return '' unless defined $s && defined $e;
            my $content = $self->_get_content($f);
            return '' unless length($content) >= $e;
            return substr( $content, $s, $e - $s );
        }

        method _extract_macro_val( $n, $f ) {
            my $off = $n->{range}{begin}{offset};
            return '' unless defined $off;
            my $content = $self->_get_content($f);
            return '' unless length($content);
            my $r = substr( $content, $off );
            if ( $r =~ /^(.*?)$/m ) {
                my $line = $1;
                my $name = $n->{name};
                if ( $line =~ /#\s*define\s+\Q$name\E\s+(.*)/ ) {
                    my $v = $1;
                    $v =~ s/\/\/.*$//;
                    $v =~ s/\/\*.*?\*\///g;
                    $v =~ s/^\s+|\s+$//g;
                    return $v;
                }
            }
            '';
        }

        method _scan_macros_fallback($acc) {
            my %seen = map { $_->name => 1 } grep { ref($_) eq 'Affix::Wrap::Macro' } @$acc;
            for my $f ( keys %$allowed_files ) {
                next unless $self->_is_valid_file($f);
                my $c = $self->_get_content($f);
                while ( $c =~ /^\s*#\s*define\s+(\w+)(?:[ \t]+(.*?))?\s*$/mg ) {
                    my $name = $1;
                    next if $seen{$name};
                    my $val  = $2 // '';
                    my $off  = $-[0];
                    my $end  = $+[0];
                    my $pre  = substr( $c, 0, $off );
                    my $line = ( $pre =~ tr/\n// ) + 1;
                    $val =~ s/\/\/.*$//;
                    $val =~ s/\/\*.*?\*\///g;
                    $val =~ s/^\s+|\s+$//g;
                    push @$acc,
                        Affix::Wrap::Macro->new(
                        name         => $name,
                        file         => $f,
                        line         => $line,
                        end_line     => $line,
                        value        => $val,
                        doc          => $self->_extract_doc( $f, $off ),
                        start_offset => $off,
                        end_offset   => $end
                        );
                }
            }
        }

        method _merge_typedefs($objs) {
            my @tds = grep { ref($_) eq 'Affix::Wrap::Typedef' } @$objs;
            for my $td (@tds) {
                next if $td->is_merged;
                my ($child) = grep {
                    !$_->is_merged                                                               &&
                        $_->file eq $td->file                                                    &&
                        ( $_->name eq '(anonymous)' || $_->name eq '' || $_->name eq $td->name ) &&
                        ( ref($_) eq 'Affix::Wrap::Enum' || ref($_) eq 'Affix::Wrap::Struct' )   &&
                        ( abs( $_->end_line - $td->line ) <= 2 || abs( $_->end_line - $td->end_line ) <= 2 )
                } @$objs;
                if ($child) {
                    my $new = Affix::Wrap::Typedef->new(
                        name         => $td->name,
                        underlying   => $child,
                        file         => $td->file,
                        line         => $td->line,
                        end_line     => $child->end_line,
                        doc          => $td->doc // $child->doc // $self->_extract_doc( $td->file, $td->start_offset ),
                        start_offset => $td->start_offset,
                        end_offset   => $td->end_offset
                    );
                    for ( my $i = 0; $i < @$objs; $i++ ) {
                        if ( $objs->[$i] == $td ) { $objs->[$i] = $new; last; }
                    }
                    $child->mark_merged();
                }
            }
            @$objs = grep { !$_->is_merged } @$objs;
        }

        method _wrap_named_types($objs) {
            for ( my $i = 0; $i < @$objs; $i++ ) {
                my $node = $objs->[$i];
                next if $node->is_merged;
                if ( ( ref($node) eq 'Affix::Wrap::Struct' || ref($node) eq 'Affix::Wrap::Enum' ) &&
                    length( $node->name ) &&
                    $node->name ne '(anonymous)' ) {

                    # If there's already a typedef for this name, skip it
                    next if grep { $_ isa Affix::Wrap::Typedef && $_->name eq $node->name } @$objs;
                    my $new = Affix::Wrap::Typedef->new(
                        name         => $node->name,
                        underlying   => $node,
                        file         => $node->file,
                        line         => $node->line,
                        end_line     => $node->end_line,
                        doc          => $node->doc,
                        start_offset => $node->start_offset,
                        end_offset   => $node->end_offset
                    );
                    $node->mark_merged();
                    $objs->[$i] = $new;
                }
            }
        }

        method _get_triple {
            my $arch = $Config{archname} =~ /aarch64|arm64/i ? 'aarch64' : $Config{archname} =~ /x64|x86_64/i ? 'x86_64' : 'i686';
            if ( $^O eq 'MSWin32' ) {
                if   ( $Config{cc} =~ /gcc/i ) { return "$arch-pc-windows-gnu"; }
                else                           { return "$arch-pc-windows-msvc"; }
            }
            elsif ( $^O eq 'linux' )  { return "$arch-unknown-linux-gnu"; }
            elsif ( $^O eq 'darwin' ) { return "$arch-apple-darwin"; }
            my ($out) = Capture::Tiny::capture { system $clang, '-print-target-triple' };
            $out =~ s/\s+//g if $out;
            return $out // "$arch-unknown-unknown";
        }
    }
    class    #
        Affix::Wrap::Driver::Regex {
        field $project_files : param : reader;
        field $file_cache = {};

        method _normalize ($path) {
            return '' unless defined $path && length $path;
            my $abs = Path::Tiny::path($path)->absolute->stringify;
            $abs =~ s{\\}{/}g;
            return $abs;
        }

        method _is_valid_file ($f) {
            return 0 unless defined $f && length $f;
            return $f !~ m{^/usr/(include|lib|share|local/include)} &&
                $f !~ m{^/System/Library} &&
                $f !~ m{(Program Files|Strawberry|MinGW|Windows|cygwin|msys)}i;
        }

        method parse( $entry_point, $ids //= [] ) {
            my @objs;
            for my $f (@$project_files) {
                my $abs = $self->_normalize($f);
                next unless length $abs;
                next unless $self->_is_valid_file($abs);
                if ( $f =~ /\.h(pp|xx)?$/i ) { $self->_scan( $f, \@objs ); $self->_scan_funcs( $f, \@objs ); }
                else                         { $self->_scan_funcs( $f, \@objs ); }
            }
            @objs = sort { ( $a->file cmp $b->file ) || ( $a->start_offset <=> $b->start_offset ) } @objs;
            @objs;
        }

        method _read($f) {
            my $abs = $self->_normalize($f);
            return $file_cache->{$abs} if exists $file_cache->{$abs};
            return $file_cache->{$abs} = Path::Tiny::path($f)->slurp_utf8;
        }

        method _scan( $f, $acc ) {
            my $c = $self->_read($f);

            # Macros
            while ( $c =~ /^\s*#\s*define\s+(\w+)(?:[ \t]+(.*?))?$/gm ) {
                my $name = $1;
                my $val  = $2 // '';
                my $s    = $-[0];
                my $e    = $+[0];
                $val =~ s/\/\/.*$//;
                $val =~ s/\/\*.*?\*\///g;
                $val =~ s/^\s+|\s+$//g;
                push @$acc,
                    Affix::Wrap::Macro->new(
                    name         => $name,
                    value        => $val,
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => $self->_doc( $c, $s ),
                    start_offset => $s,
                    end_offset   => $e
                    );
            }

            # Structs
            while ( $c =~ /typedef\s+struct\s*(?:\w+\s*)?(\{(?:[^{}]++|(?1))*\})\s*(\w+)\s*;/gs ) {
                my $s      = $-[0];
                my $e      = $+[0];
                my $mem    = $self->_mem( substr( $1, 1, -1 ) );
                my $struct = Affix::Wrap::Struct->new(
                    name         => '',
                    tag          => 'struct',
                    members      => $mem,
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => undef,
                    start_offset => $s,
                    end_offset   => $e
                );
                push @$acc,
                    Affix::Wrap::Typedef->new(
                    name         => $2,
                    underlying   => $struct,
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => $self->_doc( $c, $s ),
                    start_offset => $s,
                    end_offset   => $e
                    );
            }

            # Enums (typedef)
            while ( $c =~ /typedef\s+enum\s*(?:\w+\s*)?(\{(?:[^{}]++|(?1))*\})\s*(\w+)\s*;/gs ) {
                my $s    = $-[0];
                my $e    = $+[0];
                my $enum = Affix::Wrap::Enum->new(
                    name         => '',
                    constants    => $self->_enum_consts( substr( $1, 1, -1 ) ),
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => undef,
                    start_offset => $s,
                    end_offset   => $e
                );
                push @$acc,
                    Affix::Wrap::Typedef->new(
                    name         => $2,
                    underlying   => $enum,
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => $self->_doc( $c, $s ),
                    start_offset => $s,
                    end_offset   => $e
                    );
            }

            # Enums (standard)
            while ( $c =~ /enum\s+(\w+)\s*(\{(?:[^{}]++|(?2))*\})\s*;/gs ) {
                my $s    = $-[0];
                my $e    = $+[0];
                my $enum = Affix::Wrap::Enum->new(
                    name         => $1,
                    constants    => $self->_enum_consts( substr( $2, 1, -1 ) ),
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => $self->_doc( $c, $s ),
                    start_offset => $s,
                    end_offset   => $e
                );
                push @$acc,
                    Affix::Wrap::Typedef->new(
                    name         => $1,
                    underlying   => $enum,
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => $self->_doc( $c, $s ),
                    start_offset => $s,
                    end_offset   => $e
                    );
            }

            # Global variables
            while ( $c
                =~ /^\s*extern\s+((?:const\s+|unsigned\s+|struct\s+|[\w:<>]+(?:\s*::\s*[\w:<>]+)*\s*\*?\s*)+?)([\s\*]+)([a-zA-Z_]\w*(?:\[.*?\])?)\s*(?:=\s*[^;]+)?\s*;\s*(?:\/\/([^\r\n]*))?/gm
            ) {
                my $s        = $-[0];
                my $e        = $+[0];
                my $type_str = $1 . $2;
                my $name     = $3;
                my $trail    = $4;

                # Strip likely API macros (uppercase words) from the type definition
                $type_str =~ s/\b[A-Z_][A-Z0-9_]*\b//g;
                $type_str =~ s/^\s+|\s+$//g;

                # Handle array syntax: "int vars[10]" -> type="int[10]", name="vars"
                if ( $name =~ s/(\[.*\])$// ) { $type_str .= $1; }

                # Merge standard preceding doc with captured trailing doc
                my $doc = $self->_doc( $c, $s );
                if ( defined $trail && length $trail ) {
                    $trail =~ s/^\s+|\s+$//g;
                    $doc = defined $doc ? "$doc\n$trail" : $trail;
                }
                push @$acc,
                    Affix::Wrap::Variable->new(
                    name         => $name,
                    type         => Affix::Wrap::Type->parse($type_str),
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => $doc,
                    start_offset => $s,
                    end_offset   => $e
                    );
            }

            # Typedefs
            while ( $c =~ /typedef\s+(?!struct\s*(?:\w+\s*)?\{|enum\s*(?:\w+\s*)?\{)(.+?)\s*;/gs ) {
                my $content = $1;
                my $s       = $-[0];
                my $e       = $+[0];
                $content =~ s/\s+/ /g;
                $content =~ s/^\s+|\s+$//g;
                if ( $content =~ /^(.+?)\s*\(\*\s*(\w+)\)\s*\((.*?)\)$/ ) {
                    my ( $ret_str, $name, $args_str ) = ( $1, $2, $3 );
                    my $ret = Affix::Wrap::Type->parse($ret_str);
                    my @args;
                    if ( defined $args_str && length $args_str && $args_str ne 'void' ) {
                        my @args_raw = grep {length} map { s/^\s+|\s+$//g; $_ } split /,(?![^(]*\))/, $args_str;
                        if ( @args_raw == 1 && $args_raw[0] =~ /^void$/ ) { @args_raw = (); }
                        for my $raw (@args_raw) {
                            if ( $raw =~ /^(.+?)([\s\*]+)([a-zA-Z_]\w*(?:\[.*?\])?)$/ ) {
                                my ( $t, $sep, $n ) = ( $1, $2, $3 );
                                $t .= $sep;
                                if ( $n =~ s/(\[.*\])$// ) { $t .= $1 }
                                push @args, Affix::Wrap::Type->parse($t);
                            }
                            else {
                                push @args, Affix::Wrap::Type->parse($raw);
                            }
                        }
                    }
                    my $coderef = Affix::Wrap::Type::CodeRef->new( ret => $ret, params => \@args );
                    push @$acc,
                        Affix::Wrap::Typedef->new(
                        name         => $name,
                        underlying   => $coderef,
                        file         => $f,
                        line         => $self->_ln( $c, $s ),
                        end_line     => $self->_ln( $c, $e ),
                        doc          => $self->_doc( $c, $s ),
                        start_offset => $s,
                        end_offset   => $e
                        );
                }
                elsif ( $content =~ /^(.+?)([\s\*]+)([a-zA-Z_]\w*(?:\[.*?\])?)$/ ) {
                    my ( $type_str, $sep, $name ) = ( $1, $2, $3 );
                    $type_str .= $sep;
                    if ( $name =~ s/(\[.*\])$// ) { $type_str .= $1; }
                    push @$acc,
                        Affix::Wrap::Typedef->new(
                        name         => $name,
                        underlying   => Affix::Wrap::Type->parse($type_str),
                        file         => $f,
                        line         => $self->_ln( $c, $s ),
                        end_line     => $self->_ln( $c, $e ),
                        doc          => $self->_doc( $c, $s ),
                        start_offset => $s,
                        end_offset   => $e
                        );
                }
            }
        }

        method _enum_consts($body) {
            my @cs;
            my $v = 0;
            for ( split /,/, $body ) {
                s/\/\/.*$//;
                s/\/\*.*?\*\///s;
                s/^\s+|\s+$//g;
                next unless length;
                if (/^(\w+)\s*(?:=\s*(.+?))?$/) {
                    my $name = $1;
                    my $val  = $2;    # Capture string or undef

                    # Safe hex handling without string eval
                    if ( defined $val && $val =~ /^(-?)0x([\da-fA-F]+)$/ ) {
                        my $sign = $1 || '';
                        my $num  = hex($2);
                        $val = $sign eq '-' ? -$num : $num;
                    }
                    push @cs, { name => $name, value => $val };
                }
            }
            return \@cs;
        }

        method _scan_funcs( $f, $acc ) {
            my $c = $self->_read($f);
            while ( $c
                =~ /^\s*((?:const\s+|unsigned\s+|struct\s+|[\w:<>]+(?:\s*::\s*[\w:<>]+)*\s*\*?\s*)+?)\s*(\w+)\s*(\((?:[^()]++|(?3))*\))(?:\s*;|\s*\{)/gm
            ) {
                next if $2 =~ /^(if|while|for|return|switch|typedef)$/ || $1 =~ /static/;
                my $s = $-[0];
                my $e = $+[0];
                my ( $ret_str, $func_name, $args_str ) = ( $1, $2, substr( $3, 1, -1 ) );
                #
                $ret_str =~ s/\b[A-Z_][A-Z0-9_]*\b//g;
                $ret_str =~ s/^\s+|\s+$//g;
                my $ret_obj = Affix::Wrap::Type->parse($ret_str);

                # Split args respecting commas inside parentheses (function pointers, etc.)
                my @args_raw = grep {length} map { s/^\s+|\s+$//g; $_ } split /,(?![^(]*\))/, $args_str;
                if ( @args_raw == 1 && $args_raw[0] =~ /^void$/ ) { @args_raw = (); }
                my @args;
                for my $raw (@args_raw) {
                    if ( $raw =~ /^(.+?)\s*\(\*\s*(\w+)\)\s*\((.*)\)$/ ) {
                        my ( $r_type, $cb_name, $cb_args ) = ( $1, $2, $3 );
                        my $ret = Affix::Wrap::Type->parse($r_type);
                        my @p;
                        if ( $cb_args ne '' && $cb_args ne 'void' ) {
                            @p = map { Affix::Wrap::Type->parse($_) } split /,(?![^(]*\))/, $cb_args;
                        }
                        my $code_ref = Affix::Wrap::Type::CodeRef->new( ret => $ret, params => \@p );
                        push @args, Affix::Wrap::Argument->new( type => $code_ref, name => $cb_name );
                    }
                    elsif ( $raw =~ /^(.+?)([\s\*]+)([a-zA-Z_]\w*(?:\[.*?\])?)$/ ) {
                        my ( $t, $sep, $n ) = ( $1, $2, $3 );
                        $t .= $sep;
                        if ( $n =~ s/(\[.*\])$// ) { $t .= $1 }
                        push @args, Affix::Wrap::Argument->new( type => Affix::Wrap::Type->parse($t), name => $n );
                    }
                    else {
                        push @args, Affix::Wrap::Argument->new( type => Affix::Wrap::Type->parse($raw) );
                    }
                }
                push @$acc,
                    Affix::Wrap::Function->new(
                    name         => $func_name,
                    mangled_name => $func_name,
                    ret          => $ret_obj,
                    args         => \@args,
                    file         => $f,
                    line         => $self->_ln( $c, $s ),
                    end_line     => $self->_ln( $c, $e ),
                    doc          => $self->_doc( $c, $s ),
                    start_offset => $s,
                    end_offset   => $e
                    );
            }
        }

        method _mem($b) {
            my @m;
            my $pending_doc = '';
            my $clean       = sub ($t) {
                $t =~ s/^\s*\/\*\*?//mg;
                $t =~ s/\s*\*\/$//mg;
                $t =~ s/^\s*\*\s?//mg;
                $t =~ s/^\s*\/\/\s?//mg;
                $t =~ s/^\s+|\s+$//g;
                return length($t) ? $t : undef;
            };
            while ( length($b) > 0 ) {
                if ( $b =~ s/^(\s+)// ) { next; }
                if ( $b =~ s|^(\s*/\*(.*?)\*/)||s ) { $pending_doc .= $2;     next; }
                if ( $b =~ s|^(//(.*?)\n)|| )       { $pending_doc .= "$2\n"; next; }
                if ( $b =~ s/^\s*(union|struct)\s*(\{(?:[^{}]++|(?2))*\})\s*(\w+)\s*;// ) {
                    my $tag = $1;
                    my $d   = Affix::Wrap::Struct->new( name => '', tag => $tag, members => $self->_mem( substr( $2, 1, -1 ) ) );
                    push @m, Affix::Wrap::Member->new( name => $3, definition => $d, doc => $clean->($pending_doc) );
                    $pending_doc = '';
                    next;
                }

                # Function pointer: ret (*name)(args)
                if ( $b =~ s/^\s*([\w\s\*]+?)\s*\(\*\s*(\w+)\)\s*\((.*?)\)\s*;// ) {
                    my ( $ret_str, $name, $args_str ) = ( $1, $2, $3 );
                    my $ret = Affix::Wrap::Type->parse($ret_str);
                    my @args;
                    if ( $args_str ne '' && $args_str ne 'void' ) {
                        @args = map { Affix::Wrap::Type->parse($_) } split( /\s*,\s*/, $args_str );
                    }
                    my $type_obj = Affix::Wrap::Type::CodeRef->new( ret => $ret, params => \@args );
                    push @m, Affix::Wrap::Member->new( name => $name, type => $type_obj, doc => $clean->($pending_doc) );
                    $pending_doc = '';
                    next;
                }
                if ( $b =~ s/^\s*(.+?)([\s\*]+)([a-zA-Z_]\w*(?:\[.*?\])?)\s*;// ) {
                    my ( $t, $sep, $n ) = ( $1, $2, $3 );
                    $t .= $sep;
                    $t =~ s/^\s+|\s+$//g;
                    if ( $n =~ s/(\[.*\])$// ) { $t .= $1 }
                    push @m, Affix::Wrap::Member->new( name => $n, type => Affix::Wrap::Type->parse($t), doc => $clean->($pending_doc) );
                    $pending_doc = '';
                    next;
                }
                substr( $b, 0, 1 ) = '';
                $pending_doc = '';
            }
            return \@m;
        }
        method _ln( $c, $o ) { ( substr( $c, 0, $o ) =~ tr/\n// ) + 1 }

        method _doc( $c, $o ) {
            return undef if $o == 0;
            my @l = split /\n/, substr( $c, 0, $o );
            my @d;
            my $cap = 0;
            while ( my $l = pop @l ) {
                next if !$cap && $l =~ /^\s*$/;
                if    ( $l =~ s/\s*\*\/\s*$// ) { $cap = 1; }
                elsif ( $l =~ m{^\s*//} )       { $cap = 1; }
                if    ($cap) {
                    unshift @d, $l;
                    last if $l =~ /^\s*\/\*/;
                    last if $l =~ m{^\s*//} && ( !@l || $l[-1] !~ m{^\s*//} );
                }
                else {last}
            }
            return undef unless @d;
            my $t = join "\n", @d;
            $t =~ s/^\s*(\/\*+|\*+\/|\*|\/\/)\s?//mg;
            $t =~ s/^\s+|\s+$//g;
            return $t;
        }
    }

    class Affix::Wrap {
        field $driver        : param //= ();
        field $project_files : param //= $driver->project_files;
        field $include_dirs  : param //= [];
        field $types         : param //= {};
        #
        ADJUST {
            if ( defined $driver && !builtin::blessed($driver) ) {
                if    ( $driver eq 'Clang' ) { $driver = Affix::Wrap::Driver::Clang->new( project_files => $project_files ); }
                elsif ( $driver eq 'Regex' ) { $driver = Affix::Wrap::Driver::Regex->new( project_files => $project_files ); }
                else                         { die "Unknown driver '$driver'"; }
            }
            elsif ( !defined $driver ) {

                # Wrap in a localized warn-handler to suppress the internal "Can't spawn" error
                my $exit = do {
                    local $SIG{__WARN__} = sub { };
                    system( 'clang', '--version', '>', File::Spec->devnull, '2>&1' );
                };
                my $use_clang = ( $exit == 0 );
                $driver = $use_clang ? Affix::Wrap::Driver::Clang->new( project_files => $project_files ) :
                    Affix::Wrap::Driver::Regex->new( project_files => $project_files );
            }
        }

        method parse( $entry_point //= () ) {
            $entry_point //= $project_files->[0];
            my @nodes = $driver->parse( $entry_point, $include_dirs );
            $self->_resolve_macros( \@nodes );
            return @nodes;
        }

        method _resolve_macros ($nodes) {
            my %macros;
            for my $node (@$nodes) {
                if ( $node isa Affix::Wrap::Macro ) {
                    my $val = $node->value // '';
                    $val =~ s/(?<=\d)[Uu][Ll]{0,2}//g;    # Strip C suffixes like 100ULL
                    $macros{ $node->name } = $val;
                }
            }
            my %cache;
            my $resolve;
            $resolve = sub {
                my ($token) = @_;
                return undef unless defined $token;
                $token =~ s/^\s+|\s+$//g;
                return oct($token)    if $token =~ /^0x[\da-fA-F]+$/i;
                return $token + 0     if $token =~ /^-?\d+(?:\.\d+)?$/;
                return $cache{$token} if exists $cache{$token};
                local $cache{$token} = undef;
                my $expr = $macros{$token};
                return undef unless defined $expr;
                1 while $expr =~ s/^\((.*)\)$/$1/;    # Strip outer parens

                # Resolve bitwise and arithmetic expressions
                if ( $expr =~ /[|&<>+\-*\/]/ ) {
                    my $evaluable = $expr;

                    # Using {} delimiters so the // operator doesn't break the regex parser
                    $evaluable =~ s{\b([a-zA-Z_]\w*)\b}{ $resolve->($1) // $1 }ge;

                    # Clean up any C-style suffixes that might have survived
                    $evaluable =~ s/\b(\d+)L+\b/$1/g;

                    # If everything is now numeric/operators/whitespace, we can safely eval
                    if ( $evaluable =~ /^[0-9\s|&<>\+\-\*\/\(\).xXa-fA-F]+$/ ) {

                        # Using a string eval here to let Perl's engine handle C-like precedence
                        my $res = eval $evaluable;
                        return $cache{$token} = $res if defined $res;
                    }
                }

                # Fallback: Treat as simple alias (A -> B)
                return $cache{$token} = $resolve->($expr);
            };
            for my $node (@$nodes) {
                if ( $node isa Affix::Wrap::Macro ) {
                    my $val = $resolve->( $node->name );
                    $node->set_value($val) if defined $val;
                }
            }
        }

        method _generate_code( $lib, $pkg ) {
            Carp::croak("Affix::Wrap::generate/wrap requires a valid package name") unless defined $pkg && $pkg =~ /^[a-zA-Z_]\w*(::\w+)*$/;
            my @nodes = $self->parse;
            my %unique_types;
            my %referenced_names;
            for my $node (@nodes) {
                if ( $node->can('name') && $node->name && $node->name ne '(anonymous)' ) {
                    next if $node isa Affix::Wrap::Macro || $node isa Affix::Wrap::Function || $node isa Affix::Wrap::Variable;
                    $unique_types{ $node->name } = $node;
                }

                # Collect dependencies from affix_type strings (e.g. '@sockaddr')
                my $sig = eval { $node->affix . "" } // '';
                while ( $sig =~ /@([a-zA-Z_]\w*)/g ) { $referenced_names{$1} = 1; }
            }

            # Atomic Engine Batch
            my @fwd = sort keys %{ { map { $_ => 1 } ( keys %unique_types, keys %referenced_names ) } };
            my @batch_lines;
            for my $name ( sort keys %unique_types ) {
                my $sig = $unique_types{$name}->affix_type;
                push @batch_lines, "    typedef $name => $sig;" if $sig && $sig ne "$name()";
            }
            my $batch_str = @batch_lines ? join( "\n", @batch_lines ) . "\n" : "";

            # Perl Module Construction
            # Safely quote $lib: escape \ and ] within q[...] delimiters
            my $_lib = '';
            if ( defined $lib ) {
                my $safe_lib = $lib;
                $safe_lib =~ s/\\/\\\\/g;
                $safe_lib =~ s/\]/\\]/g;
                $_lib = "my \$lib = q[$safe_lib];";
            }
            my $out = <<~"PERL";
            package $pkg {
                use v5.40;
                use Affix qw[:all];
                #
                $_lib
            PERL
            for my $name (@fwd) {
                $out .= "    typedef '$name';\n";
            }
            $out .= $batch_str;
            $out .= "\n    #\n";
            for my $node (@nodes) {
                $out .= "    " . $node->perl_constants . "\n" if $node isa Affix::Wrap::Enum;
            }
            $out .= "\n    #\n";
            for my $node (@nodes) {
                my $code = $node->affix_type;
                if ( $code && ( $node isa Affix::Wrap::Function || $node isa Affix::Wrap::Variable || $node isa Affix::Wrap::Macro ) ) {
                    $out .= "    $code;\n";
                }
            }
            $out .= "};\n1;\n";
        }

        method generate( $lib, $pkg, $file ) {
            my ( $code, $nodes ) = $self->_generate_code( $lib, $pkg );
            Path::Tiny::path($file)->spew_utf8($code);
        }

        method wrap ( $lib, $pkg //= [caller]->[0] ) {
            my ( $code, $nodes ) = $self->_generate_code( $lib, $pkg );
            eval $code;
            if ($@) {
                Carp::croak("Affix::Wrap wrap() compilation failed: $@\n\nCode:\n$code");
            }
            return grep { $_ isa Affix::Wrap::Function || $_ isa Affix::Wrap::Variable || $_ isa Affix::Wrap::Macro } @$nodes;
        }

        method list_symbols ($lib_path) {
            my $abs = path($lib_path)->absolute->stringify;
            return [] unless -e $abs;
            my @symbols;
            my ( $out, $err, $exit );

            # llvm-nm
            # We use --extern-only to find the public API
            ( $out, $err, $exit ) = capture { system( 'llvm-nm', '--extern-only', '--defined-only', $abs ) };
            if ( $exit == 0 && $out ) {
                for ( split /\n/, $out ) {
                    if (/ [TRG] (?:_)?(\w+)$/) { push @symbols, $1; }
                }
            }

            # objdump for Strawberry Perl
            if ( !@symbols ) {
                ( $out, $err, $exit ) = capture { system( 'objdump', '-p', $abs ) };
                if ( $exit == 0 && $out ) {

                    # objdump -p displays the "Export Address Table"
                    # We look for the lines following the table header
                    my $in_exports = 0;
                    for ( split /\n/, $out ) {
                        if (/^\[Ordinal\/Name Pointer\] Table$/) { $in_exports = 1; next; }
                        if ($in_exports) {
                            last if /^\s*$/;    # End of table

                            # Format:[   0] lsquic_engine_new
                            if (/\[\s*\d+\]\s+(\w+)/) { push @symbols, $1; }
                        }
                    }
                }
            }

            # dumpbin for MSVC
            if ( !@symbols ) {
                ( $out, $err, $exit ) = capture { system( 'dumpbin', '/EXPORTS', $abs ) };
                if ( $exit == 0 && $out ) {
                    my $in_exports = 0;
                    for ( split /\n/, $out ) {
                        if (/ordinal\s+hint\s+RVA\s+name/) { $in_exports = 1; next; }
                        if ($in_exports) {

                            # Format: 1    0 00001234 lsquic_engine_new
                            if (/^\s+\d+\s+[A-F0-9]+\s+[A-F0-9]+\s+(\w+)/) { push @symbols, $1; }
                        }
                    }
                }
            }
            @symbols = sort @symbols;
            if ( !@symbols ) {
                warn "[!] list_symbols: No symbols found in $abs using llvm-nm, objdump, or dumpbin.\n";
            }
            return \@symbols;
        }
    }
}
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.
