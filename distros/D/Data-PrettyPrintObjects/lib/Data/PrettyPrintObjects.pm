package Data::PrettyPrintObjects;
# Copyright (c) 2010-2010 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

########################################################################
# PREREQUISITES
########################################################################

use warnings;
use strict;

require Exporter;
use Scalar::Util qw(reftype blessed);

our (@ISA,@EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(PPO
             PPO_Options
             PPO_OptionsFile
            );

use YAML::Syck;

our $VERSION;
$VERSION='1.00';

########################################################################
# INITIALIZATION
########################################################################

my $config_file = '.ppo.yaml';

our(%Options,%Refs,$Links,%Defaults,%ObjDefaults,%Printed);

# %Options = ( OPTION   => VAL,
#              ...
#              objs     => { OBJECT    => { OBJ_OPTION => VAL,
#                                           ...
#                                         },
#                            ...
#                          }
#            )
#
#            OPTION is any key included in %Defaults
#            OBJ_OPTION is any key included in %ObjDefautls
#            OBJECT is any value returned by ref($object)

# %Refs    = ( REF       => [ LINK, N ],
#              ...
#            )
#
#            REF is ARRAY(0x111111)
#            LINK is $VAR->[0]
#            N is the number of times this reference appears in
#               the data structure

# $Links   = 1  if ciruclar or duplicate references are found
#               in the data structure

# %Printed = ( REF => 1,
#              ...
#            )
#
#            This is a list of all references (keys from %Refs)
#            which have already been printed.

%Defaults = ( 'indent'           => 2,
              'list_format'      => 'standard',
              'max_depth'        => 0,
              'max_depth_method' => 'ref',
              'duplicates'       => 'link',
            );

%ObjDefaults = ( 'print'         => 'ref',
                 'type'          => 'scalar',
                 'ref'           => 0,
                 'args'          => [],
                 'func'          => '',
               );

if (-f $config_file) {
   PPO_OptionsFile($config_file);
}

########################################################################
# BASE METHODS
########################################################################

sub PPO_Options {
   my(%options) = @_;
   foreach my $key (keys %options) {
      if ($key eq 'objs') {
         foreach my $obj (keys %{ $options{$key} }) {
            my $val = $options{$key}{$obj};
            $Options{$key}{$obj} = $val;
         }
      } else {
         my $val = $options{$key};
         $Options{$key} = $val;
      }
   }
}

sub PPO_OptionsFile {
   my($file) = @_;
   my $opts  = LoadFile($file);

   foreach my $key (keys %$opts) {
      if ($key eq 'objs') {
         foreach my $obj (keys %{ $$opts{$key} }) {
            my $val = $$opts{$key}{$obj};
            $Options{$key}{$obj} = $val;
         }
      } else {
         my $val = $$opts{$key};
         $Options{$key} = $val;
      }
   }
}

sub PPO {
   my ($val) = @_;

   _refs($val);

   my $depth = 1;
   my $type  = ref($val);
   my @str;

   if (! $type) {
      @str = _print_scalar($val);

   } elsif ($type eq "ARRAY") {
      @str = _print_array($val,$depth);

   } elsif ($type eq "HASH") {
      @str = _print_hash($val,$depth);

   } else {
      @str = _print_object($val,$depth);
   }

   my $str = join("\n",@str) . "\n";
   return $str;
}

########################################################################
########################################################################

sub _option {
   my($opt,$obj) = @_;

   if (defined $obj) {
      if      (exists $Options{'objs'}{$obj}{$opt}) {
         return $Options{'objs'}{$obj}{$opt};
      } elsif (exists $ObjDefaults{$opt}) {
         return $ObjDefaults{$opt};
      } else {
         return undef;
      }

   } else {
      if      (exists $Options{$opt}) {
         return $Options{$opt};
      } elsif (exists $Defaults{$opt}) {
         return $Defaults{$opt};
      } else {
         return undef;
      }
   }
}

# This recurses through a structure and gets a list of
# refs and the path to each.
#
sub _refs {
   my($var) = @_;
   %Refs    = ();
   $Links   = 0;
   __refs($var,'$VAR');
}
sub __refs {
   my($var,$link) = @_;

   my $type    = ref($var);
   return      if (! $type);

   # Check to see if we've encountered this reference before... i.e. a
   # circular link, or a reference embedded multiple times.
   my $ref     = scalar($var);
   if (exists($Refs{$ref})) {
      $Links   = 1;
      $Refs{$ref}[1]++;
      return;
   }

   $Refs{$ref} = [$link,1];

   if      ($type eq 'ARRAY') {
      for (my $i=0; $i<@$var; $i++) {
         __refs($$var[$i],$link . "->[$i]");
      }

   } elsif ($type eq 'HASH') {
      foreach my $key (keys %$var) {
         __refs($$var{$key},$link . "->{$key}");
      }
   }
}

sub _print_object {
   my($val,$depth) = @_;

   my $type = ref($val);

   my $opt_print  = _option('print',$type);
   my $opt_func   = _option('func',$type);
   my $opt_args   = _option('args',$type);
   my $opt_type   = _option('type',$type);
   my $opt_ref    = _option('ref',$type);

   if      ($opt_print eq 'ref') {
      return (scalar($val));

   } elsif ($opt_print eq 'method'  ||
            $opt_print eq 'func') {
      my @str;

      my $func_defined = 0;

      if ($opt_print eq 'func') {
         my ($caller) = caller;
         my ($bless)  = blessed($val);

         my @func     = ("${caller}::$opt_func",
                         "${bless}::$opt_func",
                         "::$opt_func",
                        );
         foreach my $func (@func) {
            if (defined &$func) {
               $opt_func = $func;
               $func_defined = 1;
               last;
            }
         }
      }

      if ($opt_print eq 'method') {
         $func_defined = 1  if ($val->can($opt_func));
      }

      if (! $func_defined) {
         return ('*** NO FUNCTION ***');
      }

      if ($opt_ref) {
         push(@str,scalar($val) . ' ');
      }

      my @args = @$opt_args;
      if ($opt_print eq 'func') {
         foreach my $arg (@args) {
            $arg = $val  if ($arg eq '$OBJ');
         }
      }

      if      ($opt_type eq 'list') {
         my @list;
         if ($opt_print eq 'method') {
            @list = $val->$opt_func(@args);
         } else {
            no strict 'refs';
            @list = &$opt_func(@args);
         }
         if (@list == 1  &&  ref($list[0]) eq 'ARRAY') {
            @list = @{ $list[0] };
         }

         _append(\@str,_print_array(\@list,$depth+1));

      } elsif ($opt_type eq 'hash') {
         my @list;
         my %hash;
         if ($opt_print eq 'method') {
            @list = $val->$opt_func(@args);
         } else {
            no strict 'refs';
            @list = &$opt_func(@args);
         }
         if (@list == 1  &&  ref($list[0]) eq 'HASH') {
            %hash = %{ $list[0] };
         } else {
            %hash = @list;
         }

         _append(\@str,_print_hash(\%hash,$depth+1));

      } else {
         if ($opt_print eq 'method') {
            _append(\@str,scalar($val->$opt_func(@args)));
         } else {
            _append(\@str,scalar(&$opt_func(@args)));
         }
      }

      return @str;

   } elsif ($opt_print eq 'data') {
      $type = reftype($val);
      my @str;

      if ($opt_ref) {
         push(@str,scalar($val) . ' ');
      }

      if      ($type eq "ARRAY") {
         _append(\@str,_print_array($val,$depth));

      } elsif ($type eq "HASH") {
         _append(\@str,_print_hash($val,$depth));

      } else {
         _append(\@str,_print_scalar($val));
      }

      return @str;
   }
}

# indexed:
#   [
#     0 : VAL|STRUCT,
#     1 : VAL|STRUCT,
#     ...
#   ]
#
# standard:
#   [
#     VAL|STRUCT,
#     VAL|STRUCT,
#     ...
#   ]
#
sub _print_array {
   my($listref,$depth) = @_;

   # handle duplicates
   my ($done,@str) = _duplicates($listref);
   return @str     if ($done);

   my $opt_indent  = _option('indent');
   my $opt_maxdep  = _option('max_depth');
   my $opt_format  = _option('list_format');
   $opt_indent     = 1  if (! $opt_indent);   # To handle the [ ]

   # Determine how much to indent the list, an index, and a value
   #    ..... [
   #      [IDX: ]VAL,
   #    }
   #      ^      ^
   #      |      |
   #      |      idxindent + maxidxlen
   #      $opt_indent

   my @vals          = @$listref;
   my $maxidxlen     = length(scalar(@vals)) + 2;
   my $idxindent     = $opt_indent;
   my $valindent     = ($opt_format eq 'indexed' ?
                        $idxindent + $maxidxlen + 3 :
                        $idxindent);
   my $nextindent    = $idxindent + $opt_indent;
   my $idxindentstr  = " "x$idxindent;
   my $valindentstr  = " "x$valindent;

   _append(\@str,'[');

   for (my $i=0; $i<=$#vals; $i++) {
      my $val      = $vals[$i];
      my $type     = ref($val);

      # Print indentationsIDX:

      if ($opt_format eq 'indexed') {
         push(@str,"$idxindentstr$i: " . " "x($maxidxlen-length($i)-2));
      } elsif ($opt_format eq 'standard') {
         push(@str,$valindentstr);
      }

      # Print val

      my ($first,@tmp,$indentstr);
      $indentstr = $idxindentstr;

      if (! $type) {
         ($first,@tmp) = _print_scalar($val);
         $indentstr    = $valindentstr;

      } elsif ($depth == $opt_maxdep) {
         ($first,@tmp) = _print_maxdepth($val);

      } elsif ($type eq "ARRAY") {
         ($first,@tmp) = _print_array($val,$depth+1);

      } elsif ($type eq "HASH") {
         ($first,@tmp) = _print_hash($val,$depth+1);

      } else {
         ($first,@tmp) = _print_object($val,$depth+1);
      }

      @tmp         = map { "$indentstr$_" } @tmp;
      _append(\@str,$first,@tmp);

      # The last value won't get a comma
      _append(\@str,',')  if ($i < $#vals);
   }

   push(@str,']');
   return @str;
}

# {
#   key => val,      val is a scalar
#   key => REF,      we're at max_depth, val is a ref
#   key => STRUCT,   otherwise
# }
#
sub _print_hash {
   my($hashref,$depth) = @_;

   # handle duplicates
   my ($done,@str) = _duplicates($hashref);
   return @str     if ($done);

   my $opt_indent  = _option('indent');
   my $opt_maxdep  = _option('max_depth');
   $opt_indent     = 1  if (! $opt_indent);   # To handle the { }

   # Determine how much to indent the hash, a key, and a value
   # (for multiline scalars).
   #    ..... {
   #      key     => val
   #    }
   #      ^       ^  ^
   #      |       |  |
   #      |       |  keyindent + maxkeylen + 3
   #      |       keyindent + maxkeylen
   #      $opt_indent

   my @keys          = keys %$hashref;
   my $maxkeylen     = _maxLength(@keys) + 1;
   my $keyindent     = $opt_indent;
   my $valindent     = $keyindent + $maxkeylen + 3;
   my $keyindentstr  = " "x$keyindent;
   my $valindentstr  = " "x$valindent;

   _append(\@str,'{');

   my $i           = 0;
   foreach my $key (sort @keys) {
      $i++;
      my $val      = $$hashref{$key};
      my $type     = ref($val);

      # Print key    =>

      my @tmp      = map { "$keyindentstr$_" } _print_scalar($key);
      my $tmp      = pop(@tmp);
      $tmp        .= " "x($keyindent+$maxkeylen-length($tmp)) . '=> ';
      push(@str,@tmp,$tmp);

      # Print val

      my ($first,$indentstr);
      $indentstr = $keyindentstr;

      if (! $type) {
         ($first,@tmp) = _print_scalar($val);
         $indentstr    = $valindentstr;

      } elsif ($depth == $opt_maxdep) {
         ($first,@tmp) = _print_maxdepth($val);

      } elsif ($type eq "ARRAY") {
         ($first,@tmp) = _print_array($val,$depth+1);

      } elsif ($type eq "HASH") {
         ($first,@tmp) = _print_hash($val,$depth+1);

      } else {
         ($first,@tmp) = _print_object($val,$depth+1);
      }

      @tmp         = map { "$indentstr$_" } @tmp;
      _append(\@str,$first,@tmp);

      # The last key/val pair won't get a comma
      _append(\@str,',')  if ($i < @keys);
   }

   push(@str,'}');
   return @str;
}

sub _print_scalar {
   my($val) = @_;
   my @str;

   if (! defined $val) {
      @str = ('undef');

   } elsif ($val eq '') {
      @str = ("''");

   } elsif ($val =~ /[,'\s\n]/s) {

      # Trailing newlines are displayed as '\n' only
      if ($val =~ m,(\n*)$,) {
         my $tmp = $1;
         $tmp    =~ s,\n,\\n,g;
         $val    =~ s,\n*$,$tmp,;
      }

      # Intermediate newlines are displayed as '\n' + newline
      $val =~ s,\n,\\n\n,g;

      # Split it into a list of strings
      @str = split(/\n/,$val);

      # Quotes are added. The lines look like:
      # >'LINE1
      # > LINE2
      # > ...
      # > LINEn'
      #
      my $tmp = shift(@str);
      $tmp    = "'$tmp";
      @str    = map { " $_" } @str;
      unshift(@str,$tmp);
      $str[$#str] .= "'";

   } else {
      @str = ($val);
   }

   return @str;
}

sub _append {
   my($listref,@newlist) = @_;

   if (@$listref) {
      $$listref[$#$listref] .= shift(@newlist);
   }
   push (@$listref,@newlist);
}

sub _maxLength {
   my(@list) = @_;
   my $max   = 0;
   foreach my $ele (@list) {
      my $len;
      if (ref($ele)) {
         $len = length(scalar($ele));
      } else {
         $len = length($ele);
      }
      $max = $len  if ($len > $max);
   }
   return $max;
}

sub _duplicates {
   my($val)     = @_;
   my $opt_dupl = _option('duplicates');
   my $ref      = scalar($val);
   return (0)    if (! exists $Refs{$ref}  ||
                     $Refs{$ref}[1] == 1);

   if (exists $Printed{$ref}) {

      if      ($opt_dupl eq 'link') {
         return (1,$Refs{$ref}[0]);

      } elsif ($opt_dupl eq 'reflink') {
         return (1,"$ref " . $Refs{$ref}[0]);

      } elsif ($opt_dupl eq 'ref') {
         return (1,$ref);
      }

   } else {
      $Printed{$ref} = 1;

      if      ($opt_dupl eq 'link'  ||
               $opt_dupl eq 'ref') {
         return (0);

      } elsif ($opt_dupl eq 'reflink') {
         return (0,"$ref ");
      }
   }
}

sub _print_maxdepth {
   my($var) = @_;
   my $opt_maxmeth = _option('max_depth_method');

   if ($opt_maxmeth eq 'ref') {
      return (scalar($var));

   } else {
      return (ref($var));

   }
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
# cperl-label-offset: -2
# End:
