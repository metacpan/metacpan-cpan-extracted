package Date::Manip::Delta;
# Copyright (c) 1995-2021 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################
# Any routine that starts with an underscore (_) is NOT intended for
# public use.  They are for internal use in the the Date::Manip
# modules and are subject to change without warning or notice.
#
# ABSOLUTELY NO USER SUPPORT IS OFFERED FOR THESE ROUTINES!
########################################################################

use Date::Manip::Obj;
@ISA = ('Date::Manip::Obj');

require 5.010000;
use warnings;
use strict;
use utf8;
use IO::File;
#use re 'debug';

use Date::Manip::Base;
use Date::Manip::TZ;

our $VERSION;
$VERSION='6.85';
END { undef $VERSION; }

########################################################################
# BASE METHODS
########################################################################

sub is_delta {
   return 1;
}

sub config {
   my($self,@args) = @_;
   $self->SUPER::config(@args);

   # A new config can change the value of the format fields, so clear them.
   $$self{'data'}{'f'}    = {};
   $$self{'data'}{'flen'} = {};
}

# Call this every time a new delta is put in to make sure everything is
# correctly initialized.
#
sub _init {
   my($self) = @_;

   my $def = [0,0,0,0,0,0,0];
   my $dmt = $$self{'tz'};
   my $dmb = $$dmt{'base'};

   $$self{'err'}  = '';
   $$self{'data'} =
     {
      'delta'      => $def,        # the delta put in (all negative fields signed)

      'in'         => '',          # the string that was parsed (if any)
      'length'     => 0,           # length of delta (in seconds)

      'gotmode'    => 0,           # 1 if mode set explicitly
      'mode'       => 'standard',  # standard/business
      'type'       => 'exact',     # exact, semi, estimated, approx
      'type_from'  => 'init',      # where did the type come from
                                   #    init - from here
                                   #    opt  - specified in an option/string
                                   #    det  - determined automatically
      'normalized' => 1,           # 1 if normalized

      'f'          => {},          # format fields
      'flen'       => {},          # field lengths
     }
}

sub _init_args {
   my($self) = @_;

   my @args = @{ $$self{'args'} };
   $self->parse(@args);
}

sub value {
   my($self,$as_input) = @_;

   if ($$self{'err'}) {
      return ()  if (wantarray);
      return '';
   }

   my $dmt = $$self{'tz'};
   my $dmb = $$dmt{'base'};

   my @delta   = @{ $$self{'data'}{'delta'} };

   return @delta  if (wantarray);
   my $err;

   my %o = ( 'source'  => 'delta',
             'nonorm'  => 1,
             'type'    => $$self{'data'}{'type'},
             'sign'    => 0,
             'mode'    => $$self{'data'}{'mode'},
           );

   ($err,@delta) = $dmb->_delta_fields( \%o, [@delta]);
   return join(':',@delta);
}

sub input {
   my($self) = @_;
   return  $$self{'data'}{'in'};
}

########################################################################
# DELTA METHODS
########################################################################

BEGIN {
   my %f   = qw( y 0  M 1  w 2  d 3  h 4  m 5  s 6 );

   sub set {
      my($self,@args) = @_;
      my %opts;
      if      (ref($args[0]) eq 'HASH') {
         %opts = %{ $args[0] };
      } else {
         # *** DEPRECATED 7.0 ***
         if (@args == 3) {
            %opts = ( $args[0] => $args[1],
                      'nonorm' => ($args[2] ? 1 : 0) );
         } else {
            %opts = ( $args[0] => $args[1] );
         }
      }

      # Check for some invalid opts

      foreach my $key (keys %opts) {
         my $val = $opts{$key};
         delete $opts{$key};

         # *** DEPRECATED 7.0 ***
         $key    = 'standard'  if (lc($key) eq 'normal');

         if (lc($key) eq 'delta'     ||
             lc($key) eq 'business'  ||
             lc($key) eq 'standard'  ||
             lc($key) eq 'nonorm'    ||
             lc($key) eq 'mode'      ||
             lc($key) eq 'type') {

            if (exists $opts{lc($key)}) {
               $key = lc($key);
               $$self{'err'} = "[set] Invalid option: $key entered twice";
               return 1;
            }

            $opts{lc($key)} = $val;

         } elsif ($key =~ /^[yMwdhms]$/) {

            $opts{$key} = $val;

         } else {
            $$self{'err'} = "[set] Unknown option: $key";
            return 1;
         }
      }

      if ( (exists $opts{'delta'}) +
           (exists $opts{'business'}) +
           (exists $opts{'standard'}) +
           (exists $opts{'y'} || exists $opts{'M'} || exists $opts{'w'} ||
            exists $opts{'d'} || exists $opts{'h'} || exists $opts{'m'} ||
            exists $opts{'s'})
           > 1 ) {
         $$self{'err'} = "[set] Fields set multiple times";
         return 1;
      }

      if (exists $opts{'mode'}  &&  $opts{'mode'} !~ /^(business|standard)$/) {
         $$self{'err'} = "[set] Unknown value for mode: $opts{mode}";
         return 1;
      }
      if (exists $opts{'type'}  &&
          $opts{'type'} !~ /^(exact|semi|estimated|approx)$/) {
         $$self{'err'} = "[set] Unknown value for type: $opts{type}";
         return 1;
      }

      if ( (exists $opts{'business'}) +
           (exists $opts{'standard'}) +
           (exists $opts{'mode'})
           > 1 ) {
         $$self{'err'} = "[set] Mode set multiple times";
         return 1;
      } elsif (exists $opts{'business'}) {
         $opts{'delta'} = $opts{'business'};
         $opts{'mode'}  = 'business';
      } elsif (exists $opts{'standard'}) {
         $opts{'delta'} = $opts{'standard'};
         $opts{'mode'}  = 'standard';
      }

      # If we are setting delta/business/standard, we need to initialize
      # all the parameters.

      my @delta;
      if (exists $opts{'delta'}) {
         if (ref($opts{'delta'}) ne 'ARRAY') {
            $$self{'err'} = "[set] Option delta requires an array value";
            return 1;
         }

         # Init everything because we're setting an entire new delta
         $self->_init();
         @delta = @{ $opts{'delta'} };

      } else {
         @delta      = @{ $$self{'data'}{'delta'} };
      }

      # Figure out the parameters.  Include the nonorm/mode/type
      # options.

      my $err;
      my $dmt        = $$self{'tz'};
      my $dmb        = $$dmt{'base'};
      my $gotmode    = (exists $opts{'mode'} ? 1 : $$self{'data'}{'gotmode'});
      my $mode       = (exists $opts{'mode'} ? $opts{'mode'} :
                        $$self{'data'}{'mode'});
      my $nonorm     = (exists $opts{'nonorm'} ? $opts{'nonorm'} : 0);

      my ($type,$type_from);
      if (exists $opts{'type'}) {
         $type       = $opts{'type'};
         $type_from  = 'opt';
      } else {
         $type       = $$self{'data'}{'type'};
         $type_from  = $$self{'data'}{'type_from'};
      }

      # If we're setting individual fields, do that now

      {
         my $field_set = 0;

         # Check all individual fields
         foreach my $opt (qw(y M w d h m s)) {
            if (exists $opts{$opt}) {
               if (ref($opts{$opt})) {
                  $$self{'err'} = "[set] Option $opt requires a scalar value";
                  return 1;
               }
               my $val = $opts{$opt};
               if (! $dmb->_is_num($val)) {
                  $$self{'err'} = "[set] Option $opt requires a numerical value";
                  return 1;
               }
               $delta[ $f{$opt} ] = $val;
               $field_set         = 1;
            }
         }

         # If none were set, than we're done with setting.
         last  if (! $field_set);

         if ($$self{'err'}) {
            return 1;
         }
      }

      # Check that the type is consistent with @delta.

      ($err,$type,$type_from) =
        $dmb->_check_delta_type($mode,$type,$type_from,@delta);

      if ($err) {
         $$self{'err'} = "[set] $err";
         return 1;
      }

      my %o = ( 'source'  => 'delta',
                'nonorm'  => $nonorm,
                'type'    => $type,
                'sign'    => -1,
                'mode'    => $mode,
              );

      ($err,@delta) = $dmb->_delta_fields( \%o, [@delta]);

      if ($err) {
         $$self{'err'} = "[set] $err";
         return 1;
      }

      $$self{'data'}{'delta'}      = [ @delta ];
      $$self{'data'}{'mode'}       = $mode;
      $$self{'data'}{'gotmode'}    = $gotmode;
      $$self{'data'}{'type'}       = $type;
      $$self{'data'}{'type_from'}  = $type_from;
      $$self{'data'}{'normalized'} = 1-$nonorm;
      $$self{'data'}{'length'}     = 'unknown';
      $$self{'data'}{'in'}         = '';

      return 0;
   }
}

sub _rx {
   my($self,$rx) = @_;
   my $dmt = $$self{'tz'};
   my $dmb = $$dmt{'base'};

   return $$dmb{'data'}{'rx'}{'delta'}{$rx}
     if (exists $$dmb{'data'}{'rx'}{'delta'}{$rx});

   if ($rx eq 'expanded') {
      my $sign    = '[-+]?\s*';
      my $sep     = '(?:,\s*|\s+|$)';

      my $nth     = $$dmb{'data'}{'rx'}{'nth'}[0];
      my $yf      = $$dmb{data}{rx}{fields}[1];
      my $mf      = $$dmb{data}{rx}{fields}[2];
      my $wf      = $$dmb{data}{rx}{fields}[3];
      my $df      = $$dmb{data}{rx}{fields}[4];
      my $hf      = $$dmb{data}{rx}{fields}[5];
      my $mnf     = $$dmb{data}{rx}{fields}[6];
      my $sf      = $$dmb{data}{rx}{fields}[7];
      my $num     = '(?:\d+(?:\.\d*)?|\.\d+)';

      my $y       = "(?:(?:(?<y>$sign$num)|(?<y>$nth))\\s*(?:$yf)$sep)";
      my $m       = "(?:(?:(?<m>$sign$num)|(?<m>$nth))\\s*(?:$mf)$sep)";
      my $w       = "(?:(?:(?<w>$sign$num)|(?<w>$nth))\\s*(?:$wf)$sep)";
      my $d       = "(?:(?:(?<d>$sign$num)|(?<d>$nth))\\s*(?:$df)$sep)";
      my $h       = "(?:(?:(?<h>$sign$num)|(?<h>$nth))\\s*(?:$hf)$sep)";
      my $mn      = "(?:(?:(?<mn>$sign$num)|(?<mn>$nth))\\s*(?:$mnf)$sep)";
      my $s       = "(?:(?:(?<s>$sign$num)|(?<s>$nth))\\s*(?:$sf)?)";

      my $exprx   = qr/^\s*$y?$m?$w?$d?$h?$mn?$s?\s*$/i;
      $$dmb{'data'}{'rx'}{'delta'}{$rx} = $exprx;

   } elsif ($rx eq 'mode') {

      my $mode = qr/\b($$dmb{'data'}{'rx'}{'mode'}[0])\b/i;
      $$dmb{'data'}{'rx'}{'delta'}{$rx} = $mode;

   } elsif ($rx eq 'when') {

      my $when = qr/\b($$dmb{'data'}{'rx'}{'when'}[0])\b/i;
      $$dmb{'data'}{'rx'}{'delta'}{$rx} = $when;

   }

   return $$dmb{'data'}{'rx'}{'delta'}{$rx};
}

sub parse {
   my($self,$instring,@args) = @_;
   $self->_init();

   my %opts;
   if (ref($args[0]) eq 'HASH') {
      %opts = %{ $args[0] };

   } else {
      # *** DEPRECATED 7.0 ***

      my($business,$no_normalize);

      if (@args == 2) {
         ($business,$no_normalize) = (lc($args[0]),lc($args[1]));
         if      ($business eq 'standard'  ||  ! $business) {
            $opts{'mode'} = 'standard';
         } else {
            $opts{'mode'} = 'business';
         }

         $opts{'nonorm'} = ($no_normalize ? 1 : 0);

      } elsif (@args == 1) {
         my $arg = lc($args[0]);
         if      ($arg eq 'standard') {
            $opts{'mode'} = 'standard';
         } elsif ($arg eq 'business') {
            $opts{'mode'} = 'business';
         } elsif ($arg eq 'nonormalize') {
            $opts{'nonorm'} = 1;
         } elsif ($arg) {
            $opts{'mode'} = 'business';
         } else {
            $opts{'mode'} = 'standard';
         }

      } elsif (@args) {
         $$self{'err'} = "[parse] Unknown arguments";
         return 1;
      }
   }

   my $dmt = $$self{'tz'};
   my $dmb = $$dmt{'base'};
   $self->_init();

   if (! $instring) {
      $$self{'err'} = '[parse] Empty delta string';
      return 1;
   }

   #
   # Parse the string
   #    $err   : any error
   #    @delta : the delta parsed
   #    $mode  : the mode string (if any) in the string
   #

   my ($err,@delta,$mode);
   $mode         = '';
   $$self{'err'} = '';
   $instring     =~ s/^\s*//;
   $instring     =~ s/\s*$//;

   PARSE: {

      # First, we'll try the standard format (without a mode string)

      ($err,@delta) = $dmb->_split_delta($instring);
      last PARSE  if (! $err);

      # Next, we'll need to get a list of all the encodings and look
      # for (and remove) the mode string from each.  We'll also recheck
      # the standard format for each.

      my @strings = $dmb->_encoding($instring);
      my $moderx  = $self->_rx('mode');

      foreach my $string (@strings) {
         if ($string =~ s/\s*$moderx\s*//i) {
            my $m = $1;
            if ($$dmb{'data'}{'wordmatch'}{'mode'}{lc($m)} == 1) {
               $m = 'standard';
            } else {
               $m = 'business';
            }
            $mode = $m;

            ($err,@delta) = $dmb->_split_delta($string);
            last PARSE  if (! $err);
         }
      }

      # Now we'll check each string for an expanded form delta.

      foreach my $string (@strings) {
         my $past    = 0;

         my $whenrx  = $self->_rx('when');
         if ($string  &&
             $string =~ s/$whenrx//i) {
            my $when = $1;
            if ($$dmb{'data'}{'wordmatch'}{'when'}{lc($when)} == 1) {
               $past   = 1;
            }
         }

         my $rx        = $self->_rx('expanded');
         if ($string  &&
             $string   =~ $rx) {
            @delta     = @+{qw(y m w d h mn s)};
            foreach my $f (@delta) {
               if (! defined $f) {
                  $f = 0;
               } elsif (exists $$dmb{'data'}{'wordmatch'}{'nth'}{lc($f)}) {
                  $f = $$dmb{'data'}{'wordmatch'}{'nth'}{lc($f)};
               } else {
                  $f =~ s/\s//g;
               }
            }

            # if $past, reverse the signs
            if ($past) {
               foreach my $v (@delta) {
                  $v *= -1;
               }
            }

            last PARSE;
         }
      }
   }

   if (! @delta) {
      $$self{'err'} = "[parse] Invalid delta string";
      return 1;
   }

   # If the string contains a mode string and the mode was passed in
   # as an option, they must be identical.

   if ($mode  &&  exists($opts{'mode'})  &&  $mode ne $opts{'mode'}) {
      $$self{'err'} =
        "[parse] Mode option conflicts with mode specified in string";
      return 1;
   }
   $mode = $opts{'mode'}  if (exists $opts{'mode'});
   $mode = 'standard'     if (! $mode);

   # Figure out the type.

   my %o = ( 'source'  => 'string',
             'nonorm'  => (exists $opts{'nonorm'} ? $opts{'nonorm'} : 0),
             'sign'    => -1,
             'mode'    => $mode,
           );

   ($err,@delta) = $dmb->_delta_fields( \%o, [@delta]);
   my $type      = $o{'type'};
   my $type_from = $o{'type_from'};

   if ($err) {
      $$self{'err'} = "[parse] $err";
      return 1;
   }

   $$self{'data'}{'in'}         = $instring;
   $$self{'data'}{'delta'}      = [@delta];
   $$self{'data'}{'mode'}       = $mode;
   $$self{'data'}{'gotmode'}    = ($mode  ||  exists $opts{'mode'} ? 1 : 0);
   $$self{'data'}{'type'}       = $type;
   $$self{'data'}{'type_from'}  = $type_from;
   $$self{'data'}{'length'}     = 'unknown';
   $$self{'data'}{'normalized'} = ($opts{'nonorm'} ? 0 : 1);

   return 0;
}

sub printf {
   my($self,@in) = @_;
   if ($$self{'err'}) {
      warn "WARNING: [printf] Object must contain a valid delta\n";
      return undef;
   }

   my($y,$M,$w,$d,$h,$m,$s) = @{ $$self{'data'}{'delta'} };

   my @out;
   foreach my $in (@in) {
      my $out = '';
      while ($in) {
         if ($in =~ s/^([^%]+)//) {
            $out .= $1;

         } elsif ($in =~ s/^%%//) {
            $out .= "%";

         } elsif ($in =~ s/^%
                           (\+)?                   # sign
                           ([<>0])?                # pad
                           (\d+)?                  # width
                           ([yMwdhms])             # field
                           v                       # type
                          //ox) {
            my($sign,$pad,$width,$field) = ($1,$2,$3,$4);
            $out .= $self->_printf_field($sign,$pad,$width,0,$field);

         } elsif ($in =~ s/^(%
                              (\+)?                   # sign
                              ([<>0])?                # pad
                              (\d+)?                  # width
                              (?:\.(\d+))?            # precision
                              ([yMwdhms])             # field
                              ([yMwdhms])             # field0
                              ([yMwdhms])             # field1
                           )//ox) {
            my($match,$sign,$pad,$width,$precision,$field,$field0,$field1) =
              ($1,$2,$3,$4,$5,$6,$7,$8);

            # Get the list of fields we're expressing

            my @field = qw(y M w d h m s);
            while (@field  &&  $field[0] ne $field0) {
               shift(@field);
            }
            while (@field  &&  $field[$#field] ne $field1) {
               pop(@field);
            }

            if (! @field) {
               $out .= $match;
            } else {
               $out .=
                 $self->_printf_field($sign,$pad,$width,$precision,$field,@field);
            }

         } elsif ($in =~ s/^%
                           (\+)?                   # sign
                           ([<>])?                 # pad
                           (\d+)?                  # width
                           Dt
                          //ox) {
            my($sign,$pad,$width) = ($1,$2,$3);
            $out .= $self->_printf_delta($sign,$pad,$width,'y','s');

         } elsif ($in =~ s/^(%
                              (\+)?                   # sign
                              ([<>])?                 # pad
                              (\d+)?                  # width
                              D
                              ([yMwdhms])             # field0
                              ([yMwdhms])             # field1
                           )//ox) {
            my($match,$sign,$pad,$width,$field0,$field1) = ($1,$2,$3,$4,$5,$6);

            # Get the list of fields we're expressing

            my @field = qw(y M w d h m s);
            while (@field  &&  $field[0] ne $field0) {
               shift(@field);
            }
            while (@field  &&  $field[$#field] ne $field1) {
               pop(@field);
            }

            if (! @field) {
               $out .= $match;
            } else {
               $out .= $self->_printf_delta($sign,$pad,$width,$field[0],
                                            $field[$#field]);
            }

         } else {
            $in =~ s/^(%[^%]*)//;
            $out .= $1;
         }
      }
      push(@out,$out);
   }

   if (wantarray) {
      return @out;
   } elsif (@out == 1) {
      return $out[0];
   }

   return ''
}

sub _printf_delta {
   my($self,$sign,$pad,$width,$field0,$field1) = @_;
   my $dmt = $$self{'tz'};
   my $dmb = $$dmt{'base'};
   my @delta = @{ $$self{'data'}{'delta'} };
   my $delta;
   my %tmp   = qw(y 0 M 1 w 2 d 3 h 4 m 5 s 6);

   # Add a sign to each field

   my $s = "+";
   foreach my $f (@delta) {
      if ($f < 0) {
         $s = "-";
      } elsif ($f > 0) {
         $s = "+";
         $f *= 1;
         $f = "+$f";
      } else {
         $f = "$s$f";
      }
   }

   # Split the delta into field sets containing only those fields to
   # print.
   #
   # @set = ( [SETa] [SETb] ....)
   #   where [SETx] is a listref of fields from one set of fields

   my @set;
   my $mode = $$self{'data'}{'mode'};

   my $f0 = $tmp{$field0};
   my $f1 = $tmp{$field1};

   if ($field0 eq $field1) {
      @set = ( [ $delta[$f0] ] );

   } elsif ($mode eq 'business') {

      if ($f0 <= 1) {
         # if (field0 = y or M)
         #    add [y,M]
         #    if field1 = M
         #       done
         #    else
         #       field0 = w
         push(@set, [ @delta[$f0..1] ]);
         $f0 = ($f1 == 1 ? 7 : 2);
      }

      if ($f0 == 2) {
         # if (field0 = w)
         #    add [w]
         #    if field1 = w
         #       done
         #    else
         #       field0 = d
         push(@set, [ $delta[2] ]);
         $f0 = ($f1 == 2 ? 7 : 3);
      }

      if ($f0 <= 6) {
         push(@set, [ @delta[$f0..$f1] ]);
      }

   } else {

      if ($f0 <= 1) {
         # if (field0 = y or M)
         #    add [y,M]
         #    if field1 = M
         #       done
         #    else
         #       field0 = w
         push(@set, [ @delta[$f0..1] ]);
         $f0 = ($f1 == 1 ? 7 : 2);
      }

      if ($f0 <= 3) {
         # if (field0 = w or d)
         #    if (field1 = w or d)
         #       add [w ... [f1]]
         #       done
         #    else
         #       add [w,d]
         #       field0 = h
         if ($f1 <= 3) {
            push(@set, [ @delta[$f0..$f1] ]);
            $f0 = 7;
         } else {
            push(@set, [ @delta[$f0..3] ]);
            $f0 = 4;
         }
      }

      if ($f0 <= 6) {
         push(@set, [ @delta[$f0..$f1] ]);
      }
   }

   # If we're not forcing signs, remove signs from all fields
   # except the first in each set.

   my @ret;

   foreach my $set (@set) {
      my @f = @$set;

      if (defined($sign)  &&  $sign eq "+") {
         push(@ret,@f);
      } else {
         push(@ret,shift(@f));
         foreach my $f (@f) {
            $f =~ s/[-+]//;
            push(@ret,$f);
         }
      }
   }

   # Width/pad

   my $ret = join(':',@ret);
   if ($width  &&  length($ret) < $width) {
      if (defined $pad  &&  $pad eq ">") {
         $ret .= ' 'x($width-length($ret));
      } else {
         $ret = ' 'x($width-length($ret)) . $ret;
      }
   }

   return $ret;
}

sub _printf_field {
   my($self,$sign,$pad,$width,$precision,$field,@field) = @_;

   my $val = $self->_printf_field_val($field,@field);
   $pad    = "<"  if (! defined($pad));

   # Strip off the sign.

   my $s = '';

   if ($val < 0) {
      $s   = "-";
      $val *= -1;
   } elsif ($sign) {
      $s   = "+";
   }

   # Handle the precision.

   if (defined($precision)) {
      $val = sprintf("%.${precision}f",$val);

   } elsif (defined($width)) {
      my $i = $s . int($val) . '.';
      if (length($i) < $width) {
         $precision = $width-length($i);
         $val = sprintf("%.${precision}f",$val);
      }
   }

   # Handle padding.

   if ($width) {
      if      ($pad eq ">") {
         $val = "$s$val";
         my $pad = ($width > length($val) ? $width - length($val) : 0);
         $val .= ' 'x$pad;

      } elsif ($pad eq "<") {
         $val = "$s$val";
         my $pad = ($width > length($val) ? $width - length($val) : 0);
         $val = ' 'x$pad . $val;

      } else {
         my $pad = ($width > length($val)-length($s) ?
                    $width - length($val) - length($s): 0);
         $val = $s . '0'x$pad . $val;
      }
   } else {
      $val = "$s$val";
   }

   return $val;
}

# $$self{'data'}{'f'}{X}{Y} is the value of field X expressed in terms of Y.
#
sub _printf_field_val {
   my($self,$field,@field) = @_;

   if (! exists $$self{'data'}{'f'}{'y'}  &&
       ! exists $$self{'data'}{'f'}{'y'}{'y'}) {

      my($yv,$Mv,$wv,$dv,$hv,$mv,$sv) = map { $_*1 } @{ $$self{'data'}{'delta'} };
      $$self{'data'}{'f'}{'y'}{'y'} = $yv;
      $$self{'data'}{'f'}{'M'}{'M'} = $Mv;
      $$self{'data'}{'f'}{'w'}{'w'} = $wv;
      $$self{'data'}{'f'}{'d'}{'d'} = $dv;
      $$self{'data'}{'f'}{'h'}{'h'} = $hv;
      $$self{'data'}{'f'}{'m'}{'m'} = $mv;
      $$self{'data'}{'f'}{'s'}{'s'} = $sv;
   }

   # A single field

   if (! @field) {
      return $$self{'data'}{'f'}{$field}{$field};
   }

   # Find the length of 1 unit of each field in terms of seconds.

   if (! exists $$self{'data'}{'flen'}{'s'}) {
      my $mode     = $$self{'data'}{'mode'};
      my $dmb      = $self->base();
      $$self{'data'}{'flen'} = { 's'  => 1,
                                 'm'  => 60,
                                 'h'  => 3600,
                                 'd'  => $$dmb{'data'}{'len'}{$mode}{'dl'},
                                 'w'  => $$dmb{'data'}{'len'}{$mode}{'wl'},
                                 'M'  => $$dmb{'data'}{'len'}{$mode}{'ml'},
                                 'y'  => $$dmb{'data'}{'len'}{$mode}{'yl'},
                               };
   }

   # Calculate the value for each field.

   my $val = 0;
   foreach my $f (@field) {

      # We want the value of $f expressed in terms of $field

      if (! exists $$self{'data'}{'f'}{$f}{$field}) {

         # Get the value of $f expressed in seconds

         if (! exists $$self{'data'}{'f'}{$f}{'s'}) {
            $$self{'data'}{'f'}{$f}{'s'} =
              $$self{'data'}{'f'}{$f}{$f} * $$self{'data'}{'flen'}{$f};
         }

         # Get the value of $f expressed in terms of $field

         $$self{'data'}{'f'}{$f}{$field} =
           $$self{'data'}{'f'}{$f}{'s'} / $$self{'data'}{'flen'}{$field};
      }

      $val += $$self{'data'}{'f'}{$f}{$field};
   }

   return $val;
}

sub type {
   my($self,$op) = @_;
   $op = lc($op);

   if ($op eq 'business'  ||
       $op eq 'standard') {
      return ($$self{'data'}{'mode'} eq $op ? 1 : 0);
   }

   return ($$self{'data'}{'type'} eq $op ? 1 : 0);
}

sub calc {
   my($self,$obj,@args) = @_;
   if ($$self{'err'}) {
      $$self{'err'} = "[calc] First object invalid (delta)";
      return undef;
   }

   if      (ref($obj) eq 'Date::Manip::Date') {
      if ($$obj{'err'}) {
         $$self{'err'} = "[calc] Second object invalid (date)";
         return undef;
      }
      return $obj->calc($self,@args);

   } elsif (ref($obj) eq 'Date::Manip::Delta') {
      if ($$obj{'err'}) {
         $$self{'err'} = "[calc] Second object invalid (delta)";
         return undef;
      }
      return $self->_calc_delta_delta($obj,@args);

   } else {
      $$self{'err'} = "[calc] Second object must be a Date/Delta object";
      return undef;
   }
}

sub __type_max {
   my($type1,$type2) = @_;
   return $type1  if ($type1 eq $type2);
   foreach my $type ('estimate','approx','semi') {
      return $type  if ($type1 eq $type  ||  $type2 eq $type);
   }
   return 'exact';
}

sub _calc_delta_delta {
   my($self,$delta,@args) = @_;
   my $dmt = $$self{'tz'};
   my $dmb = $$dmt{'base'};
   my $ret = $self->new_delta;

   my($subtract,$no_normalize);
   if (@args > 2) {
      $$ret{'err'} = "Unknown args in calc";
      return $ret;
   }

   if      (@args == 2) {
      ($subtract,$no_normalize) = @args;
   } elsif (@args == 1) {
      if ($args[0] eq 'nonormalize') {
         $subtract     = 0;
         $no_normalize = 1;
      } else {
         $subtract     = $args[0];
         $no_normalize = 0;
      }
   } else {
      $subtract     = 0;
      $no_normalize = 0;
   }

   if ($$self{'data'}{'mode'} ne $$delta{'data'}{'mode'}) {
      $$ret{'err'} = "[calc] Delta/delta calculation objects must be of " .
        'the same mode';
      return $ret;
   }

   my ($err,@delta);
   for (my $i=0; $i<7; $i++) {
      if ($subtract) {
         $delta[$i] = $$self{'data'}{'delta'}[$i] - $$delta{'data'}{'delta'}[$i];
      } else {
         $delta[$i] = $$self{'data'}{'delta'}[$i] + $$delta{'data'}{'delta'}[$i];
      }
   }

   my $type = __type_max($$self{'data'}{'type'},
                         $$delta{'data'}{'type'});
   my %o = ( 'source'  => 'delta',
             'nonorm'  => $no_normalize,
             'sign'    => -1,
             'type'    => $type,
             'mode'    => $$self{'data'}{'mode'},
           );

   ($err,@delta) = $dmb->_delta_fields( \%o, [@delta]);

   $$ret{'data'}{'in'}         = '';
   $$ret{'data'}{'delta'}      = [@delta];
   $$ret{'data'}{'mode'}       = $$self{'data'}{'mode'};
   $$ret{'data'}{'gotmode'}    = 1;
   $$ret{'data'}{'type'}       = $type;
   $$ret{'data'}{'type_from'}  = 'det';
   $$ret{'data'}{'length'}     = 'unknown';
   $$ret{'data'}{'normalized'} = 1-$no_normalize;

   return $ret;
}

sub convert {
   my($self,$to) = @_;

   my %mode_val = ( 'exact'     => 0,
                    'semi'      => 1,
                    'approx'    => 2,
                    'estimated' => 3,
                  );

   my $from     = $$self{'data'}{'type'};
   my $from_val = $mode_val{$from};
   my $to_val   = $mode_val{$to};

   return  if ($from_val == $to_val);

   #
   # Converting from exact to less exact
   #

   if ($from_val < $to_val) {

      $self->set( { 'nonorm'  => 0,
                    'type'    => $to } );
      return;
   }

   #
   # Converting from less exact to more exact
   # *** DEPRECATE *** 7.00
   #

   my @fields;
   {
      no integer;

      my $dmb = $self->base();
      my $mode= $$self{'data'}{'mode'};
      my $yl  = $$dmb{'data'}{'len'}{$mode}{'yl'};
      my $ml  = $$dmb{'data'}{'len'}{$mode}{'ml'};
      my $wl  = $$dmb{'data'}{'len'}{$mode}{'wl'};
      my $dl  = $$dmb{'data'}{'len'}{$mode}{'dl'};

      # Convert it to seconds

      my($y,$m,$w,$d,$h,$mn,$s) = @{ $$self{'data'}{'delta'} };
      $s += $y*$yl + $m*$ml + $w*$wl + $d*$dl + $h*3600 + $mn*60;

      @fields  = (0,0,0,0,0,0,$s);

      if ($mode eq 'business') {

         if ($to eq 'estimated') {
            @fields = $dmb->_normalize_bus_est(@fields);

         } elsif ($to eq 'approx'  ||
                  $to eq 'semi') {
            @fields = $dmb->_normalize_bus_approx(@fields);

         } else {
            @fields = $dmb->_normalize_bus_exact(@fields);
         }

      } else {

         if ($to eq 'estimated') {
            @fields = $dmb->_normalize_est(@fields);

         } elsif ($to eq 'approx'  ||
                  $to eq 'semi') {
            @fields = $dmb->_normalize_approx(@fields);

         } else {
            @fields = $dmb->_normalize_exact(@fields);
         }

      }
   }

   $$self{'data'}{'delta'}      = [ @fields ];
   $$self{'data'}{'gotmode'}    = 1;
   $$self{'data'}{'type'}       = $to;
   $$self{'data'}{'type_from'}  = 'opt';
   $$self{'data'}{'normalized'} = 1;
   $$self{'data'}{'length'}     = 'unknown';
}

sub cmp {
   my($self,$delta) = @_;

   if ($$self{'err'}) {
      warn "WARNING: [cmp] Arguments must be valid deltas: delta1\n";
      return undef;
   }

   if (! ref($delta) eq 'Date::Manip::Delta') {
      warn "WARNING: [cmp] Argument must be a Date::Manip::Delta object\n";
      return undef;
   }
   if ($$delta{'err'}) {
      warn "WARNING: [cmp] Arguments must be valid deltas: delta2\n";
      return undef;
   }

   if ($$self{'data'}{'mode'} ne $$delta{'data'}{'mode'}) {
      warn "WARNING: [cmp] Deltas must both be business or standard\n";
      return undef;
   }

   my $mode = $$self{'data'}{'mode'};
   my $dmb  = $self->base();
   my $yl   = $$dmb{'data'}{'len'}{$mode}{'yl'};
   my $ml   = $$dmb{'data'}{'len'}{$mode}{'ml'};
   my $wl   = $$dmb{'data'}{'len'}{$mode}{'wl'};
   my $dl   = $$dmb{'data'}{'len'}{$mode}{'dl'};

   if ($$self{'data'}{'length'} eq 'unknown') {
      my($y,$m,$w,$d,$h,$mn,$s) = @{ $$self{'data'}{'delta'} };

      no integer;
      $$self{'data'}{'length'}  = int($y*$yl + $m*$ml + $w*$wl +
                                      $d*$dl + $h*3600 + $mn*60 + $s);
   }

   if ($$delta{'data'}{'length'} eq 'unknown') {
      my($y,$m,$w,$d,$h,$mn,$s) = @{ $$delta{'data'}{'delta'} };

      no integer;
      $$delta{'data'}{'length'}  = int($y*$yl + $m*$ml + $w*$wl +
                                       $d*$dl + $h*3600 + $mn*60 + $s);
   }

   return ($$self{'data'}{'length'} <=> $$delta{'data'}{'length'});
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
