package Config::Natural;

use strict;
use Carp qw(carp croak);
use File::Spec;
use FileHandle;

{ no strict; 
  $VERSION = '1.01';
}

# class option
my %options = (
    quiet => 0, 
);


# 
# new()
# ---
sub new {
    my $class = shift;
    my $self = bless {
        options => {
            'comment_line_symbol'     => '#', 
            'affectation_symbol'      => '=', 
            'append_symbol'           => '+', 
            'multiline_begin_symbol'  => '-', 
            'multiline_end_symbol'    => '.', 
            'array_begin_symbol'      => '(', 
            'array_end_symbol'        => ')', 
            'list_begin_symbol'       => '{', 
            'list_end_symbol'         => '}', 
            'include_symbol'          => 'include', 
            'case_sensitive'          => 1, 
            'auto_create_surrounding_list' => 0, 
            'read_hidden_files'       => 0, 
            'strip_indentation'       => 0, 
        }, 
        state => {  }, 
        param => {  }, 
        handlers => {  }, 
        prefilter => 0, 
        filter => 0, 
    }, $class;
    
    if(ref $_[0] eq 'HASH') {
        my $opts = shift;
        for my $option (keys %$opts) {
            $options{$option} = $opts->{$option} if exists $options{$option};
            $self->{'options'}{$option} = $opts->{$option};
            $self->filter($opts->{$option}) if $option eq 'filter';
            $self->prefilter($opts->{$option}) if $option eq 'prefilter';
        }
    }
    $self->read_source(shift) if @_;
    return $self;
}


# 
# AUTOLOAD()
# --------
sub AUTOLOAD {
    no strict;
    my $self = $_[0];
    my $type = ref $self || croak "I am not an object, so don't call me that way.";
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    
    carp "Unknown option '$name'" 
      unless exists $options{$name} or defined $self->{options}{$name};

    my $code = q{
        sub {
            my $self = shift;
            my $value = $self->{options}{METHOD};
            $self->{options}{METHOD} = shift if @_;
            return $value
        }
    };
    $code =~ s/METHOD/$name/g;

    *$AUTOLOAD = eval $code;
    goto &$AUTOLOAD;
}


# 
# DESTROY()
# -------
sub DESTROY {
    my $self = shift;
    $self->clear_params;
    $self->delete_all;
}


# 
# options()
# -------
sub options {
    my $self = shift;
    my $args = _parse_args(@_);
    my @ret_list = ();
    
    for my $arg (@{$args->{'get'}}) {
        carp "Class option '$arg' does not exist" and next 
            unless exists $options{$arg} or $options{'quiet'};
        push @ret_list, $options{$arg};
    }
    
    for my $arg (keys %{$args->{'set'}}) {
        carp "Class option '$arg' does not exist" and next 
            unless exists $options{$arg} or $options{'quiet'};
        $options{$arg} = $args->{'set'}{$arg};
    }
    
    return wantarray ? @ret_list : $ret_list[0];
}


# 
# _read_dir()
# ---------
# Recursively walk through the given directory and read 
# all the files encountered
# 
sub _read_dir {
    my $self = shift;
    my $dir  = shift;
    
    return $self->read_source($dir) if -f $dir;
    
    opendir(DIR, $dir) or croak "Can't read directory '$dir': $!";
    my @list = grep {!/^\.\.?$/} readdir(DIR);  # remove . and ..
    @list = grep {!/^\./} @list unless $self->read_hidden_files;
    closedir(DIR);
    
    for my $file (@list) {
        my $path = File::Spec->catfile($dir, $file);

        if(-d $path) {
            $self->_read_dir($path)
        } else {
            $self->read_source($path)
        }
    }
}


# 
# read_source()
# -----------
# Read the data from the given file or filehandle
# 
sub read_source {
    my $self = shift;
    my $file = shift;
    local $_;
    
    # go to recursive mode if the argument is a directory
    if(-d $file) {
        unshift @_, $self, $file;
        goto &_read_dir
    }
    
    # ... else open the file
    my $fh = _file_or_handle($file) or croak "Can't open file '$file': $!";
    
    # keep local copy of the properties we'll use
    my $comment   = $self->comment_line_symbol;
    my $aff_sym   = $self->affectation_symbol;
    my $app_sym   = $self->append_symbol;
    my $multiline = $self->multiline_begin_symbol;
    my $multi_end = $self->multiline_end_symbol;
    my $array     = $self->array_begin_symbol;
    my $array_end = $self->array_end_symbol;
    my $list      = $self->list_begin_symbol;
    my $list_end  = $self->list_end_symbol;
    my $include   = $self->include_symbol;
    my $state     = $self->{'state'};
    
    # store the name of the last opened file
    $state->{'filename'} = $file;
    
    while(<$fh>) {
        ## execute the prefilter if present
        $self->{'prefilter'} and $_ = &{$self->{'prefilter'}}($self, $_);
        
        next if /^\s*$/;  # skip empty lines
        next if /^\s*$comment/;  # skip comments
        chomp;
        
        ## include statement
        if(/^\s*\Q${include}\E\s+(\S+)\s*$/) {
            my $included = $1;
            my @path = File::Spec->splitdir($state->{'filename'});
            pop @path;  # remove the current file name from the path
            $included = File::Spec->catdir(@path, $included);
            $self->read_source($included);
            next
        }
        
        ## begin of a new list
        if(/^\s*(\S+)\s*\Q${list}\E\s*$/) {
            push @{$state->{lists_names}}, $1;
            push @{$state->{lists_stacks}}, {};
            next
        }
        
        ## end of the current list
        if(/^\s*\Q${list_end}\E\s*$/) {
            my $lists_stacks = $state->{'lists_stacks'};
            my $curlistname = pop @{$state->{'lists_names'}};
            my $curlistref  = pop @$lists_stacks;
            
            if(@$lists_stacks) {
                push @{ $$lists_stacks[-1] ->{ $curlistname } }, $curlistref
            } else {
                push @{$self->{'param'}{$curlistname}}, $curlistref
            }
            
            next
        }
        
        ## parameter affectation
        my($field,$value) = (/^\s*(\S+)\s*\Q${app_sym}\E?\s*\Q${aff_sym}\E\s*(.*)$/);
        
        ## detect append mode
        my $append = /^\s*(\S+)\s*\Q${app_sym}\E\s*\Q${aff_sym}\E\s*(.*)$/;
        my $prev_value = ${$state->{'lists_names'}}[-1] ? 
                $state->{'lists_stacks'}[-1]{$field} : $self->{'param'}{$field};
        
        ## multiline case
        if($value =~ /^\s*\Q${multiline}\E\s*$/) {
            $value = '';
            $value = $prev_value . $value and $append = 0 if $append;
            $_ = <$fh>;
            
            $self->strip_indentation and my($indent) = (/^(\s*)/);
            
            while(not /^\s*\Q${multi_end}\E\s*$/) {
                $indent and s/^$indent//;
                $value .= $_;
                $_ = <$fh>;
                last if eof($fh)
            }
        }
        
        ## array case
        if($value =~ /^\s*\Q${array}\E\s*$/) {
            $value = '';
            $_ = <$fh>;
            
            while(not /^\s*\Q${array_end}\E\s*$/) {
                s/^\s*//;
                $value .= $_;
                $_ = <$fh>;
                last if eof($fh)
            }
            
            $append ? 
              ( push @$prev_value, split($/, $value) and $append = 0 )
              : $self->param({ $field => [ split $/, $value ] });
            next
        }
        
        ## create a surrounding list if the parameter already exists
        if($self->auto_create_surrounding_list) {
            my $surrlist   = "${field}s";
            my $root_param = $self->{'param'};
            my $curlistref = ${$self->{'state'}{'lists_stacks'}}[-1];
            
            if($curlistref) {
                $root_param = $curlistref
            }
            
            ## the surrounding list doesn't already exist
            if(exists $root_param->{$field} and not exists $root_param->{$surrlist}) {
                $root_param->{$surrlist} = [ { $field => $root_param->{$field} } ];
                delete $root_param->{$field};
            }
            
            ## add the new parameter to the list
            if(exists $root_param->{$surrlist}) {
                push @{$root_param->{$surrlist}}, { $field => $value };
                next
            }
        }
        
        ## add the new value to the object parameters
        $value = $prev_value . $value if $append;
        $self->param({ $field => $value });
    }
}


# 
# _file_or_handle()
# ---------------
sub _file_or_handle {
    my $file = shift;
    
    unless(ref $file) {
        my $mode = shift || 'r';
        my $fh = new FileHandle $file, $mode;
        return $fh
    }
    
    return $file
}


# 
# param()
# -----
sub param {
    my $self = shift;
    return $self->all_parameters unless @_;
    
    my $args = _parse_args(@_);
    
    my @retlist = ();  # return list
    
    ## get the value of the desired parameters
    for my $arg (@{$args->{'get'}}) {
        carp "Parameter '$arg' does not exist" and next
            if not exists $self->{'param'}{_case_($self, $arg)} and not $options{'quiet'};
        
        push @retlist, $self->{'param'}{_case_($self, $arg)}
    }
    
    ## set the named parameters to new values
    my $param;
    my $current_list = ${$self->{'state'}{'lists_names'}}[-1];
    my @arg_list = keys %{$args->{'set'}};
    
    if($current_list) {
        $param = ${$self->{'state'}{'lists_stacks'}}[-1];
        
    } else {
        $param = $self->{'param'};
    }
    
    for my $arg (@arg_list) {
        my $value = $args->{'set'}{$arg};
        
        ## use the filter if present
        $self->{'filter'} and
            $value = &{$self->{'filter'}}($self, $value);
        
        ## use the handler if present
        $self->{'handlers'}{$arg} and 
            $value = $self->exec_handler($arg, $value);
        
        $param->{_case_($self, $arg)} = $value
    }
    
    return wantarray ? @retlist : $retlist[0]
}


# 
# _case_()
# ------
# Check for the case 
# 
sub _case_ {
    my $self = shift;
    my $param = shift;
    return ($self->case_sensitive ? $param : lc $param)
}


# 
# _parse_args()
# -----------
sub _parse_args {
    my %args = ( get => [], set => {} );
    
    while(my $arg = shift) {
        if(my $ref_type = ref $arg) {
            
            ## setting multiples parameters using a hashref
            if($ref_type eq 'HASH') {
                local $_;
                for (keys %$arg) {
                    $args{'set'}{$_} = $arg->{$_} if $_
                }
                
            } else {
                carp "Bad ref $ref_type; ignoring it" unless $options{'quiet'};
                next
            }
        
        } else {
           ## setting a parameter to a new value
           if(substr($arg, 0, 1) eq '-') {
               $arg = substr($arg, 1);
               my $val = shift;
               carp "Undefined value for parameter '$arg'" and next 
                   if not defined $val and not $options{'quiet'};
               $args{'set'}{$arg} = $val if $arg
               
           ## getting the value of a parameter
           } else {
               push @{$args{'get'}}, $arg
           }
        }
    }
    
    return \%args
}


# 
# prefilter()
# ---------
# Set a new prefilter. 
# 
sub prefilter {
    my $self = shift;
    my $code = shift;
    croak "Not a CODEREF" unless ref $code eq 'CODE';
    $self->{'prefilter'} = $code;
}


# 
# filter()
# ------
# Set a new filter. 
# 
sub filter {
    my $self = shift;
    my $code = shift;
    croak "Not a CODEREF" unless ref $code eq 'CODE';
    $self->{'filter'} = $code;
}


# 
# set_handler()
# -----------
# Set a new handler for a parameter
# 
sub set_handler {
    my $self = shift;
    my $param = shift;
    my $code = shift;
    $self->{'handlers'}{$param} = $code;
}


# 
# delete_handler()
# --------------
# Delete the handler of the given parameter
# 
sub delete_handler {
    my $self = shift;
    my $param = shift;
    delete $self->{'handlers'}{$param};
}


# 
# has_handler()
# -----------
# Check if the given parameter has a handler
# 
sub has_handler {
    my $self = shift;
    my $param = shift;
    return exists $self->{'handlers'}{$param}
}


# 
# exec_handler()
# ------------
# Execute the handler of a parameter
# 
sub exec_handler {
    my $self = shift;
    my $param = shift;
    my $value = shift;
    return &{$self->{'handlers'}{$param}}($param, $value)
}


# 
# all_parameters()
# --------------
# Return the list of all the parameters at the root level
# 
sub all_parameters {
    my $self = shift;
    return keys %{$self->{'param'}}
}


# 
# param_tree()
# --------------
# Return the hash tree of all parameters
# 
sub param_tree {
    my $self = shift;
    my $tree = {};
    $tree->{$_} = $self->param($_) for($self->param());
    return $tree;
}


# 
# value_of()
# --------
# Return the value of the specified parameter
# 
sub value_of {
    my $self = shift;
    my $param_path = shift;
    
    # handle simple cases simply...
    return $self->{'param'}{$param_path} if $self->{'param'}{$param_path};
    
    # handle more complex cases nicely.
    my @path = split '/', $param_path;
    not $path[0] and shift @path;
    
    my($name,$index) = ( (shift @path) =~ /^([^[]+)(?:\[([+-]?\d+|\*)\])?$/ );
    my $node = $self->param($name);  $index ||= 0;
    return $node if $index eq '*';
    
    if(ref $node) {
        $node = $node->[int($index)];
        for my $p (@path) {
            ($name,$index) = ( ($p) =~ /^([^[]+)(?:\[([+-]?\d+|\*)\])?$/ );
            $node = $node->{$name};  $index ||= 0;
            ref $node and $index ne '*' and $node = $node->[int($index)];
        }
    }
    
    return $node
}


# 
# delete()
# ------
# Delete the given parameters
# 
sub delete {
    my $self = shift;
    
    for my $param (@_) {
        carp "Parameter '$param' does not exist" and next 
            if not exists $self->{'param'}{_case_($self, $param)} and not $options{'quiet'};
        delete $self->{'param'}{_case_($self, $param)}
    }
}


# 
# delete_all()
# ----------
sub delete_all {
    my $self = shift;
    $self->delete($self->all_parameters)
}


# 
# clear()
# -----
sub clear {
    my $self = shift;
    for my $param (@_) {
        $self->param({$param => ''})
    }
}


# 
# clear_params()
# ------------
sub clear_params {
    my $self = shift;
    for my $param ($self->all_parameters) {
        $self->param({$param => ''})
    }
}


# 
# dump_param()
# ----------
sub dump_param {
    my $self = shift;
    my $args = _parse_args(@_);
    my $prefix = $args->{'set'}{'prefix'} || '';
    my $suffix = $args->{'set'}{'suffix'} || '';
    my $nospace = $args->{'set'}{'nospace'} || 0;

    return _dump_tree($self, $self->{'param'}, 0, 
        prefix => $prefix, suffix => $suffix, nospace => $nospace)
}


# 
# _dump_tree()
# ----------
sub _dump_tree {
    my $self = shift;
    my $tree = shift;
    my $level = shift;
    my %state = @_;
    my $str = '';
    my $sp = $state{'nospace'} ? '' : ' ';
    
    if(ref $tree eq 'HASH') {
        
        # add the list name and symbol
        $state{'list_name'} and 
        $str .= join '', 
                $/, $sp x (($level-1)*2), $state{'list_name'}, $sp, 
                $self->list_begin_symbol, $/;
        
        for my $param (sort keys %$tree) {
            if(ref($tree->{$param})) {
                $str .= _dump_tree($self, $tree->{$param}, $level+1, %state, list_name => $param)
            
            } else {
                ## multi-line value?
                my $multiline = 1 if $tree->{$param} =~ /\n|\r/;
            
                $str .= join '', 
                        $sp x ($level*2), 
                        $state{'prefix'}, $param, $sp, $self->affectation_symbol, $sp, 
                        ($multiline ? $self->multiline_begin_symbol . $/ : ''), 
                        $tree->{$param}, 
                        ($multiline ? $self->multiline_end_symbol   . $/ : ''), 
                        $state{'suffix'}, $/;
            }
        }
       
        # add the list end symbol
        $state{'list_name'} and 
        $str .= join '', 
                $sp x (($level-1)*2), $self->list_end_symbol, $/;
    
    } elsif(ref $tree eq 'ARRAY') {
        if(ref $tree->[0]) {
            for my $list (@$tree) { $str .= _dump_tree($self, $list, $level, %state) }
        } else {
            $str .= join '', 
                    $sp x ($level*2), 
                    $state{'prefix'}, $state{'list_name'}, $sp,
                    $self-> affectation_symbol, $sp, $self->array_begin_symbol, $/, 
                    (map {($sp x (($level+1)*2)) . $_ . $/} @$tree), 
                    $sp x ($level*2), $self->array_end_symbol, $/
        }
    
    } else {
        warn "unexpected reference type ", ref($tree)
    }
    
    return $str
}


# 
# write_source()
# ------------
# Write the current state of the object to a file
# 
sub write_source {
    my $self = shift;
    
    # use the last filename given to read_source() if no arg
    push @_, $self->{'state'}{'filename'} unless @_;
    
    my $file = shift;
    my $fh = _file_or_handle($file, 'w');
    print $fh $self->dump_param(@_) or croak "Error while writing to '$file': $!";
}


1;

__END__

=head1 NAME

Config::Natural - Module that can read easy-to-use configuration files

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

Lets say you have a file F<mail.conf>

    name = John Doe
    email = jdoe@somewhere.net
    server = mail.somewhere.net
    signature = -
John Doe
--
Visit my homepage at http://www.somewhere.net/~jdoe/
.

You can read it using the following program:

    use Config::Natural;
    my $mailconf = new Config::Natural 'mail.conf';

and you can for example print the signature:

    print $mailconf->param('signature');


=head1 DESCRIPTION

This module has been written in order to provide an easy way to read 
simple configuration files. The syntax of these configuration files 
is what seemed to me the most natural way to write these files, hence 
the name of this module. 

One of the reason I wrote this module is that I wanted a very easy way 
to feed data to C<HTML::Template> based scripts. Therefore the API of 
C<Config::Natural> is compatible with C<HTML::Template>, and you can write 
programs as simple as:

    use strict;
    use Config::Natural;
    use HTML::Template;

    my $source = new Config::Natural 'file.src';
    my $tmpl = new HTML::Template type => 'filename', 
            source => 'file.tmpl', associate => $source;
    print $tmpl->output;

And this is not just another trivial example: I use scripts nearly 
as simple as this one to create most of my web pages. 


=head1 SYNTAX

In brief, C<Config::Natural> supports the following features in 
configuration files: 

=over 4

=item *

multiline values, 

=item *

arrays, 

=item *

nested lists, 

=item *

inclusion. 

=back

Any element of the syntax can be changed via the corresponding accessor. 


=head2 Affectations

To affect a value to a parameter, simply write:

    greetings = hello world

The parameter C<greetings> will have the value C<"hello world">. 
You can also give multi-lines values this way:

    text = -
    Perl is a language optimized for scanning arbitrary text files, 
    extracting information from those text files, and printing 
    reports based on that information.  It's also a good language 
    for many system management tasks.  The language is intended to 
    be practical (easy to use, efficient, complete) rather than 
    beautiful (tiny, elegant, minimal).
    
    [from perl(1)]
    .

Think of this as a "Unix inspired" syntax. Instead of giving the value, 
you write C<"-"> to mean "the value will follow" (in Unix, this means the 
data will come from standard input). To end the multi-lines value, put 
a single dot C<"."> on a line (as in Unix mail, but it needn't be on 
the first column). 

Since version 1.00, values can also be appended by prefixing the append 
symbol, by default C<+>, so if you write 

    motto = Everything that has a beginning 
    motto += has an end

the parameter C<motto> will have the value 
C<"Everything that has a beginning has an end">. 


=head2 Arrays

Since version 0.99, C<Config::Natural> also supports arrays, using the 
following syntax: 

    fruits = (
        apple
        banana
        kiwi
        orange
    )

Arrays can also be appended using the same syntax as for usual values: 

    fruits = (
        apple
        banana
    )
    fruits += (
        kiwi
        orange
    )

The array C<fruits> now has the same value as in the previous example. 


=head2 Lists

If you need to write several identical records, you can use lists. 
The syntax is:

    list_name {
        parameter = value
        text = -
        This text may be as long as you wish. 
        .
    }

Example: a version history 

    ## that's the version history of Config::Natural :)
    
    history {
        date = 2000.10.10
        version = 0.7.0
        comment = First fully functional release as an independent module.
    }

    history {
        date = 2000.11.04
        version = 0.7.1
        comment = Minor change in the internal structure: options are now grouped.
    }

    history {
        date = 2000.11.05
        version = 0.8.0
        comment = Code cleanup (mainly auto-generation of the options accessors).
        comment = Added list support.
    }

Lists can be nested. Example: 

    machine {
        name = neutron
        sys = linux

        service {
            type = firewall
            importance = critical
       }
    }

    machine {
        name = proton
        sys = linux

        service {
            type = proxy
            importance = low
        }

        service {
            type = router
            importance = medium
       }
    }

Note that list blocks need not to contain exactly the same set of parameters

If you enable the C<auto_create_surrounding_list> option, you can then write 
something like

    flavour = lemon
    flavour = strawberry
    flavour = vanilla

as a shorthand for 

    flavours {
        flavour = lemon
    }

    flavours {
        flavour = strawberry
    }

    flavours {
        flavour = vanilla
    }

As you see, C<Config::Natural> automatically creates a surrounding list 
around the parameter C<"flavour">, and names this list using the plural 
of the list name, i.e. C<"flavours"> (ok, I'm only appending a "s" for 
now C<;)>

Such a construct can be also be nested. 

B<Note:> There must be only one item on each line. 
This means you can't write: 

    line { param = value }

but instead

    line {
      param = value
    }

I don't think it's a big deal, because the aim of C<Config::Natural> 
is to be fast and to read files with a clear and simple syntax. 


=head2 Inclusion

You can include a file using the C<"include"> keyword. For example: 

    # including some other file
    include generic.conf
    
    # now do specific stuff
    debug = 0
    fast = 1

If the argument is the name of a directory, all the files inside that 
directory are included. Check read_source() for more information. 


=head2 Comments

You can use comments in your file. If a line begins with a 
sharp sign C<"#">, it will be ignored. The sharp sign needs not 
being in the first column though. 


=head1 SPECIAL FEATURES

=head2 Filters

C<Config::Natural> offer three filter mechanisms so that you can modify 
the data on-the-fly at two differents moments of the parsing. 

   file.txt             read_source()
   ___________          _________________
  | ...       | =====> | reading file    |
  | foo=hello |        | > for each line |     _____________
  | ...       |        |        X <======|==> |  prefilter  |
  |___________|        |        v        |    |_____________|
                       |   parsing line -|--,
                       |_________________|  |
                                            |
                        param()  <----------'
                        _________________      _____________
                       |         X <=====|==> | data filter |
                       |         v       |    |_____________|
                       |         X <=====|==> |   handler   |
                       |         v       |    |_____________|
                       |  storing value  |
                       |_________________|

=head2 Prefilter

Prefilter occurs before C<Config::Natural> parsing, therefore a prefilter 
receives the current line as it was read from the file. This can be 
used in order to correct some names which otherwise couldn't be parsed 
by C<Config::Natural>, for example names with spaces. Check in the 
F<examples/> directory for sample programs that implements such functions. 

You can set up a prefilter using the C<prefilter()> method, or at 
creation time with the C<prefilter> option. 

=head2 Data filter

Data filter only occurs when affecting values to their parameters. 
This can be used to implement additional features, like a syntax 
for interpolating values. Check in the F<examples/> directory for 
sample programs that implements such functions. 

You can set up a data filter using the C<filter()> method, or at 
creation time with the C<filter> option. 


=head2 Handlers

Handlers only occurs when affecting values to their parameters, 
but instead of being object methods, handlers can be seen as 
"parameters" methods, in that they are bound to a name, and are 
only called when a parameter with that name is affected. 

Handlers are defined with the C<set_handler()> method. 


=head1 PARAMETER PATH

This is a new functionality, introduced in version 0.99. 

A parameter path is a way of referring any parameter, even if 
it's deeply buried inside several layers of nested lists. 
It is used by the method C<value_of()> to provide a much 
easier way to read data hidden in nested lists. 

The parameter path syntax is loosely inspired by XPath:

    path = /level0[index0]/level1[index1]/.../param

Indexes start at zero, like in Perl (and unlike XPath). 
When an index is omitted, C<[0]> is assumed. 

Examples: 

    # same as $config->param('myparam')
    $value = $config->value_of('/myparam');

    # same as $config->param('list')->[0]{myparam}
    $value = $config->value_of(/list[0]/myparam);
    $value = $config->value_of(/list/myparam);

If you want to get back a whole list, instead of a single value, 
use C<[*]> as the last index, and it will return the reference to 
that list. 

    # same as $config->param('list')
    $value = $config->value_of('/list[*]');

    # same as $config->param('list')->[0]{inner_list}
    $value = $config->value_of('/list/inner_list[*]');

This syntax also applies to arrays, so when you read

    operators = (
        Ibuki Maya
        Hyuga Makoto
        Aoba Shigeru
    )

then the following code behaves as expected: 

    print $nerv->value_of("/operators");     # prints "Ibuki Maya"
    print $nerv->value_of("/operators[1]");  # prints "Hyuga Makoto"
    $ref = $nerv->value_of("/operators[*]"); # return the corresponding arrayref. 


=head1 OBJECTS OPTIONS

=head2 Syntax Options

If the default symbols used in the configuration file syntax doesn't 
fit your needs, you can change them using the following methods. 
Of course you must call these I<before> reading the configuration 
files. 

=over 4

=item affectation_symbol

Use this accessor to change the affectation symbol. Default is C<"=">.


=item append_symbol

Use this accessor to change the append symbol. Default is C<"+">.


=item multiline_begin_symbol

Use this accessor to change the multiline begin symbol. Default is C<"-">.


=item multiline_end_symbol

Use this accessor to change the multiline end symbol. Default is C<".">.


=item array_begin_symbol

Use this accessor to change the array begin symbol. Default is C<"(">.


=item array_end_symbol

Use this accessor to change the array end symbol. Default is C<")">.


=item comment_line_symbol

Use this accessor to change the comment symbol. Default is C<"#">.


=item list_begin_symbol

Use this accessor to change the list begin symbol. Default is C<"{">.


=item list_end_symbol

Use this accessor to change the list end symbol. Default is C<"}">.


=item include_symbol

Use this accessor to change the include symbol. Default is C<"include">. 

=back


=head2 Other Options

=over 4

=item auto_create_surrounding_list

Use this accessor to enable or disable the auto creation of surrounding 
lists. Default is 0 (disabled). 


=item case_sensitive

Use this accessor to change the case behaviour. Default is 1 (case sensitive). 


=item read_hidden_files

Use this accessor to allow of forbid C<Config::Natural> to read hidden files 
when reading a directory. Default is 0 (don't read hidden files). 


=item strip_indentation

Use this accessor to enable C<Config::Natural> to automatically strip the 
indentation from multilines values. For example, when this option is 
enabled, the following: 

    text = -
        I thought what I'd do was. 
        I'd pretend I was one of those deaf-mutes or should I?
            --Laughing Man
    .

will be converted in
    
    text = -
I thought what I'd do was. 
I'd pretend I was one of those deaf-mutes or should I?
    --Laughing Man
    .

This option is disabled by default. 

=back


=head1 METHODS

=over 4

=item new ( )

=item new ( [ OPTIONS, ] FILE )

This method creates a new object. 

You can give an optional hashref in order to change settings of the 
object at creation time. Any valid object option can be used here. 

    my $config = new Config::Natural { read_hidden_files => 1 };

You can also give a file name or a file handle, which will call 
read_source() with that argument. 

    # calling with a file name
    my $config = new Config::Natural 'myconfig.conf';
    
    # calling with a file handle
    my $config = new Config::Natural \*DATA;


=item read_source ( I<FILENAME> )

=item read_source ( I<FILEHANDLE> )

This method reads the content of the given file and returns an object that 
contains the data present in that file. The argument can be either a file 
name or a file handle. This is useful if you want to store your parameters 
in your program:

    use Config::Natural;
    my $conf = new Config::Natural \*DATA;
    
    $conf->param(-debug => 1);  ## set debug on
    
    if($conf->param('debug')) {
        print "current options:\n";
        print $conf->dump_param(-prefix => '  ');
    }
    
    # ...
    
    __END__
    ## default values
    verbose = 1
    debug = 0
    die_on_errors = 0

If the argument is a directory name, read_source() then recursively reads 
all the files present in that directory. Invisible files (dot-files) are 
read only when the option C<read_hidden_files> is enabled. 

You can call the read_source() method several times if you want 
to merge the settings from different configuration files. 


=item param ( )

=item param ( I<LIST> )

=item param ( I<HASHREF> )

This is the general purpose manipulating method. It can used to get or set 
the value of the parameters of an object. 

1) Return the list of the parameters: 

    @params = $conf->param;

2) Return the value of a parameter:

    print $conf->param('debug');

3) Return the values of a number of parameters:

    @dbg = $conf->param(qw(debug verbose));

4) Set the value of a parameter:

    ## using CGI.pm-like syntax
    $conf->param(-debug => 0);
    
    ## using a hashref
    $conf->param({ debug => 0 });

5) Set the values of a number of parameters
   
    ## using Perl/Tk-like syntax
    $conf->param(
        -warn_non_existant => 1, 
        -mangle => 0 
    );
    
    ## using a hashref
    $conf->param(
      { 
        warn_non_existant => 1, 
        mangle => 0 
      }
    );


=item param_tree ( )

This method returns a hashref that allows direct access to the tree 
of parameters. 


=item value_of ( I<PARAMETER_PATH> )

This method is an easier way to access the values of the parameters. 
It returns the value of the parameter path given in argument. 
Check L<"PARAMETER PATH"> for more information and some examples.


=item all_parameters ( )

This method returns the list of the parameters of an object.


=item delete ( I<LIST> )

This method deletes the given parameters. 


=item delete_all ( )

This method deletes all the parameters. 


=item clear ( I<LIST> )

This method sets the given parameters to undef. 


=item clear_params ( )

This method sets all the parameters to undef. 


=item dump_param ( I<OPTIONS> )

This method returns a dump of the parameters as a string using the 
current format of the C<Config::Natural> object. It can be used to simply 
print them out, or to save them to a configuration file which can be 
re-read by another C<Config::Natural> object. 

Options are passed as a hashref. 

B<Options>

=over 4

=item *

C<nospace> - If you set this option to true, no space will be printed 
around the affectation symbol. 

=item *

C<prefix> - If you set this option to a string, it will be printed 
before printing each parameter. 

=item * 

C<suffix> - If you set this option to a string, it will be printed 
after printing each parameter. 

=back


=item write_source ( )

=item write_source ( I<FILENAME> [, I<OPTIONS>] )

=item write_source ( I<FILEHANDLE> [, I<OPTIONS>] )

This method writes the current object to the given file name or file 
handle. Remaining options, if any, will be passed unmodified to 
dump_param(). If no argument is given, the file or handle used by 
the last call of read_source() will be used. 


=item filter ( I<CODEREF> )

This method can be used to set a new data filter. 
The subroutine code will be considered as an object method and 
will receive the data as it was read. The return value of the 
function will be used as the actual value. 
For example: 

    sub myfilter {
        my $self = shift;  # important! remember it's a method
        my $data = shift;
        $data =~ s/\s*#.*$//go;  # remove comments appearing on 
        return $data          # an affectation line
    }

    my $conf = new Config::Natural { filter => \&myfilter };


=item prefilter ( I<CODEREF> )

This method can be used to set up a new input prefilter. 
The same rules as for data filters applies, the only difference 
being in that the prefilter can modify the data before 
C<Config::Natural> parses it. 


=item set_handler ( I<PARAM, CODEREF> )

This method can be used to hook a handler to a particular parameter. 
The subroutine code will receive the name of the parameter and the 
value being affected as arguments. The return value of the code will 
be used as the actual value. An example function could look like this: 

    sub crypt_handler {
        my $param = shift;
        my $value = shift;
        return crypt($value, $param);
    }

    $conf->set_handler('passwd', \&crypt_handler);


=item delete_handler ( I<PARAM> )

This method can be used to remove the handler of a parameter. 


=item has_handler ( I<PARAM> )

This method checks whether a parameter has a handler or not. 

=back

=head2 Internal Methods

=over 4

=item exec_handler()

Executes the handler of a parameter.

=item options()

Handles class options. 

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-config-natural@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Natural>. 
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

C<Config::Natural> is Copyright (C)2000-2005 SE<eacute>bastien Aperghis-Tramoni.

This program is free software. You can redistribute it and/or modify it 
under the same terms as Perl itself. 

=cut
