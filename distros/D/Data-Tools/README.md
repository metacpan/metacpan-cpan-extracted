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

    my $escaped   = str_html_escape( $plain_str ); # HTML-style &name; escaping
    my $plain_str = str_html_unescape( $escaped );

    my $hex_str   = str_hex( $plain_str ); # HEX-style XX string escaping
    my $plain_str = str_unhex( $hex_str );

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

    * Data::Tools::Socket (socket I/O processing, TODO: docs)
    * Data::Tools::Time   (time processing)

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

    Data::Tools::Socket provides set of socket I/O functions.

# SYNOPSIS

    use Data::Tools::Socket qw( :all );  # import all functions
    use Data::Tools::Socket;             # the same as :all :)
    use Data::Tools::Socket qw( :none ); # do not import anything, use full package names

    # --------------------------------------------------------------------------

    my $read_res_len  = socket_read(  $socket, $data_ref, $length, $timeout );
    my $write_res_len = socket_write( $socket, $data,     $length, $timeout );
    my $write_res_len = socket_print( $socket, $data, $timeout );

    # --------------------------------------------------------------------------

    my $read_data = socket_read_message(  $socket, $timeout );
    my $write_res = socket_write_message( $socket, $data, $timeout );

    # --------------------------------------------------------------------------

# FUNCTIONS

## socket\_read(  $socket, $data\_ref, $length, $timeout )

Reads $length sized data from the $socket and store it to $data\_ref scalar
reference.

Returns read length (can be shorter than requested $length);

$timeout is optional, it is in seconds and can be less than 1 second.

## socket\_write( $socket, $data,     $length, $timeout )

Writes $length sized data from $data scalar to the $socket.

Returns write length (can be shorter than requested $length);

$timeout is optional, it is in seconds and can be less than 1 second.

## socket\_print( $socket, $data, $timeout )

Same as socket\_write() but calculates requested length from the $data scalar.

$timeout is optional, it is in seconds and can be less than 1 second.

## socket\_read\_message(  $socket, $timeout )

Reads 32bit network-order integer, which then is used as data size to be read
from the socket (i.e. message = 32bit-integer + data ).

Returns read data or undef for message or network error.

$timeout is optional, it is in seconds and can be less than 1 second.

## socket\_write\_message( $socket, $data, $timeout )

Writes 32bit network-order integer, which is the size of the given $data to be
written to the $socket and then writes the data
(i.e. message = 32bit-integer + data ).

Returns 1 on success or undef for message or network error.

$timeout is optional, it is in seconds and can be less than 1 second.

# TODO

    * more docs

# REQUIRED MODULES

Data::Tools::Socket uses:

    * Time::HiRes

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

    Data::Tools::Process provides set of functions for process control,
    forking, daemonizing and pid files handling.

# SYNOPSIS

    use Data::Tools::Process qw( :all );  # import all functions
    use Data::Tools::Process;             # the same as :all :)
    use Data::Tools::Process qw( :none ); # do not import anything

    # --------------------------------------------------------------------------

    # fork and exec a command, returns the child pid to the parent
    my $pid = fork_exec_cmd( "/usr/bin/somecmd --with args" );
    waitpid( $pid, 0 );

    # --------------------------------------------------------------------------

    # detach from the controlling terminal and become a daemon
    daemonize();
    daemonize( CHDIR => '/var/lib/myapp', UMASK => 0022 );

    # --------------------------------------------------------------------------

    # create a pid file, holding the pid of the current process
    my $res = pidfile_create( '/var/run/myapp.pid' );
    die "already running with pid [$res]" if $res;

    # ...and take over the pid file if the process in it is gone
    my $res = pidfile_create( '/var/run/myapp.pid', STALE_CHECK => 1 );

    # signal the process named in a pid file and remove the file
    pidfile_kill_and_remove( '/var/run/myapp.pid' );          # sends TERM
    pidfile_kill_and_remove( '/var/run/myapp.pid', 15, '5s', 9 );

    # just remove the pid file
    pidfile_remove( '/var/run/myapp.pid' );

    # --------------------------------------------------------------------------

# FUNCTIONS

## fork\_exec\_cmd( $command )

Forks and exec()s $command in the child process.

Returns:

    * the child process pid in the parent process
    * undef if fork() failed

The child never returns. $command is passed to exec() as a single string,
so it is subject to the usual shell handling of exec().

## daemonize( %options )

Detaches the current process from the controlling terminal and turns it into
a daemon: forks, calls POSIX::setsid(), forks again (SVR4 second fork policy),
changes the current directory, closes all open file descriptors and reopens
STDIN, STDOUT and STDERR to /dev/null.

Options are:

    CHDIR => $path   # directory to change to, default is '/'
    UMASK => $umask  # umask to set, default is 0077

Returns 1 in the resulting daemon process. The original process and the
intermediate one exit() and never return. Dies on any of the steps failing.

    NOTE: all open file descriptors are closed, including any files, sockets
          or database handles opened before the call.

## pidfile\_create( $pid\_file\_name, %options )

Creates $pid\_file\_name and writes the pid of the current process in it. The
file is created with O\_EXCL, so two processes racing for the same pid file
cannot both succeed. Missing directories on the way are created.

Options are:

    STALE_CHECK => 1  # take over the pid file if its process is not running

Returns:

    * undef on success, the pid file now holds our pid
    * a positive pid if the pid file exists and holds a running process
    * -1 if the pid file cannot be created

A pid file which does not hold a valid (positive) pid is always considered
stale and is replaced, regardless of STALE\_CHECK.

## pidfile\_kill\_and\_remove( $pid\_file\_name, @signal\_list )

Sends the given signals to the pid found in $pid\_file\_name and then removes
the file. @signal\_list defaults to a single TERM (15).

A list item ending with 's' is not a signal but a sleep time in seconds. All
items are processed in the given order, so:

    pidfile_kill_and_remove( $fname, 15, '5s', 15, '2s', 9 );

sends TERM, waits 5 seconds, sends TERM again, waits 2 seconds, sends KILL.

Returns:

    * undef if $pid_file_name does not exist
    * 1 if the signals have been sent and the pid file removed

## pidfile\_remove( $pid\_file\_name )

Removes $pid\_file\_name. Returns undef.

# REQUIRED MODULES

Data::Tools::Process uses:

    * POSIX
    * Data::Tools

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools.git

    git clone git://github.com/cade-vs/perl-data-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
# NAME

Data::Tools::Process::Forks - Fork process creation and control

# SYNOPSIS

    use Data::Tools::Process::Forks;

    # set up signal handlers for graceful shutdown (optional)
    forks_setup_signals();

    # configure maximum concurrent forks (default is 8)
    forks_set_max( 18 );

    # case A: start simple worker processes
    for my $task ( @tasks )
      {
      # this is the parent process, fork and continue
      forks_start_one( 'THINKER' ) and next; 
      
      # here is the forked child process, do some work and exit:
      # ...
      exit 111;
      # exit here is mandatory and omitting it would be a problem, 
      # since it will start forking more processes from the child one!
      # however it is the most simple use case.
      }

    # wait for all children to finish
    forks_wait_all();



    # case B: start worker processes with sub reference or closure
    for my $task ( @tasks )
      {
      forks_start_one( 'GOPHER', \&fetch_things ); 
      forks_start_one( 'PARSER', sub { call_parser(); cleanup(); } ); 
      forks_start_one( undef, sub { print "Testing :)\n; return 222 " } ); 
      }

    # wait for all children to finish
    forks_wait_all();

# DESCRIPTION

Data::Tools::Process::Forks provides a simple interface for managing multiple
forked child processes. It handles the common patterns of limiting concurrent
processes, tracking active children by name, and graceful shutdown via signals.

The module keeps track of running and completed children when the maximum fork 
count is reached, allowing new processes to start or wait for new open slot.

# FUNCTIONS

All functions are exported by default.

## Signal Handling

### forks\_setup\_signals()

Installs signal handlers for `INT` and `TERM` signals. When either signal is
received, the handler will send `TERM` to all child processes, wait for them
to exit, then terminate the parent process with exit code 111.

    forks_setup_signals();

This is optional and should typically be called early in the parent process 
before forking any children.

## Process Creation and Waiting

### forks\_start\_one( $name, $coderef, @args )

Forks a new child process to execute the given subroutine.

    my $pid = forks_start_one( 'worker', \&do_work, @work_args );

**Parameters:**

- `$name`

    Optional name for the forked process, used for identification. Defaults to
    `'*'` if not provided or undefined.

- `$coderef`

    Optional code reference to execute in the child. If provided, the child will
    execute this subroutine and exit with its return value as the exit code.
    If not provided, the function returns 0 in the child, allowing inline child
    code (see SYNOPSIS).

- `@args`

    Optional arguments passed to `$coderef` when executed in the child.

**Returns:**

- In the parent: the child's PID on success, or `'0E0'` (true but zero) on
fork failure. On fork failure and inline child prcesses, the parent will simply
skip the child code and try to fork again. To avoid high load, save the result
code and do something like:

        my $fr = forks_start_one();
        if( $fr eq '0E0' )
          {
          print "fork error [$!] sleeping\n";
          sleep 3;
          }
        next if $fr;  
        
        # forked child here
        exit 1;

- In the child (when no `$coderef` provided): 0

    To be sure code runs in the forked child process, return value must be checked
    like this:

        if( ! forks_start_one() )
          {
          # child here
          # must finish with exit!
          exit 2;
          }

    WARNING: return value should never be compared to 0, otherwise on fork errors, 
    child code will be executed in the parent process!

        if( forks_start_one() == 0 )
          {
          # WRONG! this will execute in the parent
          # must finish with exit!
          exit 2;
          }
        

**Note:** If the current number of active forks equals or exceeds the maximum
(see `forks_set_max()`), this function blocks until a child exits before
forking the new process.

### forks\_wait\_one( $non\_blocking )

Waits for one child process to exit.

    # blocking, return all child attributes (list context)
    my ( $pid, $exit_code, $signal, $name ) = forks_wait_one();
    
    # Non-blocking check, got pid only (scalar context)
    my $pid = forks_wait_one( 1 );

**Parameters:**

- `$non_blocking`

    If true, returns immediately if no child has exited (uses `WNOHANG`).
    If false or omitted, blocks until a child exits.

**Returns:**

In list context: `( $pid, $exit_code, $signal, $name )`

- `$pid`

    The process ID of the exited child.

- `$exit_code`

    The exit code returned by the child (high 8 bits of `$?`).

- `$signal`

    The signal that terminated the child, if any (low 7 bits of `$?`).

- `$name`

    The name assigned to the child when it was forked.

In scalar context: returns only `$pid`.

Returns an empty list if no children have exited (non-blocking mode) or if
there are no active children.

### forks\_wait\_all( $timeout )

Blocks until all active child processes have exited. Optional timeout in
seconds can be specified to avoid blocking. Avoiding blocking may give control
to the parent process when forked one has blocked for some reason.

    # block until all forks finished
    forks_wait_all(); 
    
    # or
    
    # wait 4 seconds for finished forks and return finished count
    my $c = forks_wait_all( 4 ); 
    

internally it calls forks\_wait\_one() until internal forked processes
count reached 0 or timeout reached.

## Process Signalling

### forks\_signal\_all( $signal )

Sends the specified signal to all active child processes.

    forks_signal_all( 'HUP' );
    forks_signal_all( 15 );      # SIGTERM by number

if signal is undef or empty parameter list, will do nothing and exit.

**Parameters:**

- `$signal`

    The signal name or number to send.

**Returns:** `undef` if no signal specified, otherwise the result of `kill()`.

### forks\_stop\_all()

Sends `TERM` signal to all active child processes.

    forks_stop_all();

Equivalent to `forks_signal_all( 'TERM' )`.

### forks\_kill\_all()

Sends `KILL` signal to all active child processes.

    forks_kill_all();

Equivalent to `forks_signal_all( 'KILL' )`. Use this for forceful termination
when children do not respond to `TERM`.

## Configuration

### forks\_set\_max( $max )

Sets the maximum number of concurrent child processes (slots).

    forks_set_max( 16 );
    

**Parameters:**

- `$max`

    Maximum number of concurrent forks. Values less than 1 are clamped to 4.

When `forks_start_one()` is called and the current fork count (slots) equals 
or exceeds this maximum, it will wait until a child exits before forking.

Default value is 4.

If called without parameters, will try to figure machine core count and set
it the same. Note that this works only on machines with /proc file system 
(i.e. Linux). if not Linux, /proc not mounted or other error will set to 8.

### forks\_get\_max()

Returns the current maximum fork limit.

    my $max = forks_get_max();

## Inspection

### forks\_count()

Returns the number of currently active child processes.

    my $active = forks_count();
    print "Running $active workers\n";

### forks\_pids()

Returns a list of PIDs for all active child processes.

    my @pids = forks_pids();

### forks\_names()

Returns a list of unique names assigned to active child processes.

    my @names = forks_names();

Note that multiple processes may share the same name; this returns only
unique names in use.

### forks\_set\_start\_wait\_to( $timeout )

This sets timeout for waiting for free slot when trying to start new fork but
maximum count has been reached. Setting $timeout to 0 will enable blocking,
i.e. forks\_start\_one() will wait until slot freed. If timeout reached
forks\_start\_one() will return '0E0' (zero but true) which is same as fork 
error.

# EXAMPLES

## Parallel Task Processing

    use Data::Tools::Process::Forks;

    forks_setup_signals();
    forks_set_max( 6 );

    my @files = glob( '*.dat' );

    for my $file ( @files )
      {
      forks_start_one( 
                       'processor', 
                       sub 
                          {
                          process_file( $file );
                          return 0;
                          }
                     );
      }

    forks_wait_all();
    print "All files processed\n";

## Worker Pool with Status Monitoring

    use Data::Tools::Process::Forks;

    forks_setup_signals();
    forks_set_max( 11 );

    # Start workers
    for my $id ( 1 .. 20 )
      {
      forks_start_one( "worker-$id", \&worker_task, $id );
      }

    # Monitor progress
    while( forks_count() > 0 )
      {
      my ( $pid, $exit, $sig, $name ) = forks_wait_one();
      if( $exit == 0 )
        {
        print "$name completed successfully\n";
        }
      else
        {
        print "$name failed with exit code $exit\n";
        }
      }

## Graceful Shutdown

    use Data::Tools::Process::Forks;

    forks_setup_signals();  # Handles INT/TERM automatically

    # Or manual shutdown:
    END
      {
      if( forks_count() > 0 )
        {
        print "Shutting down workers...\n";
        forks_stop_all();
        forks_wait_all();
        }
      }

# NOTES

- The module uses package-level variables to track state. Only one fork pool
can be managed per process but fork names can represent separate fork pools.

    This is really a design choice. This module was meant to be simple with
    minimum dependencies (only Perl core Exporter and POSIX). 

    For, possibly, more complex things you may check **Parralel::ForkManager** 
    on **CPAN**.

- Child processes reset the parent fork pool state so they can have own
fork process pool and use this module themselves.
- The `forks_start_one()` function may block indefinitely if child processes
do not exit and the maximum fork count is reached. To avoid this situation
`forks_set_start_wait_to()` can be used to set timeout for waiting for a free
slot to be available while trying to start new one:

        forks_set_start_wait_to( 4 );
        my $fr = forks_start_one();
        if( $fr eq '0E0' )
          {
          # either fork error occured
          # or timeout waiting for free slot reached
          ...
          }

# SEE ALSO

[Parallel::ForkManager](https://metacpan.org/pod/Parallel%3A%3AForkManager), [fork(2)](http://man.he.net/man2/fork), [waitpid(2)](http://man.he.net/man2/waitpid), [POSIX](https://metacpan.org/pod/POSIX)

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/  

# COPYRIGHT AND LICENSE

Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.
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
# NAME

    Data::Tools::Socket::Protocols provides transparent serialization on top
    of the Data::Tools::Socket message functions.

# SYNOPSIS

    use Data::Tools::Socket::Protocols qw( :all );  # import all functions
    use Data::Tools::Socket::Protocols;             # the same as :all :)
    use Data::Tools::Socket::Protocols qw( :none ); # do not import anything

    # --------------------------------------------------------------------------

    # send a hash reference, serialized with the 'j'son protocol
    socket_protocol_write_message( $socket, 'j', $hash_ref, $timeout );

    # read it back, the protocol type is taken from the message itself
    my $hash_ref = socket_protocol_read_message( $socket, $timeout );

    # in list context the protocol type and an error string are returned too
    my ( $hash_ref, $ptype, $error ) =
        socket_protocol_read_message( $socket, $timeout );

    # the 'b'inary protocol carries plain data instead of a hash reference
    socket_protocol_write_message( $socket, 'b', $raw_data, $timeout );

    # --------------------------------------------------------------------------

    # restrict which protocol types will be accepted and sent
    socket_protocols_allow( 'bjh' );      # only binary, json and hash
    socket_protocols_allow( 'b', 'jh' );  # the same, arguments are concatenated
    socket_protocols_allow( '*' );        # allow all of them again

    # --------------------------------------------------------------------------

# PROTOCOL TYPES

A protocol type is a single character, sent as the first byte of every
message. The rest of the message is the payload, serialized accordingly:

    'b'  binary,        payload is plain data, not a hash reference
    'p'  Storable       (nfreeze/thaw)
    'e'  Sereal
    's'  Data::Stacker
    'j'  JSON
    'x'  XML::Simple
    'h'  hash2str()     from Data::Tools, needs no extra module
    'H'  hash2str_url() from Data::Tools, needs no extra module

Except for 'b', the payload is always a hash reference.

The module needed by a protocol type is loaded on demand, the first time
that type is actually used, so a missing module is only a problem if the
corresponding protocol type is used. 'b', 'h' and 'H' need no extra module.

    NOTE: Storable is a core module and JSON is already required by
          Data::Tools, so those types work out of the box. Sereal,
          Data::Stacker and XML::Simple are not required by this
          distribution and may need to be installed separately.

# FUNCTIONS

## socket\_protocol\_write\_message( $socket, $ptype, $data, $timeout )

Serializes $data according to the $ptype protocol type, prefixes it with the
protocol type character and sends it with socket\_write\_message().

$data must be a hash reference, unless $ptype is 'b', in which case it is
plain data.

Returns 1 on success or undef if the message could not be sent.

Confesses if $ptype is not a known or currently allowed protocol type, or if
$data is not a hash reference for a non-binary protocol type.

## socket\_protocol\_read\_message( $socket, $timeout, $opt )

Reads a message with socket\_read\_message(), takes the protocol type from its
first byte and deserializes the rest accordingly.

In scalar context returns the deserialized data, or undef on error.

In list context returns:

    ( $data, $ptype, $error )

$error is undef when everything went fine, otherwise it is one of the error
strings of socket\_read\_message(), or 'E\_EMPTY' if the message carries no
protocol type byte or no payload after it.

Confesses if the incoming protocol type is not known or not currently
allowed, or if a non-binary protocol type does not deserialize into a hash
reference.

## socket\_protocols\_allow( @protocol\_types )

Restricts which protocol types will be accepted and sent. The arguments are
concatenated and then split into single characters, so these are the same:

    socket_protocols_allow( 'bjh' );
    socket_protocols_allow( 'b', 'j', 'h' );

A single '\*' allows all known protocol types again.

By default all protocol types are allowed. Confesses if an unknown protocol
type is given, in which case the allowed set is left incomplete, so pass all
wanted types in one call.

# REQUIRED MODULES

Data::Tools::Socket::Protocols uses:

    * Data::Tools
    * Data::Tools::Socket

and, on demand and only for the corresponding protocol types:

    * Storable, Sereal, Data::Stacker, JSON, XML::Simple

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools.git

    git clone git://github.com/cade-vs/perl-data-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
