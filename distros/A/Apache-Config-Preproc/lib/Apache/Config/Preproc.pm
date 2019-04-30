package Apache::Config::Preproc;
use parent 'Apache::Admin::Config';
use strict;
use warnings;
use Carp;

our $VERSION = '1.03';

sub new {
    my $class = shift;
    my $file = shift;
    my $explist = Apache::Admin::Config::Tree::_get_arg(\@_, '-expand')
	|| [ qw(include) ];

    my $self = $class->SUPER::new($file, @_) or return;
    bless $self, $class;
    $self->{_options} = \@_;

    eval {
	return unless $self->_preproc($explist);
    };
    if ($@) {
	$Apache::Admin::Config::ERROR = $@;
	return;
    }
    
    return $self;
}

sub dequote {
    my ($self, $str) = @_;
    if ($str =~ s/^"(.*)"$/$1/) {
	$str =~ s/\\"/"/g;
    }
    return $str;
}

sub options { shift->{_options} }

sub _preproc {
    my ($self, $explist) = @_;

    return 1 unless @$explist;
    
    return $self->_preproc_section($self,
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

sub _preproc_section {
    my ($self, $section, $modlist) = @_;

  OUTER:
    for (my $i = 0; defined(my $d = $section->select(-which => $i)); ) {
	foreach my $mod (@$modlist) {
	    my @repl;
	    if ($mod->expand($d, \@repl)) {
		my $prev = $d;
		foreach my $r (@repl) {
		    $prev = $section->add($r, -after => $prev);
		}
		$d->unlink;
		next OUTER;
	    }
	    if ($d->type eq 'section') {
		$self->_preproc_section($d, $modlist);
	    }
	}
	$i++;
    }
    return 1;
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
module B<Apache::Config::Preproc::I<phase>>. This module must provide the
following methods:

=head2 new($conf, ...)

Class constructor. The B<$conf> argument is the configuration file object
(B<Apache::Config::Preproc>). Rest are constructor arguments provided with
the module name in the B<-expand> list.    

=head2 expand

This method must perform actual expansion of a subtree of the parse tree.
It is called as:

    $phase->expand($subtree, $repl)

Its arguments are:

=over 4

=item $subtree

The subtree to be processed.

=item $repl

A reference to array of items (of the same type as I<$subtree>,
i.e. B<Apache::Admin::Config> or B<Apache::Admin::Config::Tree>) where
expansion is to be stored.

=back

The function returns true if it did process the I<$subtree>. In this case,
the subtree will be removed from the parse tree and the items from B<@$repl>
will be inserted in its place. Thus, to simply remove the I<$subtree> the
B<expand> method must return true and not touch I<$repl>. For example, the
following is the B<expand> method definition from the
B<Apache::Config::Preproc::compact> module:

    sub expand {
	my ($self, $d, $repl) = @_;
	return $d->type eq 'blank' || $d->type eq 'comment';
    }

Notice, that B<expand> does not need to recurse into section objects. This
is taken care of by the caller.

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

B<Apache::Admin::Config>(3).    
    
=cut
    
    
    
