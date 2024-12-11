package Config::Proxy::Impl::haproxy;
use 5.010;
use strict;
use warnings;
use parent 'Config::Proxy::Base';
use Text::Locus;
use Config::Proxy::Node::Root;
use Config::Proxy::Node::Section;
use Config::Proxy::Node::Statement;
use Config::Proxy::Node::Comment;
use Config::Proxy::Node::Empty;
use Text::ParseWords;
use Carp;

our $VERSION = '1.0';

my %sections = (
    global => 1,
    defaults => 1,
    frontend => 1,
    backend => 1,
    resolvers => 1
);

sub new {
    my $class = shift;
    return $class->SUPER::new(shift // '/etc/haproxy/haproxy.cfg', 'haproxy -c -f');
}

sub parse {
    my $self = shift;

    open(my $fh, '<', $self->filename)
	or croak "can't open ".$self->filename.": $!";
    my $line = 0;
    $self->reset();
    my $cur = $self->tree;
    while (<$fh>) {
	my $locus = new Text::Locus($self->filename, ++$line);
	chomp;
	my $orig = $_;
	s/^\s+//;
	s/\s+$//;

	if ($_ eq "") {
	    $cur->append_node(
		new Config::Proxy::Node::Empty(orig => $orig,
					       locus => $locus));
	    next;
	}

	if (/^#.*/) {
	    $cur->append_node(
		new Config::Proxy::Node::Comment(orig => $orig,
						 locus => $locus));
	    next;
	}

	my @words = parse_line('\s+', 1, $_);
	my $kw = shift @words;
	if ($sections{$kw}) {
	    my $section =
		new Config::Proxy::Node::Section(kw => $kw,
						 argv => \@words,
						 orig => $orig,
						 locus => $locus);
	    $self->tree->append_node($section);
	    $cur = $section;
	} else {
	    $cur->append_node(
		new Config::Proxy::Node::Statement(kw => $kw,
						   argv => \@words,
						   orig => $orig,
						   locus => $locus));
	}
    }
    close $fh;
    return $self;
}

sub declare_section {
    my ($class, $name) = @_;
    $sections{$name} = 1;
}

sub undeclare_section {
    my ($class, $name) = @_;
    $sections{$name} = 0;
}

1;
__END__

=head1 NAME

Config::Proxy::Impl::haproxy - Configuration parser implementation for HAProxy.

=head1 SYNOPSIS

    use 'Config::Proxy';

    my $cfg = new Config::Proxy('haproxy' [, $filename, $linter]);

=head1 DESCRIPTION

This class implements configuration parser for B<HAProxy> proxy
configuration file.  Please refer to L<Config::HAProxy> for a detailed
description.

=head1 SEE ALSO

L<Config::HAProxy>.

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
