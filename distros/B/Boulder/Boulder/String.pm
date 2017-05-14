package Boulder::String;
use Boulder::Stream;
@ISA = 'Boulder::Stream';

$DATE="4 Dec 2000";
$VERSION=1.01;

=head1 NAME

Boulder::String - Read and write tag/value data from a string.

=head1 SYNOPSIS

   #!/bin/perl
   # Read a B<Stone> from stdin and create a string that can be 
   # passed to a dumb sub, which doesn't know about Stones.
   use Boulder::Stream;
   use Boulder::String;
   
   my $stream = Boulder::Stream->newFh;
   
   # read a stone from stdin
   my $record = <$stream> );

      print $stream $record;
    }

=head1 DESCRIPTION

Boulder::String provides access to L<Boulder> IO
hierarchical tag/value data.  
Stone objects printed to the tied string
are appended to the string in L<Boulder> format.

=head1 Boulder::Stream METHODS

=head2 $stream = Boulder::Stream->new($in_string,\$out_string);

The B<new()> method creates a new B<Boulder::String> object.  You must
provide an input string and a reference to an output string.
The input string may be empty.

=head2 $stream->write_record($stone)

Write the passed stone in L<Boulder> IO format into $out_string.

=head1 AUTHOR

Lincoln D. Stein <lstein@cshl.org>, Cold Spring Harbor Laboratory,
Cold Spring Harbor, NY.  This module can be used and distributed on
the same terms as Perl itself.

Patches and bug fixes contributed by Bernhard Schmalhofer
<bernhard@biomax.de>.

=head1 SEE ALSO

L<Boulder>, L<Boulder::Stream>, 
L<Boulder::Blast>, L<Boulder::Genbank>, L<Boulder::Medline>, L<Boulder::Unigene>,
L<Boulder::Omim>, L<Boulder::SwissProt>

=cut

# Override Stream.pm to allow the input and output to be 
# strings.  If outString is not defined, then we fall back
# to Boulder::Stream behavior, otherwise we append to the
# indicated string.
sub new {
    my($package,$inString,$outStringRef) = @_;
    die "Usage: Boulder::String::new(\$inString,\\\$outString)\n"
	unless defined($inString) && !ref($inString);
    die "Usage: Boulder::String::new(\$inString,\\\$outString)\n"
	if defined($outStringRef) && (ref($outStringRef) ne 'SCALAR');

    return bless {
	'IN'=>undef,
	'OUT'=>undef,
	'INSTRING'=>$inString,
	'OUTSTRING'=>$outStringRef,
	'delim'=>'=',
	'record_stop'=>"=\n",
	'line_end'=>"\n",
	'subrec_start'=>"\{",
	'subrec_end'=>"\}",
	'binary'=>'true',
	'passthru'=>undef
	},$package;
}

# Write out the specified Stone record.
sub write_record {
    my($self,$stone)=@_;
    my $out = $self->{OUTSTRING};
    return unless $out;

    $self->{'WRITE'}++;

    # Write out a Stone record in boulder format.
    my ($key,$value,@value);
    foreach $key ($stone->tags) {
	@value = $stone->get($key);
	$key = $self->escapekey($key);
	foreach $value (@value) {
	  next unless ref $value;
	  if (exists $value->{'.name'}) {
	    $value = $self->escapeval($value);
	    $$out .= "$key$self->{delim}$value\n";
	  } else {
	    $$out .= "$key$self->{delim}$self->{subrec_start}\n";
	    _write_nested($self,1,$value);
	  }
	}
    }
    ${$self->{OUTSTRING}} .= "$self->{delim}\n";
}

#--------------------------------------
# Internal (private) procedures.
#--------------------------------------
# This finds an array of key/value pairs and
# stashes it where we can find it.
sub read_next_rec {
    my($self) = @_;
    unless (defined($self->{RECORDS})) {
	$self->{RECORDS} = [split("\n$self->{record_stop}",$self->{INSTRING})];
    }
    my($nextrec) = shift(@{$self->{RECORDS}});
    $self->{PAIRS}=[grep($_,split($self->{'line_end'},$nextrec))];
}

# This returns TRUE when we've reached the end
# of the input stream
sub done {
    my $self = shift;
    return undef if @{$self->{PAIRS}};
    return undef unless ref($self->{RECORDS});
    return !scalar(@{$self->{RECORDS}});
}

sub _write_nested {
    my($self,$level,$stone) = @_;
    my $indent = '  ' x $level;
    my($key,$value,@value);
    my $out = $self->{OUTSTRING};
    return unless ref($out);

    foreach $key ($stone->tags) {
	@value = $stone->get($key);
	$key = $self->escapekey($key);
	foreach $value (@value) {
	  next unless ref $value;
	  if (exists $value->{'.name'}) {
	    $value = $self->escapeval($value);
	    $$out .= "$indent$key$self->{delim}$value\n";
	  } else {
	    $$out .= "$indent$key$self->{delim}$self->{subrec_start}\n";
	    _write_nested($self,$level+1,$value);
	  }
	}
    }
    
    $$out .= ('  ' x ($level-1)) . "$self->{'subrec_end'}\n";
}

sub DESTROY {
    my $self = shift;
    $out=$self->{OUTSTRING};
    if (ref($out) && !$self->{WRITE} && $self->{INVOKED} && 
	!$self->{LEVEL} && $self->{'passthru'} && $self->{PASSED}) {
	$$out .= "$self->{'delim'}\n";
    }
}


1;

