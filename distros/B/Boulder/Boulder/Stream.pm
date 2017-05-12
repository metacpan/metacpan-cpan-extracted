package Boulder::Stream;

# CHANGE HISTORY:

# changes from 1.04 to 1.05
# - new() will now accept filehandle globs, IO::File, and FileHandle objects

# changes from 1.03 to 1.04
# - Fixed regexp bug that broke on tags with embedded spaces -pete

# Changes from 1.01 to 1.03
# - Fixed a problem in escaping the {} characters

# Changes from 1.00 to 1.01
# - Added the asTable() method to Boulder::Stream

=head1 NAME

Boulder::Stream - Read and write tag/value data from an input stream

=head1 SYNOPSIS

   #!/bin/perl
   # Read a series of People records from STDIN.
   # Add an "Eligible" tag to all those whose
   # Age >= 35 and Friends list includes "Fred"
   use Boulder::Stream;
   
   my $stream = Boulder::Stream->newFh;
   
   while ( my $record = <$stream> ) {
      next unless $record->Age >= 35;
      my @friends = $record->Friends;
      next unless grep {$_ eq 'Fred'} @friends;

      $record->insert(Eligible => 'yes');
      print $stream $record;
    }

=head1 DESCRIPTION

Boulder::Stream provides stream-oriented access to L<Boulder> IO
hierarchical tag/value data.  It can be used in a magic tied
filehandle mode, as shown in the synopsis, or in object-oriented mode.
Using tied filehandles, L<Stone> objects are read from input using the
standard <> operator.  Stone objects printed to the tied filehandle
appear on the output stream in L<Boulder> format.

By default, data is read from the magic ARGV filehandle (STDIN or a
list of files provided on the command line) and written to STDOUT.
This can be changed to the filehandles of your choice.

=head2 Pass through behavior

When using the object-oriented form of Boulder::Stream, tags which
aren't specifically requested by the get() method are passed through
to output unchanged.  This allows pipes of programs to be constructed
easily. Most programs will want to put the tags back into the boulder
stream once they're finished, potentially adding their own.  Of course
some programs will want to behave differently.  For example, a
database query program will generate but not read a B<boulderio>
stream, while a report generator will read but not write the stream.

This convention allows the following type of pipe to be set up:

  query_database | find_vector | find_dups | \
    | blast_sequence | pick_primer | mail_report

If all the programs in the pipe follow the conventions, then it will be
possible to interpose other programs, such as a repetitive element finder,
in the middle of the pipe without disturbing other components.

=head1 SKELETON BOULDER PROGRAM

Here is a skeleton example.

   #!/bin/perl
   use Boulder::Stream;
   
   my $stream = Boulder::Stream->newFh;
   
   while ( my $record = <$stream> ) {
      next unless $record->Age >= 35;
      my @friends = $record->Friends;
      next unless grep {$_ eq 'Fred'} @friends;

      $record->insert(Eligible => 'yes');
      print $stream $record;
    }

The code starts by creating a B<Boulder::Stream> object to handle the
I/O.  It reads from the stream one record at a time, returning a
L<Stone> object.  We recover the I<Age> and I<Friends> tags, and
continue looping unless the Age is greater or equal to 35, and the
list of Friends contains "Fred".  If these criteria match, then we
insert a new tag named Eligible and print the record to the stream.
The output may look like this:

  Name=Janice
  Age=36
  Eligible=yes
  Friends=Susan
  Friends=Fred
  Friends=Ralph
  =
  Name=Ralph
  Age=42
  Eligible=yes
  Friends=Janice
  Friends=Fred
  =
  Name=Susan
  Age=35
  Eligible=yes
  Friends=Susan
  Friends=Fred
  =

Note that in this case only records that meet the criteria are echoed
to standard output.  The object-oriented version of the program looks
like this:

   #!/bin/perl
   use Boulder::Stream;
   
   my $stream = Boulder::Stream->new;
   
   while ( my $record = $stream->get('Age','Friends') ) {
      next unless $record->Age >= 35;
      my @friends = $record->Friends;
      next unless grep {$_ eq 'Fred'} @friends;

      $record->insert(Eligible => 'yes');
      $stream->put($record);
    }

The get() method is used to fetch Stones containing one or more of the
indicated tags.  The put() method is used to send the result to
standard output.  The pass-through behavior might produce a set of
records like this one:

  Name=Janice
  Age=36
  Eligible=yes
  Friends=Susan
  Friends=Fred
  Friends=Ralph
  =
  Name=Phillip
  Age=30
  =
  Name=Ralph
  Age=42
  Eligible=yes
  Friends=Janice
  Friends=Fred
  =
  Name=Barbara
  Friends=Agatha
  Friends=Janice
  =
  Name=Susan
  Age=35
  Eligible=yes
  Friends=Susan
  Friends=Fred
  =

Notice that there are now two records ("Phillip" and "Barbara") that
do not contain the Eligible tag.

=head1 Boulder::Stream METHODS

=head2 $stream = Boulder::Stream->new(*IN,*OUT)

=head2 $stream = Boulder::Stream->new(-in=>*IN,-out=>*OUT)

The B<new()> method creates a new B<Boulder::Stream> object.  You can
provide input and output filehandles. If you leave one or both
undefined B<new()> will default to standard input or standard output.
You are free to use files, pipes, sockets, and other types of file
handles.  You may provide the filehandle arguments as bare words,
globs, or glob refs. You are also free to use the named argument style
shown in the second heading.

=head2 $fh = Boulder::Stream->newFh(-in=>*IN, -out=>*OUT)

Returns a filehandle object tied to a Boulder::Stream object.  Reads
on the filehandle perform a get().  Writes invoke a put().

To retrieve the underlying Boulder::Stream object, call Perl's
built-in tied() function:

  $stream = tied $fh;

=head2 $stone = $stream->get(@taglist)

=head2 @stones = $stream->get(@taglist)

Every time get() is called, it will return a new Stone object.  The
Stone will be created from the input stream, using just the tags
provided in the argument list.  Pass no tags to receive whatever tags
are present in the input stream.

If none of the tags that you specify are in the current boulder
record, you will receive an empty B<Stone>.  At the end of the input
stream, you will receive B<undef>.

If called in an array context, get() returns a list of all stones from
the input stream that contain one or more of the specified tags.

=head2 $stone = $stream->read_record(@taglist)

Identical to get(>, but the name is longer.

=head2 $stream->put($stone)

Write a B<Stone> to the output filehandle.

=head2 $stream->write_record($stone)

Identical to put(), but the name is longer.

=head2 Useful State Variables in a B<Boulder::Stream>

Every Boulder::Stream has several state variables that you can adjust.
Fix them in this fashion:

	$a = new Boulder::Stream;
	$a->{delim}=':';
	$a->{record_start}='[';
	$a->{record_end}=']';
	$a->{passthru}=undef;

=over 4

=item * delim

This is the delimiter character between tags and values, "=" by default.

=item * record_start

This is the start of nested record character, "{" by default.

=item * record_end

This is the end of nested record character, "}" by default.

=item * passthru

This determines whether unrecognized tags should be passed through
from the input stream to the output stream.  This is 'true' by
default.  Set it to undef to override this behavior.

=back

=head1 BUGS

Because the delim, record_start and record_end characters in the
B<Boulder::Stream> object are used in optimized (once-compiled)
pattern matching, you cannot change these values once get() has once
been called.  To change the defaults, you must create the
Boulder::Stream, set the characters, and only then begin reading from
the input stream.  For the same reason, different Boulder::Stream
objects cannot use different delimiters.

=head1 AUTHOR

Lincoln D. Stein <lstein@cshl.org>, Cold Spring Harbor Laboratory,
Cold Spring Harbor, NY.  This module can be used and distributed on
the same terms as Perl itself.

=head1 SEE ALSO

L<Boulder>, 
L<Boulder::Blast>, L<Boulder::Genbank>, L<Boulder::Medline>, L<Boulder::Unigene>,
L<Boulder::Omim>, L<Boulder::SwissProt>

=cut

require 5.004;
use strict;
use Stone;
use Carp;
use Symbol();

use vars '$VERSION';
$VERSION=1.06;

# Pseudonyms and deprecated methods.
*get        =  \&read_record;
*put        =  \&write_record;

# Call this with IN and OUT filehandles of your choice.
# If none specified, defaults to <>/STDOUT.
sub new {
  my $package = shift;
  my ($in,$out) = rearrange(['IN','OUT'],@_);

  $in = $package->to_fh($in)     || \*main::ARGV;
  $out = $package->to_fh($out,1) || \*main::STDOUT;
  my $pack = caller;

  return bless {
		'IN'=>$in,
		'OUT'=>$out,
		'delim'=>'=',
		'record_stop'=>"=\n",
		'line_end'=>"\n",
		'subrec_start'=>"\{",
		'subrec_end'=>"\}",
		'binary'=>'true',
		'passthru'=>'true'
	       },$package;
}

# You are free to redefine the following magic variables:
# $a = new Boulder::Stream;
# $a->{delim}         separates tag = value ['=']
# $a->{line_end}      separates tag=value pairs [ newline ]
# $a->{record_stop}   ends records ["=\n"]
# $a->{subrec_start}  begins a nested record [ "{" ]
# $a->{subrec_end}    ends a nested record [ "}" ]
# $a->{passthru}      if true, passes unread tags -> output [ 'true' ]
# $a->{binary}        if true, escapes and unescapes records [ 'true' ]

# Since escaping/unescaping has some overhead, you might want to undef
# 'binary' in order to improve performance.

# Read in and return a Rolling Stone record.  Will return
# undef() when an empty record is hit.  You can specify
# keys that you are interested in getting, as in the
# original boulder package.
sub read_one_record {
    my($self,@keywords) = @_;

    return if $self->done;

    my(%interested,$key,$value);
    grep($interested{$_}++,@keywords);

    my $out=$self->{OUT};
    my $delim=$self->{'delim'};
    my $subrec_start=$self->{'subrec_start'};
    my $subrec_end=$self->{'subrec_end'};
    my ($stone,$pebble,$found);

    # This is a small hack to ensure that we respect the
    # record delimiters even when we don't make an 
    # intervening record write. 
    if (!$self->{WRITE} && $self->{INVOKED} && !$self->{LEVEL} 
	&& $self->{'passthru'} && $self->{PASSED}) {
	print $out ($self->{'record_stop'});
    } else {
	$self->{INVOKED}++;	# keep track of our invocations
    }

    undef $self->{WRITE};
    undef $self->{PASSED};

    while (1) {

	last unless $_ = $self->next_pair;

	if (/^#/) {
	    print $out ("$_$self->{line_end}") if $self->{'passthru'};
	    next;
	}

	if (/^\s*$delim/o) {
	    undef $self->{LEVEL};
	    last;
	}

	if (/$subrec_end$/o) {
	    $self->{LEVEL}--,last if $self->{LEVEL};
	    print $out ("$_$self->{line_end}") if $self->{'passthru'};
	    next;
	}

	next unless ($key,$value) = /^\s*(.+?)\s*$delim\s*(.*)/o;

	$stone = new Stone() unless $stone;

	if ((!@keywords) || $interested{$key}) {

	    $found++;
	    if ($value=~/^\s*$subrec_start/o) {
		$self->{LEVEL}++;
		$pebble = read_one_record($self); # call ourselves recursively
		$pebble = new Stone() unless $pebble; # an empty record is still valid
		$stone->insert($self->unescapekey($key)=>$pebble);
		next;
	    }

	    $stone->insert($self->unescapekey($key)=>$self->unescapeval($value));

	} elsif ($self->{'passthru'}) {
	    print $out ("$_$self->{line_end}");
	    $self->{PASSED}++;	# flag that we will need to write a record delimiter
	}
    }
    
    return undef unless $found;
    return $stone;
}

# Write out the specified Stone record.
sub write_record {
    my($self,@stone)=@_;
    for my $stone (@stone) {
      $self->{'WRITE'}++;
      my $out=$self->{OUT};

      # Write out a Stone record in boulder format.
      my ($key,$value,@value);
      foreach $key ($stone->tags) {
	@value = $stone->get($key);
	$key = $self->escapekey($key);
	foreach $value (@value) {
	  next unless ref $value;
	  if (exists $value->{'.name'}) {
	    $value = $self->escapeval($value);
	    print $out ("$key$self->{delim}$value\n");
	  } else {
	    print $out ("$key$self->{delim}$self->{subrec_start}\n");
	    _write_nested($self,1,$value);
	  }
	}
      }
      print $out ("$self->{delim}\n");
    }
    1;
}

# read_record() returns one stone if called in a scalar
# context and all the stones if called in an array
# context.
sub read_record {
    my($self,@tags) = @_;
    if (wantarray) {
	my(@result,$s);
	while (!$self->done) {
	    $s = $self->read_one_record(@tags);
	    push(@result,$s) if $s;
	}
	return @result;
    } else {
	my $s;
	while (!$self->done) {
	    $s = $self->read_one_record(@tags);
	    return $s if $s;
	}
	return undef;
    }
}

# ----------------------------------------------------------------
# TIED INTERFACE METHODS
# ----------------------------------------------------------------

# newFh() is a class method that returns a tied filehandle
# 
sub newFh {
  my $class = shift;
  return unless my $self = $class->new(@_);
  return $self->fh;
}

# fh() returns a filehandle that you can read stones from
sub fh {
  my $self = shift;
  my $class = ref($self) || $self;
  my $s = Symbol::gensym;
  tie $$s,$class,$self;
  return $s;
}

sub TIEHANDLE {
  my $class = shift;
  return bless {stream => shift},$class;
}

sub READLINE {
  my $self = shift;
  return $self->{stream}->read_record();
}

sub PRINT {
  my $self = shift;
  $self->{stream}->write_record(@_);
}

#--------------------------------------
# Internal (private) procedures.
#--------------------------------------
# This finds an array of key/value pairs and
# stashes it where we can find it.
sub read_next_rec {
    my($self) = @_;
    my($olddelim) = $/;

    $/="\n".$self->{record_stop};
    my($in) = $self->{IN};

    my($data);
    chomp($data = <$in>);

    if ($in !~ /ARGV/) {
	$self->{EOF}++ if eof($in);
    } else {
	$self->{EOF}++ if eof();
    }

    $/=$olddelim;
    $self->{PAIRS}=[grep($_,split($self->{'line_end'},$data))];
}

# This returns TRUE when we've reached the end
# of the input stream
sub done {
    my $self = shift;
    return if defined $self->{PAIRS} && @{$self->{PAIRS}};
    return $self->{EOF};
}

# This returns the next key/value pair.
sub next_pair {
    my $self = shift;
    $self->read_next_rec unless $self->{PAIRS};
    return unless $self->{PAIRS};
    return shift @{$self->{PAIRS}} if @{$self->{PAIRS}};
    undef $self->{PAIRS};
    return undef;
}

sub _write_nested {
    my($self,$level,$stone) = @_;
    my $indent = '  ' x $level;
    my($key,$value,@value);
    my $out = $self->{OUT};

    foreach $key ($stone->tags) {
	@value = $stone->get($key);
	$key = $self->escapekey($key);
	foreach $value (@value) {
	    if (exists $value->{'.name'}) {
		$value = $self->escapeval($value);
		print $out ($indent,"$key$self->{delim}$value\n");
	    } else {
		print $out ($indent,"$key$self->{delim}$self->{subrec_start}\n");
		_write_nested($self,$level+1,$value);
	    }
	}
    }

    print $out ('  ' x ($level-1),$self->{'subrec_end'},"\n");
}

# Escape special characters.
sub escapekey {
    my($s,$toencode)=@_;
    return $toencode unless $s->{binary};
    my $specials=" $s->{delim}$s->{subrec_start}$s->{subrec_end}$s->{line_end}$s->{record_stop}%";
    $toencode=~s/([$specials])/uc sprintf("%%%02x",ord($1))/oge;
    return $toencode;
}

sub escapeval {
    my($s,$toencode)=@_;
    return $toencode unless $s->{binary};
    my $specials="$s->{delim}$s->{subrec_start}$s->{subrec_end}$s->{line_end}$s->{record_stop}%";
    $toencode=~s/([$specials])/uc sprintf("%%%02x",ord($1))/oge;
    return $toencode;
}

# Unescape special characters
sub unescapekey {
    unescape(@_);
}

sub unescapeval {
    unescape(@_);
}

# Unescape special characters
sub unescape {
    my($s,$todecode)=@_;
    return $todecode unless $s->{binary};
    $todecode =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $todecode;
}

# utility routine to turn type globs, barewords, IO::File structs, etc into
# filehandles.
sub to_fh {
  my ($pack,$thingy,$write) = @_;
  return unless $thingy;
  return $thingy if defined fileno($thingy);

  my $caller;
  while (my $package = caller(++$caller)) {
    my $qualified_thingy = Symbol::qualify_to_ref($thingy,$package);
    return $qualified_thingy if defined fileno($qualified_thingy);
  }
  
  # otherwise try to open it as a file
  my $fh = Symbol::gensym();
  $thingy = ">$thingy" if $write;
  open ($fh,$thingy) || croak "$pack open of $thingy: $!";
  return \*$fh;
}

sub DESTROY {
    my $self = shift;
    my $out=$self->{OUT};
    print $out ($self->{'delim'},"\n")
	if !$self->{WRITE} && $self->{INVOKED} && !$self->{LEVEL} && $self->{'passthru'} && $self->{PASSED};
}


#####################################################################
###################### private routines #############################
sub rearrange {
    my($order,@param) = @_;
    return unless @param;
    my %param;

    if (ref $param[0] eq 'HASH') {
      %param = %{$param[0]};
    } else {
      return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');

      my $i;
      for ($i=0;$i<@param;$i+=2) {
        $param[$i]=~s/^\-//;     # get rid of initial - if present
        $param[$i]=~tr/a-z/A-Z/; # parameters are upper case
      }

      %param = @param;                # convert into associative array
    }
    
    my(@return_array);
    
    local($^W) = 0;
    my($key)='';
    foreach $key (@$order) {
        my($value);
        if (ref($key) eq 'ARRAY') {
            foreach (@$key) {
                last if defined($value);
                $value = $param{$_};
                delete $param{$_};
            }
        } else {
            $value = $param{$key};
            delete $param{$key};
        }
        push(@return_array,$value);
    }
    push (@return_array,{%param}) if %param;
    return @return_array;
}

1;

