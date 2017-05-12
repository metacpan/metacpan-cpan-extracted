# --*-Perl-*--
# $Id: MSWord.pm 19 2004-12-12 12:15:43Z tandler $
#

=head1 NAME

PBib::Document::MSWord - Handle Word Documents

=head1 SYNOPSIS

  use PBib::Document::MSWord;

=head1 DESCRIPTION

=head2 EXPORT

=cut

package PBib::Document::MSWord;
use 5.006;
use strict;
use warnings;
#  use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 19 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::Document::PBib);
#  our @ISA = qw(PBib::Document::PBib);

# used modules
use Win32::OLE;

# used own modules
use PBib::Document::RTF;

# module variables
#use vars qw(mmmm);

END {
	my $Count = Win32::OLE->EnumAllObjects(sub {
			my $Object = shift;
			my $Class = Win32::OLE->QueryObjectType($Object);
			printf STDERR "# Object=%s Class=%s\n", $Object, $Class;
		});
	print STDERR "Document::MSWord: $Count OLE objects left ...\n";
}

sub DESTROY ($) {
	my $self = shift;
	print STDERR "Document::MSWord: Destroy document ", $self->filename(), "\n" if $self->{verbose};
	#  $self->close();
}


#
#
# text access methods
#
#

sub paragraphs {
  my $self = shift;
  return $self->{'paragraphs'} if defined($self->{'paragraphs'});
  my $wordPars = $self->wordParagraphs();
  my @pars = map { convertWordText($_) } @$wordPars;
  $self->{'paragraphs'} = \@pars;
  return \@pars;
}


#
#
# converting
#
#

# do anything you want to before being converted
# the given object is used for conversion.
sub prepareConvert {
	my ($self, $conv) = @_;
	
	# we're doing the conversion based on RTF,
	# so first, convert the DOC to RTF
	my $file = $self->saveAsRTF();
	return undef unless $file;
	return $self if $file eq $self->filename();
	
	my $outDoc = $conv->outDoc();
	if( ref($outDoc) ne 'PBib::Document::RTF' ) {
		# the output for conversion has to be the same format
		# --> create new (temp) outfile
		my $name = $outDoc->filename();
		#  $name .= '.rtf' unless $name =~ s/\.\w+$/.rtf/;
		$conv->{'outDoc'} = new PBib::Document::RTF(
			'filename' => $name,
			'mode' => 'w',
			'finalizeConvert' => $outDoc, ## OBSOLETE??
			);
		#  print Dumper $conv->{'outDoc'};
	}
	my $inDoc = new PBib::Document::RTF(
		'filename' => $file,
		'mode' => 'r',
		);
	#  print Dumper $inDoc;
	$inDoc->close(); # close word document
	#  print Dumper $conv->{'foundInfo'};
	$conv->{'foundInfo'} = undef;
	return $inDoc;
}

# do anything you want to after being converted
# the given object is used for further processing.
sub finalizeConvert {
	my ($self, $conv) = @_;
	#  print Dumper $self;
	return $self;
}

#
#
# converting to internal format
#
#

sub convertWordText ($) {
   # Here some characters could be converted like:
   my $text = shift;

# remove 0-bytes
$text =~ s/\x00//g;

# replace CR-LF
# Paragraph end is "\x0d", line-break is "\x0b"
$text =~ s/\x0a//g;		# strip LF
$text =~ s/\x0d/\n\n/g;	# convert CR to \n
$text =~ s/\x0b/\n/g;

# replace special chars

# german quotes: double open "\x1e\x20", close "\x1c\x20",
#		single open "\x1a\x20", close "\x18\x20"
# english quotes: double open "\x1c\x20", close "\x1d\x20",
#		single open "\x18\x20", close "\x19\x20"
$text =~ s/\x18\x20/'/g;
$text =~ s/\x19\x20/'/g;
$text =~ s/\x1a\x20/'/g;
$text =~ s/\x1c\x20/"/g;
$text =~ s/\x1d\x20/"/g;
$text =~ s/\x1e\x20/"/g;

### missing "\x1b\x20" ??

# hyphens:
# normal hyphen "\x2d" '-'
# nonbreaking "\x1e(\x00)?" -- bei 2-byte-text folgt ein 0-byte
# optional hyphen "\x1f"
# en-dash "\x13\x20" oder "\x96"
# em-dash "\x14\x20" oder "\x97"
### missing "\x95" ??
$text =~ s/\x96/--/g; #$text =~ s/\x13\x20/--/g;
$text =~ s/\x97/---/g; #$text =~ s/\x14\x20/---/g;
$text =~ s/\x1f/{{-}}/g;
# ellipsis "\x85"
$text =~ s/\x85/.../g;
$text =~ tr/\x1e\x84\x91\x92\x93\x94/-"`'""/;

# non-breaking space: "\xa0"
# en-space: "\x02\x20"
# em-space: "\x03\x20"
$text =~ s/\xa0/{{ }}/g;
$text =~ s/\x02\x20/  /g;
$text =~ s/\x03\x20/   /g;


# replace word fields
$text =~ s/\x13\s*REF\s(\S+)\s[^\x14\x15]*\x14Error! Reference source not found\.\x15/[$1]/g;
$text =~ s/\x13\s*REF\s(\S+)\s[^\x14\x15]*\x14([^\x15]*)\x15/ $2 . quoteRef($1) /eg;
$text =~ s/\x13([^\x14\x15]*)\x14([^\x15]*)\x15/$2\{\{$1\}\}/g;
#$text =~ tr/\x13\x14\x15/{|}/;

# pictures?
$text =~ s/\x01/{{picture}}/g;

# escape all other control chars
$text =~ s/([\x01-\x09\x0b\x0c\x0e-\x1f\x80-\x9f])/'{{'.ord($1).'}}'/eg;

#   $text =~ s/[\x08\x09]/\t/g;
#   $text =~ s/(\x07\x07)/$1\x0d/g;
#   $text =~ s/\x07/ /g;
#   $text =~ s/[\xa0]/ /g;
#   $text =~ s/[\x0b\x0c\x0e]/\x0d/g;
#   $text =~ tr/\x1e\x84\x91\x92\x93\x94/-"`'""/;

   # Away with Words control characters
#   $text =~ s/[\x00-\x06\x0f-\x1f\x80-\x9f]//g;
  return $text;
}

sub quoteRef ($) {
  my $ref = shift;
  return ( $ref =~ /^(Sec)|(Req)|(Fig)/ ) ? "{{$ref}}" : "[$ref]"
}


sub quoteFieldId { my ($self, $id) = @_;
#
# return a valid field ID
#
# strip all non-bookmark chars, and add a prefix "r"
#
  $id =~ s/[^A-Z0-9]//gi;
  return $id;
}


#
#
#
#
#

sub replaceAll {
	my ($self, $find, $text, $repl) = @_;
	
	wordReplaceAll($find, $text, $repl);
	
	# now check field for [# ... #] patterns
	# ... it's important that the text between [+...+] and [-...-] is NOT matched greedy! --> .*?
	while( $repl =~ s/(\[\+.+?\+\].*?\[\-.+?\-\])// ) {
		$self->xtags()->{$1} = 1;
print "<<<$1>>>\n";
	}
}


our %xchars = (
	'p' => '^p',
	'br' => '^|',
	'pbr' => '^m',
	'cbr' => '^n',
	'tab' => '^t',
	'em-' => '^+',
	'en-' => '^=',
	'nbr ' => '^s',
	'nbr-' => '^~',
	'opt-' => '^-',
	);
#	'optbr'	- word has no opt. line break
#	'em '		- ???
#	'en '		- ???
sub xchar {
	my ($self, $xchar) = @_;
	return $xchars{$xchar} || '';
}

sub finishReplace ($$) {
	my ($self, $sel) = @_;
	my $find = $sel->Find();
	foreach my $xtag (keys %{$self->xtags()}) {
		#    print "$xtag\n";
		$self->xtagToClipboard($sel, $xtag);
		wordReplaceAll($find, $xtag, "^c");
	}
	print "xchars [#...#]\n";
	foreach my $xchar (keys %xchars) {
		wordReplaceAll($find, "[#$xchar#]", $xchars{$xchar});
	}
	#  wordReplaceAll($find, "[#p#]", "^p"); # new paragraph
	#  wordReplaceAll($find, "[#br#]", "^|"); # line break
	#  wordReplaceAll($find, "[#pbr#]", "^m"); # page break
	#  wordReplaceAll($find, "[#cbr#]", "^n"); # column break
	#  wordReplaceAll($find, "[#tab#]", "^t");
	#  wordReplaceAll($find, "[#endash#]", "^=");
	#  wordReplaceAll($find, "[#emdash#]", "^+");
	#  wordReplaceAll($find, "[#nbr #]", "^s");
	#  wordReplaceAll($find, "[#nbr-#]", "^~");
	#  wordReplaceAll($find, "[#opt-#]", "^-");
}

sub xtagToClipboard {
	my ($self, $sel, $xtag) = @_;
	
	$xtag =~ /^\[\+(.+?)\+\]/;
	my $tag = $1;
	$xtag =~ /^\[\+$tag\+\](.*)\[\-$tag\-\]$/;
	my $text = $1;
#	print "$tag ...\n";
	$tag =~ /^([a-zA-Z]+)(?::(.*))?$/;
	my $type = $1;
	my $arg = $2;
	my $f = $type . "ToClipboard";
print "$type($arg): <", substr($text,0,30), ">\n";
	$self->startClip($sel);
    $self->$f($sel, $text, $arg);
	$self->stopClip($sel);
}
sub startClip {
	my ($self, $sel) = @_;
	$sel->HomeKey({ 'Unit' => wdStory() });
	$sel->TypeParagraph();
	$sel->MoveLeft({ 'Unit' => wdCharacter(), 'Count' => 1 });
}
sub stopClip {
	my ($self, $sel) = @_;
	$sel->HomeKey({ 'Unit' => wdStory(), 'Extend' => wdExtend() });
	$sel->Cut();
	$sel->delete({ 'Unit' => wdCharacter(), 'Count' => 1 });
}



#
#
# text formating methods
#
#


# text styles

sub iToClipboard {
	my ($self, $sel, $text) = @_;
	$sel->Font()->{'Italic'} = wdToggle();
	$sel->TypeText({ 'Text' => $text });
	$sel->Font()->{'Italic'} = wdToggle();
}
sub bToClipboard {
	my ($self, $sel, $text) = @_;
	$sel->Font()->{'Bold'} = wdToggle();
	$sel->TypeText({ 'Text' => $text });
	$sel->Font()->{'Bold'} = wdToggle();
}
sub uToClipboard {
	my ($self, $sel, $text, $arg) = @_;
	$sel->Font()->{'Underline'} = wdUnderlineSingle();
	$sel->TypeText({ 'Text' => $text });
	$sel->Font()->{'Underline'} = wdUnderlineNone();
}


# fonts

sub ttToClipboard {
	my ($self, $sel, $text) = @_;
	$sel->Font()->{'Underline'} = wdUnderlineSingle();
	$sel->TypeText({ 'Text' => $text });
	$sel->Font()->{'Underline'} = wdUnderlineNone();
}

# fields

sub fieldToClipboard {
	my ($self, $sel, $text, $arg) = @_;
#	$sel->TypeText({ 'Text' => $xchar });
    $sel->Fields()->Add({ 'Range' => $sel->Range(), 'Type' => wdFieldEmpty(),
    	Text => $arg,
    	'PreserveFormatting' => 1 });
	$sel->EndKey({ 'Unit' => wdLine() });
}


sub bkmkToClipboard {
	my ($self, $sel, $text, $arg) = @_;
	$sel->TypeText({ 'Text' => $text });
	$sel->HomeKey({ 'Unit' => wdLine(), 'Extend' => wdExtend() });
    my $bk = $sel->Application()->ActiveDocument()->Bookmarks();
    $bk->Add({ 'Range' => $sel->Range(), 'Name' => $arg });
#    $bk->DefaultSorting = wdSortByName
#    $bk->ShowHidden = False
#exit(42);
#
#### the past of the bookmark doesn't work ... well ...
#
	$sel->EndKey({ 'Unit' => wdLine() });
}

sub bkmkrefToClipboard {
	my ($self, $sel, $text, $arg) = @_;
	$sel->TypeText({ 'Text' => $text });
	$sel->HomeKey({ 'Unit' => wdLine(), 'Extend' => wdExtend() });
    $sel->Application()->ActiveDocument()->Hyperlinks()->Add({ 'Anchor' => $sel->Range(), 
    	'Address' => "",
        'SubAddress' => $arg });
	$sel->EndKey({ 'Unit' => wdLine() });
}

sub hrefToClipboard {
	my ($self, $sel, $text, $arg) = @_;
	$sel->TypeText({ 'Text' => $text });
	$sel->HomeKey({ 'Unit' => wdLine(), 'Extend' => wdExtend() });
    $sel->Application()->ActiveDocument()->Hyperlinks()->Add({ 'Anchor' => $sel->Range(), 
    	'Address' => $arg,
        'SubAddress' => '' });
	$sel->EndKey({ 'Unit' => wdLine() });
}


#
#
# interactive editing methods
#
#

sub openInEditor { my ($self) = @_;
  my $filename = $self->filename();
  if( ! defined($filename) ) {
    print STDERR "can't open document with no filename specified.\n";
	return;
  }
  openWordDocument($filename);
}

sub jumpToBookmark {
  my ($self, $bookmark) = @_;
# this feature require some interaction with an appropriate editor
# application for this kind of document
# open the document in an editor, and jump to the given bookmark
  my $filename = $self->filename();
  if( not defined($filename) ) {
    print STDERR "can't open document with no filename specified.\n";
	return;
  }
  openWordDocument($filename, $bookmark);
}

sub searchInEditor { my ($self, $text) = @_;
  $self->openInEditor();
  searchWordDocument({'Text' => $text});
}

sub saveAsRTF {
	my ($self, $name) = @_;
	if( ! defined $name ) {
		$name = $self->filename();
		$name .= '-tmp-pbib$$.rtf' unless $name =~ s/\.\w+$/-tmp-pbib$$.rtf/;
	}
	my $doc = $self->doc();
	return undef unless defined $doc;
	
	# first save the original format to avoid lost changes
	print STDERR "save ", $self->filename(), " (doc)\n" unless $self->{quiet};
	$doc->Save();
	
	print STDERR "save as $name (rtf)\n" unless $self->{quiet};
	my $result = $doc->SaveAs({
		'FileName' => $name,
		'FileFormat' => wdFormatRTF(),
		'AddToRecentFiles' => 0,
		'EmbedTrueTypeFonts' => 0,
		});
	#  print STDERR " --> <", $result ? $result : "<undef>", ">\n";
	return $name;
}

#
#
# word access methods
#
#

sub doc {
  my $self = shift;
  my $wd = $self->{'wd'};
  if( ! defined($wd) ) {
    my $filename = $self->filename();
    print "try to open $filename using OLE ...\n" if $self->{verbose};
    $wd = Win32::OLE->GetObject($filename);
    if( ! defined($wd) ) {
      print "can't open $filename, error: ", Win32::OLE->LastError(), "\n";
      return undef;
    }
    #printProps($wd);
    print "got word handle: ", type($wd), "\n" if $self->{verbose};
    $self->{'wd'} = $wd;
  }
  return $wd;
}

sub close {
	my $self = shift;
	my $wd = $self->{'wd'};
	if( $wd ) {
		print STDERR "close ", $self->filename(), "\n" if $self->{verbose};
		$wd->Close();
		$self->{wd} = undef;
	}
}


sub wordParagraphs {
#
# return all paragraphs of this document in word's internal coding
#
  my ($self) = @_;
  my @pars;

  my $wd = $self->doc();
  if( not defined($wd) ) {
    return ();
  }

  my $c = $wd->Content();
  # printProps($c);
  my $t = $c->Text();
  print STDERR length($t), " bytes of text\n";

  @pars = split(/\r/, $t);
  print STDERR scalar(@pars), " paragraphs.\n";
  return \@pars;
#
#### old version: much slower!
#
#  my $par = $wd->Paragraphs()->First();
#  #printProps($par);
#  #print "first par: <<", $par->Range()->Text(), ">>\n";
#  while( defined($par) ) {
#    print '.';
#    push @pars, $par->Range()->Text();
#    $par = $par->Next();
#  }
#  print " done: ", scalar(@pars), " paragraphs.\n";
#  return @pars;
}



sub parStyle ($$) {
  my $self = shift; my ($wdPar) = @_;
  return $wdPar->Style()->NameLocal();
}

sub parBookmarks ($$) {
  my $self = shift; my ($wdPar) = @_;
  return $wdPar->Range()->Bookmarks();
}


sub figureName ($$) {
# If this par's style is 'Figure' or 'Caption',
# look for the first bookmark in its Caption
# and return its name
  my $self = shift; my ($wdPar) = @_;
  my $style = $self->parStyle($wdPar);
  if( $style eq 'Figure' or $style eq 'figure' ) {
    $wdPar = $wdPar->Next();
    $style = $self->parStyle($wdPar);
  }
  if( $style ne 'Caption' ) { return undef; }
  my $bks = $self->parBookmarks($wdPar);
  if( $bks->Count() < 1 ) { return undef; }
  return $bks->Item(1)->Name();
}



#
#
# class methods
#
#


sub wordReplaceAll {
	my ($find, $text, $replacement) = @_;
	my $idx = 0;
	while( length($replacement) >= 250 ) {
		my $mark = "[#$idx#]"; $idx ++;
		my $temp = substr($replacement, 0, 240);
		$replacement = substr($replacement, 240);
		wordBasicReplaceAll($find, $text, $temp . $mark);
		$text = $mark;
	}
	wordBasicReplaceAll($find, $text, $replacement);
}

sub wordBasicReplaceAll {
	my ($find, $text, $replacement) = @_;
#	print "replace <$text> with <$replacement>, length = ", length($replacement), "\n";
    $find->ClearFormatting();
    $find->Replacement()->ClearFormatting();
    $find->{'Text'} = $text;
    $find->Replacement->{'Text'} = $replacement;
    $find->{'Forward'} = 1;
    $find->{'Wrap'} = PBib::Document::MSWord::wdFindContinue();
    $find->{'format'} = 0;
    $find->{'MatchCase'} = 1;
    $find->{'MatchWholeWord'} = 0;
    $find->{'MatchWildcards'} = 0;
    $find->{'MatchSoundsLike'} = 0;
    $find->{'MatchAllWordForms'} = 0;
    $find->Execute({ 'Replace' => PBib::Document::MSWord::wdReplaceAll() });
}



#
# word constants
#

# WdUnits
sub wdCharacter { 1 }
sub wdLine { 5 }
sub wdParagraph { 4 }
sub wdStory { 6 } #a story is a text flow, e.g. the main flow, or the headings, footnotes, etc.

# WdReplace
sub wdReplaceAll { 2 }
sub wdReplaceNone { 0 }
sub wdReplaceOne { 1 }

# WdMovementType
sub wdMove { 0 }
sub wdExtend { 1 }

# WdFindWrap
sub wdFindContinue { 1 }

# WdFieldType
sub wdFieldEmpty { -1 }

# WdConstants
sub wdToggle { 9999998 }

# WdUnderline
sub wdUnderlineNone { 0 }
sub wdUnderlineSingle { 1 }

# WdSaveFormat
sub wdFormatDocument { 0 }
sub wdFormatText { 2 }
sub wdFormatRTF { 6 }
sub wdFormatUnicodeText { 7 }


#
#
#

sub app {
	my ($class) = @_;
	$class = 'Word.Application' unless $class;
	my $app;
	eval('$app = Win32::OLE->GetActiveObject($class)');
	goterror("No '$class' installed", 1) if $@;
	unless( $app ) {
		#  $app = Win32::OLE->new($class, sub {$_[0]->Quit();})
		$app = Win32::OLE->new($class)
			or goterror("can't get OLE handle for '$class'", 1);
	}
	return $app;
}

sub openWordDocument {
	my ($filename, $bookmark) = @_;
	print "open file in Word: $filename", ($bookmark ? "#$bookmark":""), "\n";
	my $app = app();
	my $adoc = $app->Documents()->Open({FileName => $filename});
	print "Open --> $adoc, ", type($adoc), "\n";
	unless( $adoc ) {
		print "open failed? no active document in word!\n";
		return undef;
	}
	
	# active word and the document
	$app->Activate();
	$adoc->Activate();
	
	# jump to a bookmark?
	if( $bookmark ) {
		my $result = $adoc->FollowHyperlink({
			'Address' => $filename,
			( $bookmark ? ('SubAddress' => $bookmark) : ()),
			'NewWindow'=> 1,
			'AddHistory'=>1});
	#    or goterror("open failed");
		print "FollowHyperlink --> ", ($result ? $result : 'undef');
	}
	return $adoc;
}

sub searchWordDocument {
  my ($findArgs) = @_;
  my $app = app();
  print STDERR "search for:\n";
  my $sel = $app->Selection();
  $sel->MoveRight({'Count' => 1});
  my $find = $sel->Find();
  $find->ClearFormatting();
  $find->Replacement->{'Text'} = '';
  $find->{'Forward'} = 1;
  $find->{'Wrap'} = 1;
  my ($k, $v);
  while (($k, $v) = (each %$findArgs)) {
    print STDERR "  $k = $v\n";
    $find->{$k} = $v;
  }
  $find->Execute();
}



sub goterror {
  my ($msg, $fatal) = @_;
  my $err = Win32::OLE::LastError();
  $msg = "$msg\n$err\n";
  die $msg if $fatal;
  print STDERR $msg;
}


#
#
# debugging class methods
#
#

sub type($) {
  my $Object = shift;
  return Win32::OLE->QueryObjectType($Object)
}

sub props($) {
  my $o = shift;
  return keys(%{$o})
}

sub printProps($) {
  my $o = shift;
  if( not defined($o) ) {
    print "printProps(undef) -- maybe there was an error?\n";
	my $err = Win32::OLE::LastError();
	print "(last error = $err)\n";
  }
  my $p;
  print $o, " [", type($o), "]: ";
  foreach $p (props($o)) {
    print "$p ";
  }
  print "\n";
}


1;

#
# $Log: MSWord.pm,v $
# Revision 1.12  2004/03/29 13:07:18  tandler
# added destrocture to close word handle
#
# Revision 1.11  2003/06/12 22:10:44  tandler
# new sub prepareConvert() that opens outDoc() in editor
# improved saveAsRTF()
# new close()
# improved app()
# much improved openWordDocument()
#
# Revision 1.10  2002/10/12 15:54:33  peter
# fixed
#
# Revision 1.9  2002/10/11 10:15:11  peter
# refactored: uses new superclass Document::PBib
#
# Revision 1.8  2002/09/23 11:07:04  peter
# save as RTF
#
# Revision 1.7  2002/08/22 10:41:53  peter
# - direct search/replace support for word ...
#
# Revision 1.5  2002/06/29 18:30:00  Diss
# result handling of jump-to-hyperlink changed
#
# Revision 1.4  2002/06/24 10:42:37  Diss
# minor changes
#
# Revision 1.3  2002/06/06 10:24:00  Diss
# searchInEditor support - jump to CiteKeys in editor
# (litUI uses PBib::Doc classes)
#
# Revision 1.2  2002/06/06 09:02:34  Diss
# merged with features of ReadDoc.pm (which should be obsolete by now)
#
# Revision 1.1  2002/05/27 10:25:29  Diss
# started editing support
#
# Revision 1.2  2002/03/27 10:00:51  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#