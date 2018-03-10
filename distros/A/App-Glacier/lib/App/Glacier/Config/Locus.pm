package App::Glacier::Config::Locus;

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);

=head1 NAME

App::Glacier::Config::Locus - source file location

=head1 SYNOPSIS

use App::Glacier::Config::Locus;

$locus = new App::Glacier::Config::Locus;

$locus = new App::Glacier::Config::Locus($file, $line);

$locus->add($file, $line);

$s = $locus->format;

$locus->fixup_names('old' => 'new');

$locus->fixup_lines();

=head1 DESCRIPTION

Provides support for manipulating source file locations.    

=head2 $locus = new App::Glacier::Config::Locus($file, $line);

Creates a new locus object.  Arguments are optional: either no arguments
should be given, or both of them.  If given, they indicate the source
file name and line number this locus is to represent.    
    
=cut

sub new {
    my $class = shift;
    
    my $self = bless { table => {}, order => 0 }, $class;

    $self->add(@_) if $#_ == 1;
    
    return $self;
}

=head2 $locus->add($file, $line);

Adds new location to the locus.  Use this for statements spanning several
lines and/or files.    
    
=cut

sub add {
    my ($self, $file, $line) = @_;
    unless (exists($self->{table}{$file})) {
	$self->{table}{$file}{order} = $self->{order}++;
	$self->{table}{$file}{lines} = [];
    }
    push @{$self->{table}{$file}{lines}}, $line;
    delete $self->{string};
}

=head2 $s = $locus->format($msg);

Returns a string representation of the locus.  The argument is optional.
If given, its string representation will be concatenated to the formatted
locus with a ": " in between.  If multiple arguments are supplied, their
string representations will be concatenated, separated by horizontal
space characters.  This is useful for formatting error messages.

If the locus contains multiple file locations, the method tries to compact
them by representing contiguous line ranges as B<I<X>-I<Y>> and outputting
each file name once.  Line ranges are separated by commas.  File locations
are separated by semicolons.  E.g.:

    $locus = new App::Glacier::Config::Locus("foo", 1);
    $locus->add("foo", 2);
    $locus->add("foo", 3);
    $locus->add("foo", 5);
    $locus->add("bar", 2);
    $locus->add("bar", 7);
    print $locus->format("here it goes");

will produce the following:

    foo:1-3,5;bar:2,7: here it goes

=cut

sub format {
    my $self = shift;
    unless (exists($self->{string})) {
	$self->{string} = '';
	foreach my $file (sort {
	                    $self->{table}{$a}{order} <=> $self->{table}{$b}{order}
			  }
			  keys %{$self->{table}}) {
	    my @lines = @{$self->{table}{$file}{lines}};
	    $self->{string} .= ';' if $self->{string};
	    $self->{string} .= "$file:";
	    my $beg = shift @lines;
	    my $end = $beg;
	    my @ranges;
	    foreach my $line (@lines) {
		if ($line == $end + 1) {
		    $end = $line;
		} else {
		    if ($end > $beg) {
			push @ranges, "$beg-$end";
		    } else {
			push @ranges, $beg;
		    }
		    $beg = $end = $line;
		}
	    }

	    if ($end > $beg) {
		push @ranges, "$beg-$end";
	    } else {
		push @ranges, $beg;
	    }
	    $self->{string} .= join(',', @ranges);
	}
    }
    if (@_) {
	if ($self->{string} ne '') {
	    return "$self->{string}: " . join(' ', @_);
	} else {
	    return join(' ', @_);
	}
    }
    return $self->{string};
}

=head2 $locus->fixup_names('foo' => 'bar', 'baz' => 'quux');

Replaces file names in the locations according to the arguments.

=cut

sub fixup_names {
    my $self = shift;
    local %_ = @_;
    while (my ($oldname, $newname) = each %_) {
	next unless exists $self->{table}{$oldname};
	croak "target name already exist" if exists $self->{table}{$newname};
	$self->{table}{$newname} = delete $self->{table}{$oldname};
    }
    delete $self->{string};
}

=head2 $locus->fixup_lines('foo' => 1, 'baz' => -2);

Offsets line numbers for each named file by the given number of lines.  E.g.:

     $locus = new App::Glacier::Config::Locus("foo", 1);
     $locus->add("foo", 2);
     $locus->add("foo", 3);
     $locus->add("bar", 3);
     $locus->fixup_lines(foo => 1. bar => -1);
     print $locus->format;

will produce

     foo:2-4,bar:2

If given a single argument, the operation will affect all locations.  E.g.,
adding the following to the example above:

     $locus->fixup_lines(10);
     print $locus->format;

will produce

     foo:22-24;bar:22
    
=cut

sub fixup_lines {
    my $self = shift;
    return unless @_;
    if ($#_ == 0) {
	my $offset = shift;
	while (my ($file, $ref) = each %{$self->{table}}) {
	    $ref->{lines} = [map { $_ + $offset } @{$ref->{lines}}];
	}
    } elsif ($#_ % 2) {
	local %_ = @_;
	while (my ($file, $offset) = each %_) {
	    if (exists($self->{table}{$file})) {
		$self->{table}{$file}{lines} =
		    [map { $_ + $offset }
		         @{$self->{table}{$file}{lines}}];
	    }
	}
    } else {
	croak "bad number of arguments";
    }
    delete $self->{string};
}

1;
