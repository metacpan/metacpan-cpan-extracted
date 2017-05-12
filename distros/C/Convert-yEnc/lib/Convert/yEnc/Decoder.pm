package Convert::yEnc::Decoder;

use strict;
use IO::File;
use warnings;

use constant yEncBrainDamage => 1;


sub new
{
    my($class, $dir) = @_;

    my $decoder = { dir => $dir || '.' };

    bless $decoder, $class
}

sub out_dir
{
    my($decoder, $dir) = @_;

    $decoder->{dir} = $dir;
}


sub decode
{
    my($decoder, $in) = @_;

    delete $decoder->{temp};

    $decoder->_in($in);
    $decoder->_begin;
    $decoder->_out;
    $decoder->_part if $decoder->{temp}{begin}{part};
    $decoder->_body;
    $decoder->_end;
}

sub _in
{
    my($decoder, $in) = @_;

    my $IN = ref $in ? $in : 
                       defined $in ? (new IO::File $in) : \*STDIN;

    $IN or die ref $decoder, "::decode: Can't open $in: $!\n";
    $decoder->{temp}{IN} = $IN;
}

sub _begin
{
    my $decoder = shift;
    my $temp    = $decoder->{temp};
    my $IN      = $temp->{IN};

    my $begin;
    while ($begin = <$IN>) 
    { 
	$begin =~ /^=ybegin/ and last;
    }

    $begin or die ref $decoder, "::_begin: Can't find =ybegin line\n";
    
    my @begin = split ' ', $begin;

    for my $field (@begin)
    {
	my($key, $val) = split /=/, $field;
	$temp->{begin}{$key} = $val;
    }

    my($name) = $begin =~ /name=(.*)/;  # Horrid Martian.
    $name =~ s/^\s+|\s+$//g;
    $temp->{begin}{name} = $name;

    $temp->{line}{ybegin} = $begin;
}

sub _out
{
    my $decoder = shift;
    my $dir     = $decoder->{dir};
    my $temp    = $decoder->{temp};
    my $name 	= $temp->{begin}{name};
    my $file 	= "$dir/$name";
    my $mode    = O_CREAT | O_WRONLY;
    my $OUT  	= new IO::File $file, $mode or	
	die ref $decoder, "::_out: Can't open $file: $!\n";
    
    binmode $OUT or
	die ref $decoder, "::_out: Can't binmode $file: $!\n";

    $temp->{name} = $name;
    $temp->{file} = $file;
    $temp->{OUT } = $OUT;
}

sub _part
{
    my $decoder = shift;
    my $temp    = $decoder->{temp};
    my $IN      = $temp->{IN };
    my $OUT     = $temp->{OUT};
    my $part 	= <$IN>;
       $part 	=~ /^=ypart/ or die ref $decoder, "::_part: No =ypart line\n";
    my @part 	= split ' ', $part;

    for my $field (@part)
    {
	my($key, $val) = split /=/, $field;
	$temp->{part}{$key} = $val;
    }

    my $begin  = $temp->{part}{begin};
    my $end    = $temp->{part}{end  };
    my $offset = $begin - yEncBrainDamage;
    my $size   = $end   - $offset;

    seek $OUT, $offset, 0 or 
	die ref $decoder, "::_part: Can't seek to $begin: $!\n";

    $temp->{part}{size } = $size;
    $temp->{line}{ypart} = $part;
}

sub _body
{
    my $decoder = shift;
    my $temp    = $decoder->{temp};
    my $file    = $temp->{file};
    my $IN      = $temp->{IN};
    my $OUT     = $temp->{OUT};
    my $line;

    while ($line = <$IN>)
    {
	$line =~ /^=yend/ and last;
	chomp $line;

	$decoder->_line($line);

	print $OUT $line or
	    die "can't print to $file: $!\n";
    }

    close $OUT;
    $temp->{line}{yend} = $line;
}

sub _line
{
    $_[1] =~ s/=(.)/chr(ord($1)+256-64 & 255)/egosx;
    $_[1] =~ tr[\000-\377][\326-\377\000-\325];
    
}

sub _end
{
    my $decoder = shift;
    my $temp    = $decoder->{temp};
    my $end     = $temp->{line}{yend};
       $end     =~ /^=yend/ or die ref $decoder, "::end: No =yend line\n";

    my @end = split ' ', $end;

    for my $field (@end)
    {
	my($key, $val) = split /=/, $field;
	$temp->{end}{$key} = $val;
    }

    my $beginSize  =  $temp->{begin}{size};
    my $partSize   =  $temp->{part }{size};
    my $endSize    =  $temp->{end  }{size};
    my $decodeSize =  defined $partSize ? $partSize : $beginSize;

    $decodeSize == $endSize or 
	die ref $decoder, 
	"::_end: Begin/PartSize $decodeSize != EndSize $endSize\n";

    if (not defined $partSize)
    {
	my $file     = $temp->{file};
	my $fileSize = (stat $file)[7];
	$beginSize == $fileSize or 
	    die ref $decoder, 
	    "::_end: BeginSize $beginSize != FileSize $fileSize\n";
    }

    $temp->{size} = $decodeSize;
}

sub name   { shift->{temp}{name} }
sub file   { shift->{temp}{file} }
sub size   { shift->{temp}{size} }
sub ybegin { shift->{temp}{line}{ybegin} }
sub ypart  { shift->{temp}{line}{ypart } }
sub yend   { shift->{temp}{line}{yend  } }


1

__END__


=head1 NAME

Convert::yEnc::Decoder - decodes yEncoded files


=head1 SYNOPSIS

  use Convert::yEnc::Decoder;
  
  $decoder = new Convert::yEnc::Decoder;
  $decoder = new Convert::yEnc::Decoder $dir;
  
  $decoder->out_dir($dir);
  
  eval 
  { 
      $decoder->decode( $file);
      $decoder->decode(\*FILE);
      $decoder->decode;
  };
  print $@ if $@;
  
  $name   = $decoder->name;
  $file   = $decoder->file;
  $size   = $decoder->size;
  
  $ybegin = $decoder->ybegin;
  $ypart  = $decoder->ypart;
  $yend   = $decoder->yend;


=head1 ABSTRACT

yEnc decoder


=head1 DESCRIPTION

C<Convert::yEnc::Decoder> decodes a yEncoded file and writes it to disk.
Methods are provided for returning information about the decoded file.
    

=head2 Exports

Nothing.


=head2 Methods

=over 4


=item I<$decoder> = C<new> C<Convert::yEnc::Decoder>

=item I<$decoder> = C<new> C<Convert::yEnc::Decoder> I<$dir>

Creates and returns a new C<Convert::yEnc::Decoder> object.

Decoded files will be written to I<$dir>.
If I<$dir> is omitted, 
it defaults to the current working directory.


=item I<$decoder>->C<out_dir>(I<$dir>)

Sets the output directory to I<$dir>.


=item I<$decoder>->C<decode>(I<$file>)

=item I<$decoder>->C<decode>(I<\*FILE>)

=item I<$decoder>->C<decode>

Decodes a file.
C<die>s if there are any errors.

The first form reads from the file named I<$file>.
The second form reads from the file handle I<FILE>.
The third form reads from C<STDIN>.

The data stream need not begin at the C<=yBegin> line;
C<decode> will search until it finds it.
C<decode> stops reading when it finds the C<=yend> line,
so C<Decoder> can decode multiple files from the same 
data stream.
    
C<decode> may be called repeatedly on the same C<Decoder> object
to decode multiple files.


=item I<$name> = I<$decoder>->C<name>

After a successful decode, 
returns the name of the file that was created.

=item I<$file> = I<$decoder>->C<file>

After a successful decode, 
returns the complete path of the file that was created.

=item I<$size> = I<$decoder>->C<size>

After a successful decode, 
returns the size of the decoded file.


=item I<$ybegin> = I<$decoder>->C<ybegin>

After a successful decode, 
returns the C<=ybegin> line.

=item I<$ypart> = I<$decoder>->C<ypart>

After a successful decode, 
returns the C<=ypart> line,
or undef if there wasn't one.

=item I<$yend> = I<$decoder>->C<yend>

After a successful decode, 
returns the C<=yend> line.

=back


=head1 NOTES

=head2 1-liner

To decode a single file on the command line, write

    perl -MConvert::yEnc::Decoder -e 'Convert::yEnc::Decoder->new->decode' < myFile


=head1 TODO

=over 4

=item *

CRCs

=back


=head1 SEE ALSO

=over 4

=item *

L<Convert::yEnc>

=item *

L<http://www.yenc.org>

=item *

L<http://www.yenc.org/yenc-draft.1.3.txt>

=back


=head1 AUTHOR

Steven W McDougall, E<lt>swmcd@world.std.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008 by Steven McDougall.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
