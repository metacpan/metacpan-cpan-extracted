package Data::Describe;

use strict;
use vars qw($AUTOLOAD);
use Carp;
use warnings;

# require Exporter;

use IO::File;
use File::Basename;
# use Fax::DataFax::DateTime qw(get_date_format);

# This allows declaration       use DataFax ':all';
# If you do not need this, moving things directly into @EXPORT or
# @EXPORT_OK will save memory.
our @ISA;
our %EXPORT_TAGS = ( 'all' => [ qw(describe) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw( );
our $VERSION     = '1.03';

=head1 NAME

Data::Describe - Perl extension for scanning/describing a text file 
or array.

=head1 SYNOPSIS

  use Data::Describe;

  $dsp = Data::Describe->new;       # create an empty object
  my %arg = ( input_file_name => 'input.txt', # the same as 'ifn' 
              skip_first_row  => 'Y',         # the same as 'sfr'
              input_field_sep => ',',         # the same as 'ifs'
              ofs=>'|',             # the same as 'output_field_sep'
              ofn=>'out.dat',       # the same as 'output_file_name'
              odf=>'out.def',       # the same as 'output_def_file'
            );
  $dsp = Data::Describe->new(%arg); # with arguments

  $dsp->skip_first_row;             # i,e. 1st row contains col names
  $dsp->set_sfr(1);                 # is the same as the above       

  $dsp->set_ifs('\t');              # set input field separator to tab
  $dsp->input_field_separator('|'); # set input field separator to '|'
  $dsp->set_ofs('|');               # set output field separator to |
  $dsp->output_field_separator('|');# set output field separator to | 

  $dsp->set_ifn('input.txt');       # set input file name
  $dsp->input_file_name('input.txt'); # set input file name
  $dsp->input_file_name($arf);      # it can be array ref

  $dsp->set_ofn('out.dat');         # set output file name
  $dsp->output_file_name('out.dat');# set output file name
  $dsp->output_file_name('Y');      # it can be array ref

  $dsp->set_odf('out.def');         # set output def file name
  $dsp->output_def_file('output.def');# set output definition file name
  $dsp->output_def_file('Y');       # default to '${in}.def" 

  # all the set method has its corresponding get method
  $rc      = $dsp->get_sfr;
  $rc      = $dsp->get_ifs; 
  $rc      = $dsp->input_field_separator; # the same as get_ifs

  $dsp->debug(5);                   # set debug level to 5
  $dsp->echoMSG('This message', 1); # tag the message as level 1
  my $crf = $dsp->get_def_arrayref;
  my $drf = $dsp->get_dat_arrayref;
  $dsp->output($crf, "", 'def');    # output def file to STDOUT
  $dsp->outptu($drf, 'out.dat', 'dat'); 

=head1 DESCRIPTION

This class contains a describe method that scans through each records 
or number of records sepcified and fields in those records in the
array or a file to collect information about the content in the 
array or the file. It creates a column definition array and a data
array containing all the data without the column record. 

The column definition array built by the module is actually an array
with hash members. It contains these hash elements ('col', 'typ', 
'max', 'min', 'dec', 'req' and 'dsp') for each column. The subscripts 
in the array are in the format of $ary[$col_seq]{$hash_ele}. The hash 
elements are:

  col - column name
  typ - column type, 'N' for numeric, 'C' for characters, 
        and 'D' for date
  max - maximum length of the records in the column
        (could use 'wid' to record the max length of the 
         records.)
  min - minimum length of the record in the column
        (When 'wid' is used, no 'min' is needed.)
  dft - date format such as YYYY/MM/DD, MON/DD/YYYY, etc.
  dec - maximun decimal length of the record in the column
  req - whether there is null or zero length records in the 
        column only 'NOT NULL is shown
  dsp - description of the columns

The array or records passed to the module can have the first row 
containing column names. 

=cut

# bootstrap Data::Describe $VERSION;

{  # Encapsulated class data
    my %_attr_data =                        # default accessibility
    ( # method          => ['type', 'access', 'default value']
      # method type:    $ - scalar method
      #                 % - array ref method
      # method access:  R - read access
      #                 W - write access
      # method default: undef - undefined initially, but r
      #                         equired at runtime
      _ifn              => ['$','R/W',undef],  # input file name
      _sfr              => ['$','R/W',1],      # skip first row: yes 
      _ifs              => ['$','R/W','|'],    # input field separator
      _ofs              => ['$','R/W','|'],    # output field separator
      _ofn              => ['$','R/W',''],     # output file name
      _odf              => ['$','R/W',''],     # output def file name
      _def_arrayref     => ['$','R',''],       # column def array ref
      _dat_arrayref     => ['$','R',''],       # data array ref
    );
    # class methods, to operate on encapsulated class data
    # is a specified object attribute accessible in a given mode
    sub _accessible {
        my ($self, $attr, $mode) = @_;
        my $c = substr($mode, 0, 1);
        my $m = $_attr_data{$attr}[1]; $m =~ s /\//\|/g;
        # print "$mode, $c, $m\n"; 
        return $c =~ /($m)/i if exists $_attr_data{$attr};
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

=head1 METHODS

This class contains many methods to "set" and/or "get" parameters.
Here is the list of methods:

=over 4

=item * the constructor new(%arg)

Without any input, i.e., new(), the constructor generates an empty 
object. If any argument is provided, the constructor expects them in
the right order. 

=back

=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    # populate the references to hash or even overwrite them 
    # if they are defined in the input hash
    foreach my $attrname ( $self->_standard_keys() ) {
        my ($argname) = ($attrname =~ /^_(.*)/);
        if (exists $arg{$argname}) { 
            $self->{$attrname} = $arg{$argname};
        } elsif ($caller_is_obj) {
            $self->{$attrname} = $caller->{$attrname};
        } else {
            $self->{$attrname} = $self->_default_for($attrname);
        }
    }
    my $als='input_file_name,input_field_sep,input_field_separator';
    $als .= ',output_field_sep,output_field_separator,';
    $als .= 'output_def_file,output_definition_file,set_dfn,';
    $als .= 'definition_file_name,skip_first_row,debug';
    foreach my $a ( split /,/, $als ) {
        if (exists $arg{$a} && $self->can($a)) { 
           $self->$a($arg{$a}); 
        }
    }
 
    # my $i = "";
    # foreach $i (sort keys %arg) { print "$i=$arg{$i}\n"; }
    # foreach $i (sort keys %{$self}) { print "$i=${$self}{$i}\n"; }
    return $self;
}

# destructor adjusts class count
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

=over 4

=item * [set|get]_sfr/skip_first_row(1)

This method tells whether the first row in the array or a file
containing column names. If it is true, the describe method will skip
it. The get method allows you to query current condition. 
The default is false.

=back 

=cut

sub skip_first_row {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_sfr}=shift) : return $s->{_sfr};
}

=over 4

=item * [set|get]_ifs/input_field_sep/input_field_separator

This method sets/gets input field separator. The default separator is
vertical bar ('|').

=back

=cut

sub input_field_sep {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_ifs}=shift) : return $s->{_ifs};
}

sub input_field_separator {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_ifs}=shift) : return $s->{_ifs};
}

=over 4

=item * [set|get]_ofs/output_field_sep/output_field_separator 

This method sets/gets output field separator. The default separator 
is a vertical bar ('|').   

=back

=cut

sub output_field_sep {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_ofs}=shift) : return $s->{_ofs};
}

sub output_field_separator {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_ofs}=shift) : return $s->{_ofs};
}

=over 4

=item * [set|get]_ifn/input_file_name 

This method sets/gets input file name. It can also be an array 
reference to a two-dimension array. 
If it contains an array ref, an array will be scanned and described
instead of a text file.

=back

=cut
 
sub input_file_name {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_ifn}=shift) : return $s->{_ifn};
}

=over 4

=item * [set|get]_ofn/output_file_name 

This method sets/gets output file file name. It defaults to undef.
It can be a 'Y', then the output file name will be defaulted to 
'dsbf.dat' or the same as input file name with extension as '.dat'.

=back

=cut
 
sub output_file_name {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_ofn}=shift) : return $s->{_ofn};
}

=over 4

=item * [set|get]_odf/output_def_file 

This method sets/gets output file name for column definition. 
It defaults to undef. It can be 'Y', then the file name will be 
defaulted to the same as input file name with extension as '.def'; 
if the input is an array, then it defaults to 'dsbf.def'.

=back

=cut
 
sub output_def_file {
    my $s = shift;
    croak "ERR: Too many args to input_file_name." if @_ > 1;
    @_ ? ($s->{_odf}=shift) : return $s->{_odf};
}

sub output_definition_file { 
    my $s = shift; return $s->output_def_file(@_);
}

sub definition_file_name { 
    my $s = shift; return $s->output_def_file(@_);
}

sub set_dfn { 
    my $s = shift; return $s->output_def_file(@_);
}

sub get_dfn { 
    my $s = shift; return $s->output_def_file(@_);
}

=over 4

=item * get_def_arrayref  

This method gets the reference pointing to the column definition array.
The column definition array contains column name, column type, 
column max length, column min length, column decimal length, and 
column constraints. 

=item * get_dat_arrayref  

This method gets data array reference. 
It does not change the internal attributes defined for
the object, so you can pass any data array reference to this method
without touching the internal attributes in the object. Actually, all
the I<get> methods do not change anything in the object. 

=back

=cut

# implement other get_... and set_... method (create as neccessary)
sub AUTOLOAD {
    no strict "refs";
    my ($self, $v1, $v2) = @_;
    (my $sub = $AUTOLOAD) =~ s/.*:://;
    my $m = $sub;
    (my $attr = $sub) =~ s/^(get|set)//;
        $attr = "$attr";
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

=over 4

=item * describe($inf,$def,$out,$sfr,$ifs,$ofs,$nrc,$owt,$chr)

=over 8

=item * Input variables:

  $inf - input file name, full path to a ASCII file
  $def - output file name for column definitions,
         default to "*.def" while $def = undef or 'Y'
  $out - output file name for data,
         default to "*.dat" while $out = 'Y'
  $sfr - skip first row, i.e., the first row contains
         column names
  $ifs - input field separator, default is '|'
  $ofs - output field separator, default is '|'
  $nrc - first number of lines to be read,
         default is to read all
  $owt - overwrite existing files, default to 'N'
  $chr - quote characters to be removed.

=item * Variables used or routines called:

  echoMSG - print debug messages

=item * How to use:

  use Data::Describe;
  my $dsb= Data::Describe->new;
  my ($crf,$drf) = $dsp->describe($inf,'Y','',$sfr);

=item * Return: none. 

You can get the output through method I<get_def_arrayref> and
I<get_dat_arrayref>, or specify output file names and call
I<output> method.

=back

This routine reads in a text file, search its content and create
column definitons. The $crf contains the column definiton, i.e.,
${$crf}[$j]{$itm}, where $j is column sequence and $itm includes:
'col', 'typ', 'wid', 'dec', 'dft', 'dsp', etc.

The $drf contains the data, ${$drf}[$i][$j], where $i is record
number and $j is column name. The first row contains
column names. The rest rows are data.

=back

=cut

sub describe {
    my $self     = shift;
    my ($inf,$def,$out,$sfr,$ifs,$ofs,$nrc,$owt,$chr) = @_;
    $inf = $self->get_ifn if !$inf;
    croak "ERR: no input file/array is specified.\n" if !$inf;
    $self->echoMSG("  - describing $inf...");
    $sfr = $self->get_sfr   if !$sfr; 
    $sfr = 'N' if !$sfr;    # default skip first row to 'N'
    $ifs = $self->get_ifs   if !$ifs;
    $ifs = '\|' if !$ifs;   # default input field sep to '|'
    $ofs = $self->get_ofs   if !$ofs; 
    $ofs = '\|' if !$ofs;   # default output field sep to '|'
    $nrc = 0   if !$nrc;    # default sample records to 0 (all)
    # $dfs = '/' if !$dfs;  # default dir separator to '/'
    $owt = 'N' if !$owt;    # default overwrite to 'N'
    $chr = '"' if !$chr;    # default quote character to '"'
    my ($fhi, @data); 
    if ($inf =~ /ARRAY/) {
        @data = @{$inf};
    } else { 
        croak "ERR: input file does not exist.\n"  if (!-f $inf);
        $fhi = new IO::File "<$inf";   # input file handler
        croak "ERR: could not open file - $inf.\n" if (!defined($fhi));
        @data = <$fhi>;
        undef $fhi;
    }
    #
    # read the data and process it
    my(@a, @b, $j, $n, $c, $v, $msg);
    my @A=();         # store field definition information
    my @D=();         # store possible date field information
    my $max_nf = 0;   # max number of fields
    my $i = -1;
    my $drf = bless [], ref($self)||$self;
    foreach (@data) {
        # skip empty and comment lines
        next if (!$_ || $_ =~ /^\s+$/ || $_ =~ /^#/);
        ++$i; chomp;
        @a = split /$ifs/, $_, 99999;
        $max_nf = ($#a+1>$max_nf)? $#a+1 : $max_nf;
        if ($chr) {
            for $j (0..$#a) { next if !$a[$j];
                $a[$j] =~ s/^\s*//;   # remove leading spaces
                $a[$j] =~ s/\s*$//;   # remove trailing spaces
                $a[$j] =~ s/^($chr)*//;  # remove leading quote char
                $a[$j] =~ s/($chr)*?$//;  # remove trailing quote char
            }
        }
        if ($i==0) {             # define column names
            if ($sfr =~ /^Y$/i || $sfr == 1) {
                # get column names from the first row
                for $j (0..$#a) {
                    if (!$a[$j] || $a[$j] =~ /^\s*$/) {
                        $A[$j]{'col'} = sprintf "FLD%03d", $j+1;
                    } else      {
                        $A[$j]{'col'} = $a[$j];
                    }
                }
                next;            # skip the first column
            } else {             # generate seq column names
                for $j (0..$#a) {
                    $A[$j]{'col'} = sprintf "FLD%03d", $j+1;
                }
            }
            for $j (0..$#A) {
                ${$drf}[0][$j] = $A[$j]{col};
            }
        }
        push(@{$drf}, [@a]);
        for $j (0..$#a) {     # loop thru fields
            $v = $a[$j];         # value in the field
            if (!defined($A[$j]{'max'})) { $A[$j]{'max'} = -1; }
            if (!defined($A[$j]{'min'})) { $A[$j]{'min'} = 9999999; }
            if (!defined($A[$j]{'typ'})) { $A[$j]{'typ'} = ""; }
            if (!defined($A[$j]{'dft'})) { $A[$j]{'dft'} = ""; }
            if (!defined($A[$j]{'dsp'})) { $A[$j]{'dft'} = ""; }
            if (!defined($A[$j]{'dec'})) { $A[$j]{'dec'} = 0; }
            if ($A[$j]{'max'}<length($v)){ $A[$j]{'max'}=length($v); }
            if ($A[$j]{'min'}>length($v)){ $A[$j]{'min'}=length($v); }
            if (!$A[$j]{'typ'} || $A[$j]{'typ'} ne 'C') {
                if ($v =~ /^-?[\d\.]*$/) {     # it is numerical
                    $A[$j]{'typ'} = 'N';
                } elsif ($v =~ /^[\d \/\.]*$/ ) {   # it is date?
                    $A[$j]{'typ'} = 'D';
                    @b = split /\//, $v;
                    # first date field
                    if (!defined($D[$j][1]{min})) {
                        $D[$j][1]{min} = 999999;
                    }
                    # if (!exists $D[$j][1]{min}) {
                    #     $D[$j][1]{min} = 999999;
                    # }
                    if (!defined($D[$j][1]{max})) {
                    # if (!exists $D[$j][1]{max}) {
                        $D[$j][1]{max} = -1;
                    }
                    $D[$j][1]{min} = ($D[$j][1]{min}>$b[0]) ? $b[0] :
                         $D[$j][1]{min};
                    $D[$j][1]{max} = ($D[$j][1]{max}<$b[0]) ? $b[0] :
                         $D[$j][1]{max};
                     # second date field
                    if (!exists $D[$j][2]{min}) {
                 
                        $D[$j][2]{min} = 999999;
                    }
                    if (!exists $D[$j][2]{max}) {
                        $D[$j][2]{max} = -1;
                    }
                    $D[$j][2]{min} = ($D[$j][2]{min}>$b[0]) ? $b[1] :
                         $D[$j][2]{min};
                    $D[$j][2]{max} = ($D[$j][2]{max}<$b[0]) ? $b[1] :
                         $D[$j][2]{max};
                     # third date field
                    if (!exists $D[$j][3]{min}) {
                        $D[$j][3]{min} = 999999;
                    }
                    if (!exists $D[$j][3]{max}) {
                        $D[$j][3]{max} = -1;
                    }
                    $D[$j][3]{min} = ($D[$j][3]{min}>$b[0]) ? $b[2] :
                         $D[$j][3]{min};
                    $D[$j][3]{max} = ($D[$j][3]{max}<$b[0]) ? $b[2] :
                         $D[$j][3]{max};
                } else {
                    $A[$j]{'typ'} = 'C';
                }
            }
            if ($A[$j]{'typ'} eq 'N') {   # it is numeric
                if (!defined($A[$j]{'dec'})) { $A[$j]{'dec'} = 0; }
                @b = split /\./, $v;
                if (!defined($b[1])) { $b[1] = ""; } # so no warning
                if ($A[$j]{'dec'}<length($b[1])) {   # max decimal
                    $A[$j]{'dec'} = length($b[1]);   # length
                }
            }
        }   # end of for $j (...)
    }   # end of while(<$fhi>)
    my $tot = $i;  if ($sfr !~ /^Y$/i) { $tot = $i+1; }
    my $tcn = $#A+1;
    my ($mx1, $mx2, $mx3, $mn1, $mn2, $mn3);
    for $i (0..$#A) {
        if ($A[$i]{'min'}>0) { $A[$i]{'req'} = 'NOT NULL';
        } else {               $A[$i]{'req'} = "" }
        $A[$i]{'col'} =~ s/^\s*//;      # trim leading spaces
        $A[$i]{'col'} =~ s/\s*$//;      # trim ending spaces
        $A[$i]{'dsp'} = $A[$i]{'col'};
        $A[$i]{'col'} =~ s/[ \/]/_/ig;  # convert space and / to _
        # determine date format
        if ($A[$i]{typ} =~ /^D/i) {
            $mn1 = $D[$i][1]{min}; $mx1 = $D[$i][1]{max};
            $mn2 = $D[$i][2]{min}; $mx2 = $D[$i][2]{max};
            $mn3 = $D[$i][3]{min}; $mx3 = $D[$i][3]{max};
            $A[$i]{dft} = $self->get_date_format("$mn1:$mx1",
                 "$mn2:$mx2", "$mn3:$mx3");
        }
    }
    for $j (0..$max_nf) {
        next if ($A[$j]{'col'});
        if (!$A[$j]{'typ'}) { splice(@A, $j, 1); next; }
        $A[$j]{'col'} = sprintf "FLD%03d", $j+1;
    }
    $self->{_def_arrayref} = \@A;
    $self->{_dat_arrayref} = $drf; 
    $self->echoMSG("      Total records processed: $tot",2);
    $self->echoMSG("      Total columns created: $tcn",2);
}

=over 4

=item * output($arf,$out,$otp,$ifn,$ofs,$owt)

=over 8

=item * Input variables:

  $arf - array ref
  $out - output file name
  $otp - output type: data or definition
  $ifn - input file name as name reference
  $ofs - output field separator
  $owr - whether to overwrite existing file

=item * Variables used or routines called: 

  get_def_arrayref - get column definition array reference
  get_dat_arrayref - get data array reference
  get_odf - get definition output file name
  get_ofn - get data output file name 
  get_ofs - get output field separator
  get_ifn - get input file name
  fileparse - parse file name 

=item * How to use:

  my $crf = $self->get_def_arrayref;
  # output $crf to standard output device - STDOUT
  $self->output($crf, "", 'def');  
  my $drf = $self->get_dat_arrayref;
  # output $drf to 'out.dat'
  $self->output($drf, "out.dat", 'dat'); 

=item * Return: None. 

=back

=back

=cut

sub output {
    my $self = shift;
    my ($arf, $out, $otp, $ifn, $ofs, $owt) = @_;
    # Input variables:
    #   $arf - array ref
    #   $out - output file name
    #   $otp - output type: data or definition
    #   $ifn - input file name as name reference
    #   $ofs - output field separator
    #   $owr - whether to overwrite existing file
    #
    $self->echoMSG('WARN: nothing to be outputed') if (!$arf && !$otp);
    $otp = 'def' if !$otp;
    if ($otp =~ /^def/i) {            # column definition array ref
        $arf = $self->get_def_arrayref if !$arf;
        $out = $self->get_odf          if !$out;
    } else {
        $arf = $self->get_dat_arrayref if !$arf;
        $out = $self->get_ofn          if !$out;
    }
    $self->echoMSG('WARN: no input array defined') if !$arf;
    return if !$arf;
    $owt = 'N' if !$owt; 
    $ofs = $self->get_ofs if !$ofs;
    #
    # let's determine output file name
    $ifn = $self->get_ifn if !$ifn;
    my $ds = '/'; 
    $ifn = 'dsbf.dat' if !$ifn;
    my ($bnm,$dir,$type)=fileparse($ifn,'\.\w+$');
    my $fho = ""; 
    if (!$out) {
        $fho = *STDOUT;
    } elsif ($out =~ /^Y/i) {
        if ($otp =~ /^def/i) {    
            $out =  "$dir${bnm}.def";
        } else {
            $out =  "$dir${bnm}.dat";
        }
        $self->echoMSG("  - outputing to $out..."); 
        if ($owt eq 'Y' && $out && -f $out) { unlink $out; }
        carp "WARN: file - $out exist.\n" if -f $out;
        $fho = new IO::File ">$out";   # output file hanlder
        croak "ERR: could not write to $out.\n" if (!defined($fho));
    }

    if ($otp =~ /^def/i) {    
        # ColName|ColType|ColWidth|ColRequirement|DateFmt|ColLabel
        my ($t1, $t2, $t3); 
        $t1  = "# Input  file name: $ifn\n" if $ifn;
        $t1  = "# Input  file name: $arf\n" if !$ifn;
        $t1 .= "# Output file name: $out\n";
        $t1 .= "# Created at " . (scalar localtime) . "\n";
        $t1 .= "# Created by Data::Describe::output\n#";
        $t2  = "# ColName|ColType|ColWidth|ColRequirement|DateFmt|";
        $t2 .= "ColLabel";
        my ($rec,$wid,$dsp,$typ);
        print $fho "$t1\n$t2\n";
        for my $i (0..$#{$arf}) {
            $wid = 0; $typ = ${$arf}[$i]{'typ'};
            if (${$arf}[$i]{'wid'}) { $wid = ${$arf}[$i]{'wid'};
            } else { $wid = ${$arf}[$i]{'max'}; }
            if ($typ eq 'N') { $wid = "$wid.${$arf}[$i]{'dec'}"; }
            if (!defined(${$arf}[$i]{'dsp'})) {
                ${$arf}[$i]{'dsp'} = "";
            } else { $dsp = ${$arf}[$i]{'dsp'}; }
            $rec = join $ofs, ${$arf}[$i]{'col'},$typ,
                $wid,${$arf}[$i]{'req'},${$arf}[$i]{'dft'}, $dsp;
            print $fho "$rec\n";
        }
    } else {
        foreach (@{$arf}) {
            print $fho (join $ofs, @{$_}) . "\n";
        }
    }
    undef $fho;
}

=over 4

=item * debug($n)

=over 8

=item * Input variables:

  $n   - a number between 0 and 100. It specifies the
         level of messages that you would like to
         display. The higher the number, the more
         detailed messages that you will get.

=item * Variables used or routines called: None.

=item * How to use:

  $self->debug(2);     # set the message level to 2
  print $self->debug;  # print current message level

=item * Return: the debug level or set the debug level.

=back

=back

=cut

sub debug {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $s =  ref($_[0])?shift:(bless {}, $c_pkg);
    my $s =  shift;
    croak "ERR: Too many args to debug." if @_ > 1;
    @_ ? ($s->{_debug}=shift) : return $s->{_debug};
}

=over 4

=item * echoMSG($msg, $lvl, $yn)

=over 8

=item * Input variables:

  $msg - the message to be displayed. No newline
         is needed in the end of the message. It
         will add the newline code at the end of
         the message.
  $lvl - the message level is assigned to the message.
         If it is higher than the debug level, then
         the message will not be displayed.
  $yn  - whether to return the message

=item * Variables used or routines called:

  debug - get debug level.

=item * How to use:

  # default msg level to 0
  $self->echoMSG('This is a test");
  # set the msg level to 2
  $self->echoMSG('This is a test", 2);

=item * Return: None.

=back 

This method will display message or a hash array based on I<debug>
level. If I<debug> is set to '0', no message or array will be
displayed. If I<debug> is set to '2', it will only display the message
level ($lvl) is less than or equal to '2'. If you call this
method without providing a message level, the message level ($lvl) is
default to '0'.  Of course, if no message is provided to the method,
it will be quietly returned.

This is how you can call I<echoMSG>:

  my $df = Data::Describe->new;
     $df->echoMSG("This is a test");   # default the msg to level 0
     $df->echoMSG("This is a test",1); # assign the msg as level 1 msg
     $df->echoMSG("Test again",2);     # assign the msg as level 2 msg
     $df->echoMSG($hrf,1);             # assign $hrf as level 1 msg
     $df->echoMSG($hrf,2);             # assign $hrf as level 2 msg

If I<debug> is set to '1', all the messages with default message levels
0 and 1 will be displayed. The higher level messages
will not be displayed.

=back

=cut

sub echoMSG {
    my $self = shift;
    my ($msg,$lvl,$yn) = @_;
    if (!defined($msg)) { return; }      # return if no msg
    if (!defined($lvl)) { $lvl = 0; }    # default level to 0
    return $msg if $yn;
    my $class = ref($self)||$self;       # get class name
    my $dbg = $self->debug;              # get debug level
    if (!$dbg) { return; }               # return if not debug
    my $ref = ref($msg);
    return if ($lvl > $dbg );
    if ($ref eq $class) {                # an array? 
        # $self->disp_param($msg);
    } else { print "$msg\n"; }
}

=over 4

=item *  get_date_format($r1, $r2, $r3, $ds)

Input variables:

  $r1 - date range 1: 'min:max'
  $r2 - date range 2: 'min:max'
  $r3 - date range 3: 'min:max'
  $ds - date separator

Variables used or routines called:

  None.

How to use:

  # the $dft = 'MM/DD/YY'
  my $dft = $self->get_date_format('1:12','1:31','1:2');
  # the $dft = 'MM/DD/YYYY'
     $dft = $self->get_date_format('1:12','1:31','0:2002');

Return: the date format.

=back

=cut

sub get_date_format {
    my $self = shift;
    my ($r1, $r2, $r3, $ds) = @_;
    # Input variables:
    #   $r1 - date range 1: 'min:max'
    #   $r2 - date range 2: 'min:max'
    #   $r3 - date range 3: 'min:max'
    #   $ds - date separator
    #
    my ($mn1, $mx1) = split /:/, $r1;
    my ($mn2, $mx2) = split /:/, $r2;
    my ($mn3, $mx3) = split /:/, $r3;
    $ds = '/' if !$ds;
    my ($msg, $dft, $d1, $d2, $d3) = ("", "", "", "", "");
    if (($mn1>31 && $mx1<=99) || ($mn1>99 && $mx1<10000)) {
        # 1st fd is YY or YYYY
        if ($mn1>31 && $mx1<=99) {      # 1st fd is YY
            $d1 = 'YY';
        } else { $d1 = 'YYYY'; }        # 1st fd is YYYY
        if ($mn2>=1 && $mx2<=12) {      # 2nd fd is MM
            $d2 = 'MM';
        } elsif ($mn2>=1 && $mx2<=31) { # 2nd fd is DD
            $d2 = 'DD';
        }
        if ($d1 eq 'MM' && $mn3>=1 && $mx3<=12) {  # 3rd fd is DD
            $d3 = 'DD';
        } elsif ($mn3>=1 && $mx3<=12) { # 3rd fd is MM
            $d3 = 'MM';
        } elsif ($mn3>=1 && $mx3<=31) {  # 3rd fd is DD
            $d3 = 'DD';
        }
    } elsif ($mn1>=1 && $mx1<=12) {     # 1st fd is MM
        $d1 = 'MM';
        if ($mx2>31 && $mx2<=99) {          # 2nd fd is YY
            $d2 = 'YY';
        } elsif ($mx2>99 && $mx2<10000) {   # 2nd fd is YYYY
            $d2 = 'YY';
        } elsif ($mn2>=1 && $mx2<=31) {     # 2nd fd is DD
            $d2 = 'DD';
        }
        if ($d2 eq 'DD' && $mx3<=99) {      # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mn3>31 && $mx3<=99) {     # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mn3>99 && $mx3<10000) {   # 3nd fd is YYYY
            $d3 = 'YYYY';
        } elsif ($mn3>=1 && $mx3<=31) {     # 3nd fd is DD
            $d3 = 'DD';
        }
    } elsif ($mn1>=1 && $mx1<=31) {     # 1st fd is DD
        $d1 = 'DD';
        if ($mx2>31 && $mx2<=99) {          # 2nd fd is YY
            $d2 = 'YY';
        } elsif ($mx2>99 && $mx2<10000) {   # 2nd fd is YYYY
            $d2 = 'YY';
        } elsif ($mn2>=1 && $mx2<=12) {     # 2nd fd is MM
            $d2 = 'MM';
        }
        if ($d2 eq 'MM' && $mx3<=99) {      # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mx3>31 && $mx3<=99) {     # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mx3>99 && $mx3<10000) {   # 3nd fd is YYYY
            $d3 = 'YYYY';
        } elsif ($mn3>=1 && $mx3<=12) {     # 3nd fd is MM
            $d3 = 'MM';
        }
    } else {                                # 1st fd is YY (32~99)?
        $d1 = 'YY';
        if ($mn2>=1 && $mx2<=12) {      # 2nd fd is MM
            $d2 = 'MM';
        } elsif ($mn2>=1 && $mx2<=31) { # 2nd fd is DD
            $d2 = 'DD';
        }
        if ($d1 eq 'MM' && $mn3>=1 && $mx3<=12) {  # 3rd fd is DD
            $d3 = 'DD';
        } elsif ($mn3>=1 && $mx3<=12) { # 3rd fd is MM
            $d3 = 'MM';
        } elsif ($mn3>=1 && $mx3<=31) {  # 3rd fd is DD
            $d3 = 'DD';
        }
    }
    if ($d1 && $d2 && $d3 && ($d1 ne $d2) && ($d2 ne $d3)) {
        $dft = join $ds, $d1, $d2, $d3;
    } else {
        $msg = "illegal date: $d1($r1), $d2($r2), $d3($r3)";
    }
    return ($dft) ? $dft : $msg;
}

1;   # ensure that the module can be successfully used.

__END__

=head1 FAQ

=head2 How to create a describe object? 

You can create a describe object as the following:

  $dsc = Data::Describe->new;   # an empty object
 
You can set a hash to define your object attributes and create it as 
the following:

  %attr = ( 
     input_field_sep => ':',    # output field separator
     skip_first_row' => 1,      # 1st row has col names
    );
  $dsp = Data::Describe->new(%attr);

=head2 How is the column definition generated?

If the first row in the data array contains column names, it uses the
column names in the row to define the column definition array. The 
column type is determined by searching all the records in the data 
array. If all the records in the column only contain digits,
i.e., only [0-9.], the column is defined as numeric ('N'); otherwise,
it is defined as character ('C'). In type 'C', it checks whether the
string is a date type. If the field only contains digits and '/', 
then it consider the field as a date field. It calls to 
I<get_date_foramt> to determine the date format.

If the first row does not contain column names, it  
will generate field names as "FLD###". The "###" is a sequential number
starting with 1. If the minimum length of a column is zero, then the
value in the column can be null; if the minimum length is greater than
zero, then it is a required column.

The default indicator for the first row is false, i.e., the first row
does not contain column names. You can indicate whether the first row 
in the data array is column names by using I<skip_first_row> 
or I<set_sfr> to set it.

  $dsp->skip_first_row('Y');      # first row contains column names
  $dsp->set_sfr('Y');             # the same as the above
  $dsp->set_sfr(1);               # the same as the above

To reverse it, here is how to

  $dsp->set_sfr('N');             # no column in the first row
  $dsp->skip_first_row(0);        # the same as the above


=head2 Future Implementation

Although it seems a simple task, it requires a lot of thinking to get
it working in an object-oriented frame. Intented future implementation
includes 

=over 4

=item * add a sampling function 

Instead of scanning all the records, just randomly sample portion of
the records. It can be specified as percentage or number of records.

=item * add a statistic function 

This function will help to analyze the quality of the data. 

=item * any more function? 

The column definition array will be used in other classes to 
generate control file and sql*loader codes for uploading the data 
into Oracle. The class I temporarily name it I<Data::Loader>. It 
may be changed based on the name approval from PAUSE.

You are welcome to give me suggestions.

=back

=head1 AUTHOR

Hanming Tu, hanming_tu@yahoo.com

=head1 CODING HISTORY

=over 4

=item * Version 1.03: 11/06/2002 - fixed a bug in I<output> method with
fileparse(): need a valid pathname.

=item * Version 1.02: 11/03/2002 - add Makefile.PL to include
required classes for testing. 

=item * Version 1.01: 10/30/2002 - ported I<get_date_format> from 
B<Fax::DataFax::DateTime>.

=item * Version 1.00: 10/26/2002 - Ported to this class

I ported from the initial class and just keep the describing/scanning
capability in this class.. 

=item * Version 0.01: 06/10/1999 - Initial coding

This is part of initial class I<Data::Display>. I coded a while ago -
probably in 1999. 

=back

=head1 SEE ALSO (some of docs that I check often)

perltoot(1), perlobj(1), perlbot(1), perlsub(1), perldata(1),
perlsub(1), perlmod(1), perlmodlib(1), perlref(1), perlreftut(1).

=cut

