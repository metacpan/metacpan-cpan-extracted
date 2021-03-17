##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/Expression.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/02/20
## Modified 2021/02/20
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::Expression;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use Regexp::Common qw( Apache2 );
    use PPI;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{legacy} = 0;
    $self->{trunk}  = 0;
    $self->SUPER::init( @_ );
    return( $self );
}

sub legacy { return( shift->_set_get_boolean( 'legacy', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( '' ) if( !length( $data ) );
    my $opts = {};
    if( @_ )
    {
        $opts = ref( $_[0] ) eq 'HASH'
            ? shift( @_ )
            : !( @_ % 2 )
                ? { @_ }
                : {};
    }
    pos( $data ) = 0;
    my $prefix = $self->legacy ? 'Legacy' : $self->trunk ? 'Trunk' : '';
    $self->message( 3, "Using prefix '$prefix'." );
    my @callinfo = caller(0);
    $opts->{top} = 0;
    $opts->{top} = 1 if( $callinfo[0] ne ref( $self ) || ( $callinfo[0] eq ref( $self ) && substr( (caller(1))[3], rindex( (caller(1))[3], ':' ) + 1 ) ne 'parse' ) );
    $self->message( 3, "Parsing expression '$data'. Called from file $callinfo[1] at line $callinfo[2] and from sub ", (caller(1))[3], ". top is set to '$opts->{top}'" );
    ## This is used to avoid looping when an expression drills down its substring by calling parse again
    my $skip = {};
    if( ref( $opts->{skip} ) eq 'ARRAY' &&
        scalar( @{$opts->{skip}} ) )
    {
        @$skip{ @{$opts->{skip}} } = ( 1 ) x scalar( @{$opts->{skip}} )
    }
    $self->message( 3, "Skip contains: ", sub{ $self->dump( $skip ) });
    my $p = {};
    $p->{is_negative} = 0;
    my $elems = [];
    my $hash =
    {
    raw => $data,
    elements => $elems,
    };
    my $looping = 0;
    PARSE:
    {
        my $pos = pos( $data );
        $self->message( 3, "Nothing more to parse at pos '$pos'. End of data." ), last PARSE if( pos( $data ) == length( $data ) );
        $self->message( 3, "Parsing ", length( $data ), " bytes of data starting at '$pos' in string '$data'" );
        if( $data =~ m/\G\r?\n$/ )
        {
            $self->message( 3, "End of string new line detected, skipping." );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with legacy variable." ) && 
               $data =~ /\A\G$RE{Apache2}{LegacyVariable}\Z/gmcs && 
               length( $+{variable} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in legacy variable." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "variable => capture groups for $+{variable} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements => [],
            type => 'variable',
            raw => $re->{variable},
            re => $re,
            };
            if( length( $re->{var_func_name} ) )
            {
                $def->{subtype} = 'function';
                $def->{name}    = $re->{var_func_name};
                $def->{args}    = $re->{var_func_args};
                if( length( $def->{args} ) )
                {
                    my @argv = $self->parse_args( $def->{args} );
                    $def->{args_def} = [];
                    foreach my $this ( @argv )
                    {
                        my $this = $self->parse( $this );
                        push( @{$def->{elements}}, @{$this->{elements}} );
                        push( @{$def->{args_def}}, @{$this->{elements}} );
                    }
                }
            }
            elsif( length( $re->{varname} ) )
            {
                $def->{subtype} = 'variable';
                $def->{name}    = $re->{varname};
            }
            elsif( length( $re->{rebackref} ) )
            {
                $def->{subtype} = 'rebackref';
                $def->{value} = $re->{rebackref};
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( !$skip->{cond} && 
               $self->message( 3, "Trying with condition." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Cond"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Cond"}/gmcs ) &&
               length( $+{cond} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in condition." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "condition => capture groups for '$+{cond}' in data '$data' are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements => [],
            type => 'cond',
            raw => $re->{cond},
            re => $re,
            };
            $def->{is_negative} = 1 if( $re->{cond_neg} );
            $p->{is_negative} = 1 if( $re->{cond_neg} && $opts->{top} );
            if( length( $re->{cond_variable} ) )
            {
                $def->{subtype} = 'variable';
                $def->{variable_def} = [];
                ## Avoid looping
                unless( $re->{cond_variable} eq $data )
                {
                    my $this = $self->parse( $re->{cond_variable} );
                    $def->{elements} = $this->{elements};
                    $def->{variable_def} = $this->{elements};
                }
            }
            elsif( length( $re->{cond_parenthesis} ) )
            {
                $def->{subtype} = 'parenthesis';
                $def->{parenthesis_def} = [];
                unless( $re->{cond_parenthesis} eq $data )
                {
                    my $this = $self->parse( $re->{cond_parenthesis} );
                    $def->{elements} = $this->{elements};
                    $def->{parenthesis_def} = $this->{elements};
                }
            }
            elsif( length( $re->{cond_neg} ) )
            {
                $def->{subtype} = 'negative';
                $def->{negative_def} = [];
                if( length( $re->{cond_expr} ) )
                {
                    my $this = $self->parse( $re->{cond_expr} );
                    $def->{elements} = $this->{elements};
                    $def->{negative_def} = $this->{elements};
                }
            }
            elsif( length( $re->{cond_and} ) || length( $re->{cond_or} ) )
            {
                $def->{subtype} = length( $re->{cond_and} ) ? 'and' : 'or';
                $def->{ $def->{subtype} . '_def' } = [];
                $def->{expr1}   = length( $re->{cond_and_expr1} ) ? $re->{cond_and_expr1} : $re->{cond_or_expr1};
                $def->{expr2}   = length( $re->{cond_and_expr2} ) ? $re->{cond_and_expr2} : $re->{cond_or_expr2};
                my $this1 = $self->parse( $def->{expr1} );
                my $this2 = $self->parse( $def->{expr2} );
                $def->{elements} = [ @{$this1->{elements}}, @{$this2->{elements}} ];
                $def->{ $def->{subtype} . '_def' }       = [ @{$this1->{elements}}, @{$this2->{elements}} ];
                $def->{ $def->{subtype} . '_def_expr1' } = [ @{$this1->{elements}} ];
                $def->{ $def->{subtype} . '_def_expr2' } = [ @{$this2->{elements}} ];
            }
            elsif( length( $re->{cond_comp} ) )
            {
                $def->{subtype} = 'comp';
                $def->{comp_def} = [];
                my $chunk = $re->{cond_comp};
                my $this = $self->parse( $chunk, skip => [qw( cond )] );
                $def->{elements} = $this->{elements};
                $def->{comp_def} = $this->{elements};
            }
            ## e.g. when the condition is just true or false
            elsif( length( $re->{cond_true} ) || length( $re->{cond_false} ) )
            {
                $def->{subtype} = 'boolean';
                $def->{boolval} = length( $re->{cond_true} ) ? 1 : 0;
                $def->{booltype} = length( $re->{cond_true} ) ? 'true' : 'false';
                $def->{value} = length( $re->{cond_true} ) ? $re->{cond_true} : $re->{cond_false};
            }
            else
            {
                $def->{subtype} = 'cond';
            }
            my $chunk = $re->{cond};
            push( @$elems, $def ) if( length( $re->{cond} ) );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with string comparison." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}StringComp"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}StringComp"}/gmcs ) && 
               length( $+{stringcomp} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in string comp." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "stringcomp => capture groups for $+{stringcomp} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'stringcomp',
            raw         => $re->{stringcomp},
            re          => $re,
            op          => $re->{stringcomp_op},
            worda       => $re->{stringcomp_worda},
            wordb       => $re->{stringcomp_wordb},
            };
            $def->{worda_def} = [];
            $def->{wordb_def} = [];
            if( length( $def->{worda} ) )
            {
                my $this = $self->parse( $def->{worda} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{worda_def} = $this->{elements};
            }
            if( length( $def->{wordb} ) )
            {
                my $this = $self->parse( $def->{wordb} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{wordb_def} = $this->{elements};
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with integer comparison." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}IntegerComp"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}IntegerComp"}/gmcs ) && 
               length( $+{integercomp} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in integer comp." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "integercomp => capture groups for $+{integercomp} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'integercomp',
            raw         => $re->{integercomp},
            re          => $re,
            op          => $re->{integercomp_op},
            worda       => $re->{integercomp_worda},
            wordb       => $re->{integercomp_wordb},
            };
            if( length( $re->{integercomp_worda} ) )
            {
                my $this = $self->parse( $re->{integercomp_worda} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{worda_def} = $this->{elements};
            }
            if( length( $re->{integercomp_wordb} ) )
            {
                my $this = $self->parse( $re->{integercomp_wordb} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{wordb_def} = $this->{elements};
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with general comparison." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Comp"}\Z/gms ) || 
                 ( $pos > 0 && $data =~ /\G$RE{Apache2}{"${prefix}Comp"}/gmcs ) ) && 
               length( $+{comp} ) )
        {

#         elsif( $self->message( 3, "Trying with general comparison." ) && 
#                ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Comp"}\Z/gms ) && 
#                length( $+{comp} ) )

#         elsif( $self->message( 3, "Trying with general comparison." ) && 
#                ( $data =~ /\G$RE{Apache2}{"${prefix}Comp"}/gmcs ) && 
#                length( $+{comp} ) )
#         {
            my $re = { %+ };
            my $cur_pos = pos( $data );
            $self->message( 3, "Got here in comp." );
            $self->whereami( \$data, $cur_pos );
            $self->message( 3, "comparison => capture groups for $+{comp} are: ", sub{ $self->dump( $re ) });
            ## next PARSE unless( length( $re->{comp} ) );
            my $def =
            {
            elements => [],
            type => 'comp',
            raw => $re->{comp},
            re => $re,
            };
            my $this;
            my $chunk = $re->{comp};
            if( length( $re->{comp_unary} ) )
            {
                $self->message( 3, "Found unary operation." );
                $def->{subtype} = 'unary';
                $def->{op} = $re->{comp_unaryop};
                $def->{word} = $re->{comp_word};
                $def->{word_def} = [];
                if( length( $def->{word} ) )
                {
                    my $this = $self->parse( $def->{word} );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    $def->{word_def} = $this->{elements};
                }
            }
            elsif( length( $re->{comp_binary} ) )
            {
                $self->message( 3, "Found binary operation." );
                $def->{subtype} = 'binary';
                $def->{op}      = $re->{comp_binaryop};
                $def->{is_negative} = ( defined( $re->{comp_binary_is_neg} ) ? length( $re->{comp_binary_is_neg} ) > 0 ? 1 : 0 : 0 );
                $def->{worda} = $re->{comp_worda};
                $def->{wordb} = $re->{comp_wordb};
                $def->{worda_def} = [];
                $def->{wordb_def} = [];
                if( length( $def->{worda} ) )
                {
                    my $this = $self->parse( $def->{worda} );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    $def->{worda_def} = $this->{elements};
                }
                if( length( $def->{wordb} ) )
                {
                    my $this = $self->parse( $def->{wordb} );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    $def->{wordb_def} = $this->{elements};
                }
            }
            elsif( length( $re->{comp_word_in_listfunc} ) )
            {
                $self->message( 3, "Found function." );
                $def->{subtype} = 'function';
                $def->{word}    = $re->{comp_word};
                $def->{function}    = $re->{comp_listfunc};
                $def->{word_def}    = [];
                $def->{function_def} = [];
                if( length( $def->{word} ) )
                {
                    my $this1 = $self->parse( $def->{word} );
                    push( @{$def->{elements}}, @{$this1->{elements}} );
                    $def->{word_def} = $this1->{elements};
                }
                my $this2 = $self->parse( $def->{function} );
                push( @{$def->{elements}}, @{$this2->{elements}} );
                $def->{function_def} = $this2->{elements};
            }
            elsif( length( $re->{comp_in_regexp} ) || length( $re->{comp_in_regexp_legacy} ) )
            {
                $self->message( 3, "Found regular expression." );
                $def->{subtype} = 'regexp';
                $def->{word}    = $re->{comp_word};
                $def->{op}      = $re->{comp_regexp_op};
                $def->{regexp}  = $re->{comp_regexp};
                $def->{word_def}    = [];
                $def->{regexp_def}  = [];
                my $str = $def->{word} . '';
                ## Break down the word being compared as well as the regular expression
                if( length( $str ) )
                {
                    my $this1 = $self->parse( $str );
                    $def->{elements} = [@{$this1->{elements}}];
                    $def->{word_def} = $this1->{elements};
                }
                if( length( $def->{regexp} ) )
                {
                    my $this2 = $self->parse( $def->{regexp} );
                    push( @{$def->{elements}}, @{$this2->{elements}} );
                    $def->{regexp_def} = $this2->{elements};
                }
            }
            elsif( length( $re->{comp_word_in_list} ) )
            {
                $self->message( 3, "Found comparison to list." );
                $def->{subtype} = 'list';
                $def->{word}    = $re->{comp_word};
                $def->{list}    = $re->{com_list};
                $def->{word_def}    = [];
                $def->{list_def}    = [];
                if( length( $def->{word} ) )
                {
                    my $this1 = $self->parse( $def->{word} );
                    push( @{$def->{elements}}, @{$this1->{elements}} );
                    $def->{word_def} = $this1->{elements};
                }
                if( length( $def->{list} ) )
                {
                    my @argv = $self->parse_args( $def->{list} );
                    foreach my $this ( @argv )
                    {
                        my $this = $self->parse( $this );
                        push( @{$def->{elements}}, @{$this->{elements}} );
                        push( @{$def->{list_def}}, @{$this->{elements}} );
                    }
                }
            }
            else
            {
                $self->message( 3, "No match found in comparison." );
            }
            if( defined( $this ) && scalar( keys( %$this ) ) )
            {
                $def->{elements} = $this->{elements};
            }
            push( @$elems, $def ) if( length( $re->{comp} ) );
            $cur_pos == length( $data ) && $self->message( 3, "End of string (", length( $data ), " bytes long) reached at pos ", $cur_pos ) && last PARSE;
            # redo PARSE unless( !length( $re->{comp} ) && ++$looping > 1 );
            redo PARSE;
        }
        ## Trunk function
        elsif( $self->message( 3, "Trying with trunk join." ) && 
               $prefix eq 'Trunk' &&
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Join"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Join"}/gmcs ) && 
               length( $+{join} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in join for string '$data'." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "join => capture groups for $+{join} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'join',
            raw         => $re->{join},
            re          => $re,
            word        => $re->{join_word},
            list        => $re->{join_list},
            };
            ## word is optional
            if( length( $def->{word} ) )
            {
                my $this = $self->parse( $def->{word} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{word_def} = $this->{elements};
            }
            if( length( $def->{list} ) )
            {
                my @argv = $self->parse_args( $def->{list} );
                $def->{list_def} = [];
                foreach my $that ( @argv )
                {
                    my $this = $self->parse( $that );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    push( @{$def->{list_def}}, @{$this->{elements}} );
                }
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with trunk split." ) && 
               $prefix eq 'Trunk' &&
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Split"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Split"}/gmcs ) && 
               length( $+{split} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in split for string '$data'." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "split => capture groups for $+{split} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'split',
            raw         => $re->{split},
            re          => $re,
            regex       => $re->{split_regex},
            word        => $re->{split_word},
            list        => $re->{split_list},
            };
            ## It is either a word or a list as parameter
            if( length( $def->{word} ) )
            {
                my $this = $self->parse( $def->{word} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{word_def} = $this->{elements};
            }
            if( length( $def->{list} ) )
            {
                my @argv = $self->parse_args( $def->{list} );
                $def->{list_def} = [];
                foreach my $that ( @argv )
                {
                    my $this = $self->parse( $that );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    push( @{$def->{list_def}}, @{$this->{elements}} );
                }
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with legacy variable." ) && 
               $prefix eq 'Trunk' &&
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Sub"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Sub"}/gmcs ) && 
               length( $+{sub} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in sub for string '$data'." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "sub => capture groups for $+{split} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'sub',
            raw         => $re->{sub},
            re          => $re,
            regsub      => $re->{sub_regsub},
            word        => $re->{sub_word},
            };
            if( length( $def->{word} ) )
            {
                my $this = $self->parse( $def->{word} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{word_def} = $this->{elements};
            }
            if( length( $def->{regsub} ) )
            {
                my $this = $self->parse( $def->{regsub} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{regsub_def} = $this->{elements};
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with function." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Function"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Function"}/gmcs ) && 
               length( $+{function} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in function for string '$data'." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "function => capture groups for $+{function} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'function',
            raw         => $re->{function},
            re          => $re,
            name        => $re->{func_name},
            args        => $re->{func_args},
            };
            if( length( $def->{args} ) )
            {
                my @argv = $self->parse_args( $def->{args} );
                $def->{args_def} = [];
                foreach my $this ( @argv )
                {
                    my $this = $self->parse( $this );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    push( @{$def->{args_def}}, @{$this->{elements}} );
                }
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with list function." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}ListFunc"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}ListFunc"}/gmcs ) && 
               length( $+{listfunc} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in listfunc." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "listfunc => capture groups for $+{listfunc} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements => [],
            type => 'listfunc',
            raw => $re->{listfunc},
            re => $re,
            name => $re->{func_name},
            args => $re->{func_args},
            };
            if( length( $def->{args} ) )
            {
                my @argv = $self->parse_args( $def->{args} );
                $def->{args_def} = [];
                foreach my $this ( @argv )
                {
                    my $this = $self->parse( $this );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    push( @{$def->{args_def}}, @{$this->{elements}} );
                }
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with regex." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Regexp"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Regexp"}/gmcs ) && 
               length( $+{regex} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in regex." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "regex => capture groups for $+{regex} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'regex',
            raw         => $re->{regex},
            re          => $re,
            pattern     => $re->{regpattern},
            flags       => $re->{regflags},
            sep         => $re->{regsep},
            };
            push( @$elems, $def );
            redo PARSE;
        }
        ## Trunk only
        elsif( $self->message( 3, "Trying with regex any." ) && 
               $prefix eq 'Trunk' &&
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Regany"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Regany"}/gmcs ) && 
               length( $+{regany} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in regany." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "regany => capture groups for $+{regany} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'regany',
            raw         => $re->{regany},
            re          => $re,
            regex       => $re->{regany_regex},
            regsub      => $re->{regany_regsub},
            };
            push( @$elems, $def );
            redo PARSE;
        }
        ## Trunk only
        elsif( $self->message( 3, "Trying with regsub." ) && 
               $prefix eq 'Trunk' &&
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Regsub"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Regsub"}/gmcs ) && 
               length( $+{regsub} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in regsub." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "regsub => capture groups for $+{regsub} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements    => [],
            type        => 'regsub',
            raw         => $re->{regsub},
            re          => $re,
            pattern     => $re->{regpattern},
            replacement => $re->{regstring},
            flags       => $re->{regflags},
            sep         => $re->{regsep},
            };
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( !$skip->{words} &&
               $self->message( 3, "Trying with words." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Words"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}Words"}/gmcs ) &&
               length( $+{words} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in words." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "words => capture groups for $+{words} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements => [],
            type => 'words',
            raw => $re->{words},
            re => $re,
            word => $re->{words_word},
            };
            if( length( $re->{words_list} ) )
            {
                $def->{list} = $re->{words_list};
                $def->{sublist} = $re->{words_sublist};
                my $this2 = $self->parse( $def->{list}, skip => [qw( words )] );
                $def->{elements} = $this2->{elements};
                $def->{list_def} = $this2->{elements};
                $def->{words_def} = [];
                $self->message( "Found list word '$def->{word}' with sublist '$def->{sublist}'" );
                my $this = $self->parse( $def->{word}, skip => [qw( words )] );
                push( @{$def->{words_def}}, @{$this->{elements}} );
                
                my $tmp = $def->{sublist};
                while( $tmp =~ s/^$RE{Apache2}{"${prefix}Words"}$//gs )
                {
                    my $re2 = { %+ };
                    $re2->{words_word} = '' if( !exists( $re2->{words_word} ) );
                    $re2->{words_sublist} = '' if( !exists( $re2->{words_sublist} ) );
                    $self->message( "Found list word '$re2->{words_word}' with sublist '$re2->{words_sublist}" );
                    my $this = $self->parse( $re2->{words_word}, skip => [qw( words )] );
                    push( @{$def->{words_def}}, @{$this->{elements}} );
                    $tmp = $re2->{words_sublist} if( $re2->{words_sublist} );
                }
            }
            else
            {
                my $this = $self->parse( $def->{word}, skip => [qw( words )] );
                $def->{word_def} = $this->{elements};
                push( @{$def->{elements}}, @{$this->{elements}} );
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with word." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}Word"}\Z/gms ) || 
                 ( $pos > 0 && $data =~ /\G$RE{Apache2}{"${prefix}Word"}/gmcs ) 
               ) &&
               length( $+{word} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in word." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "word => capture groups for '$+{word}' are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements => [],
            type => 'word',
            raw => $re->{word},
            re => $re,
            };
            if( length( $re->{word_digits} ) )
            {
                ## We keep whatever quote was used
                $def->{subtype} = 'digits';
                $def->{value} = $re->{word_digits};
            }
            elsif( length( $re->{word_ip} ) )
            {
                $def->{subtype} = 'ip';
                $def->{ip_version} = length( $re->{word_ip4} ) ? 4 : 6;
                $def->{value} = length( $re->{word_ip4} ) ? $re->{word_ip4} : $re->{word_ip6};
            }
            elsif( length( $re->{word_quote} ) || length( $re->{word_parens_open} ) )
            {
                $def->{word} = $re->{word_enclosed};
                if( length( $re->{word_quote} ) )
                {
                    $def->{subtype} = 'quote';
                    $def->{quote} = $re->{word_quote};
                }
                elsif( length( $re->{word_parens_open} ) )
                {
                    $def->{subtype} = 'parens';
                    ## If the enclosing elements are parenthesis
                    $def->{parens} = [$re->{word_parens_open}, $re->{word_parens_close}];
                    my $this = $self->parse( $def->{word} );
                    push( @{$def->{elements}}, @{$this->{elements}} );
                    $def->{word_def} = $this->{elements};
                }
                # XXX Should probably make a run on the enclosed word as it could be a variable
                # For example: "Go back to %{REQUEST_URI}"
            }
            elsif( length( $re->{word_function} ) || length( $re->{word_variable} ) )
            {
                my $chunk = ( $re->{word_function} || $re->{word_variable} );
                my $this = length( $chunk ) ? $self->parse( $chunk ) : {};
                $def->{subtype} = length( $re->{word_function} ) ? 'function' : length( $re->{word_variable} ) ? 'variable' : undef();
                if( defined( $this ) && scalar( keys( %$this ) ) )
                {
                    $def->{elements} = $this->{elements};
                    if( $def->{subtype} eq 'function' )
                    {
                        $def->{function_def} = $this->{elements};
                    }
                    elsif( $def->{subtype} eq 'variable' )
                    {
                        $def->{variable_def} = $this->{elements};
                    }
                }
            }
            elsif( length( $re->{word_join} ) )
            {
                $def->{subtype} = 'join';
                my $this = $self->parse( $re->{word_variable} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{join_def} = $this->{elements};
            }
            elsif( length( $re->{word_sub} ) )
            {
                $def->{subtype} = 'sub';
                my $this = $self->parse( $re->{word_variable} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{sub_def} = $this->{elements};
            }
            elsif( length( $re->{word_variable} ) )
            {
                $def->{subtype} = 'variable';
                my $this = $self->parse( $re->{word_variable} );
                push( @{$def->{elements}}, @{$this->{elements}} );
                $def->{variable_def} = $this->{elements};
            }
            elsif( length( $re->{word_dot_word} ) )
            {
                $def->{subtype} = 'dotted';
                $def->{word} = $re->{word_dot_word};
            }
            elsif( length( $re->{rebackref} ) )
            {
                $def->{subtype} = 'rebackref';
                $def->{value} = $re->{rebackref};
            }
            elsif( length( $re->{regex} ) )
            {
                $def->{subtype} = 'regex';
                $def->{sep} = $re->{regsep};
                $def->{pattern} = $re->{regpattern};
                $def->{flags} = $re->{regflags};
            }
            push( @$elems, $def );
            redo PARSE;
        }
        elsif( $self->message( 3, "Trying with string." ) && 
               ( ( $pos == 0 && $data =~ /\A$RE{Apache2}{"${prefix}String"}\Z/gms ) || $data =~ /\G$RE{Apache2}{"${prefix}String"}/gmcs ) &&
               length( $+{string} ) )
        {
            my $re = { %+ };
            $self->message( 3, "Got here in string." );
            $self->whereami( \$data, pos( $data ) );
            $self->message( 3, "string => capture groups for $+{string} are: ", sub{ $self->dump( $re ) });
            my $def =
            {
            elements => [],
            type => 'string',
            raw => $re->{string},
            re => $re,
            };
            push( @$elems, $def );
            redo PARSE;
        }
        else
        {
            $self->message( 3, "Do not know what to do with '$data'." );
        }
        $self->message( 3, "Nothing found." );
        $self->message( 3, "Looping detected now exiting parsing." ) && last PARSE if( ++$looping > 1 );
        ## We arrived here, which means we could not find anything suitable in our parser, instead of returning a result for part of the data parsed, we return the original string marking it as nomatch string.
        if( $opts->{top} )
        {
            @$elems =
            ({
            type => 'string',
            subtype => 'nomatch',
            raw => $data,
            pos => $pos,
            });
            $self->message( 3, "Failed to complete parsing, so returning original data as string: ", sub{ $self->dump( $elems ) } );
            last PARSE;
        }
    };
    $self->message( 3, "Returning hash: ", sub{ $self->dump( $hash ) } );
    return( scalar( @$elems ) ? $hash : {} );
}

sub parse_args
{
    my $self = shift( @_ );
    ## String
    my $args = shift( @_ );
    $self->message( 3, "Parsing arguments: '$args'." );
    my $doc = PPI::Document->new( \$args, readonly => 1 ) || 
        return( "Unable to parse: ", PPI::Document->errstr, "\n$args" );
    ## Nothing found as argument
    return( () ) if( !scalar( @{$doc->{children}} ) );
    return( $self->error( "Was expecting a statement, but got ", ($doc->elements)[0]->class ) ) if( ($doc->elements)[0]->class ne 'PPI::Statement' );
    $self->message( 3, "Arguments contains the following PPI structure: ", sub{ $self->dump( $doc->{children} ) });
    my $st = ($doc->elements)[0];
    my @children = $st->elements;
    my $op_skip = 
    {
    ',' => 1,
    };
    my $expect = 0;
    local $recur = sub
    {
        my @elems = @_;
        ## We need space, so we do not remove them
        ## For example, md5("some string") is not the same as md5, ("some string")
        my $argv = [];
        for( my $i = 0; $i < scalar( @elems ); $i++ )
        {
            my $e = $elems[$i];
            my @expr;
            ## Hopefully those below should cover all of our needs
            if( 
                $e->class eq 'PPI::Token::ArrayIndex' ||
                ## Including PPI::Token::Number::Float
                $e->isa( 'PPI::Token::Number' ) ||
                ## operators like ==, !=, =~
                ( $e->class eq 'PPI::Token::Operator' && !exists( $op_skip->{ $e->content } ) ) ||
                ## including, PPI::Token::Quote::Double, PPI::Token::Quote::Interpolate, PPI::Token::Quote::Literal and PPI::Token::Quote::Single
                ## Example q{foo bar}
                $e->isa( 'PPI::Token::Quote' ) ||
                $e->isa( 'PPI::Token::QuoteLike' ) ||
                ## Including PPI::Token::Regexp::Match, PPI::Token::Regexp::Substitute, PPI::Token::Regexp::Transliterate
                $e->isa( 'PPI::Token::Regexp' ) ||
                ## Including for example PPI::Token::Magic
                $e->isa( 'PPI::Token::Symbol' ) ||
                $e->class eq 'PPI::Token::Word'
            )
            {
                push( @$argv, [$e] );
            }
            elsif( $e->class eq 'PPI::Token::Operator' && $e->content eq ',' )
            {
                $self->message( 3, "Found a comma separating argument '", ( ( $i - 1 ) >= 0 ? $elems[$i-1]->content : '' ), "' and '", ( ( $i + 1 ) <= scalar( @elems ) ? $elems[$i+1]->content : '' ), "'." );
            }
            ## Either this is arguments for the previous function found, or this is expressions embedded within parenthesis
            # XXX Need to implement also PPI::Token::Structure, i.e. [], {}
            elsif( $e->class eq 'PPI::Structure::List' )
            {
                if( ref( $elems[$i - 1] ) && 
                    $elems[$i - 1]->class eq 'PPI::Token::Word' && 
                    $argv->[-1]->[0]->class eq 'PPI::Token::Word' )
                {
                    push( @{$argv->[-1]}, $e );
                }
                elsif( scalar($e->elements) && 
                       ref(($e->elements)[0]) && 
                       ( @expr = $self->_find_expression($e) ) &&
                       $expr[0]->class eq 'PPI::Statement::Expression' )
                {
                    my @list = $self->_trim( $expr[0]->elements );
                    my @new = $recur->( @list );
                    push( @$argv, [$e->start] );
                    push( @$argv, @new );
                    push( @$argv, [$e->finish] );
                }
            }
            ## else we are not interested
            else
            {
                $self->message( 3, "Clueless about what I should do with element of class '", $e->class, "' and value '", $e->content, "'." );
            }
        }
        return( @$argv );
    };
    my @objects = $recur->( @children );
    $self->message( 3, "Objects found: ", sub{ $self->dump( @objects ) } );
    ## Stringify result
    my @result = map( join( '', map( $_->content, @$_ ) ), @objects );
    return( @result );
}

sub trunk { return( shift->_set_get_boolean( 'trunk', @_ ) ); }

sub whereami
{
    my $self = shift( @_ );
    my( $ref, $pos ) = @_;
    ## How far back should we look?
    my $lookback = 10;
    $lookback = $pos if( $pos < $lookback );
    my $lookahead = 20;
    my $start = $pos - $lookback;
    my $first_line = substr( $$ref, $start, $lookback + $lookahead );
    $lookback += () = substr( $$ref, $start, $lookback ) =~ /\n/gs;
    $first_line =~ s/\n/\\n/gs;
    my $sec_line = ( '.' x $lookback ) . '^' . ( '.' x $lookahead );
    $self->message( 3, "Cusrsor is now here at position '$pos':\n$first_line\n$sec_line" );
}

## PPI object manipulation
sub _find_expression
{
    my $self = shift( @_ );
    my $e = shift( @_ );
    my @found = ();
    foreach my $this ( $e->elements )
    {
        push( @found, $e );
    }
    return( @found );
}

## PPI object manipulation
sub _trim
{
    my $self = shift( @_ );
    my @elems = @_;
    for( my $i = 0; $i < scalar( @elems ); $i++ )
    {
        if( $elems[$i]->class eq 'PPI::Token::Whitespace' )
        {
            splice( @elems, $i, 1 );
            $i--;
        }
    }
    return( @elems );
}

1;

__END__

=encoding utf-8

=pod

=head1 NAME

Apache2::Expression - Apache2 Expressions

=head1 SYNOPSIS

    use Apache2::Expression;
    my $exp = Apache2::Expression->new( legacy => 1 );
    my $hash = $exp->parse;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<Apache2::Expression> is used to parse Apache2 expression like the one found in SSI (Server Side Includes).

=head1 METHODS

=head2 parse

This method takes a string representing an Apache2 expression as argument, and returns an hash containing the details of the elements that make the expression.

It takes an optional hash of parameters, as follows :

=over 4

=item I<legacy>

When this is provided with a positive value, this will enable Apache2 legacy regular expression. See L<Regexp::Common::Apache2> for more information on what this means.

=item I<trunk>

When this is provided with a positive value, this will enable Apache2 experimental and advanced expressions. See L<Regexp::Common::Apache2> for more information on what this means.

=back

For example :

    $HTTP_COOKIE = /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/

would return :

    {
      elements => [
        {
          elements => [
            {
              elements => [
                {
                  elements => [],
                  name => "HTTP_COOKIE",
                  raw => "\$HTTP_COOKIE",
                  re => { variable => "\$HTTP_COOKIE", varname => "HTTP_COOKIE" },
                  subtype => "variable",
                  type => "variable",
                },
                {
                  elements => [],
                  flags => undef,
                  pattern => "lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?",
                  raw => "/lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
                  re => {
                    regex => "/lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
                    regpattern => "lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?",
                    regsep => "/",
                  },
                  sep => "/",
                  type => "regex",
                },
              ],
              op => "=",
              raw => "\$HTTP_COOKIE = /lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
              re => {
                comp => "\$HTTP_COOKIE = /lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
                comp_in_regexp_legacy => "\$HTTP_COOKIE = /lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
                comp_regexp => "/lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
                comp_regexp_op => "=",
                comp_word => "\$HTTP_COOKIE",
              },
              regexp => "/lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
              subtype => "regexp",
              type => "comp",
              word => "\$HTTP_COOKIE",
            },
          ],
          raw => "\$HTTP_COOKIE = /lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
          re => {
            cond => "\$HTTP_COOKIE = /lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
            cond_comp => "\$HTTP_COOKIE = /lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
          },
          subtype => "comp",
          type => "cond",
        },
      ],
      raw => "\$HTTP_COOKIE = /lang\\%22\\%3A\\%22([a-zA-Z]+\\-[a-zA-Z]+)\\%22\\%7D;?/",
    }

The properties returned in the hash are:

=over 4

=item I<elements>

An array reference of sub elements contained which provides granular definition.

Whatever the I<elements> array reference contains is defined in one of the types below.

=item I<name>

The name of the element. For example if this is a function, this would be the function name, or if this is a variable, this would be the variable name without it leading dollar or percent sign nor its possible surrounding accolades.

=item I<raw>

The raw string, or chunk of string that was processed.

=item I<re>

This contains the hash of capture groups as provided by L<Regexp::Common::Apache2>. It is made available to enable finer and granular control.

=item I<regexp>

=item I<subtype>

A sub type that provide more information about the type of expression processed.

This can be any of the I<type> mentioned below plus the following ones : binary (for comparison), list (for word to list comparison), negative, parenthesis, rebackref, regexp, unary (for comparison)

See below for possible combinations.

=item I<type>

The main type matching the Apache2 expression. This can be comp, cond, digits, function, integercomp, quote (for quoted words), regex, stringcomp, listfunc, variable, word

See below for possible combinations.

=item I<word>

If this is a word, this contains the word. In th example above, C<$HTTP_COOKIE> would be the word used in the regular expression comparison.

=back

=head2 parse_args

Given a string that represents typically a function arguments, this method will use L<PPI> to parse it and returns an array of parameters as string.

Parsing a function argument is non-trivial as it can contain function call within function call.

=head1 COMBINATIONS

=over 4

=item B<comp>

Type: comp

Possible sub types:

=over 8

=item I<binary>

When a binary operator is used, such as :

    ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

Example :

    192.168.2.10 -ipmatch 192.168.2/24

C<192.168.2.10> would be captured in property I<worda>, C<ipmatch> (without leading dash) would be captured in property I<op> and C<192.168.2/24> would be captured in property I<wordb>.

The array reference in property I<elements> will contain more information on I<worda> and I<wordb>

Also the details of elements for I<worda> can be accessed with property I<worda_def> as an array reference and likewise for I<wordb> with I<wordb_def>.

=item I<function>

This contains the function name and arguments when the lefthand side word is compared to a list function.

For example :

    192.168.1.10 in split( /\,/, $ip_list )

In this example, C<192.168.1.10> would be captured in I<word> and C<split( /\,/, $ip_list )> would be captured in I<function> with the array reference I<elements> containing more information about the word and the function.

Also the details of elements for I<word> can be accessed with property I<word_def> as an array reference and likewise for I<function> with I<function_def>.

=item I<list>

Is true when the comparison is of a word on the lefthand side to a list of words, such as :

    %{SOME_VALUE} in {"John", "Peter", "Paul"}

In this example, C<%{SOME_VALUE}> would be captured in property I<word> and C<"John", "Peter", "Paul"> (without enclosing accolades or possible spaces after and before them) would be captured in property I<list>

The array reference I<elements> will possibly contain more information on I<word> and each element in I<list>

Also the details of elements for I<word> can be accessed with property I<word_def> as an array reference and likewise for I<list> with I<list_def>.

=item I<regexp>

When the lefthand side word is being compared to a regular expression.

For example :

    %{HTTP_COOKIE} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/

In this example, C<%{HTTP_COOKIE}> would be captured in property I<word> and C</lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/> would be captured in property I<regexp> and C<=~> would be captured in property I<op>

Check the array reference in property I<elements> for more details about the I<word> and the regular expression in I<regexp>.

Also the details of elements for I<word> can be accessed with property I<word_def> as an array reference and likewise for I<regexp> with I<regexp_def>.

=item I<unary>

When the following operator is used against a word :

    -d, -e, -f, -s, -L, -h, -F, -U, -A, -n, -z, -T, -R

For example:

    -A /some/uri.html # (same as -U)
    -d /some/folder # file is a directory
    -e /some/folder/file.txt # file exists
    -f /some/folder/file.txt # file is a regular file
    -F /some/folder/file.txt # file is a regular file and is accessible to all (Apache2 does a sub query to check)
    -h /some/folder/link.txt # true if file is a symbolic link
    -n %{QUERY_STRING} # true if string is not empty (opposite of -z)
    -s /some/folder/file.txt # true if file is not empty
    -L /some/folder/link.txt # true if file is a symbolic link (same as -h)
    -R 192.168.1.1/24 # remote ip match this ip block; same as %{REMOTE_ADDR} -ipmatch 192.168.1.1/24
    -T %{HTTPS} # false if string is empty, "0", "off", "false", or "no" (case insensitive). True otherwise.
    -U /some/uri.html # check if the uri is accessible to all (Apache2 does a sub query to check)
    -z %{QUERY_STRING} # true if string is empty (opposite of -n)

In this example C<-e /some/folder/file.txt>, C<e> (without leading dash) would be captured in I<op> and C</some/folder/file.txt> would be captured in I<word>

Check the array reference in property I<elements> for more information about the word in I<word>

Also the details of elements for I<word> can be accessed with property I<word_def> as an array reference.

See here for more information: L<Regexp::Common::Apache2::comp>

=back

Available properties:

=over 8

=item I<op>

Contains the operator used. See L<Regexp::Common::Apache2::comp>, L<Regexp::Common::Apache2/stringcomp> and L<Regexp::Common::Apache2/integercomp>

This may be for unary operators :

    -d, -e, -f, -s, -L, -h, -F, -U, -A, -n, -z, -T, -R

For binary operators :

    ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

For integer comparison :

    -eq, -ne, -lt, -le, -gt, -ge

For string comparison :

    ==, !=, <, <=, >, >=

In all the possible operators above, I<op> contains the value, but without the leading dash, if any.

=item I<word>

The word being compared.

=item I<worda>

The first word being compared, and on the left of the operator. For example :

    12 -ne 10

=item I<wordb>

The second word, being compared to, and on the right of the operator.

=back

See L<Regexp::Common::Apache2/comp> for more information.

=item B<cond>

Type: cond

Possible sub types:

=over 8

=item I<and>

When the condition is an ANDed expression such as :

    $ap_true && $ap_false

In this case, C<$ap_true> would be captured in property I<expr1> and C<$ap_false> would be captured in property I<expr2>

Also the details of elements for the variable can be accessed with property I<and_def> as an array reference and I<and_expr1_def> and I<and_expr2_def>

=item I<comp>

Contains the expression when the condition is actually a comparison.

This will recurse and you can see more information in the array reference in the property I<elements>. For more information on what it will contain, check the B<comp> type.

=item I<cond>

Default sub type

=item I<negative>

When the condition is negative, ie prefixed by an exclamation mark.

For example :

    !-z /some/folder/file.txt

You need to check for the details in array reference contained in property I<elements>

Also the details of elements for the variable can be accessed with property I<negative_def> as an array reference.

=item I<or>

When the condition is an ORed expression such as :

    $ap_true || $ap_false

In this case, C<$ap_true> would be captured in property I<expr1> and C<$ap_false> would be captured in property I<expr2>

Also the details of elements for the variable can be accessed with property I<and_def> as an array reference and I<and_expr1_def> and I<and_expr2_def>

=item I<parenthesis>

When the condition is embedded within parenthesis

You need to check the array reference in property I<elements> for information about the embedded condition.

Also the details of elements for the variable can be accessed with property I<parenthesis_def> as an array reference.

=item I<variable>

Contains the expression when the condition is based on a variable, such as :

    %{REQUEST_URI}

Check the array reference in property I<elements> for more details about the variable, especially the property I<name> which would contain the name of the variable; in this case : C<REQUEST_URI>

Also the details of elements for the variable can be accessed with property I<variable_def> as an array reference.

=back

Available properties:

=over 8

=item I<args>

Function arguments. See the content of the I<elements> array reference for more breakdown on the arguments provided.

=item I<is_negative>

If the condition is negative, this value is true

=item I<name>

Function name

=back

See L<Regexp::Common::Apache2/cond> for more information.

=item B<function>

Type: function

Possible sub types: none

Available properties:

=over 8

=item I<args>

Function arguments. See the content of the I<elements> array reference for more breakdown on the arguments provided.

Also the details of elements for those args can be accessed with property I<args_def> as an array reference.

=item I<name>

Function name

=back

See L<Regexp::Common::Apache2/function> for more information.

=item B<integercomp>

Type: integercomp

Possible sub types: none

Available properties:

=over 8

=item I<op>

Contains the operator used. See L<Regexp::Common::Apache2/integercomp>

=item I<worda>

The first word being compared, and on the left of the operator. For example :

    12 -ne 10

Also the details of elements for I<worda> can be accessed with property I<worda_def> as an array reference.

=item I<wordb>

The second word, being compared to, and on the right of the operator.

Also the details of elements for I<wordb> can be accessed with property I<wordb_def> as an array reference.

=back

See L<Regexp::Common::Apache2/integercomp> for more information.

=item B<join>

Type: join

Possible sub types: none

Available properties:

=over 8

=item I<list>

The list of strings to be joined. See the content of the I<elements> array reference for more breakdown on the arguments provided.

Also the details of elements for those args can be accessed with property I<list_def> as an array reference.

=item I<word>

The word used to join the list. This parameter is optional.

Details for the word parameter, if any, can be found in the I<elements> array reference or can be accessed with the I<word_def> property.

=back

For example :

    join({"John Paul Doe"}, ', ')
    # or
    join({"John", "Paul", "Doe"}, ', ')
    # or just
    join({"John", "Paul", "Doe"})

See L<Regexp::Common::Apache2/join> for more information.

=item B<listfunc>

Type: listfunc

Possible sub types: none

Available properties:

=over 8

=item I<args>

Function arguments. See the content of the I<elements> array reference for more breakdown on the arguments provided.

Also the details of elements for those args can be accessed with property I<args_def> as an array reference.

=item I<name>

Function name

=back

See L<Regexp::Common::Apache2/listfunc> for more information.

=item B<regex>

Type: regex

Possible sub types: none

Available properties:

=over 8

=item I<flags>

Example: C<mgis>

=item I<pattern>

Regular expression pattern, excluding enclosing separators.

=item I<sep>

Type of separators used. It can be: /, #, $, %, ^, |, ?, !, ', ", ",", ";", ":", ".", _, and -

=back

See L<Regexp::Common::Apache2/regex> for more information.

=item B<stringcomp>

Type: stringcomp

Possible sub types: none

Available properties:

=over 8

=item I<op>

COntains the operator used. See L<Regexp::Common::Apache2/stringcomp>

=item I<worda>

The first word being compared, and on the left of the operator. For example :

    12 -ne 10

Also the details of elements for I<worda> can be accessed with property I<worda_def> as an array reference.

=item I<wordb>

The second word, being compared to, and on the right of the operator.

Also the details of elements for I<wordb> can be accessed with property I<wordb_def> as an array reference.

=back

See L<Regexp::Common::Apache2/stringcomp> for more information.

=item B<variable>

Type: variable

Possible sub types:

=over 8

=item I<function>

    %{md5:"some arguments"}

=item I<rebackref>

This is a regular expression back reference, such as C<$1>, C<$2>, etc. up to 9

=item I<variable>

    %{REQUEST_URI}
    # or by enabling the legacy expressions
    ${REQUEST_URI}

=back

Available properties:

=over 8

=item I<args>

Function arguments. See the content of the I<elements> array reference for more breakdown on the arguments provided.

=item I<name>

Function name, or variable name.

=item I<value>

The regular expression back reference value, such as C<1>, C<2>, etc

=back

See L<Regexp::Common::Apache2/variable> for more information.

=item B<word>

Type: word

Possible sub types:

=over 8

=item I<digits>

When the word contains one or more digits.

=item I<dotted>

When the word contains words sepsrated by dots, such as C<192.168.1.10>

=item I<function>

When the word is a function.

=item I<parens>

When the word is surrounded by parenthesis

=item I<quote>

When the word is surrounded by single or double quotes

=item I<rebackref>

When the word is a regular expression back reference such as C<$1>, C<$2>, etc up to 9.

=item I<regex>

This is an extension I added to make work some function such as C<split( /\w+/, $ip_list)>

Without it, the regular expression would not be recognised as the Apache BNF stands.

=item I<variable>

When the word is a variable. For example : C<%{REQUEST_URI}>, and it can also be a variable like C<${REQUEST_URI> if the legacy mode is enabled.

=back

Available properties:

=over 8

=item I<flags>

The regular expression flags used, such as C<mgis>

=item I<parens>

Contains an array reference of the open and close parenthesis, such as:

    ["(", ")"]

=item I<pattern>

The regular expression pattern

=item I<quote>

Contains the type of quote used if the sub type is I<quote>

=item I<regex>

Contains the regular expression

=item I<sep>

The separator used in the regular expression, such as C</>

=item I<value>

The value of the digits if the sub type is I<digits> or I<rebackref>

=item I<word>

The word enclosed in quotes

=back

See L<Regexp::Common::Apache2/variable> for more information.

=back

=head1 CAVEAT

This module supports well Apache2 expressions. However, some expression are difficult to process. For example:

Expressions with functions not using enclosing parenthesis:

    %{REMOTE_ADDR} -in split s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName')

Instead, use:

    %{REMOTE_ADDR} -in split(s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName'))

There is no mechanism yet to prevent infinite recursion. This needs to be implemented.

=head1 CHANGES & CONTRIBUTIONS

Feel free to reach out to the author for possible corrections, improvements, or suggestions.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::SSI>, L<Regexp::Common::Apache2>, 
L<https://httpd.apache.org/docs/current/expr.html>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
