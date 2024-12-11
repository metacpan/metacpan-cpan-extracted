package Config::Pound;
use strict;
use warnings;
use parent 'Config::Proxy';

sub new {
    my $class = shift;
    return $class->SUPER::new('pound', @_);
}

1;
=head1 NAME

Config::Pound - Parser for Pound configuration file

=head1 SYNOPSIS

    use Config::Pound;
    $cfg = new Config::Pound([$filename, $linter_program]);
    $cfg->parse;

    $name = $cfg->filename;

    @listeners = $cfg->select(name => 'ListenHTTP');

    $itr = $cfg->iterator(inorder => 1);
    while (defined($node = $itr->next)) {
	# do something with $node
    }

    $cfg->lint(enable => 1, command => 'pound -c -f',
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

The B<Config::Pound> class is a parser that converts the B<Pound>
configuration file to a parse tree and provides methods for various
operations on this tree, such as: searching, modifying and saving it
to a file.

An object of this class contains a I<parse tree> representing the
configuration read from the file (or created from scratch).  See
L<Config::Proxy/PARSE TREE>, for a detailed discussion.  The following
describes nodes, specific for B<Pound> configuration files:

=over 4

=item IP	(L<Config::Pound::Node::IP>)

Objects of this type represent IP addresses or CIDRs from an
B<ACL> section in Pound configuration section.

=item Section	(L<Config::Pound::Node::Section>)

A container, representing a C<compound statement>, or C<section>: a
statement that contains multiple sub-statements. Examples of compound
statements in B<Pound> configuration file are: B<ListenHTTP>,
B<Section>, and B<Backend> (the list is not exhaustive).

=item Verbatim	(L<Config::Pound::Node::Verbatim>)

Objects of this class represent verbatim context embedded in
a Pound configuration.  Currently it is used to represent contents of
B<ConfigText> statement in B<Resolver> section.

=back

=head1 CONSTRUCTOR

    $cfg = new Config::Pound([$filename, $linter]);

Creates and returns a new object for manipulating Pound configuration file.
Optional B<$filename> specifies the name of the file to read configuration
from. It defaults to F</etc/pound/pound.cfg>.

Optional B<$linter> parameter supplies a shell command to be called in order
to check configuration file syntax.  The command will be called by B<save> and
B<write> methods before saving the configuration file.  See
L<Config::Proxy/save> and L<Config::Proxy/write>.  Default linter command
is F<pound -c -f>.

=head1 METHODS AND ATTRIBUTES

See L<Config::Proxy>, for a detailed discussion of these.

=head1 SEE ALSO

L<Config::Proxy>,
L<Config::Proxy::Node>,
L<Config::Proxy::Node::Comment>,
L<Config::Proxy::Node::Empty>,
L<Config::Pound::Node::IP>,
L<Config::Proxy::Node::Root>
L<Config::Pound::Node::Section>,
L<Config::Proxy::Node::Statement>,
L<Config::Pound::Node::Verbatim>,
L<Config::Proxy::Iterator>.

=head1 AUTHOR

Sergey Poznyakoff, E<lt>gray@gnu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023, 2024 by Sergey Poznyakoff

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
