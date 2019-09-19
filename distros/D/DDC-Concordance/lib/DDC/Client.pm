## -*- Mode: CPerl -*-

## File: DDC::Client.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: client sockets
##======================================================================

package DDC::Client;
use DDC::Utils qw(:escape);
use DDC::HitList;
use DDC::Hit;
use IO::Handle;
use IO::File;
use IO::Socket::INET;
use Encode qw(encode decode);
use Carp;
use strict;

##======================================================================
## Globals

## $ifmt
## + pack format to use for integer sizes passed to and from DDC
## + default value should be right for ddc-2.x (always 32-bit unsigned little endian)
## + for ddc-1.x, use machine word size and endian-ness of server
our $ifmt = 'V';

## $ilen
## + length in bytes of message size integer used for DDC protocol in bytes
## + default value should be right for ddc-2.x (always 32-bit unsigned little endian)
## + for ddc-1.x, use machine word size and endian-ness of server
our $ilen = 4;


##======================================================================
## Constructors etc

## $dc = $CLASS_OR_OBJ->new(%args)
##  + %args:
##    (
##     ##-- connection options
##     connect=>\%connectArgs,  ##-- passed to IO::Socket::(INET|UNIX)->new()
##     mode   =>$queryMode,     ##-- one of 'table', 'html', 'text', 'json', or 'raw'; default='json' ('html' is not yet supported)
##     linger =>\@linger,       ##-- SO_LINGER socket option; default=[1,0]: immediate termination
##     ##
##     ##-- query options (formerly only in DDC::Client::Distributed)
##     start    =>$start,       ##-- index of first hit to fetch (default=0)
##     limit    =>$limit,       ##-- maximum number of hits to fetch (default=10)
##     timeout  =>$secs,        ##-- query timeout in seconds (lower bound, default=60)
##     hint     =>$hint,        ##-- navigation hint (optional; default=undef: none)
##     ##
##     ##-- hit parsing options (mostly obsolete)
##     parseMeta=>$bool,        ##-- if true, hit metadata will be parsed to %$hit (default=1)
##     parseContext=>$bool,     ##-- if true, hit context data will be parsed to $hit->{ctx_} (default=1)
##     metaNames =>\@names,     ##-- metadata field names (default=undef (none))
##     expandFields => $bool,   ##-- whether to implicitly expand hit fields to HASH-refs (default=true; only valid for 'table' mode)
##     keepRaw=>$bool,          ##-- if false, raw context buffer will be deleted after parsing context data (default=false)
##     #defaultField => $name,   ##-- default field names (default='w')
##
##     fieldSeparator => $char, ##-- intra-token field separator (default="\x{1f}": ASCII unit separator)
##     tokenSeparator => $char, ##-- inter-token separator       (default="\x{1e}": ASCII record separator)
##
##     textHighlight => [$l0,$r0,$l1,$r1],  ##-- highlighting strings, text mode (default=[qw(&& && _& &_)])
##     htmlHighlight => [$l0,$r0,$l1,$r1],  ##-- highlighting strings, html mode (default=[('<STRONG><FONT COLOR=red>','</FONT></STRONG>') x 2])
##     tableHighlight => [$l0,$r0,$l1,$r1], ##-- highlighting strings, table mode (default=[qw(&& && _& &_)])
##    )
##  + default \%connectArgs:
##     Domain=>'INET',          ##-- also accepts 'UNIX'
##     PeerAddr=>'localhost',
##     PeerPort=>50000,
##     Proto=>'tcp',
##     Type=>SOCK_STREAM,
##     Blocking=>1,
##
sub new {
  my ($that,%args) = @_;
  my %connect = (
		 ##-- connection options
		 Domain=>'INET',
		 PeerAddr=>'localhost',
		 PeerPort=>50000,
		 Proto=>'tcp',
		 Type=>SOCK_STREAM,
		 Blocking=>1,

		 ##-- connect: user args
		 (defined($args{'connect'}) ? %{$args{'connect'}} : qw()),
		);
  delete($args{'connect'});

  my $dc =bless {
		 ##-- connection options
		 connect=>\%connect,
		 linger => [1,0],
		 mode   =>'json',
		 encoding => 'UTF-8',

		 ##-- query options (formerly in DDC::Client::Distributed)
		 start=>0,
		 limit=>10,
		 timeout=>60,
		 hint=>undef,

		 ##-- hit-parsing options
		 parseMeta=>1,
		 parseContext=>1,
		 expandFields=>1,
		 keepRaw=>0,

		 #fieldSeparator => "\x{1f}",
		 #tokenSeparator => "\x{1e}",
		 #defaultField => 'w',
		 #metaNames => undef,
		 #textHighlight=>undef,
		 #tableHighlight=>undef,
		 #htmlHighlight=>undef,

		 %args,
		}, ref($that)||$that;

  if (defined($args{optFile})) {
    $dc->loadOptFile($args{optFile})
      or confess(__PACKAGE__ . "::new(): could not load options file '$args{optFile}': $!");
  }

  $dc->{fieldSeparator} = "\x{1f}" if (!$dc->{fieldSeparator});
  $dc->{tokenSeparator} = "\x{1e}" if (!$dc->{tokenSeparator});
  $dc->{textHighlight} = [qw(&& && _& &_)] if (!$dc->{textHighlight});
  $dc->{tableHighlight} = [qw(&& && _& &_)] if (!$dc->{tableHighlight});
  $dc->{htmlHighlight} = [
			  '<STRONG><FONT COLOR=red>','</FONT></STRONG>',
			  '<STRONG><FONT COLOR=red>','</FONT></STRONG>',
			 ] if (!$dc->{htmlHighlight});

  return $dc;
}

##======================================================================
## DDC *.opt file

## $dc = $dc->loadOptFile($filename, %opts);
## $dc = $dc->loadOptFile($fh,       %opts);
## $dc = $dc->loadOptFile(\$str,     %opts);
##  Sets client options from a DDC *.opt file: #fieldNames, metaNames, fieldSeparator.
##  %opts:
##  (
##   clobber => $bool,  ##-- whether to clobber existing %$dc fields (default=false)
##  )
##
##  WARNING: for whatever reason, DDC does not return metadata fields in the same
##   order in which they appeared in the *.opt file (nor in any lexicographic order
##   combination of the fields type, name, and xpath of the 'Bibl' directorive I
##   have tried), BUT this code assumes that the order in which the 'Bibl' directives
##   appear in the *.opt file are identical to the order in which DDC returns the
##   corresponding data in 'text' and 'html' modes.  The actual order used by the
##   server should appear in the server logs.  Change the *.opt file you pass to
##   this function accordingly.
sub loadOptFile {
  my ($dc,$src,%opts) = @_;
  my ($fh);

  ##-- get source fh
  if (!ref($src)) {
    $fh = IO::File->new("<$src")
      or confess(__PACKAGE__ . "::loadOptFile(): open failed for '$src': $!");
    binmode($fh,":encoding($dc->{encoding})") if ($dc->{encoding});
  }
  elsif (ref($src) eq 'SCALAR') {
    $fh = IO::Handle->new;
    open($fh,'<',$src)
      or confess(__PACKAGE__ . "::loadOptFile(): open failed for buffer: $!");
    binmode($fh,":encoding($dc->{encoding})") if ($dc->{encoding});
  }
  else {
    $fh = $src;
  }

  ##-- parse file
  my $clobber = $opts{clobber};
  my (@indices,@show,@meta,$showMeta);
  while (defined($_=<$fh>)) {
    chomp;
    if (/^Indices\s(.*)$/) {
      @indices = map {s/^\s*\[//; s/\]\s*$//; [split(' ',$_)]} split(/\;\s*/,$1);
    }
    elsif (/^Bibl\s+(\S+)\s+(\d)\s+(\S+)\s+(.*)$/) {
      my ($type,$visible,$name,$xpath) = ($1,$2,$3,$4);
      push(@meta,[$type,$visible,$name,$xpath]) if ($visible+0);
    }
    elsif (/^IndicesToShow\s+(.*)$/) {
      @show = map {$_-1} split(' ',$1);
    }
    elsif (/^OutputBibliographyOfHits\b/) {
      $showMeta = 1;
    }
    elsif (/^InterpDelim[ie]ter\s(.*)$/) {
      $dc->{fieldSeparator} = unescape($1) if ($clobber || !$dc->{fieldSeparator});
    }
    elsif (/^TokenDelim[ie]ter\s(.*)$/) {
      $dc->{tokenSeparator} = unescape($1) if ($clobber || !$dc->{tokenSeparator});
    }
    elsif (/^Utf8\s*$/) {
      $dc->{encoding} = 'utf8' if ($clobber || !$dc->{encoding});
    }
    elsif (/^HtmlHighlighting\s*(.*)$/) {
      $dc->{htmlHighlight} = [map {unescape($1)} split(/\s*\;\s*/,$1,4)] if ($clobber || !$dc->{htmlHighlight});
    }
    elsif (/^TextHighlighting\s*(.*)$/) {
      $dc->{textHighlight} = [map {unescape($1)} split(/\s*\;\s*/,$1,4)] if ($clobber || !$dc->{textHighlight});
    }
    elsif (/^TableHighlighting\s*(.*)$/) {
      $dc->{tableHighlight} = [map {unescape($_)} split(/\s*\;\s*/,$1,4)] if ($clobber || !$dc->{tableHighlight});
    }
  }

  ##-- setup local options
  @show = (0) if (!@show);
  $dc->{fieldNames} = [map {$_->[1]} @indices[@show]] if ($clobber || !$dc->{fieldNames});
  if (!$dc->{metaNames}) {
    if (!$showMeta) {
      $dc->{metaNames} = ['file_'];
    }
    elsif (@meta) {
      $dc->{metaNames} = [map {$_->[2]} @meta] if (@meta && ($clobber || !$dc->{metaNames}));
    }
  }

  ##-- cleanup
  $fh->close if (!ref($src) || ref($src) eq 'SCALAR');
  return $dc;
}

##======================================================================
## Query requests (formerly in DDC::Client::Distributed)

## $buf = $dc->queryRaw($query_string)
## $buf = $dc->queryRaw(\@raw_strings)
sub queryRaw {
  my $dc = shift;
  my $buf = $dc->queryRawNC(@_);
  $dc->close(); ##-- this apparently has to happen: bummer
  return $buf;
}

## $buf = $dc->queryRawNC($query_string)
## $buf = $dc->queryRawNC(\@raw_strings)
##  + guts for queryRaw() without implicit close()
sub queryRawNC {
  my ($dc,$query) = @_;
  if (UNIVERSAL::isa($query,'ARRAY')) {
    ##-- raw array: send raw data to DDC
    $dc->send(join("\001",@$query));
  }
  elsif ($dc->{mode} =~ /^(?:raw|req)/i) {
    ##-- "raw" or "request" mode: send raw request to DDC
    $dc->send($query);
  }
  else {
    ##-- query string: send 'run-query Distributed'
    $dc->send(join("\001",
		   "run_query Distributed",
		   $query,
		   $dc->{mode},
		   join(' ', @$dc{qw(start limit timeout)}, ($dc->{hint} ? $dc->{hint} : qw()))));
  }
  ##-- get output buffer
  return $dc->readData();
}

## @bufs = $dc->queryMulti($queryString1, $queryString2, ...)
## @bufs = $dc->queryMulti(\@queryStrings1, \@queryStrings2, ...)
sub queryMulti {
  my $dc   = shift;
  my @bufs = map {$dc->queryRawNC($_)} @_;
  $dc->close(); ##-- this apparently has to happen: bummer
  return @bufs;
}

## $obj = $dc->queryJson($query_string)
## $obj = $dc->queryJson(\@raw_strings)
sub queryJson {
  my ($dc,$query) = @_;
  return $dc->decodeJson($dc->queryRaw($query));
}

## $hits = $dc->query($query_string)
sub query {
  my ($dc,$query) = @_;
  return $dc->parseData($dc->queryRaw($query));
}


##======================================================================
## Common Requests

## $rsp = $dc->request($request_string)
sub request {
  my $dc = shift;
  my $buf = $dc->requestNC(@_);
  $dc->close();
  return $buf;
}

## $rsp = $dc->requestNC($request_string)
##  + guts for request() which doesn't implicitly call close()
sub requestNC {
  my $dc = shift;
  $dc->send($_[0]);
  return $dc->readData();
}

## $data = $dc->requestJson($request_string)
sub requestJson {
  my $dc  = shift;
  return $dc->decodeJson($dc->request($_[0]));
}

## $server_version = $dc->version()
sub version {
  my $dc = shift;
  return $dc->request("version");
}

## $status = $dc->status()
## $status = $dc->status($timeout)
sub status {
  my ($dc,$timeout) = @_;
  $timeout = $dc->{timeout} if (!defined($timeout));
  return $dc->requestJson("status".(defined($timeout) ? " $timeout" : ''));
}

## $vstatus = $dc->vstatus()
## $vstatus = $dc->vstatus($timeout)
sub vstatus {
  my ($dc,$timeout) = @_;
  $timeout = $dc->{timeout} if (!defined($timeout));
  return $dc->requestJson("vstatus".(defined($timeout) ? " $timeout" : ''));
}

## $info = $dc->info()
## $info = $dc->info($timeout)
sub info {
  my ($dc,$timeout) = @_;
  $timeout = $dc->{timeout} if (!defined($timeout));
  return $dc->requestJson("info".(defined($timeout) ? " $timeout" : ''));
}

## $expandRaw = $dc->expand_terms($pipeline, $term)
## $expandRaw = $dc->expand_terms($pipeline, $term, $timeout)
## $expandRaw = $dc->expand_terms($pipeline, $term, $timeout, $subcorpus)
## $expandRaw = $dc->expand_terms(\@pipeline, \@terms)
## $expandRaw = $dc->expand_terms(\@pipeline, \@terms, $timeout)
## $expandRaw = $dc->expand_terms(\@pipeline, \@terms, $timeout, $subcorpus)
sub expand_terms {
  my ($dc,$chain,$terms,$timeout,$subcorpus) = @_;
  $chain = join('|', @$chain)  if (UNIVERSAL::isa($chain,'ARRAY'));
  $terms = join("\t", @$terms) if (UNIVERSAL::isa($terms,'ARRAY'));

  ##-- hack: detect swapping of $timeout and $subcorpus (old DDC::Client::Distributed-style)
  $timeout   = '' if (!defined($timeout));
  $subcorpus = '' if (!defined($subcorpus));
  ($timeout,$subcorpus) = ($subcorpus,$timeout)
    if ($timeout ne '' && $subcorpus ne '' && $timeout =~ /[0-9]/ && $subcorpus !~ /[0-9]/);

  $timeout   = $dc->{timeout} if ($timeout eq '');
  $timeout   = 5 if (!defined($timeout) || $timeout eq '');
  $dc->send(join("\x01", 'expand_terms ', $chain, $terms, $timeout, $subcorpus));
  ##-- get output buffer
  my $buf = $dc->readData();
  $dc->close(); ##-- this apparently has to happen: bummer
  return $buf;
}

## \@terms = $dc->expand($pipeline, $term)
## \@terms = $dc->expand($pipeline, $term, $timeout)
## \@terms = $dc->expand($pipeline, $term, $timeout, $subcorpus)
## \@terms = $dc->expand(\@pipeline, \@terms)
## \@terms = $dc->expand(\@pipeline, \@terms, $timeout)
## \@terms = $dc->expand(\@pipeline, \@terms, $timeout, $subcorpus)
sub expand {
  my $dc = shift;
  return $dc->parseExpandTermsResponse($dc->expand_terms(@_));
}

## $buf = $dc->get_first_hits($query)
## $buf = $dc->get_first_hits($query,$timeout?,$limit?,$hint?)
sub get_first_hits {
  my $dc = shift;
  my $query = shift;
  my $timeout = @_ ? shift : $dc->{timeout};
  my $limit   = @_ ? shift : $dc->{limit};
  my $hint    = @_ ? shift : $dc->{hint};
  return $dc->request("get_first_hits $query\x{01}$timeout $limit".($hint ? " $hint" : ''));
}

## $buf = $dc->get_hit_strings($format?,$start?,$limit?)
sub get_hit_strings {
  my $dc = shift;
  my $format  = @_ ? shift : ($dc->{mode} eq 'raw' ? 'json' : '');
  my $start   = @_ ? shift : $dc->{start};
  my $limit   = @_ ? shift : $dc->{limit};
  return $dc->request("get_hit_strings $format\x{01}$start $limit");
}


## $buf = $dc->run_query($corpus,$query,$format?,$start?,$limit?,$timeout?,$hint?)
sub run_query {
  my $dc = shift;
  my $corpus = shift;
  my $query  = shift;
  my $format = @_ ? shift : $dc->{mode};
  my $start  = @_ ? shift : $dc->{start};
  my $limit  = @_ ? shift : $dc->{limit};
  my $timeout = @_ ? shift : $dc->{timeout};
  my $hint    = @_ ? shift : $dc->{hint};
  $corpus = 'Distributed' if (!defined($corpus));
  return $dc->request("run_query $corpus\x{01}$query\x{01}$format\x{01}$start $limit $timeout".($hint ? " $hint" : ''));
}

##======================================================================
## Low-level communications

## $io_socket = $dc->open()
sub open {
  my $dc = shift;
  my $domain = $dc->{connect}{Domain} // 'INET';
  if (lc($domain) eq 'unix') {
    ##-- v0.43: use unix-domain socket connection
    $dc->{sock} = IO::Socket::UNIX->new(%{$dc->{'connect'}});
  } else {
    ##-- compatibility hack: use INET-domain sockets (TCP)
    $dc->{sock} = IO::Socket::INET->new(%{$dc->{'connect'}});
  }
  return undef if (!$dc->{sock});
  $dc->{sock}->setsockopt(SOL_SOCKET, SO_LINGER, pack('II',@{$dc->{linger}})) if ($dc->{linger});
  $dc->{sock}->autoflush(1);
  return $dc->{sock};
}

## undef = $dc->close()
sub close {
  my $dc = shift;
  $dc->{sock}->close() if (defined($dc->{sock}));
  delete($dc->{sock});
}

## $encoded = $dc->ddc_encode(@message_strings)
sub ddc_encode {
  my $dc = shift;
  my $msg = join('',@_);
  $msg = encode($dc->{encoding},$msg) if ($dc->{encoding} && utf8::is_utf8($msg));
  return pack($ifmt,length($msg)) . $msg;
}

## $decoded = $dc->ddc_decode($response_buf)
sub ddc_decode {
  my $dc  = shift;
  my $buf = unpack("$ifmt/a*",$_[0]);
  $buf = decode($dc->{encoding},$buf) if ($dc->{encoding});
  return $buf;
}

## undef = $dc->send(@message_strings)
##  + sends @message_strings
sub send {
  my $dc = shift;
  $dc->open() if (!defined($dc->{sock}));
  return $dc->sendfh($dc->{sock}, @_);
}

## undef = $dc->sendfh($fh,@message_strings)
##  + sends @message_strings to $fh, prepending total length
sub sendfh {
  my ($dc,$fh) = (shift,shift);
  $fh->print( $dc->ddc_encode(@_) );
}

## $size = $dc->readSize()
## $size = $dc->readSize($fh)
sub readSize {
  my ($dc,$fh) = @_;
  my ($size_packed);
  $fh = $dc->{sock} if (!$fh);
  confess(ref($dc), "::readSize(): could not read size from socket: $!")
    if (($fh->read($size_packed,$ilen)||0) != $ilen);
  return 0 if (!defined($size_packed));
  return unpack($ifmt,$size_packed);
}

## $data = $dc->readBytes($nbytes)
## $data = $dc->readBytes($nbytes,$fh)
sub readBytes {
  my ($dc,$nbytes,$fh) = @_;
  my ($buf);
  $fh = $dc->{sock} if (!$fh);
  my $nread = $fh->read($buf,$nbytes);
  confess(ref($dc), "::readBytes(): failed to read $nbytes bytes of data (only found $nread): $!")
    if ($nread != $nbytes);
  return $buf;
}

## $data = $dc->readData()
## $data = $dc->readData($fh)
sub readData { return $_[0]->readBytes($_[0]->readSize($_[1]),$_[1]); }

##======================================================================
## Hit Parsing

## $hitList = $dc->parseData($buf)
sub parseData {
  return $_[0]->parseJsonData($_[1])  if ($_[0]{mode} eq 'json');
  return $_[0]->parseTableData($_[1]) if ($_[0]{mode} eq 'table');
  return $_[0]->parseTextData($_[1])  if ($_[0]{mode} eq 'text');
  return $_[0]->parseHtmlData($_[1])  if ($_[0]{mode} eq 'html');
  confess(__PACKAGE__ . "::parseData(): unknown query mode '$_[0]{mode}'");
}

##--------------------------------------------------------------
## Hit Parsing: Text

## $hitList = $dc->parseTextData($buf)
##  + returns a DDC::HitList
sub parseTextData {
  my ($dc,$buf) = @_;
  my $hits = DDC::HitList->new(start=>$dc->{start},limit=>$dc->{limit});

  ##-- parse response macro structure
  $buf = decode($dc->{encoding},$buf) if ($dc->{encoding} && !utf8::is_utf8($buf));
  my ($buflines,$bufinfo) = split("\001", $buf, 2);

  ##-- parse administrative data from response footer
  chomp($bufinfo);
  @$hits{qw(istatus_ nstatus_ end_ nhits_ ndocs_ error_)} = split(' ', $bufinfo,6);

  ##-- successful response: parse hit data
  my @buflines = split(/\n/,$buflines);
  my $metaNames = $dc->{metaNames} || [];
  my ($bufline,$hit,@fields,$ctxbuf);
  foreach $bufline (@buflines) {
    if ($bufline =~ /^Corpora Distribution\:(.*)$/) {
      $hits->{dhits_} = $1;
      next;
    } elsif ($bufline =~ /^Relevant Documents Distribution:(.*)$/) {
      $hits->{ddocs_} = $1;
      next;
    }
    push(@{$hits->{hits_}},$hit=DDC::Hit->new);
    $hit->{raw_} = $bufline if ($dc->{keepRaw});

    if ($dc->{parseMeta} || $dc->{parseContext}) {
      @fields = split(/ ### /, $bufline);
      $ctxbuf = pop(@fields);

      ##-- parse: metadata
      if ($dc->{parseMeta}) {
	$hit->{meta_}{file_} = shift(@fields);
	$hit->{meta_}{page_} = shift(@fields);
	$hit->{meta_}{indices_} = [split(' ', pop(@fields))];
	$hit->{meta_}{$metaNames->[$_]||"${_}_"} = $fields[$_] foreach (0..$#fields);
      }

      ##-- parse: context
      $hit->{ctx_} = $dc->parseTextContext($ctxbuf) if ($dc->{parseContext});
    }
  }

  $hits->expandFields($dc->{fieldNames}) if ($dc->{expandFields});
  return $hits;
}


## \@context_data = $dc->parseTextContext($context_buf)
sub parseTextContext {
  my ($dc,$ctx) = @_;

  ##-- defaults
  my $fieldNames = $dc->{fieldNames};
  my $fs         = qr(\Q$dc->{fieldSeparator}\E);
  my $ts         = qr(\Q$dc->{tokenSeparator}\E\ *);
  my $hl         = $dc->{textHighlight};
  my $hls        = qr(\Q$dc->{tokenSeparator}\E\ *\Q$hl->[0]\E);
  my $hlw0       = qr(^(?:(?:\Q$hl->[0]\E)|(?:\Q$hl->[2]\E)));
  my $hlw1       = qr((?:(?:\Q$hl->[1]\E)|(?:\Q$hl->[3]\E))$);

  ##-- split into sentences
  $ctx =~ s/^\s*//;
  my ($sbuf,@s,$w);
  my $sents = [[],[],[]];
  foreach $sbuf (split(/ {4}/,$ctx)) {

    if ($sbuf =~ $hls) {
      ##-- target sentence with index dump: parse it
      $sbuf =~ s/^$ts//;
      @s    = map {[0,split($fs,$_)]} split($ts,$sbuf);

      ##-- parse words
      foreach $w (@s) {
	if ($w->[1] =~ $hlw0 && $w->[$#$w] =~ $hlw1) {
	  ##-- matched token
	  $w->[1]    =~ s/$hlw0//;
	  $w->[$#$w] =~ s/$hlw1//;
	  $w->[0]    = 1;
	}
      }
      push(@{$sents->[1]},@s);
    }
    else {
      ##-- context sentence: surface strings only
      $sbuf =~ s/^$ts//;
      @s = split($ts,$sbuf);
      if (!@{$sents->[1]}) {
	##-- left context
	push(@{$sents->[0]}, @s);
      } else {
	##-- right context
	push(@{$sents->[2]}, @s);
      }
    }
  }

  return $sents;
}

##--------------------------------------------------------------
## Hit Parsing: Table

## $hitList = $dc->parseTableData($buf)
##  + returns a DDC::HitList
sub parseTableData {
  my ($dc,$buf) = @_;
  my $hits = DDC::HitList->new(start=>$dc->{start},limit=>$dc->{limit});

  ##-- parse response macro structure
  $buf = decode($dc->{encoding},$buf) if ($dc->{encoding} && !utf8::is_utf8($buf));
  my ($buflines,$bufinfo) = split("\001", $buf, 2);

  ##-- parse administrative data from response footer
  chomp($bufinfo);
  @$hits{qw(istatus_ nstatus_ end_ nhits_ ndocs_ error_)} = split(' ', $bufinfo,6);

  ##-- successful response: parse hit data
  my @buflines = split(/\n/,$buflines);
  my ($bufline,$hit,@fields,$field,$val);
  foreach $bufline (@buflines) {
    push(@{$hits->{hits_}},$hit=DDC::Hit->new);
    $hit->{raw_} = $bufline if ($dc->{keepRaw});

    if ($dc->{parseMeta} || $dc->{parseContext}) {
      @fields = split("\002", $bufline);
      while (defined($field=shift(@fields))) {

	if ($field eq 'keyword') {
	  ##-- special handling for 'keyword' field
	  $val = shift(@fields);
	  while ($val =~ /\<orth\>(.*?\S)\s*\<\/orth\>/g) {
	    push(@{$hit->{orth_}}, $1);
	  }
	}
	elsif ($field eq 'indices') {
	  ##-- special handling for 'indices' field
	  $val = shift(@fields);
	  $hit->{meta_}{indices_} = [split(' ',$val)];
	}
	elsif ($field =~ /^\s*\<s/) {
	  ##-- special handling for context pseudo-field
	  $hit->{ctx_} = $dc->parseTableContext($field) if ($dc->{parseContext});
	}
	elsif ($dc->{parseMeta}) {
	  ##-- normal bibliographic field
	  $field .= '_' if ($field =~ /^(?:scan|orig|page|rank(?:_debug)?)$/); ##-- special handling for ddc-internal fields
	  $val = shift(@fields);
	  $hit->{meta_}{$field} = $val;
	}
      }
    }
  }

  $hits->expandFields($dc->{fieldNames}) if ($dc->{expandFields});
  return $hits;
}


## \@context_data = $dc->parseTableContext($context_buf)
sub parseTableContext {
  my ($dc,$ctx) = @_;

  ##-- defaults
  my $fieldNames = $dc->{fieldNames};
  my $fs         = qr(\Q$dc->{fieldSeparator}\E);
  my $ts         = qr(\Q$dc->{tokenSeparator}\E\ *);
  my $hl         = $dc->{tableHighlight};
  my $hlw0       = qr(^(?:(?:\Q$hl->[0]\E)|(?:\Q$hl->[2]\E)));
  my $hlw1       = qr((?:(?:\Q$hl->[1]\E)|(?:\Q$hl->[3]\E))$);

  ##-- split into sentences
  my $sents = [[],[],[]];
  my ($sbuf,@s,$w);

  foreach $sbuf (split(/\<\/s\>\s*/,$ctx)) {

    if ($sbuf =~ /^\s*<s part=\"m\"\>/) {
      ##-- target sentence with index dump: parse it
      $sbuf =~ s|^\s*\<s(?: [^\>]*)?\>\s*$ts||;
      @s    = map {[0,split($fs,$_)]} split($ts,$sbuf);

      ##-- parse words
      foreach $w (@s) {
	if ($w->[1] =~ $hlw0 && $w->[$#$w] =~ $hlw1) {
	  ##-- matched token
	  $w->[1]    =~ s/$hlw0//;
	  $w->[$#$w] =~ s/$hlw1//;
	  $w->[0]    = 1;
	}
      }
      push(@{$sents->[1]}, @s);
    }
    else {
      ##-- context sentence; surface strings only
      $sbuf =~ s|^\s*\<s(?: [^\>]*)?\>$ts||;
      @s = split($ts,$sbuf);
      if (!@{$sents->[1]}) {
	##-- left context
	push(@{$sents->[0]}, @s);
      } else {
	##-- right context
	push(@{$sents->[2]}, @s);
      }
    }
  }

  return $sents;
}


##--------------------------------------------------------------
## Hit Parsing: JSON

## $obj = $dc->decodeJson($buf)
sub decodeJson {
  my $dc = shift;
  my ($bufr) = \$_[0];
  if ($dc->{encoding} && !utf8::is_utf8($$bufr)) {
    my $buf = decode($dc->{encoding},$$bufr);
    $bufr   = \$buf;
  }

  require JSON;
  my $jxs = $dc->{jxs};
  $jxs    = $dc->{jxs} = JSON->new->utf8(0)->relaxed(1)->canonical(0) if (!defined($jxs));
  return $jxs->decode($$bufr);
}

## $hitList = $dc->parseJsonData($buf)
##  + returns a DDC::HitList
sub parseJsonData {
  my $dc = shift;
  my $data = $dc->decodeJson($_[0]);
  my $hits = DDC::HitList->new(%$data,
			       start=>$dc->{start},
			       limit=>$dc->{limit},
			      );

  $_ = bless($_,'DDC::Hit') foreach (@{$hits->{hits_}||[]});
  $hits->expandFields($dc->{fieldNames}) if ($dc->{expandFields});
  return $hits;
}

##--------------------------------------------------------------
## Hit Parsing: expand_terms()

## \@terms = $dc->parseExpandTermsResponse($buf)
##  @terms = $dc->parseExpandTermsResponse($buf)
sub parseExpandTermsResponse {
  my $dc    = shift;
  my @items = grep {defined($_) && $_ ne ''} split(/[\t\r\n]+/,$_[0]);
  die("error in expand_terms response") if ($items[0] !~ /^0 /);
  shift(@items);
  return wantarray ? @items : \@items;
}

1; ##-- be happy

__END__

##======================================================================
## Docs
=pod

=head1 NAME

DDC::Client - Client socket object and utilities for DDC::Concordance

=head1 SYNOPSIS

 use DDC::Client;

 ##---------------------------------------------------------------------
 ## Constructors, etc.

 $dc = DDC::Client->new(PeerAddr=>'localhost',PeerPort=>50000);

 ##---------------------------------------------------------------------
 ## Common Requests

 $rsp     = $dc->request($request);           ##-- generic request
 $rsp     = $dc->requestNC($request);         ##-- generic request, no close()
 $data    = $dc->requestJson($request);       ##-- generic JSON request

 $version = $dc->version();                   ##-- get server version string
 $status  = $dc->status();                    ##-- get server status HASH-ref
 $vstatus = $dc->vstatus();                   ##-- get verbose status HASH-ref
 $info    = $dc->info();                      ##-- get server info HASH-ref

 $rsp     = $dc->expand_terms(\@pipeline, \@terms);  ##-- raw term expansion
 @terms   = $dc->expand(\@pipeline, \@terms);        ##-- parsed term expansion

 $hits    = $dc->query($query_string);        ##-- fetch and parse hits
 $hits    = $dc->queryJson($query_string);    ##-- fetch and parse JSON-formatted hits
 $buf     = $dc->queryRaw($query_string);     ##-- fetch raw query result buffer
 $buf     = $dc->queryRawNC($query_string);   ##-- fetch raw query result, no close()
 @bufs    = $dc->queryMulti(@query_strings);  ##-- fetch multiple request results without intervening close()

 $rsp     = $dc->get_first_hits($query);      ##-- low-level request
 $rsp     = $dc->get_hit_strings();           ##-- low-level request
 $rsp     = $dc->run_query($corpus,$query);   ##-- low-level request

 ##---------------------------------------------------------------------
 ## Low-level Communications

 $io_socket = $dc->open();          ##-- open the connection
 undef      = $dc->close();         ##-- close the connection

 $dc->send(@command);               ##-- send a command (prepends size)
 $dc->sendfh($fh,@command);         ##-- ... to specified filehandle

 $size = $dc->readSize();           ##-- get size of return message from client socket
 $size = $dc->readSize($fh);        ##-- ... or from a given filehandle

 $buf  = $dc->readBytes($size);     ##-- read a sized return buffer from client socket
 $buf  = $dc->readBytes($size,$fh); ##-- ... or from a given filehandle

 $buf  = $dc->readData();           ##-- same as $dc->readBytes($dc->readSize())
 $buf  = $dc->readData($fh);        ##-- ... same as $dc->readBytes($dc->readSize($fh),$fh)

 $hits = $dc->parseData($buf);      ##-- parse a return buffer
 $hits = $dc->parseJsonData($buf);  ##-- parse a return buffer in 'json' mode
 $hits = $dc->parseTextData($buf);  ##-- parse a return buffer in 'text' mode
 $hits = $dc->parseTableData($buf); ##-- parse a return buffer in 'table' mode
 $hits = $dc->parseHtmlData($buf);  ##-- parse a return buffer in 'html' mode

 @terms = $dc->parseExpandTermsResponse($buf);  ##-- parse an expand_terms response buffer

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

=cut


##----------------------------------------------------------------
## DESCRIPTION: DDC::Client: Globals
=pod

=head2 Globals

=over 4

=item Variable: $ifmt

pack()-format to use for integer sizes passed to and from a DDC server.
The default value ('V') should be right for ddc-2.x (always 32-bit unsigned little endian).
For ddc-1.x, the machine word size and endian-ness should match the those native to the
machine running the DDC server.

=item Variable: $ilen

Length of message size integer used for DDC protocol in bytes.
If you change $ifmt, you should make sure to change $ilen appropriately,
e.g. by setting:

 $ilen = length(pack($ifmt,0));

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Client: Constructors etc
=pod

=head2 Constructors etc

=over 4

=item new

 $dc = $CLASS_OR_OBJ->new(%args);

=over 4

=item accepted %args are keys of %$dc:

 (
  ##-- connection options
  connect  =>\%connectArgs,   ##-- passed to IO::Socket::(INET|UNIX)->new(), depending on $connectArgs{Domain}
  mode     =>$mode,           ##-- query mode; one of qw(json table text html raw); default='json'
  linger   =>\@linger,        ##-- SO_LINGER socket option (default=[1,0]: immediate termination)
 
  ##-- query options (formerly only in DDC::Client::Distributed)
  start    =>$start,          ##-- index of first hit to fetch (default=0)
  limit    =>$limit,          ##-- maximum number of hits to fetch (default=10)
  timeout  =>$secs,           ##-- query timeout in seconds (lower bound, default=60)
 
  ##-- hit parsing options (mostly obsolete)
  optFile  =>$filename,       ##-- parse meta names, separators from DDC *.opt file
  parseMeta=>$bool,           ##-- if true, hit metadata will be parsed to $hit->{_meta} (default=1)
  parseContext=>$bool,        ##-- if true, hit context data will be parsed to $hit->{_ctx} (default=1)
  keepRaw  =>$bool,           ##-- if false, raw context buffer $hit->{_raw} will be deleted after parsing context data (default=false)
  encoding =>$enc,            ##-- DDC server encoding (default='UTF-8')
  fieldSeparator => $str,     ##-- intra-token field separator (default="\x{1f}": ASCII unit separator); 'text' and 'table' modes only
  tokenSeparator => $str,     ##-- inter-token separator       (default="\x{1e}": ASCII record separator); 'text' and 'table' modes only
  metaNames      => \@names,  ##-- metadata names for 'text' and 'html' modes; default=none
 
  textHighlight => [$l0,$r0,$l1,$r1],  ##-- highlighting strings, text mode (default=[qw(&& && _& &_)])
  htmlHighlight => [$l0,$r0,$l1,$r1],  ##-- highlighting strings, html mode (default=[('<STRONG><FONT COLOR=red>','</FONT></STRONG>') x 2])
  tableHighlight => [$l0,$r0,$l1,$r1], ##-- highlighting strings, table mode (default=[qw(&& && _& &_)])
 )

=item default \%connectArgs:

 Domain=>'INET',
 PeerAddr=>'localhost',
 PeerPort=>50000,
 Proto=>'tcp',
 Type=>SOCK_STREAM,
 Blocking=>1,

=item connect to a UNIX socket at C<$SOCKPATH> on the local host:

  $dc = DDC::Client->new(connect=>{Domain=>'UNIX',Peer=>$SOCKPATH});

=back

=back

=cut

  
##----------------------------------------------------------------
## DESCRIPTION: DDC::Client::Distributed: Query Requests
=pod

=head2 Querying

=over 4

=item queryRaw

 $buf = $dc->queryRaw($query_string);

Send a query string to the selected server and returns the raw result buffer.
Implicitly close()s the connection.

=item queryRawNC

 $buf = $dc->queryRawNC($query_string);

Send a query string to the selected server and returns the raw result buffer.
No implicit close().

=item queryMulti

 @bufs = $dc->queryMulti(@query_strings);

Sends a series of query strings or requests to the server, and returns a list of raw result buffers.
Implicitly close()s the client after all requests have been sent,
but not between individual requests.

=item query

 $hits = $dc->query($query_string);

Send a query string to the selected server and parses the result into a list of hits.

=item get_first_hits

 $buf = $dc->get_first_hits($query,$timeout?,$limit?,$hint?);

Requests IDs of the first $limit hit(s) for query $query, using optional navigation hint $hint,
and returns the raw DDC response buffer.
The optional parameters default to the %$dc keys of the same name.

=item get_hit_strings

 $buf = $dc->get_hit_strings($format?,$start?,$limit?)

Requests the full strings for up to $limit hits beginning at logical offset $start
formatted as $format.
$format defaults to $dc-E<gt>{mode},
and the remaining optional parameters default to the %$dc keys of the same name.

=item run_query

 $buf = $dc->run_query($corpus,$query,$format?,$start?,$limit?,$timeout?,$hint?)

Requests a complete query evaluation of up to $limit hit(s) beginning at offset $start for query $query,
formatted as $format with server-side timeout lower bound $timeout and optional navigation hint
$hint.
If $corpus is specified as C<undef>, it defaults to the string "Distributed".
Optional parameters default to the %$dc keys of the same name.
Note that this method returns the raw DDC response;
see the L<query()|/query> method for a more comfortable alternative.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Client: Common Requests
=pod

=head2 Common Requests

=over 4

=item request

 $rsp = $dc->request($request_string);

Send a raw DDC request and return the server's response as a raw byte-string.

=item requestJson

 $data = $dc->requestJson($request_string);

Send a raw DDC request and decode the server's response as JSON data.

=item version

 $server_version = $dc->version();

Request the current running version of the selected server,
wraps $dc-E<gt>L<request|/request>("version").

=item status

 $status = $dc->status();
 $status = $dc->status($timeout);

Get basic server status;
wraps $dc-E<gt>L<requestJson|/requestJson>("status $timeout").

=item vstatus

 $vstatus = $dc->vstatus();
 $vstatus = $dc->vstatus($timeout);

Get verbose server status;
wraps $dc-E<gt>L<requestJson|/requestJson>("vstatus $timeout").

=item info

 $info = $dc->info();
 $info = $dc->info($timeout);

Get verbose server information;
wraps $dc-E<gt>L<requestJson|/requestJson>("info $timeout").


=item expand_terms

 $expandRaw = $dc->expand_terms($pipeline, $term);
 $expandRaw = $dc->expand_terms($pipeline, $term, $timeout);
 $expandRaw = $dc->expand_terms($pipeline, $term, $timeout, $subcorpus);

Perform server-side term-expansion for the term C<$term> via pipeline C<$pipeline>.
Both C<$term> and C<$pipeline> may be specified as ARRAY-refs or bare strings.
Returns the raw response data string.

=item expand

 @terms = $dc->expand($pipeline, $term);
 @terms = $dc->expand($pipeline, $term, $timeout);
 @terms = $dc->expand($pipeline, $term, $timeout, $subcorpus);

Perform server-side term-expansion for the term C<$term> via pipeline C<$pipeline>
and parses the response with L<parseExpandTermsResponse|/parseExpandTermsResponse>.
Returns an array C<@terms> of server expansions in list-context;
in scalar context returns the reference \@terms to such an array.

=item query

 $hits = $dc->query($query_string);

Send a query string to the selected server and parses the result into a
L<DDC::HitList|DDC::HitList> object.

=item queryRaw

 $buf = $dc->queryRaw($query_string);
 $buf = $dc->queryRaw(\@raw_strings);

Send a query string to the selected server and returns the raw result buffer.
The second form is equivalent to

 $dc->queryRaw(join("\x01",@raw_strings));

Implicitly close()s the connection.

=item queryRawNC

 $buf = $dc->queryRawNC($query_string);

Send a query string to the selected server and returns the raw result buffer.
No implicit close().

=item queryMulti

 @bufs = $dc->queryMulti(@query_strings);

Sends a series of query strings or requests to the server, and returns a list of raw result buffers.
Implicitly close()s the client after all requests have been sent,
but not between individual requests.

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DDC::Client: Low-level Communications
=pod

=head2 Low-level Communications

=over 4

=item open

 $io_socket = $dc->open();

Open the underlying INET- or UNIX-domain socket; returns undef on failure.
Most users will never need to call this method, since it will be called
implicitly by higher-level methods such as L<requiest()|/request>, L<query()|/query>, L<status()|/status>
if required.

=item close

 undef = $dc->close();

Closes the underlying socket if currently open.
Most users will never need to call this method, since it will be called
implicitly by higher-level methods such as L<requiest()|/request>, L<query()|/query>, L<status()|/status>
if required.

=item send

 undef = $dc->send(@message_strings);

=over 4

=item *

Sends @message_strings to the underlying socket as a single message.

=back

=item sendfh

 undef = $dc->sendfh($fh,@message_strings);

=over 4

=item *

Sends @message_strings to filehandle $fh, prepending total length.

=back

=item readSize

 $size = $dc->readSize();
 $size = $dc->readSize($fh)

Reads message size from $fh (default=underlying socket).

=item readBytes

 $data = $dc->readBytes($nbytes);
 $data = $dc->readBytes($nbytes,$fh)

Reads fixed number of bytes from $fh (default=underlying socket).

=item readData

 $data = $dc->readData();
 $data = $dc->readData($fh)

Reads pending data from $fh (default=underlying socket); calls L<readSize()|/readSize> and L<readBytes()|/readBytes>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Client: Hit Parsing
=pod

=head2 Hit Parsing

=over 4

=item parseTableData

=item parseTextData

=item parseJsonData

 \@hits = $dc->parseTableData($buf);
 \@hits = $dc->parseTextData($buf);
 \@hits = $dc->parseJsonData($buf);

Parses raw DDC data buffer in $buf.
Returns an array-ref of L<DDC::Hit|DDC::Hit> objects representing
the individual hits.

JSON parsing requires the L<JSON|JSON> module.

=item parseExpandTermsResponse

 \@terms = $dc->parseExpandTermsResponse($buf);
  @terms = $dc->parseExpandTermsResponse($buf);

Parses a DDC server C<expand_terms> response buffer.
Returns an array C<@terms> of server expansions in list-context;
in scalar context returns the reference \@terms to such an array.


=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
