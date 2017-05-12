package CGI::AppBuilder::Message;

use warnings;
use Carp;
use IO::File;
use POSIX qw(strftime);
use CGI::AppBuilder;

# require Exporter;
@ISA = qw(Exporter CGI::AppBuilder);
# @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(disp_param set_param echo_msg debug_level echoMSG
    debug get_params
    );
our %EXPORT_TAGS = (
  all      => [@EXPORT_OK],
  echo_msg => [qw(disp_param echo_msg debug_level)],
);
our $VERSION = 1.0001;

=head1 NAME

CGI::AppBuilder::Message - Display debug messages based on levels

=head1 SYNOPSIS

    my $self = bless {}, "main";
    use CGI::AppBuilder::Message;
    $self->debug_level(2);   # set debug level to 2
    # The level 3 message will not be displayed
    $self->echo_msg("This is level 1 message.", 1);
    $self->echo_msg("This is level 2 message.", 2);
    $self->echo_msg("This is level 3 message.", 3);  

=head1 DESCRIPTION

The package contains the modules can be used for debuging or displaying
contents of your runtime state. You would first define the level of 
each message in your program, then define a debug level that you would
like to see in your runtime.

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
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

*debug = \&CGI::AppBuilder::Message::debug_level;

sub debug_level {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $s =  ref($_[0])?shift:(bless {}, $c_pkg);
    my $s =  shift;
    croak "ERR: Too many args to debug_level." if @_ > 1;
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

This method will display message or a hash array based on 
I<debug_level> level. If I<debug_level> is set to '0', no message 
or array will be displayed. If I<debug_level> is set to '2', it 
will only display the message level ($lvl) is less than or equal 
to '2'. If you call this method without providing a message level, 
the message level ($lvl) is default to '0'.  Of course, if no message 
is provided to the method, it will be quietly returned.

This is how you can call I<echo_msg>:

  my $df = CGI::AppBuilder::Message->new;
     $df->echo_msg("This is a test");   # default the msg to level 0
     $df->echo_msg("This is a test",1); # assign the msg as level 1 msg
     $df->echo_msg("Test again",2);     # assign the msg as level 2 msg
     $df->echo_msg($hrf,1);             # assign $hrf as level 1 msg
     $df->echo_msg($hrf,2);             # assign $hrf as level 2 msg

If I<debug_level> is set to '1', all the messages with default message 
level, i.e., 0, and '1' will be displayed. The higher level messages
will not be displayed.

This method displays or writes the message based on debug level.
The filehandler is provided through $fh or $ENV{FH_DEBUG_LOG}, and
the outputs are written to the file.

=cut

*echoMSG = \&CGI::AppBuilder::Message::echo_msg; 

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
    my $dbg = $self->debug_level;        # get debug level
    if (!$dbg) { return; }  # return if not debug
    my $ref = ref($msg);
    if ($ref eq $class || $ref =~ /(ARRAY|HASH)/) {
        if ($lvl <= $dbg) { $self->disp_param($msg); }
        return;
    }
    my $wbf = (exists $ENV{QUERY_STRING}||exists $ENV{HTTP_HOST})?1:0;
    $msg =~ s/\/(\w+)\@/\/****\@/g if $msg =~ /(\w+)\/(\w+)\@(\w+)/;
    my $f1 = "<h2>%s</h2>";
    my $f2 = "<font color=%s>%s</font>";
    my $f3 = "<pre>\n%s</pre>";
    if ($wbf) { 
        $msg = sprintf $f1, $msg            if $msg =~ /^\s*\d+\.\s+\w+/; 
        $msg = sprintf $f2, 'red',    $msg  if $msg =~ /^ERR:/i; 
        $msg = sprintf $f2, 'orange', $msg  if $msg =~ /^WARN:/i; 
        $msg = sprintf $f2, 'cyan',   $msg  if $msg =~ /^INFO:/i; 
        $msg = sprintf $f2, 'blue',   $msg  if $msg =~ /^CMD:/i;         
        $msg = sprintf $f3,    	      $msg  if $msg =~ /^CODE:/i;         
        $msg .= "<br>"                      if $msg !~ /^\s*\d+\.\s+\w+/; 
    }    
    $msg = "$msg\n";
    # $msg =~ s/\n/<br>\n/gm if $wbf;
    if ($lvl <= $dbg) { 
        if (defined wantarray) { # assign to a variable
          return $msg;           # return the value
        } else {                 # print the msg
          if ($fh) { print $fh $msg; } else { print $msg; }
        }
    }
    if (exists  $self->{write_log} && $self->{write_log}) {
        my $fh2 = (exists $self->{fh_dtl}) ? $self->{fh_dtl} : "";     
        return if ! $fh2;
        print $fh2 "$msg"; 
    }
}

=head2 disp_param($arf,$lzp, $fh)

Input variables:

  $arf - array reference
  $lzp - number of blank space indented in left
  $fh  - file handler

Variables used or routines called:

  echo_msg 	- print debug messages
  debug_level   - set debug level
  disp_param 	- recusively called

How to use:

  use CGI::AppBuilder::Message qw(:echo_msg);
  my $self= bless {}, "main";
  $self->disp_param($arf);

Return: Display the content of the array.

This method recursively displays the contents of an array. If a
filehandler is provided through $fh or $ENV{FH_DEBUG_LOG}, the outputs
are written to the file.

=cut

sub disp_param {
    my ($self, $hrf, $lzp, $fh) = @_;

    $self->echo_msg(" -- displaying parameters...",3);
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
        foreach my $k (sort keys %$hrf) {
            if (!defined(${$hrf}{$k})) { $v = "";
            } else { $v = $hrf->{$k}; }
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

=head2 set_param($var, $ar[,$val])

Input variables:

  $var - variable name
  $ar  - parameter hash or array ref 
  $val - value to be added or assigned

Variables used or routines called:

  None 

How to use:

  use CGI::AppBuilder::Message qw(set_param);
  my $ar = {a=>1,b=>25};
  my $br = [1,2,5,10];
  # for hash ref
  my $va = $self->set_param('a',$ar);  # set $va = 1
  my $v1 = $self->set_param('v1',$ar); # set $v1 = "" 
  my $v2 = $self->set_param('b',$ar);  # set $v2 = 25
  # for array ref
  my $v3 = $self->set_param(0,$br);    # set $v3 = 1
  my $v4 = $self->set_param(3,$br);    # set $v4 = 10
  # add or assign values and return array ref
  $self->set_param('c',$ar,30);        # set $ar->{c} = 30
  $self->set_param(5,$br,50);          # set $br->[5] = 50

Return: $r - the value in the hash or empty string or array ref.

=cut

sub set_param {
    my ($s, $v, $r) = @_;
    # return blank if no $v or $r is not array, hash nor object
    return "" if $v =~ /^\s*$/ || ! ref($r); 
    if ($#_>2) {   # there is a third input
        $r->[$v] = $_[3]  if $v =~ /^\d+$/ && ref($r) =~ /ARRAY/;
        $r->{$v} = $_[3]  if ref($r) =~ /HASH/ && ref $r;
        return ;
    }
    return "" if $v !~ /^\d+$/ && ref($r) =~ /ARRAY/; 
    return (exists $r->[$v])?$r->[$v]:"" if ref($r) =~ /^ARRAY/; 
    # if $r = $s, then ref $r will make it sure to catch that as well
    return (exists $r->{$v})?$r->{$v}:"" if ref($r) =~ /^HASH/||ref $r;
    return "";     # catch all
}

=head2 get_params($vs, $ar)

Input variables:

  $vs  - a list of variable names separated by comma
  $ar  - parameter hash or array ref

Variables used or routines called:

  set_param - get individual parameter

How to use:

  use CGI::AppBuilder::Message;
  my $ar = {a=>1,b=>25};
  my ($va, $vb) = $self->get_params('a,b',$ar); 

Return: array or array ref 

This method gets multiple values for listed variables. 

=cut

sub get_params {
    my $s = shift;
    my ($vs, $r) = @_; 
    return () if ! $vs;
    my $p = [];
    $vs =~ s/\s+//g;   # remove any spaces
    foreach my $k (split /,/, $vs) {
        push @$p, $s->set_param($k, $r); 
    }
    return wantarray ? @$p : $p; 
}


1;

=head1 CODING HISTORY

=over 4

=item * Version 0.10

Extracted methods debug_level, echo_msg, disp_param, and set_param 
from Debug::EchoMessage. 

=item * Version 0.11

Some minor changes to echo_msg.

=item * Version 0.12

Added get_params method. 

=item * Version 1.0001

Bring the version to 1.0001 after 10 years!

=back

=head1 FUTURE IMPLEMENTATION

=over 4

=item * no plan yet 

=back

=head1 AUTHOR

Copyright (c) 2004 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

