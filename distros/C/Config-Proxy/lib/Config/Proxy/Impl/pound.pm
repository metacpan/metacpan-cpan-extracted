package Config::Proxy::Impl::pound;
use strict;
use warnings;
use parent 'Config::Proxy::Base';
use Config::Proxy::Node::Root;
use Config::Pound::Node::Section;
use Config::Proxy::Node::Comment;
use Config::Proxy::Node::Statement;
use Config::Proxy::Node::Empty;
use Config::Pound::Node::Verbatim;
use Config::Pound::Node::IP;
use Text::Locus;
use Text::ParseWords;
use Carp;
use Data::Dumper;

our $VERSION = '1.0';

sub new {
    my $class = shift;
    return $class->SUPER::new(shift // '/etc/pound.cfg', 'pound -c -f');
}

sub dequote {
    my ($self, $text) = @_;
    my $q = ($text =~ s{^"(.*)"$}{$1});
    if ($q) {
	$text =~ s{\\(.)}{$1}g;
    }
    if (wantarray) {
	return ($text, $q)
    } else {
	return $text;
    }
}

sub select {
    my $self = shift;
    my @query;
    while (my $cond = shift @_) {
	if ($cond eq 'name') {
	    $cond = 'name_ci';
	}
	push @query, $cond, shift(@_);
    }
    $self->SUPER::select(@query);
}

use constant {
    PARSER_OK => 0,
    PARSER_END => 1
};

sub _parser_End {
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;
    $parent->append_node(
	new Config::Proxy::Node::Statement(
	    kw => $kw,
	    argv => $words,
	    orig => $orig,
	    locus => new Text::Locus($filename, $line)
	)
    );
    return (PARSER_END, $filename, $line);
}

my %generic_section = ( 'end' => \&_parser_End );

my %match_section;

%match_section = (
    'match' => \%match_section,
    'not' => \&_parser_Not,
    'acl' => \&_parser_ACL,
    'end' => \&_parser_End
);

my %rewrite_section = (
    'else' => \&_parser_Else,
    'rewrite' => \&_parser_Rewrite,
    'match' => \%match_section,
    'not' => \&_parser_Not,
    'acl' => \&_parser_ACL,
    'end' => \&_parser_End
);

my %resolver_section = (
    'configtext' => \&_parser_ConfigText,
    'end' => \&_parser_End
);

my %service_section = (
    'backend' => \%generic_section,
    'match' => \%match_section,
    'not' => \&_parser_Not,
    'acl' => \&_parser_ACL,
    'rewrite' => \&_parser_Rewrite,
    'session' => \%generic_section,
    'end' => \&_parser_End
);

my %http_section = (
    'service' => \%service_section,
    'end' => \&_parser_End
);

my %top_section = (
# FIXME: If Include is to be expanded, this line should appear in all
# sections (since pound commit 6c7258cb2e).
#    'include' => \&_parser_Include,
    'listenhttp' => \%http_section,
    'listenhttps' => \%http_section,
    'acl' => \&_parser_ACL,
    'service' => \%service_section,
    'backend' => \%generic_section,
    'resolver' => \%resolver_section,
);

sub _parser_section {
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;
    # FIXME: extract label from $words etc
    my $section = Config::Pound::Node::Section->new(
	kw => $kw,
	argv => $words,
	orig => $orig,
	locus => new Text::Locus($filename, $line));
    my $r;
    ($r, $filename, $line) = $self->_parser($section, $filename, $line,
					    $fh, $ptab);
    $section->locus->add($filename, $line);
    $parent->append_node($section);
    return ($r, $filename, $line)
}

sub _parser {
    my ($self, $parent, $filename, $line, $fh, $ptab) = @_;
    my $start_locus = "$filename:$line";
    while (<$fh>) {
	$line++;
	chomp;
	my $orig = $_;
	s/^\s+//;
	s/\s+$//;

	if ($_ eq "") {
	    $parent->append_node(
		new Config::Proxy::Node::Empty(
		    orig => $orig,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	    next;
	}

	if (/^#.*/) {
	    $parent->append_node(
		new Config::Proxy::Node::Comment(
		    orig => $orig,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	    next;
	}

	my @words = parse_line('\s+', 1, $_);
	my $kw = shift @words;
	if (my $meth = $ptab->{lc($kw)}) {
	    my $r;

	    if (ref($meth) eq 'CODE') {
		($r, $filename, $line) = $self->${ \$meth }(
		    $parent,
		    $kw,
		    \@words,
		    $orig,
		    $filename,
		    $line,
		    $fh,
		    $ptab
		);
	    } elsif (ref($meth) eq 'HASH') {
		($r, $filename, $line) = $self->_parser_section(
		    $parent,
		    $kw,
		    \@words,
		    $orig,
		    $filename,
		    $line,
		    $fh,
		    $meth
		);
	    } else {
		croak "Unsupported element type: " . ref($meth);
	    }
	    return (PARSER_OK, $filename, $line) if $r == PARSER_END;
	} else {
	    $parent->append_node(
		new Config::Proxy::Node::Statement(
		    kw => $kw,
		    argv => \@words,
		    orig => $orig,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	}
    }
    if (exists($ptab->{end})) {
	croak "End statement missing in statement started at $start_locus"
    }
    return (PARSER_OK, $filename, $line);
}

sub _parser_Include {
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;
    my $includefile = $words->[0] or
	croak "$filename:$line: Filename is missing";

    # FIXME: Make sure filename is quoted
    $includefile = $self->dequote($includefile);

    open(my $ifh, "<", $includefile) or
	croak "can't open $filename: $!";

    my $stmt = new Config::Proxy::Node::Statement(
	kw => $kw,
	argv => $words,
	orig => $orig,
	locus => new Text::Locus($includefile, 1)
    );

    my ($r) = $self->_parser($stmt, $includefile, 0, $ifh, $ptab);
    close($ifh);
    $parent->append_node($stmt);
    return ($r, $filename, $line);
}

sub _parser_ACL {
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;

    if (!$parent->is_root && @$words) {
	$parent->append_node(
	    Config::Proxy::Node::Statement->new(
		kw => $kw,
		argv => $words,
		orig => $orig,
		locus => new Text::Locus($filename, $line)
	    )
	);
	return (PARSER_OK, $filename, $line);
    }

    # FIXME: Check $words
    my $section = Config::Pound::Node::Section->new(
	kw => $kw,
	argv => $words,
	orig => $orig,
	locus => new Text::Locus($filename, $line)
    );
    my $start_locus = "$filename:$line";
    while (<$fh>) {
	$line++;
	chomp;
	$section->locus->add($filename, $line);
	if (/^\s+$/) {
	    $section->append_node(
		new Config::Proxy::Node::Empty(
		    orig => $_,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	} elsif (/^\s*#.*$/) {
	    $section->append_node(
		new Config::Proxy::Node::Comment(
		    orig => $_,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	} elsif (/^\s*(end)\s*(?#.*)?$/i) {
	    $section->append_node(
		new Config::Proxy::Node::Statement(
		    kw => $1,
		    orig => $_,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	    $parent->append_node($section);
	    return (PARSER_OK, $filename, $line);
	} elsif (/^\s*"(.+?)"\s*(?#.*)?$/) {
	    $section->append_node(
		new Config::Pound::Node::IP(
		    kw => $1,
		    orig => $_,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	} else {
	    my $orig = $_;
	    s/^\s*//;
	    s/\s+$//;
	    my @words = parse_line('\s+', 1, $_);
	    my $kw = shift @words;
	    $section->append_node(
		new Config::Proxy::Node::Statement(
		    kw => $kw,
		    argv => \@words,
		    orig => $orig,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	}
    }

    croak "missing End in ACL statement started at $start_locus";
}

sub _parser_Not {
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;

    $orig =~ s/^(\s*$kw)//;

    my $sec = new Config::Pound::Node::Section(
	kw => $kw,
	orig => $1,
	locus => new Text::Locus($filename, $line)
    );

    if (@{$words} == 0) {
	croak "$filename:$line: \"Not\" statement missing arguments";
    } else {
	$kw = shift @{$words};
	if ($kw =~ /^(match|not)$/i) {
	    my $meth;
	    if ($kw =~ /^match$/i) {
		$meth = '_parser_section'
	    } else {
		$meth = '_parser_Not'
	    }

	    (undef, $filename, $line) = $self->${ \$meth }(
		$sec,
		$kw,
		$words,
		$orig,
		$filename,
		$line,
		$fh,
		$ptab
	    );
	    $sec->locus->add($filename, $line)
	} else {
	    my $stmt = new Config::Proxy::Node::Statement(
		kw => $kw,
		argv => $words,
		orig => $orig,
		locus => new Text::Locus($filename, $line)
	    );
	    $sec->append_node($stmt);
	}
    }
    $parent->append_node($sec);
    return (PARSER_OK, $filename, $line)
}

sub _parser_Else {
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;
    my $section = new Config::Pound::Node::Section(
	kw => $kw,
	argv => $words,
	orig => $orig,
	locus => new Text::Locus($filename, $line)
    );
    $parent->append_node($section);
    return (PARSER_OK, $filename, $line);
}

sub _parser_Rewrite {
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;
    my $r;
    ($r, $filename, $line) = $self->_parser_section(
	$parent,
	$kw,
	$words,
	$orig,
	$filename,
	$line,
	$fh,
	\%rewrite_section
    );

    my $rwr = $parent->tree(-1);
    my $itr = $rwr->iterator(inorder => 1, recursive => 0);
    my $branch;
    while (defined(my $node = $itr->next)) {
	my $kw = lc($node->kw);
	if ($kw eq 'else') {
	    $branch = $node;
	} elsif ($kw eq 'end') {
	    last;
	} elsif ($branch) {
	    $branch->append_node($node);
	    $node->drop(); # FIXME: see mark_dirty in Pound.pm
	}
    }
    return ($r, $filename, $line);
}

sub _parser_ConfigText{
    my ($self, $parent, $kw, $words, $orig, $filename, $line, $fh, $ptab) = @_;
    my $section = new Config::Pound::Node::Section(
	kw => $kw,
	argv => $words,
	orig => $orig,
	locus => new Text::Locus($filename, $line)
    );
    my $start_locus = "$filename:$line";
    while (<$fh>) {
	$line++;
	chomp;
	$section->locus->add($filename, $line);
	if (/^\s*(end)\s*(?#.*)?$/i) {
	    $section->append_node(
		new Config::Proxy::Node::Statement(
		    kw => $1,
		    orig => $_,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	    $parent->append_node($section);
	    return (PARSER_OK, $filename, $line)
	} else {
	    $section->append_node(
		new Config::Pound::Node::Verbatim(
		    orig => $_,
		    locus => new Text::Locus($filename, $line)
		)
	    );
	}
    }
    croak "missing End in $kw statement started at $start_locus"
}

sub parse {
    my ($self, %args) = @_;
    my $fh;
    if ($args{fh}) {
	$fh = $args{fh}
    } else {
	open($fh, '<', $self->filename)
	    or croak "can't open ".$self->filename.": $!";
    }
    $self->reset();
    $self->_parser($self->tree, $self->filename, $args{line} // 0,
		   $fh, \%top_section);
    close $fh unless $args{fh};
    return $self
}

sub topmost_not_node {
    my $node = shift;
    my $topmost;

    $node = $node->parent;
    while (!$node->parent->is_root &&
	   $node->parent->is_section &&
	   lc($node->parent->kw) eq 'not') {
	$topmost = $node->parent;
	$node = $topmost;
    }
    return $topmost;
}

sub write {
    my $self = shift;
    my $file = shift;
    my $fh;

    if (!defined($file)) {
	$file = \*STDOUT
    }
    if (ref($file) eq 'GLOB') {
	$fh = $file;
    } else {
	open($fh, '>', $file) or croak "can't open $file: $!";
    }

    local %_ = @_;
    my $itr = $self->iterator(inorder => 1);

    my @rws = ([-1, 0]);
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
#		print STDERR "\n# ".$node->as_string . "; depth ".$node->depth."; correction ", $rws[-1]->[1] . " (".(@rws+0).")\n";
		my $depth = $node->depth - $rws[-1]->[1];
		if ($node->is_section) {
		    if (lc($node->kw) eq 'rewrite') {
			push @rws, [ 0, $rws[-1]->[1] ];
		    } elsif (lc($node->kw) eq 'else') {
			if (!$rws[-1]->[0]) {
			    $rws[-1]->[0] = 1;
			    $rws[-1]->[1]++;
			    $depth--;
			}
		    }
		} elsif ($node->is_statement && lc($node->kw) eq 'end') {
		    if ($node->parent->is_section &&
			$node->parent->kw &&
			lc($node->parent->kw) eq 'rewrite') {
			pop @rws;
		    } elsif (my $topnot = topmost_not_node($node)) {
#			print STDERR " # pop\n";
			pop @rws;
			$depth = $topnot->depth - $rws[-1]->[1];
		    } else {
#			print $fh "# Decr $depth\n";
			$depth--;
		    }
		}
#		print STDERR "# Depth $depth\n";
		my $indent = ' ' x ($_{indent} * $depth);
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
	print $fh $s;
	if ($node->is_section && lc($node->kw) eq 'not') {
	    my $delta = $rws[-1]->[1];
	    while (lc($node->kw) eq 'not') {
		$node = $itr->next;
		($s = $node->as_string) =~ s/^\s+//;
		print $fh " $s";
		++$delta
	    }
	    if ($node->is_section) {
		push @rws, [ undef, $delta ];
#		print STDERR "# Push $rws[-1]->[1]\n";
	    }
	}
	print $fh "\n";
    }

    close $fh unless ref($file) eq 'GLOB';
}

1;
__END__

=head1 NAME

Config::Proxy::Impl::pound - Configuration parser implementation for Pound.

=head1 SYNOPSIS

    use 'Config::Proxy';

    my $cfg = new Config::Proxy('pound' [, $filename, $linter]);

=head1 DESCRIPTION

This class implements configuration parser for B<Pound> proxy
configuration file.  Please refer to B<Config::Pound> for a detailed
description.

=head1 SEE ALSO

B<Config::Pound>,
B<pound>(8).

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
