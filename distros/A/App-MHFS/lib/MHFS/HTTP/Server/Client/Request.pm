package MHFS::HTTP::Server::Client::Request v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
use URI::Escape;
use Cwd qw(abs_path getcwd);
use Feature::Compat::Try;
use File::Basename;
use File::stat;
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use Data::Dumper;
use Scalar::Util qw(weaken);
use List::Util qw[min max];
use Symbol 'gensym';
use Devel::Peek;
use Encode qw(decode encode);
use constant {
    MAX_REQUEST_SIZE => 8192,
};
use FindBin;
use File::Spec;
use MHFS::EventLoop::Poll;
use MHFS::Process;
use MHFS::Util qw(get_printable_utf8 LOCK_GET_LOCKDATA getMIME shell_escape escape_html_noquote parse_ipv4);
BEGIN {
    if( ! (eval "use JSON; 1")) {
        eval "use JSON::PP; 1" or die "No implementation of JSON available";
        warn __PACKAGE__.": Using PurePerl version of JSON (JSON::PP)";
    }
}

# Optional dependency, Alien::Tar::Size
BEGIN {
    use constant HAS_Alien_Tar_Size => (eval "use Alien::Tar::Size; 1");
    if(! HAS_Alien_Tar_Size) {
        warn "Alien::Tar::Size is not available";
    }
}

sub new {
    my ($class, $client) = @_;
    my %self = ( 'client' => $client);
    bless \%self, $class;
    weaken($self{'client'}); #don't allow Request to keep client alive
    $self{'on_read_ready'} = \&want_request_line;
    $self{'outheaders'}{'X-MHFS-CONN-ID'} = $client->{'outheaders'}{'X-MHFS-CONN-ID'};
    $self{'rl'} = 0;
    # we want the request
    $client->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
    $self{'recvrequesttimerid'} = $client->AddClientCloseTimer($client->{'server'}{'settings'}{'recvrequestimeout'}, $client->{'CONN-ID'}, 1);
    return \%self;
}

# on ready ready handlers
sub want_request_line {
    my ($self) = @_;

    my $ipos = index($self->{'client'}{'inbuf'}, "\r\n");
    if($ipos != -1) {
        if(substr($self->{'client'}{'inbuf'}, 0, $ipos+2, '') =~ /^(([^\s]+)\s+([^\s]+)\s+(?:HTTP\/1\.([0-1])))\r\n/) {
            my $rl = $1;
            $self->{'method'}    = $2;
            $self->{'uri'}       = $3;
            $self->{'httpproto'} = $4;
            my $rid = int(clock_gettime(CLOCK_MONOTONIC) * rand()); # insecure uid
            $self->{'outheaders'}{'X-MHFS-REQUEST-ID'} = sprintf("%X", $rid);
            say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . " X-MHFS-REQUEST-ID: " . $self->{'outheaders'}{'X-MHFS-REQUEST-ID'};
            say "RECV: $rl";
            if(($self->{'method'} ne 'GET') && ($self->{'method'} ne 'HEAD') && ($self->{'method'} ne 'PUT')) {
                say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . 'Invalid method: ' . $self->{'method'}. ', closing conn';
                return undef;
            }
            my ($path, $querystring) = ($self->{'uri'} =~ /^([^\?]+)(?:\?)?(.*)$/g);
            say("raw path: $path\nraw querystring: $querystring");

            # transformations
            ## Path
            $path = uri_unescape($path);
            my %pathStruct = ( 'unescapepath' => $path );

            # collapse slashes
            $path =~ s/\/{2,}/\//g;
            say "collapsed: $path";
            $pathStruct{'unsafecollapse'} = $path;

            # without trailing slash
            if(index($pathStruct{'unsafecollapse'}, '/', length($pathStruct{'unsafecollapse'})-1) != -1) {
                chop($path);
                say "no slash path: $path ";
            }
            $pathStruct{'unsafepath'} = $path;

            ## Querystring
            my %qsStruct;
            # In the querystring spaces are sometimes encoded as + for legacy reasons unfortunately
            $querystring =~ s/\+/%20/g;
            my @qsPairs = split('&', $querystring);
            foreach my $pair (@qsPairs) {
                my($key, $value) = split('=', $pair);
                if(defined $value) {
                    if(!defined $qsStruct{$key}) {
                        $qsStruct{$key} = uri_unescape($value);
                    }
                    else {
                        if(ref($qsStruct{$key}) ne 'ARRAY') {
                            $qsStruct{$key} = [$qsStruct{$key}];
                        };
                        push @{$qsStruct{$key}}, uri_unescape($value);
                    }
                }
            }

            $self->{'path'} = \%pathStruct;
            $self->{'qs'} = \%qsStruct;
            $self->{'on_read_ready'} = \&want_headers;
            #return want_headers($self);
            goto &want_headers;
        }
        else {
            say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' Invalid Request line, closing conn';
            return undef;
        }
    }
    elsif(length($self->{'client'}{'inbuf'}) > MAX_REQUEST_SIZE) {
        say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' No Request line, closing conn';
        return undef;
    }
    return 1;
}

sub want_headers {
    my ($self) = @_;
    my $ipos;
    while($ipos = index($self->{'client'}{'inbuf'}, "\r\n")) {
        if($ipos == -1) {
            if(length($self->{'client'}{'inbuf'}) > MAX_REQUEST_SIZE) {
                say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' Headers too big, closing conn';
                return undef;
            }
            return 1;
        }
        elsif(substr($self->{'client'}{'inbuf'}, 0, $ipos+2, '') =~ /^(([^:]+):\s*(.*))\r\n/) {
            say "RECV: $1";
            $self->{'header'}{$2} = $3;
        }
        else {
            say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' Invalid header, closing conn';
            return undef;
        }
    }
    # when $ipos is 0 we recieved the end of the headers: \r\n\r\n

    # verify correct host is specified when required
    if($self->{'client'}{'serverhostname'}) {
        if((! $self->{'header'}{'Host'}) ||
        ($self->{'header'}{'Host'} ne $self->{'client'}{'serverhostname'})) {
            my $printhostname = $self->{'header'}{'Host'} // '';
            say "Host: $printhostname does not match ". $self->{'client'}{'serverhostname'};
            return undef;
        }
    }

    $self->{'ip'} = $self->{'client'}{'ip'};

    # check if we're trusted (we can trust the headers such as from reverse proxy)
    my $trusted;
    if($self->{'client'}{'X-MHFS-PROXY-KEY'} && $self->{'header'}{'X-MHFS-PROXY-KEY'}) {
        $trusted = $self->{'client'}{'X-MHFS-PROXY-KEY'} eq $self->{'header'}{'X-MHFS-PROXY-KEY'};
    }
    # drops conns for naughty client's using forbidden headers
    if(!$trusted) {
        my @absolutelyforbidden = ('X-MHFS-PROXY-KEY', 'X-Forwarded-For');
        foreach my $forbidden (@absolutelyforbidden) {
            if( exists $self->{'header'}{$forbidden}) {
                say "header $forbidden is forbidden!";
                return undef;
            }
        }
    }
    # process reverse proxy headers
    else {
        delete $self->{'header'}{'X-MHFS-PROXY-KEY'};
        try { $self->{'ip'} = parse_ipv4($self->{'header'}{'X-Forwarded-For'}) if($self->{'header'}{'X-Forwarded-For'}); }
        catch ($e) { say "ip not updated, unable to parse X-Forwarded-For: " . $self->{'header'}{'X-Forwarded-For'}; }
    }
    my $netmap = $self->{'client'}{'server'}{'settings'}{'NETMAP'};
    if($netmap && (($self->{'ip'} >> 24) == $netmap->[0])) {
        say "HACK for netmap converting to local ip";
        $self->{'ip'} = ($self->{'ip'} & 0xFFFFFF) | ($netmap->[1] << 24);
    }

    # remove the final \r\n
    substr($self->{'client'}{'inbuf'}, 0, 2, '');
    if((defined $self->{'header'}{'Range'}) &&  ($self->{'header'}{'Range'} =~ /^bytes=([0-9]+)\-([0-9]*)$/)) {
        $self->{'header'}{'_RangeStart'} = $1;
        $self->{'header'}{'_RangeEnd'} = ($2 ne  '') ? $2 : undef;
    }
    $self->{'on_read_ready'} = undef;
    $self->{'client'}->SetEvents(MHFS::EventLoop::Poll->ALWAYSMASK );
    $self->{'client'}->KillClientCloseTimer($self->{'recvrequesttimerid'});
    $self->{'recvrequesttimerid'} = undef;

    # finally handle the request
    foreach my $route (@{$self->{'client'}{'server'}{'routes'}}) {
        if($self->{'path'}{'unsafecollapse'} eq $route->[0]) {
            $route->[1]($self);
            return 1;
        }
        else {
            # wildcard ending
            next if(index($route->[0], '*', length($route->[0])-1) == -1);
            next if(rindex($self->{'path'}{'unsafecollapse'}, substr($route->[0], 0, -1), 0) != 0);
            $route->[1]($self);
            return 1;
        }
    }
    $self->{'client'}{'server'}{'route_default'}($self);
    return 1;
}

# unfortunately the absolute url of the server is required for stuff like m3u playlist generation
sub getAbsoluteURL {
    my ($self) = @_;
    return $self->{'client'}{'absurl'} // (defined($self->{'header'}{'Host'}) ? 'http://'.$self->{'header'}{'Host'} : undef);
}

sub _ReqDataLength {
    my ($self, $datalength) = @_;
    $datalength //= 99999999999;
    my $end =  $self->{'header'}{'_RangeEnd'} // ($datalength-1);
    my $dl = $end+1;
    say "_ReqDataLength returning: $dl";
    return $dl;
}

sub _SendResponse {
    my ($self, $fileitem) = @_;
    if(Encode::is_utf8($fileitem->{'buf'})) {
        warn "_SendResponse: UTF8 flag is set, turning off";
        Encode::_utf8_off($fileitem->{'buf'});
    }
    if($self->{'outheaders'}{'Transfer-Encoding'} && ($self->{'outheaders'}{'Transfer-Encoding'} eq 'chunked')) {
        say "chunked response";
        $fileitem->{'is_chunked'} = 1;
    }

    $self->{'response'} = $fileitem;
    $self->{'client'}->SetEvents(POLLOUT | MHFS::EventLoop::Poll->ALWAYSMASK );
}

sub _SendDataItem {
    my ($self, $dataitem, $opt) = @_;
    my $size  = $opt->{'size'};
    my $code = $opt->{'code'};

    if(! $code) {
        # if start is defined it's a range request
        if(defined $self->{'header'}{'_RangeStart'}) {
            $code = 206;
        }
        else {
            $code = 200;
        }
    }

    my $contentlength;
    # range request
    if($code == 206) {
        my $start =  $self->{'header'}{'_RangeStart'};
        my $end =  $self->{'header'}{'_RangeEnd'};
        if(defined $end) {
            $contentlength = $end - $start + 1;
        }
        elsif(defined $size) {
            say 'Implicitly setting end to size';
            $end = $size - 1;
            $contentlength = $end - $start + 1;
        }
        # no end and size unknown. we have 4 choices:
        # set end to the current end (the satisfiable range on RFC 7233 2.1). Dumb clients don't attempt to request the rest of the data ...
        # send non partial response (200). This will often disable range requests.
        # send multipart. "A server MUST NOT generate a multipart response to a request for a single range"(RFC 7233 4.1) guess not

        # LIE, use a large value to signify infinite size. RFC 8673 suggests doing so when client signifies it can.
        # Current clients don't however, so lets hope they can.
        else {
            say 'Implicitly setting end to 999999999999 to signify unknown end';
            $end = 999999999999;
        }

        if($end < $start) {
            say "_SendDataItem, end < start";
            $self->Send403();
            return;
        }
        $self->{'outheaders'}{'Content-Range'} = "bytes $start-$end/" . ($size // '*');
    }
    # everybody else
    else {
        $contentlength = $size;
    }

    # if the CL isn't known we need to send chunked
    if(! defined $contentlength) {
        $self->{'outheaders'}{'Transfer-Encoding'} = 'chunked';
    }
    else {
        $self->{'outheaders'}{'Content-Length'} = "$contentlength";
    }



    my %lookup = (
        200 => "HTTP/1.1 200 OK\r\n",
        206 => "HTTP/1.1 206 Partial Content\r\n",
        301 => "HTTP/1.1 301 Moved Permanently\r\n",
        307 => "HTTP/1.1 307 Temporary Redirect\r\n",
        403 => "HTTP/1.1 403 Forbidden\r\n",
        404 => "HTTP/1.1 404 File Not Found\r\n",
        408 => "HTTP/1.1 408 Request Timeout\r\n",
        416 => "HTTP/1.1 416 Range Not Satisfiable\r\n",
        503 => "HTTP/1.1 503 Service Unavailable\r\n"
    );

    my $headtext = $lookup{$code};
    if(!$headtext) {
        say "_SendDataItem, bad code $code";
        $self->Send403();
        return;
    }
    my $mime     = $opt->{'mime'};
    $headtext .=   "Content-Type: $mime\r\n";

    my $filename = $opt->{'filename'};
    my $disposition = 'inline';
    if($opt->{'attachment'}) {
        $disposition = 'attachment';
        $filename = $opt->{'attachment'};
    }
    elsif($opt->{'inline'}) {
        $filename = $opt->{'inline'};
    }
    if($filename) {
        my $sendablebytes = encode('UTF-8', get_printable_utf8($filename));
        $headtext .=   "Content-Disposition: $disposition; filename*=UTF-8''".uri_escape($sendablebytes)."; filename=\"$sendablebytes\"\r\n";
    }

    $self->{'outheaders'}{'Accept-Ranges'} //= 'bytes';
    $self->{'outheaders'}{'Connection'} //= $self->{'header'}{'Connection'};
    $self->{'outheaders'}{'Connection'} //= 'keep-alive';

    # SharedArrayBuffer
    if($opt->{'allowSAB'}) {
        say "sending SAB headers";
        $self->{'outheaders'}{'Cross-Origin-Opener-Policy'} =  'same-origin';
        $self->{'outheaders'}{'Cross-Origin-Embedder-Policy'} = 'require-corp';
    }

    # serialize the outgoing headers
    foreach my $header (keys %{$self->{'outheaders'}}) {
        $headtext .= "$header: " . $self->{'outheaders'}{$header} . "\r\n";
    }

    $headtext .= "\r\n";
    $dataitem->{'buf'} = $headtext;

    if($dataitem->{'fh'}) {
        $dataitem->{'fh_pos'} = tell($dataitem->{'fh'});
        $dataitem->{'get_current_length'} //= sub { return undef };
    }

    $self->_SendResponse($dataitem);
}

sub Send400 {
    my ($self) = @_;
    my $msg = "400 Bad Request\r\n";
    $self->SendHTML($msg, {'code' => 403});
}

sub Send403 {
    my ($self) = @_;
    my $msg = "403 Forbidden\r\n";
    $self->SendHTML($msg, {'code' => 403});
}

sub Send404 {
    my ($self) = @_;
    my $msg = "404 Not Found";
    $self->SendHTML($msg, {'code' => 404});
}

sub Send408 {
    my ($self) = @_;
    my $msg = "408 Request Timeout";
    $self->{'outheaders'}{'Connection'} = 'close';
    $self->SendHTML($msg, {'code' => 408});
}

sub Send416 {
    my ($self, $cursize) = @_;
    $self->{'outheaders'}{'Content-Range'} = "*/$cursize";
    $self->SendHTML('', {'code' => 416});
}

sub Send503 {
    my ($self) = @_;
    $self->{'outheaders'}{'Retry-After'} = 5;
    my $msg = "503 Service Unavailable";
    $self->SendHTML($msg, {'code' => 503});
}

# requires already encoded url
sub SendRedirectRawURL {
    my ($self, $code, $url) = @_;

    $self->{'outheaders'}{'Location'} = $url;
    my $msg = "UNKNOWN REDIRECT MSG";
    if($code == 301) {
        $msg = "301 Moved Permanently";
    }
    elsif($code == 307) {
        $msg = "307 Temporary Redirect";
    }
    $msg .= "\r\n<a href=\"$url\"></a>\r\n";
    $self->SendHTML($msg, {'code' => $code});
}

# encodes path and querystring
# path and query string keys and values must be bytes not unicode string
sub SendRedirect {
    my ($self, $code, $path, $qs) = @_;
    my $url;
    # encode the path component
    while(length($path)) {
        my $slash = index($path, '/');
        my $len = ($slash != -1) ? $slash : length($path);
        my $pathcomponent = substr($path, 0, $len, '');
        $url .= uri_escape($pathcomponent);
        if($slash != -1) {
            substr($path, 0, 1, '');
            $url .= '/';
        }
    }
    # encode the querystring
    if($qs) {
        $url .= '?';
        foreach my $key (keys %{$qs}) {
            my @values;
            if(ref($qs->{$key}) ne 'ARRAY') {
                push @values, $qs->{$key};
            }
            else {
                @values = @{$qs->{$key}};
            }
            foreach my $value (@values) {
                $url .= uri_escape($key).'='.uri_escape($value) . '&';
            }
        }
        chop $url;
    }

    @_ = ($self, $code, $url);
    goto &SendRedirectRawURL;
}

sub SendLocalFile {
    my ($self, $requestfile) = @_;
    my $start =  $self->{'header'}{'_RangeStart'};
    my $client = $self->{'client'};

    # open the file and get the size
    my %fileitem = ('requestfile' => $requestfile);
    my $currentsize;
    if($self->{'method'} ne 'HEAD') {
        my $FH;
        if(! open($FH, "<", $requestfile)) {
            say "SLF: open failed";
            $self->Send404;
            return;
        }
        binmode($FH);
        my $st = stat($FH);
        if(! $st) {
            $self->Send404();
            return;
        }
        $currentsize = $st->size;
        $fileitem{'fh'} = $FH;
    }
    else {
        $currentsize = (-s $requestfile);
    }

    # seek if a start is specified
    if(defined $start) {
        if($start >= $currentsize) {
            $self->Send416($currentsize);
            return;
        }
        elsif($fileitem{'fh'}) {
            seek($fileitem{'fh'}, $start, 0);
        }
    }

    # get the maximumly possible file size. 99999999999 signfies unknown
    my $get_current_size = sub {
        return $currentsize;
    };
    my $done;
    my $ts;
    my $get_max_size = sub {
        if($done) {
            return $ts;
        }
        my $locksz = LOCK_GET_LOCKDATA($requestfile);
        if(defined($locksz)) {
            $ts = ($locksz || 0);
        }
        else {
            $done = 1;
            $ts = ($get_current_size->() || 0);
        }
    };
    my $filelength = $get_max_size->();

    # truncate to the [potentially] satisfiable end
    if(defined $self->{'header'}{'_RangeEnd'}) {
        $self->{'header'}{'_RangeEnd'} = min($filelength-1,  $self->{'header'}{'_RangeEnd'});
    }

    # setup callback for retrieving current file size if we are following the file
    if($fileitem{'fh'}) {
        if(! $done) {
            $get_current_size = sub {
                return stat($fileitem{'fh'})
            };
        }

        my $get_read_filesize = sub {
            my $maxsize = $get_max_size->();
            if(defined $self->{'header'}{'_RangeEnd'}) {
                my $rangesize = $self->{'header'}{'_RangeEnd'}+1;
                return $rangesize if($rangesize <= $maxsize);
            }
            return $maxsize;
        };
        $fileitem{'get_current_length'} = $get_read_filesize;
    }

    # flag to add SharedArrayBuffer headers
    my @SABwhitelist = ('static/music_worklet_inprogress/index.html');
    my $allowSAB;
    foreach my $allowed (@SABwhitelist) {
        if(index($requestfile, $allowed, length($requestfile)-length($allowed)) != -1) {
            $allowSAB = 1;
            last;
        }
    }

    # finally build headers and send
    if($filelength == 99999999999) {
        $filelength = undef;
    }
    my $mime = getMIME($requestfile);

    my $opt = {
        'size'     => $filelength,
        'mime'     => $mime,
        'allowSAB' => $allowSAB
    };
    if($self->{'responseopt'}{'cd_file'}) {
        $opt->{$self->{'responseopt'}{'cd_file'}} = basename($requestfile);
    }

    $self->_SendDataItem(\%fileitem, $opt);
}

# currently only supports fixed filelength
sub SendPipe {
    my ($self, $FH, $filename, $filelength, $mime) = @_;
    if(! defined $filelength) {
        $self->Send404();
    }

    $mime //= getMIME($filename);
    binmode($FH);
    my %fileitem;
    $fileitem{'fh'} = $FH;
    $fileitem{'get_current_length'} = sub {
        my $tocheck = defined $self->{'header'}{'_RangeEnd'} ? $self->{'header'}{'_RangeEnd'}+1 : $filelength;
        return min($filelength, $tocheck);
    };

    $self->_SendDataItem(\%fileitem, {
        'size'     => $filelength,
        'mime'     => $mime,
        'filename' => $filename
    });
}

# to do get rid of shell escape, launch ssh without blocking
sub SendFromSSH {
    my ($self, $sshsource, $filename, $node) = @_;
    my @sshcmd = ('ssh', $sshsource->{'userhost'}, '-p', $sshsource->{'port'});
    my $fullescapedname = "'" . shell_escape($filename) . "'";
    my $folder = $sshsource->{'folder'};
    my $size = $node->[1];
    my @cmd;
    if(defined $self->{'header'}{'_RangeStart'}) {
        my $start = $self->{'header'}{'_RangeStart'};
        my $end = $self->{'header'}{'_RangeEnd'} // ($size - 1);
        my $bytestoskip =  $start;
        my $count = $end - $start + 1;
        @cmd = (@sshcmd, 'dd', 'skip='.$bytestoskip, 'count='.$count, 'bs=1', 'if='.$fullescapedname);
    }
    else{
        @cmd = (@sshcmd, 'cat', $fullescapedname);
    }
    say "SendFromSSH (BLOCKING)";
    open(my $cmdh, '-|', @cmd) or die("SendFromSSH $!");

    $self->SendPipe($cmdh, basename($filename), $size);
    return 1;
}

# ENOTIMPLEMENTED
sub Proxy {
    my ($self, $proxy, $node) = @_;
    die;
    return 1;
}

# buf is a bytes scalar
sub SendBytes {
    my ($self, $mime, $buf, $options) = @_;

    # we want to sent in increments of bytes not characters
    if(Encode::is_utf8($buf)) {
        warn "SendBytes: UTF8 flag is set, turning off";
        Encode::_utf8_off($buf);
    }

    my $bytesize = length($buf);

    # only truncate buf if responding to a range request
    if((!$options->{'code'}) || ($options->{'code'} == 206)) {
        my $start =  $self->{'header'}{'_RangeStart'} // 0;
        my $end   =  $self->{'header'}{'_RangeEnd'}  // $bytesize-1;
        $buf      =  substr($buf, $start, ($end-$start) + 1);
    }

    # Use perlio to read from the buf
    my $fh;
    if(!open($fh, '<', \$buf)) {
        $self->Send404;
        return;
    }
    my %fileitem = (
        'fh' => $fh,
        'get_current_length' => sub { return undef }
    );
    $self->_SendDataItem(\%fileitem, {
        'size'     => $bytesize,
        'mime'     => $mime,
        'filename' => $options->{'filename'},
        'code'     => $options->{'code'}
    });
}

# expects unicode string (not bytes)
sub SendText {
    my ($self, $mime, $buf, $options) = @_;
    @_ = ($self, $mime, encode('UTF-8', $buf), $options);
    goto &SendBytes;
}

# expects unicode string (not bytes)
sub SendHTML {
    my ($self, $buf, $options) = @_;;
    @_ = ($self, 'text/html; charset=utf-8', encode('UTF-8', $buf), $options);
    goto &SendBytes;
}

# expects perl data structure
sub SendAsJSON {
    my ($self, $obj, $options) = @_;
    @_ = ($self, 'application/json', encode_json($obj), $options);
    goto &SendBytes;
}

sub SendCallback {
    my ($self, $callback, $options) = @_;
    my %fileitem;
    $fileitem{'cb'} = $callback;

    $self->_SendDataItem(\%fileitem, {
        'size'     => $options->{'size'},
        'mime'     => $options->{'mime'},
        'filename' => $options->{'filename'}
    });
}

sub SendAsTar {
    my ($self, $requestfile) = @_;

    if(!HAS_Alien_Tar_Size) {
        warn("Cannot send tar without Alien::Tar::Size");
        $self->Send404();
        return;
    }
    my ($libtarsize) = Alien::Tar::Size->dynamic_libs;
    if(!$libtarsize) {
        warn("Cannot find libtarsize");
        $self->Send404();
        return;
    }

    # HACK, use LD_PRELOAD to hook tar to calculate the size quickly
    my @tarcmd = ('tar', '-C', dirname($requestfile), basename($requestfile), '-c', '--owner=0', '--group=0');
    $self->{'process'} =  MHFS::Process->new(\@tarcmd, $self->{'client'}{'server'}{'evp'}, {
        'SIGCHLD' => sub {
            my $out = $self->{'process'}{'fd'}{'stdout'}{'fd'};
            my $size;
            read($out, $size, 50);
            chomp $size;
            say "size: $size";
            $self->{'process'} = MHFS::Process->new(\@tarcmd, $self->{'client'}{'server'}{'evp'}, {
                'STDOUT' => sub {
                    my($out) = @_;
                    say "tar sending response";
                    $self->{'outheaders'}{'Accept-Ranges'} = 'none';
                    my %fileitem = ('fh' => $out, 'get_current_length' => sub { return undef });
                    $self->_SendDataItem(\%fileitem, {
                        'size' => $size,
                        'mime' => 'application/x-tar',
                        'code' => 200,
                        'attachment' => basename($requestfile).'.tar'
                    });
                    return 0;
                }
            });
        },
    },
    undef, # fd settings
    {
        'LD_PRELOAD' => $libtarsize
    });
}

sub SendDirectory {
    my ($request, $droot) = @_;

    # otherwise attempt to send a file from droot
    my $requestfile = abs_path($droot . $request->{'path'}{'unsafecollapse'});
    say "abs requestfile: $requestfile" if(defined $requestfile);

    # not a file or is outside of the document root
    if(( ! defined $requestfile) ||
    (rindex($requestfile, $droot, 0) != 0)){
        $request->Send404;
    }
    # is regular file
    elsif (-f $requestfile) {
        if(index($request->{'path'}{'unsafecollapse'}, '/', length($request->{'path'}{'unsafecollapse'})-1) == -1) {
            $request->SendFile($requestfile);
        }
        else {
            $request->Send404;
        }
    }
    # is directory
    elsif (-d _) {
        # ends with slash
        if(index($request->{'path'}{'unescapepath'}, '/', length($request->{'path'}{'unescapepath'})-1) != -1) {
            my $index = $requestfile.'/index.html';
            if(-f $index) {
                $request->SendFile($index);
                return;
            }
            $request->Send404;
        }
        else {
            # redirect to slash path
            my $bn = basename($requestfile);
            $request->SendRedirect(301, $bn.'/');
        }
    }
    else {
        $request->Send404;
    }
}

sub SendDirectoryListing {
    my ($self, $absdir, $urldir) = @_;
    my $urf = $absdir .'/'.substr($self->{'path'}{'unsafepath'}, length($urldir));
    my $requestfile = abs_path($urf);
    my $ml = $absdir;
    say "rf $requestfile " if(defined $requestfile);
    if (( ! defined $requestfile) || (rindex($requestfile, $ml, 0) != 0)){
        $self->Send404;
        return;
    }

    if(-f $requestfile) {
        if(index($self->{'path'}{'unsafecollapse'}, '/', length($self->{'path'}{'unsafecollapse'})-1) == -1) {
            $self->SendFile($requestfile);
        }
        else {
            $self->Send404;
        }
        return;
    }
    elsif(-d _) {
        # ends with slash
        if((substr $self->{'path'}{'unescapepath'}, -1) eq '/') {
            opendir ( my $dh, $requestfile ) or die "Error in opening dir $requestfile\n";
            my $buf;
            my $filename;
            while( ($filename = readdir($dh))) {
                next if(($filename eq '.') || ($filename eq '..'));
                next if(!(-s "$requestfile/$filename"));
                my $url = uri_escape($filename);
                $url .= '/' if(-d _);
                $buf .= '<a href="' . $url .'">'.${escape_html_noquote(decode('UTF-8', $filename, Encode::LEAVE_SRC))} .'</a><br><br>';
            }
            closedir($dh);
            $self->SendHTML($buf);
            return;
        }
        # redirect to slash path
        else {
            $self->SendRedirect(301, basename($requestfile).'/');
            return;
        }
    }
    $self->Send404;
}

sub PUTBuf_old {
    my ($self, $handler) = @_;
    if(length($self->{'client'}{'inbuf'}) < $self->{'header'}{'Content-Length'}) {
        $self->{'client'}->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
    }
    my $sdata;
    $self->{'on_read_ready'} = sub {
        my $contentlength = $self->{'header'}{'Content-Length'};
        $sdata .= $self->{'client'}{'inbuf'};
        my $dlength = length($sdata);
        if($dlength >= $contentlength) {
            say 'PUTBuf datalength ' . $dlength;
            my $data;
            if($dlength > $contentlength) {
                $data = substr($sdata, 0, $contentlength);
                $self->{'client'}{'inbuf'} = substr($sdata, $contentlength);
                $dlength = length($data)
            }
            else {
                $data = $sdata;
                $self->{'client'}{'inbuf'} = '';
            }
            $self->{'on_read_ready'} = undef;
            $handler->($data);
        }
        else {
            $self->{'client'}{'inbuf'} = '';
        }
        #return '';
        return 1;
    };
    $self->{'on_read_ready'}->();
}

sub PUTBuf {
    my ($self, $handler) = @_;
    if($self->{'header'}{'Content-Length'} > 20000000) {
        say "PUTBuf too big";
        $self->{'client'}->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
        $self->{'on_read_ready'} = sub { return undef };
        return;
    }
    if(length($self->{'client'}{'inbuf'}) < $self->{'header'}{'Content-Length'}) {
        $self->{'client'}->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
    }
    $self->{'on_read_ready'} = sub {
        my $contentlength = $self->{'header'}{'Content-Length'};
        my $dlength = length($self->{'client'}{'inbuf'});
        if($dlength >= $contentlength) {
            say 'PUTBuf datalength ' . $dlength;
            my $data;
            if($dlength > $contentlength) {
                $data = substr($self->{'client'}{'inbuf'}, 0, $contentlength, '');
            }
            else {
                $data = $self->{'client'}{'inbuf'};
                $self->{'client'}{'inbuf'} = '';
            }
            $self->{'on_read_ready'} = undef;
            $handler->($data);
        }
        return 1;
    };
    $self->{'on_read_ready'}->();
}

sub SendFile {
    my ($self, $requestfile) = @_;
    foreach my $uploader (@{$self->{'client'}{'server'}{'uploaders'}}) {
        return if($uploader->($self, $requestfile));
    }
    say "SendFile - SendLocalFile $requestfile";
    return $self->SendLocalFile($requestfile);
}

1;
