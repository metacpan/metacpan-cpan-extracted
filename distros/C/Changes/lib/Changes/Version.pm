##----------------------------------------------------------------------------
## Changes file management - ~/lib/Changes/Version.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/12/01
## Modified 2022/12/01
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Changes::Version;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $VERSION_LAX_REGEX $DEFAULT_TYPE );
    use version ();
    use Nice::Try;
    # From version::regex
    # Comments in the regular expression below are taken from version::regex
    our $VERSION_LAX_REGEX = qr/
    (?<ver_str>
        # Lax dotted-decimal version number. Distinguished by having either leading "v" 
        # or at least three non-alpha parts. Alpha part is only permitted if there are 
        # at least two non-alpha parts. Strangely enough, without the leading "v", Perl 
        # takes .1.2 to mean v0.1.2, so when there is no "v", the leading part is optional
        (?<dotted>
            (?<has_v>v)
            (?<ver>
                (?<major>[0-9]+)
                (?:
                    (?<minor_patch>(?:\.[0-9]+)+)
                    (?:_(?<alpha>[0-9]+))?
                )?
            )
            |
            (?<ver>
                (?<major>[0-9]+)?
                (?<minor_patch>(?:\.[0-9]+){2,})
                (?:_(?<alpha>[0-9]+))?
            )
        )
        |
        # Lax decimal version number. Just like the strict one except for allowing an 
        # alpha suffix or allowing a leading or trailing decimal-point
        (?<decimal>
            (?<ver>(?<release>(?<major>[0-9]+) (?: (?:\.(?<minor>[0-9]+)) | \. )?) (?:_(?<alpha>[0-9]+))?)
            |
            (?<ver>(?:\.(?<release>(?<major>[0-9]+))) (?:_(?<alpha>[0-9]+))?)
        )
    )/x;
    our $DEFAULT_TYPE = 'dotted';
    use overload (
        '""'    => \&as_string,
        # '='		=> \&clone,
        '0+'    => \&numify,
        '<=>'   => \&_compare,
        'cmp'   => \&_compare,
        'bool'  => \&_bool,
        '+'     => sub { return( shift->_compute( @_, { op => '+' }) ); },
        '-'     => sub { return( shift->_compute( @_, { op => '-' }) ); },
        '*'     => sub { return( shift->_compute( @_, { op => '*' }) ); },
        '/'     => sub { return( shift->_compute( @_, { op => '/' }) ); },
        '+='    => sub { return( shift->_compute( @_, { op => '+=' }) ); },
        '-='    => sub { return( shift->_compute( @_, { op => '-=' }) ); },
        '*='    => sub { return( shift->_compute( @_, { op => '*=' }) ); },
        '/='    => sub { return( shift->_compute( @_, { op => '/=' }) ); },
        '++'    => sub { return( shift->_compute( @_, { op => '++' }) ); },
        '--'    => sub { return( shift->_compute( @_, { op => '--' }) ); },
        # We put it here so perl won't trigger the noop overload method
        '='     => sub { $_[0] },
        'abs'   => \&_noop,
        'nomethod' => \&_noop,
    );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{alpha}  = undef;
    # Used for other version types
    $self->{beta}   = undef;
    $self->{compat} = 0;
    # What version fragment to increase/decrease by default, such as when we do operations like $v++ or $v--
    $self->{default_frag} = 'minor';
    $self->{extra}  = [];
    $self->{major}  = undef;
    $self->{minor}  = undef;
    $self->{original} = undef;
    $self->{padded} = 1;
    $self->{patch}  = undef;
    $self->{pretty} = 0;
    $self->{qv}     = 0;
    # Release candidate used by non-perl open source softwares
    $self->{rc}     = undef;
    $self->{target} = 'perl';
    $self->{type}   = undef;
    my $keys = [qw( alpha beta compat default_frag extra  major minor original patch qv rc target type _version )];
    my $vstr;
    # Changes::Version->new( 'v0.1.2_3' ); or
    # Changes::Version->new( 'v0.1.2_3', alpha => 4 ); or
    # Changes::Version->new( 'v0.1.2_3', { alpha => 4 } ); or
    # Changes::Version->new( major => 0, minor => 1, patch => 2, alpha => 3, qv => 1 ); or
    # Changes::Version->new({ major => 0, minor => 1, patch => 2, alpha => 3, qv => 1 }); or
    if( ( @_ == 1 && ref( $_[0] ) ne 'HASH' ) ||
        ( @_ > 1 && ref( $_[0] ) ne 'HASH' && ( ( @_ % 2 ) || ref( $_[1] ) eq 'HASH' ) ) )
    {
        $vstr = shift( @_ );
        return( $self->error( "version string provided is empty." ) ) if( !defined( $vstr ) || !length( "$vstr" ) );
        # So we can get options like debug for parser
        my $opts = $self->_get_args_as_hash( @_ );
        $self->debug( $opts->{debug} ) if( exists( $opts->{debug} ) && defined( $opts->{debug} ) && length( "$opts->{debug}" ) );
        # A version string was provided, so we parse it
        my $v = $self->parse( $vstr );
        return( $self->pass_error ) if( !defined( $v ) );
        # And we copy the collected value as default values for our new object, which can then be overriden by additional option passed here.
        @$self{ @$keys } = @$v{ @$keys };
    }
    $self->{_init_strict_use_sub} = 1;
    my $rv = $self->SUPER::init( @_ );
    return( $self->pass_error ) if( !defined( $rv ) );
    return( $self );
}

sub alpha { return( shift->reset(@_)->_set_get_number( { field => 'alpha', undef_ok => 1 }, @_ ) ); }

sub as_string
{
    my $self = shift( @_ );
    if( !exists( $self->{_reset} ) || 
        !defined( $self->{_reset} ) ||
        !CORE::length( $self->{_reset} ) )
    {
        if( exists( $self->{_cache_value} ) &&
            defined( $self->{_cache_value} ) &&
            length( $self->{_cache_value} ) )
        {
            return( $self->{_cache_value} );
        }
        elsif( defined( $self->{original} ) && length( "$self->{original}" ) )
        {
            return( $self->{original}->scalar );
        }
    }
    my $type = $self->type;
    my $str;
    if( ( defined( $type ) && $type eq 'dotted' ) ||
        ( !defined( $type ) && $DEFAULT_TYPE eq 'dotted' ) )
    {
        $str = $self->normal( raw => 1 );
    }
    else
    {
        $str = $self->numify( raw => 1 );
        if( !$self->padded && index( $str, '_' ) == -1 )
        {
            return( $str * 1 );
        }
        
        if( $self->pretty && index( $str, '_' ) == -1 && !( length( [split( /\./, $str )]->[1] ) % 3 ) )
        {
            # $str = join( '_', grep{ $_ ne ''} split( /(...)/, $str ) );
            # Credit: <https://stackoverflow.com/questions/33442240/perl-printf-to-use-commas-as-thousands-separator>
            while( $str =~ s/(\d+)(\d{3})/$1\_$2/ ){};
        }
    }
    $self->{_cache_value} = $str;
    CORE::delete( $self->{_reset} );
    return( $str );
}

{
    no warnings 'once';
    *stringify = \&as_string;
}

sub beta { return( shift->reset(@_)->_set_get_number( { field => 'beta', undef_ok => 1 }, @_ ) ); }

# NOTE: clone() is inherited

sub compat { return( shift->_set_get_boolean( 'compat', @_ ) ); }

sub dec { return( shift->_inc_dec( 'dec', @_ ) ); }

sub dec_alpha { return( shift->_inc_dec( 'dec' => 'alpha', @_ ) ); }

# For non-perl open source softwares
sub dec_beta { return( shift->_inc_dec( 'dec' => 'beta', @_ ) ); }

sub dec_major { return( shift->_inc_dec( 'dec' => 'major', @_ ) ); }

sub dec_minor { return( shift->_inc_dec( 'dec' => 'minor', @_ ) ); }

sub dec_patch { return( shift->_inc_dec( 'dec' => 'patch', @_ ) ); }

sub default_frag { return( shift->_set_get_scalar_as_object( 'default_frag', @_ ) ); }

sub extra { return( shift->_set_get_array_as_object( 'extra', @_ ) ); }

sub inc { return( shift->_inc_dec( 'inc', @_ ) ); }

sub inc_alpha { return( shift->_inc_dec( 'inc' => 'alpha', @_ ) ); }

sub inc_beta { return( shift->_inc_dec( 'inc' => 'beta', @_ ) ); }

sub inc_major { return( shift->_inc_dec( 'inc' => 'major', @_ ) ); }

sub inc_minor { return( shift->_inc_dec( 'inc' => 'minor', @_ ) ); }

sub inc_patch { return( shift->_inc_dec( 'inc' => 'patch', @_ ) ); }

sub is_alpha { return( shift->alpha->length > 0 ? 1 : 0 ); }

sub is_qv { return( shift->qv ? 1 : 0 ); }

sub major { return( shift->reset(@_)->_set_get_number( { field => 'major', undef_ok => 1 }, @_ ) ); }

sub minor { return( shift->reset(@_)->_set_get_number( { field => 'minor', undef_ok => 1 }, @_ ) ); }

sub normal
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{raw} //= 0;
    my $v;
    try
    {
        my $clone = $self->clone;
        if( !$self->qv )
        {
            $clone->qv(1);
        }
        if( $opts->{raw} )
        {
            $v = $clone->_stringify;
            # We already did it with stringify, so we return what we got
            return( $v );
        }
        else
        {
            $clone->type( 'dotted' );
            return( $clone );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error normalising version $v: $e" ) );
    }
}

sub numify
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{raw} //= 0;
    my $v;
    try
    {
        if( $opts->{raw} )
        {
            # If alpha is set, such as when we convert a dotted decimal into a decimal, we need to remove it and add it back later, because version mess it up
            # For example: version->parse( '1.0_3' )->normal yields v1.30.0 instead of v1.0.0_3 whereas version->parse( '1.0' )->normal yields correctly v1.0.0
            my $clone = $self->clone;
            my $alpha = $clone->alpha;
            $clone->alpha( undef );
            $v = $clone->_stringify;
            my $str = version->parse( $v )->numify;
            $str .= "_${alpha}" if( defined( $alpha ) && length( "$alpha" ) );
            return( $str );
        }
        else
        {
            my $new = $self->clone;
            # This will also remove qv boolean
            $new->type( 'decimal' );
            return( $new );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error numifying version $v: $e" ) );
    }
}

sub original { return( shift->_set_get_scalar_as_object( 'original', @_ ) ); }

sub padded { return( shift->reset(@_)->_set_get_boolean( 'padded', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    return( $self->error( "No version string was provided." ) ) if( !defined( $str ) || !length( "$str" ) );
    if( $str =~ /^$VERSION_LAX_REGEX$/ )
    {
        my $re = { %+ };
        my $def = { original => $str };
        if( defined( $re->{dotted} ) && length( $re->{dotted} ) )
        {
            $def->{type} = 'dotted';
        }
        elsif( defined( $re->{decimal} ) && length( $re->{decimal} ) )
        {
            $def->{type} = 'decimal';
        }
        else
        {
            return( $self->error( "No version types found. This should not happen." ) );
        }
        my $v;
        $def->{qv}    = 1 if( defined( $re->{has_v} ) && length( $re->{has_v} ) );
        $def->{major} = $re->{major};
        $def->{alpha} = $re->{alpha} if( defined( $re->{alpha} ) && length( $re->{alpha} ) );
        if( $def->{type} eq 'dotted' )
        {
            if( defined( $re->{minor_patch} ) )
            {
                my @frags = split( /\./, $re->{minor_patch} );
                shift( @frags );
                $def->{minor} = shift( @frags );
                $def->{patch} = shift( @frags );
                $def->{extra} = \@frags;
            }
            $v = version->parse( $re->{dotted} );
        }
        elsif( $def->{type} eq 'decimal' )
        {
            # $def->{minor} = $re->{minor} if( defined( $re->{minor} ) );
            # $re->{release} is the decimal version without the alpha information if it is smaller than 3
            # This issue stems from decimal number having an underscore can either mean they have a version like
            # 5.006_002 which would be equivalent v5.6.2 and in this case, "_002" is not an alpha information; and
            # 1.002_03 where 03 is the alpha version and should be converted to 1.2_03, but instead becomes v1.2.30
            # If compatibility with 'compat' is enabled, then we use the classic albeit erroneous way of converting the decimal version
            if( defined( $def->{alpha} ) && 
                length( $def->{alpha} ) < 3 && 
                !$self->compat )
            {
                $v = version->parse( "$re->{release}" );
            }
            else
            {
                $v = version->parse( "$str" );
            }
            my $vstr = $v->normal;
            if( $vstr =~ /^$VERSION_LAX_REGEX$/ )
            {
                my $re2 = { %+ };
                if( defined( $re2->{dotted} ) && length( $re2->{dotted} ) )
                {
                    if( defined( $re2->{minor_patch} ) )
                    {
                        $def->{major} = $re2->{major};
                        my @frags = split( /\./, $re2->{minor_patch} );
                        shift( @frags );
                        $def->{minor} = shift( @frags );
                        $def->{patch} = shift( @frags );
                        $def->{extra} = \@frags;
                    }
                }
            }
        }
        my $new = $self->new( %$def );
        $new->{_version} = $v if( defined( $v ) );
        return( $self->pass_error ) if( !defined( $new ) );
        CORE::delete( $new->{_reset} );
        return( $new );
    }
    else
    {
        return( $self->error( "Invalid version '$str'" ) );
    }
}

sub patch { return( shift->reset(@_)->_set_get_number( { field => 'patch', undef_ok => 1 }, @_ ) ); }

sub pretty { return( shift->reset(@_)->_set_get_boolean( 'pretty', @_ ) ); }

sub qv { return( shift->reset(@_)->_set_get_boolean( 'qv', @_ ) ); }

sub rc { return( shift->_set_get_scalar_as_object( 'rc', @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    if( (
            !exists( $self->{_reset} ) ||
            !defined( $self->{_reset} ) ||
            !CORE::length( $self->{_reset} ) 
        ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
        if( defined( $self->{major} ) )
        {
            my $str = $self->_stringify;
            try
            {
                my $v = version->parse( "$str" );
                $self->{_version} = $v;
            }
            catch( $e )
            {
                warn( "Warning only: error trying to get a version object from version string '$str': $e\n" ) if( $self->_warnings_is_enabled );
            }
        }
    }
    return( $self );
}

sub target { return( shift->_set_get_scalar_as_object( 'target', @_ ) ); }

sub type { return( shift->reset(@_)->_set_get_scalar_as_object({
    field => 'type',
    callbacks => 
    {
        add => sub
        {
            my $self = shift( @_ );
            if( $self->{type} eq 'decimal' )
            {
                $self->{qv} = 0;
            }
            elsif( $self->{type} eq 'dotted' )
            {
                # By default
                $self->{qv} = 1;
            }
        }
    }
}, @_ ) ); }

sub _bool
{
    my $self = shift( @_ );
    # return( $self->_compare( $self->_version, version->new("0"), 1 ) );
    return( $self->_compare( $self, "0", 1 ) );
}

sub _cascade
{
    my $self = shift( @_ );
    my $frag = shift( @_ );
    # We die, because this is an internal method and those cases should not happen unless this were a design bug
    if( !defined( $frag ) || !length( $frag ) )
    {
        die( "No fragment was provided to cascade" );
    }
    elsif( $frag !~ /^(major|minor|patch|alpha|\d+)$/ )
    {
        die( "Unsupported version fragment '$frag'. Only use 'major', 'minor', 'patch' or 'alpha' or a number starting from 1 (1 = major, 2 = minor, etc)." );
    }
    my $extra = $self->extra;
    my $frag_is_int = ( $frag =~ /^\d+$/ ? 1 : 0 );
    if( $frag eq 'major' || ( $frag_is_int && $frag == 1 ) )
    {
        $self->alpha( undef );
        $self->patch(0);
        $self->minor(0);
    }
    elsif( $frag eq 'minor' || ( $frag_is_int && $frag == 2 ) )
    {
        $self->alpha( undef );
        $self->patch(0);
    }
    elsif( $frag eq 'patch' || ( $frag_is_int && $frag == 3 ) )
    {
        $self->alpha( undef );
    }
    elsif( $frag eq 'alpha' )
    {
        # Nothing to do
    }
    elsif( $frag_is_int )
    {
        my $offset = ( $frag - 4 );
        my $len = $extra->length;
        # Before the fragment offset, we set the value to 0 if it is undefined or empty, and
        # after the fragment offset everything else is reset to 0
        for( my $i = 0; $i < ( $offset < $len ? $len : $offset ); $i++ )
        {
            if( (
                    $i < $offset && 
                    ( !defined( $extra->[$i] ) || !length( $extra->[$i] ) )
                ) || $i > $offset )
            {
                $extra->[$i] = 0;
            }
        }
        $self->alpha( undef );
    }
}

sub _compare
{
    my( $left, $right, $swap ) = @_;
    my $class = ref( $left );
    unless( $left->_is_a( $right => $class ) )
    {
        $right = $class->new( $right, debug => $left->debug );
    }

    if( $swap )
    {
        ( $left, $right ) = ( $right, $left );
    }
    
    unless( _verify( $left ) )
    {
        die( "Invalid version ", ( $swap ? 'format' : 'object ' . overload::StrVal( $left ) ), "." );
    }
    unless( _verify( $right ) )
    {
        die( "Invalid version ", ( $swap ? 'format' : 'object' . overload::StrVal( $right ) ), "." );
    }
    my $lv = $left->_version;
    my $rv = $right->_version;
    # TODO: better compare version. perl's version fails at comparing version that have alpha.
    # For example, the documentation states:
    # Note that "alpha" version objects (where the version string contains a trailing underscore segment) compare as less than the equivalent version without an underscore:
    # $bool = version->parse("1.23_45") < version->parse("1.2345"); # TRUE
    # However, this is not true. The above doc example will yield FALSE, not TRUE, and even the following too:
    # perl -Mversion -lE 'my $v = version->parse("v1.2.3"); my $v2 = version->parse("v1.2.3_4"); say $v > $v2'
    # See RT#145290: <https://rt.cpan.org/Ticket/Display.html?id=145290>
    # return( $left->{_version} == $right->{_version} );
    # return( $lv == $rv );
    return( $lv <=> $rv );
}

sub _compute
{
    my $self = shift( @_ );
    my $opts = pop( @_ );
    my( $other, $swap, $nomethod, $bitwise ) = @_;
    my $frag = $self->default_frag // 'minor';
    $frag = 'minor' if( $frag !~ /^(major|minor|patch|alpha|\d+)$/ );
    if( !defined( $opts ) || 
        ref( $opts ) ne 'HASH' || 
        !exists( $opts->{op} ) || 
        !defined( $opts->{op} ) || 
        !length( $opts->{op} ) )
    {
        die( "No argument 'op' provided" );
    }
    my $op = $opts->{op};
    my $clone = $self->clone;
    my $extra = $self->extra;
    my $frag_is_int = ( $frag =~ /^\d+$/ ? 1 : 0 );
    my $map =
    {
    1 => 'major',
    2 => 'minor',
    3 => 'patch',
    };
    my $coderef;
    if( ( $frag_is_int && exists( $map->{ $frag } ) ) || !$frag_is_int )
    {
        $coderef = $self->can( $map->{ $frag } // $frag ) ||
            die( "Cannot find code reference for method ", ( $frag_is_int ? $map->{ $frag } : $frag ) );
    }
    my $val = defined( $coderef ) ? $coderef->( $self ) : $extra->[ $frag - 4 ];
    my $err;
    if( !defined( $val ) )
    {
        $val = $self->new_number(0);
    }
    elsif( !$self->_is_a( $val => 'Module::Generic::Number' ) )
    {
        $val = $self->new_number( "$val" );
        if( !defined( $val ) )
        {
            $err = $self->error->message;
        }
    }
    my $n = $val->scalar;
    my $eval;
    if( $opts->{op} eq '++' || $opts->{op} eq '--' )
    {
        $eval = "\$n${op}";
    }
    else
    {
        $eval = $swap ? ( defined( $other ) ? $other : 'undef' ) . "${op} \$n" : "\$n ${op} " . ( defined( $other ) ? $other : 'undef' );
    }
    my $rv = eval( $eval );
    $err = $@ if( $@ );
    if( defined( $err ) )
    {
        warn( $err, "\n" ) if( $self->_warnings_is_enabled );
        # Return unchanged
        # return( $swap ? $other : $self );
        return;
    }
    
    if( $swap )
    {
        return( ref( $rv ) ? $rv->scalar : $rv );
    }
    else
    {
        my $new = $clone;
        my $new_val;
        if( $op eq '++' || $op eq '--' )
        {
            $new = $self;
            $new_val = $n;
        }
        else
        {
            $new_val = int( $rv );
        }
        
        if( defined( $coderef ) )
        {
            $coderef->( $new, $new_val );
        }
        else
        {
            $extra->[( $frag - 4 )] = $new_val;
        }
        $new->_cascade( $frag );
        return( $new );
    }
}

sub _inc_dec
{
    my $self = shift( @_ );
    my $op = shift( @_ ) || return( $self->error( "No op was provided." ) );
    return( $self->error( "Op can only be 'inc' or 'dec'" ) ) if( $op !~ /^(inc|dec)$/ );
    my $frag = shift( @_ );
    my $unit = shift( @_ );
    if( !defined( $frag ) || !length( "$frag" ) )
    {
        return( $self->error( "No version fragment was specified to ", ( $op eq 'inc' ? 'increase' : 'decrease' ), " the version number." ) );
    }
    elsif( $frag !~ /^(major|minor|patch|alpha|\d+)$/ )
    {
        return( $self->error( "Unsupported version fragment '$frag' to ", ( $op eq 'inc' ? 'increase' : 'decrease' ), ". Only use 'major', 'minor', 'patch' or 'alpha' or a number starting from 1 (1 = major, 2 = minor, etc)." ) );
    }
    if( defined( $unit ) && $unit !~ /^\d+$/ )
    {
        return( $self->error( "Unit to ", ( $op eq 'inc' ? 'increase' : 'decrease' ), " fragment $frag value must be an integer." ) );
    }
    my $extra = $self->extra;
    my $frag_is_int = ( $frag =~ /^\d+$/ ? 1 : 0 );
    my $map =
    {
    1 => 'major',
    2 => 'minor',
    3 => 'patch',
    };
    my $coderef;
    if( ( $frag_is_int && exists( $map->{ $frag } ) ) || !$frag_is_int )
    {
        $coderef = $self->can( $map->{ $frag } // $frag ) ||
            die( "Cannot find code reference for method ", ( $frag_is_int ? $map->{ $frag } : $frag ) );
    }
    my $n = defined( $coderef ) ? $coderef->( $self ) : $extra->[ $frag - 4 ];
    # The offset specified is out of bound
    if( $frag_is_int && ( $frag - 4 ) > $extra->size )
    {
        $n = (
            $op eq 'inc'
                ? ( defined( $unit ) ? $unit : 1 )
                : 0
        );
    }
    elsif( defined( $unit ) && $unit == 1 )
    {
        $op eq 'inc' ? ( $n += $unit ) : ( $n -= $unit );
    }
    else
    {
        $op eq 'inc' ? $n++ : $n--;
    }
    
    if( defined( $coderef ) )
    {
        $coderef->( $self, $n );
    }
    else
    {
        $extra->[( $frag - 4 )] = $n;
    }
    $self->_cascade( $frag );
    return( $self );
}

sub _noop
{
    my( $self, $other, $swap, $nomethod, $bitwise ) = @_;
    warn( "This operation $nomethod is not supported by Changes::Version\n" ) if( $self->_warnings_is_enabled );
}

sub _stringify
{
    my $self = shift( @_ );
    my $comp = $self->new_array;
    my $def = {};
    for( qw( major minor patch alpha ) )
    {
        $def->{ $_ } = $self->$_;
    }
    my $type = $self->type;
    $def->{major} = 0 if( !defined( $def->{major} ) || !length( $def->{major} ) );
    if( $self->qv || ( ( $type // '' ) eq 'dotted' ) )
    {
        $def->{minor} = 0 if( !defined( $def->{minor} ) || !length( "$def->{minor}" ) );
        $def->{patch} = 0 if( !defined( $def->{patch} ) || !length( "$def->{patch}" ) );
    }
    elsif( ( $type // '' ) eq 'decimal' )
    {
        # We need to avoid the scenario where we would have a major and alpha, but not minor.
        # For example: 3_6 would trigger version error "Invalid version format (alpha without decimal)"
        $def->{minor} = 0 if( ( !defined( $def->{minor} ) || !length( "$def->{minor}" ) ) && defined( $def->{alpha} ) && length( "$def->{alpha}" ) );
    }
    my $ok = 0;
    for( qw( patch minor major ) )
    {
        next if( !length( $def->{ $_ } ) && !$ok );
        # We stop skipping version fragments as soon as one is defined
        $ok++;
        $comp->unshift( $def->{ $_ } );
    }
    my $v = ( $self->qv ? 'v' : '' ) . $comp->map(sub{ 0 + $_ })->join( '.' )->scalar;
    $v .= '_' . $def->{alpha} if( defined( $def->{alpha} ) && length( $def->{alpha} ) );
    return( $v );
}

sub _verify
{
    my $self = shift( @_ );
    if( defined( $self ) )
    {
    }
    if( defined( $self ) &&
        Module::Generic->_is_a( $self => 'Changes::Version' ) &&
        eval{ exists( $self->{_version} ) } &&
        Module::Generic->_is_a( $self->{_version} => 'version' ) )
    {
        return(1);
    }
    else
    {
        return(0);
    }
}

sub _version
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->error( "Value provided is not a version object." ) ) if( !$self->_is_a( $v => 'version' ) );
    }
    elsif( !exists( $self->{_version} ) || !defined( $self->{_version} ) )
    {
        my $str = $self->_stringify;
        try
        {
            $self->{_version} = version->parse( "$str" );
        }
        catch( $e )
        {
            warn( "Warning only: error trying to get a version object from version string '$str': $e\n" ) if( $self->_warnings_is_enabled );
        }
    }
    return( $self->{_version} );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Changes::Version - Version string object class

=head1 SYNOPSIS

    use Changes::Version;
    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
        qv => 1,
        debug => 2,
    );
    # or
    my $v = Changes::Version->new( 'v0.1.2_3' );
    # or
    my $v = Changes::Version->new( 'v0.1.2_3', alpha => 4 );
    # or
    my $v = Changes::Version->new( 'v0.1.2_3', { alpha => 4 } );
    # or
    my $v = Changes::Version->new( major => 0, minor => 1, patch => 2, alpha => 3, qv => 1 );
    # or
    my $v = Changes::Version->new({ major => 0, minor => 1, patch => 2, alpha => 3, qv => 1 });
    die( Changes::Version->error ) if( !defined( $v ) );
    my $v = Changes::Version->parse( 'v1.2.3_4' );
    die( Changes::Version->error ) if( !defined( $v ) );
    my $type = $v->type;
    $v->type( 'decimal' );
    $v->padded(0);
    $v->pretty(1);
    $v->type( 'dotted' );
    $v++;
    # Updating 'minor'
    say "$v"; # v1.3.0
    $v += 2;
    $v->default_frag( 'major' );
    $v++;
    say "$v"; # v2.0.0
    $v->inc_patch;
    say $v->is_alpha; # false
    say $v->numify; # returns new Changes::Version object
    say $v->normal; # returns new Changes::Version object
    say $v->as_string; # same as say "$v";

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a software version based on perl's definition and providing for perl recommended C<dotted decimal> and also C<decimal> types. In the future, this will be expanded to other non-perl version formats.

It allows for parsing and manipulation of version objects.

=head1 CONSTRUCTOR

=head2 new

Provided with an optional version string and an optional hash or hash reference of options and this will instantiate a new L<Changes::Version> object.

If an error occurs, it will return an L<error|Module::Generic/error>, so alway check for the definedness of the returned value.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    die( Changes::Version->error ) if( !defined( $v ) );

Note that if you do:

    my $v = Changes::Version->new( ... ) || die( Changes::Version->error );

would be dangerous, because you would be assessing the return version object in a boolean context that could return false if the version was C<0>.

It supports the following options that can also be accessed or changed with their corresponding method.

=over 4

=item * C<alpha>

Specifies the alpha fragment integer of the version. See L</alpha> for more information.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    my $alpha = $v->alpha; # 4
    $v->alpha(7);
    say "$v"; # v1.2.3_7

=item * C<beta>

Specifies the beta fragment integer of the version. See L</beta> for more information.

Currently unused and reserved for future release.

=item * C<compat>

Boolean. When enabled, this will ensure the version formatting is strictly compliant with the L<version> module. Default to false.

=item * C<default_frag>

Specifies the fragment name or integer value used by overloaded operations.

    my $v = Changes::Version->new( 'v1.2.3_4' );
    my $default = $v->default_frag; # By default 'minor'
    $v->default_frag( 'major' );
    $v++; # Version is now v2.2.3_4

=item * C<extra>

Specifies the array reference of version fragments beyond C<patch>

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 12,
        extra => [qw( 4 5 6 7 )],
    );
    say "$v"; # v1.2.3.4.5.6.7_12
    my $a = $v->extra; # contains 4, 5, 6, 7

=item * C<major>

Specifies the C<major> fragment of the version string.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    my $major = $v->major; # 1
    say "$v"; # v1.2.3_4
    $v->major(3);
    say "$v"; # v3.0.0

=item * C<minor>

Specifies the C<minor> fragment of the version string.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    my $minor = $v->minor; # 2
    say "$v"; # v1.2.3_4
    $v->minor(3);
    say "$v"; # v1.3.0

=item * C<original>

Specifies an original version string. This is normally set by L</parse> and used by L</as_string> to bypass any formatting when nothing has been changed.

=item * C<padded>

Specifies whether version string of type decimal should be zero padded or not. Default to true.

    my $v = Change::Version->new(
        major => 1,
        minor => 20,
        patch => 300,
        type => 'decimal',
    );
    say "$v"; # 1.020300
    $v->padded(0);
    say "$v"; # 1.0203

=item * C<patch>

Specifies the C<patch> fragment of the version string.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    my $patch = $v->patch; # 3
    say "$v"; # v1.2.3_4
    $v->patch(7);
    say "$v"; # v1.3.7

=item * C<pretty>

Specifies whether version string of type C<decimal> should be formatted with an underscore (C<_>) separating thousands in the fraction part.

    my $v = Change::Version->new(
        major => 1,
        minor => 20,
        patch => 300,
        type => 'decimal',
        pretty => 1,
    );
    say "$v"; # 1.020_300
    $v->pretty(0);
    say "$v"; # 1.020300

=item * C<qv>

Specifies whether version string of type C<dotted> should be formatted with the prefix C<v>. Defaults to true.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    say "$v"; # v1.2.3_4
    $v->qv(0);
    say "$v"; # 1.2.3_4

=item * C<rc>

Specifies the release candidate value. This is currently unused and reserved for future release.

=item * C<target>

Specifies the target formatting for the version string. By default this is C<perl> and is the only supported value for now. In future release, other format types will be supported, such as C<opensource>.

=item * C<type>

Specifies the version type. Possible values are C<dotted> for dotted decimal versions such as C<v1.2.3> or C<decimal> for decimal versions such as C<1.002003>

=back

=head2 parse

Provided with a version string, and this will parse it and return a new L<Changes::Version> object.

Currently, only 2 version types are supported: C<dotted decimal> and C<decimal>

    v1.2
    1.2345.6
    v1.23_4
    1.2345
    1.2345_01

are all legitimate version strings.

If an error occurred, this will return an L<error|Module::Generic/error>.

=head1 METHODS

=head2 alpha

Sets or gets the C<alpha> fragment integer of the version.

Setting this to C<undef> effectively removes it.

Returns a L<number object|Module::Generic::Number>

=head2 as_string

Returns a version string properly formatted according to the C<type> set with L</type> and other parameters sets such as L</qv>, L</padded> and L</pretty>

Resulting value is cached, which means the second time this is called, the cached value will be returned for speed.

Any change to the version object parameters, and this will force the re-formatting of the version string.

For example:

    my $v = Changes::Version->new( 'v1.2.3_4' );
    # This is a version of type 'dotted' for dotted decimal
    say "$v"; # v1.2.3_4
    # Changing the patch level
    $v->inc( 'patch' );
    # Now forced to re-format
    say "$v"; # v1.2.4
    # No change, using the cache
    say "$v"; # v1.2.4

=head2 beta

The beta fragment integer of the version. This is currently unused and reserved for future release of this class.

=head2 compat

Boolean. When enabled, this will ensure the version formatting is strictly compliant with the L<version> module. Default to false.

=head2 dec

Provided with a version fragment, and an optiona integer, and this will decrease the version fragment value by as much. If no integer is provided, the default decrement is 1.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    say "$v"; # v1.2.3_4;
    $v->dec( 'alpha' );
    say "$v"; # v1.2.3_3;
    $v->dec( 'patch', 2 );
    say "$v"; # v1.2.1

    my $v = Changes::Version->new( 'v1.2.3.4.5.6.7_8' );
    # Decrease the 5th fragment
    $v->dec(5);
    say "$v"; # v1.2.3.4.4.0.0

Any change to a fragment value will reset the lower fragment values to zero. Thus:

=over 4

=item * changing the C<major> value will reset C<minor> and C<patch> to 0 and C<alpha> to C<undef>

=item * changing the C<minor> value will reset C<patch> to 0 and C<alpha> to C<undef>

=item * changing the C<patch> value will reset C<alpha> to C<undef>

=item * changing the nth fragment value will reset all fragment value after that to 0

=back

If you pass a fragment that is an integer and it is outside the maximum number of fragments, it will automatically expand the number of version fragments and initialise the intermediary fragments to 0. A fragment as an integer starts at 1.

Using the example above:

    $v->dec(10);
    say "$v"; # v1.2.3.4.5.6.7.0.0.0

The 10th element is set to 0 because it does not exist, so it cannot be decreased.

=head2 dec_alpha

This is a shortcut for calling L</dec> on fragment C<alpha>

=head2 dec_beta

This is a shortcut for calling L</dec> on fragment C<beta>

=head2 dec_major

This is a shortcut for calling L</dec> on fragment C<major>

=head2 dec_minor

This is a shortcut for calling L</dec> on fragment C<minor>

=head2 dec_patch

This is a shortcut for calling L</dec> on fragment C<patch>

=head2 default_frag

    my $v = Changes::Version->new( 'v1.2.3_4' );
    my $default = $v->default_frag; # By default 'minor'
    $v->default_frag( 'major' );
    $v++; # Version is now v2.2.3_4

String. Sets or gets the name or the integer value for the version fragment. Supported value can be C<major>, C<minor>. C<patch>, C<alpha>, or an integer.

Returns a L<scalar object|Module::Generic::Scalar>

=head2 extra

Sets or gets an array reference of version fragments starting from C<1> for C<major>, C<2> for C<minor>, C<3> for C<patch>, etc. For example:

    my $v = Changes::Version->new( 'v1.2.3.4.5.6.7_8' );
    my $a = $v->extra; # contains 4, 5, 6, 7

Note that C<alpha> is not accessible via digits, but only using L</alpha>

You should not be accessing this directly.

Returns an L<array object|Module::Generic::Array>

=head2 inc

Same as L</dec>, but increasing instead of decreasing.

=head2 inc_alpha

This is a shortcut for calling L</inc> on fragment C<alpha>

=head2 inc_beta

This is a shortcut for calling L</inc> on fragment C<beta>

=head2 inc_major

This is a shortcut for calling L</inc> on fragment C<major>

=head2 inc_minor

This is a shortcut for calling L</inc> on fragment C<minor>

=head2 inc_patch

This is a shortcut for calling L</inc> on fragment C<patch>

=head2 is_alpha

Returns true if L</alpha> has a value set.

=head2 is_qv

Returns true if L</qv> is set to true, false otherwise.

=head2 major

Sets or gets the C<major> fragment of the version string.

    my $v = Changes::Version->new( 'v1.2.3_4' );
    my $major = $v->major; # 1
    $v->major(3);
    say "$v"; # v3.2.3_4

Setting this to C<undef> effectively removes it.

Returns a L<number object|Module::Generic::Number>

=head2 minor

Sets or gets the C<minor> fragment of the version string.

    my $v = Changes::Version->new( 'v1.2.3_4' );
    my $minor = $v->minor; # 2
    $v->minor(3);
    say "$v"; # v1.3.3_4

Setting this to C<undef> effectively removes it.

Returns a L<number object|Module::Generic::Number>

=head2 normal

Returns a new L<Changes::Version> object as a normalised version, which is a dotted decimal format with the C<v> prefix.

If an error occurred, an L<error|Module::Generic/error> is returned.

=head2 numify

Returns a new L<Changes::Version> object as a number, which represent a decimal-type version

Contrary to L<version> if there is an C<alpha> value set, it will add it to the numified version.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    say $v->numify; # 1.002003_4

L<version> would yields a different, albeit wrong result:

    perl -Mversion -lE 'say version->parse("v1.2.3_4")->numify'

would wrongly return C<1.002034> and not C<1.002003_4>

    perl -Mversion -lE 'say version->parse("1.002034")->normal'

then yields C<v1.2.34>

If an error occurred, an L<error|Module::Generic/error> is returned.

=head2 original

Sets or gets the original string. This is set by L</parse>

Returns a L<scalar object|Module::Generic::Scalar>

=head2 padded

Boolean. Sets or ges whether the resulting version string of type C<decimal> should be '0' padded or not. Default to pad with zeroes decimal numbers.

For example:

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 30,
        type => 'decimal',
        padded => 1,
    );
    say "$v"; # 1.002030
    $v->padded(0);
    say "$v"; # 1.00203

Returns a L<boolean object|Module::Generic::Boolean>

=head2 patch

Sets or gets the C<patch> fragment of the version string.

    my $v = Changes::Version->new( 'v1.2.3_4' );
    my $patch = $v->patch; # 3
    $v->patch(5);
    say "$v"; # v1.3.5_4

Returns a L<number object|Module::Generic::Number>

=head2 pretty

Boolean. When enabled, this will render version number for decimal type a bit cleaner by separating blocks of 3 digits by an underscore (C<_>). This does not work on dotted decimal version numbers such as C<v1.2.3> or on version that have an C<alpha> set up.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 30,
        type => 'decimal',
    );

Returns a L<boolean object|Module::Generic::Boolean>

=head2 qv

Boolean. When enabled, this will prepend the dotted decimal version strings with C<v>. This is true by default.

    my $v = Changes::Version->new(
        major => 1,
        minor => 2,
        patch => 3,
        alpha => 4,
    );
    say "$v"; # v1.2.3_4
    $v->qv(0);
    say "$v"; # 1.2.3_4

Returns a L<boolean object|Module::Generic::Boolean>

=head2 rc

Sets or gets the release candidate value. This is currently unused and reserved for future releases.

Returns a L<scalar object|Module::Generic::Scalar>

=for Pod::Coverage reset

=head2 stringify

This is an alias for L</as_string>

=head2 target

Sets or gets the target format. By default this is C<perl>. This means that L</as_string> will format the version string for C<perl>. In future release of this class, other format wil be supported, such as C<opensource>

Returns a L<scalar object|Module::Generic::Scalar>

=head2 type

Sets or gets the version type. Currently, supported values are C<dotted> for dotted decimal versions such as C<v1.2.3>, and C<decimal> for decimal versions such as C<1.002003>.

Returns a L<scalar object|Module::Generic::Scalar>

=head1 OVERLOADED OPERATIONS

The following operations are overloaded, and internally relies on L<version> to return the value. See also L<overload> for more information.

Note that calling the version object with any operations other than those listed below will trigger a warning, if warnings are enabled with L<warnings> and C<undef> is return in scalar context or an empty list in list context.

=over 4

=item * C<stringification>

Returns value from L</as_string>

=item * C<0+>

Returns value from L</numify>

=item * C<< <=> >>

Compares two versions. If the other version being compared is not a L<Changes::Version>, it is made one before comparison actually occurs.

Note that, C<version> core module L<states in its documentation|version/"How to compare version objects"> that: "alpha" version objects (where the version string contains a trailing underscore segment) compare as less than the equivalent version without an underscore."

    $bool = version->parse("1.23_45") < version->parse("1.2345"); # TRUE

However, as of perl v5.10, this is not true. The above will actually return false, not true. And so will the following:

    perl -Mversion -lE 'say version->parse("v1.002003") > version->parse("v1.002003_4");'

This is on my bucket list of things to improve.

=item * C<cmp>

Same as above.

=item * C<bool>

=item * C<+>, C<->, C<*>, C</>

When performing those operations, it will use the value of the fragment of the version set with L</default_frag>, which, by default, is C<minor>.

It returns a new L<Changes::Version> object reflecting the new version value. However, if the operation is swapped, with the version object on the right-hand side instead of the left-hand side, this will return a regular number.

    my $vers = Changes::Version->new( 'v1.2.3_4' );
    my $new_version_object = $vers + 2; # Now v1.4.3_4 (minor has been bumped up by 2)
    $vers->default_frag( 'major' );
    my $new_version_object = $vers + 2; # Now v3.2.3_4 (this time, 'major' was increased)

But, when swapped:

    my $vers = Changes::Version->new( 'v1.2.3_4' );
    my $n = 3 + $vers; # yields 5 (using the 'minor' fragment by default)
    $vers->default_frag( 'major' );
    my $n = 3 + $vers; # yields 4 (this time, using the 'major' fragment)

=item * C<+=>, C<-=>, C<*=>, C</=>

In this operations, it modifies the current object with the operand provided and returns the current object, instead of creating a new one.

    my $vers = Changes::Version->new( 'v1.2.3_4' );
    # By default, using the 'minor' fragment
    $vers += 1; # version is now v2.2.3_4
    $vers->default_frag( 'alpha' );
    $vers /= 2; # version is now v1.2.3_2

=item * C<++>, C<-->

When using those operations, it updates the current object directly and returns it. For example:

    my $vers = Changes::Version->new( 'v1.2.3_4' );
    # By default, using the 'minor' fragment
    $vers++; # version is now v1.3.3_4

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Changes>, L<Changes::Release>, L<Changes::Group>, L<Changes::Change> and L<Changes::NewLine>

L<version>, L<Perl::Version>

L<CPAN::Meta::Spec/"Version Formats">

L<http://www.modernperlbooks.com/mt/2009/07/version-confusion.html>

L<https://xdg.me/version-numbers-should-be-boring/>

L<https://en.wikipedia.org/wiki/Software_versioning>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
