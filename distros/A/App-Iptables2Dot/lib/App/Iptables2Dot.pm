package App::Iptables2Dot;

# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use warnings;
use strict;
use Carp;
use Getopt::Long qw(GetOptionsFromString);

use version; our $VERSION = qv('v0.3.0');

# Module implementation here

my @optdefs = qw(
    checksum-fill
    clamp-mss-to-pmtu
    comment=s
    ctstate=s
    destination|d=s
    dport=s
    destination-ports|dports=s
    gid-owner=s
    in-interface|i=s
    icmp-type=s
    jump|j=s
    limit=s
    limit-burst=s
    log-prefix=s
    m=s
    mac-source=s
    match-set=s
    notrack
    o=s
    physdev-in=s
    physdev-is-bridged
    physdev-is-in
    physdev-is-out
    physdev-out=s
    protocol|p=s
    reject-with
    source|s=s
    sport=s
    state=s
    tcp-flags=s
    to-destination=s
    to-ports=s
    to-source
    ulog-prefix=s
);

sub new {
    my ($self) = @_;
    my $type = ref($self) || $self;

    $self = bless { nodemap => {}, nn => 0 }, $type;

    return $self;
} # new()

sub add_optdef {
    my $optdef = shift;
    push @optdefs, $optdef;
} # add_optdef()

# dot_graph($opt, @graphs)
#
# Creates a graph in the 'dot' language for all tables given in the list
# @graphs.
#
# Returns the graph as string.
#
sub dot_graph {
    my $self = shift;
    my $opt  = shift;
    my $subgraphs = '';
    foreach my $graph (@_) {
        $subgraphs .= $self->_dot_subgraph($opt,$graph);
    }
    my $ranks = join "; ", $self->_internal_nodes($opt,@_); # determine all internal chains
    my $graph = <<"EOGRAPH";
digraph iptables {
  { rank = source; $ranks; }
  rankdir = LR;
$subgraphs
}
EOGRAPH
    return $graph;
} # dot_graph()

sub read_iptables {
    my ($self,$input) = @_;

    while (<$input>) {
        $self->_read_iptables_line($_);
    }
} # read_iptables()

sub read_iptables_file {
	my ($self,$fname) = @_;

	if (open(my $input, '<', $fname)) {
		$self->read_iptables($input);
		close $input;
	}
	else {
		die "can't open file '$fname' to read iptables-save output";
	}
} # read_iptables_file()

## internal functions only

# _dot_edges($table)
#
# Lists all jumps between chains in the given table as edge description in the
# 'dot' language.
#
# Returns a list of edge descriptions.
#
sub _dot_edges {
    my ($self,$opt,$table) = @_;
    my @edges = ();
    my %seen  = ();
    my $re_it = qr/^(MASQUERADE|RETURN|TCPMSS)$/;
    foreach my $edge (@{$self->{jumps}->{$table}}) {
        my $tp  = ':w';
        my $lbl = '';
        if ($opt->{edgelabel} && $edge->[2]) {
            $lbl = " [label=\"$edge->[2]\"]";
        }
        unless ($edge->[1] =~ $re_it) {
            $tp = ":name:w";
        }
        my $e0 = $edge->[0];
        my $e1 = $edge->[1];
        if ($opt->{"use-numbered-nodes"}) {
            $e0 = $self->{nodemap}->{$edge->[0]} || $edge->[0];
            $e1 = $self->{nodemap}->{$edge->[1]} || $edge->[1];
        }
        if ($opt->{showrules}) {
            if (my $ot = $opt->{'omittargets'}) {
                my %omit = map { $_ => 1, } split(',',$ot);
                push @edges, "$e0:R$edge->[3]:e -> $e1$tp$lbl;"
                    unless ($omit{$edge->[1]});
            }
            else {
                push @edges, "$e0:R$edge->[3]:e -> $e1$tp$lbl;";
            }
        }
        else {
            my $etext = "$e0:e -> $e1$tp$lbl";
            unless ($seen{$etext} ++) {
                push @edges, $etext;
            }
        }
    }
    if ($opt->{showrules} || $opt->{edgelabel}) {
        return @edges;
    }
    else {
        my @le = map {
            1 < $seen{$_} ? qq($_ [label="($seen{$_})"];) : qq($_;);
        } @edges;
        return @le;
    }
} # _dot_edges()

# _dot_nodes($table)
#
# Lists all chains in the given table as node descriptions in the 'dot'
# language.
#
# Returns a list of node descriptions.
#
sub _dot_nodes {
    my ($self,$opt,$table) = @_;
    my @nodes = ();
    my %used = ();
    unless ($opt->{showunusednodes}) {
        %used = map { $_->[0] => 1, } @{$self->{jumps}->{$table}};
    }
    foreach my $node (keys %{$self->{chains}->{$table}}) {
        next unless ($used{$node} || $opt->{showunusednodes});
        my @rules = ();
        my $rn = 0;
        if ($opt->{showrules}) {
            foreach my $rule (@{$self->{chains}->{$table}->{$node}->{rules}}) {
                push @rules, qq(<tr><td PORT="R$rn">$rule</td></tr>);
                $rn++;
            }
        }
        my $lbl = "<table border=\"0\" cellborder=\"1\" cellspacing=\"0\">"
                . qq(<tr><td bgcolor="lightgrey" PORT="name">$node</td></tr>\n)
                . join("\n", @rules, "</table>");
        if ($opt->{"use-numbered-nodes"}) {
            push @nodes, $self->{nodemap}->{$node} ." [shape=none,margin=0,label=<$lbl>];";
        }
        else {
            push @nodes, "$node [shape=none,margin=0,label=<$lbl>];";
        }
    }
    return @nodes;
} # _dot_nodes()

# _dot_subgraph($opt, $table)
#
# Creates a subgraph in the 'dot' language for the table given in $table.
#
# Returns the subgraph as string.
#
sub _dot_subgraph {
    my ($self,$opt,$table) = @_;
    my $nodes  = join "\n    ", $self->_dot_nodes($opt,$table);
    my $edges  = join "\n    ", $self->_dot_edges($opt,$table);
    my $graph  = <<"EOGRAPH";
  subgraph $table {
    $nodes
    $edges
  }
EOGRAPH
    return $graph;
} # _dot_subgraph()

# _internal_nodes(@tables)
#
# Lists all chains from all tables in @tables, that are internal chains.
#
# Returns a list of all internal tables.
#
sub _internal_nodes {
    my $self      = shift;
    my $opt       = shift;
    my $re_in     = qr/^(PREROUTING|POSTROUTING|INPUT|FORWARD|OUTPUT)$/;
    my @nodes     = ();
    my %have_node = ();
    my %used      = ();
    foreach my $table (@_) {
        unless ($opt->{showunusednodes}) {
            %used = map { $_->[0] => 1, } @{$self->{jumps}->{$table}};
        }
        foreach my $node (sort keys %{$self->{chains}->{$table}}) {
            next unless ($used{$node} || $opt->{showunusednodes});
            if (!$have_node{$node} && $node =~ $re_in) {
                push @nodes, qq("$node");
                $have_node{$node} = 1;
            }
        }
    }
    return @nodes;
} # _internal_nodes()

# _read_iptables_line($line)
#
# Reads the next line from iptables output and creates an entry in the rules
# and or jump table for it.
#
# Returns nothing.
#
sub _read_iptables_line {
    my ($self,$line) = @_;
    return if ($line =~ /^#.*$/);
    return if ($line =~ /^COMMIT$/);
    chomp;
    if ($line =~ /^\*(\S+)$/) {
        $self->{last_table} = $1;
        push @{$self->{tables}}, $1;
        $self->{chains}->{$1} = {};
        $self->{jumps}->{$1}  = [];
    }
    elsif ($line =~ /^:(\S+)\s.+$/) {
        $self->{chains}->{$self->{last_table}}->{$1} = { rules => [] };
        unless ($self->{nodemap}->{$1}) {
                $self->{nodemap}->{$1} = "node" . $self->{nn};
                $self->{nn} += 1;
        }
    }
    elsif ($line =~ /^-A\s(\S+)\s(.+)$/) {
        my $chain = $1;
        my $rule  = $2;
        my %opt;
        my $last_table = $self->{last_table};
        my ($ret, $args) = GetOptionsFromString($rule,\%opt,@optdefs);
        if ($ret) {
            my $iface = $opt{'in-interface'} || '';
            my $target = $opt{'jump'} || '';
            unless ($target =~ /^(ACCEPT|DROP|REJECT)$/) {
                my $rn = scalar @{$self->{chains}{$last_table}->{$chain}->{rules}};
                push @{$self->{jumps}->{$last_table}}, [ $chain, $target, $iface, $rn ];
            }
        }
        else {
            die "unknown argument in rule: $rule";
        }
        push @{$self->{chains}->{$last_table}->{$chain}->{rules}}, $rule;
    }
    else {
        die "unrecognized line: $line";
    }
    return;
} # _read_iptables_line()

1; # Magic true value required at end of module
__END__

=head1 NAME

App::Iptables2Dot - turn iptables-save output into graphs for GraphViz


=head1 VERSION

This document describes App::Iptables2Dot version v0.3.0


=head1 SYNOPSIS

    use App::Iptables2Dot;

    App::IpTables2Dot::add_optdef('unknown-opt=s');

    my $i2d = new App::Iptables2Dot()
    
    $i2d->read_iptables(\*STDIN);
    $i2d->read_iptables_file($fname);

    print $i2d->dot_graph( {showrules => 1} , @tables);

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 new()

Create a new App::Iptables2Dot object.

=head2 dot_graph( $opt, @tables )

Returns a description suitable for the I<dot> program of the iptables rules
from the given tables according to the options given in $opt.

Arguments:

=over

=item $opt

A hash reference with the following options:

=over

=item edgelabel => 0,

With a true value edges may be labeled with the interface that determines the
matching rule for the jump.

=item omittargets => '',

The given targets will be suppressed in the I<dot> graph. This only works
together with option I<showrules>.

Multiple targets are separated with comma (C<,>). For instance:

 { omittargets => 'SNAT,DNAT',
   showrules   => 1,
 }

=item showrules => 0,

With a true value all rules of a chain will be added to the node representing
that chain.

=item showunusednodes => 0,

Usually chains with no jumps to other chains or targets will not be shown.
With a true value these chains show up in the graph.

=item use-numbered-nodes => 0

With a true value the nodes in the dot file will be named I<node0> .. I<noden>
and provided with a label showing their name from C<iptables-save> output.

This option can help if the filter rules contain chains with a dash (C<->)
in their name, which is not allowed as input for C<dot>.

=back

=item @tables

An array containing the table names we are interested in. Namely C<filter>,
C<mangle>, C<nat> and C<raw>.

=back

=head2 read_iptables( $input )

Reads the output from iptables-save from the given input stream.

=head2 read_iptables_file( $fname )

Reads the saved output from iptables-save from the file with name
C<$fname>.

=head2 App::Iptables2Dot::add_optdef( $optdef )

This function is not bound to an App::Iptables2Dot object.

You usually want to use this to extend the rule parser with the given option
definition if you find that the iptables-save output you analyze uses an
option that the rule parser didn't know.

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< can't open file '%s' to read iptables-save output >>

Method read_iptables_file will die with this message if it could not open
the file given with C<$fname>.

=item C<< unknown argument in rule: %s >>

The rule parser will die with this message showing the rule for
I<iptables-save> that contained an unknown parameter.

Since the rules are parsed by C<GetOptionsFromString()> from module
I<Getopt::Long>, you may workaround this by adding the unknown option to the
array C<@optdefs> at the top of F<Apt/Iptables2Dot.pm>. After that please file
a bug at L<https://rt.cpan.org/> or send me a notice at L<mamawe@cpan.org>
to have it fixed in one of the next releases of this distribution.

Alternatively you may want to use I<App::Iptables2Dot::add_optdef()> like this

 App::Iptables2Dot::add_optdef('unknown-opt=s');

if the rule parser dies with message
I<unknown argument in rule: --unknown-opt arg ...> and you don't want to touch
the library file I<Apt/Iptables2Dot.pm>.

=item C<< unrecognized line: %s >>

The function that read in the output from I<iptables-save> found a line that
it could not interpret and died in grief and despair. If you think the line
ist valid output from I<iptables-save>, please file a bug at
L<https://rt.cpan.org/> or send me a notice at L<mamawe@cpan.org>.

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
App::Iptables2Dot requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

=over

=item Getopt::Long

=item Pod::Usage

=back


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-iptables2dot@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Mathias Weidner  C<< <mamawe@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Mathias Weidner C<< <mamawe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
