package CGI::AppBuilder::Config;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use File::Basename;

our $VERSION = 1.0001;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(get_inputs read_init_file read_cfg_file
    eval_var eval_named_var eval_variables get_opt _parseline
                   );
our %EXPORT_TAGS = (
    eval_var => [qw(eval_var eval_named_var eval_variables)],
    config => [qw(get_inputs read_init_file)],
    all  => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::Config - Configuration initializer 

=head1 SYNOPSIS

  use CGI::AppBuilder::Config;

  my $cg = CGI::AppBuilder::Config->new(
     'ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my $ar = $cg->get_inputs; 

=head1 DESCRIPTION

This class provides methods for reading and parsing configuration
files. 

=cut

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head2 get_inputs($ifn, $opt)

Input variables:

  $ifn  - input/initial file name. 
  $opt  - options for Getopt::Std, for instance 'vhS:a:'

Variables used or routines called:

  None

How to use:

  my $ar = $self->get_inputs('/tmp/my_init.cfg','vhS:');

Return: ($q, $ar) where $q is the CGI object and 
$ar is a hash array reference containing parameters from web form,
or command line and/or configuration file if specified.

This method performs the following tasks:

  1) create a CGI object
  2) get input from CGI web form or command line 
  3) read initial file if provided
  4) merge the two inputs into one hash array

This method uses the following rules: 

  1) All parameters in the initial file can not be changed through
     command line or web form;
  2) The "-S" option in command line can be used to set non-single
     char parameters in the format of 
     -S k1=value1:k2=value2
  3) Single char parameters are included only if they are listed
     in $opt input variable.

Some parameters are defined automatically:

  script_name - $ENV{SCRIPT_NAME} 
  url_dn      - $ENV{HTTP_HOST}
  home_url    - http://$ENV{HTTP_HOST}
  HomeLoc     - http://$ENV{HTTP_HOST}/
  version     - $VERSION
  action      - https://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}
  encoding    - application/x-www-form-urlencoded
  method      - POST
  script_name - {home_url}{script_name}

=cut

sub get_inputs {
    my $s = shift;
    my ($ifn, $par) = @_;

    my $prg = 'AppBuilder::Config->get_inputs'; 
    $ifn = $s->{ifn} if !$ifn;
    $par = $s->{opt} if !$par;
    $s->echo_msg("INFO: ($prg) IFN=$ifn OPT=$par",3);
    $s->echo_msg("INFO: ($prg) ARGV: @ARGV",3);
    # 02/10/2011 (htu) - get IFN dir
    my($ifn_nam, $ifn_dir, $ifn_sfx) = fileparse($ifn,qr{\..*});
    $ifn_dir =~ s/\/$//; 

    # return () if (!$ENV{'QUERY_STRING'} && !$ENV{'DOCUMENT_URI'} &&
    #      !$ENV{'REMOTE_ADDR'}  && !@ARGV);

    my %opt = ();           # optional inputs
    my %cfg = ();           # configuration parameters
    my $ds = '/';           # dir separator
    my $q = new CGI;        # create CGI object
    my $script_name = "";
       $script_name = $ENV{SCRIPT_NAME} if exists $ENV{SCRIPT_NAME};
    $opt{script_name} = $script_name;
    if (exists $ENV{HTTP_HOST}) {
        $opt{url_dn} = $ENV{HTTP_HOST};
        if (exists $ENV{HTTPS} && $ENV{HTTPS} =~ /^on/i) { 
            $opt{action} = "https://$opt{url_dn}$ENV{SCRIPT_NAME}";
        } else {
            $opt{action} = "http://$opt{url_dn}$ENV{SCRIPT_NAME}";
        }
    } else {
        $opt{url_dn} = ""; 
        $opt{action} = "command line";
    }
    $opt{encoding}  = 'application/x-www-form-urlencoded';
    $opt{method}    = 'POST';
    if (! exists $ENV{QUERY_STRING} || @ARGV) {
        $s->echo_msg("INFO: ($prg) Got ARGV...", 3);
        # since $s->{opt} was set in new, then we have $par
        getopts("$par", \%opt);
        # $s->disp_param(\%opt); 
    } else {
        $s->echo_msg("INFO: ($prg) Got QUERY_STRING...", 3);
        # corresponding to ARGV
        my $p1 = $par;  $p1 =~ s/://g;   # remove ':"
        foreach my $k (split //, $p1) { 
            $opt{$k} = $q->param($k);    # get inputs 
        }
    }
    my @names = ();

    if (exists $ENV{QUERY_STRING} && $ENV{QUERY_STRING}) {
        @names = $q->param;
    }
    if (exists $opt{S} && $opt{S}) {
        foreach my $r (split /\:/, $opt{S}) { 
            my ($k, $v) = (split /=/, $r);
            $opt{$k} = $v if ! exists $opt{$k};
        }
    }
    foreach my $k (@names) { 
        $opt{$k} = $q->param($k) if ! exists $opt{$k}; 
    }
    # make sure that we have got the form data as well
    # if (exists $ENV{QUERY_STRING}) {
        my $vv = $q->Vars; 
        foreach my $k (keys %$vv) {
          my $v = $vv->{$k};
          # 02/08/2011 (htu): handled multiple selections separated by nul char
          if (index($v, chr(0)) > 0) {
            my @asc = unpack("C*", $v);			# get ascii number
            # $s->disp_param(\@asc); 
            # replace the nul char (0) with comma (44)
            for my $i (0..$#asc) { $asc[$i] = ($asc[$i]==0) ? 44 : $asc[$i]; } 
            # $s->disp_param(\@asc); 
            $v = pack("C*", @asc);			# put chars together
            $s->echo_msg("INFO: ($prg) Found multi-selections: $v",3);           
          } 
          $opt{$k} = $v if ! exists $opt{$k}; 
        }
    # }
    # check input variables
    $opt{v}  = 'n' if ! exists $opt{v} || !defined($opt{v}); 
    $opt{v}  = ($opt{v} && $opt{v} =~ /^y/i)?1:$opt{v};
    $opt{v}  = ($opt{v} =~ /\d+/)?$opt{v}:0;
    
    %cfg = ($ifn && -f $ifn)?$s->read_init_file($ifn):();
    $cfg{version} = "CGI::AppBuilder::Config $VERSION";
    
    if (exists $ENV{HTTP_HOST}) {
        $cfg{home_url} = "http://$ENV{HTTP_HOST}"  if !$cfg{home_url}; 
        $cfg{HomeLoc}  = "http://$ENV{HTTP_HOST}/" if !$cfg{HomeLoc}; 
    } else {
        $cfg{home_url} = ""   ; # home URL
        $cfg{HomeLoc}  = "/"  ; # ASP var
    }
    $cfg{script_name} = $script_name if ! exists $cfg{script_name};
    $cfg{script_url} = "$cfg{home_url}$cfg{script_name}" 
       if ! exists $cfg{script_url};
    foreach my $k (keys %opt) { 
        $cfg{$k} = $opt{$k} if ! exists $cfg{$k}; 
    }
    
    # 07/21/2010: enhanced for sub tasks
    my $j2i = eval ((exists $cfg{jp2_ini})?$cfg{jp2_ini}:'{}'); # ini file array
    
    my $pid = (exists $cfg{pid}) ? $cfg{pid} : '';		# project id
       $pid = 'dba' if ! $pid; 
    my $tsk = (exists $cfg{task})?$cfg{task}:''; 		# task name
    my $sif = (exists $j2i->{$pid})?$j2i->{$pid}:'';		# sub init file
       $sif = join $ds, $ifn_dir, $sif if ($sif && $sif !~ /^\//); 
       
    if (exists $j2i->{$pid} && -f $sif) { 
      $s->echo_msg("INFO: ($prg) reading sub init file $sif...",3); 
      my %stp = $s->read_init_file($sif); 
      foreach my $k (keys %stp) {
        $cfg{$k} = $stp{$k}; 
      }
      $s->eval_variables(\%cfg, \%cfg); 
    } else {
      $s->echo_msg("WARN: ($prg): could not find sub init file - $sif.",0);
    }
    
    $cfg{ifn} = $ifn; $cfg{opt} = $par;
    $s->debug_level($cfg{v}) if exists $cfg{v};
    $s->echo_msg("INFO: INI - $ifn: read.", 2);
    return ($q, \%cfg);
}

=head2 get_opt($opt)

Input variables:

  $opt  - option parameter such as 'a:hi:s:S:t:v:'
  @ARGV - inputs 

Variables used or routines called:

  None.

How to use:

  my $opts = 'a:hi:s:S:t:v:';
  $self->get_opt($opts);

Return: None

=cut

sub get_opt {
    my ($s,$opt) = @_;
    
    $opt = 'a:hi:s:S:t:v:' if ! $opt; 
    my %p = ();
    $p{arg} = join " ", @ARGV; 
    getopts($opt, \%p);
    # $s->disp_param(\%p); 
    if (exists $p{S} && $p{S}) {
      foreach my $pv (split /:/, $p{S}) {
          my ($k, $v) = split /=/, $pv;
          $p{$k} = $v; 
      }
    } 
    $p{ifn} = $p{i}  if (exists $p{i} && $p{i}); 
    $p{ifn} = $0     if !$p{ifn}; 
    $p{ifn} =~ s/\.pl/\.ini/;
    $p{opt} = 'a:hi:s:S:t:v:' if ! exists $p{opt} || ! $p{opt};
    $p{act} = $p{a}  if (exists $p{a} && $p{a}); 
    $p{act} = 'test' if ! $p{act}; 
    $p{lvl} = $p{v}  if (exists $p{v} && $p{v});
    $p{lvl} = 0      if ! $p{lvl}; 
    $p{sel} = $p{s}  if (exists $p{s} && $p{s});
    $p{sel} = 0      if ! $p{sel}; 
    $p{task}= $p{t}  if (exists $p{t} && $p{t}); 
    
    wantarray ? %p: \%p;
}

=head2  read_init_file($fn, $dvr)

Input variables:

  $fn - full path to a file name
  $dvr - delay variable replacement
         0 - No (default)
         1 - yes

Variables used or routines called:

  eval_variables - replace variables with their values

  CGI::AppBuilder::Message
    echo_msg - echo messages

How to use:

  my $ar = $self->read_init_file('crop.ini');

Return: a hash array ref 

This method reads a configuraton file containing parameters in the 
format of key=values. Multiple lines is allowed for values as long
as the lines after the "key=" line are indented as least with two 
blanks. For instance:

  width = 80
  desc  = This is a long
          description about the value
  # you can define perl hash araay as well
  msg = {
    101 => "msg 101",
    102 => "msg 102"
    }
  # you can use variable as well
  js_var = /my/js/var_file.js
  js_src = /my/first/js/prg.js,$js_var
  # a comma (,) after sharp (#) make it not a comment
  my_sql = select sid, serial#,username from v\$session; 

This will create a hash array of 

  $ar->{width} = 80
  $ar->{desc}  = "This is a long description about the value"
  $ar->{msg}   = {101=>"msg 101",102=>"msg 102"}
  $ar->{js_var}= "/my/js/var_file.js";
  $ar->{js_src}= "/my/first/js/prg.js,/my/js/var_file.js";

=cut

sub read_init_file {
    my $s = shift;
    my ($fn, $dvr) = @_;
    if (!$fn)    { carp "    No file name is specified."; return; }
    if (!-f $fn) { carp "    File - $fn does not exist!"; return; }

    my($fn_nam, $fn_dir, $fn_sfx) = fileparse($fn,qr{\..*});    
    $fn_dir =~ s/\/$//; 
    my $ds = '/'; 
    my $prg = 'read_init_file';
    $s->echo_msg("INFO: ($prg) reading $fn...",3); 
    
    my ($k, $v, %h, $mk);
    open FILE, "< $fn" or
        croak "ERR: could not read to file - $fn: $!\n";
    while (<FILE>) {
      # 07/21/2010 (htu): enable included files
      if ($_ =~ /^\s*##include:\s*([\w\.\/]+)/i) {
        # we find a included file
        my $f2 = $1; 
           $f2 = join $ds, $fn_dir, $f2 if ($f2 && $f2 !~ /^\//);         
        if (! -f $f2) {
          $s->echo_msg("WARN: ($prg) could not find included file - $f2",2);
          next; 
        } else {
          $s->echo_msg("INFO: ($prg) reading sub init file - $f2...",2);
        }
        ($k,$v) = ();
        open F2, "< $f2" or
          croak "ERR: ($prg) could not read file - $f2: $!\n";
        while (<F2>) {          
          next if $_ =~ /^\s*#/ || $_ =~ /^\s*$/; 
          chomp;     			# remove line break
          my ($x, $y) = $s->_parseline($_); 
          $k = $x if $x; $v = $y ;
          if ($x) { $h{$k} = $v; } else { $h{$k} .= " $v"; }
        }
        close F2;
        next;
      }
      # skip comment and empty lines
      next if $_ =~ /^\s*#/ || $_ =~ /^\s*$/; 
      chomp;               # remove line break
      my ($x, $y) = $s->_parseline($_); 
      $k = $x if $x; $v = $y ;
      if ($x) { $h{$k} = $v; } else { $h{$k} .= " $v"; }
    }
    close FILE;
    if (! $dvr) {  # not delay variable replacement 
        $mk = $s->eval_variables(\%h); 
        $s->echo_msg($mk, 4); 
    }
    return wantarray ? %h : \%h;
}


# 07/21/2010 (htu): enable including init files in a init file
sub _parseline {
  # 11/05/2015 (htu) - fix: 'group#' to be 'grou'
  my ($s, $rec) = @_;
  my ($k, $v) = (); 
  if ($rec =~ /^(\w+)\s*=\s*(.+)/) {
    $k = $1; $v = $2;  
    $v =~ s/^\s+//; $v =~ s/\s+$//;	# remove leading and trailing spaces
    $v =~ s/\s*[^'"\(\w]#[^'",\)].*$//;   	# remove inline comments
  } elsif ($rec =~ /\s*(\w+)\s*=>\s*(.+)/) {  	# k1 => v1
    $k = ''; $v = $rec; 
    $v =~ s/^\s+//; $v =~ s/\s+$//;	# remove leading and trailing spaces
    $v =~ s/\s*[^'"\(\w]#[^'",\)].*$//; 	# remove inline comments
  } else {
    $k = ''; $v = $rec; 
    $v =~ s/^\s+//; $v =~ s/\s+$//; 	# remove leading and trailing spaces 
    $v =~ s/\s*[^'"\(\w]#[^'",\)].*$//;   # remove inline comments
  }
  return ($k,$v); 
}


=head2  eval_variables($cfg, $hr)

Input variables:

  $cfg - a hash array ref containing variable names
  $hr  - a hash array ref contianing  varliable values

Variables used or routines called:

  eval_named_var - get named variables' values
  eval_var       - get variables' values

How to use:

  my $mr = $self->eval_variables($cfg, $hr);

Return: a hash or hash ref.  

This method evaluates the configuration hash and replace variable
names with their values up to 5 levels of nested variables. 
For instance, you have the following configuration hash:

  my $cfg = { a=>10, b=>"$a+2", c=>"2*($b)", d=>"$c-1", 
              result=>"3*($d)" }
  my $mk = $self->eval_variables($cfg);   

This will result $cfg to 

  a = 10
  b = 10+2
  c = 2*(10+2)
  d = 2*(10+2)-1
  result = 3*(2*(10+2)-1)

=cut

sub eval_variables {
    my $s = shift;
    my ($cfg, $hr) = @_;

    # explode the inline variables for ENV variables 
    my $m  = {};    # matched variables
    my $kv = {};    # store hash name 
    return wantarray ? %$m : $m  if (ref($cfg) !~ /HASH/) || !$cfg;

    foreach my $k (keys %$cfg) {
        next if ! exists $cfg->{$k};
        next if ! $cfg->{$k};
        next if ($cfg->{$k} =~ /^(ARRAY|HASH)/); 
        $cfg->{$k} =~ s/^\s*//; $cfg->{$k} =~ s/\s*$//;
        my $v = $cfg->{$k};
        map { ++$kv->{$_} } ( $v =~ /\$(\w+)\{\w+\}/gi ); 
    }
    $m->{ENV} = $s->eval_named_var($cfg, 'ENV'); 
    foreach my $k (keys %$kv) {
       next if $k =~ /^ENV$/;
       $m->{$k} = $s->eval_named_var($cfg, $k, $hr); 
    }
    $m->{p1}  = $s->eval_var($cfg, $hr); 
    $m->{p2}  = $s->eval_var($cfg, $hr) if $m->{p1}; 
    $m->{p3}  = $s->eval_var($cfg, $hr) if $m->{p1} && $m->{p2}; 
    $m->{p4}  = $s->eval_var($cfg, $hr) if $m->{p1} && $m->{p2} && 
                $m->{p3}; 
    $m->{p5}  = $s->eval_var($cfg, $hr) if $m->{p1} && $m->{p2} && 
                $m->{p3} && $m->{p4}; 
    return wantarray ? %$m : $m;
}

=head2  eval_var($cfg, $hr)

Input variables:

  $cfg - a hash ref containing variable names
  $hr  - a hash ref which will be used to search for values 

Variables used or routines called:

  None

How to use:

  my $cfg = {first_name=>'John', last_name=>'Smith',
     full_name => "\$first_name \$last_name",
     addr1=>"111 Main Street",
     city=>"Philadelphia", zip_code=>"19102",
     address => "\$addr1, \$city, PA \$zip_code",
     contact=>"\$full_name <address>\$address</address> \$logo",
     };
  my $hr = { logo => 'http://mydomain.com/images/logo.gif', };
  my $p1 = $self->eval_var($cfg, $hr);
  my $p2 = $self->eval_var($cfg, $hr);
  # The first pass will get full_name, address replaced with values
  # but leave contact with variable names in it.
  # The second pass will get first_name, last_name, and address in
  # contact replaced with their values. 
 
Return: a hash or hash ref 

This method evaluates the variable names contained in a configuration
hash and replace the variable names with their values. 

=cut

sub eval_var {
    my $s = shift;
    my ($hr, $ar) = @_;
    return wantarray ? () : {}  if !$hr; 

    my $kp = {}; 
    foreach my $k (keys %$hr) {
        next if ! exists $hr->{$k}; 
        next if ! $hr->{$k}; 
        next if ($hr->{$k} =~ /^(ARRAY|HASH)/); 
        my $v = $hr->{$k};
        my @m = ( $v =~ /(\$\w+)\s*/g );    # matched variables
        next if (!@m); 
        foreach my $x (@m) { 
            my $y = $x; $y =~ s/^\$//; 
            if (exists $hr->{$y} || ($ar && exists $ar->{$y}) ) { 
                ++$kp->{$y}; 
            } else {
                $kp->{$y} += 0; 
                next; 
            } 
            $v =~ s{\$$y}{$hr->{$y}}    if  exists $hr->{$y}; 
            $v =~ s{\$$y}{$ar->{$y}}    if !exists $hr->{$y} 
                && $ar && exists $ar->{$y};
        }
        $hr->{$k} = $v;
    }
    return wantarray ? %$kp : $kp; 
}

=head2  eval_named_var($hr, $vn, $sr)

Input variables:

  $hr - a hash array ref containing variable names
  $vn - variable name default to 'ENV' 
  $sr - source hash ref. If omitted, {%$vn} will be used.

Variables used or routines called:

  None

How to use:

  my %ENV = (HTTP_HOST=>'testdomain.com:8000',USER=>'htu');
  my $hr  = {first_name=>'John', last_name=>'Smith'};
  my $cfg = { hh=>'$ENV{HTTP_HOST}',usr=>'$ENV{USER}',
             fn=>'$hr{first_name}', ln=>'$hr{last_name}',
           };
  my $p1 = $self->eval_named_var($cfg, 'ENV');
  # the first pass will get 
  #   $cfg->{hh}  = 'testdomain.com:8000'
  #   $cfg->{usr} = 'htu'
  my $p2 = $self->eval_named_var($cfg, 'hr', $hr);
  # the second pass will get 
  #   $cfg->{fn}  = 'John'
  #   $cfg->{ln}  = 'Smith'

Return: a hash or hash ref 

This method evaluates the variable names contained in a configuration
hash and replace the variable names with their values. 

=cut

sub eval_named_var {
    my $s = shift;
    my ($hr, $vn, $sr) = @_;
    return wantarray ? () : {}  if !$hr; 
    $vn = 'ENV'  if ! $vn; 
    no strict "refs"; 
    my $ar = ($sr) ? $sr : {%$vn}; 
    my $kp = {}; 
    foreach my $k (keys %$hr) {
        next if ! exists $hr->{$k}; 
        next if ! $hr->{$k}; 
        next if ($hr->{$k} =~ /^(ARRAY|HASH)/); 
        $hr->{$k} =~ s/^\s*//; $hr->{$k} =~ s/\s*$//;
        my $v = $hr->{$k};
	# http://ENV{HTTP_HOST}ENV{SCRIPT_NAME}
        my @m  = ( $v =~ /\$$vn\{(\w+)\}/gi ); # matched variables
	next if (!@m); 
        foreach my $x (@m) { 
            my $y = $x; $y =~ s/^\$//; 
            $v =~ s#\$$vn\{$y\}#$ar->{$y}#i  if exists $ar->{$y}; 
            ++$kp->{$y}                      if exists $ar->{$y}; 
        }
        $hr->{$k} = $v;
    }
    return wantarray ? %$kp : $kp; 
}

=head2  read_cfg_file($fn,$ot, $fs)

Input variables:

  $fn - full path to a file name
  $ot - output array type: A(array) or H(hash)
  $fs - field separator, default to vertical bar (|)


Variables used or routines called:

  CGI::AppBuilder::Message
    echo_msg  - display message

How to use:

  my $arf = $self->read_cfg_file('crop.cfg', 'H');

Return: an array or hash array ref containing (${$arf}[$i]{$itm},
${$arf}[$i][$j];

This method reads a configuraton file containing delimited fields. 
It looks a line starting with '#CN:' for column names. If it finds 
the line, it uses to define the first row in the array or use the 
column names as keys in the hash array. 

The default output type is A(array). It will read the field names
into the first row ([0][0]~[0][n]). If output array type is hash,
then it uses the columns name as keys such as ${$arf}[$i]{key}. 
If it does not find '#CN:' line, it will use 'FD001' ~ 'FD###' as
keys.

  #Form: fm1
  #CN: Step|VarName|DispName|Action|Description				
  0.0|t1|Title||CROP Worksheet				


=cut

sub read_cfg_file {
    my $s = shift;
    my ($fn,$ot,$fs) = @_;
    #
    if (!$fn)    { carp "    No file name is specified."; return; }
    if (!-f $fn) { carp "    File - $fn does not exist!"; return; }
    $s->echo_msg("    CFG - $fn.", 2);
    $ot = 'A' if !$ot;
    
    my (@a, @b, $i, $j, $k, @keys, $rec);
    open FILE, "< $fn" or
        croak "ERR: could not read to file - $fn: $!\n";
    @a = <FILE>;
    close FILE;
    my @r = (); 
    # get column names first
    for my $x (0..$#a) {
        $rec = $a[$x];
        next if ($rec !~ /^#\s*CN:\s*(.*)/);
        $k =$1; $k =~ s/^\s+//; $k =~ s/\s+$//; $k =~ s/\s+/_/g;
        @keys = split /\|/, $k;
        $r[0] = [@keys];
        last;
    }
    
    # get content
    $i = 0; $rec = "";
    for my $x (0..$#a) {
        # skip comment and empty lines
        next if ($a[$x] =~ /^#/ || $a[$x] =~ /^\s*$/);
        chomp $a[$x]; 
        if ($a[$x] =~ /^\s*\|/) {
            $rec .= " $a[$x]"; # continuous record
        } elsif (index($a[$x], "\|")>=0) {
            if ($rec) {        # save the previous record
                $rec =~ s/\s+/ /g; @b = split /\|/, $rec; 
                ++$i; $r[$i]=[@b];
            }
            $rec = $a[$x];     # a new record
        } else {
            $rec .= " $a[$x]"; # continuous record
        }
    }
    if ($rec) { 
        $rec =~ s/\s+/ /g; @b = split /\|/, $rec; 
        ++$i; $r[$i]=[@b];
    }
    if (!@keys) {  # if it did not get the keys
        for $j (0..$#{$r[1]}) {
            push @keys, (sprintf "DF%03d", $j+1);
        }
        $r[0] = [@keys];        
    }
    return \@r if $ot =~ /^A/i; 
    #
    my @hr = ();

    # convert the array into hash array
    for $i (1..$#r) {
        my %h = ();
        for $j (0..$#{$r[$i]}) {
            $k = $r[0][$j]; 
            # remove leading and trailing spaces  
            $k =~ s/^\s*//g; $k=~ s/\s*$//g;
            $h{$k} = $r[$i][$j]; 
            # remove leading and trailing spaces  
            $h{$k} =~ s/^\s*//g; $h{$k} =~ s/\s*$//g; 
        }
        $j = $i-1;
        $hr[$j] = \%h;
    }
    return \@hr;
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracts these methods from CGI::Getopt class: 
get_inputs, read_init_file, and read_cfg_file.

  0.11 Inherited the new constructor from CGI::AppBuilder.
  0.12 Added eval_var, eval_named_var, eval_variables and
       modified read_init_file method. 
  04/29/2010 (htu) - added get_opt sub

=item * Version 0.20

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::AppBuilder, File::Xcopy,
CGI::AppBuilder::Message

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

