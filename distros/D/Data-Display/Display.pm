package Data::Display;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD %EXPORT_TAGS);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
@EXPORT_OK = qw(set_cols_ref set_data_ref get_dimension set_col_width
    mod_col_def disp_col_defs add_col_def get_format_string
    get_col_width get_column_defs_arrayref get_column_defs get_content
);
%EXPORT_TAGS = (
  all => [@EXPORT_OK]
);

$VERSION = '0.02';

# bootstrap Data::Display $VERSION;

use Carp;

{  # Encapsulated class data
    my %_attr_data =                           # default accessibility
    ( _field_sep   => ['?','read/write', ' '], # field separator
      _first_row   => [1,  'read/write', 0],   # default 1st row no cols
      _data_ref    => ['?','read/write',\[]],  # ary_ref for data
      _cols_ref    => ['?','read/write',\[]],  # ary_ref for cols
      __fmt_ref    => ['?','read/write',\[]],  # format array
      _col_width   => ['?','read/write', 1],   # set col width
      _skip_first_row => [1,'read', 0],        # default 1st row no cols
      _no_of_fields   => [1,'read', 0],        # no of fields/columns
      _no_of_columns  => [1,'read', 0],        # no of fields/columns
      _no_of_rows     => [1,'read', 0],        # no of records/rows
      _no_of_records  => [1,'read', 0],        # no of records/rows
    );
    # my $_count = 0;
  # class methods, to operate on encapsulated class data
    # is a specified object attribute accessible in a given mode
    sub _accessible {
        my ($self, $attr, $mode) = @_;
        $_attr_data{$attr}[1] =~ /$mode/
    }
    # classwide default value for a specified object attributes
    sub _default_for {
        my ($self, $attr) = @_;
        $_attr_data{$attr}[2];
    }
    # list of names of all specified object attributes
    sub _standard_keys { keys %_attr_data; }
}

# Counstructor may be called as a class method
# (in which case it uses the class's default values),
# or an object method
# (in which case it gets defaults from the existing object)
sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my $data_ref      = shift if (ref($_[0]) eq 'ARRAY'); # first input 
    my $cols_ref      = shift if (ref($_[0]) eq 'ARRAY'); # second input
    my %arg           = @_;   # convert rest of inputs into hash array
    # populate the references to hash or even overwrite them 
    # if they are defined in the input hash
    $arg{'data_ref'}  = $data_ref;  
    $arg{'cols_ref'}  = $cols_ref;  
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
    # my $i = "";
    # foreach $i (sort keys %arg) { print "$i=$arg{$i}\n"; }
    # foreach $i (sort keys %{$self}) { print "$i=${$self}{$i}\n"; }
    return $self;
}

# destructor adjusts class count
sub DESTROY {  }

sub _chkArrays {
    my($self, $arf, $crf) = @_;
    my $class = ref($self) || $self;

    # print "___$#{$arf}:$#{$crf}:", $self->get_first_row, "\n";
    # check whether the data array contains any records
    if ($#{$arf} < 1) {       # if no element in the array
        my $module = $self; $module =~ s/(=.*)//; 
        my $msg  = "No data ref specified or set.\n";
           $msg .= "Run $module->set_data_ref(\$ary_ref).";
        croak "$msg";
    }
    if ($#{${$arf}[0]}==$#{$crf} && $#{$crf}>0) {
        # If number of columns in $arf equals to number of columns in
        # $crf, then
        # we already have column definition stored and let's return it
        return @{$crf};
    }
}

sub set_cols_ref {
    $_[0]->{'_cols_ref'} = $_[1];  # set col array ref
    # set format array ref to the new
    $_[0]->_set_fmt_ref($_[1]);
    return ;
}

sub set_data_ref {
    $_[0]->{'_data_ref'} = $_[1];  # set col array ref
    # set dimensions of the array
    $_[0]->{'_no_of_rows'}    = $#{$_[1]};
    $_[0]->{'_no_of_records'} = $#{$_[1]};
    $_[0]->{'_no_of_fields'}  = $#{${$_[1]}[0]};
    $_[0]->{'_no_of_columns'} = $#{${$_[1]}[0]};
    return ;
}

sub get_dimension {
    my $self = shift; 
    my $ary_ref = "";
       $ary_ref = shift if ref($_[0]) eq 'ARRAY'; 
       $ary_ref = $self->get_data_ref if (!$ary_ref);
    return ($#{$ary_ref}, $#{${$ary_ref}[0]});
}

sub _set_fmt_ref {
    my $self = shift;
    my $_fmt_ref = \[];
       $_fmt_ref = $_[0] if ref($_[0]) eq 'ARRAY'; 
    my @_fmt_ary = ();
    #   @_fmt_ary = @$_fmt_ref;      # this will not do it
    for my $i (0..$#{$_fmt_ref}) {   # specifically created it
        %{$_fmt_ary[$i]} = %{${$_fmt_ref}[$i]};  
    }
    $self->{'__fmt_ref'} = \@_fmt_ary;
    # print "_set_fmt_ref: $self->{'__fmt_ref'}\n";
    return;
}

sub _get_fmt_ref {
    return $_[0]->{'__fmt_ref'};
}

sub set_col_width {
    my $self     = shift; 
    my %arg      = @_; 
    my $arf      = $self->_get_fmt_ref;
    # print "\nset_col_width: $arf\n";
    my ($k, $v, $i, $j);
    foreach $k (sort keys %arg) {
        $v = $arg{$k};
        if ($v =~ /\D+/) { 
            carp "Invalid value $v for column $k";
            next;
        }
        if ($k =~ /\D+/) {        # column name 
            $j = -1;
            for $i (0..$#{$arf}) {    # find the column's index
                if (lc($k) eq lc(${$arf}[$i]{'col'})) {
                    $j = $i; last;
                }
            }
            if ($j < 0) { carp "$k is not a valid column"; next; }
            ${$arf}[$j]{'max'} = $v; 
        } else {
            ${$arf}[$k+0]{'max'} = $v; 
        }
    }
    return;
}

sub mod_col_def {
    my $self     = shift; 
    my %arg      = @_; 
    my $arf      = $self->get_cols_ref;
    # print "\nset_col_def: $arf\n";
    my ($k, $v, $i, $j);
    foreach $k (sort keys %arg) {  # key could be index or col_name
        $v = $arg{$k};             # col definition
        $j = -1;                   # index for the column
        if ($k =~ /\D+/) {        # column name 
            # ColA, 'typ:max:min:dec:dft:req'
            for my $i (0..$#{$arf}) {    # find the column's index
                if (lc($k) eq lc(${$arf}[$i]{'col'})) {
                    $j = $i; last;
                }
            }
        } else {                  # column index
            $j = $k + 0;
        }
        if ($j<0||$j>$#{$arf}) { 
            carp "$k is not a valid column"; 
            next;                 # ignore incorrect column indexes
        }
        # 4, 'typ:max:min:dec:dft:req'
        # 4, 'typ=>D:max=>15'
        if ($v =~ /=>/) {
            foreach my $p (split /:/, $v) {
                my($x,$y) = split /=>/, $p;
                $x = lc($x);
                if ($x !~ /(typ|max|min|dec|dft|req)/) {
                    carp "$x is not a valid variable.";
                    next;         # ignore incorrect variables
                }
                ${$arf}[$j]{$x} = $y;
            }
        } else { 
            my @a=split /:/,$v;   # split the col defs
            if ($#a==6) {         # typ:max:min:dec:dft:req:dsp
                (${$arf}[$j]{'typ'},${$arf}[$j]{'max'},
                 ${$arf}[$j]{'min'},${$arf}[$j]{'dec'},
                 ${$arf}[$j]{'dft'},${$arf}[$j]{'req'},
                 ${$arf}[$j]{'dsp'}) = (@a); 
            } else {              # typ:wid:dec:dft:req:dsp
                (${$arf}[$j]{'typ'},${$arf}[$j]{'wid'},
                 ${$arf}[$j]{'dec'},
                 ${$arf}[$j]{'dft'},${$arf}[$j]{'req'},
                 ${$arf}[$j]{'dsp'}) = (@a); 
            }
        }
    }
    return;
}

sub disp_col_defs {
    my $self = shift; 
    my $crf  = "";
       $crf  = shift if (ref($_[0]) eq 'ARRAY');
       $crf  = $self->get_cols_ref if (!$crf);
    my $fmt1 = "%12s %-8s %6s %6s %6s %-10s %-10s %-10s\n";
    my $fmt2 = "%12s %-8s %6d %6d %6d %-10s %-10s %-10s\n";
    printf $fmt1, "ColumnName", "CType", "MaxLen", "DecLen", 
        "MinLen", "DateFmt", "NULL?", "Description";  
    for my $i (0..$#{$crf}) {
        my $wid = 0;
        if (${$crf}[$i]{'wid'}) {
            $wid = ${$crf}[$i]{'wid'};
        } else {
            $wid = ${$crf}[$i]{'max'};
        }
        if (!defined(${$crf}[$i]{'dsp'})) { 
            ${$crf}[$i]{'dsp'} = ""; 
        }
        printf $fmt2,
            ${$crf}[$i]{'col'},${$crf}[$i]{'typ'},$wid,
            ${$crf}[$i]{'dec'},${$crf}[$i]{'min'},${$crf}[$i]{'dft'},
            ${$crf}[$i]{'req'},${$crf}[$i]{'dsp'};  
    } 
}

sub add_col_def {
    # (ColA, 'typ:max:min:dec:dft:req') add the column to the end
    # (2,    'col:typ:max:min:dec:dft:req') insert the column
    my $self     = shift; 
    my @arg      = @_; 
    my $arf      = $self->get_cols_ref;
    # print "\nset_col_def: $arf\n";
    my ($k, $v, $i, $j, $col, @a);
    foreach my $p (0..$#arg) {  # key could be index or col_name
        if ($p%2 == 1) {
            $v = $arg[$p];         # col definition
        } else { 
            $k = $arg[$p]; next;   # column name and next
        }
        @a = split /:/, $v;        # split the col defs
        $j = -1;                   # insert position
        if ($k =~ /\D+/) {         # column name 
            $col=$k; 
            $j = $#{$arf}+1;       # insertion location
        } else {                   # column index
            $col=shift(@a);        # get column name
            $col=~s/col=>//;       # get rid of hash notation if exists
            $j = $k + 0;           # insertion location
        }
        # ColA, 'typ:max:min:dec:dft:req'
        # check whether the column name exist
        my $colexist=-1;
        for my $i (0..$#{$arf}) {  # find the column's index
            if (lc($col) eq lc(${$arf}[$i]{'col'})) {
                $colexist = $i; last;
            }
        }
        if ($colexist >= 0) {      # column exist
            carp "Column $col exist. Not inserted.";
            next;
        }
        if ($j<0||$j>$#{$arf}+1) { 
            carp "$j is not a valid column index. Insertion ignored."; 
            next;                 # ignore incorrect column indexes
        }
        # print "$j:$col\n";
        splice(@$arf, $j, 0, {}); # add an empty hash element
        # ++$j;                     # the inserted col index       
        # 4, 'typ:max:min:dec:dft:req'
        # 4, 'typ=>D:max=>15'
        ${$arf}[$j]{'col'} = uc($col);
        if ($v =~ /=>/) {         # use hash notation
            foreach my $p (@a) {
                my($x,$y) = split /=>/, $p;
                $x = lc($x);
                if ($x !~ /(typ|max|min|dec|dft|req|dsp|wid)/) {
                    carp "$x is not a valid variable.";
                    next;         # ignore incorrect variables
                }
                ${$arf}[$j]{$x} = $y;
            }
        } else { 
            if ($#a==6) {         # 7 elements
                 # typ:max:min:dec:dft:req:dsp
                (${$arf}[$j]{'typ'},${$arf}[$j]{'max'},
                 ${$arf}[$j]{'min'},${$arf}[$j]{'dec'},
                 ${$arf}[$j]{'dft'},${$arf}[$j]{'req'},
                 ${$arf}[$j]{'dsp'}) = (@a); 
            } else {              # typ:wid:dec:dft:req:dsp
                (${$arf}[$j]{'typ'},${$arf}[$j]{'wid'},
                 ${$arf}[$j]{'min'},${$arf}[$j]{'dec'},
                 ${$arf}[$j]{'dft'},${$arf}[$j]{'req'},
                 ${$arf}[$j]{'dsp'}) = (@a); 
            }
        }
    }
    return;
}

sub get_col_width {
    my $self     = shift; 
    my @arg      = @_; 
    my $crf      = $self->_get_fmt_ref;
    print "\@arg=@arg\n";
    if (!@arg) {
        return $self->get_format_string($crf);
    }
    my ($k, @v, $i, $j);
    @v = ();
    foreach $k (@arg) {     # subscripts or column names
        if ($k =~ /\D+/) {        # column name 
            $j = -1;
            for $i (0..$#{$crf}) {    # find the column's index
                if (lc($k) eq lc(${$crf}[$i]{'col'})) {
                    $j = $i; last;
                }
            }
            if ($j < 0) { carp "$k is not a valid column"; next; }
            push @v, ${$crf}[$j]{'max'}; 
        } else {
            push @v, ${$crf}[$k+0]{'max'}; 
        }
    }
    return @v; 
}

sub get_column_defs_arrayref { 
    my @defs_array = get_column_defs(@_);
    return \@defs_array; 
}

sub get_column_defs { 
    my $self     = shift; 
    my $data_ref = "";
    my $display  = "";
       $data_ref = shift if (ref($_[0]) eq 'ARRAY'); # first input 
       $display  = shift if $_[0];                   # second input ? 
    # since this is a 'get' method, we do not set other attrs as well
    # $self->set_data_ref($data_ref) if $data_ref;
    my $arf      = "";
    my $crf      = "";
       $arf      = $data_ref if $data_ref;
       $arf      = $self->get_data_ref if (!$arf);   # get data ref
       $crf      = $self->get_cols_ref;              # get cols ref
    # print "\$arf=$arf:\$crf=$crf\n";
    # print "$#{$arf}:$#{$crf}:", $self->get_first_row, "\n";
    $self->_chkArrays($arf, $crf);
    my(@A, @a, $i, $j, $n, $c, $v, $msg);
    @A=();
    for $i (0..$#{$arf}) {       # loop thru the array
        # print ":" . (join ";", @{${$arf}[$i]}) . "\n";
        if ($i==0) {             # define column names
            if ($self->get_skip_first_row) {
                # get column names from the first row
                for $j (0..$#{${$arf}[$i]}) { 
                    $A[$j]{'col'} = ${$arf}[$i][$j]; 
                }
                next;            # skip the first column
            } else {             # generate seq column names
                for $j (0..$#{${$arf}[$i]}) { 
                    $A[$j]{'col'} = sprintf "FLD%03d", $j+1; 
                }
            }
        } 
        for $j (0..$#{${$arf}[$i]}) {     # loop thru fields  
            $v = ${$arf}[$i][$j];         # value in the field
            if (!defined($A[$j]{'max'})) { $A[$j]{'max'} = -1; }
            if (!defined($A[$j]{'min'})) { $A[$j]{'min'} = 9999999; }
            if (!defined($A[$j]{'typ'})) { $A[$j]{'typ'} = ""; }
            if (!defined($A[$j]{'dft'})) { $A[$j]{'dft'} = ""; }
            if (!defined($A[$j]{'dsp'})) { $A[$j]{'dft'} = ""; }
            if (!defined($A[$j]{'dec'})) { $A[$j]{'dec'} = 0; }
            if ($A[$j]{'max'}<length($v)){ $A[$j]{'max'}=length($v); }
            if ($A[$j]{'min'}>length($v)){ $A[$j]{'min'}=length($v); }
            if ($A[$j]{'typ'} ne 'C') {    $A[$j]{'typ'} = 'N';
                if ($v =~ /\D+/) { $A[$j]{'typ'} = 'C'; }
            }
            if ($A[$j]{'typ'} eq 'N') {   # it is numeric 
                if (!defined($A[$j]{'dec'})) { $A[$j]{'dec'} = 0; }
                @a = split /\./, $v; 
                if (!defined($a[1])) { $a[1] = ""; } # so no warning
                if ($A[$j]{'dec'}<length($a[1])) {   # max decimal
                    $A[$j]{'dec'} = length($a[1]);   # length
                }
            }
        }   # end of for $j (...) 
    }   # end of for $i (...)
    for $i (0..$#A) { 
        if ($A[$i]{'min'}>0) { $A[$i]{'req'} = 'NOT NULL';
        } else {               $A[$i]{'req'} = "" } 
    } 
    if ($display) { $self->disp_col_defs(\@A); }
    return @A;
}

sub get_content { 
    my $self     = shift; 
    # print "$self\n";
    my $data_ref = "";    # We need to initialize it to prevent from
    my $cols_ref = "";    # getting value from callers.
    my $out_type = "";
    my $display  = "";
       $data_ref = shift if (ref($_[0]) eq 'ARRAY'); # 1st input 
       $cols_ref = shift if (ref($_[0]) eq 'ARRAY'); # 2nd input 
       $out_type = shift if $_[0];                   # 3rd input 
       $display  = shift if $_[0];                   # 4th input 
    my $arf      = "";   # We need to initialize in case the caller has 
    my $crf      = "";   # used the same variable names.  .
       $arf      = $data_ref if $data_ref;           # use data ref
       # print "\$data_ref \$arf=$arf\n";
       $arf      = $self->get_data_ref if (!$arf);   # get data ref
       $crf      = $cols_ref if $cols_ref;           # use cols ref
       $crf      = $self->_get_fmt_ref if (!$crf);   # get cols ref
    if ($data_ref && !$cols_ref) { 
        # we need to build the column defs based on the input data
        # array.
        $crf = $self->get_column_defs_arrayref($data_ref);
    }
    # print "\$data_ref=$data_ref\t\$arf=$arf\n";
    $self->_chkArrays($arf, $crf);
    my($fmt1, $fmt2) = $self->get_format_string($crf);
    my @CN = (); my @BAR = ();
    for my $i (0..$#{$crf}) { 
        # print "${$crf}[$i]{'col'}:${$crf}[$i]{'max'}\n";
        my $len = (${$crf}[$i]{'max'} == 0) ? 1 : ${$crf}[$i]{'max'}; 
        if (${$crf}[$i]{'col'} =~ /^FLD/) {
            push @CN, substr(${$crf}[$i]{'col'},-$len);
        } else {
            push @CN, substr(${$crf}[$i]{'col'},0,$len);
        }
        push @BAR, "-" x $len;
    }
    my $result = "";
    $result  = sprintf $fmt1, @CN; 
    $result .= sprintf $fmt1, @BAR;
    for my $i (0..$#{$arf}) { 
        next if ($self->get_first_row && $i==0); 
        $result .= sprintf $fmt2, @{${$arf}[$i]}; 
    }
    if ($display) { print $result; }
    return $result;
}

sub get_format_string {
    my $self      = shift; 
    my $cols_ref  = ""; 
    my $field_sep = " ";
    my $display   = "";
    my $crf       = "";
       $cols_ref  = shift if (ref($_[0]) eq 'ARRAY'); # first input 
       $field_sep = shift if $_[0];                   # field separator
       $display   = shift if $_[0];                   # second input ? 
       $crf       = $cols_ref if $cols_ref;           # input first
    # if not input, try to get from object attributes
    $crf = $self->get_cols_ref if (!$crf); 
    # if we still do not get, let us inform the caller
    croak "No array ref for column definition found" if (!$crf);
    $field_sep = $self->get_field_sep if (!defined($field_sep));
    # print "get_format_string: $crf\n";

    # Build format string 
    my $fmt_t = "";     # format string for column names
    my $fmt   = "";     # format string for array
    if (${$crf}[0]{'typ'} eq 'N') {     # numeric column
        $fmt .= "%${$crf}[0]{'max'}.${$crf}[0]{'dec'}f"; 
    } else {                            # text column
        $fmt .= "%${$crf}[0]{'max'}s";  
    }
    $fmt_t .= "%${$crf}[0]{'max'}s";
    for my $i (1..$#{$crf}) {
        $fmt_t .= "$field_sep%${$crf}[$i]{'max'}s"; 
        if (${$crf}[$i]{'typ'} eq 'N') { 
            $fmt .= "$field_sep%${$crf}[$i]{'max'}.${$crf}[$i]{'dec'}f";
        } else {
            $fmt .= "$field_sep%${$crf}[$i]{'max'}s"; 
        }
    }
    $fmt .= "\n"; $fmt_t .= "\n";
    return $fmt_t, $fmt;
}

# implement other get_... and set_... method (create as neccessary)
sub AUTOLOAD {
    no strict "refs";
    my ($self, $newval) = @_;
    # was it a get_... method?
    if ($AUTOLOAD =~ /.*::get(_\w+)/ && $self->_accessible($1, 'read'))
    {   my $attr_name = $1;
        # print "get $attr_name->\n";
        *{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
        return $self->{$attr_name};
    }
    # If it is a set method ...
    if ($AUTOLOAD =~ /.*::set(_\w+)/ && $self->_accessible($1, 'write'))
    {   my $attr_name = $1;
        # print "set $attr_name->$newval\n";
        *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
        $self->{$attr_name} = $newval;
        return;
    }
    # If it is a skip method ...
    if ($AUTOLOAD =~ /.*::skip(_\w+)/ && $self->_accessible($1,'write'))
    {   my $attr_name = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
        # we need to set both "_first_row" and "_skip_first_row"
        if ($newval) { 
            $self->{$attr_name} = $newval; 
            $self->{"_skip$attr_name"} = $newval;
        } else  { $self->{$attr_name} = 1;
            $self->{"_skip$attr_name"} = 1; }
        return;
    }
    # must have been a mistake then ...
    croak " No such method: $AUTOLOAD";
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit 
# program.

1;   # ensure that the module can be successfully used.

__END__
# Below is the stub of documentation for your module. You better edit 
# it!

=head1 NAME

Data::Display - Perl extension for formating and displaying array. 

=head1 SYNOPSIS

  use Data::Display;

  $dsp = Data::Display->new($drf, $crf, $ech, %arg);
  $dsp->skip_first_row;           # i,e. 1st row contains col names
  $dsp->set_skip_first_row(1);    # is the same as the above       
  $dsp->set_field_sep($ech);      # default is a space
  $dsp->set_data_ref($drf);       # ref to an array containing data
  $dsp->set_cols_ref($crf);       # ref to an array containing col defs
  $dsp->set_col_width($fld,$wd,$col,$wd,...);
  $dsp->add_col_def($col,'typ:max:min:dec:dft:req');     # append
  $dsp->add_col_def($idx,'col:typ:max:min:dec:dft:req'); # isert
  $dsp->mod_col_def($fld,'typ:max:min:dec:dft:req');

  $rc      = $dsp->get_skip_first_row;
  $rc      = $dsp->get_first_row; # the same as the above

  $ary_ref = $dsp->get_column_defs_arrayref($drf,$ech);
  @ary     = $dsp->get_column_defs(\@ary,$ech);  # $yn: display? 

  $str     = $dsp->get_col_width();              # get format string
  @ary     = $dsp->get_col_width($fld,$col,...); # a list of width
  ($cfs, $dfs) = $dsp->get_col_width();   
  ($cfs, $dfs) = $dsp->get_format_string($crf,$sep,$ech);

  $str     = $dsp->get_content($drf,$crf,$typ,$ech); 
  $str     = $dsp->get_content($typ,$ech);       # use ary refs 

  $rv      = $dsp->get_no_of_fields;
  $rv      = $dsp->get_no_of_columns;
  $rv      = $dsp->get_no_of_rows;
  $rv      = $dsp->get_no_of_records;
  ($rows, $cols) = $dsp->get_dimension($drf); 
  ($rows, $cols) = $dsp->get_dimension; 


Notation and Conventions

   $dsp    a display object
   $drf    data array reference
   $crf    column definition array reference
   $ech    whether to echo messages or contents
   $cfs    column heading format string 
   $dfs    data content format string
   $sep    field separator character
   $typ    output type, text, html, etc.

   $drh    Driver handle object (rarely seen or used in applications)
   $h      Any of the $??h handle types above
   $rc     General Return Code  (boolean: true=ok, false=error)
   $rv     General Return Value (typically an integer)
   @ary    List of values returned from the database, typically a row 
           of data
   $rows   Number of rows processed (if available, else -1)
   $fh     A filehandle
   undef   NULL values are represented by undefined values in perl
   \%attr  Reference to a hash of attribute values passed to methods

=head1 DESCRIPTION

This is my first object-oriented Perl program.
The Display module will scan through each records and fields in the
array to collect information about the content in the array. It creates
a column definition array, builds formating strings, and display the 
contents nicely.

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

The array passed to the module can have the first row containing column
names or have a separate array containing column definitions. It has to
be in the same format of the array that we describe in the above if it 
is referenced to a out side array. 

It also creates and tracks a format information. The format information
contains in a separate array, which has exactly the same element as the
column definition array.

It has many "set" and "get" methods to assign and to query data 
contained in the object. Here is the list of methods:

=over 4

=item the constructor new($drf, $crf, $ech, %arg)

Without any input, i.e., new(), the constructor generates an empty 
object. If any argument is provided, the constructor expects them in
the right order. 

=item skip_first_row/set_first_row(1)

This method indicates that the first row in the array contains column 
names. The default is false.

=item get_skip_first_row/get_first_row 

This method checks the indicator for the first row data, i.e., whether 
it contains column names.

=item set_field_sep($ech)/get_field_sep 

This method sets/gets output field separator. The default separator 
is a space(" ").   

=item set_data_ref($drf)/get_data_ref 

This method sets/gets data array reference. The records in the array 
that the ref points to are used to determine column definitions and 
to be displayed.

=item set_cols_ref($crf)/get_cols_ref 

This method sets/gets column array reference. The array contains 
column name, column type, column max length, column min length, column 
decimal length, and column constraints. 

=item get_column_defs_arrayref($drf, $ech)  

This method gets the reference pointing to the column definition array.
If new data array reference is specified, it gets the definition for
the data array. It does not change the internal attributes defined for
the object, so you can pass any data array reference to this method
without touching the internal attributes in the object. Actually, all
the I<get> methods do not change anything in the object. 

=item get_column_defs($drf, $ech) 

This method get the contents in the column definition array. If no 
input column array ref and no column names in the first row, it 
generates sequential column names such as "FLD001", "FLD002, etc.
If $ech is specified, it will display the content of the column 
definition array. 

=item disp_col_defs($crf)

This method displays the content of column definition array in a nice
format. 

=item set_col_width/get_col_width($cp,$v1,$cn,$v2,...) 

This method sets/gets the max length of columns based on column 
position ($cp) or column names ($cn). The column position is zero based.
The default is the same as the column definition array. The get method 
without any argument returns the Perl format string based on modified 
column max width. If no modification, the returned format string is 
the same as that from I<get_format_ string>. 

=item get_format_string($crf,$sep,$ech) 

This method gets the Perl format string. It is created based on the 
column format array.

=item get_content($drf,$crt,$typ,$ech) 

This method gets the formated contents from the data array. It uses 
the separator to divide fields. If $drf and $crf are not provided, 
this method will get them from the attributes in the object. The
$typ sepcifies what type of output format will be, currently only 
"text" is available. If $ech is specified, the content will also be
displayed.

=item get_no_of_fields/get_no_of_columns 

This method gets number of fields (columns) in the data array.

=item get_no_of_rows/get_no_of_records 

This method gets number of rows (records) in the data array.

=item get_dimension($drf) 

This method gets number of rows and columns in the data array or 
the array ref passed to this method. 

=item add_col_def($fld, $col_def)

This method add or construct column definition array. You can 
either append to the end of the column def array or insert into
the position that you specified. It takes two inputs: column name
or index and column definitions. If column name is specified in 
the first input, it will try to append the column and its defintion
to the end of the array. If the first input is the column position,
then it inserts the definiton after the position specified. You can
use two format to define column, i.e., camma delimited values or
comma delimited hash assignment. In camma delimited value format,
the vlaues have to be in the exact order in 
'col:typ:max:min:dec:dft:req'. In hash assignment format, order is
not an issue. For instance, 'max=>5:typ=D:dft=>YYYY/MM/DD'. The
column name or column index are checked before any insertion is 
commited. You can add as many columns as you like in one run,
just be cautious when you insert columns. You may not get the 
position that you desire since array's index changes once you have
inserted column definiton in it.

=item mod_col_def($fld, $col_def)

This method modifies the existing column definitons in the column
definiton array. You can use the same ways and formats described
in the I<add_col_def> method.

=back

=head2 How to create a display object? 

If you have an array @ary and column array @C, you can create a display 
object as the following:

  $dsp = Data::Display->new(\@ary,\@C); 

This is equivalent to 

  $dsp = Data::Display->new();
  $dsp->set_data_ref(\@ary);
  $dsp->set_cols_ref(\@C);

If you do not have column array, you can generate it as the following:

  $col_ref = $dsp->get_column_defs_arrayref(\@ary); 
  $dsp->set_cols_ref($col_ref);

You can set a hash to define your object attributes and create it as 
the following:

  %attr = (
    'field_sep'       => ':',    # output field separator
     'skip_first_row' => 1,      # 1st row has col names
     'data_ref'       => \@ary,  # array_ref for data
     'cols_ref'       => \@C,    # array_ref for col defs
    );
  $dsp = Data::Display->new(%attr);

=head2 How is the column definition generated?

If the first row in the data array contains column names, it uses the
column names in the row to define the column definition array. The 
column type is determined by searching all the records in the data 
array. If all the records in the column only do not contain non-digits,
i.e., only [0-9.], the column is defined as numeric ('N'); otherwise,
it is defined as character ('C'). No other data types such as date 
are searched currently.

If the first row does not contain column names and no column definition
array is provided, the I<get_column_defs> or I<get_column_defs_arrayref>
will generate field names as "FLD###". The "###" is a sequential number
starting with 1. If the minimum length of a column is zero, then the
value in the column can be null; if the minimum length is greater than
zero, then it is a required column.

The default indicator for the first row is false, i.e., the first row
does not contain column names. You can indicate whether the first row 
in the data array is column names by using I<skip_first_row> 
or I<set_skip_first_row> to set it.

  $dsp->skip_first_row;
  $dsp->set_skip_first_row(1);    # the same as the above
  $dsp->set_first_row(1);         # the same as the above
  $dsp->set_skip_first_row('Y');  # the same effect 
  $dsp->set_first_row('Y');       # the same as the above

To reverse it, here is how to

  $dsp->set_skip_first_row(0);    # no column in the first row
  $dsp->set_first_row(0);         # the same as the above
  $dsp->set_skip_first_row('');   # the same effect 
  $dsp->set_first_row('');        # the same as the above

=head2 How to change the array references in the display object

You can pass data and column definition array references to display
objects using the object constructor I<new> or using the I<set> methods:

  $dsp = Data::Display->new($arf, $crf); 
  $dsp->set_data_ref(\@new_array);
  $dsp->set_cols_ref(\@new_defs);     


=head2 How to access the object?

You can get the information from the object through all the I<get>
methods described above. 

=head2 How to add column definitons?

You can add column definitions to the existing definition array 
using method I<add_col_def> through two ways: append or insert. 

  $dsp = Data::Display->new($arf, $crf); 
  $dsp->add_col_def('ColX','D:18:10::YYYY/MM/DD:NOT NULL');  # append 
  $dsp->add_col_def(2,'max=>18:col=>ColX:typ=>D');           # insert

You can use two formats as you already see from the above examples:
list or hash. In the value list format, you must follow the order of
'col:typ:max:min:dec:dft:req'. You can add multiple columns at once.
You can pre-create an array and pass the whole array to the 
method. Here is an example:

  @cols = ( 'ColX', 'D:18:10::YYYY/MM/DD:NOT NULL',
             '2',   'max=>18:col=>ColX:typ=>D',
            'ColY', 'max=>15:typ=>N:dec=>2',
             '4',   'C:20:0::::'
          );
  $dsp->add_col_def(@cols);

The column name and position will be checked before inserting new 
columns. If the column name exist or the position is out of the 
range of the existing column definition array, the insertion for
the column will be ignored. Please also note that positions are
changed based on previous insertions.

=head2 How to modify column definitons?

You can modify the existing column definitions using method 
I<add_col_def> through two ways (append and insert) and two formats
(list and hash) just as described in the adding column definitons
section. 

=head2 Future Implementation

Although it seems a simple task, it requires a lot of thinking to get
it working in an object-oriented frame. Intented future implementation
includes 

=over 4

=item * add more output type such as HTML table.

=item * a I<sync> method 

This method will be used to syncronize the data, definition and format
array references.

=item * a debugger option

A method can also be implemented to turn on/off the debugger. 

=item * a logger option

This option will allow output and/or debbuging information to be 
logged.

=back

=head1 AUTHOR

Hanming Tu, hanming_tu@yahoo.com

=head1 CODING HISTORY

=over 4

=item * Version 0.02: 12/14/2000 - First enhancement

  1) added date datatype; 
  2) added add_col_def method;
  3) added mod_col_def method; 
  4) added disp_col_defs method.

=item * Version 0.01: 05/10/2000 - Initial coding

=back

=head1 SEE ALSO (some of docs that I check often)

perltoot(1), perlobj(1), perlbot(1), perlsub(1), perldata(1),
perlsub(1), perlmod(1), perlmodlib(1), perlref(1), perlreftut(1).

=cut

