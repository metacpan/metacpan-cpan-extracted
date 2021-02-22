package Apache::Config::Preproc;
use parent 'Apache::Admin::Config';
use strict;
use warnings;
use Carp;
use version 0.77;

our $VERSION = '1.07';

sub import {
    my $class = shift;
    if (defined(my $kw = shift)) {
	if ($kw eq ':default') {
	    install_preproc_default()
	} elsif ($kw eq ':optimized') {
	    install_preproc_optimized()
	} else {
	    croak "Unrecognized import parameter: $kw"
	}
    }
    if (@_) {
	croak "Too many import parameters";
    }
    $class->SUPER::import();
}

sub new {
    my $class = shift;
    my $file = shift;
    my $explist = Apache::Admin::Config::Tree::_get_arg(\@_, '-expand')
	|| [ qw(include) ];

    my $self = $class->SUPER::new($file, @_) or return;
    bless $self, $class;
    $self->{_filename} = $file;
    $self->{_options} = \@_;

    eval {
	$self->_preproc($explist);
    };
    if ($@) {
	$Apache::Admin::Config::ERROR = $@;
	return;
    }
    
    return $self;
}

sub filename { shift->{_filename} }

sub dequote {
    my ($self, $str) = @_;
    if ($str =~ s/^"(.*)"$/$1/) {
	$str =~ s/\\"/"/g;
    }
    return $str;
}

sub options { @{shift->{_options}} }

sub _preproc {
    my ($self, $explist) = @_;

    $self->_preproc_section($self,
			  [ map {
			      my ($mod,@arg);
			      if (ref($_) eq 'HASH') {
				  ($mod,my $ref) = each %$_;
				  @arg = @$ref;
			      } elsif (ref($_) eq 'ARRAY') {
				  @arg = @$_;
				  $mod = shift @arg;
			      } else {
				  $mod = $_;
			      }
			      $mod = 'Apache::Config::Preproc::'.$mod;
			      (my $file = $mod) =~ s|::|/|g;
			      require $file . '.pm';
			      $mod->new($self, @arg)
			    } @$explist ]);
}

# As of version 0.95, the Apache::Admin::Config package provides no
# methods for iterating over all configuration file statements, excepting
# the select method with the -which => N argument, which returns Nth
# statement or undef if N is out of range.  This method has two drawbacks:
#
#   1. It iterates over entire statement tree no matter what arguments are
#      given (see Apache/Admin/Config.pm, lines 417-439)
#   2. It makes unnecessary memory allocations (ibid., line 437).
#   3. When N is out of range, the following warning is emitted
#      in -w mode:
#         Use of uninitialized value $_[0] in string at
#         /usr/share/perl5/overload.pm line 119
#      That's because it unreferences the undefined value and passes it
#      to the overload::StrVal method (ibid., line 443).
#
# This means that time complexity of the code below is O(N**2).  This is
# further aggravated by the fact that no method is provided for inline
# modification of the source tree, except for the 'add' method, which again
# iterates over entire tree in order to locate the element, after which
# the new one should be inserted.
#
# Thus, the following default implementation of the _preproc_section function
# is highly inefficient:

sub _preproc_section_default {
    my ($self, $section, $modlist) = @_;

    return unless @$modlist;

    $_->begin_section($section) foreach (@$modlist);
  OUTER:
    for (my $i = 0;
	 defined(my $d = do {
	     local $SIG{__WARN__} = sub {
		 my $msg = shift;
		 warn "$msg" unless $msg =~ /uninitialized/;
	     };
	     $section->select(-which => $i) }); ) {
	foreach my $mod (@$modlist) {
	    if ($mod->expand($d, \my @repl)) {
		my $prev = $d;
		foreach my $r (@repl) {
		    $prev = $section->add($r, -after => $prev);
		}
		$d->unlink;
		next OUTER;
	    }
	    if ($d->type eq 'section') {
		$self->_preproc_section_default($d, $modlist);
	    }
	}
	$i++;
    }
    $_->end_section($section) foreach (@$modlist);
}

# In an attempt to fix the above problems I resort to a kludgy solution,
# which directly modifies the Apache::Admin::Config::Tree namespace
# and defines two missing functions in it: get_nth(N), which returns
# the Nth statement or undef if N is greater than the source tree
# length, and replace_inplace(N, A), which replaces the Nth statement
# with statements from the array A.  With these two methods at hand,
# the following implementation is used:
sub _preproc_section_optimized {
    my ($self, $section, $modlist) = @_;

    return unless @$modlist;

    $_->begin_section($section) foreach (@$modlist);
  OUTER:
    for (my $i = 0; defined(my $d = $section->get_nth($i)); ) {
	foreach my $mod (@$modlist) {
	    if ($mod->expand($d, \my @repl)) {
		$section->replace_inplace($i, @repl);
		next OUTER;
	    }
	    if ($d->type eq 'section') {
		$self->_preproc_section_optimized($d, $modlist);
	    }
	}
	$i++;
    }
    $_->end_section($section) foreach (@$modlist);
}

# The _preproc_section method upon its first invocation selects the
# right implementation to use.  If the version of the Apache::Admin::Config
# module is 0.95 or if the object has attribute {tree}{children} and it is
# a list reference, the function installs the two new methods in the
# Apache::Admin::Config::Tree namespace and selects the optimized
# implementation.  Otherwise, the default implementation is used.
#
# The decision can be forced when requiring the module.  To select the
# default implementation, do
#
#   use Apache::Config::Preproc qw(:default);
#
# To select the optimized implementation:
#
#   use Apache::Config::Preproc qw(:optimized);
#
sub _preproc_section {
    my $self = shift;
    unless ($self->can('_preproc_section_internal')) {
	if ((version->parse($Apache::Admin::Config::VERSION) == version->parse('0.95')
	    || (exists($self->{children}) && ref($self->{tree}{children}) eq 'ARRAY'))) {
	    install_preproc_optimized()
	} else {
	    install_preproc_default()
	}
    }
    $self->_preproc_section_internal(@_);
}

sub install_preproc_optimized {
    no warnings 'once';
    *{Apache::Admin::Config::Tree::get_nth} = sub {
	my ($self, $n) = @_;
	if ($n < @{$self->{children}}) {
	    return $self->{children}[$n];
	}
	return undef
    };
    *{Apache::Admin::Config::Tree::replace_inplace} = sub {
	my ($self, $n, @items) = @_;
	splice @{$self->{children}}, $n, 1,
	       map { $_->{parent} = $self; $_ } @items;
    };

    *{_preproc_section_internal} = \&_preproc_section_optimized;
}

sub install_preproc_default {
    *{_preproc_section_internal} = \&_preproc_section_default;
}

1;
__END__

=head1 NAME

Apache::Config::Preproc - Preprocess Apache configuration files

=head1 SYNOPSIS

    use Apache::Config::Preproc;
    
    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
             -expand => [ qw(include compact macro ifmodule ifdefine) ] 
             or die $Apache::Admin::Config::ERROR;

=head1 DESCRIPTION

B<Apache::Config::Preproc> reads and parses Apache configuration
file, expanding the syntactic constructs selected by the B<-expand> option.
In the simplest case, the argument to that option is a reference to the
list of names. Each name in the list identifies a module responsible for
processing specific Apache configuration keywords. For convenience, most
modules are named after the keyword they process, so that, e.g. B<include> is
responsible for inclusion of the files listed with B<Include> and
B<IncludeOptional> statements. The list of built-in module names follows:    

=over 4

=item B<compact>

Removes empty lines and comments.

=item B<include>

Expands B<Include> and B<IncludeOptional> statements by replacing them
with the content of the corresponding files.

=item B<ifmodule>

Expands the B<E<lt>IfModuleE<gt>> statements.

=item B<ifdefine>
    
Expands the B<E<lt>IfDefineE<gt>> statements.

=item B<locus>

Attaches file location information to each node in the parse tree.    
    
=item B<macro>

Expands the B<E<lt>MacroE<gt>> statements.    

=back

See the section B<MODULES> for a detailed description of these modules.

More expansions can be easily implemented by supplying a corresponding
expansion module (see the section B<MODULE INTERNALS> below).

If the B<-expand> argument is not supplied, the following default is
used:

    [ 'include' ]
    
The rest of methods is inherited from B<Apache::Admin::Config>.

=head1 IMPORT

The package provides two implementations of the main preprocessing
method.  The default implementation uses only the documented methods
of the base B<Apache::Admin::Config> class and due to its deficiences
shows the O(N**2) time complexity.  The optimized implementations does
some introspection into the internals of the base class, which allow it
to reduce the time complexity to O(N).  Whenever possible, the optimized
implementation is selected.  You can, however, force using the particular
implementation by supplying keywords to the C<use> statement.  To
select the default implementation:

    use Apache::Config::Preproc qw(:default);

To select the optimized implementation:

    use Apache::Config::Preproc qw(:optimized);

See the source code for details.

=head1 CONSTRUCTOR

=head2 new

    $obj = new Apache::Config::Preproc $file,
          [-expand => $modlist],
          [-indent => $integer], ['-create'], ['-no-comment-grouping'],
          ['-no-blank-grouping']

Reads the Apache configuration file from I<$file> and preprocesses it.
The I<$file> argument can be either the file name or file handle.

The keyword arguments are:

=over 4

=item B<-expand> =E<gt> I<$arrayref>

Define what expansions are to be performed. B<$arrayref> is a reference to
array of module names with optional arguments. To supply arguments,
use either a list reference where the first element is the module
name and rest of elements are arguments, or a hash reference with the name
of the module as key and a reference to the list of arguments as its value.
Consider, for example:

    -expand => [ 'include', { ifmodule => { probe => 1 } } ]

    -expand => [ 'include', [ 'ifmodule', { probe => 1 } ] ]

Both constructs load the B<include> module with no specific arguments,
and the B<ifmodule> module with the arguments B<probe =E<gt> 1>.
    
See the B<MODULES> section for a discussion of built-in modules and allowed
arguments.    

A missing B<-expand> argument is equivalent to

    -expand => [ 'include' ]
    
=back

Rest of arguments is the same as for the B<Apache::Admin::Config> constructor:

=over 4    
    
=item B<-indent> =E<gt> I<$n>

Enables reindentation of the configuration content. The B<$n> argument
is the indenting amount per level of nesting. Negative value means
indent with tab characters.    

=item B<-create>

If present I<$file> is a pathname of unexisting file, don't return an
error.

=item B<-no-comment-grouping>

Disables grouping of successive comments into one C<comment> item.
Useless if the B<compact> expansion is enabled.    

=item B<-no-blank-grouping>

Disables grouping of successive empty lines into one C<blank> item.
Useless if the B<compact> expansion is enabled.    
    
=back

=head1 METHODS

All methods are inherited from B<Apache::Admin::Config>.

Additional methods:

=head2 filename

Returns the name of the configuration file.

=head2 options

Returns the list of options passed to the constructor when creating
the object.    
    
=head1 MODULES

The preprocessing phases to be performed on the parsed configuration text are
defined by the B<-expand> argument. Internally, each name in its argument
list causes loading of a Perl module responsible for this particular phase.
Arguments to the constructor can be supplied using any of the following
constructs:

       { NAME => [ ARG, ...] }

or

       [ NAME, ARG, ... ]

    
This section describes the built-in modules and their arguments.

=head2 compact

The B<compact> module eliminates empty and comment lines. The constructor
takes no arguments.    
    
=head2 include

Processes B<Include> and B<IncludeOptional> statements and replaces them
with the contents of the files supplied in their argument. If the latter
is not an absolute file name, it is searched in the server root directory.

The following keyword arguments can be used to set the default server root
directory:

=over 4

=item B<server_root =E<gt>> I<DIR>

Sets default server root value to I<DIR>.

=item B<probe =E<gt>> I<LISTREF> | B<1>

Determines the default server root value by analyzing the output of
B<httpd -V>. If I<LISTREF> is given, it contains alternative pathnames
of the Apache B<httpd> binary. Otherwise, 

    probe => 1

is a shorthand for

    probe => [qw(/usr/sbin/httpd /usr/sbin/apache2)]
        
=back

When the B<ServerRoot> statement is seen, its value overwrites any
previously set server root directory. 

=head2 ifmodule

Processes B<IfModule> statements. If the statement's argument evaluates to
true, it is replaced by the statements inside it. Otherwise, it is removed.
Nested statements are allowed. The B<LoadModule> statements are examined in
order to evaluate the argument.

The constructor understands the following arguments:

=over 4

=item B<preloaded =E<gt>> I<LISTREF>

Supplies a list of preloaded module names. You can use this argument to
pass a list of modules linked statically in your version of B<httpd>.

=item B<probe =E<gt>> I<LISTREF> | B<1>

Provides an alternative way of handling statically linked Apache modules.
If I<LISTREF> is given, each its element is treated as the pathname of
the Apache B<httpd> binary. The first of them that is found is run with
the B<-l> option to list the statically linked modules, and its output
is parsed.

The option

    probe => 1

is a shorthand for

    probe => [qw(/usr/sbin/httpd /usr/sbin/apache2)]

=back

=head2 ifdefine

Eliminates the B<Define> and B<UnDefine> statements and expands the
B<E<lt>IfDefineE<gt>> statements in the Apache configuration parse
tree. Optional arguments to the constructor are treated as the names
of symbols to define (similar to the B<httpd> B<-D> options). Example:   

    -expand => [ { ifdefine => [ qw(SSL FOREGROUND) ] } ]

=head2 locus

Attaches to each node in the parse tree a L<Text::Locus> object
which describes the location of the corresponding statement in the source
file.  The location for each node can be accessed via the B<locus> method.
E.g. the following prints location and type of each statement:

    $x = new Apache::Config::Preproc '/etc/httpd.conf',
                                     -expand => [ qw(locus) ];

    foreach ($x->select) {
        print $_->locus
    }
    
See L<Text::Locus> for a detailed discussion of the locus object and its
methods.

=head2 macro

Processes B<Macro> and B<Use> statements (see B<mod_macro>).  B<Macro>
statements are removed. Each B<Use> statement is replaced by the expansion
of the macro named in its argument.

The constructor accepts the following arguments:
    
=over 4

=item B<keep =E<gt>> I<$listref>

List of macro names to exclude from expanding. Each B<E<lt>MacroE<gt>> and
B<Use> statement with a name from I<$listref> as its first argument will be
retained in the parse tree.

As a syntactic sugar, I<$listref> can also be a scalar value. This is
convenient when a single macro name is to be retained.    

=back
    
=head1 MODULE INTERNALS 

Each keyword I<phase> listed in the B<-expand> array causes loading of the
package B<Apache::Config::Preproc::I<phase>>.  This package must inherit
from B<Apache::Config::Preproc::Expand> and overload at least the
B<expand> method.  See the description of B<Apache::Config::Preproc::Expand>
for a detailed description.

=head1 EXAMPLE

    my $obj = new Apache::Config::Preproc('/etc/httpd/httpd.conf',
                   -expand => [qw(compact include ifmodule macro)],
                   -indent => 4) or die $Apache::Admin::Config::ERROR;
    print $obj->dump_raw

This snippet loads the Apache configuration from file
F</etc/httpd/httpd.conf>, performs all the built-in expansions, and prints
the result on standard output, using 4 character indent for each additional
level of nesting.    

=head1 SEE ALSO

L<Apache::Admin::Config>

L<Apache::Config::Preproc::compact>

L<Apache::Config::Preproc::ifdefine>

L<Apache::Config::Preproc::ifmodule>

L<Apache::Config::Preproc::include>

L<Apache::Config::Preproc::locus>

L<Apache::Config::Preproc::macro>

=cut
    
    
    
