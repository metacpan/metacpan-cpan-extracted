## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Base class for datum I/O

package DTA::CAB::Format;
use DTA::CAB::Format::Registry; ##-- registry
use DTA::CAB::Utils;
use DTA::CAB::Persistent;
use DTA::CAB::Logger;
use DTA::CAB::Datum;
use DTA::CAB::Token;
use DTA::CAB::Sentence;
use DTA::CAB::Document;
use IO::File;
use IO::Handle;
use File::Map qw();
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Persistent DTA::CAB::Logger);

## $CLASS_DEFAULT
##  + default format class for newFormat()
our $CLASS_DEFAULT = 'DTA::CAB::Format::TT';

## $REG
##  + global format registry, a DTA::CAB::Format::Registry object
our ($REG);
BEGIN {
  $REG = DTA::CAB::Format::Registry->new();
}

BEGIN {
  *isa = \&UNIVERSAL::isa;
  *can = \&UNIVERSAL::can;
}

our $LL_BLK_DEBUG = undef; ##-- log level for block debugging

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    {
##     ##-- DTA::CAB::IO: common
##     utf8 => $bool,                 ##-- use UTF-8 I/O, where applicable; default=1
##
##     ##-- DTA::CAB::IO: input parsing
##     #(none)
##
##     ##-- DTA::CAB::IO: output formatting
##     level    => $formatLevel,      ##-- formatting level, where applicable
##     outbuf   => $stringBuffer,     ##-- output buffer, where applicable
##    }
sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- DTA::CAB::IO: common
		   utf8 => 1,

		   ##-- DTA::CAB::IO: input parsing
		   #(none)

		   ##-- DTA::CAB::IO: output formatting
		   #level    => undef,
		   #outbuf   => undef,

		   ##-- user args
		   @_
		  }, ref($that)||$that);
  return $fmt;
}

## undef = $fmt->DESTROY()
##  + destructor
##  + default implementation calls close()
sub DESTROY {
  $_[0]->close();
}

## $fmt = CLASS->newFormat($class_or_short_or_class_suffix, %opts)
##  + wrapper for DTA::CAB::Format::Registry::newFormat(); accepts %opts qw(class file)
sub newFormat {
  my ($that,$class,%opts) = @_;
  return $REG->newFormat($class,%opts);
}

## $fmt = CLASS->newReader(%opts)
##  + wraper for DTA::CAB::Format::Registry::newReader; accepts %opts qw(class file)
sub newReader {
  my ($that,%opts) = @_;
  return $REG->newReader(%opts) // $CLASS_DEFAULT->new(%opts);
}

## $fmt = CLASS->newWriter(%opts)
##  + wraper for DTA::CAB::Format::Registry::newWriter; accepts %opts qw(class file)
sub newWriter {
  my ($that,%opts) = @_;
  return $REG->newWriter(%opts) // $CLASS_DEFAULT->new(%opts);
}

##==============================================================================
## Methods: Global Format Registry

## \%registered = $CLASS_OR_OBJ->registerFormat(%opts)
##  + wrapper for DTA::CAB::Format::Registry::register()
sub registerFormat {
  my ($that,%opts) = @_;
  $opts{name} = (ref($that)||$that) if (!defined($opts{name}));
  return $REG->register(%opts);
}

## \%registered_or_undef = $CLASS_OR_OBJ->guessFilenameFormat($filename)
##  + wrapper for DTA::CAB::Format::Registry::guessFilenameFormat()
sub guessFilenameFormat {
  return $REG->guessFilenameFormat($_[1]);
}

## $readerClass_or_undef = $CLASS_OR_OBJ->fileReaderClass($filename)
##  + wrapper for DTA::CAB::Format::Registry::fileReaderClass()
sub fileReaderClass {
  return $REG->fileReaderClass($_[1]);
}

## $readerClass_or_undef = $CLASS_OR_OBJ->fileWriterClass($filename)
##  + wrapper for DTA::CAB::Format::Registry::fileWriterClass()
sub fileWriterClass {
  return $REG->fileWriterClass($_[1]);
}

## $registered_or_undef = $CLASS_OR_OBJ->short2reg($shortname)
##  + wrapper for DTA::CAB::Format::Registry::short2reg()
sub short2reg {
  return $REG->short2reg($_[1]);
}

## $registered_or_undef = $CLASS_OR_OBJ->base2reg($basename)
##  + wrapper for DTA::CAB::Format::Registry::base2reg()
sub base2reg {
  return $REG->base2reg($_[1]);
}


##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + default returns qw(outbuf fh tmpfh)
sub noSaveKeys {
  return qw(outbuf fh tmpfh);
}

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + default inherited from DTA::CAB::Persistent

##==============================================================================
## Methods: I/O : Generic
##==============================================================================

## $fmt = $fmt->close()
## $fmt = $fmt->close($savetmp)
##  + close current input source, if any
##  + default calls $fmt->{tmpfh}->close() if available and $savetmp is false (default)
##  + always deletes $fmt->{fh} and $fmt->{doc}
sub close {
  if (!$_[1] && $_[0]{tmpfh}) {
    $_[0]{tmpfh}->close() if ($_[0]{tmpfh}->opened);
    delete($_[0]{tmpfh});
  }
  #$_[0]{fh}->close() if ($_[0]{fh} && $_[0]{fh}->opened());
  delete(@{$_[0]}{qw(fh doc)});
  return $_[0];
}

## @layers = $fmt->iolayers()
##  + returns PerlIO layers to use for I/O handles
##  + default returns ':utf8' if $fmt->{utf8} is true, otherwise ':raw'
sub iolayers {
  return ($_[0]{utf8} ? ':utf8' : ':raw');
}

## $fmt = $fmt->setLayers()
## $fmt = $fmt->setLayers($fh)
## $fmt = $fmt->setLayers($fh,@layers)
##  + wrapper for binmode($fh,$_) foreach (@layers ? @layers : $fmt->iolayers)
sub setLayers {
  my ($fmt,$fh,@layers) = @_;
  $fh = $fmt->{fh} if (!defined($fh));
  return $fmt if (!defined($fh));
  binmode($fh,$_) foreach (@layers ? @layers : $fmt->iolayers);
  return $fmt;
}


##==============================================================================
## Methods: I/O: Block-wise
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Generic

## %blockOpts = $CLASS_OR_OBJECT->blockDefaults()
##  + returns default block options as for blockOptions()
##  + default implementation just returns (bsize=>(128*1024), eob=>'s')
sub blockDefaults {
  return (bsize=>(128*1024), eob=>'s');
}

## %blockOpts = $CLASS_OR_OBJECT->blockOptions($block_spec)
##  + parses $block_spec as a block-boundary spec, which is a string of the form
##            MIN_BYTES[{k,M,G,T}][@EOB]
##    where:
##    - MIN_BYTES[{k,M,G,T}] is the minimum block size in bytes, with optional SI suffix
##    - EOB indicates desired block boundary: either 's' (sentence) or 'w' (word)
##  + returns a hash with 'size' and 'where' keys
##  + pukes if not parseable
sub blockOptions {
  my ($fmt,$bspec) = @_;
  if (($bspec||'') =~ /^([0-9\.]*)([bkmgt])?(?:[:\@](.*))?$/i) {
    my ($n,$suff,$eob) = ($1,lc($2),$3);
    $n *= 2**10 if ($suff eq 'k');
    $n *= 2**20 if ($suff eq 'm');
    $n *= 2**30 if ($suff eq 'g');
    $n *= 2**40 if ($suff eq 't');
    return ($fmt->blockDefaults(), ($n ? (bsize=>$n) : qw()), ($eob ? (eob=>$eob) : qw()));
  }
  $fmt->logconfess("parseBlockOpts(): could not parse block specification '$bspec'");
  return $fmt->blockDefaults();
}

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Input

## \@blocks = $fmt->blockScan($infile, %opts)
##  + scans $filename for block boundaries according to %opts, which may contain:
##    (
##     bsize => $bytes,      ##-- minimum block-size in bytes
##     eob  => $eob,         ##-- block boundary type; either 's' (sentence) or 't' (word); default='w'
##    )
##  + sets local keys in %opts passed to sub-methods blockScan{Head,Body,Foot}()
##    (
##     ifile => $infile,      ##-- (in) input filename
##     ifsize => $bytes,      ##-- (in) total size of $infile in bytes (-s $infile)
##     ihead => [$off,$len],  ##-- (in) offset, length of header in $infile
##     ifoot => [$off,$len],  ##-- (in) offset, length of footer in $infile
##     ibody => \@iblocks,    ##-- (in) blocks computed by blockScanBody()
##     ohead => [$off,$len],  ##-- (out) offset, length of header in $$odata
##     ofoot => [$off,$len],  ##-- (out) offset, length of footer in $$odata
##    )
##  + returns an ARRAY ref of block specifications \@blocks = [$blk1,$blk2,...]
##    where each $blk \in @blocks is a HASH-ref containing at least the following keys:
##    {
##     ifile => $infile,      ##-- (in) input filename
##     #isize => $bytes,       ##-- (in) total size of $filename in bytes (-s $filename)
##     ioff  => $offset,      ##-- (in) byte-offset of block beginning in $infile
##     ilen  => $len,         ##-- (in) byte-length of block in $infile
##     id    => [$i,$N]       ##-- (in/out) indices s.t. $blk=$blocks[$i], $N=$#blocks
##    }
##  + additionally, $blk may contain the following keys:
##    {
##     ihead => [$off,$len],  ##-- (in) set by blockScanHead() for $infile
##     ifoot => [$off,$len],  ##-- (in) set by blockScanFoot() for $infile
##     ibody => \@iblocks,    ##-- (in) blocks computed by blockScanBody()
##     eos   => $bool,        ##-- (in/out) true if block ends on a sentence boundary (for TT, TJ)
##     odata => \$odata,      ##-- (out) block data octets (for blockAppend())
##     ohead => [$off,$len],  ##-- (out) set by blockScanHead() for $odata
##     ofoot => [$off,$len],  ##-- (out) set by blockScanFoot() for $odata
##     ofile => $ofilename,   ##-- (out) output filename (for Queue::Server::addblock())
##     ofmt  => $class,       ##-- (out) output formatter class or short name (for Queue::Server::addblock())
##    }
##  + default implementation here calls $fmt->blockScanHead(), $fmt->blockScanBody(), $fmt->blockScanFoot();
##    then sets @$blk{qw(ifile ihead ifoot id)} for each body block
sub blockScan {
  my ($fmt,$infile,%opts) = @_;
  $opts{bsize} = 128*1024 if (!defined($opts{bsize}));
  $opts{eob}   = 'w' if (!defined($opts{eob}));
  $fmt->vlog('trace', "blockScan(size=$opts{bsize}, eob=$opts{eob}, file=$infile)");

  ##-- mmap file
  $opts{ifile}  = $infile;
  $opts{ifsize} = (-s $infile);
  my ($buf);
  File::Map::map_file($buf, $infile,'<',0,$opts{fsize});

  ##-- scan blocks into head, body, foot
  my $ihead = $opts{ihead} = $fmt->blockScanHead(\$buf,'i',\%opts);
  my $ibody = $opts{ibody} = $fmt->blockScanBody(\$buf,    \%opts);
  my $ifoot = $opts{ifoot} = $fmt->blockScanFoot(\$buf,'i',\%opts);

  ##-- adopt 'n', 'head', 'foot' keys into body blocks
  my ($blk);
  my $llBlockScan = undef;
  $fmt->vlog($llBlockScan, "blockScan: $infile \[head]: $ihead->[0] +$ihead->[1] =".($ihead->[0]+$ihead->[1])." <$opts{ifsize}");
  foreach (0..$#$ibody) {
    $blk = $ibody->[$_];
    $blk->{id}    = [$_,$#$ibody] if (!defined($blk->{id}));
    $blk->{ifile} = $infile  if (!defined($blk->{ifile}));
    $blk->{ihead} = $ihead   if (!defined($blk->{ihead}));
    $blk->{ifoot} = $ifoot   if (!defined($blk->{ifoot}));
    $fmt->vlog($llBlockScan, "blockScan: $infile \[".($_+1)."/".($#$ibody+1)."]: $blk->{ioff} +$blk->{ilen} =".($blk->{ioff}+$blk->{ilen})." <$opts{ifsize}");
  }
  $fmt->vlog($llBlockScan, "blockScan: $infile \[foot]: $ifoot->[0] +$ifoot->[1] =".($ifoot->[0]+$ifoot->[1])." <$opts{ifsize}");

  ##-- cleanup & return
  File::Map::unmap($buf);
  return $ibody;
}

## \@head = $fmt->blockScanHead(\$buf,$io,\%opts)
##  + scans for block header (${io}head); returns [$offset,$length] for block header in (mmaped) \$buf
##  + defatult implementation just returns [0,0] (empty header)
sub blockScanHead {
  my ($fmt,$bufr,$io,$opts) = @_;
  return [0,0];
}

## \@foot = $fmt->blockScanFoot(\$buf,$io,\%opts)
##  + scans for block footer (${io}foot); returns [$offset,$length] for block footer in (mmaped) \$buf
##  + may adjust contents of $opts{${io}body}
##  + default implementation just returns [0,0] (empty footer)
sub blockScanFoot {
  my ($fmt,$bufr,$io,$opts) = @_;
  return [0,0];
}

## \@blocks = $fmt->blockScanBody(\$buf,\%opts)
##  + guts for blockScan(); input only
##  + default implementation just dies
sub blockScanBody {
  my ($fmt,$bufr,$opts) = @_;
  $fmt->logconfess("blockScanBody(): method not implemented in abstract base class ", __PACKAGE__);
}


## \$buf = $fmt->blockReadChunk($fh,$f_off,$f_len, \$buf, $b_off=length($buf))
##   + append a string of $f_len bytes starting from $f_off in file $fh to buffer \$buf at $b_off
sub blockReadChunk {
  my ($fmt, $fh,$off,$len, $bufr,$boff) = @_;
  $boff = defined($$bufr) ? length($$bufr) : 0 if (!defined($boff));
  sysseek($fh, $off, SEEK_SET)
    or $fmt->logconfess("blockReadChunk(): sysseek($off) failed: $!");
  sysread($fh, $$bufr, $len, $boff)==$len
    or $fmt->logconfess("blockReadChunk(): sysread() failed for chunk of length $len: $!");
  return $bufr;
}

## \$buf = $fmt->blockRead(\%blk)
## \$buf = $fmt->blockRead(\%blk,\$buf)
##   + reads block input data for \%blk into \$bufr
##   + default implementation just appends raw bytes for:
##     - block header @{$blk{ihead}}
##     - block body   @blk{qw(ioff ilen)}
##     - block footer @{$blk{ifoot}}
sub blockRead {
  my ($fmt,$blk,$bufr) = @_;
  $bufr     = \(my $buf) if (!defined($bufr));
  $$bufr    = '';
  my $infile = ($blk->{ifile} || $blk->{file});
  my $infh   = IO::File->new("<$infile")
    or $fmt->logconfess("blockRead(): open failed for '$infile': $!");
  binmode($infh,':raw');

  $fmt->blockReadChunk($infh, @{$blk->{ihead}}, $bufr)     if ($blk->{ihead} && $blk->{ihead}[1]);   ##-- head
  $fmt->blockReadChunk($infh, @$blk{qw(ioff ilen)}, $bufr) if ($blk->{ilen});                        ##-- body
  $fmt->blockReadChunk($infh, @{$blk->{ifoot}}, $bufr)     if ($blk->{ifoot} && $blk->{ifoot}[1]);  ##-- foot

  $infh->close();
  return $bufr;
}

## $doc = $fmt->parseBlock(\%blk)
##  + parses a block into a DTA::CAB::Document
##  + wrapper for blockRead(), parseString(), close()
sub parseBlock {
  my ($fmt,$blk) = @_;
  my $ibufr = $fmt->blockRead($blk);
  my $doc   = $fmt->parseString($ibufr);
  $fmt->close();
  return $doc;
}


##--------------------------------------------------------------
## Methods: I/O: Block-wise: Output

## $blk = $fmt->blockStore(\$odata,$blk,\%bopt={})
##  + store output buffer \$buf in $blk->{odata}
##  + additionally store keys qw(ofmt ohead odata ofoot) relative to $blk->{odata}
##  + default calls blockScanHead(), blockScanFoot() with dummy options only if not already set in $blk
sub blockStore {
  my ($fmt,$bufr,$blk,$bopt) = @_;

  $bopt = {} if (!defined($bopt));
  $blk->{id}    = [0,0] if (!defined($blk->{id}));
  $blk->{ohead} = ($blk->{id}[0]==0             ? [0,0] : $fmt->blockScanHead($bufr,'o',{%$blk,%$bopt})) if (!defined($blk->{ohead}));
  $blk->{obody} = [$blk]                                                                                 if (!defined($blk->{obody}));
  $blk->{ofoot} = ($blk->{id}[0]==$blk->{id}[1] ? [0,0] : $fmt->blockScanFoot($bufr,'o',{%$blk,%$bopt})) if (!defined($blk->{ofoot}));
  $blk->{odata} = $bufr            if (!defined($blk->{odata}));
  $blk->{ofmt}  = $fmt->shortName  if (!defined($blk->{ofmt}));

  return $blk;
}

## $fmt = $fmt->putDocumentBlock($doc,$blk)
##  + wrapper for $fmt->toString(\(my $buf))->putDocumentRaw()->flush()->blockStore(\$buf,$blk)
sub putDocumentBlock {
  my ($fmt,$doc,$blk) = @_;
  my $buf = '';
  $fmt->toString(\$buf)->putDocumentRaw($doc)->flush()->blockStore(\$buf,$blk);
  return $fmt;
}

## $fmt_or_undef = $fmt->blockAppend($blk)
## $fmt_or_undef = $fmt->blockAppend($blk,$ofile)
##  + append a block $block to a file $ofile (default=$blk->{ofile})
##  + $block is a HASH-ref as returned by blockScan()
##  + default implementation just dumps $blk->{odata} to $filename;
##    modulo @$blk{qw(ohead ofoot)} as appropriate
sub blockAppend {
  my ($fmt,$blk,$ofile) = @_;
  $ofile = $blk->{ofile} if (!defined($ofile));

  ##-- common variables
  use bytes;
  my $bufr  = $blk->{odata};
  my $id    = $blk->{id}    || [0,0];
  my $ohead = $blk->{ohead} || [0,0];
  my $ofoot = $blk->{ofoot} || [0,0];

  my $blkid = "${ofile}:$id->[0]/$id->[1]";
  my $outfh = IO::File->new(($id->[0]==0 ? '>' : '>>').$ofile)
    or $fmt->logconfess("blockAppend(): open failed for '$ofile': $!");
  binmode($outfh, utf8::is_utf8($$bufr) ? ':utf8' : ':raw');

  $fmt->vlog($LL_BLK_DEBUG, "blockAppend($blkid): begin: pos=", $outfh->tell, "; buflen=", bytes::length($$bufr));
  $fmt->vlog($LL_BLK_DEBUG, "blockAppend($blkid): ohead=[$ohead->[0],$ohead->[1]]; ofoot=[$ofoot->[0],$ofoot->[1]]");

  ##-- dump: header (initial block only)
  if ($id->[0]==0 && $ohead->[1]>0) {
    $outfh->print(substr($$bufr, $ohead->[0], $ohead->[1]-$ohead->[0]))
      or $fmt->logconfess("blockAppend(): print failed to '$ofile' for initial-block header: $!");
    $fmt->vlog($LL_BLK_DEBUG, "blockAppend($blkid): wrote ", ($ohead->[1]-$ohead->[0]), " header bytes\n");
  }

  ##-- dump: body
  $outfh->print(substr($$bufr, $ohead->[1], ($ofoot->[0]||length($$bufr))-($ohead->[0]+$ohead->[1])))
    or $fmt->logconfess("blockAppend(): print failed to '$ofile' for block body: $!");
  $fmt->vlog($LL_BLK_DEBUG, "blockAppend($blkid): wrote ", (($ofoot->[0]||length($$bufr))-($ohead->[0]+$ohead->[1])), " data bytes");

  ##-- dump: footer (final block only)
  if ($id->[0]==$id->[1] && $ofoot->[1]>0) {
    $outfh->print(substr($$bufr, $ofoot->[0], $ofoot->[1]-$ofoot->[0]))
      or $fmt->logconfess("blockAppend(): print failed to '$ofile' for final-block footer: $!");
    $fmt->vlog($LL_BLK_DEBUG, "blockAppend($blkid): wrote ", ($ofoot->[1]-$ofoot->[0]), " footer bytes");
  }

  ##-- cleanup & return
  $fmt->vlog($LL_BLK_DEBUG, "blockAppend($blkid): finished, pos=", $outfh->tell);
  $outfh->close;
  return $fmt;
}

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->from(fh=>$fh)
## $fmt = $fmt->from(file=>$file)
## $fmt = $fmt->from(string=>$str)
## $fmt = $fmt->from(string=>\$str)
##  + open $fmt for input from specified source
##  + wraps fromFh(), fromFile(), fromString()
sub from {
  my $fmt   = shift;
  my $which = shift;
  return $fmt->fromFh(@_)   if ($which eq 'fh');
  return $fmt->fromFile(@_) if ($which eq 'file');
  return $fmt->fromString(@_);
}

## $fmt = $fmt->fromString( $string)
## $fmt = $fmt->fromString(\$string)
##  + select input from string $string
##  + default calls $fmt->fromFh($fmt->{tmpfh}=$new_fh)
sub fromString {
  my $fmt = shift;
  $fmt->close;
  my $fh = IO::Handle->new();
  CORE::open($fh, '<', ref($_[0]) ? $_[0] : \$_[0])
      or $fmt->logconfess("fromString(): open failed for string input: $!");
  return $fmt->fromFh($fmt->{tmpfh}=$fh);
}

## $fmt = $fmt->fromFile($filename)
##  + select input from file $filename
##  + default calls $fmt->fromFh($fmt->{tmpfh}=$new_fh)
sub fromFile {
  my ($fmt,$file) = @_;
  $fmt->close;
  my $fh = (ref($file) ? $file : IO::File->new("<$file"))
    or $fmt->logconfess("fromFile(): open failed for '$file'");
  return $fmt->fromFh($fmt->{tmpfh}=$fh);
}

## $fmt = $fmt->fromFh($fh)
##  + select input from open filenandle $fh
##  + default implementation just calls $fmt->close(1) and sets $fmt->{fh}=$fh
sub fromFh {
  my ($fmt,$fh) = @_;
  $fmt->logconfess("fromFh(): abstract method called for object instance") if ($fmt->can('fromFh') eq \&fromFh); ##-- sanity check
  $fmt->close(1);            ##-- keep $fmt->{tmpfh} for auto-close
  $fmt->{fh} = $fh;          ##-- save this handle for later use
  #$fmt->setLayers();        ##-- set perlIO layers
  #$fmt->logconfess("fromFh() not implemented");
  return $fmt;
}

## $fmt = $fmt->fromFh_str($fh)
##  + alternate fromFh() implementation which slurps contents of $fh and calls $fmt->fromString(\$str)
sub fromFh_str {
  my ($fmt,$fh) = @_;
  $fmt->DTA::CAB::Format::fromFh($fh);
  $fmt->setLayers();
  local $/=undef;
  my $str = <$fh>;
  return $fmt->fromString(\$str);
}

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##   + parse document from currently selected input source
sub parseDocument {
  my $fmt = shift;
  $fmt->logconfess("parseDocument() not implemented in abstract base class ", __PACKAGE__ );
}

## $doc = $fmt->parseString( $str)
## $doc = $fmt->parseString(\$str)
##   + wrapper for $fmt->fromString(\$str)->parseDocument()
sub parseString {
  my $doc = $_[0]->fromString(ref($_[1]) ? $_[1] : \$_[1])->parseDocument;
  $_[0]->close();
  return $doc;
}

## $doc = $fmt->parseFile($filename_or_fh)
##   + wrapper for $fmt->fromFile($filename_or_fh)->parseDocument()
sub parseFile {
  my $doc = $_[0]->fromFile($_[1])->parseDocument;
  $_[0]->close();
  return $doc;
}

## $doc = $fmt->parseFh($fh)
##   + wrapper for $fmt->fromFh($filename_or_fh)->parseDocument()
sub parseFh {
  my $doc = $_[0]->fromFh($_[1])->parseDocument;
  $_[0]->close();
  return $doc;
}

##--------------------------------------------------------------
## Methods: Input: Utilties

## $doc = $fmt->forceDocument($reference)
##  + attempt to tweak $reference into a DTA::CAB::Document
##  + a slightly more in-depth version of DTA::CAB::Datum::toDocument()
sub forceDocument {
  my ($fmt,$any) = @_;
  if (!ref($any)) {
    ##-- string: token-like
    #return bless({body=>[ bless({tokens=>[bless({text=>$any},'DTA::CAB::Token')]},'DTA::CAB::Sentence') ]},'DTA::CAB::Document');
    $any ={body=>[ {tokens=>[{text=>$any}] }] };
  }
  elsif (isa($any,'DTA::CAB::Document')) {
    ##-- document
    ; #$any;
  }
  elsif (isa($any,'DTA::CAB::Sentence')) {
    ##-- sentence
    $any = {body=>[$any]};
  }
  elsif (isa($any,'DTA::CAB::Token')) {
    ##-- token
    #return bless({body=>[ bless({tokens=>[$any]},'DTA::CAB::Sentence') ]},'DTA::CAB::Document');
    $any= {body=>[ {tokens=>[$any]} ]};
  }
  elsif (ref($any) eq 'HASH') {
    ##-- hash
    if (exists($any->{body})) {
      ##-- hash, document-like
      #return bless($any,'DTA::CAB::Document');
      ;
    }
    elsif (exists($any->{tokens})) {
      ##-- hash, sentence-like
      $any = {body=>[$any]};
    }
    elsif (exists($any->{text})) {
      ##-- hash, token-like
      $any = {body=>[ {tokens=>[$any]} ]};
    }
  }
  elsif (ref($any) eq 'ARRAY') {
    ##-- array
    if (!ref($any->[0])) {
      ##-- array; assumedly of token strings
      $_ = {text=>$_} foreach (grep {!ref($_)} @$any);
      $any = {body=>[ {tokens=>$any} ]};
    }
  }
  else {
    ##-- something else
    $fmt->warn("forceDocument(): cannot massage non-document '".(ref($any)||$any)."'");
    return $any;
  }
  $any = bless($any,'DTA::CAB::Document') if (!isa($any,'DTA::CAB::Document'));
  return $any;
}

##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + default returns text/plain
sub contentType { return $_[0]->mimeType(@_[1..$#_]); }
sub mimeType    { return 'text/plain'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format (default='.cab')
sub defaultExtension { return '.cab'; }

## $short = $fmt->shortName()
##  + returns "official" short name for this format
##  + default just returns package suffix
sub shortName {
  my $short = shift;
  $short = ref($short) || $short;
  if ($short =~ s/^DTA::CAB::Format:://) {
    $short =~ s/://g;
  } else {
    $short =~ s/^.*\:\://;
  }
  return lc($short);
}

## $lvl = $fmt->formatLevel()
## $fmt = $fmt->formatLevel($level)
##  + set output formatting level
sub formatLevel {
  my ($fmt,$level) = @_;
  return $fmt->{level} if (!defined($level));
  $fmt->{level}=$level;
  return $fmt;
}

## $fmt = $fmt->flush()
##  + flush any buffered output to selected output source
##  + default implementation deletes $fmt->{outbuf} and calls $fmt->{fh}->flush()
sub flush {
  delete($_[0]{outbuf});
  $_[0]{fh}->flush() if (defined($_[0]{fh}));
  return $_[0];
}

##--------------------------------------------------------------
## Methods: Output: output selection

## $fmt = $fmt->to(fh=>$fh)
## $fmt = $fmt->to(file=>$file)
## $fmt = $fmt->to(string=>\$str)
##  + open $fmt for output to specified destination
##  + wraps toFh(), toFile(), toString()
sub to {
  my $fmt  = shift;
  my $which = shift;
  return $fmt->toFh(@_)   if ($which eq 'fh');
  return $fmt->toFile(@_) if ($which eq 'file');
  return $fmt->toString(@_);
}


## $fmt = $fmt->toString(\$str, $level)
##  + select output to $str
##  + default implementation just wraps $fmt->toFh($fmt->{tmpfh}=$new_fh, $level)
sub toString {
  my $fmt = shift;
  $fmt->close;
  my $fh = IO::Handle->new();
  CORE::open($fh, '>', ref($_[0]) ? $_[0] : \$_[0])
      or $fmt->logconfess("toString(): open failed for string output: $!");
  return $fmt->toFh($fmt->{tmpfh}=$fh, $_[1]);
}

## $fmt_or_undef = $fmt->toFile($filename, $formatLevel)
##  + select output to named file $filename
##  + default implementation just wraps $fmt->toFh($fmt->{tmpfh}=$new_fh, $level)
sub toFile {
  my ($fmt,$file,$level) = @_;
  $fmt->close;
  my $fh = (ref($file) ? $file : IO::File->new(">$file"))
    or $fmt->logconfess("toFile(): open failed for '$file'");
  return $fmt->toFh($fmt->{tmpfh}=$fh, $level);
}

## $fmt_or_undef = $fmt->toFh($fh,$level)
##  + select output to an open filehandle $fh
##  + default implementation just calls $fmt->formatLevel($level) and sets $fmt->{fh}=$fh
sub toFh {
  my ($fmt,$fh,$level) = @_;
  #$fmt->logconfess("toFh(): abstract method called for object instance") if ($fmt->can('toFh') eq \&toFh); ##-- sanity check
  $fmt->formatLevel($level) if (defined($level));
  $fmt->{fh}=$fh;
  #$fmt->setLayers($fh) ##-- set I/O layers
  #$fh->print($fmt->{outbuf});
  return $fmt;
}

## $fmt_or_undef = $fmt->buf2fh(\$inbuf=\$fmt->{outbuf},$fh)
##  + low-level utility which dumps $$buf to $fh
##  + may call utf8::encode() or utf8::upgrade() on $inbuf
sub buf2fh {
  my ($fmt,$bufr,$fh) = @_;
  $bufr = \$fmt->{outbuf} if (!defined($bufr));
  my $buf_u8 = utf8::is_utf8($$bufr);
  my $fh_u8  = grep {$_ eq 'utf8'} PerlIO::get_layers($fh);
  if ($buf_u8 && !$fh_u8) {
    ##-- utf8 -> bytes: encode buffer
    utf8::encode($$bufr);
  } elsif (!$buf_u8 && $fh_u8) {
    ##-- bytes -> utf8: upgrade buffer
    utf8::upgrade($$bufr);
  }
  $fh->print($$bufr);
  return $fmt;
}

## $fmt_or_undef = $fmt->buf2bytes(\$inbuf=\$fmt->{outbuf},\$outbuf)
##  + low-level utility which copies raw bytes of $$inbuf to $$outbuf
sub buf2bytes {
  my ($fmt,$ibufr,$obufr) = @_;
  $ibufr  = \$fmt->{outbuf} if (!defined($ibufr));
  $$obufr = $$ibufr;
  utf8::encode($$obufr) if (utf8::is_utf8($$obufr));
  return $fmt;
}

## $fmt_or_undef = $fmt->toFh_buf($fh,$formatLevel)
##  + toFh() implementation which dumps $fmt->{outbuf} to $fmt->{fh}=$fh
#sub toFh_buf {
#  my $fmt = shift;
#  $fmt->DTA::CAB::Format::toFh($fmt,@_);    ##-- set $fmt->{level}, $fmt->{fh}
#  binmode($fmt->{fh}, (utf8::is_utf8($fmt->{outbuf}) ? ':utf8' : ':raw'));
#  $fmt->{fh}->print($fmt->{outbuf});
#  return $fmt;
#}

##--------------------------------------------------------------
## Methods: Output: Recommended API

## $fmt = $fmt->putToken($tok)
##  + default implementations of other methods assume output is concatenated onto $fmt->{outbuf}
sub putTokenRaw { return $_[0]->putToken($_[1]); }
sub putToken {
  my $fmt = shift;
  $fmt->logconfess("putToken() not implemented!");
  return undef;
}

## $fmt = $fmt->putSentence($sent)
##  + default implementation just iterates $fmt->putToken() & appends 1 additional "\n" to $fmt->{outbuf}
sub putSentenceRaw { return $_[0]->putSentence($_[1]); }
sub putSentence {
  my ($fmt,$sent) = @_;
  $fmt->putToken($_) foreach (@{toSentence($sent)->{tokens}});
  $fmt->{outbuf} .= "\n";
  return $fmt;
}

##--------------------------------------------------------------
## Methods: Output: Required API

## $fmt = $fmt->putDocument($doc)
##  + default implementation just iterates $fmt->putSentence()
##  + should be non-destructive for $doc
sub putDocument {
  my ($fmt,$doc) = @_;
  $fmt->putSentence($_) foreach (@{toDocument($doc)->{body}});
  return $fmt;
}

## $fmt = $fmt->putDocumentRaw($doc)
##  + may copy plain $doc reference
sub putDocumentRaw { return $_[0]->putDocument($_[1]); }


## $fmt = $fmt->putData($data)
##  + put arbitrary raw data (e.g. for YAML, JSON, XmlPerl)
sub putData {
  $_[0]->logconfess("putData() not implemented!");
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, & edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format - Base class for DTA::CAB::Datum I/O

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = $CLASS_OR_OBJ->new(%args);
 $fmt = $CLASS->newFormat($class_or_class_suffix, %opts);
 $fmt = $CLASS->newReader(%opts);
 $fmt = $CLASS->newWriter(%opts);
 
 ##========================================================================
 ## Methods: Global Format Registry
 
 \%classReg_or_undef = $CLASS_OR_OBJ->registerFormat(%classRegOptions);
 \%classReg_or_undef = $CLASS_OR_OBJ->guessFilenameFormat($filename);
 
 $readerClass_or_undef = $CLASS_OR_OBJ->fileReaderClass($filename);
 $readerClass_or_undef = $CLASS_OR_OBJ->fileWriterClass($filename);
 
 $class_or_undef = $CLASS_OR_OBJ->shortReaderClass($shortname);
 $class_or_undef = $CLASS_OR_OBJ->shortWriterClass($shortname);
 
 $registered_or_undef = $CLASS_OR_OBJ->short2reg($shortname);
 $registered_or_undef = $CLASS_OR_OBJ->base2reg($basename);
 
 ##========================================================================
 ## Methods: Persistence
 
 @keys = $class_or_obj->noSaveKeys();
 
 ##========================================================================
 ## Methods: MIME
 
 $short = $fmt->shortName();
 $type = $fmt->mimeType();
 $ext = $fmt->defaultExtension();
 
 ##========================================================================
 ## Methods: Input
 
 $fmt = $fmt->close();
 $fmt = $fmt->fromString(\$string);
 $fmt = $fmt->fromFile($filename);
 $fmt = $fmt->fromFh($fh);
 $doc = $fmt->parseDocument();
 $doc = $fmt->parseString(\$str);
 $doc = $fmt->parseFile($filename);
 $doc = $fmt->parseFh($fh);
 $doc = $fmt->forceDocument($reference);
 
 ##========================================================================
 ## Methods: Output
 
 $lvl = $fmt->formatLevel();
 $fmt = $fmt->flush();
 $fmt_or_undef = $fmt->toString(\$str, $formatLevel);
 $fmt_or_undef = $fmt->toFile($filename_or_handle, $formatLevel);
 $fmt_or_undef = $fmt->toFh($fh, $formatLevel);
 $fmt = $fmt->putDocument($doc);
 $fmt = $fmt->putDocumentRaw($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format is an abstract base class and API specification
for objects implementing an I/O format for the
L<DTA::CAB::Datum|DTA::CAB::Datum> subhierarchy in general,
and for L<DTA::CAB::Document|DTA::CAB::Document> objects in particular.

Each I/O format (subclass) has a characteristic abstract `base class' as well as optional
`reader' and `writer' subclasses which perform the actual I/O (although in
the current implementation, all reader/writer classes are identical with
their respective base classes).  Individual formats may be invoked
either directly by their respective classes (SUBCLASS-E<gt>new(), etc.),
or by means of the global L<DTA::CAB::Format::Registry|DTA::CAB::Format::Registry>
object $REG (L</registerFormat>, L</newFormat>, L</newReader>, L</newWriter>, etc.).

See L</SUBCLASSES> for a list of common built-in formats and their registry data.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Globals
=pod

=head2 Globals

=over 4

=item @ISA

DTA::CAB::Format inherits from
L<DTA::CAB::Persistent|DTA::CAB::Persistent>
and
L<DTA::CAB::Logger|DTA::CAB::Logger>.

=item $CLASS_DEFAULT

Default class returned by L</newFormat>()
if no known class is specified.

=item Variable: $REG

Default global format registry used,
a L<DTA::CAB::Format::Registry|DTA::CAB::Format::Registry> object
used by L</registerFormat>, L</newFormat>, etc.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

Constructor.

%args, %$fmt:

 ##-- DTA::CAB::Format: common
 ##
 ##-- DTA::CAB::Format: input parsing
 #(none)
 ##
 ##-- DTA::CAB::Format: output formatting
 level    => $formatLevel,      ##-- formatting level, where applicable
 outbuf   => $stringBuffer,     ##-- output buffer, where applicable


=item newFormat

 $fmt = CLASS->newFormat($class_or_class_suffix, %opts);

Wrapper for L</new>() which allows short class suffixes to
be passed in as format names.

=item newReader

 $fmt = CLASS->newReader(%opts);

Wrapper for L<DTA::CAB::Format::Registry::newReader|DTA::CAB::Format::Registry/newReader>
which accepts %opts:

 class => $class,    ##-- classname or DTA::CAB::Format:: suffix
 file  => $filename, ##-- attempt to guess format from filename

=item newWriter

 $fmt = CLASS->newWriter(%opts);

Wrapper for L<DTA::CAB::Format::Registry::newWriter|DTA::CAB::Format::Registry/newWriter>
which accepts %opts:

 class => $class,    ##-- classname or DTA::CAB::Format:: suffix
 file  => $filename, ##-- attempt to guess format from filename


=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Methods: Global Format Registry
=pod

=head2 Methods: Global Format Registry

The global format registry lives in the package variable $REG.
The following methods are backwards-compatible wrappers for
method calls to this registry object.

=over 4

=item registerFormat

 \%registered = $CLASS_OR_OBJ->registerFormat(%opts);

Registers a new format subclass;
wrapper for
L<DTA::CAB::Format::Registry::register|DTA::CAB::Format::Registry/register>().

=item guessFilenameFormat

 \%registered_or_undef = $CLASS_OR_OBJ->guessFilenameFormat($filename);

Returns registration record for most recently registered format subclass
whose C<filenameRegex> matches $filename.
Wrapper for L<DTA::CAB::Format::Registry::guessFilenameFormat|DTA::CAB::Format::Registry/guessFilenameFormat>().

=item fileReaderClass

 $readerClass_or_undef = $CLASS_OR_OBJ->fileReaderClass($filename);

Attempts to guess reader class name from $filename.
Wrapper for
L<DTA::CAB::Format::Registry::fileReaderClass|DTA::CAB::Format::Registry/fileReaderClass>().

=item fileWriterClass

 $readerClass_or_undef = $CLASS_OR_OBJ->fileWriterClass($filename);

Attempts to guess writer class name from $filename.
Wrapper for
L<DTA::CAB::Format::Registry::fileWriterClass|DTA::CAB::Format::Registry/fileWriterClass>().


=item short2reg

 $registered_or_undef = $CLASS_OR_OBJ->short2reg($shortname);

Gets the most recent subclass registry HASH ref for the short class name $shortname.
Wrapper for
L<DTA::CAB::Format::Registry::short2reg|DTA::CAB::Format::Registry/short2reg>().


=item base2reg

 $registered_or_undef = $CLASS_OR_OBJ->base2reg($basename);

Gets the most recent subclass registry HASH ref for the claass basename name $basename.
Wrapper for
L<DTA::CAB::Format::Registry::base2reg|DTA::CAB::Format::Registry/base2reg>().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();


Returns list of keys not to be saved
This implementation ignores the key C<outbuf>,
which is used by some many writer subclasses.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Methods: MIME
=pod

=head2 Methods: MIME

=over 4

=item shortName

 $short = $fmt->shortName();

Get short name for $fmt.  Default just returns lower-cased DTA::CAB::Format:: class suffix.
Short names are all lower-case by default.

=item mimeType

 $type = $fmt->mimeType();

Returns MIME type for $fmt.
Default returns 'text/plain'.

=item defaultExtension

 $ext = $fmt->defaultExtension();

Returns default filename extension for $fmt (default='.cab').

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Methods: Input
=pod

=head2 Methods: Input

=over 4

=item close

 $fmt = $fmt->close();
 $fmt = $fmt->close($savetmp);

Close current input source, if any.
Default implementation calls $fmt-E<gt>{tmpfh}->close() iff available and $savetmp is false (default).
Always deletes @$fmt{qw(fh doc)}.

=item fromString

 $fmt = $fmt->fromString(\$string);

Select input from the string $string.
Default implementation calls L<$fmt-E<gt>fromFh($fmt-E<gt>{tmpfh}=$new_fh)|/fromFh>.

=item fromFile

 $fmt = $fmt->fromFile($filename);

Select input from file $filename.
Default implementation calls L<$fmt-E<gt>fromFh($fmt-E<gt>{tmpfh}=$new_fh)|/fromFh>().

=item fromFh

 $fmt = $fmt->fromFh($fh);

Select input from open filehandle $fh.
Default implementation just calls L<$fmt-E<gt>close(1)|/close> and sets $fmt->{fh}=$fh.

=item fromFh_str

 $fmt = $fmt->fromFh_str($handle);

Alternate fromFh() implementation which slurps contents of $fh and calls L<$fmt-E<gt>fromString(\$str)|/fromString>.

=item parseDocument

 $doc = $fmt->parseDocument();

Parse document from currently selected input source.

=item parseString

 $doc = $fmt->parseString($str);

Wrapper for $fmt-E<gt>fromString($str)-E<gt>parseDocument().

=item parseFile

 $doc = $fmt->parseFile($filename_or_fh);

Wrapper for $fmt-E<gt>fromFile($filename_or_fh)-E<gt>parseDocument()

=item parseFh

 $doc = $fmt->parseFh($fh);

Wrapper for $fmt-E<gt>fromFh($filename_or_fh)-E<gt>parseDocument()


=item forceDocument

 $doc = $fmt->forceDocument($reference);

Attempt to tweak $reference into a L<DTA::CAB::Document|DTA::CAB::Document>.
This is
a slightly more in-depth version of L<DTA::CAB::Datum::toDocument()|DTA::CAB::Datum/item_toDocument>.
Current supported $reference forms are:

=over 4

=item L<DTA::CAB::Document|DTA::CAB::Document> object

returned literally

=item L<DTA::CAB::Sentence|DTA::CAB::Sentence> object

returns a new document
with a single sentence $reference.

=item L<DTA::CAB::Token|DTA::CAB::Token> object

returns a new document
with a single token $reference.

=item non-reference

returns a new document with a single token
whose 'text' key is $reference.

=item HASH reference with 'body' key

returns a bless()ed $reference as a L<DTA::CAB::Document|DTA::CAB::Document>.

=item HASH reference with 'tokens' key

returns a new document with the single
sentence $reference

=item HASH reference with 'text' key

returns a new document with the single
token $reference

=item ARRAY reference with non-reference initial element

returns a new document with a single sentence
whose 'tokens' field is set to $reference.

=item ... anything else

will cause a warning to be emitted and $reference to be
returned as-is.

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item formatLevel

 $lvl = $fmt->formatLevel();
 $fmt = $fmt->formatLevel($level)

Get/set output formatting level.

=item flush

 $fmt = $fmt->flush();

Flush any buffered output to selected output source.
Default implementation deletes $fmt-E<gt>{outbuf} and calls $fmt-E<gt>{fh}->flush() if available.

=item toString

 $fmt = $fmt->toString(\$str);
 $fmt = $fmt->toString(\$str,$formatLevel)

Select output to byte-string $str.
Default implementation just wraps $fmt-E<gt>toFh($fmt-E<gt>{tmpfh}=$new_fh, $level).

=item toString_buf

 $fmt_or_undef = $fmt->toString_buf(\$str)

Alternate toString() implementation which sets $str=$fmt->{outbuf}.

=item toFile

 $fmt_or_undef = $fmt->toFile($filename_or_handle, $formatLevel);

Select output to named file $filename.
Default implementation just wraps L<$fmt-E<gt>toFh($fmt-E<gt>{tmpfh}=$new_fh, $level)|/toFh>.

=item toFh

 $fmt_or_undef = $fmt->toFh($fh,$formatLevel);

Select output to an open filehandle $fh.
Default implementation just calls $fmt-E<gt>formatLevel($level) and sets $fmt-E<gt>{fh}=$fh.


=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format: Methods: Output: Recommended API
=pod

=head2 Methods: Output: Recommended API

=over 4

=item putToken

 $fmt = $fmt->putToken($tok);

Append a token to the selected output sink.

Should be non-destructive for $tok.

No default implementation,
but default implementations of other methods assume output is concatenated onto $fmt-E<gt>{outbuf}.

=item putTokenRaw

 $fmt = $fmt->putTokenRaw($tok)

Copy-by-reference version of L</putToken>.
Default implementation just calls L<$fmt-E<gt>putToken($tok)|/putToken>.

=item putSentence

 $fmt = $fmt->putSentence($sent)

Append a sentence to the selected output sink.

Should be non-destructive for $sent.

Default implementation just iterates $fmt->putToken() & appends 1 additional "\n" to $fmt->{outbuf}.

=item putSentenceRaw

 $fmt = $fmt->putSentenceRaw($sent)

Copy-by-reference version of L</putSentence>.
Default implementation just calls L</putSentence>.


=item putDocument

 $fmt = $fmt->putDocument($doc);

Append document contents to the selected output sink.

Should be non-destructive for $doc.

Default implementation just iterates $fmt-E<gt>putSentence()


=item putDocumentRaw

 $fmt = $fmt->putDocumentRaw($doc);

Copy-by-reference version of L</putDocument>.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## See Also
##======================================================================
=pod

=head1 SUBCLASSES

The following formats are provided by the default distribution.
In some cases, external dependencies are also required which
may not be available on all systems.

=over 4

=item L<DTA::CAB::Format::Builtin|DTA::CAB::Format::Builtin>

Just a convenience package: load all built-in DTA::CAB::Format subclasses.

=item L<DTA::CAB::Format::ExpandList|DTA::CAB::Format::ExpandList>

Formatter for runtime term expansion, for use e.g. with
DDC L<Cab Expander|http://odo.dwds.de/~moocow/software/ddc/ddc_opt.html#Cab>,
registerd as:

 name=>__PACKAGE__, short=>'xl', filenameRegex=>qr/\.(?i:xl|xlist|l|lst)$/


=item L<DTA::CAB::Format::JSON|DTA::CAB::Format::JSON>

Abstract datum parser|formatter for JSON I/O.
Transparently wraps one of the
L<DTA::CAB::Format::JSON::XS|DTA::CAB::Format::JSON::XS>
or
L<DTA::CAB::Format::JSON::Syck|DTA::CAB::Format::JSON::Syck>
classes, depending on the availability of the underlying Perl modules
(L<JSON::XS|JSON::XS> and L<JSON::Syck|JSON::Syck>, respectively).
If you have the L<JSON::XS|JSON::XS> module installed, this module provides
the fastest I/O of all available human-readable format classes.
Registered as:

 name=>__PACKAGE__, short=>'json', filenameRegex=>qr/\.(?i:json|jsn)$/


=item L<DTA::CAB::Format::LemmaList|DTA::CAB::Format::LemmaList>

Formatter for runtime term lemmatization, for use e.g. with
DDC L<Cab Expander|http://odo.dwds.de/~moocow/software/ddc/ddc_opt.html#Cab>.
By default, returns all lemmata for function word input tokens (whose tag matches
the regex C</^(?:[CKP\$]|A[PR]|V[AM])/>), otherwise only the "best" lemma.
Regisered as:

 (name=>__PACKAGE__, short=>$_, filenameRegex=>qr/\.(?i:ll|llist|lemmas|lemmata)/)
  foreach (qw(LemmaList llist ll lemma))

A variant which returns all known lemmata for each input token is registered as:

 (name=>__PACKAGE__, short=>$_, opts=>{cctagre=>''})
  foreach (qw(LemmaListAll LemmasAll llist-all ll-all lla lemmas lemmata))

=item L<DTA::CAB::Format::Null|DTA::CAB::Format::Null>

Null-op parser/formatter for debugging and testing purposes.
Registered as:

 name=>__PACKAGE__

=item L<DTA::CAB::Format::Perl|DTA::CAB::Format::Perl>

Datum parser|formatter: perl code via Data::Dumper, eval().
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:prl|pl|perl|dump)$/

=item L<DTA::CAB::Format::Raw|DTA::CAB::Format::Raw>

Abstract only format for reading raw untokenized text and
writing simple flat list of canonical forms;
wraps L<DTA::CAB::Format::Raw::Waste|DTA::CAB::Format::Raw::Waste> by default.
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:raw)$/

=item L<DTA::CAB::Format::Raw::HTTP|DTA::CAB::Format::Raw::HTTP>

Input-only format for reading raw untokenized text and analyzing it
over HTTP using a remote WASTE FastCGI interface, registered as:

 name=>__PACKAGE__, short=>'raw-http', filenameRegex=>qr/\.(?i:raw-http|txt-http)$/

=item L<DTA::CAB::Format::Raw::Perl|DTA::CAB::Format::Raw::Perl>

Input-only format for reading raw untokenized text and analyzing it
using simple pure-perl heuristics. Registered as:

 name=>__PACKAGE__, short=>'raw-perl', filenameRegex=>qr/\.(?i:raw-perl|txt-perl)$/

=item L<DTA::CAB::Format::Raw::Waste|DTA::CAB::Format::Raw::Waste>

Input-only format for reading raw untokenized text and analyzing it
using the L<Moot::Waste|Moot::Waste> module, registered as:

 name=>__PACKAGE__, short=>'raw-waste', filenameRegex=>qr/\.(?i:raw-waste|txt-waste)$/


=begin comment text

=item L<DTA::CAB::Format::SQLite|DTA::CAB::Format::SQLite>

=end comment


=item L<DTA::CAB::Format::Storable|DTA::CAB::Format::Storable>

Binary datum parser|formatter using the L<Storable|Storable> module.
Very fast, but neither human-readable nor easily portable beyond Perl.
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:sto|bin)$/

=item L<DTA::CAB::Format::SynCoPe::CSV|DTA::CAB::Format::SynCoPe::CSV>

Datum parser|formatter for SynCoPe named entity recognizer C<-tab_input> mode.
Registered as:

 name=>__PACKAGE__, short=>'syncope-csv', filenameRegex=>qr/\.(?i:syn(?:cope)?[-\.](?:csv|tsv|tab)|)$/

=item L<DTA::CAB::Format::TCF|DTA::CAB::Format::TCF>

Datum parser|formatter for CLARIN-D TCF XML.
Handles annoation layers tokens, sentences, orthography, postags, and lemmas.
Registered as:

 (name=>__PACKAGE__, filenameRegex=>qr/\.(?i:(?:tcf[\.\-_]?xml)|(?:tcf))$/)
 (name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tokens sentences orthography'}) foreach (qw(tcf-orth tcf-web))
 (name=>__PACKAGE__, short=>$_, opts=>{tcflayers=>'tokens sentences orthography postags lemmas'}) foreach (qw(tcf tcf-xml tcfxml full-tcf xtcf))

=item L<DTA::CAB::Format::TEI|DTA::CAB::Format::TEI>

Datum parser|formatter: for raw un-tokenized TEI XML (with or without //c elements) using L<DTA::TokWrap|DTA::TokWrap>.
Any //s or //w elements in the input will be B<IGNORED> and input will be (re-)tokenized.
Outputs files are themselves parseable by L<DTA::CAB::Format::TEIws|DTA::CAB::Format::TEIws>.
Registered as:

  (name=>__PACKAGE__, filenameRegex=>qr/\.(?i:(?:c|chr|txt|tei(?:[\.\-_]?p[45])?)[\.\-_]xml|xml)$/)
  (name=>__PACKAGE__, short=>$_) foreach (qw(chr-xml c-xml cxml tei-xml teixml tei xml))

By default, this module uses L<DTA::CAB::Format::XmlTokWrap|DTA::CAB::Format::XmlTokWrap> to format the low-level
document data, and splices the result back into the original TEI document.
The following additional aliases are provided for using the L<DTA::CAB::Format::XmlTokWrapFast|DTA::CAB::Format::XmlTokWrapFast>
module to format the low-level flat token data (faster but not as flexible as the default):

 (name=>__PACKAGE__, short=>$_, opts=>{txmlfmt=>'DTA::CAB::Format::XmlTokWrapFast'})
     foreach (qw(fast-tei-xml ftei-xml fteixml ftei))

Additionally, the following aliases are provided for using the L<DTA::CAB::Format::XmlLing|DTA::CAB::Format::XmlLing>
to format the low-level flat token data using TEI att.linguistic conventions:

  (name=>__PACKAGE__, short=>$_, opts=>{'att.linguistic'=>1})
    foreach (qw(ling-tei-xml ltei-xml lteixml ltei tei-ling tei+ling teiling))


=item L<DTA::CAB::Format::TEIws|DTA::CAB::Format::TEIws>

Datum parser|formatter: for TEI XML pre-tokenized into (possibly fragmented) //w and //s elements, as output by DTA::TokWrap.
Registered as:

 (name=>__PACKAGE__, filenameRegex=>qr/\.(?i:(?:spliced|tei[\.\-\+]?ws?|wst?)[\.\-]xml)$/)
 (name=>__PACKAGE__, short=>$_) foreach (qw(tei-ws tei+ws tei+w tei-w teiw wst-xml wstxml teiws-xml));

By default, this module uses L<DTA::CAB::Format::XmlTokWrap|DTA::CAB::Format::XmlTokWrap> to format the low-level
document data, and splices the result back into the original TEI document.
The following aliases are provided for using the L<DTA::CAB::Format::XmlLing|DTA::CAB::Format::XmlLing>
to format the low-level flat token data using TEI att.linguistic conventions:

  (name=>__PACKAGE__, short=>$_, opts=>{'att.linguistic'=>1})
    foreach (qw(lteiws teilws teiwsl ltei-ws ltei+ws tei+w ltei-w lteiw lwst-xml lwstxml lteiws-xml),
             qw(ling-tei-ws tei+ling+ws tei+ws+ling teiws-ling-xml teiws+ling-xml))


=item L<DTA::CAB::Format::Text|DTA::CAB::Format::Text>

Datum parser|formatter: verbose human-readable text
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:txt|text|cab\-txt|cab\-text)$/

=item L<DTA::CAB::Format::TJ|DTA::CAB::Format::TJ>

Datum parser|formatter: "vertical" text, one token per line, with a single TAB-separated
attribute field encoding token data as JSON.
Registered as:

 (name=>__PACKAGE__, filenameRegex=>qr/\.(?i:tj|tjson|cab\-tj|cab\-tjson)$/);

=item L<DTA::CAB::Format::TT|DTA::CAB::Format::TT>

Datum parser|formatter: "vertical" text, one token per line, TAB-separated attribute fields
with conventional attribute-name prefixes.
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:t|tt|ttt|cab\-t|cab\-tt|cab\-ttt)$/


=item L<DTA::CAB::Format::YAML|DTA::CAB::Format::YAML>

Abstract datum parser|formatter for YAML I/O.
Transparently wraps one of the
L<DTA::CAB::Format::YAML::XS|DTA::CAB::Format::YAML::XS>,
L<DTA::CAB::Format::YAML::Syck|DTA::CAB::Format::YAML::Syck>,
or
L<DTA::CAB::Format::YAML::Lite|DTA::CAB::Format::YAML::Lite>
classes, depending on the availability of the underlying Perl modules
(L<YAML::XS|YAML::XS>, L<YAML::Syck|YAML::Syck>, and L<YAML::Lite|YAML::Lite>, respectively).
Registered as:

 name=>__PACKAGE__, short=>'yaml', filenameRegex=>qr/\.(?i:yaml|yml)$/

=item L<DTA::CAB::Format::XmlCommon|DTA::CAB::Format::XmlCommon>

Datum parser|formatter: XML: abstract base class.

=item L<DTA::CAB::Format::XmlNative|DTA::CAB::Format::XmlLing>

Datum parser|formatter: minimalistic flat TokWrap-like XML using only TEI att.linguistic attributes.
Based on L<DTA::CAB::Format::XmlTokWrapFast|DTA::CAB::Format::XmlTokWrapFast>,
the L<XmlLing|DTA::CAB::Format::XmlLing> parser reads and writes only IDs and the TEI att.linguistic attributes,
(L<http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.linguistic.html>)).
Registered as:

 (name=>__PACKAGE__, filenameRegex=>qr/(?:\.(?i:(?:ling|l[tuws])(?:\.?)xml))$/)
 (name=>__PACKAGE__, short=>$_) foreach (qw(ltxml lxml ling-xml lt-xml ltwxml ltw-xml))


=item L<DTA::CAB::Format::XmlNative|DTA::CAB::Format::XmlNative>

Datum parser|formatter: XML (native).
Nearly compatible with C<.t.xml> files as created by L<dta-tokwrap.perl(1)|dta-tokwrap.perl>.
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:xml\-native|xml\-dta\-cab|(?:dta[\-\._]cab[\-\._]xml)|xml)$/

and aliased as:

 name=>__PACKAGE__, short=>'xml'


=item L<DTA::CAB::Format::XmlPerl|DTA::CAB::Format::XmlPerl>

Datum parser|formatter: XML (perl-like).  Not really reccommended.
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:xml(?:\-?)perl|perl(?:[\-\.]?)xml)$/


=item L<DTA::CAB::Format::XmlRpc|DTA::CAB::Format::XmlRpc>

Datum parser|formatter: XML-RPC data structures using RPC::XML.  Much too bloated
to be of any real practical use.
Registered as:

 name=>__PACKAGE__, filenameRegex=>qr/\.(?i:xml(?:\-?)rpc|rpc(?:[\-\.]?)xml)$/


=item L<DTA::CAB::Format::XmlTokWrap|DTA::CAB::Format::XmlTokWrap>

Datum parser|formatter(s): XML as read/written by L<DTA::TokWrap>.

 (name=>__PACKAGE__, filenameRegex=>qr/\.(?i:[tuws]\.?xml)$/)
 (name=>__PACKAGE__, short=>$_) foreach (qw(txml t-xml twxml tw-xml))

=item L<DTA::CAB::Format::XmlTokWrapFast|DTA::CAB::Format::XmlTokWrapFast>

Datum parser|formatter(s): XML as read/written by L<DTA::TokWrap>.
Unlike the C<XmlTokWrap> format,
the L<XmlTokWrapFast|DTA::CAB::Format::XmlTokWrapFast> class does not read and/or write the full document structure,
but rather restricts itself to a finite hard-coded subset of the most commonly
used document-, sentence-, and token-level attributes.  The input parser
uses the expat-based L<XML::Parser|XML::Parser> module, which usually results in much faster
and memory-friendlier document parsing than offered by the L<XmlTokWrap|DTA::CAB::Format::XmlTokWrap> class.
Registered as:

 (name=>__PACKAGE__, filenameRegex=>qr/(?:\.(?i:f[tuws](?:\.?)xml))$/);
 (name=>__PACKAGE__, short=>$_) foreach (qw(ftxml ft-xml ftwxml ftw-xml))

=back

=cut


##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
