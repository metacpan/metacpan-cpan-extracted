# -*- perl -*-
#
# Config::Record by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2000-2007 Daniel P. Berrange <dan@berrange.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id: Record.pm,v 1.12 2006/01/27 16:25:50 dan Exp $

package Config::Record;

use strict;
use warnings;
use Carp qw(confess cluck);
use IO::File;

use warnings::register;

use vars qw($VERSION);

$VERSION = "1.1.2";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %params = @_;
    
    $self->{record} = exists $params{record} ? $params{record} : {};
    $self->{features} = exists $params{features} ? $params{features} : {};
    $self->{debug} = $params{debug};
    $self->{filename} = undef;
    
    bless $self, $class;
    
    if (defined $params{file}) {
	$self->load($params{file});
    }
    
    return $self;
}


sub load {
    my $self = shift;
 
    my $file;
    if (@_) {
	$file = shift;
    } elsif ($self->{filename}) {
	$file = $self->{filename};
    } else {
	die "no filename was specified";
    }
    
    my $fh;
    if (ref($file)) {
	if (!$file->isa("IO::Handle")) {
	    confess "file must be an instance of IO::Handle";
	}
	$fh = $file;
    } else {
	$fh = IO::File->new($file)
	    or confess "cannot read from $file: $!";
	$self->{filename} = $file;
    }
    
    local $/ = undef;
    my $data = <$fh>;
    $self->{record} = $self->_parse($data,  ref($file) ? "<unknown>" : $file);
    $fh->close 
	or confess "cannot close file: $!";
}


sub _parse {
    my $self = shift;
    my $data = shift;
    my $filename = shift;

    my $value = {};
    my @stack = $value;
    my $here;
    my $continuation;

    my $LABEL = '((?:\w|-|\.)+)';
    # Hairy ! Escaping the escape chars really obscures the regex.
    # Need to allow  any character except \ or "
    # unless they are written as  \\  or  \"
    my $QUOTED_LABEL = '((?:(?:[^"\\\])|(?:\\\\")|(?:\\\\\\\\))+)';
    my $TRAILING_WHITESPACE = '\s*(?:\#.*)?';
    my $lineno = 0;

    my @lines = split /\n/, $data;

    foreach my $line (@lines) {
	$lineno++;
	warn $lineno . ": '" . $line . "' here='" .
	    (defined $here ? $here : '') . "' continue='" .
	    (defined $continuation ? $continuation : '') .
	    "'\n" if $self->{debug};
	next if $line =~ m|^\s*#|;
	next if $line =~ m|^\s*$|;

	if ($here) {
	    if ($line =~ /\s*${here}\s*$/) { # EOF
		warn "$lineno: End of here doc\n" if $self->{debug};
		$here = undef;
		$continuation = undef;
	    } else {                # ...
		warn "$lineno: Middle of here doc\n" if $self->{debug};
		${$continuation} .= $line . "\n";
	    }
	} elsif ($continuation) {
	    if ($line =~ /^\s*"(.*?)"\s*(\\)?\s*$/ || # "..."
		$line =~ /^\s*(.*?)\s*(\\)?\s*$/) {   #  ...
		warn "$lineno: Continuation\n" if $self->{debug};
		${$continuation} .= $1;
		$continuation = undef unless $2;
	    } else {
		warn "$lineno: unexpected input '$line'\n";
	    }
	} else {
	    if ($line =~ /^\s*$LABEL\s*=\s*\(${TRAILING_WHITESPACE}$/ || # foo = (
		($self->{features}->{quotedkeys} &&
		 $line =~ /^\s*"$QUOTED_LABEL"\s*=\s*\(${TRAILING_WHITESPACE}$/)) { # " foo " = (
		warn "$lineno: Key '$1' with array\n" if $self->{debug};
		if (ref($value) eq "ARRAY") {
		    confess "unexpected key,value pair in $filename at line $lineno";
		}
		
		my $key = $1;

		if ($self->{features}->{quotedkeys}) {
		    $key =~ s,\\("|\\),$1,g;
		}
		
		my $new = [];
		$value->{$key} = $new;
		$value = $new;
		push @stack, $value;
	    } elsif ($line =~ /^\s*\(${TRAILING_WHITESPACE}$/) { # (
		warn "$lineno: Start of array\n" if $self->{debug};
		if (ref($value) ne "ARRAY") {
		    confess "unexpected array entry in $filename at line $lineno";
		}
		
		my $new = [];
		push @{$value}, $new;
		$value = $new;
		push @stack, $value;
	    } elsif ($line =~ /^\s*\)${TRAILING_WHITESPACE}$/) { # )
		warn "$lineno: End of array\n" if $self->{debug};
		if (ref($value) ne "ARRAY") {
		    confess "mismatched closing round bracket in $filename at line $lineno";
		}
		if ($#stack == 0) {
		    confess "too many closing curley bracket in $filename at line $lineno";
		}
		
		pop @stack;
		$value = $stack[$#stack];
	    } elsif ($line =~ /^\s*$LABEL\s*=\s*{${TRAILING_WHITESPACE}$/ || # foo = {
		     ($self->{features}->{quotedkeys} &&
		      $line =~ /^\s*"$QUOTED_LABEL"\s*=\s*{${TRAILING_WHITESPACE}$/)) { # " foo " = {
		warn "$lineno: Key '$1' with hash\n" if $self->{debug};
		if (ref($value) eq "ARRAY") {
		    confess "unexpected key,value pair in $filename at line $lineno";
		}
		
		my $key = $1;
		
		if ($self->{features}->{quotedkeys}) {
		    $key =~ s,\\("|\\),$1,g;
		}

		my $new = {};
		$value->{$key} = $new;
		$value = $new;
		push @stack, $value;
	    } elsif ($line =~ /^\s*{${TRAILING_WHITESPACE}$/) { # {
		warn "$lineno: Start of hash\n" if $self->{debug};
		if (ref($value) ne "ARRAY") {
		    confess "unexpected array entry in $filename at line $lineno";
		}
		
		my $new = {};
		push @{$value}, $new;
		$value = $new;
		push @stack, $value;
	    } elsif ($line =~ /^\s*}${TRAILING_WHITESPACE}$/) { # }
		warn "$lineno: End of hash\n" if $self->{debug};
		if (ref($value) eq "ARRAY") {
		    confess "mismatched closing curly bracket in $filename at line $lineno";
		}
		if ($#stack == 0) {
		    confess "too many closing curley bracket in $filename at line $lineno";
		}
		
		pop @stack;
		$value = $stack[$#stack];
	    } elsif ($self->{features}->{includes} &&
		     ($line =~ /^\s*$LABEL\s*=\s*\@include\((.+)\)${TRAILING_WHITESPACE}$/ || # foo = @include(filename)
		      ($self->{features}->{quotedkeys} &&
		       $line =~ /^\s*"$QUOTED_LABEL"\s*=\s*\@include\((.+)\)${TRAILING_WHITESPACE}$/))) { # " foo " = @include(filename)
		warn "$lineno: Include file\n" if $self->{debug};
		my $key = $1;
		my $file = $2;

		if ($self->{features}->{quotedkeys}) {
		    $key =~ s,\\("|\\),$1,g;
		}

		my $fh = IO::File->new($file)
		    or confess "cannot read from $file: $!";

		local $/ = undef;
		my $data = <$fh>;
		my $record = $self->_parse($data,  ref($file) ? "<unknown>" : $file);
		$fh->close
		    or confess "cannot close file: $!";

		$value->{$key} = $record;
	    } elsif ($line =~ /^\s*$LABEL\s*=\s*<<(\w+)\s*$/ || # foo = <<EOF
		     ($self->{features}->{quotedkeys} &&
		      $line =~ /^\s*"$QUOTED_LABEL"\s*=\s*<<(\w+)\s*$/)) { # " foo " = <<EOF
		warn "$lineno: Key '$1' with here doc\n" if $self->{debug};
		my $key = $1;
		my $val = "";
		
		if ($self->{features}->{quotedkeys}) {
		    $key =~ s,\\("|\\),$1,g;
		}

		$value->{$key} = $val;

		$here = $2;
		$continuation = \$value->{$key};
	    } elsif ($line =~ /^\s*$LABEL\s*=\s*"(.*)"\s*(\\)?${TRAILING_WHITESPACE}$/ || # foo = "..."
		     ($self->{features}->{quotedkeys} &&
		      $line =~ /^\s*"$QUOTED_LABEL"\s*=\s*"(.*)"\s*(\\)?${TRAILING_WHITESPACE}$/) || # " foo " = "..."
		     $line =~ /^\s*$LABEL\s*=\s*(.*?)(\\)?\s*$/ || # foo = ...
		     ($self->{features}->{quotedkeys} &&
		      $line =~ /^\s*"$QUOTED_LABEL"\s*=\s*(.*?)(\\)?\s*$/)) { # " foo " = ...
		warn "$lineno: Key '$1' with string\n" if $self->{debug};
		my $key = $1;
		my $val = $2;
		
		if ($self->{features}->{quotedkeys}) {
		    $key =~ s,\\("|\\),$1,g;
		}

		if (ref($value) eq "ARRAY") {
		    confess "expecting value, found key, value pair at line $lineno";
		}
		
		$value->{$key} = $val;
		warn "$lineno: Start continuation\n" if $3 && $self->{debug};
		$continuation = \$value->{$key} if $3;
	    } elsif ($line =~ /^\s*<<(\w+)\s*$/) { # <<EOF
		warn "$lineno: Start of here doc\n" if $self->{debug};
		my $val = "";
		
		if (ref($value) ne "ARRAY") {
		    confess "expecting key,value pair, found value at line $lineno";
		}

		push @{$value}, $val;
		
		$here = $1;
		$continuation = \$value->[$#{$value}];
	    } elsif ($self->{features}->{includes} &&
		     ($line =~ /^\s*\@include\((.+)\)${TRAILING_WHITESPACE}$/)) { # @include(filename)
		warn "$lineno: Include file\n" if $self->{debug};
		my $file = $1;

		my $fh = IO::File->new($file)
		    or confess "cannot read from $file: $!";

		local $/ = undef;
		my $data = <$fh>;
		my $record = $self->_parse($data,  ref($file) ? "<unknown>" : $file);
		$fh->close
		    or confess "cannot close file: $!";

		if (ref($value) ne "ARRAY") {
		    confess "expecting key,value pair, found value at line $lineno";
		}
		
		push @{$value}, $record;
	    } elsif ($line =~ /^\s*"(.*)"\s*(\\)?${TRAILING_WHITESPACE}$/ || # "..."
		     $line =~ /^\s*(.*?)(\\)?\s*$/) { # ...
		warn "$lineno: Value\n" if $self->{debug};
		my $val = $1;
		
		if (ref($value) ne "ARRAY") {
		    confess "expecting key,value pair, found value at line $lineno";
		}
		
		push @{$value}, $val;
		
		$continuation = \$value->[$#{$value}] if $2;
	    } else {
		warn "Unexpected value '$line'\n";
	    }
	}
    }		 
    if ($#stack != 0) {
	confess "missing closing bracket in $filename at line $lineno";
    }
		 
    return $stack[$#stack];
}
    
sub save {
    my $self = shift;
    
    my $file;
    if (@_) {
	$file = shift;
    } elsif ($self->{filename}) {
	$file = $self->{filename};
    } else {
	die "no filename was specified";
    }
    
    my $fh;
    if (ref($file)) {
	if (!$file->isa("IO::Handle")) {
	    confess "file must be an instance of IO::Handle";
	}
	$fh = $file;
    } else {
	$fh = IO::File->new(">$file")
	    or confess "cannot write to $file: $!";
	$self->{filename} = $file;
    }

    foreach my $key (keys %{$self->{record}}) {
	print $fh $self->_format_key($key), " = ";
	$self->_format($fh, $self->{record}->{$key}, "");
    }
    
    $fh->close();
}

sub _format {
    my $self = shift;
    my $fh = shift;
    my $value = shift;
    my $indent = shift;

    my $ref = ref($value);
    
    if ($ref) {
	if ($ref eq "HASH") {
	    $self->_format_hash($fh, $value, $indent);
	} elsif ($ref eq "ARRAY") {
	    $self->_format_array($fh, $value, $indent);
	} else {
	    confess "unhandled reference $ref. Configuration files" .
		"can only contain unblessed scalars, array or hash references";
	}
    } else {
	$self->_format_scalar($fh, $value, $indent);
    }
}

sub _format_hash {
    my $self = shift;
    my $fh = shift;
    my $record = shift;
    my $indent = shift;
    
    print $fh "{\n";
    foreach my $key (keys %{$record}) {
	print $fh "$indent  ", $self->_format_key($key), " = ";
	$self->_format($fh, $record->{$key}, "$indent  ");
    }
    print $fh "$indent}\n";
}

sub _format_array {
    my $self = shift;
    my $fh = shift;
    my $list = shift;
    my $indent = shift;
    
    print $fh "(\n";
    foreach my $element (@{$list}) {
	print $fh "$indent  ";
	$self->_format($fh, $element, "$indent  ");
	
    }
    print $fh "$indent)\n";
}

sub _format_scalar {
    my $self = shift;
    my $fh = shift;
    my $value = shift;
    my $indent = shift;
    
    if ($value =~ /\n/) {
	$value .= "\n" unless $value =~ /\n$/;
	print $fh "<<EOF\n";
	print $fh $value;
	print $fh "EOF\n";
    } elsif ($value =~ /^\s+/ ||
	     $value =~ /\s+$/) {
	# XXX split long lines with \
	# XXX escape embedded "
	print $fh "\"$value\"\n";
    } else {
	# XXX split long lines with \
	print $fh "$value\n";
    }
}

sub _format_key {
    my $self = shift;
    my $key = shift;
    if ($self->{features}->{quotedkeys}) {
	if ($key =~ /^((?:\w|-|\.)+)$/) {
	    return $key;
	} else {
	    $key =~ s/\\/\\\\/g;
	    $key =~ s/"/\\"/g;
	    return '"' . $key . '"';
	}
    } else {
	return $key;
    }
}


sub view {
    my $self = shift;
    my $key = shift;
    
    my $value = $self->get($key, @_);

    if (!ref($value) ||
	ref($value) ne "HASH") {
	confess "value for $key is not a hash";
    }
    return $self->new(record => $value,
		      debug => $self->{debug},
		      features => $self->{features});
}


sub get {
    my $self = shift;
    my $key = shift;
    
    my @key;

    warn "Key: '" . $key . "'\n" if $self->{debug};
    foreach (split /((?<!\\)\/)/, $key) {
	next if m,^/$,;
	warn "  -> '" . $_ . "'\n" if $self->{debug};
	push @key, $_;
    }

    my $entry = $self->{record};
    my $context;
    foreach my $fragment (@key) {
	$context = defined $context ? $context . "/" . $fragment : $fragment;
	
	if ($fragment =~ /^\[(\d+)\]$/) {
	    my $index = $1;
	    if (ref($entry) ne "ARRAY") {
		if (@_) {
		    return shift;
		}
		confess "cannot find array value at '$context' for parameter '$key'";
	    }
	    if ($#{$entry} < $index) {
		if (@_) {
		    return shift;
		}
		confess "cannot find array value at '$context' for parameter '$key'";
	    }
	    $entry = $entry->[$index];
	} elsif ($self->{features}->{quotedkeys}) {
	    $fragment =~ s/\\(\[|\]|\/|\\)/$1/g;
	    warn "Quote '$fragment'\n" if $self->{debug};
	    if (ref($entry) ne "HASH") {
		if (@_) {
		    return shift;
		}
		confess "cannot find hash value at '$context' for parameter '$key'";
	    }
	    if (!exists $entry->{$fragment}) {
		if (@_) {
		    return shift;
		}
		confess "cannot find hash value at '$context' for parameter '$key'";
	    }
	    $entry = $entry->{$fragment};
	} else {
	    warn "NonQuote '$fragment'\n" if $self->{debug};
	    if ($fragment =~ /((?:\w|-|\.)+)/) {
		if (ref($entry) ne "HASH") {
		    if (@_) {
			return shift;
		    }
		    confess "cannot find hash value at '$context' for parameter '$key'";
		}
		if (!exists $entry->{$fragment}) {
		    if (@_) {
			return shift;
		    }
		    confess "cannot find hash value at '$context' for parameter '$key'";
		}
		$entry = $entry->{$fragment};
	    } else {
		confess "fragment '$fragment' should be alphanumeric, or an array index";
	    }
	}
    }
    
    return $entry;
}


sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    
    my @key;
    warn "Key: '" . $key . "'\n" if $self->{debug};
    foreach (split /((?<!\\)\/)/, $key) {
	next if m,^/$,;
	warn "  -> '" . $_ . "'\n" if $self->{debug};
	push @key, $_;
    }


    my $entry = $self->{record};
    my $context;
    while (defined (my $fragment = shift @key)) {
	$context = defined $context ? $context . "/" . $fragment : $fragment;
	
	if ($fragment =~ /^\[(\d+)\]$/) {
	    my $index = $1;
	    if (ref($entry) ne "ARRAY") {
		confess "cannot find array value at $context for parameter $key";
	    }
	    if (@key) {
		if (exists $entry->[$index]) {
		    $entry = $entry->[$index];
		} else {
		    if ($key[0] =~ /^\[(\d+)\]$/) {
			$entry->[$index] = [];
		    } else {
			$entry->[$index] = {};
		    }
		    $entry = $entry->[$index];
		}
	    } else {
		$entry->[$index] = $value;
	    }
	} elsif ($self->{features}->{quotedkeys}) {
	    $fragment =~ s/\\(\[|\]|\/|\\)/$1/g;
	    warn "Quote '$fragment'\n" if $self->{debug};
	    if (ref($entry) ne "HASH") {
		confess "cannot find hash value at $context for parameter $key";
	    }
	    if (@key) {
		if (exists $entry->{$fragment}) {
		    $entry = $entry->{$fragment};
		} else {
		    if ($key[0] =~ /^\[(\d+)\]$/) {
			$entry->{$fragment} = [];
		    } else {
			$entry->{$fragment} = {};
		    }
		    $entry = $entry->[$fragment];
		}
	    } else {
		$entry->{$fragment} = $value;
	    }
	} else {
	    warn "NonQuote '$fragment'\n" if $self->{debug};
	    if ($fragment =~ /((?:\w|-|\.)+)/) {
		if (ref($entry) ne "HASH") {
		    confess "cannot find hash value at $context for parameter $key";
		}
		if (@key) {
		    if (exists $entry->{$fragment}) {
			$entry = $entry->{$fragment};
		    } else {
			if ($key[0] =~ /^\[(\d+)\]$/) {
			    $entry->{$fragment} = [];
			} else {
			    $entry->{$fragment} = {};
			}
			$entry = $entry->[$fragment];
		    }
		} else {
		    $entry->{$fragment} = $value;
		}
	    } else {
		confess "fragment '$fragment' should be alphanumeric, or an array index";
	    }
	}
    }
}


sub record {
    my $self = shift;
    
    return $self->{record};
}

1 # So that the require or use succeeds.

