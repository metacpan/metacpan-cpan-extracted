package Data::Fax;

=head1 NAME

Data::Fax - Perl extension for setting up DataFAX object.

=head1 VERSION

This document refers to version 0.01 of Data::Fax released April 25, 
2001.

=head1 SYNOPSIS

  use Data::Fax;
  my $df = Data::Fax->new;   # create an empty object
     $df->debug(1);          # set debug level 
     $df->reset('N');       # change reset to no

  # we can set it up using one line
  my $df = Data::Fax->new('debug', '2', 'reset', 'N');  

  # we can define a hash array for the parameters
  my %param = (     'debug'=>'1',          'reset'=>'N', 
               'df_param'=>$ary_ref), 'ss_param'=>\{});
  my $df = Data::Fax->new(%param); # or
  my $df = new Data::Fax %param;   # or indirect obj call  
  my $df = new Data::Fax (%param); # the same with indirect obj call

  # methods to set/get values
  $df->set_debug(0);        # the same as $df->debug(0);
  $df->get_debug;           # the same as $df->debug;
  $df->set_reset('Y');      # the same as $df->reset('Y'); 
  $df->get_reset;           # the same as $df->reset; 

  # All the methods to get/set scalar value have corresponding
  # methods without 'get_' or 'set_' prefix. So do the following 
  # methods:
  $df->set_FS('\t');        # set field separator
  $df->get_FS;              # get feild separator
  $df->set_OFS('|');        # set output field separator
  $df->get_OFS;             # get output field separator
  $df->set_DirSep('/');     # set directory separator
  $df->get_DirSep;          # get directory separator
  $df->set_first_row('Y');  # indicates the first row is column names
  $df->set_first_row('N');  # first row does not contain column names
  $df->get_first_row;       # get first row indicator
  $df->set_debug(2);        # set msg level to 2
  $df->get_debug;           # get msg level

  # methods to set/get array or hash array are a little different
  $df->set_df_param($fn);   # read from a DataFAX initial file
  $df->set_df_param($arf);  # or set it to a hash array ref
  %ha=$df->get_df_param;    # get the hash array
  $df->df_param;            # get hash array ref
  $df->df_param($key);      # get value of $key from the array
  $df->df_param($key,$val); # set the $key = $val
  # the same for ss_param
  $df->set_ss_param($sn);   # read from DFserver.cf of study number 
  $df->set_ss_param($arf);  # set it to a hash array ref
  %ha=$df->get_ss_param;    # get the hash array
  $df->ss_param;            # get hash array ref
  $df->ss_param($key);      # get value of $key from the array
  $df->ss_param($key,$val); # set the $key = $val

  # some utility methods
  $df->echoMSG($msg, $lvl); # echo message of level $lvl
  $df->disp_param;          # display all internal parameters
  $df->debug;               # debug

=head1 DESCRIPTION

Data::Fax class is intended to be used as parent class for all the
sub-sequent classes with Data::Fax name space.

=head2 Overview

I<Data::Fax> is a class for setting up DataFAX and study specific 
environment and parameters.

=head2 Constructor and initialization

The constructor is I<new>. You can call it directly or indirectly with
or without parameters or parameter hash array. Here are some examples:

  # direct call
  my $df = Data::Fax->new;
  my $df = Data::Fax->new('p1', 'value1', 'p2', 'value2');
  my $df = Data::Fax->new(%p);

  # indirect call
  my $df = new Data::Fax;
  my $df = new Data::Fax ('p1', 'value1', 'p2', 'value2');
  my $df = new Data::Fax (%p);

=cut

require 5.005_62;
use strict;
use vars qw($AUTOLOAD);
use warnings;
use Carp;
# use Data::Fax::Subs qw(:misc);
use Debug::EchoMessage; 

# require Exporter;
# require DynaLoader;
# use AutoLoader;

# our @ISA  = qw(Exporter DynaLoader);
our @ISA;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Fax ':all';
# If you do not need this, moving things directly into @EXPORT or 
# @EXPORT_OK will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	
);
our $VERSION = '0.02';

use Data::Dumper;              # used in debug
# use Data::Subs "read_config";  # used in set_df_param
# use Data::Fax::Subs qw(:common :param_subs echoMSG debug read_config 
#     open_datafile);
# use Data::Fax::JavaScript qw(:common :functions);
# use Data::Subs "prtHashVar";   # used in echoMSG

{  # Encapsulated class data
    my %_attr_data =                           # default accessibility
    ( _ifs         => ['$','read/write', '|'], # field separator
      _ofs         => ['$','read/write', '|'], # output field sparator
      _IFS         => ['$','read/write', '|'], # field separator
      _OFS         => ['$','read/write', '|'], # output field sparator
      _init_file   => ['$','read/write', ''],  # DataFAX.ini file  
      _DirSep      => ['$','read/write', '/'], # directory sparator
      _debug       => ['$','read/write', 0],   # debug level: 0,1,..,N 
      _reset       => ['$','read/write', 'Y'], # reset parameters: Y/N
      _sfr         => ['$','read/write', 0],   # default 1st row no cols
      _SFR         => ['$','read/write', 0],   # default 1st row no cols
      _dfdb_fn     => ['$','read/write',''],   # default to null 
      _df_param    => ['%','read/write',{}],   # ary_ref for df_param
      _sn          => ['$','read/write',0 ],   # active study number
      _ss_param    => ['%','read/write',{}],   # ary_ref for ss_param
      _wb_param    => ['%','read/write',{}],   # ary_ref for wb_param
      _dfdb        => ['%','read/write',{}],   # ary_ref for DFDB
      _dfdb_ss     => ['%','read/write',{}],   # study specific  
    );
    # class methods, to operate on encapsulated class data
    # is a specified object attribute accessible in a given mode
    sub _accessible {
        my ($self, $attr, $mode) = @_;
        # if (!exists $_attr_data{$attr}) { 
        #    print "\$attr = $attr\n"; $self->debug; }
        return $_attr_data{$attr}[1] =~ /$mode/ 
            if exists $_attr_data{$attr};
    }
    # classwide default value for a specified object attributes
    sub _default_for {
        my ($self, $attr) = @_;
        return $_attr_data{$attr}[2] if exists $_attr_data{$attr};
    }
    sub _accs_type {
        my ($self, $attr) = @_;
        return $_attr_data{$attr}[0] if exists $_attr_data{$attr};
    }
    # list of names of all specified object attributes
    sub _standard_keys { keys %_attr_data; }
}

=head2 The Constructor new(%arg)

Without any input, i.e., new(), the constructor generates an empty
object with default values for its parameters.

If any argument is provided, the constructor expects them in
the name and value pairs, i.e., in a hash array.

The constructor also calls the I<set_df_param> method to use an 
initial file for its system parameters and I<set_dfdb> method to
use study database for its study parameters. 

The default initial file is B<DataFAX.ini> located in ~/Fax/DataFax/. 
It can also be set by I<init_file> method. 

=back

=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    # print join "|", $caller,  $caller_is_obj, $class, $self, "\n";
    foreach my $attrname ( $self->_standard_keys() ) {
        my ($argname) = ($attrname =~ /^_(.*)/);
        # print "attrname = $attrname: argname = $argname\n";
        if (exists $arg{$argname}) { 
            $self->{$attrname} = $arg{$argname};
        } elsif ($caller_is_obj) {
            $self->{$attrname} = $caller->{$attrname};
        } else {
            $self->{$attrname} = $self->_default_for($attrname);
        }
        # print $attrname, " = ", $self->{$attrname}, "\n";
    }
    # $self->debug(5); 
    # $self->set_df_param;
    # $self->set_dfdb;
    return $self;
}

sub input_field_sep { my $s = shift; return $s->IFS(@_); }
sub input_field_separator { my $s = shift; return $s->IFS(@_); }

=head2 Class and object methods

The following are the methods and their usages.

=cut

# implement other get_... and set_... method (create as neccessary)
sub AUTOLOAD {
    no strict "refs";
    my ($self, $v1, $v2) = @_;
    (my $sub = $AUTOLOAD) =~ s/.*:://;
    my $m = $sub;
    (my $attr = $sub) =~ s/(get_|set_)//;
        $attr = "_$attr";
    # print join "|", $self, $v1, $v2, $sub, $attr,"\n";
    my $type = $self->_accs_type($attr);
    croak "ERR: No such method: $AUTOLOAD.\n" if !$type;
    my  $v = "";
    my $msg = "WARN: no permission to change";
    if ($type eq '$') {           # scalar method
        $v  = "\n";
        $v .= "    my \$s = shift;\n";
        $v .= "    croak \"ERR: Too many args to $m.\" if \@_ > 1;\n";
        if ($self->_accessible($attr, 'write')) {
            $v .= "    \@_ ? (\$s->{$attr}=shift) : ";
            $v .= "return \$s->{$attr};\n";
        } else {
            $v .= "    \@_ ? (carp \"$msg $m.\n\") : ";
            $v .= "return \$s->{$attr};\n";
        }
    } elsif ($type eq '@') {      # array method
        $v  = "\n";
        $v .= "    my \$s = shift;\n";
        $v .= "    my \$a = \$s->{$attr}; # get array ref\n";
        $v .= "    if (\@_ && (ref(\$_[0]) eq 'ARRAY' ";
        $v .= "|| \$_[0] =~ /.*=ARRAY/)) {\n";
        $v .= "        \$s->{$attr} = shift; return;\n    }\n";
        $v .= "    my \$i;     # array index\n";
        $v .= "    \@_ ? (\$i=shift) : return \$a;\n";
        $v .= "    croak \"ERR: Too many args to $m.\" if \@_ > 1;\n";
        if ($self->_accessible($attr, 'write')) {
            $v .= "    \@_ ? (\${\$a}[\$i]=shift) : ";
            $v .= "return \${\$a}[\$i];\n";
        } else {
            $v .= "    \@_ ? (carp \"$msg $m.\n\") : ";
            $v .= "return \${\$a}[\$i];\n";
        }
    } else {                      # assume hash method: type = '%'
        $v  = "\n";
        $v .= "    my \$s = shift;\n";
        $v .= "    my \$a = \$s->{$attr}; # get hash array ref\n";
        $v .= "    if (\@_ && (ref(\$_[0]) eq 'HASH' ";
        $v .= " || \$_[0] =~ /.*=HASH/)) {\n";
        $v .= "        \$s->{$attr} = shift; return;\n    }\n";
        $v .= "    my \$k;     # hash array key\n";
        $v .= "    \@_ ? (\$k=shift) : return \$a;\n";
        $v .= "    croak \"ERR: Too many args to $m.\" if \@_ > 1;\n";
        if ($self->_accessible($attr, 'write')) {
            $v .= "    \@_ ? (\${\$a}{\$k}=shift) : ";
            $v .= "return \${\$a}{\$k};\n";
        } else {
            $v .= "    \@_ ? (carp \"$msg $m.\n\") : ";
            $v .= "return \${\$a}{\$k};\n";
        }
    }
    $self->echoMSG("sub $m {$v}\n",100);
    *{$sub} = eval "sub {$v}";
    goto &$sub;
}

sub DESTROY {
    my ($self) = @_;
    # clean up base classes
    return if !@ISA;
    foreach my $parent (@ISA) {
        next if $self::DESTROY{$parent}++;
        my $destructor = $parent->can("DESTROY");
        $self->$destructor() if $destructor;
    }
}

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 ENVIRONMENT

Since DataFAX is primarily on Unix and Lynx, this module is only tested
in Unix environment. Other OS environments may tested later.

=head1 DIAGNOSTICS

I will add more document in this section to address diagnostic issues.

=over 4


=back

=head1 BUGS

Please report any bugs to me. 

=head1 AUTHOR

Hanming Tu, hanming_tu@yahoo.com

=head1 SEE ALSO

Debug::EchoMessage.

=head1 COPYRIGHT

Copyright (c) 2005, Hanming Tu. All Rights Reserved.
This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.

=cut

