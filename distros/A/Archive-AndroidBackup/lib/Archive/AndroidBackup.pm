package Archive::AndroidBackup;
use Moose;
use MooseX::NonMoose;
use Moose::Util::TypeConstraints;
use File::Find;
use Compress::Raw::Zlib;
use IO::Zlib;
use IO::Handle '_IOLBF';
use Archive::AndroidBackup::TarIndex;
extends 'Archive::Tar';

our $VERSION = '1.13';

has 'file' => (
  is => 'rw',
  isa => 'Str',
  default => 'backup.ab',
);

#  defaults to invalid values to ensure
#  explicit setting read_header and write_header
#
subtype 'HdrMagic'
  => as 'Str'
  => where { $_ eq "ANDROID BACKUP" }
  => message {"Invalid Header"};

has 'magic' => ( is => 'rw', isa => 'HdrMagic', lazy => 1, default => '' );

subtype 'HdrVersion'
  => as 'Num'
  => where { $_ == 1 || $_ == 2}
  => message {"Unsupported File Version [$_]"};

has 'version' => ( is => 'rw', isa => 'HdrVersion', lazy => 1, default => 0 );

subtype 'HdrCompression'
  => as 'Num'
  => where { $_ =~ /^[01]$/ };

has 'compression' => ( is => 'rw', isa => 'HdrCompression', lazy => 1, default => -1 );

subtype 'HdrEncryption'
  => as 'Str'
  => where { $_ eq "none" }
  => message {"Encryption not implemented"};

has 'encryption' => ( is => 'rw', isa => 'HdrEncryption', lazy => 1, default => "");


sub _readHdrLine($$)
{
  my ($self, $FH) = @_;
  my ($buf, $c) = (('') x 2);
  while ((read($FH, $c, 1) > 0) && ($c ne "\n")) {
    $buf .= $c;
  }
  $buf;
}

sub read_header($)
{
  my ($self, $FH) = @_;
  $self->magic($self->_readHdrLine($FH));
  $self->version($self->_readHdrLine($FH));
  $self->compression($self->_readHdrLine($FH));
  $self->encryption($self->_readHdrLine($FH));
}

sub write_header($)
{
  my ($self, $FH) = @_;

  $self->magic("ANDROID BACKUP");
  $self->version(1);
  $self->compression(1);
  $self->encryption("none");

  seek $FH, 0, 0;
  print $FH $self->magic . "\n";
  print $FH $self->version . "\n";
  print $FH $self->compression . "\n";
  print $FH $self->encryption . "\n";
}

around 'read' => sub 
{
  my ($orig, $self, @args) = @_;
  my $file = shift @args;
  if (not defined $file) {
    $file = $self->file;
  }

  my $z = new Compress::Raw::Zlib::Inflate;
  my ($inFH, $tmpFHout, $tmpFHin, $tmpbuf, $header, $inbuf, $outbuf, $status);
  open($tmpFHout, ">", \$tmpbuf) || die "no write access memory?!";
  open($tmpFHin, "<", \$tmpbuf) || die "no read access memory?!";
  open($inFH, "<",$file) || die "Cannot open $file";
  map { binmode $_, ":bytes"; } $inFH, $tmpFHin, $tmpFHout;

  $self->read_header($inFH);

  while (read($inFH, $inbuf, 4096)) {
    $status = $z->inflate($inbuf, $outbuf);
    print $tmpFHout $outbuf;
    last if $status != Z_OK;
  }
  die "inflation failed" unless $status == Z_STREAM_END;
  $tmpFHout->flush;

  #  suppress error output
  #
  $Archive::Tar::WARN = 0;

  $self->$orig($tmpFHin);
  
  map { close $_; } $inFH, $tmpFHout, $tmpFHin;

  if ($self->error) {
    die "Invalid Tar file within backup!\n".$self->error;
  }
};

around 'write' => sub 
{
  my ($orig, $self, @args) = @_;
  my $file = shift @args;
  if (not defined $file) {
    $file = $self->file;
  }

  my $z = new Compress::Raw::Zlib::Deflate;

  my ($outbuf, $status, $outFH, $tmpFHout, $tmpFHin, $tmpbuf);
  open($outFH, ">", $file) || die "cannot write to file [$file]";
  open($tmpFHout, ">", \$tmpbuf) || die "no write access memory ?!";
  open($tmpFHin, "<", \$tmpbuf) || die "no read access memory ?!";

  map { binmode $_, ":bytes"; } $outFH, $tmpFHout, $tmpFHin;
#  Archive::Tar will space pad numbers by default
#  (which makes sense considering they are ascii formatted numbers)
#  however, according to the android code, these entries can be space
#  or nul terminated
#  see BackupManagerService.java :: extractRadix
#
  $Archive::Tar::ZERO_PAD_NUMBERS = 1;

  $self->$orig($tmpFHout);

  $self->write_header($outFH);

  while (<$tmpFHin>) {
    $status = $z->deflate($_, $outbuf) ;

    $status == Z_OK or die "deflation failed\n" ;

    print $outFH $outbuf;
  }
  $status = $z->flush($outbuf);

  $status == Z_OK or die "deflation failed\n" ;

  print $outFH $outbuf;

  map { close $_; } $outFH, $tmpFHout, $tmpFHin;
};


sub add_dir
{
  my ($self, $dir) = @_;

  return unless (-d $dir);

  my $index = new Archive::AndroidBackup::TarIndex;
  find(sub { $index->build_from_str($File::Find::name); }, $dir);

  $self->add_files( $index->as_array );
}

no Moose;
__PACKAGE__->meta->make_immutable;

=pod
=head1 NAME

=head1 SYNOPSIS

=head1 METHODS

=head2 write


=head 2 read($file)

  performs 

=head2 add_dir($dir)
  emulate tar -cf dir

  will correctly sort directory index the way android backup needs it
  (aka the implementation peculiarity that spawned this whole project)



=cut
1;
