# NAME

    Data::Tools provides set of basic functions for data manipulation.

# SYNOPSIS

    use Data::Tools qw( :all );  # import all functions
    use Data::Tools;             # the same as :all :)
    use Data::Tools qw( :none ); # do not import anything, use full package names

    # --------------------------------------------------------------------------

    # these set the encoding used by the file_text_* functions only:

    data_tools_set_text_io_encoding( 'UTF-8' ); # file_text_* io will use UTF-8
    data_tools_set_text_io_utf8();              # the same, shortcut
    data_tools_set_text_io_bin();               # file_text_* io will use binary data

    my $res  = file_save( $file_name, 'file content here' );
    my $data = file_load( $file_name );

    my $data_arrayref = file_load_ar( $file_name );

    # for specific charset encoding and because of backward compatibility:

    my $res  = file_save( { FILE_NAME => $file_name, ENCODING => 'UTF-8' }, 'data' );
    my $data = file_load( { FILE_NAME => $file_name, ENCODING => 'UTF-8' } );

    my $data_arrayref = file_load_ar( { FILE_NAME => $fname, ENCODING => 'UTF-8' } );

    # ':RAW' => 1 reads/writes binary data:

    my $res  = file_save( { FILE_NAME => $file_name, ':RAW' => 1 }, $binary_data );
    my $data = file_load( { FILE_NAME => $file_name, ':RAW' => 1 } );

    # --------------------------------------------------------------------------

    my $file_modification_time_in_seconds = file_mtime( $file_name );
    my $file_change_time_in_seconds       = file_ctime( $file_name );
    my $file_last_access_time_in_seconds  = file_atime( $file_name );
    my $file_size                         = file_size(  $file_name );

    # --------------------------------------------------------------------------

    my $res  = dir_path_make( '/path/to/somewhere' ); # create full path with 0700
    my $res  = dir_path_make( '/new/path', MASK => 0755 ); # ...with mask 0755
    my $path = dir_path_ensure( '/path/s/t/h' ); # ensure path exists, check+make

    # --------------------------------------------------------------------------

    my $path_with_trailing_slash = file_path( $full_path_or_file_name );

    # file_name() and file_name_ext() return full name with leadeing
    # dot for dot-files ( .filename )
    my $file_name_including_ext  = file_name_ext( $full_path_or_file_name );
    my $file_name_only_no_ext    = file_name( $full_path_or_file_name );

    # file_ext() returns undef for dot-files ( .filename )
    my $file_ext_only            = file_ext( $full_path_or_file_name );

    # --------------------------------------------------------------------------

    # uses simple backslash escaping of \n, = and \ itself
    my $data_str = hash2str( $hash_ref ); # convert hash to string "key=value\n"
    my $hash_ref = str2hash( $hash_str ); # convert str "key-value\n" to hash

    # same as hash2str() but uses keys in certain order
    my $data_str = hash2str_keys( \%hash, sort keys %hash );
    my $data_str = hash2str_keys( \%hash, sort { $a <=> $b } keys %hash );

    # same as hash2str() and str2hash() but uses URL-style escaping
    my $data_str = hash2str_url( $hash_ref ); # convert hash to string "key=value\n"
    my $hash_ref = str2hash_url( $hash_str ); # convert str "key-value\n" to hash

    my $hash_ref = url2hash( 'key1=val1&key2=val2&testing=tralala);
    # $hash_ref will be { key1 => 'val1', key2 => 'val2', testing => 'tralala' }

    my $hash_ref_with_upper_case_keys = hash_uc( $hash_ref_with_lower_case_keys );
    my $hash_ref_with_lower_case_keys = hash_lc( $hash_ref_with_upper_case_keys );

    hash_uc_ipl( $hash_ref_to_be_converted_to_upper_case_keys );
    hash_lc_ipl( $hash_ref_to_be_converted_to_lower_case_keys );

    # save/load hash in str_url_escaped form to/from a file
    my $res      = hash_save( $file_name, $hash_ref );
    my $hash_ref = hash_load( $file_name );

    # save hash with certain keys order, uses hash2str_keys()
    my $res      = hash_save( $file_name, \%hash, sort keys %hash );

    # same as hash_save() and hash_load() but uses hash2str_url() and str2hash_url()
    my $res      = hash_save_url( $file_name, $hash_ref );
    my $hash_ref = hash_load_url( $file_name );

    # validate (nested) hash by example

    # validation example nested hash
    my $validate_hr = {
                      A => 'INT',
                      B => 'INT(-5,10)',
                      C => 'REAL',
                      D => {
                           E => 'RE:\d+[a-f]*',  # regexp match
                           F => 'REI:\d+[a-f]*', # case insensitive regexp match
                           },
                      DIR1  => '-d',   # must be existing directory
                      DIR2  => 'dir',  # must be existing directory
                      FILE1 => '-f',   # must be existing file
                      FILE2 => 'file', # must be existing file
                      };
    # actual nested hash to be verified if looks like the example
    my $data_hr     = {
                      A => '123',
                      B =>  '-1',
                      C =>  '1 234 567.89',
                      D => {
                           E => '123abc',
                           F => '456FFF',
                           },
                      }

    my @invalid_keys = hash_validate( $data_hr, $validate_hr );
    print "YES!" if hash_validate( $data_hr, $validate_hr );

    # --------------------------------------------------------------------------

    my $escaped   = str_url_escape( $plain_str ); # URL-style %XX escaping
    my $plain_str = str_url_unescape( $escaped );

    # NOTE: url (RFC 3986) is ascii only, anything else is UTF-8 bytes as %xx.
    #       str_url_escape() encodes characters (perl utf8 string) to UTF-8
    #       bytes first, a non-utf8 string is taken as bytes and escaped as it
    #       is, so UTF-8 bytes are not encoded twice. characters below 0x100 may
    #       be kept without the utf8 flag (literal "\x{e9}"), then they are bytes:
    #       str_url_escape( "\x{e9}" ) is "%E9", use utf8::upgrade() or decode()
    #       for text, then it is "%C3%A9".
    #       str_url_unescape() takes url (ascii or UTF-8 bytes) and returns
    #       characters: %xx escapes become bytes, decoded from UTF-8, invalid
    #       bytes become U+FFFD: str_url_unescape( "%D0%98" ) is "\x{418}".
    #       characters (perl utf8 string) in its input are encoded to UTF-8 bytes
    #       first, so raw text mixed with %xx escapes is kept.
    #       str_url_unescape( str_url_escape( $text ) ) returns $text.
    #       url2hash() and str2hash_url() use str_url_unescape() and return
    #       characters too.

    my $escaped   = str_html_escape( $plain_str ); # HTML-style &name; escaping
    my $plain_str = str_html_unescape( $escaped );

    my $hex_str   = str_hex( $plain_str ); # HEX-style XX string escaping
    my $plain_str = str_unhex( $hex_str );

    my $hex_str   = str_hex_utf8( $text ); # the same for text (wide chars)
    my $text      = str_unhex_utf8( $hex_str );

    # NOTE: str_hex() and str_unhex() work on bytes, i.e. unpack/pack( "H*" ):
    #       characters above 0xFF are wrapped to their low byte, so different
    #       text may give the same result: str_hex( "\x{430}\x{430}" ) and
    #       str_hex( "00" ) both return "3030". use them for binary data only.
    #       str_hex_utf8() encodes text to UTF-8 bytes first, so the result is
    #       unique per text: str_hex_utf8( "\x{430}\x{430}" ) returns "d0b0d0b0".
    #       str_unhex_utf8() decodes the bytes back to text, invalid UTF-8 bytes
    #       become U+FFFD. results differ from str_hex() for any non-ASCII text,
    #       str_hex( "\x{e9}" ) is "e9" while str_hex_utf8( "\x{e9}" ) is "c3a9".
    #       str_unhex() and str_unhex_utf8() do not check their input: odd length
    #       is padded with "0" ( "414" gives "A@" ) and non-hex characters are
    #       not rejected but silently converted to garbage bytes.

    # --------------------------------------------------------------------------

    # converts perl package names to file names, f.e: returns "Data/Tools.pm"
    my $perl_pkg_fn = perl_package_to_file( 'Data::Tools' );

    # --------------------------------------------------------------------------

    # calculating hex digests
    my $whirlpool_hex = wp_hex( $data );
    my $sha1_hex      = sha1_hex( $data );
    my $md5_hex       = md5_hex( $data );

    # --------------------------------------------------------------------------

    my $formatted_str = str_num_comma( 1234567.89 );   # returns "1'234'567.89"
    my $formatted_str = str_num_comma( 4325678, '_' ); # returns "4_325_678"
    my $padded_str    = str_pad( 'right', -12, '*' ); # returns "right*******"
    my $str_c         = str_countable( $dc, 'day', 'days' );
                        # returns 'days' for $dc == 0
                        # returns 'day'  for $dc == 1
                        # returns 'days' for $dc >  1

    my $num = str_kmg_to_num(   '1K' ); # returns 1024
    my $num = str_kmg_to_num( '2.5M' ); # returns 2621440
    my $num = str_kmg_to_num(   '1T' ); # returns 1099511627776

    # --------------------------------------------------------------------------

    # find all *.txt files in all subdirectories starting from /usr/local
    # returned files are with full path names
    my @files = glob_tree( '/usr/local/*.txt' );

    # read directory entries names (without full paths)
    my @files_and_dirs = read_dir_entries( '/tmp/secret/dir' );

    # --------------------------------------------------------------------------

    my $int   = bcd2int( $bcd_bytes ); # convert BCD byte data to integer
    my $bytes = int2bcd( $int );       # convert integer to BCD bytes
    my $str   = bcd2str( $bcd_bytes ); # convert BCD byte data to string

# FUNCTIONS

## hash\_validate( $data\_hr, $validate\_hr );

Return value can be either scalar or array context. In scalar context return
value is true (1) or false (0). In array context it returns list of the invalid
keys (possibly key paths like 'KEY1/KEY2/KEY3'):

    # array context
    my @invalid_keys = hash_validate( $data_hr, $validate_hr );

    # scalar context
    print "YES!" if hash_validate( $data_hr, $validate_hr );

# TODO

    (more docs)

# DATA::TOOLS SUB-MODULES

Data::Tools package includes several sub-modules:

    * Data::Tools::Time                (time processing)
    * Data::Tools::Math                (mathematics)
    * Data::Tools::CSV                 (compact, pure-perl CSV parsing)
    * Data::Tools::Serialization       (high-level serialization)

Since 1.60 process and socket modules are separate packages:

    * Data-Tools-Process  Data::Tools::Process, Data::Tools::Process::Forks,
                          Data::Tools::Process::ForkPool
    * Net-Tools           Net::Tools::Socket, Net::Tools::Socket::Protocols,
                          Net::Tools::Socket::Pair, Net::Tools::Socket::Err
                          (were Data::Tools::Socket*)

# REQUIRED MODULES

Data::Tools is designed to be simple, compact and self sufficient.
However it uses some 3rd party modules:

    * Digest::Whirlpool
    * Digest::MD5
    * Digest::SHA1
    * JSON

# SEE ALSO

For more complex cases of nested hash validation,
check Data::Validate::Struct module by Thomas Linden, cheers :)

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools.git

    git clone git://github.com/cade-vs/perl-data-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
# NAME

    Data::Tools::Time provides set of basic functions for time processing.

# SYNOPSIS

    use Data::Tools::Time qw( :all );  # import all functions
    use Data::Tools::Time;             # the same as :all :) 
    use Data::Tools::Time qw( :none ); # do not import anything

    # --------------------------------------------------------------------------

    my $time_diff_str     = unix_time_diff_in_words( $time1 - $time2 );
    my $time_diff_str_rel = unix_time_diff_in_words_relative( $time1 - $time2 );

    # --------------------------------------------------------------------------
      
    my $date_diff_str     = julian_date_diff_in_words( $date1 - $date2 );
    my $date_diff_str_rel = julian_date_diff_in_words_relative( $date1 - $date2 );

    # --------------------------------------------------------------------------

    # return seconds after last midnight, i.e. current day time
    my $seconds_in_the_current_day = get_local_time_only()
    
    # returns current julian day
    my $jd = get_local_julian_day()
    
    # returns current year
    my $year = get_local_year()
    
    # gets current julian date, needs Time::JulianDay
    my $jd = local_julian_day( time() );
    # or
    my $jd = get_local_julian_day();

    # move current julian date to year ago, one month ahead and 2 days ahead
    $jd = julian_date_add_ymd( $jd, -1, 1, 2 );

    # get year, month and day from julian date
    my ( $y, $m, $d ) = julian_date_to_ymd( $jd );

    # get julian date from year, month and day
    $jd = julian_date_from_ymd( $y, $m, $d );

    # move julian date ($jd) to the first day of its current month
    $jd = julian_date_goto_first_dom( $jd );

    # move julian date ($jd) to the last day of its current month
    $jd = julian_date_goto_last_dom( $jd );

    # get day of week for given julian date ( 0 => Mon .. 6 => Sun )
    my $dow = julian_date_get_dow( $jd );
    print( ( qw( Mon Tue Wed Thu Fri Sat Sun ) )[ $dow ] . "\n" );

    # get month days count for the given julian date's month
    my $mdays = julian_date_month_days( $jd );

    # get month days count for the given year and month
    my $mdays = julian_date_month_days_ym( $y, $m );

# FUNCTIONS

## unix\_time\_diff\_in\_words( $unix\_time\_diff )

Returns human-friendly text for the given time difference (in seconds).
This function returns absolute difference text, for relative 
(before/after/ago/in) see unix\_time\_diff\_in\_words\_relative().

## unix\_time\_diff\_in\_words\_relative( $unix\_time\_diff )

Same as unix\_time\_diff\_in\_words() but returns relative text
(i.e. with before/after/ago/in)

## julian\_date\_diff\_in\_words( $julian\_date\_diff );

Returns human-friendly text for the given date difference (in days).
This function returns absolute difference text, for relative 
(before/after/ago/in) see julian\_date\_diff\_in\_words\_relative().

## julian\_date\_diff\_in\_words\_relative( $julian\_date\_diff );

Same as julian\_date\_diff\_in\_words() but returns relative text
(i.e. with before/after/ago/in)

# TODO

    * support for language-dependent wording (before/ago)
    * support for user-defined thresholds (48 hours, 2 months, etc.)

# REQUIRED MODULES

Data::Tools::Time uses:

    * Data::Tools (from the same package)
    * Date::Calc
    * Time::JulianDay

# TEXT TRANSLATION NOTES

time/date difference wording functions does not have translation functions
and return only english text. This is intentional since the goal is to keep
the translation mess away but still allow simple (yet bit strange) 
way to translate the result strings with regexp and language hash:

    my $time_diff_str_rel = unix_time_diff_in_words_relative( $time1 - $time2 );
    
    my %TRANS = (
                'now'       => 'sega',
                'today'     => 'dnes',
                'tomorrow'  => 'utre',
                'yesterday' => 'vchera',
                'in'        => 'sled',
                'before'    => 'predi',
                'year'      => 'godina',
                'years'     => 'godini',
                'month'     => 'mesec',
                'months'    => 'meseca',
                'day'       => 'den',
                'days'      => 'dni',
                'hour'      => 'chas',
                'hours'     => 'chasa',
                'minute'    => 'minuta',
                'minutes'   => 'minuti',
                'second'    => 'sekunda',
                'seconds'   => 'sekundi',
                );
                
    $time_diff_str_rel =~ s/([a-z]+)/$TRANS{ lc $1 } || $1/ge;

I know this is no good for longer sentences but works fine in this case.

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools.git
    
    git clone git://github.com/cade-vs/perl-data-tools.git
    

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/  
# NAME

    Data::Tools::Math provides set of basic functions for mathematics.

# SYNOPSIS

    use Data::Tools::Math qw( :all );  # import all functions
    use Data::Tools::Math;             # the same as :all :) 
    use Data::Tools::Math qw( :none ); # do not import anything

    # --------------------------------------------------------------------------


    # --------------------------------------------------------------------------

# FUNCTIONS

## num\_round( $number, $precision )

Rounds $number to $precisioun places after the decimal point.

## num\_round\_trunc( $number, $precision )

Same as num\_round() but just truncates after the $precision places.

## num\_pow( $number, $exponent )

Returns power of $number by $exponent ( $num \*\* $exp )

# REQUIRED MODULES

Data::Tools::Time uses:

    * Math::BigFloat

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools.git
    
    git clone git://github.com/cade-vs/perl-data-tools.git
    

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/  
# NAME

    Data::Tools::CSV -- compact, pure-perl CSV parsing

# SYNOPSIS

    use Data::Tools::CSV qw( :all );  # import all functions
    use Data::Tools::CSV;             # the same as :all :)
    use Data::Tools::CSV qw( :none ); # do not import anything

    # --------------------------------------------------------------------------

    my $array_of_arrays = parse_csv( $csv_data_string );
    my @single_line     = parse_csv_line( $single_csv_line );

    while( <$fh> )
      {
      parse_csv_line( $_ );
      ...
      }

    # hash keys names are mapped from the first line of $csv_data (head)
    my @array_of_hashes = parse_csv_to_hash_array( $csv_data );

    # --------------------------------------------------------------------------

# FUNCTIONS

In all functions the '$delim' argument is optional and sets the delimiter to
be used. Default one is comma ',' (accordingly to RFC4180, see below).

In all functions the '$strip' argument should be true ("1" or non-zero string)
to strip data from leading and trailing whitespace. If leading or trailing
whitespace is required but stripping is needed to pad visually the data then
actual data must be quoted:

    NAME,   TEL
    jim,    123
    boo,    "  413  "

second field will be \[TEL\] and data will be \[123\] and \[  413  \].

Unfortunately, for keeping API simple, using stripping will require $delim.
However $delim may be undef to use default delimiter.

## parse\_csv( $csv\_data\_string, $delim, $strip )

Parses multi-line CSV text and returnsh hashref to array of arrays.

## parse\_csv\_line( $single\_csv\_line, $delim, $strip )

Parses single line CSV data and returns list of parsed fields' data.
This function will NOT strip trailing CR/LFs. However, parse\_csv() and
parse\_csv\_to\_hash\_array() will strip CR/LFs.

## parse\_csv\_to\_hash\_array( $csv\_data, $delim, $strip )

This function uses first line as hash key names to produce array of hashes
for the rest of the data.

    NOTE: Lines with more data fields than header will discard extra data fields.
    NOTE: Lines with less data fields than header will produce keys with undef values.

# IMPLEMENTATION DETAILS

Data::Tools::CSV is compact, pure-perl implementation of a CSV parser of
RFC4180 style CSV files:

    https://www.ietf.org/rfc/rfc4180.txt

RFC4180 says:

    * lines are CRLF delimited, however CR or LF-only are accepted as well.
    * whitespace is data, will not be stripped (2.4).
    * whitespace and delimiters can be quoted with double quotes (").
    * quotes in quoted text should be doubled ("") as escaping.

Any empty data (i.e. two delimiters without data between) will produce undef
value. However there are quotes with nothing inside the result will be empty
string (not undef!).

# KNOWN ISSUES

This implementation does not support multiline fields (lines split),
as described in RFC4180, (2.6).

Delimiter of "0" is silently converted to ",".

There is no much error handling. However the code makes reasonable effort
to handle properly all the data provided. This may seem vague but the CSV
format itself is vague :)

# FEEDBACK

Please, report any bugs or missing features as long as they follow RFC4180.

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools.git

    git clone git://github.com/cade-vs/perl-data-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
# NAME

    Data::Tools::Serialization provides set of high-level serialization
    and deserialization wrapper functions.

# SYNOPSIS

    use Data::Tools::Serialization qw( :all );  # import all functions
    use Data::Tools::Serialization;             # the same as :all :)
    use Data::Tools::Serialization qw( :none ); # do not import anything

    # --------------------------------------------------------------------------

    my $perl_hoh = xml2perl( $xml_text );
    my $xml_text = perl2xml( $perl_hoh );

    my $perl_hoh  = json2perl( $json_text );
    my $json_text = perl2json( $perl_hoh  );

    # --------------------------------------------------------------------------

# FUNCTIONS

## xml2perl( $xml\_text )

Returns perl hash of hashes reference representing the XML data text.

## perl2xml( $perl\_hoh )

Returns xml text representing the in-memory perl hash of hashes structure.

## json2perl( $xml\_text )

Returns perl hash of hashes reference representing the JSON data text.

## perl2json( $perl\_hoh )

Returns JSON text representing the in-memory perl hash of hashes structure.

# REQUIRED MODULES

Data::Tools::Serialization uses:

    * XML::Bare
    * JSON

all are loaded on demand and are not initial requirement nor if just other
parts of the Data::Tools are used.

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools.git

    git clone git://github.com/cade-vs/perl-data-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
