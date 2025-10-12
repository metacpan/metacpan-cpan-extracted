package MHFS::Util v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Carp qw(croak);
use Exporter 'import';
use Feature::Compat::Try;
use File::Find;
use File::Basename;
use POSIX ();
use Cwd qw(abs_path getcwd);
use Encode qw(decode encode);
use URI::Escape qw(uri_escape uri_escape_utf8);
use MIME::Base64 qw(encode_base64url decode_base64url);
use PerlIO::encoding;
use warnings::register;
our @EXPORT_OK = ('LOCK_GET_LOCKDATA', 'LOCK_WRITE', 'UNLOCK_WRITE', 'write_file', 'write_text_file', 'write_text_file_lossy', 'read_file', 'read_text_file', 'read_text_file_lossy', 'shellcmd_unlock', 'ASYNC', 'FindFile', 'space2us', 'escape_html', 'shell_escape', 'pid_running', 'escape_html_noquote', 'output_dir_versatile', 'do_multiples', 'getMIME', 'get_printable_utf8', 'small_url_encode', 'uri_escape_path', 'uri_escape_path_utf8', 'round', 'ceil_div', 'get_SI_size', 'str_to_base64url', 'base64url_to_str', 'decode_utf_8', 'parse_ipv4', 'fold_case');

BEGIN {
    if (eval "use feature 'fc'; 1;") {
        *fold_case = \&CORE::fc;
    } else {
        *fold_case = \&lc;
    }
}

# single threaded locks
sub LOCK_GET_LOCKDATA {
    my ($filename) = @_;
    my $lockname = "$filename.lock";
    try { read_text_file($lockname) }
    catch ($e) { return; }
}

#sub LOCK_GET_FILESIZE {
#    my ($filename) = @_;
#    my $lockedfilesize = LOCK_GET_LOCKDATA($filename);
#    if(defined $lockedfilesize) {
#
#    }
#}

sub LOCK_WRITE {
    my ($filename, $lockdata) = @_;
    my $lockname = "$filename.lock";
    if(-e $lockname) {
        return 0;
    }
    $lockdata //= "99999999999"; #99 Billion
    write_text_file($lockname, $lockdata);
    return 1;
}

sub UNLOCK_WRITE {
    my ($filename) = @_;
    my $lockname = "$filename.lock";
    unlink($lockname);
}

sub write_file {
    my ($filename, $data) = @_;
    if (utf8::is_utf8($data)) {
        warnings::warnif "UTF8 string in write_file";
        Encode::_utf8_off($data);
    }
    open (my $fh, '>', $filename) or croak "$! $filename";
    print $fh $data;
    close($fh);
}

sub write_text_file {
    my ($filename, $text) = @_;
    local $PerlIO::encoding::fallback = Encode::FB_CROAK;
    open (my $fh, '>:encoding(UTF-8)', $filename) or croak "$! $filename";
    print $fh $text;
    close($fh);
}

sub write_text_file_lossy {
    my ($filename, $text) = @_;
    local $PerlIO::encoding::fallback = Encode::ONLY_PRAGMA_WARNINGS | Encode::WARN_ON_ERR;
    open (my $fh, '>:encoding(UTF-8)', $filename) or croak "$! $filename";
    print $fh $text;
    close($fh);
}

sub read_file {
    my ($filename) = @_;
    local $/ = undef;
    open my $fh, "<", $filename or croak "Failed to open $filename";
    <$fh> // croak "Error reading from $filename"
}

sub read_text_file {
    my ($filename) = @_;
    local $/ = undef;
    local $PerlIO::encoding::fallback = Encode::FB_CROAK;
    open my $fh, '<:encoding(UTF-8)', $filename or croak "Failed to open $filename";
    <$fh> // croak "Error reading from $filename"
}

sub read_text_file_lossy {
    my ($filename) = @_;
    local $/ = undef;
    local $PerlIO::encoding::fallback = Encode::ONLY_PRAGMA_WARNINGS | Encode::WARN_ON_ERR;
    open my $fh, '<:encoding(UTF-8)', $filename or croak "Failed to open $filename";
    <$fh> // croak "Error reading from $filename"
}

# This is not fast
sub FindFile {
    my ($directories, $name_req, $path_req) = @_;
    my $curdir = getcwd();
    my $foundpath;
    eval {
        my $dir_matches = 1;
        my %options = ('wanted' => sub {
            return if(! $dir_matches);
            if(/$name_req/i) {
                return if( -d );
                $foundpath = $File::Find::name;
                die;
            }
        });

        if(defined $path_req) {
            $options{'preprocess'} = sub {
                $dir_matches = ($File::Find::dir =~ /$path_req/i);
                return @_;
            };
        }


        find(\%options, @$directories);
    };
    chdir($curdir);
    return $foundpath;
}

sub shellcmd_unlock {
    my ($command_arr, $fullpath) = @_;
    system @$command_arr;
    UNLOCK_WRITE($fullpath);
}

sub ASYNC {
    my $func = shift;
    my $pid = fork();
    if($pid == 0) {
        $func->(@_);
        #exit 0;
        POSIX::_exit(0);
    }
    else {
        say "PID $pid ASYNC";
        return $pid;
    }
}

sub space2us {
    my ($string) = @_;
    $string =~ s/\s/_/g;
    return $string;
}
sub escape_html {
    my ($string) = @_;
    my %dangerchars = ( '"' => '&quot;', "'" => '&#x27;', '<' => '&lt;', '>' => '&gt;', '/' => '&#x2F;');
    $string =~ s/&/&amp;/g;
    foreach my $key(keys %dangerchars) {
        my $val = $dangerchars{$key};
        $string =~ s/$key/$val/g;
    }
    return \$string;
}

sub escape_html_noquote {
    my ($string) = @_;
    my %dangerchars = ('<' => '&lt;', '>' => '&gt;');
    $string =~ s/&/&amp;/g;
    foreach my $key(keys %dangerchars) {
        my $val = $dangerchars{$key};
        $string =~ s/$key/$val/g;
    }
    return \$string;
}

sub pid_running {
    return kill 0, shift;
}

sub shell_escape {
    my ($cmd) = @_;
    ($cmd) =~ s/'/'"'"'/g;
    return $cmd;
}

sub output_dir_versatile {
    my ($path, $options) = @_;
    # hide the root path if desired
    my $root = $options->{'root'};
    $options->{'min_file_size'} //= 0;

    my @files;
    ON_DIR:
    # get the list of files and sort
    my $dir;
    if(! opendir($dir, $path)) {
        warn "outputdir: Cannot open directory: $path $!";
        return;
    }
    my @newfiles = sort { uc($a) cmp uc($b)} (readdir $dir);
    closedir($dir);
    my @newpaths = ();
    foreach my $file (@newfiles) {
        next if($file =~ /^..?$/);
        push @newpaths,  "$path/$file";
    }
    @files = (@newpaths, @files);
    while(@files)
    {
        $path = shift @files;
        if(! defined $path) {
            $options->{'on_dir_end'}->() if($options->{'on_dir_end'});
            next;
        }
        my $file = basename($path);
        if(-d $path) {
            $options->{'on_dir_start'}->($path, $file) if($options->{'on_dir_start'});
            @files = (undef, @files);
            goto ON_DIR;
        }

        my $unsafePath = $path;
        if($root) {
            $unsafePath =~ s/^$root(\/)?//;
        }
        my $size = -s $path;
        if(! defined $size) {
            say "size not defined path $path file $file";
            next;
        }
        next if( $size < $options->{'min_file_size'});
        $options->{'on_file'}->($path, $unsafePath, $file) if($options->{'on_file'});
    }
    return;
}

# perform multiple async actions at the same time.
# continue on with $result_func on failure or completion of all actions
sub do_multiples {
    my ($multiples, $result_func) = @_;
    my %data;
    my @mkeys = keys %{$multiples};
    foreach my $multiple (@mkeys) {
        my $multiple_cb = sub {
            my ($res) = @_;
            $data{$multiple} = $res;
            # return failure if this multiple failed
            if(! defined $data{$multiple}) {
                $result_func->(undef);
                return;
            }
            # yield if not all the results in
            foreach my $m2 (@mkeys) {
                return if(! defined $data{$m2});
            }
            # all results in we can continue
            $result_func->(\%data);
        };
        say "launching multiple key: $multiple";
        $multiples->{$multiple}->($multiple_cb);
    }
}

sub getMIME {
    my ($filename) = @_;

    my %combined = (
        # audio
        'mp3' => 'audio/mp3',
        'flac' => 'audio/flac',
        'opus' => 'audio',
        'ogg'  => 'audio/ogg',
        'wav'  => 'audio/wav',
        # video
        'mp4' => 'video/mp4',
        'ts'   => 'video/mp2t',
        'mkv'  => 'video/x-matroska',
        'webm' => 'video/webm',
        'flv'  => 'video/x-flv',
        # media
        'mpd' => 'application/dash+xml',
        'm3u8' => 'application/x-mpegURL',
        'm3u8_v' => 'application/x-mpegURL',
        # text
        'html' => 'text/html; charset=utf-8',
        'json' => 'application/json',
        'js'   => 'application/javascript',
        'txt' => 'text/plain; charset=utf-8',
        'css' => 'text/css',
        # images
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'bmp' => 'image/bmp',
        # binary
        'pdf' => 'application/pdf',
        'tar' => 'application/x-tar',
        'wasm'  => 'application/wasm',
        'bin' => 'application/octet-stream'
    );

    my ($ext) = $filename =~ /\.([^.]+)$/;

    # default to binary
    return $combined{$ext} // $combined{'bin'};
}

sub parse_ipv4 {
    my ($ipstring) = @_;
    my $failmessage = "invalid ip: $ipstring";
    my @values = $ipstring =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
    if(scalar(@values) != 4) {
        croak $failmessage;
    }
    foreach my $i (0..3) {
        ($values[$i] <= 255) or croak $failmessage;
    }
    return ($values[0] << 24) | ($values[1] << 16) | ($values[2] << 8) | ($values[3]);
}

sub surrogatepairtochar {
    my ($hi, $low) = @_;
    my $codepoint = 0x10000 + (ord($hi) - 0xD800) * 0x400 + (ord($low) - 0xDC00);
    return pack('U', $codepoint);
}

sub surrogatecodepointpairtochar {
    my ($hi, $low) = @_;
    my $codepoint = 0x10000 + ($hi - 0xD800) * 0x400 + ($low - 0xDC00);
    return pack('U', $codepoint);
}

# returns the byte length and the codepoint
sub _peek_utf8_codepoint {
    my ($octets) = @_;
    my @rules = (
        [0x80, 0x00, 1], # 1 byte sequence
        [0xE0, 0xC0, 2], # 2 byte sequence
        [0xF0, 0xE0, 3], # 3 byte sequence
        [0XF8, 0xF0, 4]  # 4 byte sequence
    );
    my $byteval = ord(substr($octets, 0, 1));
    my $charlen;
    foreach my $rule (@rules) {
        if(($byteval & $rule->[0]) == $rule->[1]) {
            $charlen = $rule->[2];
            last;
        }
    }
    $charlen or return {'codepoint' => 0xFFFD, 'bytelength' => 1};
    my $valid_bytes = 1;
    for my $i (1 .. $charlen - 1) {
        # this handles length($octets) < $charlen properly
        my $cont_byte = ord(substr($octets, $i, 1));
        if (($cont_byte & 0xC0) != 0x80) {
            return {'codepoint' => 0xFFFD, 'bytelength' => $valid_bytes};
        }
        $valid_bytes++;
    }
    my $char = decode("utf8", substr($octets, 0, $charlen));
    if(length($char) > 1) {
        warnings::warnif "impossible situation, decode returned more than one char";
        return {'codepoint' => 0xFFFD, 'bytelength' => 1};
    }
    return { 'codepoint' => ord($char), 'bytelength' => $charlen};
}

sub get_printable_utf8 {
    my ($octets) = @_;
    my $res;
    while(length($octets)) {
        $res .= decode('UTF-8', $octets, Encode::FB_QUIET);
        last if(!length($octets));

        # by default replace with the replacement char
        my $char = _peek_utf8_codepoint($octets);
        my $toappend = chr(0xFFFD);
        my $toremove = $char->{bytelength};

        # if we find a surrogate pair, make the actual codepoint
        my $mask = ~0 << 16 | 0xFC00;
        if (length($octets) >= 6 && ($char->{bytelength} == 3) && (($char->{codepoint} & $mask) == 0xD800)) {
            my $secondchar = _peek_utf8_codepoint(substr($octets, 3, 3));
            if(($secondchar->{bytelength} == 3) && (($secondchar->{codepoint} & $mask) == 0xDC00)) {
                $toappend = surrogatecodepointpairtochar($char->{codepoint}, $secondchar->{codepoint});
                $toremove += 3;
            }
        }

        $res .= $toappend;
        substr($octets, 0, $toremove, '');
    }

    return $res;
}

# save space by not precent encoding valid UTF-8 characters
sub small_url_encode {
    my ($octets) = @_;
    say "before $octets";

    my $escapedoctets = ${escape_html($octets)};
    my $res;
    while(length($escapedoctets)) {
        $res .= decode('UTF-8', $escapedoctets, Encode::FB_QUIET);
        last if(!length($escapedoctets));
        my $oct = ord(substr($escapedoctets, 0, 1, ''));
        $res .= sprintf ("%%%02X", $oct);
    }
    say "now: $res";
    return $res;
}

sub uri_escape_path {
    my ($b_path) = @_;
    uri_escape($b_path, qr/[^A-Za-z0-9\-\._~\/]/)
}

sub uri_escape_path_utf8 {
    my ($path) = @_;
    uri_escape_utf8($path, qr/[^A-Za-z0-9\-\._~\/]/)
}

sub round {
    return int($_[0]+0.5);
}

sub ceil_div {
    return int(($_[0] + $_[1] - 1) / $_[1]);
}

sub get_SI_size {
    my ($bytes) = @_;
    my $mebibytes = ($bytes / 1048576);
    if($mebibytes >= 1024) {
        return  sprintf("%.2f GiB", $bytes / 1073741824);
    }
    else {
        return sprintf("%.2f MiB", $mebibytes);
    }
}

# does not check for valid UTF-8
sub str_to_base64url {
    my ($str) = @_;
    utf8::encode($str);
    encode_base64url($str)
}

sub base64url_to_str {
    my ($base64url) = @_;
    my $bstr = decode_base64url($base64url);
    decode('UTF-8', $bstr, Encode::FB_CROAK)
}

sub die2croak {
    local $SIG{__DIE__} = sub {
        my ($message) = @_;
        chomp $message;
        $message =~ s/\sat\s.+\sline\s\d+\.$//;
        local $Carp::CarpLevel;
        if ($Carp::Verbose) {
            $Carp::CarpLevel += 2;
        }
        croak $message;
    };
    my $call = shift @_;
    &$call;
}

sub decode_utf_8 {
    #local $SIG{__DIE__} = sub {
    #    my ($message) = @_;
    #    chomp $message;
    #    $message =~ s/\sat\s.+\sline\s\d+\.$//;
    #    local $Carp::CarpLevel;
    #    $Carp::CarpLevel++ if ($Carp::Verbose);
    #    croak $message;
    #};
    #decode('UTF-8', $_[0], Encode::FB_CROAK | Encode::LEAVE_SRC)
    die2croak(\&decode, 'UTF-8', $_[0], Encode::FB_CROAK | Encode::LEAVE_SRC)
}

1;
