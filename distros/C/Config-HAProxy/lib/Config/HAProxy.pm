package Config::HAProxy;
use 5.010;
use strict;
use warnings;
use Text::Locus;
use Config::HAProxy::Node::Root;
use Config::HAProxy::Node::Section;
use Config::HAProxy::Node::Statement;
use Config::HAProxy::Node::Comment;
use Config::HAProxy::Node::Empty;
use Text::ParseWords;
use File::Basename;
use File::Temp qw(tempfile);
use File::stat;
use Carp;

our $VERSION = '1.02';

my %sections = (
    global => 1,
    defaults => 1,
    frontend => 1,
    backend => 1,
);

sub new {
    my $class = shift;
    my $filename = shift // '/etc/haproxy/haproxy.cfg';
    my $self = bless { _filename => $filename }, $class;
    $self->reset();
    return $self;
}

sub filename { shift->{_filename} }

sub parse {
    my $self = shift;

    open(my $fh, '<', $self->filename)
	or croak "can't open ".$self->filename.": $!";
    my $line = 0;
    $self->reset();
    $self->push($self->tos);
    while (<$fh>) {
	my $locus = new Text::Locus($self->filename, ++$line);
	chomp;
	my $orig = $_;
	s/^\s+//;
	s/\s+$//;

	if ($_ eq "") {
	    $self->tos->append_node(
		new Config::HAProxy::Node::Empty(locus => $locus));
	    next;
	}
	    
	if (/^#.*/) {
	    $self->tos->append_node(
		new Config::HAProxy::Node::Comment(orig => $orig,
						   locus => $locus));
	    next;
	}
 
	my @words = parse_line('\s+', 1, $_);
	my $kw = shift @words;
	if ($sections{$kw}) {
	    my $section =
		new Config::HAProxy::Node::Section(kw => $kw,
						   argv => \@words,
						   orig => $orig,
						   locus => $locus);
	    $self->pop;
	    $self->tos->append_node($section);
	    $self->push($section);
	} else {
	    $self->tos->append_node(
		new Config::HAProxy::Node::Statement(kw => $kw,
						     argv => \@words,
						     orig => $orig,
						     locus => $locus));
	}
    }
    $self->pop;
    close $fh;
    return $self;
}

sub reset {
    my $self = shift;
    $self->{_stack} = [ new Config::HAProxy::Node::Root() ];
}

sub push {
    my $self = shift;
    push @{$self->{_stack}}, @_;
}

sub pop {
    my $self = shift;
    croak "can't pop the root tree" if @{$self->{_stack}} == 1;
    pop @{$self->{_stack}};
}

sub tos {
    my $self = shift;
    $self->{_stack}[-1];
}

sub tree {
    my $self = shift;
    $self->{_stack}[0];
}

sub select {
    my $self = shift;
    $self->tree->select(@_);
}

sub iterator {
    my $self = shift;
    $self->tree->iterator(@_);
}

sub write {
    my $self = shift;
    my $file = shift;
    my $fh;

    if (ref($file) eq 'GLOB') {
	$fh = $file;
    } else {
	open($fh, '>', $file) or croak "can't open $file: $!";
    }

    local %_ = @_;
    my $itr = $self->iterator(inorder => 1);
    
    while (defined(my $node = $itr->next)) {
	my $s = $node->as_string;
	if ($_{indent}) {
	    if ($node->is_comment) {
		if ($_{reindent_comments}) {
		    my $indent = ' ' x ($_{indent} * $node->depth);
		    $s =~ s/^\s+//;
		    $s = $indent . $s;
		}
	    } else {
		my $indent = ' ' x ($_{indent} * $node->depth);
		if ($_{tabstop}) {
		    $s = $indent . $node->kw;
		    for (my $i = 0; my $arg = $node->arg($i); $i++) {
			my $off = 1;
			if ($i < @{$_{tabstop}}) {
			    if (($off = $_{tabstop}[$i] - length($s)) <= 0) {
				$off = 1;
			    }
			}
			$s .= (' ' x $off) . $arg;
		    }
		} else {
		    $s =~ s/^\s+//;
		    $s = $indent . $s;
		}
	    }
	}
	print $fh $s,"\n";
    }

    close $fh unless ref($file) eq 'GLOB';
}

sub save {
    my $self = shift;

    return unless $self->tree;# FIXME
    return unless $self->tree->is_dirty;
    my ($fh, $tempfile) = tempfile('haproxy.XXXXXX',
				   DIR => dirname($self->filename));
    $self->write($fh, @_);
    close($fh);
    
    my $sb = stat($self->filename);
    $self->backup;
    rename($tempfile, $self->filename)
	or croak "can't rename $tempfile to ".$self->tempfile.": $!";
    # This will succeed: we've created the file, so we're owning it.
    chmod $sb->mode & 0777, $self->filename;
    # This will fail unless we are root, let it be so.
    chown $sb->uid, $sb->gid, $self->filename;
    
    $self->tree->clear_dirty
}

sub backup_name {
    my $self = shift;
    $self->filename . '~'
}

sub backup {
    my $self = shift;
    my $backup = $self->backup_name;
    if (-f $backup) {
	unlink $backup
	    or croak "can't unlink $backup: $!"
    }
    rename $self->filename, $self->backup_name
	or croak "can't rename :"
	         . $self->filename
		 . " to "
		 . $self->backup_name
		 . ": $!";
}

1;	
__END__

=head1 NAME

Config::HAProxy - Parser for HAProxy configuration file

=head1 SYNOPSIS

    use Config::HAProxy;
    $cfg = new Config::HAProxy($filename);
    $cfg->parse;

    $name = $cfg->filename;

    @frontends = $cfg->select(name => 'frontend');

    $itr = $cfg->iterator(inorder => 1);
    while (defined($node = $itr->next)) {
        # do something with $node
    }

    $cfg->save;

    $cfg->write($file_or_handle);

    $cfg->backup;
    $name = $self->backup_name;

    $cfg->reset;
    $cfg->push($node);
    $node = $cfg->pop;
    $node = $cfg->tos;
    $node = $cfg->tree;

=head1 DESCRIPTION

The B<Config::HAProxy> class is a parser that converts the B<HAProxy>
configuration file to a parse tree and provides methods for various
operations on this tree, such as: searching, modifying and saving it
to a file.

An object of this class contains a I<parse tree> representing the
configuration read from the file (or created from scratch). Nodes in the
tree can be of four distinct classes:

=over 4

=item Empty    

Represents an empty line.
    
=item Comment

Represents a comment line.
    
=item Statement

Represents a simple statement.    

=item Section

A container, representing a C<compound statement>, i.e. a statement that
contains multiple sub-statements. Compound statements are: B<global>,
B<defaults>, B<frontend>, and B<backend>.    

=back

In addition to these four classes, a special class B<Root> is provided, which
represents the topmost node in the parse tree (i.e. the parent of other nodes).

A set of attributes is associated with each node. Among these, the B<orig>
attribute contains the original line from the configuration file that triggered
creation of this node, and B<locus> contains the location of this line (or
lines, for sections) in the configuration file (as a B<Text::Locus>) object.

These two attributes are meaningful for all nodes. For statement nodes (simple
statements and sections) the B<kw> attribute contains the statement I<keyword>,
and the B<argv> attribute - its arguments. For example, the statement

    server localhost 127.0.0.1:8080

is represented by a node of class B<Config::HAProxy::Node::Statement>, with
C<server> as B<kw> and list (C<localhost>, C<127.0.0.1:8080>) as B<argv>.

Additionally, section nodes provide methods for accessing their subtrees.

For a detailed description of the node class and its methods, please refer to
B<Config::HAProxy::Node>.    
    
=head1 CONSTRUCTOR

    $cfg = new Config::HAProxy($filename);

Creates and returns a new object for manipulating the HAProxy configuration.
Optional B<$filename> specifies the name of the file to read configuration
from. It defaults to F</etc/haproxy/haproxy.cfg>.

=head2 filename

    $s = $cfg->filename;

Returns the configuration file name given when creating the object.
    
=head1 PARSING

=head2 parse

    $cfg->parse;

Reads and parses the configuration file. Croaks if the file does not exist.
Returns B<$cfg>.    

=head1 BUILDING THE PARSE TREE
    
=head2 reset

    $cfg->reset;

Clears the parse tree.

=head2 push

    $cfg->push($node);

Appends the B<$node> (the B<Config::HAProxy::Node> object), to the
end of the parse tree.

=head2 pop

    $node = $cfg->pop;

Removes the tail node from the tree and returns it.

=head1 INSPECTING THE TREE    

=head2 tree

    $node = $cfg->tree;

Returns the top of the tree.

=head2 tos

    $node = $cfg->tos;

Returns the last node in the tree.
    
=head1 SAVING

=head2 save

    $cfg->save;

Saves the parse tree in the configuration file.

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
key B<reintent_comments> is present, and its value is evaluated as true,
then comments are reindented following the rules described above.    

=head1 SEE ALSO

B<Config::HAProxy::Node>,
B<Config::HAProxy::Node::Section>,    
B<Config::HAProxy::Node::Statement>,    
B<Config::HAProxy::Iterator>.

=head1 AUTHOR

Sergey Poznyakoff, E<lt>gray@gnu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Sergey Poznyakoff

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

    
