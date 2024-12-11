package Config::Proxy;
use strict;
use warnings;
use Carp;

our $VERSION = '1.0';

sub load {
    my $class = shift;
    my $impl = shift or croak "proxy implementation not supplied";
    my $method = shift // 'new';
    my $modname = __PACKAGE__ . '::Impl::' . $impl;
    my $modpath = $modname;
    $modpath =~ s{::}{/}g;
    $modpath .= '.pm';
    my $self = eval {
	require $modpath;
	$modname->${ \$method }(@_);
    };
    if ($@) {
	if ($@ =~ /Can't locate $modpath/) {
	    croak "unsupported proxy implementation: $impl"
	} else {
	    croak $@
	}
    }
    return $self;
}

sub new {
    my $class = shift;
    my $impl = shift;
    my $self = $class->load($impl, 'new', @_);
    $self->reset();
    $self
}

1;	
__END__

=head1 NAME

Config::Proxy - Loader class for HTTP proxy configuration parsers.

=head1 DESCRIPTION

This package provides a mechanism for parsing and editing configuration
files of two HTTP proxy servers: B<HAProxy> and B<Pound>.  It is extensible,
so that support for another proxy implementation can be easily added.

=head1 CONSTRUCTOR

   $cfg = new Config::Proxy($impl, [$filename, $linter])

Loads proxy parser class implementation B<$impl>, invokes its B<new>
method with the given arguments, and returns the result.  Implementations
are stored as Perl sources in F<B<Config/Proxy/Impl/>I<$impl>B<.pm>>.  As
of this version, two implementations are available:

=over 4

=item B<haproxy>

Parses B<HAProxy> configuration file.  Refer to L<Config::HAProxy>, for
a detailed discussion.

=item B<pound>

Parses B<Pound> configuration file.  Refer to L<Config::Pound>, for
a detailed discussion.

=back

The B<$filename> parameter gives the name of the configuration file to use.

B<$linter> is a shell command that will be used to check the modified
configuration file syntax, before writing it to disk file (used by
B<write> and B<save> methods, see below).  The command will be called with the
configuration file name as its argument.  Implementations provide default
values for these two parameters.

Normally, this constructor is not invoked directly.  Instead, either
B<Config::HAProxy> of B<Config::Pound> constructors are used.

The returned B<$cfg> object provides the following methods:

=head1 ATTRIBUTES

=head2 filename

    $s = $cfg->filename;

Returns the configuration file name given when creating the object.

=head1 PARSE TREE

The parse tree consists of I<nodes>, each node representing a single
configuration statement.  Given that the created object can be used
to edit the configuration file and save it after modification, empty
lines and comments are treated as statements and included in the
parse tree.  The tree consists of nodes of the following types (each
being a derivative of L<Config::Proxy::Node> class).

=over 4

=item Comment	(L<Config::Proxy::Node::Comment>)

Represents a comment line.

=item Empty	(L<Config::Proxy::Node::Empty>)

Represents an empty line.

=item Root	(L<Config::Proxy::Node::Root>)

This class represents the topmost node in the parse tree (i.e. the parent
of other nodes).

=item Section	(L<Config::Proxy::Node::Section>)

A container, representing a C<compound statement>, or C<section>: a
statement that contains multiple sub-statements.

=item Statement	(L<Config::Proxy::Node::Statement>)

Represents a simple statement.

=back

A set of attributes is associated with each node. Attributes common for
all node types are:

=over 4

=item B<kw>

Keyword under which the statement appears in the configuration file.

=item B<argv>

Arguments, given to the statement.  These are parsed and split according
to the syntax of the corresponding proxy configuration file.  The B<argv>
attribute keeps the resulting argument list.

=item B<orig>

Original line from the configuration file that this node represents.  The line
is saved verbatim, with leading and trailing whitespace preserved, but without
terminated newline character.

=item B<locus>

Location of this line (or lines, for sections) in the configuration file (as
a B<Text::Locus>) object.

=item B<parent>

Points to the parent node.

=item B<index>

A 0-based index of this node in its parent node.

=back

For a detailed discussion of these, see L<Config::Proxy::Node>.

Some node classes provide additional attributes and methods.  See
L<Config::Proxy::Node::Section>, L<Config::Proxy::Node::Root>,
for a detailed discussion of these.

Implementations may also provide additional node types, as does, for
example, B<Config::Pound>.

A parse tree can either be produced as a result of configuration file
parsing, or built from scratch.

=head1 CONFIGURATION FILE PARSING

=head2 parse

    $cfg->parse;

Reads and parses the configuration file. Croaks if the file does not exist.
Returns B<$cfg>.

=head1 BUILDING THE PARSE TREE

To build or modify the parse tree, use the following methods of its
B<$cfg-E<gt>tree> attribute or its subnodes: B<append_node>,
B<append_node_nonempty>, B<insert_node>, B<delete_node>.
Refer to L<Config::Proxy::Node::Section/METHODS>, for a detailed discussion
of these.

Additional functions:

=head2 reset

    $cfg->reset;

Clears the parse tree.

=head1 INSPECTING THE TREE

=head2 tree

    $node = $cfg->tree;

Returns the top node (B<Config::Proxy::Node::Root>) of the tree.

=head2 select

    @nodes = $cfg->select(%conditions)

Select and return all nodes matching the given I<%conditions>.  For a detailed
description of I<%conditions>, see L<Config::Proxy::Node::Section/select>.

=head2 iterator

    $itr = $node->iterator(@args);

Returns iterator for all nodes in the tree. See L<Config::Proxy::Iterator>, for
a detailed discussion.

=head1 SAVING

=head2 lint

    $command = $cfg->lint();
    $cfg->lint(bool);
    $cfg->lint(%hash);

Configures syntax checking, which is performed by the B<save> method prior
to writing configuration file to disk, and inspects its settings.

Called without arguments, returns the currently configured syntax-checking
command.  If syntax checking is disabled, returns B<undef>.

Called with a single boolean value, enables syntax-checking, if the value
is true, or disables it, if it is false.

When called with a hash as argument, configures syntax checking. Allowed
keys are:

=over 4

=item B<enable =E<gt> I<BOOL>>

If I<BOOL> is 0, disables syntax check.  Default is 1.

=item B<command =E<gt> I<CMD>>

Defines the shell command to use for syntax check. The command will be run
as

    CMD FILE

where I<FILE> is the name of the Pound configuration file to check.

Default value is implementation-specific.

=item B<path =E<gt> I<PATH>>

Sets the search path for the syntax checker. I<PATH> is a colon-delimited
list of directories. Unless the first word of B<command> is an absolute
file name, it will be looked for in these directories. The first match
will be used. Default is system B<$PATH>.

=back

When called this way, the method returns the syntax-checker command name, if
syntax checking is enabled, and B<undef> otherwise.

=head2 save

    $cfg->save(%hash);

Saves the parse tree to the configuration file. Syntax check will be run
prior to saving (unless previously disabled). If syntax errors are discovered,
the method will B<croak> with a diagnostic message starting with words
C<Syntax check failed:>.

If I<%hash> contains a non-zero B<dry_run> value, B<save> will only run syntax
check, without actually saving the file. If B<$cfg-E<gt>lint(enable =E<gt> 0)>
was called previously, this is a no-op.

Other keys in I<%hash> are the same as in B<write>, described below.

=head2 write

    $cfg->write($file, %hash);

Writes configuration to the named file or file handle. First argument
can be a file name, file handle or a string reference. If it is the
only argument, the original indentation is preserved. Otherwise, if
B<%hash> controls the indentation of the output. It must contain at least
the B<indent> key, which specifies the amount of indentation per nesting
level. If B<tabstop> key is also present, its value must be a reference to
 the list of tabstop columns. For each statement with arguments, this array
is consulted to determine the column number for each subsequent argument.
Arguments are zero-indexed. Starting column where the argument should be
placed is determined as B<$tabstop[$i]>, where B<$i> is the argument index.
Arguments with B<$i> greater than or equal to B<@tabstop> are appended to
the resulting output, preserving their original offsets.

Normally, comments retain their original indentation. However, if the
key B<reindent_comments> is present, and its value is evaluated as true,
then comments are reindented following the rules described above.

=head1 SEE ALSO

L<Config::HAProxy>,
L<Config::Pound>,
L<Config::Proxy::Node>,
L<Config::Proxy::Node::Comment>,
L<Config::Proxy::Node::Empty>,
L<Config::Proxy::Node::Root>,
L<Config::Proxy::Node::Section>,
L<Config::Proxy::Node::Statement>,
L<Config::Proxy::Iterator>.

=head1 AUTHOR

Sergey Poznyakoff, E<lt>gray@gnu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, 2024 by Sergey Poznyakoff

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

It is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this library. If not, see <http://www.gnu.org/licenses/>.

=cut
