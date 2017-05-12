package Dancer::Plugin::FakeCGI;

use strict;
use warnings;

use Dancer::Plugin;
use Dancer::Config;
use Dancer ':syntax';

use Cwd;
use CGI::Compile;
use HTTP::Message;
use Test::TinyMocker;
use Carp;
use Symbol;
use IO::File;
use IO::Scalar;
use File::Temp;
use Fcntl;

use Data::Dumper;

=encoding utf8

=head1 NAME

Dancer::Plugin::FakeCGI - run CGI methods or Perl-files under Dancer

=head1 SYNOPSIS

=head1 DESCRIPTION

Supports to run CGI perl files on CGI methods under Dancer.

=head1 CONFIGURATION

    plugins:
       FakeCGI:
          cgi-dir: 'cgi-dir'
          cgi-bin: '/cgi-bin'
          cgi-package: 'lib/CGI'
          cgi-class: ourCGI
          stdout-type: "file"
          temp-dir: "tmp"

=over

=item B<cgi-dir> - for setting directory where is placed Perl CGI file, standart is 'cgi-dir'. This directory must be in root on Dancer directory.

=item B<cgi-bin> - web url directory where are Perl CGI files visible. Must be set.

=item B<cgi-package> - for setting INC library where is CGI packagesa(loaded from B<fake_cgi_method>), standart is nothing.

=item B<cgi-class> - definition child-classes for CGI, it can be defined as ARRAY, standart every 'CGI*::'

=item B<stdout-type> - where will be saved captured string from F<STD[OUT|ERR]>, standart is capture into memory. Change with this options:

=over 2

=item B<file> - captured string will be saved in directory defined B<temp-dir> and in C<after> hook will be avery temp file removed

=item B<memory> - for saving captured string use IO::Scalar

=back

=item B<temp-dir> - temporary directory where will be save all captured files if B<stdout-type> is set to file. Best option is use B<file> captured and B<temp-dir> mount as RAM filesystem

=back

=head1 TODO

=over

=item B<1> - Maybe captured string parsed in HTTP::Message->parse

=item B<2> - CGI::Push use infinity loop which not existed than we don't capture any string from STDOUT and doesn't send any data.

=item B<3> - script_name() with referer

=item B<4> - Mod_PERL emulation for version 2

=item B<5> - find better solution for capturing STD[OUT|ERR] under system() call when capture to memory used

=item B<6> - Performance issue : 

every CGI files are loaded(served) 20-50% slowest then under Mod_PERL(Registry.pm). This emulation get about 15-20ms more than uner Apache. Next difference is capture in memory and to file. 
In memory is 10-20% faster. One problem finded and there is Cwd::cwd() function which is slowest than getcwd() and take 65ms. 
CGI::Compile() is similar as Mod_PERL::PerlRun(). Everytime it run eval() on given loaded code. 
If we want to use behavior as Apache::Registry(), than should on first time evaled of given code to memory as package with function and 
other every call run this method to omited evaled code into memory.

=back

=head1 BUGS

=over

=item B<1> - Not use infinity loop!!! Every CGI script must exited - finished to run properly in Dancer

=item B<2> -Problem with fork|system function under HTTP::Server::Simple. This server make bad opening file descriptor of STDOUT. On this server it will be redirected to STDERR

=back

=head1 METHODS

=cut

our $VERSION = '0.63';

# Own handles
my $settings       = undef;
my %handle_require = ();
my %handle_file    = ();

my $capture = undef;
sub Is_Win32 { $^O eq 'MSWin32' && basename($^X) eq 'wperl.exe' }

# Must first initialize faked Apache.pm and after that CGI
BEGIN {
    my ($pack, $filename) = caller;
    my $dir = $filename;
    $dir =~ s/\.pm//;

    *CORE::GLOBAL::system = \&_own_system;    # Emulation of 'system'

    # Import fake Apache
    #unshift(@INC, $dir);    # Add directories with Apache.pm as first position
    #require Apache1;
    #shift(@INC);
    require Dancer::Plugin::FakeCGI::Apache1;
    Apache->import;

    local %ENV = %ENV;
    $ENV{MOD_PERL}             = 1;
    $ENV{MOD_PERL_API_VERSION} = 1;

    #Disabling CGI::Push module
    $INC{"CGI/Push.pm"} = $INC{'Dancer/Plugin/FakeCGI.pm'};

    # Import CGI
    require CGI;

    CGI->import('read_from_client', 'read_from_cmdline', 'new_MultipartBuffer');
    CGI::initialize_globals()
      if defined &CGI::initialize_globals;    # Initialize CGI

    $ENV{MOD_PERL}             = 0;
    $ENV{MOD_PERL_API_VERSION} = 0;
    require CGI::Cookie;                      # Better is use CGI::Cookie without MOD_PERL functionalities
}

#################################################################################################
# CGI start                                                                                     #
#################################################################################################
$Dancer::Plugin::FakeCGI::Apache1::CGI_obj = CGI->new();    # Initialization for faked mod_perl emulation back to CGI

# Disabling CGI::Push
{

    package CGI::Push;

    use vars qw{$AUTOLOAD};
    use Carp;

    sub AUTOLOAD {
        my $self = shift;

        my $name = $AUTOLOAD;
        $name =~ s/.*://;    # strip fully-qualified portion

        croak "Emulation for CGI::Push module doesn't implement, because it use infinity loop....";
    }

    sub import {
        croak "Emulation for CGI::Push module doesn't implement, because it use infinity loop....";
    }
}

# Initialize some CGI methods and mocking
my @CGI_mock_methods = ('header', 'redirect');
foreach my $k (@CGI_mock_methods) {
    no strict 'refs';
    &{"CGI::" . $k}();    # Try run first for compiled given sub in CGI
    Test::TinyMocker::mock("CGI", $k, \&{"_cgi_" . $k});
}

# Return if first position in method is some of CLASS
sub _cgi_self_test {
    return 0 if (!defined($_[0]) || !ref($_[0]));
    return 1
      if (ref($_[0]) eq "CGI" || ref($_[0]) =~ /CGI::/);    # Its CGI object or Children from CGI
    return 0 unless ($settings->{'cgi-class'});
    if (ref($settings->{'cgi-class'}) eq "ARRAY") {
        foreach (@{$settings->{'cgi-class'}}) {
            return 1 if (ref($_[0]) eq $_);
        }
    } else {
        return 1 if (ref($_[0]) eq $settings->{'cgi-class'});
    }
    warn "First param is reference, but is not set : " . ref($_[0])
      if (ref($_[0]));
    return 0;
}

# Retype header function
sub _cgi_header {

    my $self = _cgi_self_test(@_) ? shift(@_) : undef;

    # old CGI
    my @p = @_;

    return "" if $self && $self->{'.header_printed'}++ and $CGI::HEADERS_ONCE;

    my ($type, $status, $cookie, $target, $expires, $nph, $cgi_charset, $attachment, $p3p, @other) = CGI::rearrange([
            ['TYPE', 'CONTENT_TYPE', 'CONTENT-TYPE'],
            'STATUS', ['COOKIE', 'COOKIES'],
            'TARGET', 'EXPIRES', 'NPH', 'CHARSET', 'ATTACHMENT', 'P3P'
        ],
        @p
    );

    #_fix_CGI_into_Dancer();	# It question if we wanted fix CGI into Dancer

    # CR escaping for values, per RFC 822
    for my $header ($type, $status, $cookie, $target, $expires, $nph, $cgi_charset, $attachment, $p3p, @other) {
        if (defined $header) {

            # From RFC 822:
            # Unfolding  is  accomplished  by regarding   CRLF   immediately
            # followed  by  a  LWSP-char  as equivalent to the LWSP-char.
            $header =~ s/$CGI::CRLF(\s)/$1/g;

            # All other uses of newlines are invalid input.
            if ($header =~ m/$CGI::CRLF|\015|\012/) {

                # shorten very long values in the diagnostic
                $header = substr($header, 0, 72) . '...'
                  if (length $header > 72);
                croak "Invalid header value contains a newline not followed by whitespace: $header";
            }
        }
    }

    $nph ||= $CGI::NPH;

    # Set content type
    content_type($type || 'text/html');

    # sets if $charset is given, gets if not

    if (defined $cgi_charset) {
        charset($cgi_charset);
    } elsif ($type && $type =~ /^text\//) {
        $cgi_charset = setting('charset');
    }
    $cgi_charset ||= '';

    # rearrange() was designed for the HTML portion, so we need to fix it up a little.
    my @other_headers;
    for (@other) {

        # Don't use \s because of perl bug 21951
        next unless my ($header, $value) = /([^ \r\n\t=]+)=\"?(.+?)\"?$/s;
        $header =~ s/^(\w)(.*)/"\u$1\L$2"/e;
        push @other_headers, {$header => CGI::unescapeHTML($value)};
    }

    $type .= "; charset=$cgi_charset"
      if $type
          and $type ne ''
          and $type !~ /\bcharset\b/
          and defined $cgi_charset
          and $cgi_charset ne '';

    # Maybe future compatibility.  Maybe not.
    my $protocol = $ENV{SERVER_PROTOCOL} || 'HTTP/1.0';

    #push(@header,$protocol . ' ' . ($status || '200 OK')) if $nph;
    $status ||= 200 if $nph;

    push_header("Server", CGI::server_software()) if $nph;

    if ($status) {
        $status = _parse_int($status);
        status($status) if ($status);
    }

    push_header "Window-Target" => $target if $target;
    if ($p3p) {
        $p3p = join ' ', @$p3p if ref($p3p) eq 'ARRAY';
        $p3p =~ s/CP=//;
        $p3p =~ s/"//;
        push_header "P3P" => 'policyref="/w3c/p3p.xml", CP="' . $p3p . '"';
    }

    # push all the cookies -- there may be several
    if ($cookie) {
        my (@cookie) = ref($cookie) && ref($cookie) eq 'ARRAY' ? @{$cookie} : $cookie;
        for my $cs (@cookie) {
            if (UNIVERSAL::isa($cs, 'CGI::Cookie')) {
                my $self_cookie = $cs;
                next unless $self_cookie->name;

                my %h = (name => CGI::escape($self_cookie->name));

                #my $value = join "&", map { CGI::escape($_) } $self_cookie->value;
                my @a_value = $self_cookie->value;
                if (scalar(@a_value) > 1) {
                    my %h_value = (@a_value);
                    $h{value} = \%h_value;
                } else {
                    $h{value} = $a_value[0];
                }
                foreach my $k ('domain', 'path', 'expires', 'secure') {
                    $h{$k} = $self_cookie->$k if $self_cookie->$k;
                }

                $h{'max-age'} = $self_cookie->max_age if $self_cookie->max_age;
                $h{'http_only'} = 1 if $self_cookie->httponly;

                set_cookie(%h);
            } else {
                push_header("Set-Cookie", $cs) if $cs ne '';
            }
        }
    }

    # if the user indicates an expiration time, then we need
    # both an Expires and a Date header (so that the browser is uses OUR clock)
    push_header "Expires" => CGI::expires($expires, 'http') if $expires;
    push_header "Date" => CGI::expires(0, 'http')
      if $expires || $cookie || $nph;

    push_header "Pragma" => "no-cache" if ($self && $self->cache());
    push_header "Content-Disposition" => "attachment; filename=\"$attachment\""
      if $attachment;

    push_header map { ucfirst $_ } @other if (@other);
    foreach my $rh (@other_headers) {
        push_header %$rh;
    }

    return '';
}

# Retype read_from_client function
sub _cgi_read_from_client {
    shift(@_) if (_cgi_self_test(@_));

    my $buf    = (ref($_[0]) eq "SCALAR") ? $_[0] : \$_[0];
    my $len    = $_[1];
    my $offset = $_[2] || 0;

    no strict 'refs';
    $$buf = substr(request->body(), $offset, $len);
    return length($$buf);
}

# Retype read_from_cmdline function
sub _cgi_read_from_cmdline {
    shift(@_) if (_cgi_self_test(@_));

    my $str = "";
    _cgi_read_from_client(\$str, 0);
    my ($subpath);
    return {'query_string' => $str, 'subpath' => $subpath};
}

# Retype redirect function
sub _cgi_redirect {

    my $self = _cgi_self_test(@_) ? shift(@_) : CGI->new;
    my @p = @_;

    my ($url, $target, $status, $cookie, $nph, @other) =
      CGI::rearrange([['LOCATION', 'URI', 'URL'], 'TARGET', 'STATUS', ['COOKIE', 'COOKIES'], 'NPH'], @p);
    $status = '302 Found' unless defined $status;
    $url ||= $self->self_url;
    my (@o);
    for (@other) { tr/\"//d; push(@o, split("=", $_, 2)); }
    unshift(
        @o,
        '-Status'   => $status,
        '-Location' => $url,
        '-nph'      => $nph
    );
    unshift(@o, '-Target' => $target) if $target;
    unshift(@o, '-Type' => '');
    my @unescaped;
    unshift(@unescaped, '-Cookie' => $cookie) if $cookie;

    return $self->header((map { $self->unescapeHTML($_) } @o), @unescaped);
}

# Retype new_MultipartBuffer function
sub _cgi_new_MultipartBuffer {
    my $self = shift;
    my $new = Dancer::Plugin::FakeCGI::MultipartBuffer->new($self, @_);

    #$new->{'.req'} = $self->{'.req'} || Apache->request;
    return $new;
}

#################################################################################################
# CGI end                                                                                       #
#################################################################################################

#
my $dancer_version = (exists &dancer_version) ? int(dancer_version()) : 1;
my ($logger);
if ($dancer_version == 1) {
    require Dancer::Config;
    Dancer::Config->import();

    #$logger = sub { Dancer::Logger->can($_[0])->($_[1]) };
} else {

    #$logger = sub { log @_ };
}

# Return path where are cgi-bin files
sub _ret_cgi_bin_path {
    return path(setting('confdir'), defined($_[0]) ? $_[0] : $settings->{'cgi-dir'});
}

# Perl trim function to remove whitespace from the start and end of the string
sub _trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

# Loading setting
sub _load_settings {
    return if (defined($settings) && ref($settings) eq "HASH");
    my $first = defined($settings) ? 0 : 1;
    $settings = plugin_setting() || {};
    unshift(@INC, _ret_cgi_bin_path($settings->{'cgi-package'})) if ($first && $settings->{'cgi-package'});
    $settings->{'cgi-dir'} ||= 'cgi-dir';

    my $dir = _ret_cgi_bin_path();
    unless (-d $dir) {
        croak "Directory doesn't exists : $dir";
    }
    unless ($settings->{'cgi-bin'}) {
        croak "Setting 'cgi-bin' must be setted";
    }

    $settings->{'stdout-type'} ||= 'memory';
    if ($settings->{'stdout-type'} eq "file") {
        unless ($settings->{'temp-dir'}) {
            croak "Setting 'temp-dir' must be setted";
        }
        unless (-d $settings->{'temp-dir'}) {
            croak "Setting 'temp-dir:" . $settings->{'temp-dir'} . "' isn't directory";
        }
        unless (-r $settings->{'temp-dir'}) {
            croak "Not readable directory :" . $settings->{'temp-dir'};
        }
        unless (-w $settings->{'temp-dir'}) {
            croak "Not writable directory :" . $settings->{'temp-dir'};
        }
    } else {
        $settings->{'stdout-type'} = 'memory';
    }

    # Repair url
    if ($first) {
        my $string = _trim($settings->{'cgi-bin'});
        $string =~ s/\/$//;
        $string =~ s/^\///;
        $settings->{'cgi-bin'} = "/" . $string;
    }

    return unless ($first);
}

# Method for loading module
sub _load_package {
    my $package = shift;

    my $pack = caller;
    unless (exists($handle_require{$package})) {
        my ($eval_result, $eval_error) = _eval("package $pack;require $package @_;1;");
        croak("Problem with require $package: $eval_error")
          unless ($eval_result);
        $handle_require{$package} = 1;
        return $eval_result;
    }
    return 1;
}

# Test if given file can run
sub _test_runable {
    my $fname = shift || return "Not defined filename";

    if (-r $fname && -s $fname) {
        if (-d $fname) {
            return "Is directory";
        }
        unless (-x $fname or Is_Win32) {
            return "File permissions deny server execution";
        }
        return undef;
    }
    return "Filename not found or unable to stat : $fname";
}

# Return filename
sub _get_file_name {
    my ($name, $ret_filename) = @_;

    unless (defined($name)) {
        croak("Not defined filename");
        return undef;
    }

    my $dir      = _ret_cgi_bin_path();
    my $filename = $dir . "/" . $name;
    my $tf       = _test_runable($filename);
    if ($tf) {
        croak $tf;
        return undef;
    }

    return ($ret_filename ? $filename : $name);
}

my $run_code_evaled = 0;

# Own function os system() for capturing string
sub _own_system {
    my @args = @_;

    return CORE::system(@args) unless ($run_code_evaled);

    # Flushing STDOUT and STDERR to file or memory to prevent problems
    flush STDERR;
    flush STDOUT;

    if ($ENV{SERVER_SOFTWARE} && $ENV{SERVER_SOFTWARE} =~ /HTTP::Server::Simple/) {
        warn
          "In HTTP::Server::Simple is problem with redirect STDOUT under forked/system proccess, use plackup instead this server !!!";
    } elsif ($settings->{'stdout-type'} eq "memory") {
        warn "system() function can't capture STDOUT when is set to memory, must be set to file !!!";

        #require IPC::Open3;
        #my $rdr;
        #my $err = Symbol::gensym;
        #my $pid = IPC::Open3::open3(undef, $rdr, $err, @args);
        #waitpid( $pid, 0 );
        #return $? >> 8;
    }

    require Capture::Tiny;
    my ($out, $err) = Capture::Tiny::capture {
        return CORE::system(@args);
    };
    print STDERR $err if ($err);
    print STDOUT $out if ($out);
}

# Method for compile files
sub _compile_file {
    my ($file, $is_perl, $package_name) = @_;

    my $filename = _get_file_name($file, 1) || return;
    my $mtime = (stat($filename))[9];

    # Test if compiled name exist and it isn't newer
    if ($handle_require{$file} && (!$handle_require{$file}->{'mtime'} || $mtime != $handle_require{$file}->{'mtime'})) {
        $is_perl = $handle_require{$file}->{'is_perl'};
        delete($handle_require{$file});
    }

    debug("After testing $file");

    my $sub = undef;
    unless (exists($handle_require{$file})) {

        # Change to current dir where is cgi-bin
        my $currWorkDir = Cwd::cwd();

        #my $dir = dirname($file);
        my $dir = _ret_cgi_bin_path();
        chdir($dir);

        my ($eval, $package, $fn_name);
        if ($is_perl) {

            #$sub = CGI::Compile->compile($file, $package_name);
            ($sub, $eval, $package, $fn_name) = CGI::Compile->compile($file, $package_name, undef, "handler");
            unless ($sub) {
                my ($eval_result, $eval_error) = _eval($eval);
                no strict 'refs';
                $sub = \&{$package . "::" . $fn_name};
            }
        } else {
            my $cgi = $file;
            $cgi =~ s/^\.//;
            $cgi =~ s/^\///;
            $sub = sub {
                system("./" . $cgi);
                if ($? == -1) {
                    die "failed to execute CGI '$cgi': $!";
                } elsif ($? & 127) {
                    die sprintf "CGI '$cgi' died with signal %d, %s coredump", ($? & 127), ($? & 128) ? 'with' : 'without';
                } else {
                    my $exit_code = $? >> 8;

                    return 0 if $exit_code == 0;

                    die "CGI '$cgi' exited non-zero with: $exit_code";
                }
            };
        }
        chdir($currWorkDir);
        $handle_require{$file} =
          {mtime => $mtime, code => $sub, is_perl => $is_perl, package => $package, func => $fn_name, loaded => 0};
    } elsif (ref($handle_require{$file}) eq "HASH") {
        $sub = $handle_require{$file}->{'code'};
    }

    debug("Loading $file");
    return $sub, $handle_require{$file};
}

# return int from scalar
sub _parse_int {
    my $ret = $_[0] || return 0;

    $ret =~ s/\D*$//;
    return $ret ? int(0 . $ret) : 0;
}

# Eval function
sub _eval {
    my ($code, @args) = @_;

    # Work around oddities surrounding resetting of $@ by immediately
    # storing it.
    my ($sigdie, $eval_result, $eval_error);
    {
        local ($@, $!, $SIG{__DIE__});    # isolate eval
        $eval_result = eval $code;               ## no critic (BuiltinFunctions::ProhibitStringyEval)
        $eval_error  = $@;
        $sigdie      = $SIG{__DIE__} || undef;
    }

    # make sure that $code got a chance to set $SIG{__DIE__}
    $SIG{__DIE__} = $sigdie if defined $sigdie;

    return ($eval_result, $eval_error);
}

# Function for added params in dancer which can be changed in CGI
sub _fix_CGI_into_Dancer {
    my @a = CGI::param();
    pop(@a) if (scalar(@a) % 2);    # Odd count of params, problems in CGI::Util::rearange
    my %all_CGI_params    = (@a);
    my $all_Dancer_params = params();

    # Added CGI param into Dancer
    while (my ($k, $d) = each %all_CGI_params) {
        $all_Dancer_params->{$k} = $d;
    }

    # Added CGI param into Dancer
    while (my ($k, $d) = each %$all_Dancer_params) {
        next if ($k eq "splat");
        $all_Dancer_params->{$k} = undef unless (exists($all_CGI_params{$k}));
    }
}

#################################################################################################
# Capture start                                                                                 #
#################################################################################################
# Initialization of captured(use_STDOUT, use_STDERR)
sub _capture_start {

    my @a_type = ();
    push(@a_type, "STDOUT") if (shift);    # If first param true, than capture STDOUT
    push(@a_type, "STDERR") if (shift);    # If second params true, than capture STDERR

    $capture ||= {STDOUT => {}, STDERR => {}};
    foreach my $type (@a_type) {
        my $rh = $capture->{$type};

        # If captured print error and return
        if ($rh->{"old_fh"}) {
            croak "Type $type is already captured";
            next;
        }

        # If not initialized than made primary initalization
        if ($settings->{'stdout-type'} eq 'memory') {
            $rh->{"string"} ||= '';
        } else {
            ($rh->{"io_fh"}, $rh->{"filename"}) = File::Temp::tempfile(
                DIR => path(setting('confdir'), $settings->{'temp-dir'}),

                #TEMPLATE => 'tempXXXXX',
                SUFFIX => "." . $type,
                UNLINK => 0,             # We unlink automatically in after hook
                OPEN   => 1,
                EXLOCK => 1,
            ) unless (exists($rh->{"io_fh"}));
        }

        open(my $fh, ">&" . $type) or die "Can't dup $type: $!";
        $rh->{"std_fh"} = $fh;

        no strict 'subs';
        close($type eq "STDERR" ? STDERR : STDOUT);

        if ($settings->{'stdout-type'} eq 'memory') {
            my $result;
            if ($type eq "STDERR") {
                $result = open(STDERR, '>>', \$rh->{"string"});
            } else {
                $result = open(STDOUT, '>>', \$rh->{"string"});
            }
            die "Can't redirect $type to scalar : $!" unless ($result);
            $rh->{"io_fh"} = new IO::Scalar \$rh->{"io_fh"} if ($type eq "STDOUT" && !exists($rh->{"io_fh"}));
        } else {
            my $result;
            if ($type eq "STDERR") {

                #$result = open(\*STDERR, '>&=' . fileno($rh->{"io_fh"}));
                $result = open(\*STDERR, '>>', $rh->{"filename"});
            } else {
                $result = open(\*STDOUT, '>>', $rh->{"filename"});
            }
            die "Can't redirect $type to " . $rh->{"filename"} . " : $!" unless ($result);

            #my $flags = fcntl($rh->{"io_fh"}, F_GETFL, 0);
            #$flags |= O_APPEND;    # Add non-blocking to the flags
            #fcntl($rh->{"io_fh"}, F_SETFL, $flags) || die "Can't set flags from '$type' to O_APPEND : $!";    # Set the flags on the f
        }

        binmode($type eq "STDERR" ? STDERR : STDOUT, ":utf8") if $] >= 5.008;
        select($type eq "STDERR" ? STDERR : STDOUT);
        $| = 1;
        select(STDOUT);
    }
}

# Endingn or stop capturing
sub _capture_end {
    return if (!$capture || ref($capture) ne "HASH");

    foreach my $type ("STDOUT", "STDERR") {
        next if (!exists($capture->{$type}) || !$capture->{$type}->{"std_fh"});
        no strict 'subs';
        if ($type eq "STDERR") {
            flush STDERR;
            open(STDERR, ">&", $capture->{$type}->{"std_fh"}) or die "Can't restore old STDERR: $!";
        } else {
            flush STDERR;
            open(STDOUT, ">&", $capture->{$type}->{"std_fh"}) or die "Can't restore old STDOUT: $!";
        }
        delete($capture->{$type}->{"std_fh"});
    }
    select(STDOUT);
}

#################################################################################################
# Capture end                                                                                   #
#################################################################################################

# what we run on before hook
hook before => sub {
    my $route_handler = shift;

    undef $capture;
};

# what we run on after hook
hook after => sub {
    if (ref($capture) eq "HASH") {
        foreach my $type ("STDOUT", "STDERR") {
            close($capture->{$type}->{"io_fh"}) if ($capture->{$type}->{"io_fh"});
            unlink($capture->{$type}->{"filename"}) if ($capture->{$type}->{"filename"});
        }
    }
    undef $capture;
};

hook before_template_render => sub {
    my $tokens = shift;

    _fix_CGI_into_Dancer();    # Fix Dancer variables after CGI runned before template rendering
};

=head3 <$capture> - is reference to this HASH

=over

=item F<STDOUT|STDERR> - type of captured string for given output. It is HASH reference to this other options:

=over 2

=item B<string> - if setting enabled capturing to memory this is string contains every characters captured

=item B<io_fh> - handler to L<IO::File> if is set to capturing into file, if is set to memory it is handler to L<IO::Scalar>

=item B<filename> - filename with path if capturing is to file

=item B<header_len> - this is size of HTTP header. On this position start HTML content. It is only for capturing into file

=item B<std_fh> - saved original filehandler into this param if is capturing enabled. If capturing stop than this option not exist

=back

=back


=head3 PARAMS for C<_run_code()> is hashref

=over

=item B<capture_stderr> - B<STDERR> will be captured similar as B<STDOUT> and when eval(_run_code) finished, that will be loged

=item B<timeout> - in seconds which can timeouted given eval via alarm() function. If is B<0|undefined> - disabled it

=item B<ret_error> - try run given code and return after eval

=back

=cut

sub _run_code {
    my $code = shift || return;
    return if (ref($code) ne "CODE");
    my $params = shift || {};
    my $filename = shift;

    my $env = request->env();
    local %ENV = (%ENV, (map { $_ => $env->{$_} } grep !/^psgix?\./, keys %$env));
    foreach my $k (
        qw/
        SERVER_SOFTWARE SERVER_NAME GATEWAY_INTERFACE SERVER_PROTOCOL
        SERVER_PORT REQUEST_METHOD PATH_INFO SCRIPT_NAME QUERY_STRING
        REMOTE_HOST REMOTE_ADDR CONTENT_TYPE CONTENT_LENGTH HTTP_ACCEPT HTTP_USER_AGENT/,

        #qw/MOD_PERL PATH_TRANSLATED AUTH_TYPE REMOTE_TYPE REMOTE_IDENT/
      ) {

        #croak("Not existed '$k' in Enviroment") unless (exists($ENV{$k}));
    }

    # Settings from config
    if ($settings->{'Enviroments'}) {
        while (my ($k, $d) = each %{$settings->{'Enviroments'}}) {
            $ENV{$k} = $d;
        }
    }

    # Repair couple of settings
    $ENV{MOD_PERL}      = 1;                     # put to all of programs, when we emulate Mod_PERL version 1
    $ENV{DOCUMENT_ROOT} = _ret_cgi_bin_path();
    $ENV{SCRIPT_FILENAME} = $ENV{DOCUMENT_ROOT} . "/" . $ENV{PATH_INFO};

    #$ENV{SCRIPT_NAME}     = $ENV{PATH_INFO};

    # Repair PATH_INFO and SCRIPT_NAME
    {
        my $sname = $ENV{PATH_INFO};
        delete($ENV{PATH_INFO});

        my $s = $settings->{'cgi-bin'};
        if ($s && $s ne "/") {
            $sname =~ s/$s//;
        }
        $sname =~ s/^\///;
        my @a_name = split('/', $sname);
        $ENV{SCRIPT_NAME} = fake_cgi_bin_url(shift(@a_name));

        # CGI.pm use referer from ENV{HTTP_REFERER}
        #$ENV{SCRIPT_NAME} .= ", referer: " . $ENV{HTTP_REFERER} if ($ENV{HTTP_REFERER} && length($ENV{HTTP_REFERER}));
        $ENV{PATH_INFO} = "/" . join('/', @a_name) if (scalar(@a_name));
    }
    debug("After ENV");

    CGI::initialize_globals()
      if defined &CGI::initialize_globals;    # Initialize CGI

    debug("After CGI::initialize_globals");

    my $str_alarmed = "alarm is called...\n";

    my ($ret, $err) = (undef, undef);
    {
        _capture_start(1, (!$params->{ret_error} && $params->{capture_stderr}) ? 1 : 0);
        debug("After _capture_start() ");

        Dancer::Factory::Hook->instance->execute_hooks('fake_cgi_before', \%ENV, $capture) unless ($params->{ret_error});
        debug("After hook: fake_cgi_before ");

        # Change to current dir where is cgi-bin
        #my $currWorkDir = Cwd::cwd();	# calling method cwd() is slowest than getcwd and use about 65ms
        my $currWorkDir = Cwd::getcwd();
        debug("After Cwd...");

        my $dir = _ret_cgi_bin_path();
        chdir($dir);

        debug("Before eval given code() ");

        #make sure this hooks are restored to their original state
        local $SIG{__DIE__}  = $SIG{__DIE__};
        local $SIG{__WARN__} = $SIG{__WARN__};

        # CGI::Compile made it
        ## Change script name
        #my $old_name = $0;
        ##local $0 = $filename; #this core dumps!?
        #*0 = \$filename if ($filename);

        $run_code_evaled = 1;

        # Test for timeout
        local $SIG{ALRM} = $SIG{ALRM};
        my $timeout = _parse_int($params->{timeout});
        if ($timeout) {
            $SIG{ALRM} = sub { die $str_alarmed };
            alarm $timeout;
        }

        eval {    # Run compiled code
            no strict 'refs';
            $ret = &{$code}();
        };

        alarm(0) if ($timeout);

        $err = $@;    # Save error to scalar

        #*0 = $old_name;

        $run_code_evaled = 0;
        chdir($currWorkDir);

        debug("After eval given code() ");

        _capture_end();
        debug("After _capture_end() ");
    }

    return $err if ($params->{ret_error});

    # When is in CGI called system() function, there is problem with filehandle and it is a blocked, then try to reopen it
    sub _reopen_file {
        return unless ($_[0]);
        close($_[0]) or warn "Can't close IO handler";
        open(my $fh, "<:utf8", $_[0]) or die "Can't reopen for reading : $!";
        return $fh;
    }

    # Print captured string on STDERR
    if ($capture->{"STDERR"}->{string}) {
        debug $capture->{"STDERR"}->{string};
    } elsif ($capture->{"STDERR"}->{io_fh}) {

        #$capture->{io_err} = _reopen_file($capture->{io_err});
        seek($capture->{"STDERR"}->{"io_fh"}, 0, SEEK_SET);

        # Print everything in STDERR as one line
        debug $capture->{"STDERR"}->{"io_fh"}->getlines();
        unlink($capture->{"STDERR"}->{"filename"}) if ($capture->{"STDERR"}->{"filename"});
    }
    delete($capture->{"STDERR"});
    debug("After STDERR print ");

    # Get on first position
    if ($settings->{'stdout-type'} eq 'file') {

        #$capture->{io_out} = _reopen_file($capture->{io_out});
    } elsif (exists($capture->{"STDOUT"}) && $capture->{"STDOUT"}->{"io_fh"}) {
        seek($capture->{"STDOUT"}->{"io_fh"}, 0, SEEK_SET);
    }

    # If error captured, than we finish
    if ($err) {
        croak $err eq $str_alarmed
          ? "Timeouted after " . $params->{timeout} . " seconds"
          : $err;
        return;
    }

    # Delete headers from captured STDOUT
    if (exists($capture->{"STDOUT"}) && $capture->{"STDOUT"}->{"io_fh"}) {
        my $r_str   = undef;
        my $str_len = 0;
        if ($capture->{"STDOUT"}->{"string"}) {
            $r_str = \$capture->{"STDOUT"}->{"string"};
        } else {
            my $str = '';
            $str_len = read($capture->{"STDOUT"}->{"io_fh"}, $str, 8 * 1024);    # Read 8kB from file a find if it isn't header
            $r_str = \$str;
        }

        # From HTTP::Message->parse
        my @hdr;
        while (1) {
            unless ($r_str) {
                last;
            } elsif ($$r_str =~ s/^([^\s:]+)[ \t]*: ?(.*)\n?//) {
                push(@hdr, $1, $2);
                $hdr[-1] =~ s/\r\z//;
            } elsif (@hdr && $$r_str =~ s/^([ \t].*)\n?//) {
                $hdr[-1] .= "\n$1";
                $hdr[-1] =~ s/\r\z//;
            } else {
                $$r_str =~ s/^\r?\n//;
                last;
            }
        }

        if ($settings->{'stdout-type'} eq 'file') {
            my $l = length($$r_str);
            $capture->{"STDOUT"}->{"header_len"} = ($l < $str_len) ? ($str_len - $l) : 0;
            seek($capture->{"STDOUT"}->{"io_fh"}, $capture->{"STDOUT"}->{"header_len"}, SEEK_SET);
        }

        #my $mess = HTTP::Message->new(\@hdr, $$r_str);
        my $mess = HTTP::Message->new(\@hdr, "");
        my $h = $mess->headers;

        content_type $h->content_type if ($h->content_type);

        #charset($h->content_type_charset) if ($h->content_type_charset);

        $h->remove_header('Content-Type');
        my @ak = $h->header_field_names;
        push_header map { ucfirst $_ => $h->header($_) } @ak if (@ak);
    }
    debug("After header read ");

    Dancer::Factory::Hook->instance->execute_hooks('fake_cgi_after', $capture);
    debug("After hook fake_cgi_after ");

    return $ret;
}

# Method for delete character from string URL
sub _clean_url_string {
    my $str = shift || return;

    $str = _trim($str);
    $str =~ s/^\///;
    $str =~ s/\/$//;
    return $str;
}

=head2 fake_cgi_bin_url($name[,@other])

Method which return url for given C<$name>. If set C<@other>, than this will be append to given URL with separattor B</>

=cut

register fake_cgi_bin_url => sub {
    my ($self, $name, @others) = plugin_args(@_);
    _load_settings() unless ($settings);

    my @a = map { _clean_url_string($_); } @others;

    $name = _clean_url_string($name || "");
    my $s = _clean_url_string($settings->{'cgi-bin'} || "");
    return join("/", $s, $name, @a);
};

=head2 fake_cgi_method($package, $method, $params, @args)

Method for runned specified CGI method-function and return values of runned function.

=over

=item B<$package> - Package name where is method, which we run. Automatically load this package to memory in first run.

=item B<$method> - Method name which we run.

=item B<$params> - Hash ref of params, look of params to C<_run_code()>

=item B<@args> - Arguments for given method 

=back

=cut

register fake_cgi_method => sub {
    my ($self, $package, $method, $params, @args) = plugin_args(@_);

    unless (defined($method)) {
        croak("If not defined method in package, use 'fake_cgi_file'");
        return;
    }

    _load_settings() unless ($settings);
    return if ($package && !_load_package($package));

    unless ($package->can($method)) {
        croak("Not existed method '$method' in package '$package'");
        return;
    }

    my $func = (defined($package) ? ($package . "::") : "") . $method;

    mock(
        "CGI::Compile",
        "_read_source",
        sub {
            return "&" . $func . "(" . (@args ? join(",", @args) : "") . ");";
        });
    my $sub = CGI::Compile->compile(join("-", "fake_cgi_method", $$, time));
    unmock("CGI::Compile", "_read_source");

    my $ret = _run_code($sub, $params);

    debug("Running method $method in package $package ");
    return $ret;
};

=head2 fake_cgi_file($file, $params, $test_is_perl)

Method for runned specified Perl CGI file and returned exit value

=over

=item B<$file> - CGI filename and first in first run we compiled this file into memory

=item B<$params> - Hash ref of params, look of params to C<_run_code()>

=item B<$test_is_perl> - try first if given file is Perl code, default we use given filename as is Perl script.

=back

=cut

register fake_cgi_file => sub {
    my ($self, $file, $params, $test_is_perl) = plugin_args(@_);

    _load_settings() unless ($settings);
    my $fname = _get_file_name($file) || return;

    my $is_perl = 1;
    $is_perl = fake_cgi_is_perl($fname) if ($test_is_perl);
    my ($sub, $rh) = _compile_file($fname, $is_perl);

    my $ret = _run_code($sub, $params, $file);
    debug("Running $file ");
    return $ret;
};

=head2 fake_cgi_compile(@args)

Load packages into memory or Compiled files into memory. B<@args> is array of this HASHREF options:

=over

=item B<package> - load package into memory

=item B<filename> - compile Perl filename into memory

=item B<test_is_perl> - if B<filename> than run test if it is Perl CGI file

=back

=cut

register fake_cgi_compile => sub {
    my ($self, @args) = plugin_args(@_);
    _load_settings() unless ($settings);
    foreach my $rh (@args) {
        if (ref($rh) ne "HASH") {
            croak("Must be hash");
        } elsif (exists($rh->{filename})) {
            my $fname = _get_file_name($rh->{filename});
            if ($fname) {
                my $is_perl = 1;
                $is_perl = fake_cgi_is_perl($fname) if ($rh->{test_is_perl});
                _compile_file($fname, $is_perl);
            }
        } elsif (exists($rh->{package})) {
            _load_package($rh->{package});
        } else {
            croak("Nothing defined");
        }
    }
};

# Takes a path to a CGI from C<root/cgi-bin> such as C<foo/bar.cgi> and returns
# the action name it is registered as.
sub _cgi_action {
    my ($cgi) = @_;

    my $action_name = 'CGI_' . $cgi;
    $action_name =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

    return $action_name;
}

=head2 fake_cgi_is_perl($file, $compile)

Tries to figure out whether the CGI is Perl code or not.

Return 1 if its Perl code otherwise is 0.

=over

=item B<$file> - filename of test file

=item B<$compile> - if true and given tested file is Perl code, than compiled given file into memory

=back

=cut

register fake_cgi_is_perl => sub {
    my ($self, $cgi, $compiled) = plugin_args(@_);
    _load_settings() unless ($settings);

    if (Is_Win32) {
        my $cgi_name = _cgi_action($cgi);

        # the fork code fails on Win32
        my $sub = _compile_file($cgi, undef, $cgi_name);
        my $success = _run_code($sub, {ret_error => 1}) ? 0 : 1;

        require Class::Unload;
        Class::Unload->unload($cgi_name);
        return $success;
    }

    require File::Spec;

    my (undef, $tempfile) = File::Temp::tempfile;

    my $pid = fork;
    unless (defined $pid) {
        croak "Cannot make fork: $!";
        return 1;
    }

    if ($pid) {
        waitpid $pid, 0;
        my $errors = IO::File->new($tempfile)->getline;
        unlink $tempfile;
        _compile_file($cgi, 1) if ($compiled && !$errors);
        return $errors ? 0 : 1;
    }

    # child
    my $fname = _get_file_name($cgi, 1);
    unless ($fname || !-s $fname) {
        IO::File->new(">$tempfile")->print("Not existed file: $cgi");
        exit;
    }

    local *NULL;
    open NULL,   '>',  File::Spec->devnull;
    open STDOUT, '>&', \*NULL;
    open STDERR, '>&', \*NULL;
    close STDIN;

    #my $ret = _run_code($sub, {ret_error => 1});
    eval { CGI::Compile->compile($fname, "Dancer::Plugin::FakeCGI::_CGIs_::__DUMMY__"); };

    IO::File->new(">$tempfile")->print($@);
    exit;
};

=head2 fake_cgi_bin($code, $patterns, $test_is_perl)

Automatically serve CGI files from B<cgi-dir> directory

    plugins:
       FakeCGI:
          cgi-bin_file_pattern: *.cgi

Setting B<cgi-bin_file_pattern> can be defined as array is pattern of file or files, which will be readed and try to compiled and setted to run as CGI.

=over

=item B<$code> - reference for code, if not set, than automatically add servering for given file with this options. 

Given method should return B<true> or B<false>. If given code no return true, than serve given CGI files in standart way. 

This is parametter for given called code:

=over 3

=item directory

=item filename

=item url

=item is_perl

=back

=item B<$paterns> - is scalar or can be array ref. If not set, than will be set from settings, otherwise read everything which kind of file will be readed

=item B<$test_is_perl> - test if readable file it is Perl CGI file, if not defined, than we use every file as Perl CGI.

=back

=head4 EXAMPLES

=over

=item Standart definition in setting file:

    plugins:
       FakeCGI:
          cgi-bin_file_pattern: "*.pl"

In yours Dancer package only put C<fake_cgi_bin();> and this script try to load every B<*.pl> files in B<cgi-bin> directory under Dancer directory. 

=item Tested files in own function for every *.pl and *.sh file:

    sub test_file	{
        my ($cgi_bin, $cgi, $url, $is_perl) = @_;

        return 1 if ($cgi =~ /^\./);     # skip serving this file 
        return 1 if ($cgi =~ /test.pl/); # skip serving this file  

        if ($cgi eq "index.pl") {  # own serving for given file
            any $url => sub {
                redirect "/index.sh";
            };
            return 1;
        }

        return 0; # default server
    }

    fake_cgi_bin(\&test_file, ["*.pl", "*.sh"], 1);

=back

=cut 

register fake_cgi_bin => sub {
    my ($self, $code, $patterns, $test_perl_enable) = plugin_args(@_);

    $code = undef if (ref($code) ne "CODE");

    require File::Find::Rule;

    #require List::MoreUtils;
    #require File::Spec::Functions;

    _load_settings() unless ($settings);

    $patterns ||= ($settings->{"cgi-bin_file_pattern"} || '*');
    $patterns = [$patterns] if not ref $patterns;
    for my $pat (@$patterns) {
        if ($pat =~ m{^/(.*)/\z}) {
            $pat = qr/$1/;
        }
    }

    my $cgi_bin = _ret_cgi_bin_path();
    $cgi_bin .= "/" if ($cgi_bin !~ /\/$/);    # Put '/' if directorires is symlink File::Find::Rule can find any files

    foreach my $file (File::Find::Rule->file->name(@$patterns)->in($cgi_bin)) {
        my $cgi = File::Spec::Functions::abs2rel($file, $cgi_bin);

        next if (_test_runable($file));

        next if $cgi =~ /\.swp\z/;

        #next if List::MoreUtils::any { $_ eq '.svn' } File::Spec::Functions::splitdir $cgi_path;
        #my $path = join '/' => File::Spec::Functions::splitdir($cgi);
        #my $action_name = _cgi_action($path);

        my $test = 0;
        if ($code) {
            my $is_perl = 1;
            $is_perl = fake_cgi_is_perl($cgi) if ($test_perl_enable);
            $test = &$code($cgi_bin, $cgi, fake_cgi_bin_url($cgi), $is_perl);
        }
        unless ($test) {
            any fake_cgi_bin_url($cgi) => sub {
                fake_cgi_file($cgi, {test_is_perl => 1});
                fake_cgi_as_string();
            };
        }
    }
};

=head2 fake_cgi_as_string($ret_ref)

Return captured strings from CGI, which will be printed to STDOUT. 

If B<$ret_ref> than given string will be returned as reference to SCALAR. 
This option can make better performance.

=cut

register fake_cgi_as_string => sub {
    my ($self, $ret_ref) = plugin_args(@_);

    return "" if (ref($capture) ne "HASH" || !exists($capture->{"STDOUT"}));

    my $ret = "";
    if ($capture->{"STDOUT"}->{"string"}) {

        #my $str = $capture->{io_out}->sref;
        #return $str ? $$str : "";
        $ret = $capture->{"STDOUT"}->{"string"};
    } elsif ($capture->{"STDOUT"}->{"io_fh"}) {
        my $fh     = $capture->{"STDOUT"}->{"io_fh"};
        my $curpos = tell($fh);
        my $pos    = $capture->{"STDOUT"}->{"header_len"} || 0;
        seek($fh, $pos > 0 ? $pos : 0, SEEK_SET);
        $ret = do { local $/; <$fh>; };
        seek($fh, $curpos, SEEK_SET);
    }

    if ($ret_ref) {
        $ret ||= "";
        return \$ret;
    }
    return $ret || "";
};

=head2 fake_cgi_capture($capture_start)

This method every time return actuall settings form capture method.

If argument B<$capture_start> is defined, can be possible START or STOP capturing with this options:

=over

=item B<true|1> - capturing will be initalized or restarted. Every data in restarting will bi appended.

=item B<false|0> - capturing

=back

=head3 RETURN array of this position:

=over

=item Hash reference for B<$capture>

=item L<IO::Scalar> or L<IO::File> of captured STDOUT strings

=item actual position of seek() - tell() method

=item size of all data captured from STDOUT in bytes

=item len of HTTP header. From this position start HTML content

=back

=cut 

register fake_cgi_capture => sub {
    my ($self, $capture_start) = plugin_args(@_);

    return () if (ref($capture) ne "HASH");

    if (defined($capture_start)) {
        if ($capture_start) {
            my @a = ();
            foreach my $type ("STDOUT", "STDERR") {
                push(@a,
                    (exists($capture->{"STDOUT"}) && ($capture->{"STDOUT"}->{"io_fh"} || $capture->{"STDOUT"}->{"string"}))
                    ? 1
                    : 0);
            }
            _capture_start(@a);
        } else {
            _capture_end();
        }
    }

    my $pos        = undef;
    my $size       = undef;
    my $fh         = undef;
    my $header_len = undef;

    if (exists($capture->{"STDOUT"}) && $capture->{"STDOUT"}->{"io_fh"}) {
        my $fh = $capture->{"STDOUT"}->{"io_fh"};
        $fh->flush();
        if ($capture->{"STDOUT"}->{"string"}) {
            $size = length($capture->{"STDOUT"}->{"string"});
        } else {
            $size = ($fh->stat())[7];
        }
        $pos = tell($fh);
        $header_len = $capture->{"STDOUT"}->{"header_len"} || 0;
    }

    return $capture, $fh, $pos, $size, $header_len;
};

=head1 HOOKS

This plugin uses Dancer's hooks support to allow you to register code that should execute at given times.

=head3 TYPES

=over

=item B<fake_cgi_before($env,$capture)> : hook which will be called before run CGI method or Perl CGI file. Arguments is HASH reference to %ENV and reference to $capture

=item B<fake_cgi_after($capture)>  : hook which will be called after runned CGI method or Perl CGI file. Arguments is reference to $capture

=back

=head3 EXAMPLE

    hook 'fake_cgi_before' => sub {
        my ($env,$capture) = @_;
    };

    hook 'fake_cgi_after' => sub {
        my ($capture) = @_;
    };

=cut

Dancer::Factory::Hook->instance->install_hooks(qw(
      fake_cgi_before
      fake_cgi_after
));

_load_settings() unless ($settings);

#register_hook(qw());
register_plugin(for_versions => ['1', '2']);

# Mocking for Multipart* in CGI
package Dancer::Plugin::FakeCGI::MultipartBuffer;
use vars qw(@ISA);
@ISA = qw(MultipartBuffer);

$Dancer::Plugin::FakeCGI::MultipartBuffer::AutoloadClass    = 'MultipartBuffer';
*Dancer::Plugin::FakeCGI::MultipartBuffer::read_from_client = \&Dancer::Plugin::FakeCGI::_cgi_read_from_client;

1;    # End of Dancer::Plugin::FakeCGI
__END__

=head1 AUTHOR

Igor Bujna, C<< <igor.bujna@post.cz> >>

=head1 CONTRIBUTING


=head1 ACKNOWLEDGEMENTS

For every developers of this packages, when made good ideas for this code :

C<Catalyst::Controller::CGIBin>, C<HTTP::Request::AsCGI>, C<CGI::PSGI>, C<CGI::Emulate::PSGI>

=head1 SUPPORT


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Igor Bujna.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 SEE ALSO

L<Dancer>

L<IO::Scalar>

L<CGI::Compile>

L<Test::TinyMocker>

L<HTTP::Message>

=cut
