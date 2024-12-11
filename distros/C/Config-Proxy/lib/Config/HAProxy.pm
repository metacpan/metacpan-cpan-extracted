package Config::HAProxy;
use strict;
use warnings;
use parent 'Config::Proxy';

my $impl = 'haproxy';

sub new {
    my $class = shift;
    return $class->SUPER::new($impl, @_);
}

sub declare_section {
    my $class = shift;
    $class->SUPER::load($impl, 'declare_section', @_);
}

sub undeclare_section {
    my $class = shift;
    $class->SUPER::load($impl, 'undeclare_section', @_);
}

1;
__END__

=head1 NAME

Config::HAProxy - Parser for HAProxy configuration file

=head1 SYNOPSIS

    use Config::HAProxy;
    $cfg = new Config::HAProxy([$filename, $lint_program]);
    $cfg->parse;

    $name = $cfg->filename;

    @frontends = $cfg->select(name => 'frontend');

    $itr = $cfg->iterator(inorder => 1);
    while (defined($node = $itr->next)) {
	# do something with $node
    }

    $cfg->lint(enable => 1, command => 'haproxy -c -f',
	       path => '/sbin:/usr/sbin')

    $cfg->save(%hash);

    $cfg->write($file_or_handle, %hash);

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
configuration read from the file (or created from scratch).
See L<Config::Proxy/PARSE TREE>, for a detailed discussion.

=head1 CONFIGURATION SECTIONS

By default, the following four HAProxy keywords begin I<compound
statements> (or I<sections>): B<backend>, B<defaults>, B<frontend>,
B<global>, B<resolvers>.  If need be, this list can be modified using the
following class methods:

=head2 declare_section

    $cfg = Config::HAProxy->declare_section($name)

Declares B<$name> as a top-level section.

=head2 undeclare_section

    $cfg = Config::HAProxy->undeclare_section($name)

Cancels declaration of B<$name> as a section.

=head1 CONSTRUCTOR

    $cfg = new Config::HAProxy([$filename, $linter]);

Creates and returns a new object for manipulating the HAProxy configuration.
Optional B<$filename> specifies the name of the file to read configuration
from. It defaults to F</etc/haproxy/haproxy.cfg>.  Optional B<$linter>
parameter supplies a shell command to be called in order to check 
configuration file syntax.  The command will be called by B<save> and
B<write> methods before saving the configuration file.  See
L<Config::Proxy/save> and L<Config::Proxy/write>.  Default linter command
is F<haproxy -c -f>.

=head1 METHODS AND ATTRIBUTES

See L<Config::Proxy>, for a detailed discussion of these.

=head1 SEE ALSO

L<Config::Proxy>,
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
