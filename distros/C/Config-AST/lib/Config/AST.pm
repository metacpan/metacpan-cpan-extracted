# This file is part of Config::AST                            -*- perl -*-
# Copyright (C) 2017-2019 Sergey Poznyakoff <gray@gnu.org>
#
# Config::AST is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# Config::AST is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Config::AST.  If not, see <http://www.gnu.org/licenses/>.

package Config::AST;

use strict;
use warnings;
use Carp;
use Text::Locus;
use Config::AST::Node qw(:sort);
use Config::AST::Node::Section;
use Config::AST::Node::Value;
use Config::AST::Follow;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'sort' => [ qw(NO_SORT SORT_NATURAL SORT_PATH) ] );
our @EXPORT_OK = qw(NO_SORT SORT_NATURAL SORT_PATH);
    
our $VERSION = "1.04";

=head1 NAME

Config::AST - abstract syntax tree for configuration files

=head1 SYNOPSIS

    my $cfg = new Config::AST(%opts);
    $cfg->parse() or die;
    $cfg->commit() or die;

    if ($cfg->is_set('core', 'variable')) {
       ...
    }

    my $x = $cfg->get('file', 'locking');

    $cfg->set('file', 'locking', 'true');

    $cfg->unset('file', 'locking');

=head1 DESCRIPTION

This module aims to provide a generalized implementation of parse tree
for various configuration files. It does not implement parser for any existing
configuration file format. Instead, it provides an API that can be used by
parsers to build internal representation for the particular configuration file
format.

See B<Config::Parser> module for an implementation of a parser based on
this module.

A configuration file in general is supposed to consist of statements of two
kinds: simple statements and sections. A simple statement declares or sets
a configuration parameter. Examples of simple statements are:

    # Bind configuration file:
    file "cache/named.root";

    # Apache configuration file:
    ServerName example.com

    # Git configuration file:
    logallrefupdates = true

A section statement groups together a number of another statements. These
can be simple statements, as well as another sections. Examples of sections
are (with subordinate statements replaced with ellipsis):

    # Bind configuration file:
    zone "." {
       ...
    };

    # Apache configuration file:
    <VirtualHost *:80>
       ...
    </VirtualHost>

    # Git configuration file:
    [core]
       ...

The syntax of Git configuration file being one of the simplest, we will use
it in the discussion below to illustrate various concepts.

The abstract syntax tree (AST) for a configuration file consists of nodes.
Each node represents a single statement and carries detailed information
about that statement, in particular:

=over 4

=item B<locus>

Location of the statement in the configuration. It is represented by an
object of class B<Text::Locus>.

=item order

0-based number reflecting position of this node in the parent section
node.

=item value

For simple statements - the value of this statement.

=item subtree

For sections - the subtree below this section.

=back

The type of each node can be determined using the following node attributes:

=over 4

=item is_section

True if node is a section node.

=item is_value

True if node is a simple statement.

=back

To retrieve a node, address it using its I<full path>, i.e. list of statement
names that lead to this node. For example, in this simple configuration file:

   [core]
       filemode = true

the path of the C<filemode> statement is C<qw(core filemode)>. 

=head1 CONSTRUCTOR
    
    $cfg = new Config::AST(%opts);

Creates new configuration parser object.  Valid options are:

=over 4

=item B<debug> => I<NUM>

Sets debug verbosity level.    

=item B<ci> => B<0> | B<1>

If B<1>, enables case-insensitive keyword matching.  Default is B<0>,
i.e. the keywords are case-sensitive.    

=item B<lexicon> => \%hash

Defines the I<keyword lexicon>.
    
=back    

=head3 Keyword lexicon

The hash reference passed via the B<lexicon> keyword defines the keywords
and sections allowed within a configuration file.  In a simplest case, a
keyword is described as

    name => 1

This means that B<name> is a valid keyword, but does not imply anything
about its properties.  A more complex declaration is possible, in
which the value is a hash reference, containing one or more of the following
keywords:

=over 4

=item mandatory => 0 | 1

Whether or not this setting is mandatory.

=item default => I<VALUE>

Default value for the setting. This value will be assigned if that particular
statement is not explicitly used in the configuration file. If I<VALUE>
is a CODE reference, it will be invoked as a method each time the value is
accessed.

Default values must be pure Perl values (not the values that should appear
in the configuration file). They are not processed using the B<check>
callbacks (see below).    
    
=item array => 0 | 1

If B<1>, the value of the setting is an array.  Each subsequent occurrence
of the statement appends its value to the end of the array.

=item re => I<regexp>

Defines a regular expression which the value must match. If it does not,
a syntax error will be reported.

=item select => I<coderef>

Reference to a method which will be called in order to decide whether to
apply this hash to a particular configuration setting.  The method is
called as 

    $self->$coderef($node, @path)

where $node is the B<Config::AST::Node::Value> object (use
B<$vref-E<gt>value>, to obtain the actual value), and B<@path> is its pathname.
    
=item check => I<coderef>

Defines a method which will be called after parsing the statement in order to
verify its value.  The I<coderef> is called as

    $self->$coderef($valref, $prev_value, $locus)

where B<$valref> is a reference to its value, and B<$prev_value> is the
value of the previous instance of this setting.  The function must return
B<true>, if the value is OK for that setting.  In that case, it is allowed
to modify the value referenced by B<$valref>.  If the value is erroneous,
the function must issue an appropriate error message using B<$cfg-E<gt>error>,
and return 0.
    
=back    

In taint mode, any value that matched B<re> expression or passed the B<check>
function will be automatically untainted.
        
To define a section, use the B<section> keyword, e.g.:

    core => {
        section => {
            pidfile => {
               mandatory => 1
            },
            verbose => {
               re => qr/^(?:on|off)/i
            }
        }
    }

This says that the section named B<core> can have two variables: B<pidfile>,
which is mandatory, and B<verbose>, whose value must be B<on>, or B<off>
(case-insensitive). E.g.:

    [core]
        pidfile = /run/ast.pid
        verbose = off

To accept arbitrary keywords, use B<*>.  For example, the following
declares B<code> section, which must have the B<pidfile> setting
and is allowed to have any other settings as well.    
 
    code => {
       section => {
           pidfile => { mandatory => 1 },
           '*' => 1
       }
    }

Everything said above applies to the B<'*'> as well.  E.g. the following
example declares the B<code> section, which must have the B<pidfile>
setting and is allowed to have I<subsections> with arbitrary settings.

    code => {
       section => {
           pidfile = { mandatory => 1 },
           '*' => {
               section => {
                   '*' => 1
               }
           }
       }
    }

The special entry

    '*' => '*'

means "any settings and any subsections are allowed".

=cut

sub new {
    my $class = shift;
    local %_ = @_;
    my $self = bless { _order => 0 }, $class;
    my $v;
    my $err;

    $self->{_debug} = delete $_{debug} || 0;
    $self->{_ci} = delete $_{ci} || 0;

    if (defined($v = delete $_{lexicon})) {
	if (ref($v) eq 'HASH') {
	    $self->{_lexicon} = $v;
	} else {
	    carp "lexicon must refer to a HASH";
	    ++$err;
	}
    }

    if (keys(%_)) {
	foreach my $k (keys %_) {
	    carp "unknown parameter $k"
	}
	++$err;
    }
    croak "can't create configuration instance" if $err;
    $self->reset;
    return $self;
}

=head2 $cfg->lexicon($hashref)

Returns current lexicon.  If B<$hashref> is supplied, installs it as a
new lexicon.

=cut

sub lexicon {
    my $self = shift;
    if (@_) {
	my $lexicon = shift;
	carp "too many arguments" if @_;
        carp "lexicon must refer to a HASH" unless ref($lexicon) eq 'HASH';
	$self->reset;
        $self->{_lexicon} = $lexicon;
    }
    return $self->{_lexicon};
}

=head1 PARSING

This module provides a framework for parsing, but does not implement parsers
for any particular configuration formats. To implement a parser, the programmer
must write a class that inherits from B<Config::AST>. This class should
implement the B<parse> method which, when called, will actually perform the
parsing and build the AST using methods described in section B<CONSTRUCTING
THE SYNTAX TREE> (see below).

The caller must then perform the following operations

=over 4

=item B<1.> Create an instance of the derived class B<$cfg>.

=item B<2.> Call the B<$cfg-E<gt>parse> method.

=item B<3.> On success, call the B<$cfg-E<gt>commit> method.

=back
    
=head2 $cfg->parse(...)

Abstract method that is supposed to actually parse the configuration file
and build the parse tree from it. Derived classes must overload it.

The must return true on success and false on failure. Eventual errors in
the configuration should be reported using B<error>.

=cut

sub parse {
    my ($self) = @_;
    croak "call to abstract method"
}

=head2 $cfg->commit([%hash])

Must be called after B<parse> to finalize the parse tree. This function
applies default values on settings where such are defined.

Optional arguments control what steps are performed.

=over 4

=item lint => 1

Forse syntax checking.  This can be necessary if new nodes were added to
the tree after parsing.

=item lexicon => I<$hashref>

Override the lexicon used for syntax checking and default value processing.

=back

Returns true on success.
    
=cut

sub commit {
    my ($self, %opts) = @_;
    my $lint = delete $opts{lint};
    my $lexicon = delete $opts{lexicon} // $self->lexicon;
    croak "unrecognized arguments" if keys(%opts);
    if ($lexicon) {
	$self->lint_subtree($lexicon, $self->tree) if $lint;
        $self->fixup_tree($self->tree, $lexicon);
    }
    return $self->{_error_count} == 0;
}

=head2 $cfg->error_count

Returns total number of errors encountered during parsing.

=cut

sub error_count { shift->{_error_count} }

=head2 $cfg->success

Returns true if no errors were detected during parsing.

=cut

sub success { ! shift->error_count }

# Auxiliary function used in commit and lint.
# Arguments:
#   $section - A Config::AST::Node::Section to start fixup at
#   $params  - Lexicon.
#   @path    - Path to $section
sub fixup_tree {
    my ($self, $section, $params, @path) = @_;

    while (my ($k, $d) = each %{$params}) {
	next unless ref($d) eq 'HASH';

	if (exists($d->{default}) && !$section->has_key($k)) {
	    my $n;
	    my $dfl = ref($d->{default}) eq 'CODE'
		        ? sub { $self->${ \ $d->{default} } }
	                : $d->{default};
	    if (exists($d->{section})) {
		$n = new Config::AST::Node::Section(
		               default => 1,
		               subtree => $dfl
		     );
	    } else {
		$n = new Config::AST::Node::Value(
		               default => 1,
		               value => $dfl
		     );
	    }
	    $section->subtree($k => $n);
	}
		
	if (exists($d->{section})) {
	    if ($k eq '*') {
		if (keys(%{$section->subtree})) {
		    while (my ($name, $vref) = each %{$section->subtree}) {
			if (my $sel = $d->{select}) {
			    if ($self->$sel($vref, @path, $name)) {
				next;
			    }
			} elsif ($vref->is_section) {
			    $self->fixup_tree($vref, $d->{section},
					      @path, $name);
			}
		    }
		} else {
		    my $node = new Config::AST::Node::Section;
		    $self->fixup_tree($node, $d->{section}, @path, $k);
		    if ($node->keys > 0) {
			# If the newly created node contains any subnodes
			# after fixup, they were created because syntax
			# contained mandatory variables with default values.
			# Treat sections containing such variables as
			# mandatory and report them.
			my %h;
			foreach my $p (map {
			                   pop @{$_->[0]};
					   join(' ', (@path, $k, @{$_->[0]}))
				       } $node->flatten(sort => SORT_PATH)) {
			    unless ($h{$p}) {
				$self->error("no section matches mandatory [$p]");
				$self->{_error_count}++;
				$h{$p} = 1;
			    }
			}
		    }
		}
	    } else {
		my $node;
		
		unless ($node = $section->subtree($k)) {
		    $node = new Config::AST::Node::Section;
		}
		if ((!exists($d->{select})
		     || $self->${ \ $d->{select} }($node, @path, $k))) {
		    $self->fixup_tree($node, $d->{section}, @path, $k);
		}
		if ($node->keys > 0) {
		    $section->subtree($k => $node);
		}
	    }
	}

	if ($d->{mandatory} && !$section->has_key($k)) {
	    $self->error(exists($d->{section})
			     ? "mandatory section ["
			        . join(' ', @path, $k)
				. "] not present"
		             : "mandatory variable \""
			        . join('.', @path, $k)
			        . "\" not set",
			 locus => $section->locus);
 	    $self->{_error_count}++;
	}	    
    }
}

=head2 $cfg->reset

Destroys the parse tree and clears error count, thereby preparing the object
for parsing another file.    

=cut    
    
sub reset {
    my $self = shift;
    $self->{_error_count} = 0;
    delete $self->{_tree};
}

=head1 METHODS

=head2 $cfg->error($message)

=head2 $cfg->error($message, locus => $loc)

Prints the B<$message> on STDERR.  If B<locus> is given, its value must
be a reference to a valid B<Text::Locus>(3) object.  In that
case, the object will be formatted first, then followed by a ": " and the
B<$message>.    
    
=cut
    
sub error {
    my $self = shift;
    my $err = shift;
    local %_ = @_;
    print STDERR "$_{locus}: " if $_{locus};
    print STDERR "$err\n";
}

=head2 $cfg->debug($lev, @msg)

If B<$lev> is greater than or equal to the B<debug> value used when
creating B<$cfg>, outputs on standard error the strings from @msg,
separating them with a single space character.

Otherwise, does nothing.    

=cut    

sub debug {
    my $self = shift;
    my $lev = shift;
    return unless $self->{_debug} >= $lev;
    $self->error("DEBUG: " . join(' ', @_));
}

=head1 NODE RETRIEVAL

A node is addressed by its path, i.e. a list of names of the configuration
sections leading to the statement plus the name of the statement itself.
For example, the statement:

    pidfile = /var/run/x.pid

has the path

    ( 'pidfile' )

The path of the B<pidfile> statement in section B<core>, e.g.:

    [core]
        pidfile = /var/run/x.pid

is

    ( 'core', 'pidfile' )

Similarly, the path of the B<file> setting in the following configuration
file:    

    [item foo]
        file = bar
    
is
    ( 'item', 'foo', 'bar' )
    
=head2 $node = $cfg->getnode(@path);

Retrieves the AST node referred to by B<@path>. If no such node exists,
returns C<undef>.    

=cut
    
sub getnode {
    my $self = shift;
    
    my $node = $self->{_tree} or return undef;
    for (@_) {
	$node = $node->subtree($self->{_ci} ? lc($_) : $_)
	    or return undef;
    }
    return $node;
}

=head2 $var = $cfg->get(@path);

Returns the B<Config::AST::Node::Value>(3) corresponding to the
configuration variable represented by its path, or C<undef> if the
variable is not set.

=cut    

sub get {
    my $self = shift;
    croak "no variable to get" unless @_;
    if (my $node = $self->getnode(@_)) {
	return $node->value;
    }
}

=head2 $cfg->is_set(@path)

Returns true if the configuration variable addressed by B<@path> is
set.    
    
=cut

sub is_set {
    my $self = shift;
    return defined $self->getnode(@_);
}

=head2 $cfg->is_section(@path)

Returns true if the configuration section addressed by B<@path> is
defined.

=cut

sub is_section {
    my $self = shift;
    my $node = $self->getnode(@_);
    return defined($node) && $node->is_section;
}

=head2 $cfg->is_variable(@path)

Returns true if the configuration setting addressed by B<@path>
is set and is a simple statement.

=cut

sub is_variable {
    my $self = shift;
    my $node = $self->getnode(@_);
    return defined($node) && $node->is_value;
}

=head2 $cfg->tree

    Returns the parse tree.

=cut    

sub tree {
    my $self = shift;
    return $self->{_tree} //= new Config::AST::Node::Section(locus => new Text::Locus);
}

=head2 $cfg->subtree(@path)

Returns the configuration subtree associated with the statement indicated by
B<@path>.

=cut    

sub subtree {
    my $self = shift;
    return $self->tree->subtree(@_);
}

=head1 DIRECT ADDRESSING

Direct addressing allows programmer to access configuration settings as if
they were methods of the configuration class. For example, to retrieve the
node at path    

    qw(foo bar baz)

one can write:

    $node = $cfg->foo->bar->baz

This statement is equivalent to

    $node = $cfg->getnode(qw(foo bar baz))

except that if the node in question does not exist, direct access returns
a I<null node>, and B<getnode> returns C<undef>. Null node is a special node
representing a missing node.  Its B<is_null> method returns true and it can
be used in conditional context as a boolean value, e.g.:

    if (my $node = $cfg->foo->bar->baz) {
        $val = $node->value;
    }

Direct addressing is enabled only if lexicon is provided (either during
creation of the object, or later, via the B<lexicon> method).

Obviously, statements that have names coinciding with one of the methods of
the B<Config::AST> class (or any of its subclasses) can't be used in direct
addressing.  In other words, you can't have a top-level statement called
C<tree> and access it as

    $cfg->tree

This statement will always refer to the method B<tree> of the B<Config::AST>
class.

Another possible problem when using direct access are keywords with dashes.
Currently a kludge is implemented to make it possible to access such
keywords: when looking for a matching keyword, double underscores compare
equal to a single dash.  For example, to retrieve the C<qw(files temp-dir)>
node, use

    $cfg->files->temp__dir;

=cut

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/(?:(.*)::)?(.+)//;
    my ($p, $m) = ($1, $2);
    croak "Can't locate object method \"$m\" via package \"$p\""
	if @_ || !$self->lexicon;
    return Config::AST::Follow->new($self->tree, $self->lexicon)->${\$m};
}

sub DESTROY { }

=head1 CONSTRUCTING THE SYNTAX TREE

The methods described in this section are intended for use by the parser
implementers. They should be called from the implementation of the B<parse>
method in order to construct the tree.    
    
=cut

sub _section_lexicon {
    my ($self, $kw, $name) = @_;

    if (defined($kw)) {
	if (ref($kw) eq 'HASH') {
	    my $synt;
	    if (exists($kw->{$name})) {
		$synt = $kw->{$name};
	    } elsif (exists($kw->{'*'})) {
		$synt = $kw->{'*'};
		if ($synt eq '*') {
		    return { '*' => '*' };
		}
	    } 
	    if (defined($synt)
		&& ref($synt) eq 'HASH'
		&& exists($synt->{section})) {
		return $synt->{section};
	    }
	}
    }
    return
}

use constant TAINT => eval '${^TAINT}';
use constant TESTS => TAINT && defined eval 'require Taint::Util';

=head2 $cfg->add_node($path, $node)

Adds the node in the node corresponding to B<$path>. B<$path> can be
either a list of keyword names, or its string representation, where
names are separated by dots. I.e., the following two calls are equivalent:

    $cfg->add_node(qw(core pidfile), $node)
    
    $cfg->add_node('core.pidfile', $node)

If the node already exists at B<$path>, new node is merged to it according
to the lexical rules.  I.e., for scalar value, new node overwrites the old
one.  For lists, it is appended to the list.

=cut

sub add_node {
    my ($self, $path, $node) = @_;

    unless (ref($path) eq 'ARRAY') {
	$path = [ split(/\./, $path) ]
    }

    my $kw = $self->{_lexicon} // { '*' => '*' };
    my $tree = $self->tree;
    my $pn = $#{$path};
    my $name;
    my $locus = $node->locus;
    for (my $i = 0; $i < $pn; $i++) {
	$name = ${$path}[$i];
	
	unless ($tree->is_section) {
	    $self->error(join('.', @{$path}[0..$i]) . ": not a section");
	    $self->{_error_count}++;
	    return;
	}

	$kw = $self->_section_lexicon($kw, $name);
	unless ($kw) {
	    $self->error(join('.', @{$path}[0..$i]) . ": unknown section");
	    $self->{_error_count}++;
	    return;
	}

	if (my $subtree = $tree->subtree($name)) {
	    $tree = $subtree;
	} else {
	    $tree = $tree->subtree(
		$name => new Config::AST::Node::Section(
		    order => $self->{_order}++,
		    locus => $locus->clone)
		);
	}
    }

    $name = ${$path}[-1];

    my $x = $kw->{$name} // $kw->{'*'};
    if (!defined($x)) {
	$self->error("keyword \"$name\" is unknown", locus => $locus);
	$self->{_error_count}++;
	return;
    }

    if ($node->is_section) {
	if ($tree->has_key($name)) {
	    $tree->locus->union($locus);
	    $tree->subtree($name)->merge($node);
	} else {
	    $tree->subtree($name => $node);
	}
	return $node;
    }

    my $v = $node->value;

    if (ref($x) eq 'HASH') {
	if (exists($x->{section})) {
	    $self->error('"'.join('.', @{$path})."\" must be a section",
			 locus => $locus);
	    $self->{_error_count}++;
	    return;
	}

	my $errstr;
	my $prev_val;
	if ($tree->has_key($name)) {
	    # FIXME: is_value?
	    $prev_val = $tree->subtree($name)->value;
	}
	my $nchecks; # Number of checks passed
	if (exists($x->{re})) {
	    if ($v !~ /$x->{re}/) {
		$self->error("invalid value for $name",
			     locus => $locus);
		$self->{_error_count}++;
		return;
	    }
	    $nchecks++;
	}

	if (my $ck = $x->{check}) {
	    unless ($self->$ck(\$v, $prev_val, $locus)) {
		$self->{_error_count}++;
		return;
	    }
	    $nchecks++;
	}
	if ($nchecks && TESTS) {
	    Taint::Util::untaint($v);
	}

	if ($x->{array}) {
	    if (!defined($prev_val)) {
		$v = [ $v ];
	    } else {
		$v = [ @{$prev_val}, $v ];
	    }
	}
    }

    $tree->locus->union($locus->clone);

    my $newnode;
    if ($newnode = $tree->subtree($name)) {
	$newnode->locus->union($locus);
    } else {
	$newnode = $tree->subtree($name => $node);
    }
    $newnode->order($self->{order}++);
    $newnode->value($v);
    return $newnode;
}

=head2 $cfg->add_value($path, $value, $locus)

Adds a statement node with the given B<$value> and B<$locus> in position,
indicated by $path.

If the setting already exists at B<$path>, the new value is merged to it
according to the lexical rules.  I.e., for scalars, B<$value> overwrites
prior setting.  For lists, it is appended to the list.

=cut    
    
sub add_value {
    my ($self, $path, $value, $locus) = @_;
    $self->add_node($path, new Config::AST::Node::Value(value => $value,
							locus => $locus));
}

=head2 $cfg->set(@path, $value)

Sets the configuration variable B<@path> to B<$value>.    

No syntax checking is performed.  To enforce syntax checking use
B<add_value>.

=cut

sub set {
    my $self = shift;
    my $node = $self->tree;
   
    while ($#_ > 1) {
	croak "not a section" unless $node->is_section; 
	my $arg = shift;
	if (my $n = $node->subtree($arg)) {
	    $node = $n;
	} else {
	    $node = $node->subtree(
		         $arg => new Config::AST::Node::Section
		    );
	}
    }
    
    my $v = $node->subtree($_[0]) ||
	    $node->subtree($_[0] => new Config::AST::Node::Value(
			              order => $self->{_order}++
			            ));
			   
    $v->value($_[1]);
    $v->default(0);
    return $v;
}

=head2 cfg->unset(@path)

Unsets the configuration variable.
    
=cut

sub unset {
    my $self = shift;

    my $node = $self->{_tree} or return;
    my @path;
    
    for (@_) {
	return unless $node->is_section && $node->has_key($_);
	push @path, [ $node, $_ ];
	$node = $node->subtree($_);
    }

    while (1) {
	my $loc = pop @path;
	$loc->[0]->delete($loc->[1]);
	last unless ($loc->[0]->keys == 0);
    }
}    

=head1 AUXILIARY METHODS

=head2 @array = $cfg->names_of(@path)

If B<@path> refers to an existing configuration section, returns a list
of names of variables and subsections defined within that section. Otherwise,
returns empty list. For example, if you have

    [item foo]
       x = 1
    [item bar]
       x = 1
    [item baz]
       y = 2

the call

    $cfg->names_of('item')

will return

    ( 'foo', 'bar', 'baz' )
    
=cut    

sub names_of {
    my $self = shift;
    my $node = $self->getnode(@_);
    return () unless defined($node) && $node->is_section;
    return $node->keys;
}

=head2 @array = $cfg->flatten()

=head2 @array = $cfg->flatten(sort => $sort)    

Returns a I<flattened> representation of the configuration, as a
list of pairs B<[ $path, $value ]>, where B<$path> is a reference
to the variable pathname, and B<$value> is a
B<Config::AST::Node::Value> object.

The I<$sort> argument controls the ordering of the entries in the returned
B<@array>.  It is either a code reference suitable to pass to the Perl B<sort>
function, or one of the following constants:

=over 4

=item NO_SORT

Don't sort the array.  Statements will be placed in an apparently random
order.

=item SORT_NATURAL

Preserve relative positions of the statements.  Entries in the array will
be in the same order as they appeared in the configuration file.  This is
the default.

=item SORT_PATH

Sort by pathname.

=back

These constants are not exported by default.  You can either import the
ones you need, or use the B<:sort> keyword to import them all, e.g.:

    use Config::AST qw(:sort);
    @array = $cfg->flatten(sort => SORT_PATH);
    
=cut

sub flatten {
    my $self = shift;
    $self->tree->flatten(@_);
}       

=head2 $h = $cfg->as_hash

=head2 $h = $cfg->as_hash($map)    

Returns parse tree converted to a hash reference. If B<$map> is supplied,
it must be a reference to a function. For each I<$key>/I<$value>
pair, this function will be called as:

    ($newkey, $newvalue) = &{$map}($what, $key, $value)

where B<$what> is C<section> or C<value>, depending on the type of the
hash entry being processed. Upon successful return, B<$newvalue> will be
inserted in the hash slot for the key B<$newkey>.

If B<$what> is C<section>, B<$value> is always a reference to an empty
hash (since the parse tree is traversed in pre-order fashion). In that
case, the B<$map> function is supposed to do whatever initialization that
is necessary for the new subtree and return as B<$newvalue> either B<$value>
itself, or a reference to a hash available inside the B<$value>. For
example:

    sub map {
        my ($what, $name, $val) = @_;
        if ($name eq 'section') {
            $val->{section} = {};
            $val = $val->{section};
        }
        ($name, $val);
    }
    
=cut

sub as_hash {
    my $self = shift;
    $self->tree->as_hash(@_);
}

=head2 $cfg->canonical(%args)

Returns the canonical string representation of the configuration tree.
For details, please refer to the documentation of this method in class
B<Config::AST::Node>.
    
=cut

sub canonical {
    my $self = shift;
    $self->tree->canonical(@_);
}
    

sub lint_node {
    my ($self, $lexicon, $node, @path) = @_;

    $lexicon = {} unless ref($lexicon) eq 'HASH';
    if (exists($lexicon->{section})) {
	return unless $node->is_section;
    } else {
	return if $node->is_section;
    }

    if (exists($lexicon->{select}) &&
	!$self->${ \ $lexicon->{select} }($node, @path)) {
	return;
    }

    if ($node->is_section) {
	$self->lint_subtree($lexicon->{section}, $node, @path);
    } else {
	my $val = $node->value;
	my %opts = ( locus => $node->locus );
		     
	if (ref($val) eq 'ARRAY') {
	    if ($lexicon->{array}) {
		my @ar;
		foreach my $v (@$val) {
		    if (exists($lexicon->{re})) {
			if ($v !~ /$lexicon->{re}/) {
			    $self->error("invalid value for $path[-1]", %opts);
			    $self->{_error_count}++;
			    next;
			}
		    }
		    if (my $ck = $lexicon->{check}) {
			unless ($self->$ck(\$v, @ar ? $ar[-1] : undef,
					   $node->locus)) { 
			    $self->{_error_count}++;
			    next;
			}
		    }
		    push @ar, $v;
		}
		$node->value(\@ar);
		return;
	    } else {
		$val = pop(@$val);
	    }
	}
	
	if (exists($lexicon->{re})) {
	    if ($val !~ /$lexicon->{re}/) {
		$self->error("invalid value for $path[-1]", %opts);
		$self->{_error_count}++;
		return;
	    }
	}

	if (my $ck = $lexicon->{check}) {
	    unless ($self->$ck(\$val, undef, $node->locus)) {
 		$self->{_error_count}++;
		return;
	    }
	}

	$node->value($val);
    }
}

sub lint_subtree {
    my ($self, $lexicon, $node, @path) = @_;
    
    while (my ($var, $value) = each %{$node->subtree}) {
	if (exists($lexicon->{$var})) {
	    $self->lint_node($lexicon->{$var}, $value, @path, $var);
	} elsif (exists($lexicon->{'*'})) {
	    $self->lint_node($lexicon->{'*'}, $value, @path, $var);
	} elsif ($value->is_section) {
	    next;
	} else {
	    $self->error("keyword \"$var\" is unknown",
			 locus => $value->locus);
 	    $self->{_error_count}++;
	}
    }
}

=head2 $cfg->lint([\%lex])

Checks the syntax according to the keyword lexicon B<%lex> (or
B<$cfg-E<gt>lexicon>, if called without arguments).  On success,
applies eventual default values and returns true.  On errors, reports
them using B<error> and returns false.

This method provides a way to delay syntax checking for a later time,
which is useful, e.g. if some parts of the parser are loaded as modules
after calling B<parse>.    
    
=cut

sub lint {
    my ($self, $lexicon) = @_;
    return $self->commit(lint => 1, lexicon => $lexicon);	
}

=head1 SEE ALSO

B<Config::AST::Node>.

B<Config::Parser>.

=cut    

1;
