##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI.pm
## Version v0.2.8
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/12/17
## Modified 2023/10/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::SSI;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw(
        $MOD_PERL $MOD_PERL_VERSION $SERVER_VERSION $VERSION
        $ATTRIBUTES_RE $EXPR_RE $SUPPORTED_FUNCTIONS $FUNCTION_PARAMETERS_RE $IS_UTF8
        $HAS_SSI_RE
    );
    our( $MOD_PERL, $MOD_PERL_VERSION, $SERVER_VERSION );
    if( exists( $ENV{MOD_PERL} )
        &&
        ( $MOD_PERL = $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ) )
    {
        $MOD_PERL_VERSION = $1;
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        # For exec cmd to check the user has permission to execute commands
        require Apache2::Access;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :common :http OK DECLINED CONN_KEEPALIVE ) );
        require Apache2::Filter;
        require Apache2::Connection;
        require Apache2::RequestRec;
        # For exec commands
        require Apache2::SubProcess;
        require Apache2::SubRequest;
        require Apache2::RequestIO;
        require Apache2::Log;
        require Apache2::ServerUtil;
        require Apache2::RequestUtil;
        require APR::Brigade;
        require APR::Bucket;
        require APR::Table;
        require APR::Base64;
        require APR::Request;
        require APR::SockAddr;
        require APR::Finfo;
        require APR::Const;
        APR::Const->import( -compile => qw( FINFO_NORM ) );
    }
    use Apache2::Expression;
    use Apache2::SSI::File;
    use Apache2::SSI::Finfo;
    use Apache2::SSI::Notes;
    use Apache2::SSI::URI;
    use Config;
    use Encode ();
    use HTML::Entities ();
    use IO::Select;
    use Nice::Try;
    use Regexp::Common qw( net Apache2 );
    use Scalar::Util ();
    use URI;
    use version;
    our $VERSION = 'v0.2.8';
    use constant PERLIO_IS_ENABLED => $Config{useperlio};
    # As of Apache 2.4.41 and mod perl 2.0.11 Apache2::SubProcess::spawn_proc_prog() is not working
    use constant MOD_PERL_SPAWN_PROC_PROG_WORKING => 0;
    our $HAS_SSI_RE = qr{<!--#(?:comment|config|echo|elif|else|endif|exec|flastmod|fsize|if|include|perl|printenv|set).*?-->}is;
};

use strict;
use warnings;

{
    # Compile it beforehand and keep it there
    our $ATTRIBUTES_RE = qr/
        (
            (?<tag_attr>
                (?:
                    [[:blank:]\h]*
                    (?<attr_name>[\w\-]+)
                    [[:blank:]\h]*
                    =
                    [[:blank:]\h]*
                    # (?<!\\)(?<attr_val>[^\"\'[:blank:]\h]+)
                    # (?:(?<!\")|(?<!\'))(?<attr_val>[^[:blank:]\h]+)
                    (?!["'])(?<attr_val>[^[:blank:]\h]+)
                    [[:blank:]\h]*
                )
                |
                (?:
                    [[:blank:]\h]*
                    (?<attr_name>[\w\-]+)
                    [[:blank:]\h]*
                    =
                    [[:blank:]\h]*
                    (?<quote>(?<quote_double>\")|(?<quote_single>\'))
                    (?(<quote_double>)
                        (?<attr_val>(?>\\"|[^"])*+)
                        |
                        (?<attr_val>(?>\\'|[^'])*+)
                    )
                    # (?>\\["']|[^"'])*+
                    \g{quote}
                    [[:blank:]\h]*
                )
            )
        )
    /xsm;
    
    our $EXPR_RE = qr/
        (?<tag_attr>
            \b(?<attr_name>expr)
            [[:blank:]\h]*\=
            (?:
                (?:
                    (?!["'])(?<attr_val>[^[:blank:]\h]+)
                    [[:blank:]\h]*
                )
                |
                (?:
                    [[:blank:]\h]*
                    (?<quote>(?<quote_double>\")|(?<quote_single>\'))
                    (?(<quote_double>)
                        (?<attr_val>(?>\\"|[^"])*+)
                        |
                        (?<attr_val>(?>\\'|[^'])*+)
                    )
                    \g{quote}
                    [[:blank:]\h]*
                )
            )
        )
    /xsmi;
    
    our $SUPPORTED_FUNCTIONS = qr/(base64|env|escape|http|ldap|md5|note|osenv|replace|req|reqenv|req_novary|resp|sha1|tolower|toupper|unbase64|unescape)/i;
    our $FUNCTION_PARAMETERS_RE = qr/
        [[:blank:]\h]*                                                  # Some possible leading blanks
        (?:
            (?:
                (?<func_quote>(?<func_quote_2>\")|(?<func_quote_1>\'))  # quotes used to enclose function parameters
                (?(<func_quote_2>)
                    (?<func_params>(?>\\"|[^"])*+)
                    |
                    (?<func_params>(?>\\'|[^'])*+)
                )
                \g{func_quote}
            )
            |
            (?<func_params>(?>\\\)|[^\)\}])*+)                             # parameters not surounded by quotes
        )
        [[:blank:]\h]*                                                  # Some possible trailing blanks
    /xsm;
    
    our $IS_UTF8 = qr/
        ^(
            ([\0-\x7F])
            |
            ([\xC2-\xDF][\x80-\xBF])
            |
            (
                (
                    ([\xE0][\xA0-\xBF])
                    |
                    ([\xE1-\xEC\xEE-\xEF][\x80-\xBF])
                    |
                    ([\xED][\x80-\x9F])
                )
                [\x80-\xBF]
            )
            |
            (
                (
                    ([\xF0][\x90-\xBF])
                    |
                    ([\xF1-\xF3][\x80-\xBF])
                    |
                    ([\xF4][\x80-\x8F])
                )
                [\x80-\xBF][\x80-\xBF]
            )
        )*$
    /x;
}

# PerlResponseHandler
sub handler : method
{
    if( Scalar::Util::blessed( $_[1] ) && $_[1]->isa( 'Apache2::Filter' ) )
    {
        return( &apache_filter_handler( @_ ) );
    }
    else
    {
        return( &apache_response_handler( @_ ) );
    }
}

sub ap2perl_expr
{
    my $self = shift( @_ );
    my $ref  = shift( @_ );
    my $buf  = shift( @_ );
    return( [] ) if( ref( $ref ) ne 'HASH' );
    my $opts = {};
    if( @_ )
    {
        $opts = ref( $_[0] ) eq 'HASH'
            ? shift( @_ )
            : !( @_ % 2 )
                ? { @_ }
                : {};
    }
    $opts->{skip} = [] if( !exists( $opts->{skip} ) );
    $opts->{top} = 0 if( !exists( $opts->{top} ) );
    $opts->{embedded} = 0 if( !exists( $opts->{embedded} ) );
    my $type = $ref->{type};
    my $stype = '';
    $stype = $ref->{subtype} if( defined( $ref->{subtype} ) );
    my $elems = $ref->{elements};

    my $prev_regexp_capture = $self->{_regexp_capture};
    my $r = $self->apache_request;
    my $env = $self->env;

    my $map_binary =
    {
    '='     => 'eq',
    '=='    => 'eq',
    '!='    => 'ne',
    '<'     => 'lt',
    '<='    => 'le',
    '>'     => 'gt',
    '>='    => 'ge',
    };
    # In perl, this is inverted, operators used for integers are used for strings and vice versa
    my $map_integer =
    {
    'eq'    => '==',
    'ne'    => '!=',
    'lt'    => '<',
    'le'    => '<=',
    'gt'    => '>',
    'ge'    => '>=',
    };
    
    # String and integer comparison are dealt with separately below
    if( $type eq 'comp' )
    {
        my $op = '';
        $op = $ref->{op} if( defined( $ref->{op} ) );
        # ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch
        if( $stype eq 'binary' )
        {
            my $this1 = $self->ap2perl_expr( $ref->{worda_def}->[0], [] );
            my $this2 = $self->ap2perl_expr( $ref->{wordb_def}->[0], [] );
            push( @$buf, '!' ) if( $ref->{is_negative} );
            # "IP address matches address/netmask"
            if( $op eq 'ipmatch' )
            {
                push( @$buf, $self->_ipmatch( $this2->[0], $this1->[0] ) );
            }
            # "left string matches pattern given by right string (containing wildcards *, ?, [])"
            elsif( $op eq 'strmatch' || $op eq 'fnmatch' )
            {
                push( @$buf, @$this1, qq{=~ /$this2->[0]/} );
            }
            # "same as -strmatch, but case insensitive"
            elsif( $op eq 'strcmatch' )
            {
                push( @$buf, @$this1, qq{=~ /$this2->[0]/i} );
            }
            else
            {
                push( @$buf, @$this1, $map_binary->{ $op }, @$this2 );
            }
        }
        # 192.168.1.10 in split( /\,/, $ip_list )
        elsif( $stype eq 'function' )
        {
            my $this1 = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
            my $func  = $ref->{function_def}->[0];
            my $func_name = $func->{name};
            my $argv = $self->parse_expr_args( $func->{args_def} );
            push( @$buf, sprintf( "scalar( grep( %s eq \$_, ${func_name}\(${argv}\) ) )", $this1->[0] ) ); 
        }
        # e.g.: %{SOME_VALUE} in {"John", "Peter", "Paul"}
        elsif( $stype eq 'list' )
        {
            my $this1 = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
            my $list  = $self->parse_expr_args( $ref->{list_def} );
            push( @$buf, sprintf( "scalar( grep( %s eq \$_, (%s) ) )", $this1->[0], $list ) );
        }
        elsif( $stype eq 'regexp' )
        {
            my $this1 = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
            my $this2 = $self->ap2perl_expr( $ref->{regexp_def}->[0], [] );
            my $map = 
            {
            '='     => '=~',
            '=='    => '=~',
            '!='    => '!~',
            };
            push( @$buf, @$this1 );
            push( @$buf, exists( $map->{ $ref->{op} } ) ? $map->{ $ref->{op} } : $ref->{op} );
            push( @$buf, @$this2 );
        }
        elsif( $stype eq 'unary' )
        {
            my $this = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
            my $word = join( '', @$this );
            # check if the uri is accessible to all
            if( $op eq 'A' || $op eq 'U' )
            {
                my $url = $word;
                # Because we cannot do variable length lookbehind
                my $res;
                my $req = $self->lookup_uri( $url );
                # A lookup will give us a code 200, so we need to run it to check if file exists
                my $file = $req->filename;
                if( $req->code != 200 )
                {
                    $res = 0;
                }
                elsif( -e( "$file" ) && ( ( -f( "$file" ) && -r( "$file" ) ) || ( -d( "$file" ) && -x( "$file" ) ) ) )
                {
                    $res = 1;
                }
                else
                {
                    $res = 0;
                }
                push( @$buf, $res );
            }
            # Those are the same as in perl so we pass through
            elsif( $op eq 'd' || $op eq 'e' || $op eq 'f' || $op eq 's' )
            {
                my $req = $self->lookup_file( $word );
                push( @$buf, "-${op} ${word}" );
                my $file = $req->filename;
                my $res = 1;
                if( $req->code != 200 )
                {
                    $res = 0;
                }
                push( @$buf, $res );
            }
            elsif( $op eq 'h' || $op eq 'L' )
            {
                push( @$buf, "-l( $word )" );
            }
            elsif( $op eq 'F' )
            {
                my $req = $self->lookup_file( $word );
            }
            elsif( $op eq 'n' || $op eq 'z' )
            {
                # Because we cannot do variable length lookbehind
                push( @$buf, ( $op eq 'z' ? '!' : '' ) . "length( ${word} )" );
            }
            # <!--#if expr='-R "134.28.200"' -->
            elsif( $op eq 'R' )
            {
                my $ip = $self->remote_ip;
                my $subnet = $word;
                # We need to be careful because the subnet provided may ver well be 
                # a function or something else, and we would not want to surround 
                # it with double quotes.
                if( $self->_is_ip( $subnet ) )
                {
                    $subnet = qq{"$subnet"};
                }

                push( @$buf, qq{\$self->_ipmatch( $subnet, "$ip" )} );
            }
            elsif( $op eq 'T' )
            {
                # Because we cannot do variable length lookbehind
                my $val = length( $word )
                    ? $word
                    : '';
                $val = $self->parse_eval_expr( $val ) if( length( $val ) );
                $val = lc( $val );
                my $res;
                if( $val eq  '' || $val eq '0' || $val eq 'off' || $val eq 'false' || $val eq 'no' )
                {
                    $res = 0;
                }
                else
                {
                    $res = 1;
                }
                push( @$buf, $res );
            }
        }
    }
    elsif( $type eq 'cond' )
    {
        if( $stype eq 'and' )
        {
            my $this1 = $self->ap2perl_expr( $ref->{and_def_expr2}->[0], [] );
            my $this2 = $self->ap2perl_expr( $ref->{and_def_expr2}->[0], [] );
            push( @$buf, @$this1, '&&', @$this2 );
        }
        elsif( $stype eq 'boolean' )
        {
            push( @$buf, $ref->{booltype} eq 'true' ? 1 : 0 );
        }
        elsif( $stype eq 'or' )
        {
            my $this1 = $self->ap2perl_expr( $ref->{or_def_expr1}->[0], [] );
            my $this2 = $self->ap2perl_expr( $ref->{or_def_expr2}->[0], [] );
            push( @$buf, @$this1, '||', @$this2 );
        }
        elsif( $stype eq 'comp' )
        {
            my $this = $self->ap2perl_expr( $ref->{elements}->[0], [] );
            push( @$buf, @$this );
        }
        elsif( $stype eq 'negative' )
        {
            my $this = $self->ap2perl_expr( $ref->{negative_def}->[0], [] );
            push( @$buf, '!(', @$this, ')' );
        }
        elsif( $stype eq 'parenthesis' )
        {
            my $this = $self->ap2perl_expr( $ref->{parenthesis_def}->[0], [] );
            push( @$buf, '(', @$this, ')' );
        }
        elsif( $stype eq 'variable' )
        {
            my $this = $self->ap2perl_expr( $ref->{variable_def}->[0], [] );
            push( @$buf, @$this );
        }
    }
    elsif( $type eq 'function' )
    {
        my $func = $ref->{name};
        warn( "\$func is not defined! Hash refernece \$ref contains: ", $self->dump( $ref ), "\n" ) if( !defined( $func ) );
        # parse_expr_args returns a string of comma separated arguments
        my $argv = $self->parse_expr_args( $ref->{args_def} );
        # https://httpd.apache.org/docs/current/expr.html
        # Functions
        # Example:
        # base64('Tous les êtres humains naissent libres (et égaux) en dignité et en droits.')
        # base64("Tous les êtres humains naissent libres et égaux en dignité et en droits.")
        # base64( $QUERY_STRING )
        # %{base64:'Tous les êtres humains naissent libres et égaux en dignité et en droits.'}
        # %{base64:"Tous les êtres humains naissent libres (et égaux) en dignité et en droits."}
        # Is this a standard Apache2 function ?
        if( $func =~ /^$SUPPORTED_FUNCTIONS$/i )
        {
            push( @$buf, "\$self->parse_func_${func}( ${argv} )" );
        }
        else
        {
            push( @$buf, "${func}( ${argv} )" );
        }
    }
    elsif( $type eq 'integercomp' )
    {
        my $op = $ref->{op};
        my $op_actual = '';
        if( !exists( $map_integer->{ $op } ) )
        {
            warn( "Unknown operator \"${op}\" for integer comparison in \"$ref->{raw}\".\n" );
            $op_actual = $op;
        }
        else
        {
            $op_actual = $map_integer->{ $op };
        }
        my $this1 = $self->ap2perl_expr( $ref->{worda_def}->[0], [] );
        my $this2 = $self->ap2perl_expr( $ref->{wordb_def}->[0], [] );
        push( @$buf, @$this1, $op_actual, @$this2 );
    }
    elsif( $type eq 'join' )
    {
        my $argv = $self->parse_expr_args( $ref->{list_def} );
        if( $ref->{word_def} )
        {
            my $this1 = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
            push( @$buf, 'join(', @$this1, ',', $argv, ')' );
        }
        else
        {
            push( @$buf, q{join('', }, $argv, ')' );
        }
    }
    elsif( $type eq 'listfunc' )
    {
        my $func = $ref->{name};
        my $args = $ref->{args_def};
        my $argv = $self->parse_expr_args( $args );
        if( $func =~ /^$SUPPORTED_FUNCTIONS$/i )
        {
            push( @$buf, "\$self->parse_func_${func}( ${argv} )" );
        }
        else
        {
            push( @$buf, "${func}( ${argv} )" );
        }
    }
    elsif( $type eq 'regany' )
    {
        # Apache2 regular expressions work asis in perl, because they are PCRE
        push( @$buf, $ref->{raw} );
    }
    elsif( $type eq 'regex' )
    {
        # Apache2 regular expressions work asis in perl, because they are PCRE
        push( @$buf, $ref->{raw} );
    }
    elsif( $type eq 'regsub' )
    {
        push( @$buf, $ref->{raw} );
    }
    elsif( $type eq 'split' )
    {
        my $regex = $ref->{regex};
        my $this;
        if( $ref->{word_def} )
        {
            $this = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
        }
        elsif( $ref->{list_def} )
        {
            $this = $self->ap2perl_expr( $ref->{list_def}->[0], [] );
        }
        push( @$buf, 'split(', $regex, ',', @$this, ')' );
    }
    elsif( $type eq 'string' && $opts->{skip} ne 'string' )
    {
        # Search string for embedded variables
        my $this = $ref->{raw};
        # my $reType = $self->legacy ? 'Legacy' : $self->trunk ? 'Trunk' : '';
        my $reType = $self->trunk ? 'Trunk' : 'Legacy';
        $this =~ s
        {
            $RE{Apache2}{"${reType}Variable"}
        }
        {
            my $var = $+{variable};
            my $res = $self->parse_expr( $var, { embedded => 1 } );
            $res //= '';
            $res;
        }gexis;
        if( $opts->{top} )
        {
            push( @$buf, 'qq{' . $this . '}' );
        }
        else
        {
            push( @$buf, $this );
        }
    }
    elsif( $type eq 'stringcomp' )
    {
        my $op = $ref->{op};
        my $op_actual = '';
        if( !exists( $map_binary->{ $op } ) )
        {
            warn( "Unknown operator \"${op}\" for integer comparison in \"$ref->{raw}\".\n" );
            $op_actual = $op;
        }
        else
        {
            $op_actual = $map_binary->{ $op };
        }
        my $this1 = $self->ap2perl_expr( $ref->{worda_def}->[0], [] );
        my $this2 = $self->ap2perl_expr( $ref->{wordb_def}->[0], [] );
        push( @$buf, @$this1, $op_actual, @$this2 );
    }
    elsif( $type eq 'sub' )
    {
        my $this = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
        push( @$buf, @$this, '=~', $ref->{regsub} );
    }
    elsif( $type eq 'variable' )
    {
        my $var_name = $ref->{name};
        if( $stype eq 'function' )
        {
            # push( @$buf, $ref->{name} . '(' . $self->parse_expr_args( $ref->{args_def} ) . ')' );
            $ref->{type} = 'function';
            my $this = $self->ap2perl_expr( $ref, [] );
            push( @$buf, @$this );
        }
        elsif( $stype eq 'rebackref' )
        {
            my $val = $prev_regexp_capture->[ int( $ref->{value} ) - 1 ];
            push( @$buf, $self->_is_number( $val ) ? $val : "q{" . $val . "}" );
            # push( @$buf, $val );
        }
        elsif( $stype eq 'variable' )
        {
            my $try = '';
            if( !length( $try ) && length( $env->{ $var_name } ) )
            {
                $try = $env->{ $var_name };
            }
            # if( !length( $try ) && defined( ${ "main\::${var_name}" } ) )
            no strict 'refs';
            if( !length( $try ) && defined( ${ "main\::" }{ ${var_name} } ) )
            {
                no strict 'refs';
                $try = ${ "main\::${var_name}" };
            }
            # Last resort
            if( !length( $try ) )
            {
                $try = $self->parse_echo({ var => $var_name });
            }
            if( !length( $try ) )
            {
                $try = '${' . $var_name . '}';
            }
            else
            {
                $try = 'q{' . $try . '}' unless( $self->_is_number( $try ) || $opts->{embedded} );
            }
            push( @$buf, $try );
        }
        else
        {
            warn( "Unknown subtype '$stype' in variable with Apache2::Expression data being: ", $self->dump( $ref ), "\n" );
        }
    }
    elsif( $type eq 'word' )
    {
        if( $stype eq 'digits' )
        {
            push( @$buf, $ref->{value} );
        }
        elsif( $stype eq 'ip' )
        {
            push( @$buf, "'" . $ref->{value} . "'" );
        }
        elsif( $stype eq 'dotted' )
        {
            push( @$buf, 'q{' . $ref->{word} . '}' );
        }
        elsif( $stype eq 'function' )
        {
            my $def = $ref->{function_def}->[0];
            push( @$buf, $def->{name} . '(' . $self->parse_expr_args( $def ) . ')' );
        }
        elsif( $stype eq 'join' )
        {
            my $this = $self->ap2perl_expr( $ref->{join_def}->[0], [] );
            push( @$buf, @$this );
        }
        elsif( $stype eq 'parens' )
        {
            my $this = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
            push( @$buf, '(' . $this->[0] . ')' );
        }
        elsif( $stype eq 'quote' )
        {
            push( @$buf, $ref->{quote} . $ref->{word} . $ref->{quote} );
        }
        elsif( $stype eq 'rebackref' )
        {
            push( @$buf, $prev_regexp_capture->[ int( $ref->{value} ) - 1 ] );
        }
        elsif( $stype eq 'regex' )
        {
            # Apache2 regular expressions are PCRE so we use them asis
            push( @$buf, $ref->{regex} );
        }
        elsif( $stype eq 'sub' )
        {
            my $this = $self->ap2perl_expr( $ref->{sub_def}->[0], [] );
            push( @$buf, @$this );
        }
        elsif( $stype eq 'variable' )
        {
            my $this = $self->ap2perl_expr( $ref->{variable_def}->[0], [] );
            push( @$buf, @$this );
        }
    }
    elsif( $type eq 'words' )
    {
        if( length( $ref->{list} ) )
        {
            # my $this2 = $self->ap2perl_expr( $ref->{list_def}->[0], [] );
            my $tmp = [];
            # We go through each element of the list which can be composed of string, function or other
            my $all_string = 1;
            if( ref( $ref->{words_def} ) )
            {
                foreach my $that ( @{$ref->{words_def}} )
                {
                    $all_string = 0 unless( $that->{type} eq 'string' || $that->{type} eq 'word' || $that->{type} eq 'variable' );
                    my $this = $self->ap2perl_expr( $that, [] );
                    push( @$tmp, @$this );
                }
                push( @$buf, $all_string ? 'q{' . $ref->{list} . '}' : join( ',', @$tmp ) );
            }
            else
            {
                my $this = $self->ap2perl_expr( $ref->{list_def}->[0], [] );
                push( @$buf, @$this );
            }
        }
        else
        {
            my $this = $self->ap2perl_expr( $ref->{word_def}->[0], [] );
            push( @$buf, @$this );
        }
    }
    return( $buf );
}

sub apache_response_handler
{
    my( $class, $r ) = @_;
    my $debug = int( $r->dir_config( 'Apache2_SSI_DEBUG' ) );
    $r->log->debug( "${class} [PerlResponseHandler]: Received request for uri '", $r->uri, "' with path info '", $r->path_info, "' and file name '", $r->filename, "', content type is '", $r->content_type, "' and arguments: '", join( "', '", @_ ), "'." ) if( $debug > 0 );
    return( &Apache2::Const::DECLINED ) unless( $r->content_type eq 'text/html' );
    $r->status( &Apache2::Const::HTTP_OK );
    $r->no_cache(1) if( ( $r->dir_config( 'Apache2_SSI_NO_CACHE' ) ) eq 'on' );
#     $r->sendfile( $r->filename );
#     return( Apache2::Const::OK );

    my $params =
    {
    apache_filter => $r->output_filters,
    apache_request => $r,
    debug => 3,
    };
    my $val;
    my $map = 
    {
    DEBUG   => 'debug',
    Echomsg => 'echomsg',
    Errmsg  => 'errmsg',
    Sizefmt => 'sizefmt',
    Timefmt => 'timefmt',
    };
    foreach my $key ( keys( %$map ) )
    {
        if( length( $val = $r->dir_config( "Apache2_SSI_${key}" ) ) )
        {
            $params->{ $map->{ $key } } = $val;
        }
    }
    if( $r->dir_config( 'Apache2_SSI_Expression' ) eq 'legacy' )
    {
        $params->{legacy} = 1;
    }
    elsif( $r->dir_config( 'Apache2_SSI_Expression' ) eq 'trunk' )
    {
        $params->{trunk} = 1;
    }
    # new(9 will automatically set the value for uri() based on the Apache2::RequestRec->unparsed_uri
    my $self = $class->new( $params ) || do
    {
        $r->log->error( "Error instantiating ${class}: ", $class->error );
        return( &Apache2::Const::DECLINED );
    };
    
    my $u = $self->uri || do
    {
        $r->log->error( "No URI set. This should not happen." );
        $r->status( &Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        return( &Apache2::Const::OK );
    };
    unless( $u->code == &Apache2::Const::HTTP_OK )
    {
        $r->log->error( "Cannot server uri \"$u\". http code is \"", $u->code, "\"." );
        $r->status( $u->code );
        return( &Apache2::Const::DECLINED );
    }
    my $file = $u->filename;
    my $max_length = int( $r->dir_config( 'Apache2_SSI_Max_Length' ) ) || 0;
    if( -s( $file ) >= $max_length )
    {
        $r->log->error( "HTML data exceeds our size threshold of $max_length. Rejecting the request." );
        $r->status( &Apache2::Const::HTTP_REQUEST_ENTITY_TOO_LARGE );
        return( &Apache2::Const::OK );
    }
    my $html = $u->slurp_utf8;
    if( !length( $html ) )
    {
        $r->status( &Apache2::Const::HTTP_NO_CONTENT );
        return( &Apache2::Const::OK );
    }
    
    # my $addr = $r->useragent_addr;
    my $res = $self->parse( $html );
    if( !defined( $res ) )
    {
        $r->log->error( "${class} is unable to process data: ", $self->error );
        return( &Apache2::Const::DECLINED );
    }
    else
    {
        try
        {
            $res = Encode::encode( 'utf8', $res, Encode::FB_CROAK );
        }
        catch( $e )
        {
            $r->log->error( "${class} encountered an error while trying to encode data into utf8: $e" );
            return( &Apache2::Const::DECLINED );
        }
        
        my $len = length( $res );
        try
        {
            $r->headers_out->set( 'Content-Length' => $len );
            my $sent = $r->print( $res );
        }
        catch( $e )
        {
            $r->log->error( "${class} encountered an error while sending resulting data via Apache2::Filter->print: $e" );
        }
        return( &Apache2::Const::OK );
    }
}

# https://perl.apache.org/docs/2.0/user/handlers/filters.html#C_PerlOutputFilterHandler_
# sub handler : FilterRequestHandler
# sub handler : method
sub apache_filter_handler
{
    # my( $class, $f, $brigade, $mode, $type, $len ) = @_;
    my( $class, $f, $bb ) = @_;
    my $r = $f->r;
    # my $class = __PACKAGE__;
    my $main = $r->is_initial_req ? $r : $r->main;
    return( &Apache2::Const::DECLINED ) unless( $r->is_initial_req && $main->content_type eq 'text/html' );
    my $debug = int( $r->dir_config( 'Apache2_SSI_DEBUG' ) );
    $main->no_cache(1) if( ( $r->dir_config( 'Apache2_SSI_NO_CACHE' ) ) eq 'on' );
    $r->log->debug( "${class} [PerlOutputFilterHandler]: Received request for uri '", $r->uri, "' with path info '", $r->path_info, "'." ) if( $debug > 0 );
    
    my $ctx = $f->ctx;
    unless( $ctx->{invoked} )
    {
        $r->log->debug( "${class} [PerlOutputFilterHandler]: First time invoked, removing Content-Length header currently set to '", $r->headers_out->get( 'Content-Length' ), "'." ) if( $debug > 0 );
        $r->headers_out->unset( 'Content-Length' );
    }
    
    # Then, we might get called multiple time, since there may be multiple brigade buckets
    # Here, we retrieve the last buffer we put in $f->ctx->{data} if any
    my $html = exists( $ctx->{data} ) ? $ctx->{data} : '';
    $r->log->debug( "${class} [PerlOutputFilterHandler]: HTML data buffer set to '$html'." ) if( $debug > 0 );
    $ctx->{invoked}++;
    my $seen_eos = 0;
    my $max_length = int( $r->dir_config( 'Apache2_SSI_Max_Length' ) ) || 0;
    $r->log->debug( "${class} [PerlOutputFilterHandler]: Maximum length set to '$max_length'." ) if( $debug > 0 );
    # Get all the brigade buckets data
    for( my $b = $bb->first; $b; $b = $bb->next( $b ) )
    {
        $seen_eos++, last if( $b->is_eos );
        $b->read( my $bdata );
        $html .= $bdata;
        return( &Apache2::Const::DECLINED ) if( $max_length && length( $html ) >= $max_length );
    }
    
    # If we have not reached the special End-of-String bucket, we store our buffer in $f->ctx->{data} and return OK
    if( !$seen_eos )
    {
        # store context for all but the last invocation
        $r->log->debug( "${class} [PerlOutputFilterHandler]: Not reached the EOS bucket. Storing html to data buffer." ) if( $debug > 0 );
        $ctx->{data} = $html;
        $f->ctx( $ctx );
        return( &Apache2::Const::OK );
    }
    
    # Let's behave well as per the doc
    if( $f->c->keepalive == &Apache2::Const::CONN_KEEPALIVE )
    {
        $r->log->debug( "${class} [PerlOutputFilterHandler]: KeepAlive count (", $f->c->keepalive, ") reached the threshold of '", &Apache2::Const::CONN_KEEPALIVE, "'." ) if( $debug > 0 );
        $ctx->{data} = '';
        $f->ctx( $ctx );
    }
    
    my $size = length( $html );
    $ctx->{data} = '';
    $ctx->{invoked} = 0;
    $f->ctx( $ctx );
    if( $size == 0 )
    {
        $r->log->debug( "${class} [PerlOutputFilterHandler]: Data received is empty. Nothing to do." );
        return( &Apache2::Const::OK );
    }
    try
    {
        $html = Encode::decode( 'utf8', $html, Encode::FB_CROAK );
    }
    catch( $e )
    {
        $r->log->error( "${class} [PerlOutputFilterHandler]: Failed to decode data from utf8: $e" );
        return( &Apache2::Const::DECLINED );
    }
    
    #W We just add that the charset is utf-8
    $main->content_type( 'text/html; charset=utf-8' ) unless( $main->content_type =~ /\bcharset\n/i );
    
    my $params =
    {
    apache_filter => $f,
    apache_request => $r,
    debug => 3,
    };
    my $val;
    my $map = 
    {
    DEBUG   => 'debug',
    Echomsg => 'echomsg',
    Errmsg  => 'errmsg',
    Sizefmt => 'sizefmt',
    Timefmt => 'timefmt',
    };
    foreach my $key ( keys( %$map ) )
    {
        if( length( $val = $r->dir_config( "Apache2_SSI_${key}" ) ) )
        {
            $params->{ $map->{ $key } } = $val;
        }
    }
    if( $r->dir_config( 'Apache2_SSI_Expression' ) eq 'legacy' )
    {
        $params->{legacy} = 1;
    }
    elsif( $r->dir_config( 'Apache2_SSI_Expression' ) eq 'trunk' )
    {
        $params->{trunk} = 1;
    }
    $r->log->debug( "${class} [PerlOutputFilterHandler]: Creating a ${class} object." ) if( $debug > 0 );
    my $self = $class->new( $params ) || do
    {
        $r->log->error( "Error instantiating ${class}: ", $class->error );
        return( &Apache2::Const::DECLINED );
    };
    # my $addr = $r->useragent_addr;
    my $res = $self->parse( $html );
    if( !defined( $res ) )
    {
        $r->log->error( "${class} [PerlOutputFilterHandler]: is unable to process data: ", $self->error );
        return( &Apache2::Const::DECLINED );
    }
    else
    {
        try
        {
            $res = Encode::encode( 'utf8', $res, Encode::FB_CROAK );
        }
        catch( $e )
        {
            $r->log->error( "${class} [PerlOutputFilterHandler]: encountered an error while trying to encode data into utf8: $e" );
            return( &Apache2::Const::DECLINED );
        }
        
        # $r->headers_out->unset( 'Content-Length' );
        my $len = length( $res );
        try
        {
            $r->headers_out->set( 'Content-Length' => $len );
            my $sent = $f->print( "$res" );
            $r->log->debug( "${class} [PerlOutputFilterHandler]: ${sent} bytes sent out." ) if( $debug > 0 );
        }
        catch( $e )
        {
            $r->log->error( "${class} encountered an error while sending resulting data via Apache2::Filter->print: $e" );
        }
        # This will cause a segfault
        # $r->rflush;
        return( &Apache2::Const::OK );
    }
}

sub init
{
    my $self = shift( @_ );
    my $class = ref( $self );
    my $args = {};
    if( scalar( @_ ) )
    {
        no warnings 'uninitialized';
        $args = Scalar::Util::reftype( $_[0] ) eq 'HASH'
            ? shift( @_ )
            : !( scalar( @_ ) % 2 )
                ? { @_ }
                : {};
    }
    my $uri = delete( $args->{document_uri} ) // '';
    $self->{html}           = '';
    $self->{apache_filter}  = '';
    $self->{apache_request} = '';
    $self->{document_root}  = '';
    # e.g.: [Value Undefined]
    $self->{echomsg}        = '';
    $self->{errmsg}         = '[an error occurred while processing this directive]';
    $self->{filename}       = '';
    $self->{legacy}         = 0;
    $self->{trunk}          = 0;
    $self->{remote_ip}      = '';
    $self->{sizefmt}        = 'abbrev';
    $self->{timefmt}        = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order} = [qw( apache_filter apache_request document_root document_uri )];
    $self->SUPER::init( %$args ) || return;
    $self->{_env}           = '';
    $self->{_path_info_processed} = 0;
    # Used to hold regular expression matches during eval in _eval_vars()
    # and make them available for the next evaluation
    $self->{_regexp_capture}= [];
    $self->{_uri_reset}     = 0;
    # A stack reflecting the current state of if/else parser.
    # Each entry is 1 when we've seen a true condition in this if-chain,
    # 0 when we haven't. Initially it's as if we're in a big true 
    # if-block with no else.
    $self->{if_state}       = [1];
    $self->{notes}          = '';
    $self->{suspend}        = [0];
    # undef means the current locale's default
    $self->mod_perl( defined( $MOD_PERL ) ? length( $MOD_PERL ) > 0 : 0 );
    my $r = $self->apache_request;
    if( $MOD_PERL && !$r )
    {
        # NOTE: Must check if GlobalRequest is set
        if( !( $r = $self->apache_request ) )
        {
            $r = Apache2::RequestUtil->request;
            if( $r )
            {
                $self->apache_request( $r );
                $self->apache_filter( $r->input_filters );
            }
            else
            {
                print( STDERR "${class} seems to be running under modperl version '$MOD_PERL', but could not get the Apache2::RequestRec object via Apache2::RequestUtil->request(). You need to enable GlobalRequest in your VirtualHost with: PerlOptions +GlobalRequest\n" );
            }
        }
    }
    my $p = {};
    if( length( "$uri" ) )
    {
        $p->{document_uri} = "$uri";
    }
    elsif( $r )
    {
        $p->{document_uri} = $r->unparsed_uri;
    }
    elsif( length( $self->env( 'DOCUMENT_URI' ) ) )
    {
        $p->{document_uri} = $self->env( 'DOCUMENT_URI' );
    }
    else
    {
        $p->{document_uri} = $self->env( 'REQUEST_URI' );
    }
    
    if( length( $self->{document_root} ) )
    {
        $p->{document_root} = $self->{document_root};
    }
    elsif( $r )
    {
        $p->{document_root} = $r->document_root;
    }
    else
    {
        $self->env( 'DOCUMENT_ROOT' );
    }
    
    $p->{debug} = $self->{debug};
    $p->{apache_request} = $r if( $r );
    if( length( "$p->{document_uri}" ) && length( "$p->{document_root}" ) )
    {
        my $u = Apache2::SSI::URI->new( $p ) ||
            return( $self->error( "Unable to instantiate an Apache2::SSI::URI object with document uri \"$p->{document_uri}\" and document root \"$p->{document_root}\": ", Apache2::SSI::URI->error ) );
        $self->{uri} = $u;
    }
    elsif( !length( "$p->{document_root}" ) )
    {
        return( $self->error( "No document root ($p->{document_root}) value was provided." ) );
    }
    elsif( !length( "$p->{document_uri}" ) )
    {
        return( $self->error( "No document uri ($p->{document_uri}) value was provided." ) );
    }
    else
    {
        return( $self->error( "No document uri ($p->{document_uri}) nor document root ($p->{document_root}) value were provided." ) );
    }
    my $notes;
    $notes = Apache2::SSI::Notes->new( debug => $self->{debug} ) if( Apache2::SSI::Notes->supported );
    $self->{notes} = $notes;
    return( $self );
}

sub apache_filter { return( shift->_set_get_object_without_init( 'apache_filter', 'Apache2::Filter', @_ ) ); }

sub apache_request { return( shift->_set_get_object_without_init( 'apache_request', 'Apache2::RequestRec', @_ ) ); }

sub clone
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my @copy = qw( debug echomsg errmsg remote_ip sizefmt timefmt );
    my $params = {};
    @$params{ @copy } = @$self{ @copy };
    $params->{apache_filter} = $self->apache_filter if( $self->apache_filter );
    $params->{apache_request} = $self->apache_request if( $self->apache_request );
    $params->{document_uri} = $self->uri->document_uri;
    $params->{document_root} = $self->document_root;
    my $new = $class->new( %$params ) || return( $self->error( "Unable to create a clone of our object: ", $class->error ) );
    return( $new );
}

sub decode_base64
{
    my $self = shift( @_ );
    try
    {
        my $v = join( '', @_ );
        if( $self->mod_perl )
        {
            $v = APR::Base64::decode( $v );
        }
        else
        {
            require MIME::Base64;
            $v = MIME::Base64::decode( $v );
        }
        $v = Encode::decode( 'utf8', $v ) if( $self->_has_utf8( $v ) );
        return( $v );
    }
    catch( $e )
    {
        return( $self->error( "Error while decoding base64 data: $e" ) );
    }
}

sub decode_entities
{
    my $self = shift( @_ );
    try
    {
        return( HTML::Entities::decode_entities( @_ ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while decoding html entities data: $e" ) );
    }
}

sub decode_uri
{
    my $self = shift( @_ );
    try
    {
        require URI::Escape::XS;
        return( URI::Escape::XS::uri_unescape( @_ ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while decoding uri: $e" ) );
    }
}

sub decode_url
{
    my $self = shift( @_ );
    try
    {
        if( $self->mod_perl )
        {
            return( Encode::decode( 'utf8', APR::Request::decode( @_ ), Encode::FB_CROAK ) );
        }
        else
        {
            # Will use XS version automatically
            require URL::Encode;
            return( URL::Encode::url_decode_utf8( @_ ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error while url decoding data: $e" ) );
    }
}

sub document_filename { return( shift->uri->filename( @_ ) ); }

sub document_path { return( shift->uri->document_path( @_ ) ); }

sub document_root
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    if( $r )
    {
        $r->document_root( @_ ) if( @_ );
        return( $r->document_root );
    }
    else
    {
        if( @_ )
        {
            $self->{document_root} = shift( @_ );
            $self->_set_env( DOCUMENT_ROOT => $self->{document_root} );
        }
        return( $self->{document_root} || $self->env( 'DOCUMENT_ROOT' ) );
    }
}

# A document uri is an absolute uri possibly with some path info and query string.
sub document_uri { return( shift->uri->document_uri( @_ ) ); }

sub echomsg { return( shift->_set_get_scalar( 'echomsg', @_ ) ); }

sub encode_base64
{
    my $self = shift( @_ );
    try
    {
        my $v = join( '', @_ );
        $v = Encode::encode( 'utf8', $v, Encode::FB_CROAK ) if( Encode::is_utf8( $v ) );
        if( $self->mod_perl )
        {
            return( APR::Base64::encode( $v ) );
        }
        else
        {
            require MIME::Base64;
            return( MIME::Base64::encode( $v, '' ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error while encoding data into base64: $e" ) );
    }
}

sub encode_entities
{
    my $self = shift( @_ );
    try
    {
        return( HTML::Entities::encode_entities( join( '', @_ ) ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while encoding data into html entities: $e" ) );
    }
}

sub encode_md5
{
    my $self = shift( @_ );
    try
    {
        require Digest::MD5;
        my $v = join( '', @_ );
        $v = Encode::encode( 'utf8', $v, Encode::FB_CROAK ) if( Encode::is_utf8( $v ) );
        return( Digest::MD5::md5_hex( $v ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while encoding data into md5 hex: $e" ) );
    }
}

sub encode_uri
{
    my $self = shift( @_ );
    try
    {
        require URI::Escape::XS;
        # return( URI::Escape::uri_escape_utf8( join( '', @_ ) ) );
        return( URI::Escape::XS::uri_escape( join( '', @_ ) ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while encoding uri: $e" ) );
    }
}

sub encode_url
{
    my $self = shift( @_ );
    try
    {
        if( $self->mod_perl )
        {
            my $v = Encode::encode( 'utf8', join( '', @_ ), Encode::FB_CROAK );
            return( APR::Request::encode( $v ) );
        }
        else
        {
            # Will use XS version automatically
            require URL::Encode;
            return( URL::Encode::url_encode_utf8( join( '', @_ ) ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error while url encoding data: $e" ) );
    }
}

sub env
{
    my $self = shift( @_ );
    # The user wants the entire hash reference
    unless( @_ )
    {
        my $r = $self->apache_request;
        if( $r )
        {
            $r = $r->is_initial_req ? $r : $r->main ? $r->main : $r;
            return( $r->subprocess_env )
        }
        else
        {
            unless( ref( $self->{_env} ) )
            {
                $self->{_env} = {%ENV};
            }
            return( $self->{_env} );
        }
    }
    my $name = shift( @_ );
    return( $self->error( "No environment variable name was provided." ) ) if( !length( $name ) );
    my $opts = {};
    if( scalar( @_ ) )
    {
        no warnings 'uninitialized';
        $opts = pop( @_ ) if( defined( $_[-1] ) && Scalar::Util::reftype( $_[-1] ) eq 'HASH' );
    }
    # return( $self->error( "Environment variable value provided is a reference data (", overload::StrVal( $val ), ")." ) ) if( ref( $val ) && ( !overload::Overloaded( $val ) || ( overload::Overloaded( $val ) && !overload::Method( $val, '""' ) ) ) );
    my $r = $opts->{apache_request} || $self->apache_request;
    if( $r )
    {
        $r = $r->is_initial_req ? $r : $r->main ? $r->main : $r;
        if( @_ )
        {
            my $val = shift( @_ );
            $r->subprocess_env( $name => $val );
            $ENV{ $name } = $val;
        }
        my $v = $r->subprocess_env( $name );
        return( $v );
    }
    else
    {
        my $env = {};
        unless( ref( $self->{_env} ) )
        {
            # Make a copy of the environment variables
            $self->{_env} = {%ENV};
        }
        $env = $self->{_env};
        if( @_ )
        {
            $env->{ $name } = $ENV{ $name } = shift( @_ );
            my $meth = lc( $name );
            if( $self->can( $meth ) )
            {
                $self->$meth( $env->{ $name } );
            }
        }
        return( $env->{ $name } );
    }
}

sub errmsg { return( shift->_set_get_scalar( 'errmsg', @_ ) ); }

# This is set by document_uri
sub filename { return( shift->uri->filename( @_ ) ); }

sub find_file
{
    my( $self, $args ) = @_;
    my $r = $self->apache_request;
    my $req = '';
    if( exists( $args->{file} ) )
    {
        $self->_interp_vars( $args->{file} );
        $req = $self->lookup_file( $args->{file} );
    }
    elsif( exists( $args->{virtual} ) )
    {
        $self->_interp_vars( $args->{virtual} );
        $req = $self->lookup_uri( $args->{virtual} );
    }
    elsif( $r )
    {
        $req = Apache2::SSI::File->new( $r->filename, apache_request => $r );
    }
    return( $req );
}

sub finfo
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    my $newfile;
    if( @_ )
    {
        $newfile = shift( @_ );
        return( $self->error( "New file path specified but is an empty string." ) ) if( !defined( $newfile ) || !length( $newfile ) );
    }
    elsif( !$self->{finfo} )
    {
        $newfile = $self->filename;
        return( $self->error( "No file path set. This should not happen." ) ) if( !$newfile );
    }
    
    if( defined( $newfile ) )
    {
        $self->{finfo} = Apache2::SSI::Finfo->new( $newfile, ( $r ? ( apache_request => $r ) : () ) );
    }
    return( $self->{finfo} );
}

sub html { return( shift->_set_get_scalar( 'html', @_ ) ); }

sub legacy { return( shift->_set_get_boolean( 'legacy', @_ ) ); }

sub lookup_file
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file provided to look up." ) );
    my $r = $self->apache_request;
    my $f = Apache2::SSI::File->new(
        $file,
        ( $r ? ( apache_request => $r ) : () ),
        base_file => $self->uri->filename,
        debug => $self->debug
    ) || return( $self->error( "Unable to instantiate an Apache2::SSI::File object: ", Apache2::SSI::File->error ) );
    if( $f->code == 404 )
    {
        # Mimic the Apache error when the file does not exist
        $self->error( "unable to lookup information about \"$file\" in parsed file \"", $self->uri, "\"." );
    }
    return( $f );
}

sub lookup_uri
{
    my $self = shift( @_ );
    my $uri  = shift( @_ );
    my $r = $self->apache_request;
    my $u = Apache2::SSI::URI->new(
        ( $r ? ( apache_request => $r ) : () ),
        base_uri => $self->uri,
        document_uri => $uri,
        document_root => ( $r ? $r->document_root : $self->document_root ),
        debug => $self->debug
    ) || return( $self->error( "Unable to instantiate an Apache2::SSI::URI object: ", Apache2::SSI::URI->error ) );
    if( $u->code == 404 )
    {
        # Mimic the Apache error when the file does not exist
        $self->error( "unable to get information about uri \"$uri\" in parsed file ", $self->uri );
    }
    return( $u );
}

sub mod_perl { return( shift->_set_get_boolean( 'mod_perl', @_ ) ); }

sub new_uri
{
    my $self = shift( @_ );
    my $uri  = shift( @_ );
    return( $self->error( "No uri provided to create an Apache2::SSI::URI object." ) ) if( !defined( $uri ) || !length( $uri ) );
    my $p =
    {
    document_uri => $uri,
    document_root => $self->document_root,
    base_uri => $self->uri,
    debug => $self->debug,
    };
    $p->{apache_request} = $self->apache_request if( $self->apache_request );
    my $o = Apache2::SSI::URI->new( $p ) ||
        return( $self->error( "Unable to create an Apache2::SSI::URI: ", Apache2::SSI::URI->error ) );
    return( $o );
}

# This makes use of Apache2::SSI::Notes which guarantees that notes are shared in and out of Apache framework
# Notes are cleaned up at server shutdown with an handler set in startup.pl
# See scripts/startup.pl and conf/extra.conf.in as an example
sub notes
{
    my $self = shift( @_ );
    my $notes = $self->{notes};
    my $r = $self->apache_request;
    unless( scalar( @_ ) )
    {
        if( $r )
        {
            return( $r->pnotes );
        }
        elsif( $notes )
        {
            return( $notes->get );
        }
        # We just return an empty hash to avoid error
        else
        {
            return( {} );
        }
    }
    my $var  = shift( @_ );
    my $new;
    my $new_value_set = 0;
    if( @_ )
    {
        $new = shift( @_ );
        $new_value_set++;
        if( $notes )
        {
            $notes->set( $var => $new );
        }
    }
    
    if( $r )
    {
        try
        {
            $r->pnotes( $var => $new ) if( $new_value_set );
            my $val = $r->pnotes( $var );
            $val //= $notes->get( $var ) if( $notes );
            return( $val );
        }
        catch( $e )
        {
            return( $self->error( "An error occurred trying to ", (defined( $new ) ? 'set/' : ''), " get the note value for variable \"${var}\"", (defined( $new ) ? " with value '${new}" : ''), ": $e" ) );
        }
    }
    return( $notes->get( $var ) ) if( $notes );
    return( '' );
}

sub parse
{
    my $self = shift( @_ );
    my $html = @_ ? shift( @_ ) : $self->{html};
    return( $self->error( "No html data was provided to parse ssi." ) ) if( !length( $html ) );
    my @parts = split( m/($HAS_SSI_RE)/s, $html );
    # Nothing to do
    # return( Apache2::Const::DECLINED ) if( scalar( @parts ) <= 1 );
    my $out = '';
    my $ssi;
    while( @parts )
    {
        $out .= ( '', shift( @parts ) )[ 1 - $self->{suspend}->[0] ];
        last unless( @parts );
        $ssi = shift( @parts );
        # There's some weird 'uninitialized' warning on the next line, but I can't find it.
        if( $ssi =~ m/^<!--#(.*)-->$/s )
        {
            my $res = $self->parse_ssi( $1 );
            $out .= "$res" if( defined( $res ) );
        }
        else
        {
            return( $self->error( 'Parse error' ) );
        }
    }
    return( $out );
}

# <!--#comment Blah Blah Blah -->
sub parse_comment
{
    my $self = shift( @_ );
    my $comment = shift( @_ );
    # comments are removed
    return( '' );
}

sub parse_config
{
    my( $self, $args ) = @_;
    $self->{echomsg} =     $args->{echomsg}   if( exists( $args->{echomsg} ) );
    $self->{errmsg}  =     $args->{errmsg}    if( exists( $args->{errmsg} ) );
    $self->{sizefmt} = lc( $args->{sizefmt} ) if( exists( $args->{sizefmt} ) );
    $self->{timefmt} =     $args->{timefmt}   if( exists( $args->{timefmt} ) );
    return( '' );
}

sub parse_echo
{
    my( $self, $args ) = @_;
    my $var = $args->{var};
    # $self->_interp_vars( $var );
    my $r = $self->apache_request;
    my $env = $self->env;
    my $value;
    no strict( 'refs' );
    
    if( defined( $var ) && $r && defined( $value = $r->subprocess_env( $var ) ) )
    {
        # Ok then
    }
    elsif( defined( $var ) && $self->can( my $method = "parse_echo_\L$var\E" ) )
    {
        $value = $self->$method( $r );
    }
    elsif( defined( $var ) && exists( $env->{ $var } ) )
    {
        $value = $env->{ $var };
    }
    else
    {
        $value = $self->echomsg;
    }
    
    if( $args->{decoding} && lc( $args->{decoding} ) ne 'none' )
    {
        $args->{decoding} = lc( $args->{decoding} );
        try
        {
            if( $args->{decoding} eq 'url' )
            {
                $value = $self->decode_uri( $value );
            }
            elsif( $args->{decoding} eq 'urlencoded' )
            {
                $value = $self->decode_url( $value );
            }
            elsif( $args->{decoding} eq 'base64' )
            {
                $value = $self->decode_base64( $value );
            }
            elsif( $args->{decoding} eq 'entity' )
            {
                $value = $self->decode_entities( $value );
            }
        }
        catch( $e )
        {
            $self->error( "Decoding of value with method \"$args->{decoding}\" for variable \"$args->{var}\" failed: $e" );
            return( $self->errmsg );
        }
    }
    
    if( $args->{encoding} && lc( $args->{encoding} ) ne 'none' )
    {
        $args->{encoding} = lc( $args->{encoding} );
        try
        {
            if( $args->{encoding} eq 'url' )
            {
                $value = $self->encode_uri( $value );
            }
            elsif( $args->{encoding} eq 'urlencoded' )
            {
                $value = $self->encode_url( $value );
            }
            elsif( $args->{encoding} eq 'base64' )
            {
                $value = $self->encode_base64( $value );
            }
            elsif( $args->{encoding} eq 'entity' )
            {
                $value = $self->encode_entities( $value );
            }
        }
        catch( $e )
        {
            $self->error( "Enecoding of value with method \"$args->{decoding}\" for variable \"$args->{var}\" failed: $e" );
            return( $self->errmsg );
        }
    }
    return( $value );
}

sub parse_echo_date_gmt { return( shift->_format_time( time(), undef, 'GMT' ) ); }

sub parse_echo_date_local { return( shift->_format_time( time() ) ); }

sub parse_echo_document_name
{
    my $self = shift( @_ );
    my $r = shift( @_ );
    my $uri = $self->uri;
    if( $r )
    {
        $r = $r->is_initial_req ? $r : $r->main ? $r->main : $r;
        my $v = $r->subprocess_env( 'DOCUMENT_NAME' ) || $uri->finfo->name;
        # return( $self->_set_var( $r, 'DOCUMENT_NAME', basename $r->filename ) );
        return( $v );
    }
    else
    {
        my $env = $self->env;
        my $v = $env->{DOCUMENT_NAME} || $uri->finfo->name;
        return( $v );
    }
}

sub parse_echo_document_uri { return( shift->document_uri ); }

sub parse_echo_last_modified
{
    my $self = shift( @_ );
    my $r = shift( @_ );
    my $uri = $self->uri;
    if( $r )
    {
        $r = $r->is_initial_req ? $r : $r->main ? $r->main : $r;
        my $v = $r->subprocess_env( 'LAST_MODIFIED' ) || $self->_lastmod( $r->filename );
    }
    else
    {
        my $env = $self->env;
        return( $env->{LAST_MODIFIED} || $self->_format_time( $uri->finfo->mtime ) );
    }
}

sub parse_echo_query_string
{
    my $self = shift( @_ );
    my $uri = $self->uri;
    return( $uri->query_string );
}

sub parse_elif
{
    my( $self, $args ) = @_;
    # Make sure we're in an 'if' chain
    return( $self->error( "Malformed if..endif SSI structure" ) ) unless( @{$self->{if_state}} > 1 );
    return( '' ) if( $self->{suspend}->[1] );
    return( $self->_handle_ifs( $self->parse_eval_expr( $args->{expr} ) ) );
}

sub parse_else
{
    my $self = shift( @_ );
    # Make sure we're in an 'if' chain
    return( $self->error( "Malformed if..endif SSI structure" ) ) unless( @{$self->{if_state}} > 1 );
    return( '' ) if( $self->{suspend}->[1] );
    return( $self->_handle_ifs(1) );
}

sub parse_endif
{
    my $self = shift( @_ );
    # Make sure we're in an 'if' chain
    return( $self->error( "Malformed if..endif SSI structure" ) ) unless( @{$self->{if_state}} > 1 );
    shift( @{$self->{if_state}} );
    shift( @{$self->{suspend}} );
    return( '' );
}

sub parse_eval_expr
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    return( '' ) if( !length( $text ) );
    
    my $perl = $self->parse_expr( $text );
    my $result;
    do
    {
        no strict;
        # Silence some warnings about bare words such as strings being eval'ed
        local $SIG{__WARN__} = sub{};
        # package main;
        no warnings 'uninitialized';
        # Only to test if this was a regular expression. If it was the array will contain successful match, other it will be empty
        # @rv will contain the regexp matches or the result of the eval
        local @matches = ();
        local @rv = ();
        my $eval = <<EOT;
\@rv = ($perl);
EOT
        if( $perl =~ /[\=\!]\~/ )
        {
            $eval .= <<EOT;
\@matches = \@-;
EOT
        }
        eval( $eval );
        $result = $rv[0];
        # Make any regular expression capture available for the next evaluation
        $self->{_regexp_capture} = \@rv if( scalar( @matches ) );
    };
    $result //= '';
    return( $self->error( "Eval error for expression '$text' translated to '$perl': $@" ) ) if( $@ );
    return( $result );
}

sub parse_exec
{
    my( $self, $args ) = @_;
    # NOTE: did we check enough?
    my $r = $self->apache_request;
    my $uri = $self->uri;
    my $filename;
    if( $r )
    {
        $filename = $r->filename;

        if( $r->allow_options & &Apache2::Const::OPT_INCNOEXEC )
        {
            $self->error( "httpd: exec used but not allowed in $filename" );
            return( $self->errmsg );
        }
    }
    # TODO Need to improve on this
    if( exists( $args->{cmd} ) )
    {
        # https://metacpan.org/pod/Apache2::SubProcess
        # Fails to work: <https://rt.cpan.org/Public/Bug/Display.html?id=54153>
        # <https://rt.cpan.org/Public/Dist/Display.html?Status=Active;Name=mod_perl>
        if( $r && MOD_PERL_SPAWN_PROC_PROG_WORKING )
        {
            my $data;
            my $fh = $r->spawn_proc_prog( $args->{cmd} );
            if( PERLIO_IS_ENABLED || IO::Select->new( $fh )->can_read(10) )
            {
                $data = <$fh>;
            }
            return( defined( $data ) ? $data : '' );
        }
        else
        {
            my $env = $self->env;
            local %ENV = %$env;
            # What a shame to fork exec. Too bad spawn_proc_prog() does not work.
            return( scalar( qx( $args->{cmd} ) ) );
        }
    }
    
    unless( exists( $args->{cgi} ) )
    {
        $self->error( "No 'cmd' or 'cgi' argument given to #exec" );
        return( $self->errmsg );
    }
    
    # Get a new Apache2::SSI::URI object
    my $cgi = $self->new_uri( $args->{cgi} ) || do
    {
        return( $self->errmsg );
    };
    my $doc_root = $self->document_root || do
    {
        $self->error( "No document root set." );
        return( $self->errmsg );
    };
    
    if( $cgi->code != 200 )
    {
        $self->error( "Error including cgi: subrequest returned status '" . $cgi->code . "', not 200" );
        return( $self->errmsg );
    }
    
    my $finfo = $cgi->finfo;
    if( !$finfo->exists )
    {
        $cgi->code( 404 );
        $self->error( "Error including cgi \"$args->{cgi}\". File not found. CGI resolved to \"", $cgi->filename, "\"" );
        return( $self->errmsg );
    }
    elsif( !$finfo->can_exec )
    {
        unless( $^O =~ /^(dos|mswin32|NetWare|symbian|win32)$/i && -T( "$finfo" ) )
        {
            # return( $self->error( "Error including cgi \"$args->{cgi}\". File is not executable by Apache user." ) );
            $self->error( "Error including cgi \"$args->{cgi}\". File is not executable by Apache user." );
            $cgi->code( 401 );
            return( $self->errmsg );
        }
    }
        
    
    if( $r )
    {
        my $rr = $cgi->apache_request;
#         my $u = URI->new( $rr->uri . ( length( $cgi->path_info ) ? $cgi->path_info : length( $uri->path_info ) ? $uri->path_info : '' ) );
#         $u->query( $uri->query_string ) if( !length( $cgi->query_string ) && length( $uri->query_string ) );
        $cgi->path_info( $uri->path_info ) if( !length( $cgi->path_info ) && length( $uri->path_info ) );
        $cgi->query_string( $uri->query_string ) if( !length( $cgi->query_string ) && length( $uri->query_string ) );
        $rr->content_type( 'application/x-httpd-cgi' );
        $cgi->env( GATEWAY_INTERFACE => 'CGI/1.1' );
        $cgi->env( DOCUMENT_URI => "$cgi" );
        my( $content, $headers ) = $rr->fetch_uri( "$cgi" );
        return( $content );
    }
    else
    {
        my $buf;
        {
            local $ENV{DOCUMENT_URI} = $cgi->document_uri;
            local $ENV{PATH_INFO} = $uri->path_info;
            local $ENV{PATH_INFO} = $cgi->path_info if( length( $cgi->path_info ) );
            local $ENV{QUERY_STRING} = $uri->query_string;
            local $ENV{QUERY_STRING} = $cgi->query_string if( length( $cgi->query_string ) );
            local $ENV{REMOTE_ADDR} = $self->remote_ip;
            local $ENV{REQUEST_METHOD} = 'GET';
            local $ENV{REQUEST_URI} = $cgi->document_uri;
            my $file = $cgi->filename;
            my $mime = $finfo->mime_type;
            if( $^O =~ /^(dos|mswin32|NetWare|symbian|win32)$/i && $mime eq 'text/x-perl' )
            {
                $buf = `$^X $file`;
            }
            else
            {
                $buf = qx( "$file" );
            }
        };
        # Failed to execute
        if( $? == -1 )
        {
            $cgi->code( 500 );
            return( $self->errmsg );
        }
        my( $key, $val );
        my $headers = {};
        while( $buf =~ s/([^\012]*)\012// ) 
        {
            my $line = $1;
            # if we need to restore as content when illegal headers are found.
            my $save = "$line\012"; 
    
            $line =~ s/\015$//;
            last unless( length( $line ) );
    
            if( $line =~ /^([a-zA-Z0-9_\-.]+)\s*:\s*(.*)/ ) 
            {
                # $response->push_header( $key, $val ) if( $key );
                $headers->{ $key } = $val if( $key );
                ( $key, $val ) = ( $1, $2 );
            } 
            elsif( $line =~ /^\s+(.*)/ && $key ) 
            {
                $val .= " $1";
            } 
            else 
            {
                # $response->push_header( "Client-Bad-Header-Line" => $line );
                $headers->{ 'Client-Bad-Header-Line' } = $line;
            }
        }
        # $response->push_header( $key, $val ) if( $key );
        $headers->{ $key } = $val if( $key );
        return( $buf );
    }
}

sub parse_expr
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    my $opts = {};
    if( @_ )
    {
        $opts = ref( $_[0] ) eq 'HASH'
            ? shift( @_ )
            : !( @_ % 2 )
                ? { @_ }
                : {};
    }
    $opts->{embedded} = 0 if( !exists( $opts->{embedded} ) );
    my $r = $self->apache_request;
    my $env = $self->env;
    my $prev_regexp_capture = $self->{_regexp_capture};
    unless( $self->{_exp} )
    {
        $self->{_exp} = Apache2::Expression->new( legacy => 1, debug => $self->debug );
    }
    
    my $exp = $self->{_exp};
    my $hash = {};
    try
    {
        local $SIG{ALRM} = sub{ die( "Timeout!\n" ) };
        alarm( 90 );
        $hash = $exp->parse( $text );
        alarm( 0 );
    }
    catch( $e )
    {
        return( $self->error( "Error parsing expression '$text': $e" ) );
    }
    my $res = [];
    $opts->{top} = 1;
    foreach my $this ( @{$hash->{elements}} )
    {
        my $res2 = $self->ap2perl_expr( $this, [], $opts );
        push( @$res, @$res2 );
    }
    return( join( ' ', @$res ) );
}

sub parse_flastmod
{
    my( $self, $args ) = @_;
    my $p = $self->find_file( $args );
    unless( $p->code == 200 )
    {
        return( $self->errmsg );
    }
    return( $self->_lastmod( $p, $args->{timefmt} || $self->{timefmt} ) );
}

sub parse_fsize
{ 
    my( $self, $args ) = @_;
    my $f = $self->find_file( $args );
    unless( $f->code == 200 )
    {
        return( $self->errmsg );
    }
    my $finfo = $f->finfo;
    my $size = $finfo->size;
    my $n = Module::Generic::Number->new( $size );
    if( $self->{sizefmt} eq 'bytes' )
    {
        # Not everyone is using a comma as thousand separator
        # 1 while( $size =~ s/^(\d+)(\d{3})/$1,$2/g );
        # return( $size );
        my $str = $n->format( 0 )->scalar;
        undef( $n );
        return( '' ) if( !defined( $str ) );
        return( $str );
    }
    elsif( $self->{sizefmt} eq 'abbrev' )
    {
        return( $size ) if( $size < 1024 );
        my $n = Module::Generic::Number->new( $size );
        my $str = $n->format_bytes->scalar;
        undef( $n );
        return( '' ) if( !defined( $str ) );
        return( $str );
    }
    else
    {
        $self->error( "Unrecognized size format '$self->{sizefmt}'" );
        return( $self->errmsg );
    }
}

# Functions
# See https://httpd.apache.org/docs/trunk/en/expr.html#page-header
# base64|env|escape|http|ldap|md5|note|osenv|replace|req|reqenv|req_novary|resp|sha1|tolower|toupper|unbase64|unescape
sub parse_func_base64 { return( shift->encode_base64( join( '', @_ ) ) ); }

# Return first match of note, reqenv, osenv
sub parse_func_env
{
    my $self = shift( @_ );
    my $var  = shift( @_ );
    my $r = $self->apache_request;
    my $env = $self->env;
    if( $r )
    {
        try
        {
            return( $r->subprocess_env( $var ) || $env->{ $var } || $self->notes( $var ) );
        }
        catch( $e )
        {
            return( $self->error( "An error occurred trying to get the environment value for variable \"${var}\": $e" ) );
        }
    }
    else
    {
        return( $env->{ $var } || $self->notes( $var ) );
    }
}

sub parse_func_escape { return( shift->encode_uri( join( '', @_ ) ) ); }

sub parse_func_http
{
    my $self = shift( @_ );
    my $header_name  = shift( @_ );
    my $r = $self->apache_request;
    if( $r )
    {
        my $headers = $r->headers_in;
        return( $headers->{ $header_name } );
    }
    # No http header outside of Apache
    else
    {
        my $env = $self->env;
        return( $env->{ $header_name } ) if( length( $env->{ $header_name } ) );
        my $name = $header_name =~ tr/-/_/;
        return( $env->{"HTTP_\U${name}\E"} ) if( length( $env->{"HTTP_\U${name}\E"} ) );
        return( $env->{ uc( $name ) } ) if( length( $env->{ uc( $name ) } ) );
        return( '' );
    }
}

# Apache documentation: "Escape characters as required by LDAP distinguished name escaping (RFC4514) and LDAP filter escaping (RFC4515)"
# Taken from Net::LDAP::Util
sub parse_func_ldap
{
    my $self = shift( @_ );
    my $val  = join( '', @_ );
    $val =~ s/([\x00-\x1F\*\(\)\\])/'\\' . unpack( 'H2', $1 )/oge;
    return( $val );
}

sub parse_func_md5 { return( shift->encode_md5( @_ ) ); }

# Notes are stored in the ENV global hash so they can be shared across processes
sub parse_func_note
{
    my $self = shift( @_ );
    my $var  = shift( @_ );
    return( $self->notes( $var ) );
}

# Essentially same as parse_func_note
sub parse_func_osenv
{
    my $self = shift( @_ );
    my $var  = shift( @_ );
    return( $ENV{ $var } );
}

sub parse_func_replace
{
    my $self = shift( @_ );
    my( $str, $what, $with ) = @_;
    $str =~ s/$what/$with/g;
    return( $str );
}

sub parse_func_req { return( shift->parse_func_http( @_ ) ); }

sub parse_func_reqenv
{
    my $self = shift( @_ );
    my $var  = shift( @_ );
    my $r = $self->apache_request;
    if( $r )
    {
        return( $r->subprocess_env( $var ) );
    }
    else
    {
        my $env = $self->env;
        return( $env->{ $var } );
    }
}

sub parse_func_req_novary { return( shift->parse_func_http( @_ ) ); }

sub parse_func_resp
{
    my $self = shift( @_ );
    my $header_name  = shift( @_ );
    my $r = $self->apache_request;
    if( $r )
    {
        my $headers = $r->headers_out;
        return( $headers->{ $header_name } );
    }
    # No http header outside of Apache
    else
    {
        return( '' );
    }
}

sub parse_func_sha1
{
    my $self = shift( @_ );
    my $val  = join( '', @_ );
    require Digest::SHA;
    return( Digest::SHA::sha1_hex( $val ) );
}

sub parse_func_tolower
{
    my $self = shift( @_ );
    return( lc( join( '', @_ ) ) );
}

sub parse_func_toupper
{
    my $self = shift( @_ );
    return( uc( join( '', @_ ) ) );
}

sub parse_func_unbase64 { return( shift->decode_base64( join( '', @_ ) ) ); }

sub parse_func_unescape { return( shift->decode_uri( join( '', @_ ) ) ); }

sub parse_if
{
    my( $self, $args ) = @_;
    unshift( @{$self->{if_state}}, 0 );
    unshift( @{$self->{suspend}}, $self->{suspend}->[0] );
    return( '' ) if( $self->{suspend}->[0] );
    return( $self->_handle_ifs( $self->parse_eval_expr( $args->{expr} ) ) );
}

sub parse_include
{
    my( $self, $args ) = @_;
    unless( exists( $args->{file} ) or exists( $args->{virtual} ) )
    {
        return( $self->error( "No 'file' or 'virtual' attribute found in SSI 'include' tag" ) );
    }
    my $f = $self->find_file( $args );
    unless( $f->code == 200 )
    {
        return( $self->errmsg );
    }
    my $filename = $f->filename;
    if( !-e( "$filename" ) )
    {
        return( $self->errmsg );
    }
    
    # TODO This needs to be improved, as we should not assume the file encoding is utf8
    # It could be binary or some other text encoding like iso-2022-jp
    # So we should slurp it, parse the meta tags if this is an html and decode if the charset attribute is set or default to utf8
    # But this complicates things quite a bit, so for now, it is just utf8 simply
    my $html = $f->slurp_utf8;
    if( !defined( $html ) )
    {
        $self->error( "Unable to get html data of included file \"", $f->filename, "\": ", $f->error );
        return( $self->errmsg );
    }
    my $clone = $self->clone || do
    {
        warn( $self->error );
        return( $self->errmsg );
    };
    # share our environment variables with our clone so we pass it to included files.
    # If we are running under mod_perl, we'll use subprocess_env
    my $env = $self->env;
    $clone->{_env} = $env;
    return( $clone->parse( $html ) );
}

# NOTE: Legacy
# http://perl.apache.org/docs/1.0/guide/snippets.html#Passing_Arguments_to_a_SSI_script
sub parse_perl
{
    my( $self, $args, $margs ) = @_;
    my $r = $self->apache_request;

    my( $pass_r, @arg1, @arg2, $sub ) = (1);
    {
        my @a;
        while( @a = splice( @$margs, 0, 2 ) )
        {
            $a[1] =~ s/\\(.)/$1/gs;
            if( lc( $a[0] ) eq 'sub' )
            {
                $sub = $a[1];
            }
            elsif( lc( $a[0] ) eq 'arg' )
            {
                push( @arg1, $a[1] );
            }
            elsif( lc( $a[0] ) eq 'args' )
            {
                push( @arg1, split( /,/, $a[1] ) );
            }
            elsif( lc( $a[0] ) eq 'pass_request' )
            {
                $pass_r = 0 if( lc( $a[1] ) eq 'no' );
            }
            elsif( $a[0] =~ s/^-// )
            {
                push( @arg2, @a );
            }
            # Any unknown get passed as key-value pairs
            else
            {
                push( @arg2, @a );
            }
        }
    }

    my $subref;
    # for <!--#perl sub="sub {print ++$Access::Cnt }" -->
    if( $sub =~ /^[[:blank:]\h]*sub[[:blank:]\h]/ )
    {
        $subref = eval( $sub );
        if( $@ ) 
        {
            $self->error( "Perl eval of '$sub' failed: $@" )
        }
        # return( $self->error( "sub=\"sub ...\" didn't return a reference" ) ) unless( ref( $subref ) );
        unless( ref( $subref ) )
        {
            $self->error( "sub=\"sub ...\" didn't return a reference" );
            return( $self->errmsg );
        }
    }
    # for <!--#perl sub="package::subr" -->
    else
    {
        no strict( 'refs' );
        $subref = ( defined( &{$sub} )
            ? \&{$sub}
            : defined( &{"${sub}::handler"} )
                ? \&{"${sub}::handler"}
                : \&{"main::$sub"});
    }
    
    if( $r )
    {
        $pass_r = 0 if( $r and lc( $r->dir_config( 'SSIPerlPass_Request' ) ) eq 'no' );
        unshift( @arg1, $r ) if( $pass_r );
    }
    return( scalar( $subref->( @arg1, @arg2 ) ) );
}

sub parse_printenv
{
    my $self = shift( @_ );
    my $env = $self->env;
    return( join( '', map( {"$_: $env->{$_}<br />\n"} sort( keys( %$env ) ) ) ) );
}

sub parse_set
{
    my( $self, $args ) = @_;
    my $r = $self->apache_request;
    my $env = $self->env;
    
    # $self->_interp_vars( $args->{value} );
    # Do we need to decode and encode it?
    # Possible values are: none, url, urlencoded, base64 or entity
    if( $args->{decoding} && lc( $args->{decoding} ) ne 'none' )
    {
        $args->{decoding} = lc( $args->{decoding} );
        try
        {
            if( $args->{decoding} eq 'url' )
            {
                $args->{value} = $self->decode_uri( $args->{value} );
            }
            elsif( $args->{decoding} eq 'urlencoded' )
            {
                $args->{value} = $self->decode_url( $args->{value} );
            }
            elsif( $args->{decoding} eq 'base64' )
            {
                $args->{value} = $self->decode_base64( $args->{value} );
            }
            elsif( $args->{decoding} eq 'entity' )
            {
                $args->{value} = $self->decode_entities( $args->{value} );
            }
        }
        catch( $e )
        {
            $self->error( "Decoding of value with method \"$args->{decoding}\" for variable \"$args->{var}\" failed: $e" );
            return( $self->errmsg );
        }
    }
    
    $args->{value} = $self->parse_eval_expr( $args->{value} );
    
    if( $args->{encoding} && lc( $args->{encoding} ) ne 'none' )
    {
        $args->{encoding} = lc( $args->{encoding} );
        try
        {
            if( $args->{encoding} eq 'url' )
            {
                $args->{value} = $self->encode_uri( $args->{value} );
            }
            elsif( $args->{encoding} eq 'urlencoded' )
            {
                $args->{value} = $self->encode_url( $args->{value} );
            }
            elsif( $args->{encoding} eq 'base64' )
            {
                $args->{value} = $self->encode_base64( $args->{value} );
            }
            elsif( $args->{encoding} eq 'entity' )
            {
                $args->{value} = $self->encode_entities( $args->{value} );
            }
        }
        catch( $e )
        {
            $self->error( "Enecoding of value with method \"$args->{decoding}\" for variable \"$args->{var}\" failed: $e" );
            return( $self->errmsg );
        }
    }
    
    if( $r )
    {
        $r->subprocess_env( $args->{var}, $args->{value} );
        $env->{ $args->{var} } = $args->{value};
    }
    else
    {
        $env->{ $args->{var} } = $args->{value};
    }
    return( '' );
}

sub parse_ssi
{
    my( $self, $html ) = @_;
    
    # For error reporting
    my $orig = $html;
    if( $html =~ s/^(\w+)[[:blank:]\h]*// )
    {
        my $tag = $1;
        return if( $self->{suspend}->[0] and !( $tag =~ /^(if|elif|else|endif)/ ) );
        my $method = lc( "parse_${tag}" );
        my $code = $self->can( $method ) ||
            return( $self->error( "ssi function $tag is unsupported. No method $method found in package \"", ref( $self ), "\"." ) );

        # Special case for comment directive because there is no key-value pair, but just text
        return( $self->$method( $html ) ) if( lc( $tag ) eq 'comment' );
        my $args = {};
        pos( $html ) = 0;
        if( $html =~ /^expr[[:blank:]\h]*\=/ )
        {
            if( $html =~ /^$EXPR_RE$/ )
            {
                $args->{ $+{attr_name} } = $+{attr_val};
            }
            else
            {
                warn( "Expression '$orig' is malformed\n" );
            }
        }
        else
        {
            while( $html =~ /\G($ATTRIBUTES_RE)/gmcs )
            {
                $args->{ $+{attr_name} } = $+{attr_val};
            }
        }
#         return( $self->$method( {@$args}, $args ) );
        return( $self->$method( $args ) );
    }
    return( '' );
}

sub path_info { return( shift->uri->path_info( @_ ) ); }

sub query_string { return( shift->uri->query_string( @_ ) ); }

# http://httpd.apache.org/docs/2.4/developer/new_api_2_4.html
# https://github.com/eprints/eprints/issues/214
sub remote_ip
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    my $new = '';
    $new = shift( @_ ) if( @_ );
    my $ip;
    if( $r )
    {
        # In Apache v2.4 or higher, client_ip is used instead of remote_ip
        my $c = $r->connection;
        my $coderef = $c->can( 'client_ip' ) // $c->can( 'remote_ip' );
        try
        {
            $coderef->( $c, $new ) if( $new );
            $ip = $coderef->( $c );
        }
        catch( $e )
        {
            $self->error( "Unable to get the remote ip with the method Apache2::Connection->", ( $c->can( 'client_ip' ) ? 'client_ip' : 'remote_ip' ), ": $e" );
        }
        $ip = $self->parse_echo({ var => 'REMOTE_ADDR' }) if( !CORE::length( $ip ) );
    }
    else
    {
        $self->{remote_ip} = $new if( $new );
        $ip = $self->{remote_ip};
        $ip = $self->parse_echo({ var => 'REMOTE_ADDR' }) if( !CORE::length( $ip ) );
    }
    return( $ip ) if( CORE::length( $ip ) );
    return( '' );
}

# Same as document_uri
sub request_uri { return( shift->uri->document_uri( @_ ) ); }

sub server_version
{
    my $self = shift( @_ );
    $self->{server_version} = $SERVER_VERSION if( !CORE::length( $self->{server_version} ) && CORE::length( $SERVER_VERSION ) );
    $self->{server_version} = shift( @_ ) if( @_ );
    return( $self->{server_version} ) if( $self->{server_version} );
    my $vers = '';
    if( $self->mod_perl )
    {
        try
        {
            my $desc = Apache2::ServerUtil::get_server_description();
            if( $desc =~ /\bApache\/([\d\.]+)/ )
            {
                $vers = $1;
            }
        }
        catch( $e )
        {
        }
    }
    
    require File::Which;
    # NOTE: to test our alternative approach
    if( !$vers && ( my $apxs = File::Which::which( 'apxs' ) ) )
    {
        $vers = qx( $apxs -q -v HTTPD_VERSION );
        chomp( $vers );
        $vers = '' unless( $vers =~ /^[\d\.]+$/ );
    }
    # Try apache2
    if( !$vers )
    {
        foreach my $bin ( qw( apache2 httpd ) )
        {
            if( ( my $apache2 = File::Which::which( $bin ) ) )
            {
                my $v_str = qx( $apache2 -v );
                if( ( split( /\r?\n/, $v_str ) )[0] =~ /\bApache\/([\d\.]+)/ )
                {
                    $vers = $1;
                    chomp( $vers );
                    last;
                }
            }
        }
    }
    if( $vers )
    {
        $self->{server_version} = $SERVER_VERSION = version->parse( $vers );
        return( $self->{server_version} );
    }
    return( '' );
}

sub sizefmt { return( shift->_set_get_scalar( 'sizefmt', @_ ) ); }

sub timefmt { return( shift->_set_get_scalar( 'timefmt', @_ ) ); }

sub trunk { return( shift->_set_get_boolean( 'trunk', @_ ) ); }

sub uri { return( shift->_set_get_object( 'uri', 'Apache2::SSI::URI', @_ ) ); }

sub parse_expr_args
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    return( $self->error( "I was expecting an array reference, but instead got '$args'." ) ) if( !$self->_is_array( $args ) );
    my $buff = [];
    my $prev_regexp_capture = $self->{_regexp_capture};
    my $r = $self->apache_request;
    my $env = $self->env;
    foreach my $this ( @$args )
    {
        my $res = $self->ap2perl_expr( $this, [] );
        push( @$buff, @$res ) if( $res );
    }
    return( join( ', ', @$buff ) );
}

sub _format_time
{
    my( $self, $time, $format, $tzone ) = @_;
    my $env = $self->env;
    $format ||= $self->{timefmt};
    # Quotes are important as they are used to stringify overloaded $time
    my $params = { epoch => "$time" };
    $params->{time_zone} = ( $tzone || 'local' );
    $params->{locale} = $env->{lang} if( length( $env->{lang} ) );
    require DateTime;
    require DateTime::Format::Strptime;
    my $tz;
    # DateTime::TimeZone::Local will die ungracefully if the local timezeon is not set with the error:
    # "Cannot determine local time zone"
    try
    {
        require DateTime::TimeZone;
        $tz = DateTime::TimeZone->new( name => 'local' );
    }
    catch( $e )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
        warn( "Your system is missing key timezone components. Reverting to UTC instead of local time zone.\n" );
    }
    
    try
    {
        my $dt = DateTime->from_epoch( %$params );
        if( length( $format ) )
        {
            my $fmt = DateTime::Format::Strptime->new(
                pattern => $format,
                time_zone => ( $params->{time_zone} || $tz ),
                locale => $dt->locale->code,
            );
            $dt->set_formatter( $fmt );
            return( $dt );
        }
        else
        {
            return( $dt->format_cldr( $dt->locale->date_format_full ) );
        }
    }
    catch( $e )
    {
        $self->error( "An error occurred getting a DateTime object for time \"$time\" with format \"$format\": $e" );
        return( $self->errmsg );
    }
}

sub _handle_ifs
{
    my $self = shift( @_ );
    my $cond = shift( @_ );
    
    if( $self->{if_state}->[0] )
    {
        $self->{suspend}->[0] = 1;
    }
    else
    {
        $self->{suspend}->[0] = !( $self->{if_state}->[0] = !!$cond );
    }
    return( '' );
}

sub _has_utf8
{
    my $self = shift( @_ );
    return( $_[0] =~ /$IS_UTF8/ );
}

sub _interp_vars
{
    # Find all $var and ${var} expressions in the string and fill them in.
    my $self = shift( @_ );
    # Because ssi_echo may change $1, $2, ...
    my( $a, $b, $c );
    $_[0] =~ s{ (^|[^\\]) (\\\\)* \$(\{)?(\w+)(\})? }
              { ($a,$b,$c) = ($1,$2,$4);
                $a . ( length( $b ) ? substr( $b, length( $b ) / 2 ) : '' ) . $self->parse_echo({ var => $c }) }exg;
}

sub _ipmatch
{
    my $self = shift( @_ );
    my $subnet = shift( @_ ) || return( $self->error( "No subnet provided" ) );
    my $ip   = shift( @_ ) || $self->remote_ip;
    try
    {
        local $SIG{__WARN__} = sub{};
        require Net::Subnet;
        my $net = Net::Subnet::subnet_matcher( $subnet );
        my $res = $net->( $ip );
        return( $res ? 1 : 0 );
    }
    catch( $e )
    {
        $self->error( "Error while calling Net::Subnet: $e" );
        return( 0 );
    }
}

sub _is_ip
{
    my $self = shift( @_ );
    my $ip   = shift( @_ );
    return( 0 ) if( !length( $ip ) );
    # We need to return either 1 or 0. By default, perl return undef for false
    return( $ip =~ /^(?:$RE{net}{IPv4}|$RE{net}{IPv6})$/ ? 1 : 0 );
}

sub _is_number
{
    my $self = shift( @_ );
    my $word = shift( @_ );
    return( 0 ) if( !length( $word ) );
    return( $word =~ /^(?:$RE{num}{int}|$RE{num}{real})$/ ? 1 : 0 );
}

sub _is_perl_script
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "No file was provided to check if it looks like a perl script." ) ) if( !length( "$file" ) );
    if( -T( "$file" ) )
    {
        my $io = IO::File->new( "<$file" ) || return( $self->error( "Unable to open file \"$file\" in read mode: $!" ) );
        my $shebang = $io->getline;
        chomp( $shebang );
        $io->close;
        # We explicitly return 1 or 0, because otherwise upon failure perl would return undef which we reserve for errors
        return( $shebang =~ /^\#\!(.*?)\bperl\b/i ? 1 : 0 );
    }
    return( 0 );
}

sub _lastmod                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
{
    my( $self, $file, $format ) = @_;
    return( $self->_format_time( ( stat( "$file" ) )[9], $format ) );
}

# This is different from the env() method. This one is obviously private
# whereas the env() one has triggers that could otherwise create an infinite loop.
sub _set_env
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return( $self->error( "No environment variable name provided." ) ) if( !length( $name ) );
    $self->{_env} = {} if( !ref( $self->{_env} ) );
    my $env = $self->{_env};
    $env->{ $name } = shift( @_ );
    return( $self );
}

sub _set_var
{
    my $self = shift( @_ );
    my $r    = shift( @_ );
    if( $r )
    {
        $r->subprocess_env( $_[0], $_[1] );
    }
    else
    {
        my $env = $self->env;
        $env->{ $_[0] } = $_[1];
    }
    return( $_[1] );
}

sub _time_args
{
    # This routine must respect the caller's wantarray() context.
    my( $self, $time, $zone ) = @_;
    return( ( $zone && $zone =~ /GMT/ ) ? gmtime( $time ) : localtime( $time ) );
}

# Credits: Torsten Förtsch
{
    # NOTE: Apache2::SSI::Filter class
    package
        Apache2::SSI::Filter;

    if( exists( $ENV{MOD_PERL} ) &&
        $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ )
    {
        require Apache2::Filter;
        require Apache2::RequestUtil;
        require APR::Brigade;
        require APR::Bucket;
        require parent;
        parent->import( qw( Apache2::Filter ) );
        require Apache2::Const;
        Apache2::Const->import( -compile => qw( OK DECLINED HTTP_OK ) );
        eval( "sub fetch_content_filter : FilterRequestHandler { return( &apache_filter_handler ); }" );
    }

    sub read_bb
    {
        my( $bb, $buffer ) = @_;
        my $r = Apache2::RequestUtil->request;
        my $debug = int( $r->dir_config( 'Apache2_SSI_DEBUG' ) );

        my $eos = 0;
        # Cycling through APR::Bucket
#         while( my $b = $bb->first )
#         {
#             $eos++ if( $b->is_eos );
#             $r->log->debug( __PACKAGE__ . ": ", $b->length, " bytes of data received." );
#             ## $b->read( my $bdata );
#             my $len = $b->read( my $bdata );
#             $r->log->debug( __PACKAGE__ . ": data read is '$bdata' ($len byts read)" );
#             push( @$buffer, $bdata ) if( $buffer and length( $bdata ) );
#             $b->delete;
#         }
        $r->log->debug( __PACKAGE__, ": cycling through all the Brigade buckets." ) if( $debug > 0 );
        for( my $b = $bb->first; $b; $b = $bb->next( $b ) )
        {
            $r->log->debug( __PACKAGE__ . ": ", $b->length, " bytes of data received." ) if( $debug > 0 );
            my $len = $b->read( my $bdata );
            $r->log->debug( __PACKAGE__ . ": data read is '$bdata' ($len byts read)" ) if( $debug > 0 );
            push( @$buffer, $bdata ) if( $buffer and length( $bdata ) );
            $b->delete;
            $eos++, last if( $b->is_eos );
        }
        return( $eos );
    }
    
    # We cannot declare it now. Instead we eval it so that it works under Apache and gets discarded outside
    # sub fetch_content_filter : FilterRequestHandler
    sub apache_filter_handler
    {
        my( $f, $bb ) = @_;
        my $r = $f->r;
        unless( $f->ctx )
        {
            unless( $r->status == &Apache2::Const::HTTP_OK or
                    $r->pnotes->{force_fetch_content} )
            {
                $f->remove;
                return( &Apache2::Const::DECLINED );
            }
            $f->ctx(1);
        }
        
        my $debug = int( $r->dir_config( 'Apache2_SSI_DEBUG' ) );

        my $out = $f->r->pnotes->{out};
        $r->log->debug( __PACKAGE__ . ": reading data using '$out'." ) if( $debug > 0 );
        if( ref( $out ) eq 'ARRAY' )
        {
            read_bb( $bb, $out );
            $r->log->debug( __PACKAGE__ . ": data read is: ", join( '', @$out ) ) if( $debug > 0 );
        }
        elsif( ref( $out ) eq 'CODE' )
        {
            read_bb( $bb, my $buf = [] );
            $out->( $f->r, @$buf );
        }
        else
        {
            $r->log->debug( __PACKAGE__ . ": request is declined because \$out is neither an array or code." ) if( $debug > 0 );
            $f->remove;
            return( &Apache2::Const::DECLINED );
        }
        return( &Apache2::Const::OK );
    }
}

{
    # NOTE: Apache2::RequestRec class
    package
        Apache2::RequestRec;

    if( exists( $ENV{MOD_PERL} ) &&
        $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ )
    {
        require Apache2::RequestRec;
        require Apache2::SubRequest;
        require APR::Table;
        require APR::Finfo;
        require APR::Const;
        APR::Const->import( -compile => qw( FILETYPE_REG ) );
        require Apache2::Const;
        Apache2::Const->import( -compile => qw( HTTP_OK OK HTTP_NOT_FOUND ) );
        require Apache2::Filter;
        require Apache2::FilterRec;
        require Apache2::Module;
        require ModPerl::Util;
    }

    sub headers_sent
    {
        my( $I ) = @_;
        # Check if any output has already been sent. If so the HTTP_HEADER
        # filter is missing in the output chain. If it is still present we
        # can send a normal error message or modify headers, see ap_die()
        # in httpd-2.2.x/modules/http/http_request.c.
        for( my $n = $I->output_filters; $n; $n = $n->next )
        {
            return if( $n->frec->name eq 'http_header' );
        }
        # http_header filter missing -- that means headers are sent
        return( 1 );
    }

    sub fetch_uri
    {
        my( $I, $url, $headers, $outfn ) = @_;
        if( @_ == 3 and ref( $headers ) eq 'CODE' )
        {
            $outfn = $headers;
            undef( $headers );
        }

        my $output = [];
        my $proxy = $url =~ m!^\w+?://!;
        my $subr;
        if( $proxy )
        {
            return unless( Apache2::Module::loaded( 'mod_proxy.c' ) );
            $subr = $I->lookup_uri( '/' );
        }
        else
        {
            $subr = $I->lookup_uri( $url );
        }
        if( $subr->status == &Apache2::Const::HTTP_OK and
            ( length( $subr->handler ) ||
              $subr->finfo->filetype == &APR::Const::FILETYPE_REG ) )
        {
            @{$subr->pnotes}{qw( out force_fetch_content )} = ( $outfn || $output, 1 );
            $subr->add_output_filter( \&Apache2::SSI::Filter::apache_filter_handler );
            if( $proxy )
            {
                $subr->proxyreq(2);
                $subr->filename( "proxy:" . $url );
                $subr->handler( 'proxy_server' );
            }
            $subr->headers_in->clear;
            if( $headers )
            {
                for( my $i = 0; $i < @$headers; $i += 2 )
                {
                    $subr->headers_in->add( @$headers[ $i, $i + 1 ] );
                }
            }
            $subr->headers_in->add( 'User-Agent' => "Apache2::SSI/$Apache2::SSI::VERSION" )
                unless( exists( $subr->headers_in->{'User-Agent'} ) );
            $_ = $I->headers_in->{Host} and $subr->headers_in->add( 'Host' => $_ )
                unless( exists( $subr->headers_in->{'Host'} ) );
            $subr->run;
            if( wantarray )
            {
                my( %hout );
                $hout{STATUS}     = $subr->status;
                $hout{STATUSLINE} = $subr->status_line;
                $subr->headers_out->do(sub
                {
                    $hout{ lc( $_[0] ) } = $_[1];
                    1;
                });
                return( ( join( '', @$output ), \%hout ) );
            }
            else
            {
                return( join( '', @$output ) );
            }
        }
        if( wantarray )
        {
            my( %hout );
            $hout{STATUS} = $subr->status;
            $hout{STATUS} = &Apache2::Const::HTTP_NOT_FOUND
                if( $hout{STATUS} == &Apache2::Const::HTTP_OK );
            $subr->headers_out->do(sub
            {
                $hout{ lc( $_[0] ) } = $_[1];
                1;
            });
            return( ( undef, \%hout ) );
        }
        else
        {
            return;
        }
        return;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Apache2::SSI - Apache2 Server Side Include

=head1 SYNOPSIS

Outside of Apache:

    use Apache2::SSI;
    my $ssi = Apache2::SSI->new(
        # If running outside of Apache
        document_root => '/path/to/base/directory'
        # Default error message to display when ssi failed to parse
        # Default to [an error occurred while processing this directive]
        errmsg => '[Oops]'
    );
    my $fh = IO::File->new( "</some/file.html" ) || die( "$!\n" );
    $fh->binmode( ':utf8' );
    my $size = -s( $fh );
    my $html;
    $fh->read( $html, $size );
    $fh->close;
    if( !defined( my $result = $ssi->parse( $html ) ) )
    {
        $ssi->throw;
    };
    print( $result );

Inside Apache, in the VirtualHost configuration, for example:

    PerlModule Apache2::SSI
    PerlOptions +GlobalRequest
    PerlSetupEnv On
    <Directory "/home/joe/www">
        Options All +Includes +ExecCGI -Indexes -MultiViews
        AllowOverride All
        SetHandler modperl
        # You can choose to set this as a response handler or a output filter, whichever works.
        # PerlResponseHandler Apache2::SSI
        PerlOutputFilterHandler Apache2::SSI
        # If you do not set this to On, path info will not work, example:
        # /path/to/file.html/path/info
        # See: <https://httpd.apache.org/docs/current/en/mod/core.html#acceptpathinfo>
        AcceptPathInfo On
        # To enable no-caching (see no_cache() in Apache2::RequestUtil:
        PerlSetVar Apache2_SSI_NO_CACHE On
        # This is required for exec cgi to work:
        # <https://httpd.apache.org/docs/current/en/mod/mod_include.html#element.exec>
        <Files ~ "\.pl$">
            SetHandler perl-script
            AcceptPathInfo On
            PerlResponseHandler ModPerl::PerlRun
            # Even better for stable cgi scripts:
            # PerlResponseHandler ModPerl::Registry
            # Change this in mod_perl1 PerlSendHeader On to the following:
            # <https://perl.apache.org/docs/2.0/user/porting/compat.html#C_PerlSendHeader_>
            PerlOptions +ParseHeaders
        </Files>
        <Files ~ "\.cgi$">
            SetHandler cgi-script
            AcceptPathInfo On
        </Files>
        # To enable debugging output in the Apache error log
        # PerlSetVar Apache2_SSI_DEBUG 3
        # To set the default echo message
        # PerlSetVar Apache2_SSI_Echomsg 
        # To Set the default error message
        # PerlSetVar Apache2_SSI_Errmsg "Oops, something went wrong"
        # To Set the default size format: bytes or abbrev
        # PerlSetVar Apache2_SSI_Sizefmt "bytes"
        # To Set the default date time format
        # PerlSetVar Apache2_SSI_Timefmt ""
        # To enable legacy mode:
        # PerlSetVar Apache2_SSI_Expression "legacy"
        # To enable trunk mode:
        # PerlSetVar Apache2_SSI_Expression "trunk"
    </Directory>

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

L<Apache2::SSI> implements L<Apache Server Side Include|https://httpd.apache.org/docs/current/en/howto/ssi.html>, a.k.a. SSI, within and outside of Apache2/mod_perl2 framework.

L<Apache2::SSI> is inspired from the original work of L<Apache::SSI> with the main difference that L<Apache2::SSI> works well when called from within Apache mod_perl2 as well as when called outside of Apache if you want to simulate L<SSI|https://httpd.apache.org/docs/current/en/howto/ssi.html>.

L<Apache2::SSI> also implements all of Apache SSI features, including functions, encoding and decoding and old style variables such as C<${QUERY_STRING}> as well as modern style such as C<v('QUERY_STRING')> and variants such as C<%{REQUEST_URI}>.

See below details in this documentation and in the section on L</"SSI Directives">

Under Apache mod_perl, you would implement it like this in your C<apache2.conf> or C<httpd.conf>

    <Files *.phtml>
        SetHandler modperl
        PerlOutputFilterHandler Apache2::SSI
    </Files>

This would enable L<Apache2::SSI> for files whose extension is C<.phtml>. You can also limit this by location, such as:

    <Location /some/web/path>
        <Files *.html>
            SetHandler modperl
            PerlOutputFilterHandler Apache2::SSI
        </Files>
    </Location>

In the example above, we enable it in files with extensions C<.phtml>, but you can, of course, enable it for all html by setting extension C<.html> or whatever extension you use for your html files.

As pointed out by Ken Williams, the original author of L<Apache::SSI>, the benefit for using L<Apache2::SSI> is:

=over 4

=item 1. You want to subclass L<Apache2::SSI> and have granular control on how to render ssi

=item 2. You want to "parse the output of other mod_perl handlers, or send the SSI output through another handler"

=item 3. You want to imitate SSI without activating them or without using Apache (such as in command line) or within your perl/cgi script

=back

=head2 INSTALLATION

    perl Makefile.PL
    make
    make test
    sudo make install

This will detect if you have Apache installed and run the Apache mod_perl2 tests by starting a separate instance of Apache on a non-standard port like 8123 under your username just for the purpose of testing. This is all handled automatically by L<Apache::Test>

If you do not have Apache or mod_perl installed, it will still install, but obviously not start an instance of Apache/mod_perl, nor perform any of the Apache mod_perl tests.

It tries hard to find the Apache configuration file. You can help it by providing command line modifiers, such as:

    perl Makefile.PL -apxs /usr/bin/apxs

or, even specify the Apache configuration file:

    perl Makefile.PL -apxs /usr/bin/apxs -httpd_conf /home/john/etc/apache2/apache2.conf

To run only some tests, for example:

    make test TEST_FILES="./t/31.file.t"

If you are on a Linux type system, you can install C<apxs> by issuing on the command line:

    apt install apache2-dev

You can check if you have it installed with the following command:

    dpkg -l | grep apache

See L<ExtUtils::MakeMaker> for more information.

=head1 METHODS

=head2 new

This instantiate an object that is used to access other key methods. It takes the following parameters:

=over 4

=item I<apache_filter>

This is the L<Apache2::Filter> object object that is provided if running under mod_perl.

=item I<apache_request>

This is the L<Apache2::RequestRec> object that is provided if running under mod_perl.

it can be retrieved from L<Apache2::RequestUtil/request> or via L<Apache2::Filter/r>

You can get this L<Apache2::RequestRec> object by requiring L<Apache2::RequestUtil> and calling its class method L<Apache2::RequestUtil/request> such as Apache2::RequestUtil->request and assuming you have set C<PerlOptions +GlobalRequest> in your Apache Virtual Host configuration.

Note that there is a main request object and subprocess request object, so to find out which one you are dealing with, use L<Apache2::RequestUtil/is_initial_req>, such as:

    use Apache2::RequestUtil (); # extends Apache2::RequestRec objects
    my $r = $r->is_initial_req ? $r : $r->main;

=item I<debug>

Sets the debug level. Starting from 3, this will output on the STDERR or in Apache error log a lot of debugging output.

=item I<document_root>

This is only necessary to be provided if this is not running under Apache mod_perl. Without this value, L<Apache2::SSI> has no way to guess the document root and will not be able to function properly and will return an L</error>.

=item I<document_uri>

This is only necessary to be provided if this is not running under Apache mod_perl. This must be the uri of the document being served, such as C</my/path/index.html>. So, if you are using this outside of the rim of Apache mod_perl and your file resides, for example, at C</home/john/www/my/path/index.html> and your document root is C</home/john/www>, then the document uri would be C</my/path/index.html>

=item I<errmsg>

The error message to be returned when a ssi directive fails. By default, it is C<[an error occurred while processing this directive]>

=item I<html>

The html data to be parsed. You do not have to provide that value now. You can provide it to L</parse> as its first argument when you call it.

=item I<legacy>

Takes a boolean value suchas C<1> or C<0> to indicate whether the Apache2 expression supported accepts legacy style.

Legacy Apache expression typically allows for perl style variable C<${REQUEST_URI}> versus the modern style of C<%{REQUEST_URI}> and just an equal sign to imply a regular expression such as:

    $HTTP_COOKIES = /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/

Modern expression equivalent would be:

    %{HTTP_COOKIES} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/

See L<Regexp::Common::Apache2> for more information.

See also the property I<trunk> to enable experimental expressions.

=item I<remote_ip>

This is used when you want to artificially set the remote ip address, i.e. the address of the visitor accessing the page. This is used essentially by the SSI directive:

    my $ssi = Apache2::SSI->new( remote_ip => '192.168.2.10' ) ||
        die( Apache2::SSI->error );

    <!--#if expr="-R '192.168.2.0/24' || -R '127.0.0.1/24'" -->
    Remote ip is part of my private network
    <!--#else -->
    Go away!
    <!--#endif -->

=item I<sizefmt>

The default way to format a file size. By default, this is C<abbrev>, which means a human readable format such as C<2.5M> for 2.5 megabytes. Other possible value is C<bytes> which would have the C<fsize> ssi directive return the size in bytes.

See L<Apache2 documentation|https://httpd.apache.org/docs/current/en/howto/ssi.html> for more information on this.

=item I<timefmt>

The default way to format a date time. By default, this uses the display according to your locale, such as C<ja_JP> (for Japan) or C<en_GB> for the United Kingdoms. The time zone can be specified in the format, or it will be set to the local time zone, whatever it is.

See L<Apache2 documentation|https://httpd.apache.org/docs/current/en/howto/ssi.html> for more information on this.

=item I<trunk>

This takes a boolean value such as C<0> or C<1> and when enabled this allows the support for Apache2 experimental expressions.

See L<Regexp::Common::Apache2> for more information.

Also, see the property I<legacy> to enable legacy Apache2 expressions.

=back

=head2 handler

This is a key method expected by mod_perl. Depending on how this module is used, it will redirect either to L</apache_filter_handler> or to L</apache_response_handler>

=head2 ap2perl_expr

This method is used to convert Apache2 expressions into perl equivalents to be then eval'ed.

It takes an hash reference provided by L<Apache2::Expression/parse>, an array reference to store the output recursively and an optional hash reference of parameters.

It parse recursively the structure provided in the hash reference to provide the perl equivalent for each Apache2 expression component.

It returns the array reference provided used as the content buffer. This array is used by L</parse_expr> and then joined using a single space to form a string of perl expression to be eval'ed.

=head2 apache_filter

Set or get the L<Apache2::Filter> object.

When running under Apache mod_perl this is set automatically from the special L</handler> method.

=head2 apache_filter_handler

This method is called from L</handler> to handle the Apache response when this module L<Apache2::SSI> is used as a filter handler.

See also L</apache_response_handler>

=head2 apache_request

Sets or gets the L<Apache2::RequestRec> object. As explained in the L</new> method, you can get this Apache object by requiring the package L<Apache2::RequestUtil> and calling L<Apache2::RequestUtil/request> such as C<Apache2::RequestUtil->request> assuming you have set C<PerlOptions +GlobalRequest> in your Apache Virtual Host configuration.

When running under Apache mod_perl this is set automatically from the special L</handler> method, such as:

    my $r = $f->r; # $f is the Apache2::Filter object provided by Apache

=head2 apache_response_handler

This method is called from L</handler> to handle the Apache response when this module L<Apache2::SSI> is used as a response handler.

See also L</apache_filter_handler>

=head2 clone

Create a clone of the object and return it.

=head2 decode_base64

Decode base64 data provided. When running under Apache mod_perl, this uses L<APR::Base64/decode> module, otherwise it uses L<MIME::Base64/decode>

If the decoded data contain utf8 data, this will decoded the utf8 data using L<Encode/decode>

If an error occurred during decoding, it will return undef and set an L</error> object accordingly.

=head2 decode_entities

Decode html data containing entities. This uses L<HTML::Entities/decode_entities>

If an error occurred during decoding, it will return undef and set an L</error> object accordingly.

Example:

    $ssi->decode_entities( 'Tous les &Atilde;&ordf;tres humains naissent libres et &Atilde;&copy;gaux en dignit&Atilde;&copy; et en droits.' );
    # Tous les êtres humains naissent libres et égaux en dignité et en droits.

=head2 decode_uri

Decode uri encoded data. This uses L<URI::Escape/uri_unescape>.

Not to be confused with x-www-form-urlencoded data. For that see L</decode_url>

If an error occurred during decoding, it will return undef and set an L</error> object accordingly.

Example:

    $ssi->decode_uri( 'https%3A%2F%2Fwww.example.com%2F' );
    # https://www.example.com/

=head2 decode_url

Decode x-www-form-urlencoded encoded data. When using Apache mod_perl, this uses L<APR::Request/decode> and L<Encode/decode>, otherwise it uses L<URL::Encode/url_decode_utf8> (its XS version) to achieve the same result.

If an error occurred during decoding, it will return undef and set an L</error> object accordingly.

Example:

    $ssi->decode_url( 'Tous+les+%C3%83%C2%AAtres+humains+naissent+libres+et+%C3%83%C2%A9gaux+en+dignit%C3%83%C2%A9+et+en+droits.' );
    # Tous les êtres humains naissent libres et égaux en dignité et en droits.

=head2 document_filename

This is an alias for L<Apache2::SSI::URI/filename>

=head2 document_directory

Returns an L<Apache2::SSI::URI> object of the current directory of the L</document_uri> provided.

=head2 document_path

Sets or gets the uri path to the document. This is the same as L</document_uri>, except it is striped from L</query_string> and L</path_info>.

=head2 document_root

Sets or gets the document root.

Wen running under Apache mod_perl, this value will be available automatically, using L<Apache2::RequestRec/document_root> method.

If it runs outside of Apache, this will use the value provided upon instantiating the object and passing the I<document_root> parameter. If this is not set, it will return the value of the environment variable C<DOCUMENT_ROOT>.

=head2 document_uri

Sets or gets the document uri, which is the uri of the document being processed.

For example:

    /index.html

Under Apache, this will get the environment variable C<DOCUMENT_URI> or calls the L<Apache2::RequestRec/uri> method.

Outside of Apache, this will rely on a value being provided upon instantiating an object, or the environment variable C<DOCUMENT_URI> be present.

The value should be an absolute uri.

=head2 echomsg

The default message to be returned for the C<echo> command when the variable called is not defined.

Example:

    $ssi->echomsg( '[Value Undefined]' );
    # or in the document itself
    <!--#config echomsg="[Value Undefined]" -->
    <!--#echo var="NON_EXISTING" encoding="none" -->

would produce:

    [Value Undefined]

=head2 encode_base64

Encode data provided into base64. When running under Apache mod_perl, this uses L<APR::Base64/encode> module, otherwise it uses L<MIME::Base64/encode>

If the data have the perl internal utf8 flag on as checked with L<Encode/is_utf8>, this will encode the data into utf8 using L<Encode/encode> before encoding it into base64.

Please note that the base64 encoded resulting data is all on one line, similar to what Apache would do. The data is B<NOT> broken into lines of 76 characters.

If an error occurred during encoding, it will return undef and set an L</error> object accordingly.

=head2 encode_entities

Encode data into html entities. This uses L<HTML::Entities/encode_entities>

If an error occurred during encoding, it will return undef and set an L</error> object accordingly.

Example:

    $ssi->encode_entities( 'Tous les êtres humains naissent libres et égaux en dignité et en droits.' );
    # Tous les &Atilde;&ordf;tres humains naissent libres et &Atilde;&copy;gaux en dignit&Atilde;&copy; et en droits.

=head2 encode_uri

Encode uri data. This uses L<URI::Escape::XS/uri_escape>.

Not to be confused with x-www-form-urlencoded data. For that see L</encode_url>

If an error occurred during encoding, it will return undef and set an L</error> object accordingly.

Example:

    $ssi->encode_uri( 'https://www.example.com/' );
    # https%3A%2F%2Fwww.example.com%2F

=head2 encode_url

Encode data provided into an x-www-form-urlencoded string. When using Apache mod_perl, this uses L<APR::Request/encode>, otherwise it uses L<URL::Encode/url_encode_utf8> (its XS version)

If an error occurred during decoding, it will return undef and set an L</error> object accordingly.

Example:

    $ssi->encode_url( 'Tous les êtres humains naissent libres et égaux en dignité et en droits.' );
    # Tous+les+%C3%83%C2%AAtres+humains+naissent+libres+et+%C3%83%C2%A9gaux+en+dignit%C3%83%C2%A9+et+en+droits.

=head2 env

Sets or gets the value for an environment variable. Or, if no environment variable name is provided, it returns the entire hash reference. This method is intended to be used by users of this module, not by developers wanting to inherit from it.

Note that the environment variable hash is unique for each new object, so it works like L<Apache2::RequestRec/subprocess_env>, meaning each process has its set of environment variable.

When a value is set for an environment variable that has an equivalent name, it will call the method as well with the new value provided. This is done to ensure data consistency and also additional processing if necessary.

For example, let assume you set the environment variable C<REQUEST_URI> or C<DOCUMENT_URI> like this:

    $ssi->env( REQUEST_URI => '/some/path/to/file.html?q=something&l=ja_JP' );

This will, in turn, call L</request_uri>, which is an alias for L<document_uri> and this method will get the uri, path info and query string from the value provided and set those values accordingly, so they can be available when parsing.

=head2 errmsg

Sets or gets the error message to be displayed in lieu of a faulty ssi directive. This is the same behaviour as in Apache.

=head2 error

Retrieve the error object set. This is a L<Module::Generic::Error> object.

This module does not die nor "croak", but instead returns undef when an error occurs and set the error object.

It is up to you to check the return value of the method calls. If you do not, you will miss important information. If you really want your script to die, it is up to you to interrupt it:

    if( !defined( $ssi->parse( $some_html_data ) ) )
    {
        die( $ssi->error );
    }

or maybe more simply, when you are sure you will not get a false, but defined value:

    $ssi->parse( $some_html_data ) || die( $ssi->error );

This example is dangerous, because L</parse> might return an empty string which will be construed as a false value and will trigger the die statement, even though no error had occurred.

=head2 filename

This is an alias for L<Apache2::SSI::URI/filename>

=head2 find_file

Provided with a file path, and this will resolve any variable used and attempt to look it up as a file if the argument I<file> is provided with a file path as a value, or as a URI if the argument C<virtual> is provided as an argument.

This will call L</lookup_file> or L</lookup_uri> depending on whether it is dealing with a file or an uri.

It returns a L<Apache2::SSI::URI> object which is stringifyable and contain the file path.

=head2 finfo

Returns a L<Apache2::SSI::Finfo> object. This provides access to L<perlfunc/stat> information as method, taking advantage of L<APR::Finfo> when running under Apache, and L<File::stat>-like interface otherwise. See L<Apache2::SSI::Finfo> for more information.

=head2 html

Sets or gets the html data to be processed.

=head2 lookup_file

Provided with a file path and this will look up the file.

When using Apache, this will call L<Apache2::SubRequest/lookup_file>. Outside of Apache, this will mimick Apache's lookup_file method by searching the file relative to the directory of the current document being served, i.e. the L</document_uri>.

As per Apache SSI documentation, you cannot specify a path starting with C</> or C<../>

It returns a L<Apache2::SSI::File> object.

=head2 lookup_uri

Provided with an uri, and this will loo it up and return a L<Apache2::SSI::URI> object.

Under Apache mod_perl, this uses L<Apache2::SubRequest/lookup_uri> to achieve that. Outside of Apache it will attempt to lookup the uri relative to the document root if it is an absolute uri or to the current document uri.

It returns a L<Apache2::SSI::URI> object.

=head2 mod_perl

Returns true when running under mod_perl, false otherwise.

=head2 parse

Provided with html data and if none is provided will use the data specified with the method L</html>, this method will parse the html and process the ssi directives.

It returns the html string with the ssi result.

=head2 parse_config

Provided with an hash reference of parameters and this sets three of the object parameters that can also be set during object instantiation:

=over 4

=item I<echomsg>

The value is a message that is sent back to the client if the echo element attempts to echo an undefined variable.

This overrides any default value set for the parameter I<echomsg> upon object instantiation.

=item I<errmsg>

This is the default error message to be used as the result for a faulty ssi directive.

See the L</echomsg> method.

=item I<sizefmt>

This is the format to be used to format the files size. Value can be either C<bytes> or C<abbrev>

See also the L</sizefmt> method.

=item I<timefmt>

This is the format to be used to format the dates and times. The value is a date formatting based on L<POSIX/strftime>

See also the L</timefmt> method.

=back

=head2 parse_echo

Provided with an hash reference of parameter and this process the C<echo> ssi directive and returns its output as a string.

For example:

    Query string passed: <!--#echo var="QUERY_STRING" -->

There are a number of standard environment variable accessible under SSI on top of other environment variables set. See L<SSI Directives> section below.

=head2 parse_echo_date_gmt

Returns the current date with time zone set to gmt and based on the provided format or the format available for the current locale such as C<ja_JP> or C<en_GB>.

=head2 parse_echo_date_local

Returns the current date with time zone set to the local time zone whatever that may be and on the provided format or the format available for the current locale such as C<ja_JP> or C<en_GB>.

Example:

    <!--#echo var="DATE_LOCAL" -->

=head2 parse_echo_document_name

Returns the document name. Under Apache, this returns the environment variable C<DOCUMENT_NAME>, if set, or the base name of the value returned by L<Apache2::RequestRec/filename>

Outside of Apache, this returns the environment variable C<DOCUMENT_NAME>, if set, or the base name of the value for L</document_uri>

Example:

    <!--#echo var="DOCUMENT_NAME" -->

If the uri were C</some/where/file.html>, this would return only C<file.html>

=head2 parse_echo_document_uri

Returns the value of L</document_uri>

Example:

    <!--#echo var="DOCUMENT_URI" -->

The document uri would include, if any, any path info and query string.

=head2 parse_echo_last_modified

This returns document last modified date. Under Apache, there is a standard environment variable called C<LAST_MODIFIED> (see the section on L</SSI Directives>), and if somehow absent, it will return instead the formatted last modification datetime for the file returned with L<Apache2::RequestRec/filename>. The formatting of that date follows whatever format provided with L</timefmt> or by default the datetime format for the current locale (e.g. C<ja_JP>).

Outside of Apache, the similar result is achieved by returning the value of the environment variable C<LAST_MODIFIED> if available, or the formatted datetime of the document uri as set with L</document_uri>

Example:

    <!--#echo var="LAST_MODIFIED" -->

=head2 parse_eval_expr

Provided with a string representing an Apache2 expression and this will parse it, transform it into a perl equivalent and return its value.

It does the parsing using L<Apache2::Expression/parse> called from L</parse_expr>

If the expression contains regular expression with capture groups, the value of capture groups will be stored and will be usable in later expressions, such as:

    <!--#config errmsg="[Include error]" -->
    <!--#if expr="%{HTTP_COOKIE} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/"-->
        <!--#set var="CONTENT_LANGUAGE" value="%{tolower:$1}"-->
    <!--#elif expr="-z %{CONTENT_LANGUAGE}"-->
        <!--#set var="CONTENT_LANGUAGE" value="en"-->
    <!--#endif-->
    <!DOCTYPE html>
    <html lang="<!--#echo encoding="none" var="CONTENT_LANGUAGE" -->">

=head2 parse_exec

Provided with an hash reference of parameters and this process the C<exec> ssi directives.

Example:

    <!--#exec cgi="/uri/path/to/progr.cgi" -->

or

    <!--#exec cmd="/some/system/file/path.sh" -->

=head2 parse_expr

It takes a string representing an Apache2 expression and calls L<Apache2::Expression/parse> to break it down, and then calls L</ap2perl_expr> to transform it into a perl expression that is then eval'ed by L</parse_eval_expr>.

It returns the perl representation of the Apache2 expression.

To make this work, certain Apache2 standard functions used such as C<base64> or C<md5> are converted to use this package function equivalents. See the C<parse_func_*> methods for more information.

=head2 parse_elif

Parse the C<elif> condition.

Example:

    <!--#if expr=1 -->
     Hi, should print
    <!--#elif expr=1 -->
     Shouldn't print
    <!--#else -->
     Shouldn't print
    <!--#endif -->

=head2 parse_else

Parse the C<else> condition.

See L</parse_elif> above for example.

=head2 parse_endif

Parse the C<endif> condition.

See L</parse_elif> above for example.

=head2 parse_flastmod

Process the ssi directive C<flastmod>

Provided with an hash reference of parameters and this will return the formatted date time of the file last modification time.

=head2 parse_fsize

Provided with an hash reference of parameters and this will return the formatted file size.

The output is affected by the value of L</sizefmt>. If its value is C<bytes>, it will return the raw size in bytes, and if its value is C<abbrev>, it will return its value formated in kilo, mega or giga units.

Example

    <!--#config sizefmt="abbrev" -->
    This file size is <!--#fsize file="/some/filesystem/path/to/archive.tar.gz" -->

would return:

This file size is 12.7M

Or:

    <!--#config sizefmt="bytes" -->
    This file size is <!--#fsize virtual="/some/filesystem/path/to/archive.tar.gz" -->

would return:

This file size is 13,316,917 bytes

The size value before formatting is a L<Module::Generic::Number> and the output is formatted using L<Number::Format> by calling L<Module::Generic::Number/format>

=head2 parse_func_base64

Returns the arguments provided into a base64 string.

If the arguments are utf8 data with perl internal flag on, as checked with L<Encode/is_utf8>, this will encode the data into utf8 with L<Encode/encode> before encoding it into base64.

Example:

    <!--#set var="payload" value='{"sub":"1234567890","name":"John Doe","iat":1609047546}' encoding="base64" -->
    <!--#if expr="$payload == 'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNjA5MDQ3NTQ2fQo='" -->
    Payload matches
    <!--#else -->
    Sorry, this failed
    <!--#endif -->

=head2 parse_func_env

Return first match of L<note>, L<reqenv>, and L<osenv>

Example:

    <!--#if expr="env( $QUERY_STRING ) == /\bl=ja_JP/" -->
    Showing Japanese data
    <!--#else -->
    Defaulting to English
    <!--#endif -->

=head2 parse_func_escape

Escape special characters in %hex encoding.

Example:

    <!--#set var="website" value="https://www.example.com/" -->
    Please go to <a href="<!--#echo var='website' encoding='escape' -->"><!--#echo var="website" --></a>

=head2 parse_func_http

Get HTTP request header; header names may be added to the Vary header.

Example:

    <!--#if expr="http('X-API-ID') == 1234567" -->
    You're good to go.
    <!--#endif -->

However, outside of an Apache environment this will return the value of the environment variable in the following order:

=over 4

=item X-API-ID (i.e. the name as-is)

=item HTTP_X_API_ID (i.e. adding C<HTTP_> and replace C<-> for C<_>)

=item X_API_ID (i.e. same as above, but without the C<HTTP_> prefix)

=back

If none is found, it returns an empty string.

For an equivalent function for response headers, see L</parse_func_resp>

=head2 parse_func_ldap

Escape characters as required by LDAP distinguished name escaping (RFC4514) and LDAP filter escaping (RFC4515).

See L<Apache documentation|https://httpd.apache.org/docs/trunk/en/expr.html#page-header> for more information

Example:

    <!--#set var="phrase" value="%{ldap:'Tous les êtres humains naissent libres (et égaux) en dignité et\ en\ droits.\n'}" -->
    # Tous les êtres humains naissent libres \28et égaux\29 en dignité et\5c en\5c droits.\5cn

=head2 parse_func_md5

Hash the string using MD5, then encode the hash with hexadecimal encoding.

If the arguments are utf8 data with perl internal flag on, as checked with L<Encode/is_utf8>, this will encode the data into utf8 with L<Encode/encode> before encoding it with md5.

Example:

    <!--#if expr="md5( $hash_data ) == '2f50e645b6ef04b5cfb76aed6de343eb'" -->
    You're good to go.
    <!--#endif -->

=head2 parse_func_note

Lookup request note

    <!--#set var="CUSTOMER_ID" value="1234567" -->
    <!--#if expr="note('CUSTOMER_ID') == 1234567" -->
    Showing special message
    <!--#endif -->

This uses L<Apache2::SSI::Notes> to enable notes to be shared on and off Apache2/mod_perl2 environment. Thus, you could set a note from a command-line perl script, and then access it under Apache2/mod_perl2 or just your regular script running under a web server.

For example:

In your perl script outside of Apache:

    # Basic parameters to make Apache2::SSI happy
    my $ssi = Apache2::SSI->new( document_root => '/home/john/www', document_uri => '/' ) ||
        die( Apache2::SSI->error );
    $ssi->notes( API_VERSION => 2 );

Then, in your perl script running under the web server, be it Apache2/mod_perl2 or not:

    my $ssi = Apache2::SSI->new || die( Apache2::SSI->error );
    my $api_version = $ssi->notes( 'API_VERSION' );

To enable shareability of notes on and off Apache, this makes uses of shared memory segments. See L<Apache2::SSI::Notes> for more information on the notes api and L<perlipc> for more information on shared memory segments.

Just keep in mind that the notes are B<never> removed even when Apache shuts down, so it is your responsibility to remove them if you do not want them anymore. For example:

    use Apache2::SSI::Notes;
    my $notes = Apache2::SSI::Notes->new;
    $notes->remove;

be aware that shared notes might note be available for your platform. Check L<Apache2::SSI::Notes> for more information and also L<perlport> on shared memory segments.

=head2 parse_func_osenv

Lookup operating system environment variable

    <!--#if expr="env('LANG') =~ /en(_(GB|US))/" -->
    Showing English language
    <!--#endif -->

=head2 parse_func_replace

replace(string, "from", "to") replaces all occurrences of "from" in the string with "to".

Example:

    <!--#if expr="replace( 'John is in Tokyo', 'John', 'Jack' ) == 'Jack is in Tokyo'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

=head2 parse_func_req

See L</parse_func_http>

=head2 parse_func_reqenv

Lookup request environment variable (as a shortcut, v can also be used to access variables).

This is only different from L</parse_func_env> under Apache.

See L</parse_func_env>

Example:

    <!--#if expr="reqenv('ProcessId') == '$$'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

Or using the Apache SSI C<v> shortcut:

    <!--#if expr="v('ProcessId') == '$$'" -->

=head2 parse_func_req_novary

Same as L</parse_func_req>, but header names will not be added to the Vary header.

=head2 parse_func_resp

Get HTTP response header.

Example:

    <!--#if expr="resp('X-ProcessId') == '$$'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

An important note here:

First, there is obviously no response header available for perl scripts running outside of Apache2/mod_perl2 framework.

If the script runs under mod_perl, not all response header will be available depending on whether you are using L<Apache2::SSI> in your Apache configuration as an output filter handler (C<PerlOutputFilterHandler>) or a response handler (C<PerlResponseHandler>).

If it is running as an output filter handler, then some headers, such as C<Content-Type> will not be available, unless they have been set by a script in a previous phase. Only basic headers will be available. For more information, check the Apache/mod_perl2 documentation on each phase.

=head2 parse_func_sha1

Hash the string using SHA1, then encode the hash with hexadecimal encoding.

Example:

    <!--#if expr="sha1('Tous les êtres humains naissent libres et égaux en dignité et en droits.') == '8c244078c64a51e8924ecf646df968094a818d59'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

=head2 parse_func_tolower

Convert string to lower case.

Example:

    <!--#if expr="tolower('Tous les êtres humains naissent libres et égaux en dignité et en droits.') == 'tous les êtres humains naissent libres et égaux en dignité et en droits.'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

=head2 parse_func_toupper

Convert string to upper case.

Example:

    <!--#if expr="toupper('Tous les êtres humains naissent libres et égaux en dignité et en droits.') == 'TOUS LES ÊTRES HUMAINS NAISSENT LIBRES ET ÉGAUX EN DIGNITÉ ET EN DROITS.'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

=head2 parse_func_unbase64

Decode base64 encoded string, return truncated string if 0x00 is found.

Example:

    <!--#if expr="unbase64('VG91cyBsZXMgw6p0cmVzIGh1bWFpbnMgbmFpc3NlbnQgbGlicmVzIGV0IMOpZ2F1eCBlbiBkaWduaXTDqSBldCBlbiBkcm9pdHMu') == 'Tous les êtres humains naissent libres et égaux en dignité et en droits.'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

=head2 parse_func_unescape

Unescape %hex encoded string, leaving encoded slashes alone; return empty string if %00 is found.

Example:

    <!--#if expr="unescape('https%3A%2F%2Fwww.example.com%2F') == 'https://www.example.com/'" -->
    This worked!
    <!--#else -->
    Nope, it failed.
    <!--#endif -->

=head2 parse_if

Parse the C<if> condition.

See L</parse_elif> above for example.

=head2 parse_include

Provided with an hash reference of parameters and this process the ssi directive C<include>, which is arguably the most used.

It will try to resolve the file to include by calling L</find_file> with the same arguments this is called with.

Under Apache, if the previous look up succeeded, it calls L<Apache2::SubRequest/run>

Outside of Apache, it reads the entire file, utf8 decode it and return it.

=head2 parse_perl

Provided with an hash reference of parameters and this parse some perl command and returns the output as a string.

Example:

    <!--#perl sub="sub{ print 'Hello!' }" -->

or

    <!--#perl sub="package::subroutine" -->

=head2 parse_printenv

This returns a list of environment variables sorted and their values.

=head2 parse_set

Provided with an hash reference of parameters and this process the ssi directive C<set>.

Possible parameters are:

=over 4

=item I<decoding>

The decoding of the variable before it is set. This can be C<none>, C<url>, C<urlencoded>, C<base64> or C<entity>

=item I<encoding>

This instruct to encode the variable value before display. It can the same possible value as for decoding.

=item I<value>

The string value for the variable to be set.

=item I<var>

The variable name

=back

Example:

    <!--#set var="debug" value="2" -->
    <!--#set decoding="entity" var="HUMAN_RIGHT" value="Tous les &Atilde;&ordf;tres humains naissent libres et &Atilde;&copy;gaux en dignit&Atilde;&copy; et en droits." encoding="urlencoded" -->

See the L<Apache SSI documentation|https://httpd.apache.org/docs/current/en/mod/mod_include.html> for more information.

=head2 parse_ssi

Provided with the html data as a string and this will parse its embedded ssi directives and return its output as a string.

If it fails, it sets an L</error> and returns an empty string.

=head2 path_info

Sets or gets the path info for the current uri.

Example:

    my $string = $ssi->path_info;
    $ssi->path_info( '/my/path/info' );

The path info value is also set automatically when L</document_uri> is called, such as:

    $ssi->document_uri( '/some/path/to/file.html/my/path/info?q=something&l=ja_JP' );

This will also set automatically the C<PATH_INFO> environment variable.

=head2 query_string

Set or gets the query string for the current uri.

Example:

    my $string = $ssi->query_string;
    $ssi->query_string( 'q=something&l=ja_JP' );

or, using the L<URI> module:

    $ssi->query_string( $uri->query );

The query string value is set automatically when you provide an L<document_uri> upon instantiation or after:

    $ssi->document_uri( '/some/path/to/file.html?q=something&l=ja_JP' );

This will also set automatically the C<QUERY_STRING> environment variable.

=head2 remote_ip

Sets or gets the remote ip address of the visitor.

Under Apache mod_perl, this will call L<Apache2::Connection/remote_ip> for version 2.2 or lower and will call L<Apache2::Connection/useragent_ip> for version above 2.2, and otherwise this will get the value from the environment variable C<REMOTE_ADDR>

This value can also be overriden by being provided during object instantiation.

    # Pretend the ssi directives are accessed from this ip
    $ssi->remote_ip( '192.168.2.20' );

This is useful when one wants to check how the rendering will be when accessed from certain ip addresses.

This is used primarily when there is an expression such as

    <!--#if expr="-R '192.168.1.0/24' -->
    Visitor is part of my private network
    <!--#endif -->

or

    <!--#if expr="v('REMOTE_ADDR') -R '192.168.1.0/24' -->
    <!--#include file="/home/john/special_hidden_login_feature.html" -->
    <!--#endif -->

L<Apache2::Connection> also has a L<Apache2::Connection/remote_addr> method, but this returns a L<APR::SockAddr> object that is used to get the binary version of the ip. However you can also get the string version like this:

    use APR::SockAddr ();
    my $ip = $r->connection->remote_addr->ip_get();

Versions above 2.2 make a distinction between ip from direct connection, or the real ip behind a proxy, i.e. L<Apache2::Connection/useragent_ip>

=head2 request_uri

This is an alias for L</document_uri>

=head2 server_version

Returns the server version as a L<version> object can caches that value.

Under mod_perl2, it uses L<Apache2::ServerUtil/get_server_description> and outside of mod_perl, it tries to find C<apxs> using L<File::Which> and in last resort, tries to find the C<apache2> or C<httpd> binary to get its version information.

=head2 sizefmt

Sets or gets the formatting for file sizes. Value can be either C<bytes> or C<abbrev>

=head2 timefmt

Sets or gets the formatting for date and time values. The format takes the same values as L<POSIX/strftime>

=head1 Encoding

At present time, the html data are treated as utf8 data and decoded and encoded back as such.

If there is a need to broaden support for other charsets, let me know.

=head1 SSI Directives

This is taken from Apache documentation and summarised here for convenience and clarity to the perl community.

=head2 config

    <!--#config errmsg="Error occurred" sizefmt="abbrev" timefmt="%B %Y" -->
    <!--#config errmsg="Oopsie" -->
    <!--#config sizefmt="bytes" -->
    # Thursday 24 December 2020
    <!--#config timefmt="%A $d %B %Y" -->

=head2 echo

     <!--#set var="HTMl_TITLE" value="Un sujet intéressant" -->
     <!--#echo var="HTMl_TITLE" encoding="entity" -->

Encoding can be either C<entity>, C<url> or C<none>

=head2 exec

    # pwd is "print working directory" in shell
    <!--#exec cmd="pwd" -->
    <!--#exec cgi="/uri/path/to/prog.cgi" -->

=head2 include

    # Filesystem file path
    <!--#include file="/home/john/var/quote_of_the_day.txt" -->
    # Relative to the document root
    <!--#include virtual="/footer.html" -->

=head2 flastmod

     <!--#flastmod file="/home/john/var/quote_of_the_day.txt" -->
     <!--#flastmod virtual="/copyright.html" -->

=head2 fsize

    <!--#fsize file="/download/software-v1.2.tgz" -->
    <!--#fsize virtual="/images/logo.jpg" -->

=head2 printenv

    <!--#printenv -->

=head2 set

    <!--#set var="debug" value="2" -->

=head2 if, elif, endif and else

    <!--#if expr="$debug > 1" -->
    I will print a lot of debugging
    <!--#else -->
    Debugging output will be reasonable
    <!--#endif -->

or with new version of Apache SSI:

    No such file or directory.
    <!--#if expr="v('HTTP_REFERER') != ''" -->
    Please let the admin of the <a href="<!--#echo encoding="url" var="HTTP_REFERER" -->"referring site</a> know about their dead link.
    <!--#endif -->

=head2 functions

Apache SSI supports the following functions, as of Apache version 2.4.

See L<Apache documentation|https://httpd.apache.org/docs/current/en/expr.html#page-header> for detailed description of what they do.

You can also refer to the methods C<parse_func_*> documented above, which implement those Apache functions.

=over 4

=item I<base64>

=item I<env>

=item I<escape>

=item I<http>

=item I<ldap>

=item I<md5>

=item I<note>

=item I<osenv>

=item I<replace>

=item I<req>

=item I<reqenv>

=item I<req_novary>

=item I<resp>

=item I<sha1>

=item I<tolower>

=item I<toupper>

=item I<unbase64>

=item I<unescape>

=back

=head2 variables

On top of all environment variables available, Apache makes the following ones also accessible:

=over 4

=item DATE_GMT

=item DATE_LOCAL

=item DOCUMENT_ARGS

=item DOCUMENT_NAME

=item DOCUMENT_PATH_INFO

=item DOCUMENT_URI

=item LAST_MODIFIED

=item QUERY_STRING_UNESCAPED

=item USER_NAME

=back

See L<Apache documentation|https://httpd.apache.org/docs/current/en/mod/mod_include.html#page-header> and L<this page too|https://httpd.apache.org/docs/current/en/expr.html#page-header> for more information.

=head2 expressions

There is reasonable, but limited support for Apache expressions. For example, the followings are supported

In the examples below, we use the variable C<QUERY_STRING>, but you can use any other variable of course.

The regular expression are the ones L<PCRE|http://www.pcre.org/> compliant, so your perl regular expressions should work.

    <!--#if expr="$QUERY_STRING = 'something'" -->
    <!--#if expr="v('QUERY_STRING') = 'something'" -->
    <!--#if expr="%{QUERY_STRING} = 'something'" -->
    <!--#if expr="$QUERY_STRING = /^something/" -->
    <!--#if expr="$QUERY_STRING == /^something/" -->
    # works also with eq, ne, lt, le, gt and ge
    <!--#if expr="9 gt 3" -->
    <!--#if expr="9 -gt 3" -->
    # Other operators work too, namely == != < <= > >= =~ !~
    <!--#if expr="9 > 3" -->
    <!--#if expr="9 !> 3" -->
    <!--#if expr="9 !gt 3" -->
    # Checks the remote ip is part of this subnet
    <!--#if expr="-R 192.168.2.0/24" -->
    <!--#if expr="192.168.2.10 -R 192.168.2.0/24" -->
    <!--#if expr="192.168.2.10 -ipmatch 192.168.2.0/24" -->
    # Checks if variable is non-empty
    <!--#if expr="-n $some_variable" -->
    # Checks if variable is empty
    <!--#if expr="-z $some_variable" -->
    # Checks if the visitor can access the uri /restricted/uri
    <!--#if expr="-A /restricted/uri" -->

For subnet checks, this uses L<Net::Subnet>

Expressions that would not work outside of Apache, i.e. it will return an empty string:

    <!--#expr="%{HTTP:X-example-header} in { 'foo', 'bar', 'baz' }" -->

See L<Apache documentation|http://httpd.apache.org/docs/2.4/en/expr.html> for more information.

=head1 CREDITS

Credits to Ken Williams for his implementation of L<Apache::SSI> from which I borrowed some code.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

Lhttps://gitlab.com/jackdeguest/Apache2-SSI>

=head1 SEE ALSO

L<Apache2::SSI::File>, L<Apache2::SSI::Finfo>, L<Apache2::SSI::Notes>, L<Apache2::SSI::URI>, L<Apache2::SSI::SharedMem> and L<Apache2::SSI::SemStat>

mod_include, mod_perl(3), L<Apache::SSI>, 
L<https://httpd.apache.org/docs/current/en/mod/mod_include.html>,
L<https://httpd.apache.org/docs/current/en/howto/ssi.html>,
L<https://httpd.apache.org/docs/current/en/expr.html>
L<https://perl.apache.org/docs/2.0/user/handlers/filters.html#C_PerlOutputFilterHandler_>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
