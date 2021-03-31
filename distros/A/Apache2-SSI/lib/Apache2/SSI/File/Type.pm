##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/File/Type.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/27
## Modified 2021/03/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::SSI::File::Type;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use Digest::MD5;
    use File::Basename ();
    use File::Spec ();
    use IO::File;
    use Nice::Try;
    use Scalar::Util ();
    use URI::file;
    our $VERSION = 'v0.1.0';
    ## Translation of type in magic file to unpack template and byte count
    our $TEMPLATES = 
    {
    'byte'      => [ 'c', 1 ],
    'ubyte'     => [ 'C', 1 ],
    'char'      => [ 'c', 1 ],
    'uchar'     => [ 'C', 1 ],
    'short'     => [ 's', 2 ],
    'ushort'    => [ 'S', 2 ],
    'long'      => [ 'l', 4 ],
    'ulong'     => [ 'L', 4 ],
    'date'      => [ 'l', 4 ],
    'ubeshort'  => [ 'n', 2 ],
    'beshort'   => [ [ 'n', 'S', 's' ], 2 ],
    'ubelong'   => [   'N',             4 ],
    'belong'    => [ [ 'N', 'I', 'i' ], 4 ],
    'bedate'    => [   'N',             4 ],
    'uleshort'  => [   'v',             2 ],
    'leshort'   => [ [ 'v', 'S', 's' ], 2 ],
    'ulelong'   => [   'V',             4 ],
    'lelong'    => [ [ 'V', 'I', 'i' ], 4 ],
    'ledate'    => [   'V',             4 ],
    'string'    => undef(),
    };
    
    ## For letter escapes in magic file
    our $ESC = 
    {
    'n' => "\n",
    'r' => "\r",
    'b' => "\b",
    't' => "\t",
    'f' => "\f"
    };
    ## Cache
    our $MAGIC_DATA = [];
    ## Keep a record of the source data file, if any, so we can re-use this cached data instead of re-reading from it
    our $MAGIC_DATA_SOURCE = '';
};

sub init
{
    my $self = shift( @_ );
    my $file;
    $file = shift( @_ ) if( @_ % 2 );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{magic} = $file if( length( $file ) );
    $self->{follow_links} = 1;
    $self->{check_magic}  = 0;
    ## If there is an error or file is empty, it returns undef instead of application/octet-stream
    $self->{error_returns_undef} = 0;
    ## Default to returns text/plain. If not, it will return an empty string and leave the caller to set the default mime-type.
    $self->{default_type} = 'text/plain';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{magic}        = {};
    $self->{magic_data}   = [];
    local $load_json_data = sub
    {
        my $json_file = shift( @_ ) || return;
        my $io = IO::File->new( "<$json_file" ) ||
            return( $self->error( "Unable to open our own json magic file \"$json_file\": $!" ) );
        local $/;
        my $buf = scalar( <$io> );
        $io->close;
        try
        {
            my $j = JSON->new->relaxed->allow_nonref;
            $MAGIC_DATA = $self->{magic_data} = $j->decode( $buf );
            return( 1 );
        }
        catch( $e )
        {
            return( $self->error( "An error occured while trying to json decode ", length( $buf ), " bytes of json data: $e" ) );
        }
    };
    
    if( $opts->{magic} )
    {
        $file = $opts->{magic};
        my $file_abs = URI::file->new_abs( $file )->file( $^O );
        $self->message( 3, "Magic file \"$file\" ($file_abs) provided. slurping it." );
        if( $file_abs eq $MAGIC_DATA_SOURCE && scalar( @$MAGIC_DATA ) )
        {
            $self->message( 3, "Data for magic file \"$file\" ($file_abs) is already loaded, re-using it." );
            $self->{magic_data} = $MAGIC_DATA;
        }
        else
        {
            my $checksum = Digest::MD5::md5_hex( $file_abs );
            my $base = File::Basename::basename( $file );
            my $path = File::Spec->catpath( File::Spec->tmpdir, $base . "_${checksum}.json" );
            if( -e( $path ) && -s( $path ) )
            {
                $self->message( 3, "Found previous magic json data file \"$path\", loading it instead." );
                $load_json_data->( $path ) || return;
            }
            else
            {
                return( $self->error( "Magic file provided \"$file\" does not exist." ) ) if( !-e( $file ) );
                my $io = IO::File->new( "<$file" ) ||
                    return( $self->error( "Unable to open magic file provided \"$file\": $!" ) );
                $io->binmode;
                $self->parse_magic_file( $io );
                $MAGIC_DATA = $self->{magic_data};
                $io->close;
                $self->message( 3, "Saving magic data to json cache file \"$path\"." );
                my $json = $self->as_json || return;
                my $fh = IO::File->new( ">$path" ) || 
                    return( $self->error( "Unable to write to magic cache json data file \"$path\": $!" ) );
                $fh->binmode;
                $fh->print( $json );
                $fh->close;
            }
            $MAGIC_DATA_SOURCE = $file_abs;
        }
    }
    elsif( $MAGIC_DATA && scalar( @$MAGIC_DATA ) )
    {
        $self->{magic_data} = $MAGIC_DATA;
    }
    else
    {
        $file = __FILE__;
        $file =~ s/\.pm/\.json/;
        $self->message( 3, "No magic file specified, reading our magic json data from \"$file\"" );
        return( $self->error( "Apache2::SSI magic file \"$file\" does not exist." ) ) if( !-e( $file ) );
        $load_json_data->( $file ) || return;
    }
    
    ## From the BSD names.h, some tokens for hard-coded checks of different texts.
    ## This isn't rocket science. It's prone to failure so these checks are only a last resort.
    $self->{SPECIALS} = 
    {
        'message/rfc822' => 
            [
            '^Received:',   
            '^>From ',       
            '^From ',       
            '^To: ',
            '^Return-Path: ',
            '^Cc: ',
            '^X-Mailer: '
            ],
        'message/news' => 
            [
            '^Newsgroups: ', 
            '^Path: ',       
            '^X-Newsreader: '
            ],
        'text/html' => 
            [
            '<html[^>]*>',
            '<HTML[^>]*>',
            '<head[^>]*>',
            '<HEAD[^>]*>',
            '<body[^>]*>',
            '<BODY[^>]*>',
            '<title[^>]*>',
            '<TITLE[^>]*>',
            '<h1[^>]*>',
            '<H1[^>]*>',
            ],
        'text/x-roff' => 
            [
            "^\\.SH",
            "^\\.PP",
            "^\\.TH",
            "^\\.BR",
            "^\\.SS",
            "^\\.TP",
            "^\\.IR",
            ],
    };

    $self->{FILE_EXTS} = 
    {
    qr/\.gz$/   => 'application/x-gzip',
    qr/\.bz2$/  => 'application/x-bzip2',
    qr/\.Z$/    => 'application/x-compress',
    qr/\.txt$/  => 'text/plain',
    qr/\.html$/ => 'text/html',
    qr/\.htm$/  => 'text/html',
    };
    return( $self );
}

sub as_json
{
    my $self = shift( @_ );
    my $data = $self->{magic_data};
    my $j = JSON->new->relaxed->allow_nonref;
    my $json = $j->pretty->encode( $data );
    return( $json );
}

sub check
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    my $prev  = $self->check_magic;
    $self->check_magic( 1 );
    my $io = IO::File->new( "<$file" ) || return( $self->error( "Unable to open magic file \"$file\": $!" ) );
    $io->binmode;
    $self->{magic}->{io} = $io;
    my $data = [];
    while( !$io->eof() )
    {
    	$self->read_magic_entry( $data );
    }
    $io->close();
    $self->dump( $data );
    $self->check_magic( $prev );
    return( $self );
}

sub check_magic { return( shift->_set_get_boolean( 'check_magic', @_ ) ); }

sub data 
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $type = '';
    
    if( length( $data ) <= 0 )
    {
        return( $self->{default_type} ? 'application/octet-stream' : '' );
    }
    
    $type = $self->with_magic( $data );
    
    ## 4) Check if it's text or binary.
    ## If it's text, then do a bunch of searching for special tokens
    if( !defined( $type ) ) 
    {
        $type = $self->with_data( $data );
    }
    if( !defined( $type ) )
    {
        $type = $self->{default_type} ? 'text/plain' : '';
    }
    return( $type );
}

sub default_type { return( shift->_set_get_scalar( 'default_type', @_ ) ); }

## Recursively write the magic file to stderr.
## Numbers are written in decimal.
sub dump
{
    my $self  = shift( @_ );
    my $data  = shift( @_ ) || $self->{magic_data};
    my $depth = shift( @_ );
    $data  = [] unless( defined( $data ) );
    $depth = 0 unless( defined( $depth ) );
    our $err = IO::File->new;
    $err->autoflush( 1 );
    $err->fdopen( fileno( STDERR ), 'w' ) || return( $self->error( "Cannot write to STDERR: $!" ) );
    $err->binmode;

    $self->messagef( 3, "There are %d entries in \$data", scalar( @$data ) );
    foreach my $entry ( @$data )
    {
        ## Delayed evaluation.
        $entry = $self->parse_magic_line( @$entry ) if( scalar( @$entry ) == 3 );
        next if( !defined( $entry ) );
        my( $offtype, $offset, $numbytes, $type, $mask, $op, $testval, $template, $message, $subtests ) = @$entry;
        $err->print( '>' x $depth );
        if( $offtype == 1 ) 
        {
            $offset->[2] =~ tr/c/b/;
            $err->printf( "(%s.%s%s)", $offset->[0], $offset->[2], $offset->[3] );
        }
        elsif( $offtype == 2 ) 
        {
            $err->print( "&", $offset );
        }
        else 
        {
            ## offtype == 0
            $err->print( $offset );
        }
        $err->print( "\t", $type );
        if( $mask ) 
        {
            $err->print( "&", $mask );
        }
        $err->print( "\t", $op, $testval, "\t", $message, "\n" );
    
        if( $subtests ) 
        {
            $self->dump( $subtests, $depth + 1 );
        }
    }
}

sub error_returns_undef { return( shift->_set_get_boolean( 'error_returns_undef', @_ ) ); }

sub file 
{
    my $self = shift( @_ );
    ## Iterate over each file explicitly so we can seek
    my $file = shift( @_ ) || do
    {
        if( $self->{error_returns_undef} )
        {
            return( $self->error( "Missing file arguement. Usage: \$magic->file( \$some_file_name )" ) );
        }
        else
        {
            $desc .= "no file provided.";
            return( "x-system/x-error; $desc" );
        }
    };
    ## The description line. append info to this string
    my $desc = '';
    my $type = '';
    
    ## No need to let everybody know what is our server file system
    my $base_file = File::Basename::basename( $file );
    ## 0) Check existence
    if( !-e( $file ) )
    {
        if( $self->{error_returns_undef} )
        {
            return( $self->error( "File $file does not exist." ) );
        }
        else
        {
            $desc .= "file '$file' does not exist.";
            return( "x-system/x-error; $desc" );
        }
    }
    ## 1) Check permission
    elsif( !-r( $file ) ) 
    {
        if( $self->{error_returns_undef} )
        {
            return( $self->error( "Unable to read file '$file'; lacking permission" ) );
        }
        else
        {
            $desc .= "unable to read '$base_file': Permission denied.";
            return( "x-system/x-error; $desc" );
        }
    }
    
    ## 2) Check for various special files first
    if( $self->follow_links ) 
    {
        CORE::stat( $file ); 
    } 
    else 
    {
        CORE::lstat( $file );
    }
    ## Avoid doing many useless redondant system stat, use '_'. See perlfunc man page
    if( !-f( _ ) || -z( _ ) ) 
    {
        if( !$self->follow_links && -l( _ ) ) 
        { 
            #$desc .= " symbolic link to ". readlink( $file );
            return( 'application/x-link' );
        }
        elsif( -d( _ ) ) { return( 'application/x-directory' ); }
        ## Named pipe
        elsif( -p( _ ) ) { return( 'application/x-pipe' ); }
        elsif( -S( _ ) ) { return( 'application/x-socket' ); }
        ## Block special file
        elsif( -b( _ ) ) { return( 'application/x-block' ); }
        ## Character special file
        elsif( -c( _ ) ) { return( 'application/x-character' ); }
        elsif( -z( _ ) ) { return( 'application/x-empty' ); }
        else 
        {
            return( $self->{default_type} ? $self->{default_type} : 'application/x-unknown' );
        }
    }
    
    ## Current file handle. or undef if check_magic (-c option) is true.
    $self->message( 3, "Opening file \"$file\" to have a peek." );
    my $io;
    $io = IO::File->new( "<$file" ) || do
    {
        if( $self->{error_returns_undef} )
        {
            return( $self->error( "Unable to open file '$file': $!" ) );
        }
        else
        {
            return( "x-system/x-error; $base_file: $!" );
        }
    };
    $io->binmode;
    
    ## 3) Check for script
    ## if( ( -x( $file ) || ( $^O =~ /^(dos|mswin32|NetWare|symbian|win32)$/i && $file =~ /\.(?:pl|cgi)$/ ) ) && 
#     if( ( -x( $file ) || $file =~ /\.(?:cgi|pl|t)$/ ) && 
#         -T( _ ) ) 
    my $default;
    if( -x( $file ) && -T( _ ) ) 
    {
        ## Note, some magic files include elaborate attempts to match #! header lines 
        ## and return pretty responses but this slows down matching and is unnecessary.
        my $line1 = $io->getline;
        if( $line1 =~ /^\#![[:blank:]\h]*(\S+)/ ) 
        {
            ## Returns the binary name, without file path
            my $bin_name = File::Basename::basename( $1 );
            #$desc .= " executable $bin_name script text";
            ## $io->close;
            ## return( "text/x-${bin_name}" );
            $default = "text/x-${bin_name}";
        }
    }
    $self->message( 3, "Using file data to find content-type for file '$file'." );
    ## $self->messagef( 3, "There are %d entries in \$self->{magic_data}", scalar( @{$self->{magic_data}} ) );
    my $out = $self->handle( $io, $desc, { default => $default } );
    $io->close;
    return( $out );
}

sub follow_links { return( shift->_set_get_boolean( 'follow_links', @_ ) ); }

sub handle 
{
    my $self = shift( @_ );
    my $io = shift( @_ );
    my $desc = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{default} = $self->default_type if( !length( $opts->{default} ) );
    my $type = '';
    
    ## $self->message( 5, "Is file handle '$io' active ? ", ( Scalar::Util::blessed( $io ) && $io->opened ) ? 'Yes' : 'No' );
    ## 3) Iterate over each magic entry.
    my $match_found = 0;
    ## $self->messagef( 3, "\$self->{magic_data} contains %d entries.", scalar( @{$self->{magic_data}} ) );
    for( my $m = 0; $m <= $#{ $self->{magic_data} }; $m++ ) 
    {
        ## Check if the m-th magic entry matches and if it does, then $desc will contain 
        ## an updated description
        ## $self->message( 5, "Checking entry $m: (", scalar( @{$self->{magic_data}->[$m]} ), " elements)" ) if( scalar( @{$self->{magic_data}->[$m]} ) );
        my $test;
        if( ( $test = $self->_magic_match( $self->{magic_data}->[$m], \$desc, $io ) ) ) 
        {
            ## $self->message( 4, "Found entry at position '$m'\n" );
            if( defined( $desc ) && $desc ne '' ) 
            {
                $match_found = 1;
                $type = $desc;
                last;
            }
        }
        elsif( !defined( $test ) )
        {
            warnings::warn( "Error occurred while checking for match: ", $self->error ) if( warnings::enabled() && $self->debug );
        }
    
        ## Read another entry from the magic file if we've exhausted all the entries 
        ## already buffered. read_magic_entry will add to the end of the array 
        ## if there are more.
        if( $m == $#{ $self->{magic_data} } &&
            $self->{magic}->{io} && 
            !$self->{magic}->{io}->eof )
        {
            $self->read_magic_entry();
            #$self->message( 4, "\$self->{magic_data} is now %d items big.\n", scalar( @{$self->{magic_data}} ) );
        }
    }
    
    ## 4) Check if it's text or binary.
    ## if It's text, then do a bunch of searching for special tokens
    if( !$match_found ) 
    {
        my $data = '';
        $io->seek( 0, 0 );
        $io->read( $data, 0x8564 );
        $type = $self->with_data( $data );
    }
    if( !defined( $type ) )
    {
        $type = $opts->{default} ? $opts->{default} : '';
    }
    return( $type );
}

sub parse_magic_file 
{
    my $self = shift( @_ );
    my $io   = shift( @_ );
    ##----{ Initialize values
    $self->{magic}->{io}     = $io;
    $self->{magic}->{buffer} = undef();
    $self->{magic}->{count}  = 0;
    while( !$io->eof() )
    {
        $self->read_magic_entry();
    }
    seek( $io, 0, 0 );
}

## parse_magic_line( $line, $line_num, $subtests )
##
## Parses the match info out of $line.  Returns a reference to an array.
##
##  Format is:
##
## [ offset, bytes, type, mask, operator, testval, template, sprintf, subtests ]
##     0      1      2       3        4         5        6        7      8
##
## subtests is an array like @$data.
sub parse_magic_line 
{
    my $self = shift( @_ );
    my( $line, $line_num, $subtests ) = @_;
    my( $offtype, $offset, $numbytes, $type, $mask, $operator, $testval, $template, $message );
    
    ## This would be easier if escaped whitespace wasn't allowed.
    
    ## Grab the offset and type.  offset can either be a decimal, oct, or hex offset or 
    ## an indirect offset specified in parenthesis like (x[.[bsl]][+-][y]), or a relative 
    ## offset specified by &. offtype : 0 = absolute, 1 = indirect, 2 = relative
    if( $line =~ s/^>*([&\(]?[a-flsx\.\+\-\d]+\)?)[[:blank:]\h]+(\S+)[[:blank:]\h]+// ) 
    {
        ( $offset, $type ) = ( $1, $2 );
        if( $offset =~ /^\(/ ) 
        {
            ## Indirect offset.
            $offtype = 1;
            ## Store as a reference [ offset1 type template offset2 ]
            my( $o1, $type, $o2 );
            if( ( $o1, $type, $o2 ) = ( $offset =~ /\((\d+)(\.[bsl])?([\+\-]?\d+)?\)/ ) )
            {
                $o1 = oct( $o1 ) if( $o1 =~ /^0/o );
                $o2 = oct( $o2 ) if( $o2 =~ /^0/o );
        
                $type =~ s/\.//;
                ## Default to long
                $type = 'l' if( $type eq '' );
                ## Type will be template for unpack
                $type =~ tr/b/c/;
                ## Number of bytes
                my $sz = $type;
                $sz =~ tr/csl/124/;
        
                $offset = [ $o1, $sz, $type, int( $o2 ) ];
            } 
            else 
            {
                return( $self->error( "Bad indirect offset at line $line_num. '$offset'" ) );
            }
        }
        elsif( $offset =~ /^&/o ) 
        {
            ## Relative offset
            $offtype = 2;
        
            $offset = substr( $offset, 1 );
            $offset = oct( $offset ) if( $offset =~ /^0/o );
        }
        else 
        {
            ## Mormal absolute offset
            $offtype = 0;
        
            ## Convert if needed
            $offset = oct( $offset ) if( $offset =~ /^0/o );
        }
    }
    else 
    {
        return( $self->error( "Bad Offset/Type at line $line_num. '$line'" ) );
    }
    
    ## Check for & operator on type
    if( $type =~ s/&(.*)// ) 
    {
        $mask = $1;
        ## Convert if needed
        $mask = oct( $mask ) if( $mask =~ /^0/o );
    }
    
    ## Check if type is valid
    if( !exists( $TEMPLATES->{ $type } ) ) 
    {
        return( $self->error( "Invalid type '$type' at line $line_num" ) );
    }
    
    ## Take everything after the first non-escaped space
    if( $line =~ s/([^\\])\s+(.*)/$1/ ) 
    {
        $message = $2;
    }
    else 
    {
        return( $self->error( "Missing or invalid test condition/message at line $line_num" ) );
    }
    
    ## Remove the return if it is still there
    $line =~ s/\n$//o;

    ## Get the operator. If 'x', must be alone. Default is '='.
    if( $line =~ s/^([><&^=!])//o ) 
    {
        $operator = $1;
    }
    elsif( $line eq 'x' ) 
    {
        $operator = 'x';
    }
    else
    {
        $operator = '=';
    }
    
    if( $type eq 'string' ) 
    {
        $testval = $line;
    
        ## Do octal/hex conversion
        $testval =~ s/\\([x0-7][0-7]?[0-7]?)/chr( oct( $1 ) )/eg;
    
        ## Do single char escapes
        $testval =~ s/\\(.)/$ESC->{ $1 }||$1/eg;
    
        ## Put the number of bytes to read in numbytes.
        ## '0' means read to \0 or \n.
        if( $operator =~ /[>x]/o ) 
        {
            $numbytes = 0;
        }
        elsif( $operator =~ /[=<]/o ) 
        {
            $numbytes = length( $testval );
        }
        elsif( $operator eq '!' )
        {
            ## Annoying special case. ! operator only applies to numerics so put it back.
            $testval  = $operator . $testval;
            $numbytes = length( $testval );
            $operator = '=';
        }
        else 
        {
            ## There's a bug in my magic file where there's a line that says
            ## "0    string    ^!<arc..." and the BSD file program treats the argument 
            ## like a numeric. To minimize hassles, complain about bad ops only if -c is set.
            return( $self->error( "Invalid operator '$operator' for type 'string' at line $line_num." ) );
        }
    }
    else 
    {
        ## Numeric
        if( $operator ne 'x' ) 
        {
            ## This conversion is very forgiving. Tt's faster and it doesn't complain 
            ## about bugs in popular magic files, but it will silently turn a string into zero.
            if( $line =~ /^0/o ) 
            {
                $testval = oct( $line );
            } 
            else 
            {
                $testval = int( $line );
            }
        }
    
        ( $template, $numbytes ) = @{$TEMPLATES->{ $type }};
    
        ## Unset coercion of $unsigned unless we're doing order comparison
        if( ref( $template ) ) 
        {
            $template = $template->[0] unless( $operator eq '>' || $operator eq '<' );
        }
    }
    return( [ $offtype, $offset, $numbytes, $type, $mask, $operator, $testval, $template, $message, $subtests ] );
}

## read_magic_entry( $magic_data, $depth )
##
## Reads the next entry from the magic file and stores it as a ref to an array at the 
## end of @$magic_data.
##
## $magic = { filehandle, last buffered line, line count }
##
## This is called recursively with increasing $depth to read in sub-clauses
##
## Returns the depth of the current buffered line.
sub read_magic_entry 
{
    my $self  = shift( @_ );
    my $data  = shift( @_ ) || $self->{magic_data};
    my $depth = shift( @_ );
    my $magic = $self->{magic};
    
    my $io = $magic->{io};
    ## A ref to an array containing a magic line's components
    my $entry = [];
    my $line  = '';
    
    ## Buffered last line
    $line = $magic->{buffer};
    while( 1 ) 
    {
        $line = '' if( !defined( $line ) );
        if( $line =~ /^\#/ || $line =~ /^[[:blank:]\h]*$/ ) 
        {
            #$self->message( 4, "Line is a comment or is empty." );
            last if( $io->eof );
            $line = <$io>;
            $magic->{count}++;
            next;
        }
    
        my $this_depth = ( $line =~ /^(>+)/ )[0];
        $this_depth    = '' if( !defined( $this_depth ) );
        $depth         = 0 if( !defined( $depth ) );
    
        $self->message( 4, "\$this_depth ($this_depth), \$depth ($depth)" );
        if( length( $this_depth ) > $depth ) 
        {
            $magic->{buffer} = $line;
        
            ## Call ourselves recursively.  will return the depth of the entry following 
            ## the nested group.
            if( $self->read_magic_entry( $entry->[2], $depth + 1 ) < $depth || 
                $io->eof )
            {
                $self->message( 4, "\$this_depth is greater than \$depth. Returning nothing" );
                return;
            }
            $line = $magic->{buffer};
        }
        elsif( length( $this_depth ) < $depth ) 
        {
            $magic->{buffer} = $line;
            $self->message( 4, "\$this_depth is less than \$depth. Returning length( \$this_depth )" );
            return( length( $this_depth ) );
        }
        elsif( @$entry ) 
        {
            $self->message( 4, "\@\$entry is defined. Returning length( \$this_depth )" );
            ## Already have an entry. This is not a continuation. Save this line for the 
            ## next call and exit.
            $magic->{buffer} = $line;
            return( length( $this_depth ) );
        }
        else 
        {
            $self->message( 4, "Other: Setting \$entry and adding it to \@\$data. Ending loop (possibly). Fetching line" );
            ## We're here if the number of '>' is the same as the current depth and we 
            ## haven't read a magic line yet.

            ## Create temp entry later, if we ever get around to evaluating this condition,
            ## we'll replace @$entry with the results from parse_magic_line.
            $entry = [ $line , $magic->{count}, [] ];

            ## Add to list
            push( @$data, $entry );

            ## Read the next line
            $self->message( 4, "We reached end of file $io->eof()\n" ) if( $io->eof() );
            last if( $io->eof() );
            $line = <$io>;
            my $tmp = $line;
            $tmp =~ s/\n$//gs;
            $self->message( 4, "(2) Fetched line '$tmp'\n" );
            $magic->{count}++;
        }
        ## print( STDERR "$line" );
    }
}

sub with_magic 
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $desc = '';
    my $type = '';
    
    return( 'application/octet-stream' ) if( length( $data ) <= 0 );
    
    ## 3) Iterate over each magic entry.
    for( my $m = 0; $m <= $#{ $self->{magic_data} }; $m++ ) 
    {
        ## Check if the m-th magic entry matches and if it does, then $desc will contain 
        ## an updated description
        if( $self->_magic_match_str( $self->{magic_data}->[ $m ], \$desc, $data ) ) 
        {
            if( defined( $desc ) && $desc ne '' ) 
            {
                $type = $desc;
                last;
            }
        }
    
        ## Read another entry from the magic file if we've exhausted all the entries 
        ## already buffered. read_magic_entry will add to the end of the array if 
        ## there are more.
        if( $m == $#{ $self->{magic_data} } && !$self->{magic}->{io}->eof() )
        {
            $self->read_magic_entry();
        }
    }
    return( $type );
}

sub with_data 
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $type = undef();
    
    return if( length( $data ) <= 0 );
    
    ## Truncate data
    $data = substr( $data, 0, 0x8564 );
    
    if( _is_binary( $data ) ) 
    {
        $type = 'application/octet-stream';
    } 
    else 
    {
        ## In BSD's version, there's an effort to search from more specific to less, 
        ## but I don't do that.
        my( $token, %val );
        foreach my $type ( keys( %{$self->{SPECIALS}} ) ) 
        {
            my $token = '(' . ( join( '|', sort{ length( $a ) <=> length( $b ) } @{$self->{SPECIALS}->{ $type } } ) ) . ')';
            my $tdata = $data;
            if( $tdata =~ /$token/mg ) 
            {
                $val{ $type } = pos( $tdata );
            }
        }
        ## Search latest match
        if( scalar( keys( %val ) ) )
        {
            my @skeys = sort{ $val{ $a } <=> $val{ $b } } keys( %val );
            $type = $skeys[0];
        }
    
        ## ALLDONE:
        ## $type = 'text/plain' if( !defined( $type ) );
    }
    ## $type = 'text/plain' if( !defined( $type ) );
    return( $type );
}

sub with_filename 
{
    my $self  = shift( @_ );
    my $fname = shift( @_ );
    my $type  = '';
    
    my $file = $fname;
    $fname =~ s/^.*\///;
    for my $regex ( keys( %{$self->{FILE_EXTS}} ) )
    {
        if( $fname =~ /$regex/i ) 
        {
            if( ( defined( $type ) && $type !~ /;/ ) || 
                !defined( $type ) ) 
            {
                ## has no x-type param
                $type = $self->{FILE_EXTS}->{ $regex };
            }
        }
    }
    return( $type );
}

sub _is_binary 
{
    my( $data ) = @_;
    my $len = length( $data );
    ## Exclude TAB, ESC, nl, cr
    my $count = ( $data =~ tr/[\x00-\x08\x0b-\x0c\x0e-\x1a\x1c-\x1f]// );
    ## No contents
    return( 1 ) if( $len <= 0 );
    ## Binary
    return( 1 ) if( ( $count / $len ) > 0.1 );
    return( 0 );
}

## Compare the magic item with the filehandle.
## If success, print info and return true, otherwise return undef.
##
## This is called recursively if an item has subitems.
sub _magic_match
{
    my $self = shift( @_ );
    ## $io is the file handle of the file being inspected
    my( $item, $p_desc, $io ) = @_;
    
    ## Delayed evaluation. If this is our first time considering this item, then parse out 
    ## its structure. @$item is just the raw string, line number, and subtests until we 
    ## need the real info. This saves time otherwise wasted parsing unused subtests.
    $item = $self->parse_magic_line( @$item ) if( @$item == 3 );
    
    ## $item could be undef if we ran into troubles while reading the entry.
    return unless( defined( $item ) );
    
    ## $io is not defined if -c. That way we always return false for every item which 
    ## allows reading/checking the entire magic file.
    return( $self->error( "File handle is not defined." ) ) unless( defined( $io ) );
    ## return unless( defined( fileno( $io ) ) );
    # $self->message( 3, "Is file handle '$io' active ? (", Scalar::Util::openhandle( $io ) ? 'yes' : 'no', ")." );
    # return unless( Scalar::Util::openhandle( $io ) );
    # $self->message( 3, "Is file handle '$io' active ? (", ( defined( $io ) && $io->opened ) ? 'yes' : 'no', ")." );
    
    my( $offtype, $offset, $numbytes, $type, $mask, $op, $testval, $template, $message, $subtests ) = @$item;
    ## $self->message( 5, "Checking item for description $$p_desc: ", sub{ $self->SUPER::dump( $item ) }) if( scalar( @$item ) );
    $self->{trick}++;
    if( $self->{trick} > 186 && $self->{trick} < 192 )
    {
        ## $self->message( 4, "$item\n" );
        my $c = -1;
        ## $self->message( 4, join( "\n", map{ sprintf( "%s: %s", $_, $item->[ ++$c ] ) } qw( offtype offset numbytes type mask op testval template message subtests ) ), "\n--------\n" );
    }
    ## Bytes from file
    my $data = '';

    ## Set to true if match
    my $match = 0;
    
    ## offset = [ off1, sz, template, off2 ] for indirect offset
    if( $offtype == 1 ) 
    {
        my( $off1, $sz, $template, $off2 ) = @$offset;
        $io->seek( $off1, 0 ) || return( $self->error( "Unable to seek to offset $off1 in file" ) );
        # return( $self->error( "Unable to read $sz bytes of data from file. Buffer is only ", length( $data ), " bytes." ) ) if( $io->read( $data, $sz ) != $sz );
        return if( $io->read( $data, $sz ) != $sz );
        $off2 += unpack( $template, $data );
        $io->seek( $off2, 0 ) || return( $self->error( "Unable to seek to offset $off2 in file." ) );
    }
    elsif( $offtype == 2 ) 
    {
        ## Relative offsets from previous seek
        $io->seek( $offset, 1 ) || return( $self->error( "Unable to seek to offset $offset in file" ) );
    }
    else 
    {
        ## Absolute offset
        $io->seek( $offset, 0 ) || return( $self->error( "Unable to seek to offset $offset in file" ) );
    }
    
    if( $type eq 'string' ) 
    {
        ## Read the length of the match string unless the comparison is 
        ## '>' ($numbytes == 0), in which case read to the next null or "\n".
        ## (that's what BSD's file does)
        if( $numbytes > 0 ) 
        {
            # return( $self->error( "Unable to read $numbytes bytes of data from file. Buffer is only ", length( $data ), " bytes." ) ) if( $io->read( $data, $numbytes ) != $numbytes );
            return if( $io->read( $data, $numbytes ) != $numbytes );
            ## $self->message( 5, "Data now contains '$data'." );
        }
        else 
        {
            my $ch = $io->getc();
            while( defined( $ch ) && $ch ne "\0" && $ch ne "\n" ) 
            {
                $data .= $ch;
                $ch = $io->getc();
            }
        }
        ## $self->message( 4, "Checking data '$data' against test value '$testval'\n" );
    
        ## Now do the comparison
        if( $op eq '=' ) 
        {
            $match = ( $data eq $testval );
        }
        elsif( $op eq '<' ) 
        {
            $match = ( $data lt $testval );
        }
        elsif( $op eq '>' )
        {
            $match = ( $data gt $testval );
        }
        ## Else bogus op, but don't die, just skip
        if( $self->check_magic ) 
        {
            print( STDERR "STRING: $data $op $testval => $match\n" );
        }
    }
    else 
    {
        ## Numeric
        ## Read up to 4 bytes
        # return( $self->error( "Unable to read $numbytes bytes of data from file. Buffer is only ", length( $data ), " bytes." ) ) if( $io->read( $data, $numbytes ) != $numbytes );
        return if( $io->read( $data, $numbytes ) != $numbytes );
    
        ## If template is a ref to an array of 3 letters, then this is an endian number
        ## which must be first unpacked into an unsigned and then coerced into a signed.
        ## Is there a better way?
        if( ref( $template ) ) 
        {
            $data = unpack( $template->[2], pack( $template->[1], unpack( $template->[0], $data ) ) );
        }
        else 
        {
            $data = unpack( $template, $data );
        }
    
        ## If mask
        if( defined( $mask ) ) 
        {
            $data &= $mask;
        }
    
        ## Now do the check
        if( $op eq '=' ) 
        {
            $match = ( $data == $testval );
        }
        elsif( $op eq 'x' )
        {
            $match = 1;
        }
        elsif( $op eq '!' ) 
        {
            $match = ( $data != $testval );
        }
        elsif( $op eq '&' )
        {
            $match = ( ( $data & $testval ) == $testval );
        }
        elsif( $op eq '^' )
        {
            $match = ( ( ~$data & $testval ) == $testval );
        }
        elsif( $op eq '<' )
        {
            $match = ( $data < $testval );
        }
        elsif( $op eq '>' ) 
        {
            $match = ( $data > $testval );
        }
        ## Else bogus entry that we're ignoring
        if( $self->check_magic ) 
        {
            print( STDERR "NUMERIC: $data $op $testval => $match\n" );
        }
    }
    
    if( $match ) 
    {
        ## It's pretty common to find "\b" in the message, but sprintf doesn't insert a 
        ## backspace. If it's at the beginning (typical) then don't include separator space.
        if( $message =~ s/^\\b// ) 
        {
            $$p_desc .= ( index( $message, '%s' ) != -1 ? sprintf( $message, $data ) : $message );
        }
        else 
        {
            ## $$p_desc .= ' ' . sprintf( $message, $data ) if( $message );
            $$p_desc .= ( index( $message, '%s' ) != -1 ? sprintf( $message, $data ) : $message ) if( $message );
        }
    
        foreach my $subtest ( @$subtests ) 
        {
            $self->_magic_match( $subtest, $p_desc, $io );
        }
        return( 1 );
    }
}

sub _magic_match_str 
{
    my $self = shift( @_ );
    my( $item, $p_desc, $str ) = @_;
    my $origstr = $str;
    
    ## Delayed evaluation. If this is our first time considering this item, then parse out 
    ## its structure. @$item is just the raw string, line number, and subtests until we 
    ## need the real info. This saves time otherwise wasted parsing unused subtests.
    $item = $self->parse_magic_line( @$item ) if( @$item == 3 );
    
    ## $item could be undef if we ran into troubles while reading the entry.
    return unless( defined( $item ) );
    
    ## $fh is not be defined if -c. That way we always return false for every item which 
    ## allows reading/checking the entire magic file.
    return unless( defined( $str ) );
    return if( $str eq '' );
    
    my( $offtype, $offset, $numbytes, $type, $mask, $op, $testval, $template, $message, $subtests ) = @$item;
    return unless( defined( $op ) );
    
    ## Bytes from file
    my $data = '';
    
    ## Set to true if match
    my $match = 0;
    
    ## offset = [ off1, sz, template, off2 ] for indirect offset
    if( $offtype == 1 ) 
    {
        my( $off1, $sz, $template, $off2 ) = @$offset;
        return if( length( $str ) < $off1 );
        $data  = pack( "a$sz", $str );
        $off2 += unpack( $template, $data );
        return if( length( $str ) < $off2 );
    }
    elsif( $offtype == 2 ) 
    {
        ## Unable to handle relative offsets from previous seek
        return;
    }
    else 
    {
        ## Absolute offset
        return if( $offset > length( $str ) );
        $str = substr( $str, $offset );
    }
    
    if( $type eq 'string' ) 
    {
        ## Read the length of the match string unless the comparison is 
        ## '>' ($numbytes == 0), in which case read to the next null or "\n".
        ## (that's what BSD's file does)
        if( $numbytes > 0 ) 
        {
            $data = pack( "a$numbytes", $str );
        }
        else 
        {
            $str =~ /^(.*)\0|$/;
            $data = $1;
        }

        ## Now do the comparison
        if( $op eq '=' ) 
        {
            $match = ( $data eq $testval );
        }
        elsif( $op eq '<' )
        {
            $match = ( $data lt $testval );
        }
        elsif( $op eq '>' )
        {
            $match = ( $data gt $testval );
        }
        ## Else bogus op, but don't die, just skip
    
        if( $self->check_magic ) 
        {
            print( STDERR "STRING: $data $op $testval => $match\n" );
        }
    }
    else 
    {
        ## Numeric
        ## Read up to 4 bytes
        $data = substr( $str, 0, 4 );
    
        ## If template is a ref to an array of 3 letters, then this is an endian number 
        ## which must be first unpacked into an unsigned and then coerced into a signed.
        ## Is there a better way?
        if( ref( $template ) ) 
        {
            $data = unpack( $template->[2], pack( $template->[1], unpack( $template->[0], $data ) ) );
        }
        else 
        {
            $data = unpack( $template, $data );
        }
    
        ## If mask
        if( defined( $mask ) ) 
        {
            $data &= $mask;
        }
    
        ## Now do the check
        if( $op eq '=' ) 
        {
            $match = ( $data == $testval );
        }
        elsif( $op eq 'x' )
        {
            $match = 1;
        }
        elsif( $op eq '!' )
        {
            $match = ( $data != $testval );
        }
        elsif( $op eq '&' )
        {
            $match = ( ( $data & $testval ) == $testval );
        }
        elsif( $op eq '^' )
        {
            $match = ( ( ~$data & $testval ) == $testval );
        }
        elsif( $op eq '<' )
        {
            $match = ( $data < $testval );
        }
        elsif( $op eq '>' )
        {
            $match = ( $data > $testval );
        }
        ## else bogus entry that we're ignoring
        if( $self->check_magic ) 
        {
            print( STDERR "NUMERIC: $data $op $testval => $match\n" );
        }
    }
    
    if( $match ) 
    {
        ## It's pretty common to find "\b" in the message, but sprintf doesn't insert a
        ## backspace. If it's at the beginning (typical) then don't include separator space.
        if( $message =~ s/^\\b// ) 
        {
            $$p_desc .= sprintf( $message, $data );
        }
        else 
        {
            ## $$p_desc .= ' ' . sprintf( $message, $data ) if( $message );
            $$p_desc .= sprintf( $message, $data ) if( $message );
        }
        foreach my $subtest ( @$subtests ) 
        {
            ## Finish evaluation when matched.
            $self->_magic_match_str( $subtest, $p_desc, $origstr );
        }
        return( 1 );
    }
}

## Obsolete routines
sub add_specials 
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    $self->{SPECIALS}->{ $type } = [ @_ ];
    return( $self );
}

sub add_file_exts 
{
    my $self    = shift( @_ );
    my $filepat = shift( @_ );
    my $type    = shift( @_ );
    $self->{FILE_EXTS}->{ $filepat } = $type;
    return( $self );
}

sub add_magic_entry 
{
    my $self  = shift( @_ );
    my $entry = shift( @_ );
    unshift( @{$self->{magic_data}}, [ $entry, -1, [] ] );
    return( $self );
}

1;

__END__

=head1 NAME

Apache2::SSI::File::Type - Guess file MIME Type using Magic

=head1 SYNOPSIS

    use Apache2::SSI::File::Type;
    
    # use internal magic data; no outside dependencies
    my $m = Apache2::SSI::File::Type->new;
    # use external magic file
    # my $m = Apache2::SSI::File::Type->new( '/etc/apache2/magic' );
    my $mime_type = $m->file( "/somewhere/unknown/file" );
    # or, on windows
    my $mime_type = $m->file( "C:\Documents\myfile.cgi" );
    # using a file handle works too
    my $io = IO::File->new( "</somewhere/unknown/file2" );
    my $mime_type = $m->handle( $io );
    
    $io->read( $data, 0x8564 );
    my $mime_type = $m->data( $data );

=head1 DESCRIPTION

This module emulates the functionnality of L<file(1)> unix utility cross platform, and returns the file MIME type.

It can guess it from a file name, data or file handle using methods described below.

It does not depend upon an external application to function.

=head1 CONSTRUCTOR

=over 4

=item B<new>( [ "/some/where/file.cgi" ] )

Creates a new L<Apache2::SSI::File::Type> object and returns it.
If a file is provided, L<Apache2::SSI::File::Type> will use it instead of its default internal data.

If it can not open it or read it, it will set an error object and return undef. See L<Module::Generic/error> for more information.

The result of the parsing of the given file is cached as a json file in the system's temporary folder, wherever that is. The location is provided by L<File::Spec/tmpdir>

The internal magic data is provided internally from a json data file located in the same place as this module.

=back

=head1 METHODS

=head2 as_json

This returns the internal magic data as a properly formatted json string using L<JSON>.

This is used to create cache of magic files.

=head2 check( "/etc/apache2/magic" )

Checks the magic file provided and dumps it on the STDERR.

This is equivalent to option C<-c> of L<file(1)>.

=head2 check_magic

Set or gets the boolean value used to decide whether the magic data are checked.

=head2 data( $some_data )

Guess the mime type based upon the data provided with C<$some_data> and returns it.

If C<$some_data> is zero length big, it will return C<application/x-empty>.

Otherwise, it defaults to the value set with L</default_type>, which, by default, is I<text/plain> if L</default_type> is set to a true value or an empty value otherwise.

=head2 default_type

Set the default mime type to be returned as default, if any at all. If this is empty, it will default to C<text/plain> by default.

If it iset to a true value, it will return that value or text/plain if it is set to empty string otherwise.

=head2 dump

Provided with an optional data as an array reference, or if nothing is provided, the internal magic data and this will print it out as a properly formatted magic file suitable to be re-used.

For example on your command line interface:
    
    # my_script.pl file:
    #/usr/bin/perl
    BEGIN
    {
        use strict;
        use warnings;
        use Apache2::SSI::File::Type;
    };
    
    my $m = Apache2::SSI::File::Type->new;
    $m->dump;
    exit;
    
    # on the command line:
    ./my_script.pl 2>my_magic

=head2 error_returns_undef

Sets or gets the boolean value to decide whether this module will return a default value (see L</default_type>) or C<undef> when there is an error.

By default this is set to false, and the module will return a default value upon error.

=head2 file( '/some/file/path.txt' )

Provided with a file and this will guess its mim type.

If an error occurs, and if L</error_returns_undef> is set to true, it will return C<x-system/x-error; description>
where description is the description of the error, otherwise it will set an error object with the error string and return C<undef>. See L<Module::Generic/error> for more information about the error object.

If the file to check is not a regular file or is empty, it will call L<perlfunc/stat> and it will try hard to find its mime type.

Otherwise, it defaults to the value set with L</default_type>.

=head2 follow_links

Provided with a boolean value, this sets whether links should be followed.

Default to true.

=head2 handle

Provided with an opened file handle and this method will try to guess the mime type and returns it.

It defaults to whatever value is set with L</default_type>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 CREDITS

Credits Nokubi Takatsugu.

=head1 SEE ALSO

L<file(1)>

L<Apache2::SSI>, L<Apache2::SSI::File>, L<Apache2::SSI::Finfo>, L<Apache2::SSI::URI>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
