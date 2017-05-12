package DataFax::StudySubs;

use strict;
use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Carp;
use IO::File; 
use Net::Rexec 'rexec'; 

$VERSION    = 0.10;
use DataFax;
@ISA        = qw(Exporter DataFax);
@EXPORT     = qw(dfparam disp_param debug_level echo_msg get_dfparam);
@EXPORT_OK  = qw(dfparam disp_param debug_level echo_msg get_dfparam
                 exec_cmd
);
%EXPORT_TAGS= (
    all     =>[@EXPORT_OK],
    echo_msg=>[qw(dfparam disp_param debug_level echo_msg get_dfparam)],
    param   =>[qw(dfparam disp_param get_dfparam)],
    cmd     =>[qw(exec_cmd)],
);

=head1 NAME

DataFax::StudySubs - DataFax common sub routines

=head1 SYNOPSIS

  use DataFax::StudySubs qw(:all);

=head1 DESCRIPTION

This class contains the common sub-routines used in DataFax.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

# ---------------------------------------------------------------------

=head1 Export Tag: all

The :all tag includes the all the methods in this module.

  use DataFax::StudySubs qw(:all);

It includes the following sub-routines:

=head2 dfparam($var, $ar[,$val])

Input variables:

  $var - variable name
  $ar  - parameter hash or array ref
  $val - value to be added or assigned

Variables used or routines called:

  None

How to use:

  use DataFax::DFstudyDB qw(dfparam);
  my $ar = {a=>1,b=>25};
  my $br = [1,2,5,10];
  # for hash ref
  my $va = $self->dfparam('a',$ar);  # set $va = 1
  my $v1 = $self->dfparam('v1',$ar); # set $v1 = ""
  my $v2 = $self->dfparam('b',$ar);  # set $v2 = 25
  # for array ref
  my $v3 = $self->dfparam(0,$br);    # set $v3 = 1
  my $v4 = $self->dfparam(3,$br);    # set $v4 = 10
  # add or assign values and return array ref
  $self->dfparam('c',$ar,30);        # set $ar->{c} = 30
  $self->dfparam(5,$br,50);          # set $br->[5] = 50

Return: $r - the value in the hash or empty string or array ref.

This method gets and sets the $var in $ar. If the varirable
does not exists in $ar, it tries in $self as well for 'get'. 

=cut

sub dfparam {
    my ($s, $v, $r) = @_;
    if ($#_>2) {   # there is a third input
        $r->[$v] = $_[3]  if $v =~ /^\d+$/ && ref($r) =~ /ARRAY/;
        $r->{$v} = $_[3]  if ref($r) =~ /HASH/ || ref $r;
        return ;
    }
    # if only variable name and the name exists in the class object
    return $s->{$v} if $#_==1 && exists $s->{$v}; 
    # return blank  if no $v or $r is not array, hash nor object
    return ""       if $v =~ /^\s*$/;
    return $s->{$v} if exists $s->{$v} && !$r; 
    return ""       if ! ref($r);
    return ""       if $v !~ /^\d+$/ && ref($r) =~ /ARRAY/;

    return (exists $r->[$v])?$r->[$v]:"" if ref($r) =~ /^ARRAY/;
    # if $r = $s, then ref $r will make it sure to catch that as well
    return (exists $r->{$v})?$r->{$v}:((exists $s->{$v})?$s->{$v}:"")
       if ref($r) =~ /^HASH/ || ref $r;
    return "";     # catch all
}

=head2 get_dfparam($vs, $ar)

Input variables:

  $vs  - a list of variable names separated by comma
  $ar  - parameter hash or array ref

Variables used or routines called:

  dfparam - get individual parameter

How to use:

  use DataFax::DFstudyDB qw(:all);
  my $ar = {a=>1,b=>25};
  my ($va, $vb) = $self->get_dfparam('a,b',$ar); 

Return: array or array ref 

This method gets multiple values for listed variables. 

=cut

sub get_dfparam {
    my $s = shift;
    my ($vs, $r) = @_; 
    return () if ! $vs;
    my $p = [];
    $vs =~ s/\s+//g;   # remove any spaces
    foreach my $k (split /,/, $vs) {
        push @$p, $s->dfparam($k, $r); 
    }
    return wantarray ? @$p : $p; 
}

=head2 exec_cmd ($cmd, $pr)

Input variables:

  $cmd - a full unix command with paraemters and arguments
  $pr  - parameter hash ref
    datafax_host - DataFax host name or ip address
    local_host - local host name or ip address
    datafax_usr - DataFax user name
    datafax_pwd - DataFax user password

Variables used or routines called:

  get_dfparam - get values for multiple parameters

How to use:

  use DataFax::DFstudyDB qw(:all);
  # Case 1: hosts are different and without id and password 
  my $cmd = "cat /my/dir/file.txt"; 
  my $pr = {datafax_host=>'dfsvr',local_host='svr2'};  
  my @a = $self->exec_cmd($cmd,$pr);   # uses rsh to run the cmd 

  # Case 2: different hosts with id and password 
  my $pr = {datafax_host=>'dfsvr',local_host='svr2',
     datafax_usr=>'fusr', datafax_pwd=>'pwd' };  
  my @a = $self->exec_cmd($cmd,$pr);   # uses rexec  

  # Case 2: hosts are the same 
  my $pr = {datafax_host=>'dfsvr',local_host='dfsvr'};  
  my $ar = $self->exec_cmd('/my/file.txt',$pr); # case 2:  

Return: array or array ref 

This method opens a file or runs a command and return the contents
in array or array ref.

=cut

sub exec_cmd {
    my $s = shift;
    my ($cmd, $pr) = @_;
    my $vs='datafax_host,local_host,datafax_usr,datafax_pwd';
    my ($dfh,$lsv,$usr,$pwd) = $s->get_dfparam($vs,$pr);
    $lsv = `hostname` if ! $lsv;
    my ($rc, @a);
    if ($dfh ne $lsv) { 
        # croak "ERR: no user name for remote access.\n" if ! $usr;
        # croak "ERR: no password for user $usr.\n"      if ! $pwd;
        if ($usr && $pwd) {    # use rexec
            $s->echo_msg("    CMD: $cmd at $dfh for user $usr...", 1); 
            ($rc, @a) = rexec($dfh, $cmd, $usr, $pwd);
            $rc == 0 || carp "    WARN: could not run $cmd on $dfh.\n";
        } else {               # use rsh  
            my $u  = "rsh $dfh $cmd |";
            my $fh = new IO::File;
            $fh->open("$u")||carp "    WARN: could not run $u: $!.\n";
            @a=<$fh>; close($fh);
        }
    } else {                   # use perl module 
        $s->echo_msg("    CMD: $cmd at $lsv...", 1); 
        my $fh = new IO::File;
        $fh->open("$cmd") || carp "    WARN: could not run $cmd: $!.\n";
        @a=<$fh>; close($fh);
    }
    return wantarray ? @a : \@a; 
}

=head2 debug_level($n)

Input variables:

  $n   - a number between 0 and 100. It specifies the
         level of messages that you would like to
         display. The higher the number, the more
         detailed messages that you will get.

Variables used or routines called: None.

How to use:

  $self->debug_level(2);     # set the message level to 2
  print $self->debug_level;  # print current message level

Return: the debug level or set the debug level.

=cut

sub debug_level {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $s =  ref($_[0])?shift:(bless {}, $c_pkg);
    my $s =  shift;
    croak "ERR: Too many args to debug." if @_ > 1;
    @_ ? ($s->{_debug_level}=shift) : return $s->{_debug_level};
}

=head2 echo_msg($msg, $lvl, $fh)

Input variables:

  $msg - the message to be displayed. No newline
         is needed in the end of the message. It
         will add the newline code at the end of
         the message.
  $lvl - the message level is assigned to the message.
         If it is higher than the debug level, then
         the message will not be displayed.
  $fh  - file handler, or set the file hanlder in this parameter
         $ENV{FH_DEBUG_LOG}

Variables used or routines called:

  debug_level - get debug level.

How to use:

  # default msg level to 0
  $self->echo_msg('This is a test");
  # set the msg level to 2
  $self->echo_msg('This is a test", 2);

Return: None.

This method will display message or a hash array based on I<debug_level>
level. If I<debug_level> is set to '0', no message or array will be
displayed. If I<debug_level> is set to '2', it will only display the message
level ($lvl) is less than or equal to '2'. If you call this
method without providing a message level, the message level ($lvl) is
default to '0'.  Of course, if no message is provided to the method,
it will be quietly returned.

This is how you can call I<echo_msg>:

  my $df = DataFax->new;
     $df->echo_msg("This is a test");   # default the msg to level 0
     $df->echo_msg("This is a test",1); # assign the msg as level 1 msg
     $df->echo_msg("Test again",2);     # assign the msg as level 2 msg
     $df->echo_msg($hrf,1);             # assign $hrf as level 1 msg
     $df->echo_msg($hrf,2);             # assign $hrf as level 2 msg

If I<debug_level> is set to '1', all the messages with default message level,
i.e., 0, and '1' will be displayed. The higher level messages
will not be displayed.

This method displays or writes the message based on debug level.
The filehandler is provided through $fh or $ENV{FH_DEBUG_LOG}, and
the outputs are written to the file.

=cut

sub echo_msg {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $self = ref($_[0])?shift:(bless {},$c_pkg);
    my $self = shift;
    my ($msg,$lvl, $fh) = @_;
    $fh = (exists $ENV{FH_DEBUG_LOG})?$ENV{FH_DEBUG_LOG}:"";
    $fh = "" if !$fh || ($fh && ref($fh) !~ /(IO::File|GLOB)/);
    if (!defined($msg)) { return; }      # return if no msg
    if (!defined($lvl)) { $lvl = 0; }    # default level to 0
    my $class = ref($self)||$self;       # get class name
    my $dbg = $self->debug_level;              # get debug level
    if (!$dbg) { return; }               # return if not debug
    my $ref = ref($msg);
    if ($ref eq $class || $ref =~ /(ARRAY|HASH)/) {
        if ($lvl <= $dbg) { $self->disp_param($msg); }
    } else {
        $msg = "<h2>$msg</h2>" if exists $ENV{QUERY_STRING} &&
            $msg =~ /^\s*\d+\.\s+\w+/;
        $msg =~ s/\/(\w+)\@/\/****\@/g if $msg =~ /(\w+)\/(\w+)\@(\w+)/;
        $msg = "$msg\n";
        $msg =~ s/\n/<br>\n/gm if exists $ENV{QUERY_STRING};
        if ($lvl <= $dbg) {
            if ($fh) { print $fh $msg; } else { print $msg; }
        }
    }
}

=head2 disp_param($arf,$lzp, $fh)

Input variables:

  $arf - array reference
  $lzp - number of blank space indented in left
  $fh  - file handler

Variables used or routines called:

  echo_msg - print debug messages
  debug_level   - set debug level
  disp_param - recusively called

How to use:

  use DataFax::StudySubs qw(:echo_msg);
  my $self= bless {}, "main";
  $self->disp_param($arf);

Return: Display the content of the array.

This method recursively displays the contents of an array. If a
filehandler is provided through $fh or $ENV{FH_DEBUG_LOG}, the outputs
are written to the file.

=cut

sub disp_param {
    my ($self, $hrf, $lzp, $fh) = @_;
    my $otp = ref $hrf; 
    $self->echo_msg(" - displaying parameters in $otp...");
    $fh = (exists $ENV{FH_DEBUG_LOG})?$ENV{FH_DEBUG_LOG}:"";
    $fh = "" if !$fh || ($fh && ref($fh) !~ /(IO::File|GLOB)/);
    if (!$lzp) { $lzp = 15; } else { $lzp +=4; }
    my $fmt;
    if (exists $ENV{QUERY_STRING}) {
        # $fmt = "%${lzp}s = %-30s<br>\n";
        $fmt = ("&nbsp;" x $lzp) . "%s = %-30s<br>\n";
    } else {
        $fmt = "%${lzp}s = %-30s\n";
    }
    if (!$hrf) {
        print "Please specify an array ref.\n";
        return;
    }
    # print join "|", $self, "HRF", $hrf, ref($hrf), "\n";
    my ($v);
    if (ref($hrf) eq 'HASH'|| $hrf =~ /.*=HASH/) {
        foreach my $k (sort keys %{$hrf}) {
            if (!defined(${$hrf}{$k})) { $v = "";
            } else { $v = ${$hrf}{$k}; }
            if ($v =~ /([-\w_]+)\/(\w+)\@(\w+)/) {
                $v =~ s{(\w+)/(\w+)\@}{$1/\*\*\*\@}g;
            }
            chomp $v;
            if ($fh) { printf $fh $fmt, $k, $v;
            } else   { printf $fmt, $k, $v; }
            if (ref($v) =~ /^(HASH|ARRAY)$/ ||
                $v =~ /.*=(HASH|ARRAY)/) {
                my $db1 = $self->debug_level;
                $self->debug_level(0);
                # print "$k = ${$hrf}{$k}: @{${$hrf}{$k}}\n";
                $self->disp_param(${$hrf}{$k},$lzp);
                $self->debug_level($db1);
                if ($fh) { print $fh "\n"; } else { print "\n"; }
            }
        }
    } elsif (ref($hrf) eq 'ARRAY' || $hrf =~ /.*=ARRAY/) {
        foreach my $i (0..$#{$hrf}) {
            if (!defined(${$hrf}[$i])) { $v = "";
            } else { $v = ${$hrf}[$i]; }
            if ($v =~ /([-\w_]+)\/(\w+)\@(\w+)/) {
                $v =~ s{(\w+)/(\w+)\@}{$1/\*\*\*\@}g;
            }
            chomp $v;
            if ($fh) { printf $fh $fmt, $i, $v;
            } else   { printf $fmt, $i, $v; }
            if (ref($v) =~ /^(HASH|ARRAY)$/ ||
                $v =~ /.*=(HASH|ARRAY)/) {
                my $db1 = $self->debug_level;
                $self->debug_level(0);
                $self->disp_param(${$hrf}[$i],$lzp);
                $self->debug_level($db1);
                if ($fh) { print $fh "\n"; } else { print "\n"; }
            }
        }
    }
}

1;

