package Convert::yEnc;

use strict;
use IO::File;
use Convert::yEnc::Decoder;
use Convert::yEnc::RC;
use warnings;

our $VERSION = '1.06';


sub new
{
    my($package, %params) = @_;

    my $rcFile 	= $params{RC } || "$ENV{HOME}/.yencrc";
    my $outDir 	= $params{out} || '.';
    my $tmpDir 	= $params{tmp} || $outDir;
    my $RC     	= new Convert::yEnc::RC $rcFile;
    my $decoder = new Convert::yEnc::Decoder;

    my $yEnc = { rcFile  => $rcFile,
		 RC      => $RC,
		 out     => $outDir,
		 tmp     => $tmpDir,
		 decoder => $decoder   };

    bless $yEnc, $package
}


sub out_dir
{
    my($yEnc, $dir) = @_;
    $yEnc->{out} = $dir;
}

sub tmp_dir
{
    my($yEnc, $dir) = @_;
    $yEnc->{tmp} = $dir;
}


sub decode
{
    my($yEnc, $in) = @_;

    my $tmpDir  = $yEnc->{tmp};
    my $decoder = $yEnc->{decoder};
    $decoder->out_dir($tmpDir);

    eval
    {
	$decoder->decode($in);

	my $rc = $yEnc->{RC};

	for my $tag (qw(ybegin ypart yend))
	{
	    my $line = $decoder->$tag;
	       $line or next;

	    $rc->update($line) or 
		die ref $yEnc, ": bad =$tag line: $line\n";
	}

	my $name = $decoder->name;
	$rc->complete($name) and
	    $yEnc->_complete($name);
    };

    my $err = $@;
    my $ok  = $err ? 0 : 1;
    wantarray ? ($ok, $err) : $ok;
}

sub _complete
{
    my($yEnc, $name) = @_;

    $yEnc->{RC}->drop($name);

    my $tmpDir  = $yEnc->{tmp};
    my $outDir  = $yEnc->{out};

    my $tmpFile = "$tmpDir/$name";
    my $outFile = $yEnc->mkpath($outDir, $name);

    if (defined $outFile and $outFile eq $tmpFile)
    {
	# all done
    }
    elsif (defined $outFile)
    {
	rename $tmpFile, $outFile or
	    die ref $yEnc, ": Can't rename $tmpFile -> $outFile: $!\n";
    }
    else
    {
	unlink $tmpFile;
    }
}

sub mkpath
{
    my($yEnc, $dir, $name) = @_;
    "$dir/$name"
}


sub decoder { shift->{decoder} }
sub RC      { shift->{RC     } }


sub DESTROY
{
    my $yEnc = shift;
    my $RC   = $yEnc->{RC};
    defined $RC and $RC->save;
}


1

__END__


=head1 NAME

Convert::yEnc - yEnc decoder

=head1 SYNOPSIS

  use Convert::yEnc;
  
  $yEnc = new Convert::yEnc RC  => $rcFile,
                            out => $outDir, 
                            tmp => $tmpDir;
  
        $yEnc->out_dir($dir);
        $yEnc->tmp_dir($dir);
  
  $ok = $yEnc->decode(\*FILE);
  $ok = $yEnc->decode( $file);
  
  $decoder = $yEnc->decoder;
  $rc      = $yEnc->RC;
  
  undef $yEnc;   # saves the Convert::yEnc::RC database to disk
  
  package My::Decoder;
  use base qw(Convert::yEnc);
  sub mkpath
  {
      my($yEnc, $dir, $name) = @_;
      "$dir/$name"
  }


=head1 ABSTRACT

yEnc decoder, with database of file parts


=head1 DESCRIPTION

C<Convert::yEnc> decodes yEncoded files and writes them to disk. File
parts are saved to I<$tmpDir>; when all parts of a file have been
received, the completed file is moved to I<$outDir>.

C<Convert::yEnc> maintains a database of partially received files, called
the RC database. The RC database is loaded from disk when a
C<Convert::yEnc> object is created, and saved to disk when the object is
C<DESTROY>'d.


=head2 Exports

Nothing.


=head2 Methods

=over 4

=item I<$yEnc> = C<new> C<Convert::yEnc> C<RC> => I<$rcFile>,
C<out> => I<$outDir>, C<tmp> => I<$tmpDir>

Creates and returns a new C<Convert::yEnc> object.
I<$rcFile> contains the RC database.
I<$outDir> is the output directory,
and I<$tmpDir> is the temporary directory,

If the C<RC> parameter is omitted, 
it defaults to F<$ENV{HOME}/.yencrc>.
If the C<out> parameter is omitted, 
it defaults to the current working directory.
If the C<tmp> parameter is omitted, 
it defaults to the C<out> parameter.


=item I<$yEnc>->C<out_dir>(I<$dir>)

Sets the output directory to I<$dir>


=item I<$yEnc>->C<tmp_dir>(I<$dir>)

Sets the temporary directory to I<$dir>


=item I<$ok> = I<$yEnc>->C<decode>(I<$file>)

=item I<$ok> = I<$yEnc>->C<decode>(I<\*FILE>)

Decodes a yEncoded file and writes it to the C<tmp> directory.
If the file is complete, 
moves it to the C<out> directory
and drops the entry for the file from the RC database.

The first form reads the file named I<$file>.
The second form reads the file handle I<FILE>.

In scalar context, returns true on success. 
In list context, returns

    ($ok, $err)

where I<$ok> is true on success,
and I<$err> is an error message.


=item I<$rc> = I<$yEnc>->C<RC>

Returns the C<Convert::yEnc::RC> object that holds the RC database for I<$yEnc>.
Applications can use the returned value to query or manipulate 
the RC database directly.


=item C<DESTROY>

C<Convert::yEnc::RC> has a destructor.
The destructor writes the RC database 
back to the file from which it was loaded.

=back


=head2 Overrides

=over 4

=item C<mkpath>

C<Convert::yEnc> calls C<mkpath> to construct the path to which a 
completed file is moved.
The default implementation of C<mkpath> is shown in the L</SYNOPSIS>.

Applications can subclass from C<Convert::yEnc> and override this method if they want
the completed file to appear somewhere else.

If C<mkpath> returns C<undef>, the completed file is discarded.


=back


=head1 NOTES

=head2 Destructors don't work reliably at global destruct time

C<Convert::yEnc> provides a C<DESTROY> method as a convenience:
you can create a C<yEnc> object, use it, forget about it

    my $yEnc = new Convert::yEnc;
       $yEnc->decode(...);

and the RC file will automatically be written when the object 
ref count goes to zero.

Unless the ref count never goes to zero, because,  for example, 
a named closure is holding a reference on the object

    sub A { $yEnc }

In this case, the object won't be destructed until global destruct time.
Unfortunately, the order in which objects are destructed during
global destruction isn't controlled, and if the embedded
C<< $yEnc->RC >> object is destructed before C<$yEnc> itself,
then C<< $yEnc->DESTROY >> won't be able to write the RC file.

To avoid creating closures, pass C<yEnc> objects as parameters

    my $yEnc = new Convert::yEnc;
    
    A($yEnc);
    
    sub A { my $yEnc = shift }

rather than referencing them as globals. To pass a C<yEnc> object to
a C<File::Find> I<wanted> routine, use an anonymous closure

    File::Find::find(sub { A($yEnc) }, $dir)

It isn't always obvious when a closure is created;
if you're feeling paranoid, write

    $yEnc->RC->save

to save the RC file.

This problem is reported as bug 7853 at L<http://www.perl.org>.


=head1 SEE ALSO

=over 4

=item *

L<Convert::yEnc::RC>

=item *

L<Convert::yEnc::Decoder>

=item *

L<http://www.yenc.org>

=item *

L<http://www.yenc.org/yenc-draft.1.3.txt>

=back


=head1 AUTHOR

Steven W McDougall, <swmcd@world.std.com>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008 by Steven McDougall.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
