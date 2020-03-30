## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analyzer API

package DTA::CAB::Analyzer;
use DTA::CAB::Persistent;
use DTA::CAB::Logger;
use DTA::CAB::Datum ':all';
use DTA::CAB::Utils ':minmax', ':files', ':time';
use File::Basename qw(basename dirname);
use Scalar::Util qw(weaken);
use Exporter;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(Exporter DTA::CAB::Persistent);

our @EXPORT = qw();
our %EXPORT_TAGS =
  (
   'access' => [qw(_am_xtext _am_xlit _am_lts _am_rw),
		qw(_am_tt_list _am_tt_fst),
		qw(_am_id_fst _am_xlit_fst),
		qw(_am_fst_wcp _am_fst_wcp_list _am_fst_wcp_listref),
		qw(_am_tt_fst_list _am_tt_fst_eqlist),
		qw(_am_fst_sort _am_fst_rsort _am_fst_uniq _am_fst_usort),
		qw(_am_clean),
		qw(_am_tag _am_word _am_lemma),
		qw(_am_tagh_fst2moota _am_tagh_list2moota _am_tagh_moota_uniq _am_tagh_list2moota_uniq),
		qw(_am_dmoot_fst2moota _am_dmoot_list2moota),
		qw(_am_wordlike_regex),
		qw(parseFstString),
	       ],
  );
our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;
$EXPORT_TAGS{all}   = [@EXPORT_OK];
$EXPORT_TAGS{child} = [@EXPORT_OK];

## %CLOSURE_CACHE = ("$object" => { "$closureCode" => \&closure, ... }, ... }
##  + cache for accessClosure() to avoid unnecessary re-compilation
our (%CLOSURE_CACHE);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     label => $label,    ##-- analyzer label (default: from class name)
##     aclass => $class,   ##-- analysis class (optional; see $anl->analysisClass() method; default=undef)
##     typeKeys => \@keys, ##-- analyzer type keys for $anl->typeKeys()
##     enabled => $bool,   ##-- set to false, non-undef value to disable this analyzer
##     initQuiet => $bool, ##-- if true, initInfo() will not print any output
##     traceLevel => $level, ##-- log-level for trace messages (default=undef: none)
##    )
sub new {
  my $that = shift;
  my $anl = bless({
		   ##-- user args
		   @_
		  }, ref($that)||$that);
  $anl->initialize();
  $anl->{label} = $anl->defaultLabel() if (!defined($anl->{label})); ##-- get label
  return $anl;
}

## undef = $anl->DESTROY()
##  + default destructor deletes any cached closures for $anl
sub DESTROY {
  #print STDERR __PACKAGE__, "::DESTROY( $_[0] ): ", scalar(keys(%{$CLOSURE_CACHE{$_[0]}//{}})), " closure(s)\n";
  delete $CLOSURE_CACHE{$_[0]};
}

## undef = $anl->initialize();
##  + default implementation does nothing
sub initialize { return; }

## undef = $anl->dropClosures();
##  + deletes any cached closures for $anl
##  + v1.112 : uses %CLOSURE_CACHE instead of "_analyze*" keys
sub dropClosures {
  delete $CLOSURE_CACHE{$_[0]};
}

## $label = $anl->defaultLabel()
##  + default label for this class
##  + default is final component of perl class-name
sub defaultLabel {
  my $anl = shift;
  my $lab = ref($anl);
  $lab =~ s/^.*\:\://;
  return $lab;
}

## $class = $anl->analysisClass()
##  + gets cached $anl->{aclass} if exists, otherwise returns undef
##  + really just an ugly wrapper for $anl->{aclass}
sub analysisClass {
  return $_[0]{aclass};
}

## @keys = $anl->typeKeys(\%opts)
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + default returns @{$anl->{typeKeys}} if defined, otherwise ($anl->{label})
sub typeKeys {
  return $_[0]{typeKeys} ? @{$_[0]{typeKeys}} : (defined($_[0]{label}) ? ($_[0]{label}) : qw());
}

##==============================================================================
## Methods: version
##==============================================================================

## $timestamp_str_or_undef = $anl->timestamp(%opts)
##  + gets local ($opts{deep}=0) or recursive timestamp ($opts{deep}=1)
sub timestamp {
  my ($anl,%opts) = @_;
  return $opts{deep} ? $anl->versionInfo(%opts)->{timestamp} : $anl->timestampLocal;
}

## $timestamp_str_or_undef = $anl->timestampLocal()
##  + gets local analyzer timestamp
##  + default implementation returns $anl->{timestampLocal} or newest mtime among all $anl->timestampFiles()
sub timestampLocal {
  my $anl = shift;
  return $anl->{timestampLocal} if (defined($anl->{timestampLocal}));
  my @tsfiles = grep {defined($_) && -e $_} $anl->timestampFiles;
  my $mtime = @tsfiles ? (sort {$b<=>$a} map {(stat($_))[9]} @tsfiles)[0] : undef;
  return $anl->{timestampLocal} = defined($mtime) ? timestamp_str($mtime) : undef;
}

## @files = $anl->timestampFiles()
##  + resource files for determining this analyzer's local timestamp
##  + default checks for analyzer keys matching m/file$/i
sub timestampFiles {
  my $anl = shift;
  return @$anl{grep {m/file$/i} keys %$anl};
}

## $version_or_undef = $anl->version()
##  + gets local analyzer version string
##  + default implementation returns $anl->{version} if defined, otherwise caches from first available file from $anl->versionFiles()
sub version {
  my $anl   = shift;
  return $anl->{version} if (defined($anl->{version}));
  my $vfile = (grep {defined($_) && -e $_} $anl->versionFiles())[0];
  return undef if (!defined($vfile));
  open(my $vfh,"<$vfile")
    or $anl->logconfess("version(): open failed for version file '$vfile': $!");
  my ($version);
  {
    local $/=undef;
    $version = <$vfh>;
  }
  chomp($version);
  close($vfh);
  return $anl->{version} = $version;
}

## @files = $anl->versionFiles()
##  + resource files for determining this analyzer's local version
##  + default searches $_.ver, noext($_).ver for all $anl->timestampFiles(), finally dirname($_)/version.txt
sub versionFiles {
  my $anl = shift;
  my @tsfiles = grep {defined($_)} $anl->timestampFiles();
  my ($base);
  return (
	  (map {$base=$_; $base =~ s/\.[^\.]*$//; ("$_.ver","$base.ver")} @tsfiles),
	  (map {dirname($_)."/version.txt"} @tsfiles),
	 );
}

## \%vinfo_or_undef = $anl->versionInfo(%opts)
##  + gets analyzer version info, including sub-analyzers
##  + options %opts as for analyzeDocument()
##  + returned HASH %vinfo =
##    (
##     rcfile => $rcfile, ##-- from $anl->{rcfile} if available
##     class => $class,
##     label => $label,
##     version => $version,
##     timestampLocal => $timestampLocal,
##     timestamp => $timestampDeep, ##-- youngest local or sub-analyzer timestamp
##     subs => \@subAnalyzerVersionInfo,
##    )
sub versionInfo {
  my ($anl,%opts) = @_;
  return undef if (!$anl->enabled(\%opts)); ##-- no version information for disabled analyzer
  my $subs = $anl->can('chain') ? $anl->chain(\%opts) : $anl->subAnalyzers(\%opts);
  my $vinfo = {
	       class => ref($anl),
	       label => $anl->{label},
	       rcfile => $anl->{rcfile},
	       version => $anl->version(%opts),
	       timestampLocal => $anl->timestampLocal(%opts),
	       ($subs && @$subs ? (subs=>[grep {defined($_)} map {$_->versionInfo(%opts)} @$subs]) : qw()),
	      };
  $vinfo->{timestamp} = (sort {($b||'') cmp ($a||'')} ($vinfo->{timestampLocal}, map {$_->{timestamp}} @{$vinfo->{subs}||[]}))[0];
  delete @$vinfo{grep {!defined($vinfo->{$_}) || $vinfo->{$_} eq ''} keys %$vinfo};
  return $vinfo;
}

##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $anl->ensureLoaded()
## $bool = $anl->ensureLoaded(\%opts)
##  + ensures analysis data is loaded from default files, or that
##    no data is available to be loaded
##  + should return false only if user has requested data to be loaded
##    and that data cannot be loaded.  "empty" analyzers should return
##    true here.
##  + default version always returns true
##  + see canAnalyze(), autoDisable() for alternatives
sub ensureLoaded { return 1; }

## $bool = $anl->prepare()
## $bool = $anl->prepare(\%opts)
##  + wrapper for ensureLoaded(), autoEnable(), initInfo()
sub prepare {
  my $anl = shift;
  $anl->ensureLoaded(@_)
    or $anl->logdie("ensureLoaded() failed: $!");
  $anl->autoEnable(@_);
  $anl->initInfo(@_);
  $anl->canAnalyze(@_)
    or $anl->logdie("canAnalyze() failed");
  return 1;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

##======================================================================
## Methods: Persistence: Perl

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + default just greps for CODE-refs
sub noSaveKeys {
  return grep {UNIVERSAL::isa($_[0]{$_},'CODE')} keys(%{$_[0]});
}

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + default implementation just clobbers $CLASS_OR_OBJ with $ref and blesses
sub loadPerlRef {
  my $that = shift;
  my $obj = $that->SUPER::loadPerlRef(@_);
  $obj->dropClosures();
  return $obj;
}

##======================================================================
## Methods: Persistence: Bin

## @keys = $class_or_obj->noSaveBinKeys()
##  + returns list of keys not to be saved for binary mode
##  + default just greps for CODE-refs
sub noSaveBinKeys {
  grep {UNIVERSAL::isa($_[0]{$_},'CODE')} keys(%{$_[0]});
}

## $loadedObj = $CLASS_OR_OBJ->loadBinRef($ref)
##  + drops closures
sub loadBinRef {
  my $that = shift;
  $that->dropClosures() if (ref($that));
  return $that->SUPER::loadBinRef(@_);
}


##==============================================================================
## Methods: Analysis: v1.x

##------------------------------------------------------------------------
## Methods: Analysis: Utils

## $bool = $anl->canAnalyze();
## $bool = $anl->canAnalyze(\%opts);
##  + returns true iff analyzer can perform its function (e.g. data is loaded & non-empty)
##  + default implementation always returns true
sub canAnalyze { return 1; }

## $bool = $anl->doAnalyze(\%opts, $name)
##  + alias for $anl->can("analyze${name}") && (!exists($opts{"doAnalyze${name}"}) || $opts{"doAnalyze${name}"})
sub doAnalyze {
  my ($anl,$opts,$name) = @_;
  return $anl->can("analyze${name}") && (!$opts || !exists($opts->{"doAnalyze${name}"}) || $opts->{"doAnalyze${name}"});
}

## $bool = $anl->enabled(\%opts)
##  + returns true if analyzer SHOULD operate, acording to %opts
##  + default returns:
##     (!defined($anl->{enabled}) || $anl->{enabled})                           ##-- globally enabled
##     &&
##     (!$opts || !defined($opts{"${lab}_enabled"} || $opts{"${lab}_enabled"})  ##-- ... and locally enabled
sub enabled {
  return (
	  (!defined($_[0]{enabled}) || $_[0]{enabled})
	  &&
	  (!$_[1] || !defined($_[1]{"$_[0]{label}_enabled"}) || $_[1]{"$_[0]{label}_enabled"})
	 );
}

## $bool = $anl->autoEnable()
## $bool = $anl->autoEnable(\%opts)
##  + sets $anl->{enabled} flag if not already defined
##  + calls $anl->canAnalyze(\%opts)
##  + returns new value of $anl->{enabled}
##  + implicitly calls autoEnable() on all sub-analyzers
sub autoEnable {
  my $anl = shift;
  foreach (@{$anl->subAnalyzers(@_)}) {
    $_->autoEnable(@_);
  }
  return $anl->{enabled} if (defined($anl->{enabled}));
  return $anl->{enabled} = $anl->canAnalyze(@_) ? 1 : 0;
}
sub autoDisable { return $_[0]->autoEnable(@_[1..$#_]); }

## undef = $anl->initInfo()
##  + logs initialization info
##  + default method reports values of {label}, enabled()
##  + sets $anl->{initQuiet}=1 (don't report multiple times)
sub initInfo {
  my $anl = shift;
  $anl->info("initInfo($anl->{label}): enabled=", ($anl->enabled(@_) ? 1 : 0)) if (!$anl->{initQuiet});
  $anl->{initQuiet}=1;
}

## \@analyzers = $anl->subAnalyzers()
## \@analyzers = $anl->subAnalyzers(\%opts)
##  + returns a list of all sub-analyzers
##  + default returns all DTA::CAB::Analyzer subclass instances in values(%$anl)
sub subAnalyzers {
  my $anl = shift;
  return [] if (!ref($anl));
  return [grep {ref($_) && UNIVERSAL::isa($_,'DTA::CAB::Analyzer')} values(%$anl)];
}


##------------------------------------------------------------------------
## Methods: Analysis: API

## $doc = $anl->analyzeDocument($doc,\%opts)
##  + analyze a DTA::CAB::Document $doc
##  + top-level API routine
##  + default implementation just calls:
##      #$anl->ensureLoaded();
##      $doc = toDocument($doc);
##      if ($anl->doAnalyze('Types')) {
##        $types = $anl->getTypes($doc);
##        $anl->analyzeTypes($doc,$types,\%opts);
##        $anl->expandTypes($doc,$types,\%opts);
##        $anl->clearTypes($doc);
##      }
##      $anl->analyzeTokens($doc,\%opts)    if ($anl->doAnalyze(\%opts,'Tokens'));
##      $anl->analyzeSentences($doc,\%opts) if ($anl->doAnalyze(\%opts,'Sentences'));
##      $anl->analyzeLocal($doc,\%opts)     if ($anl->doAnalyze(\%opts,'Local'));
##      $anl->analyzeClean($doc,\%opts)     if ($anl->doAnalyze(\%opts,'Clean'));
sub analyzeDocument {
  my ($anl,$doc,$opts) = @_;
  return $doc if (!$anl->enabled($opts));  ##-- disabled analyzer
  #return undef if (!$anl->ensureLoaded()); ##-- uh-oh...
  return $doc if (!$anl->canAnalyze);      ##-- ok... (?)
  $doc = toDocument($doc);
  my ($types);
  if ($anl->doAnalyze($opts,'Types')) {
    $types = $anl->getTypes($doc);
    $anl->analyzeTypes($doc,$types,$opts);
    $anl->expandTypes($doc,$types,$opts);
    $anl->clearTypes($doc);
  }
  $anl->analyzeTokens($doc,$opts)    if ($anl->doAnalyze($opts,'Tokens'));
  $anl->analyzeSentences($doc,$opts) if ($anl->doAnalyze($opts,'Sentences'));
  $anl->analyzeLocal($doc,$opts)     if ($anl->doAnalyze($opts,'Local'));
  $anl->analyzeClean($doc,$opts)     if ($anl->doAnalyze($opts,'Clean'));
  return $doc;
}

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
##  + default implementation does nothing
sub analyzeTypes { return $_[1]; }

## $doc = $anl->analyzeTokens($doc,\%opts)
##  + perform token-wise analysis of all tokens $doc->{body}[$si]{tokens}[$wi]
##  + no default implementation
sub analyzeTokens { return $_[1]; }

## $doc = $anl->analyzeSentences($doc,\%opts)
##  + perform sentence-wise analysis of all sentences $doc->{body}[$si]
##  + no default implementation
sub analyzeSentences { return $_[1]; }

## $doc = $anl->analyzeLocal($doc,\%opts)
##  + perform analyzer-local document-level analysis of $doc
##  + no default implementation
sub analyzeLocal { return $_[1]; }

## $doc = $anl->analyzeClean($doc,\%opts)
##  + cleanup any temporary data associated with $doc
##  + no default implementation
sub analyzeClean { return $_[1]; }

## $doc = $anl->analyzeClean_rm_undef($doc,\%opts)
##  + cleanup any temporary data associated with $doc
##  + removes keys with undef values from all tokens
sub analyzeClean_rm_undef {
  my ($anl,$doc,$opts) = @_;
  my ($tok);
  foreach (@{$doc->{body}}) {
    foreach $tok (@{$_->{tokens}}) {
      delete @$tok{grep {!defined($tok->{$_})} keys %$tok};
    }
  }
  return $doc;
}

##------------------------------------------------------------------------
## Methods: Analysis: API: Type-wise

## \%types = $anl->getTypes($doc)
##  + returns a hash \%types = ($typeText => $typeToken, ...) mapping token text to
##    basic token objects (with only 'text' key defined)
##  + default just calls $doc->types()
sub getTypes {
  return $_[1]->types;
}

## $doc = $anl->expandTypes($doc,\%types,\%opts)
##  + expands \%types into $doc->{body} tokens
##  + default just calls $doc->expandTypeKeys(\@typeKeys,\%types,\%opts)
sub expandTypes {
  my ($anl,$doc,$types,$opts) = @_;
  my %typeKeys = map {($_=>undef)} $anl->typeKeys($opts);
  return $doc->expandTypeKeys([keys %typeKeys],$types,$opts);
}

## $doc = $anl->clearTypes($doc)
##  + clears cached type->object map in $doc->{types}
##  + default just calls $doc->clearTypes()
sub clearTypes {
  return $_[1]->clearTypes();
}


##------------------------------------------------------------------------
## Methods: Analysis: Wrappers

## $tok = $anl->analyzeToken($tok_or_string,\%opts)
##  + perform type- and token- analyses on $tok_or_string
##  + wrapper for $anl->analyzeDocument()
sub analyzeToken {
  my ($anl,$tok,$opts) = @_;
  my $doc = toDocument([toSentence([toToken($tok)])]);
  $anl->analyzeDocument($doc, { ($opts ? %$opts : qw()) , doAnalyzeSentences=>0,doAnalyzeLocal=>0});
  return $doc->{body}[0]{tokens}[0];
}

## $tok = $anl->analyzeSentence($sent_or_array,\%opts)
##  + perform type- and token-, and sentence- analyses on $sent_or_array
##  + wrapper for $anl->analyzeDocument()
sub analyzeSentence {
  my ($anl,$sent,$opts) = @_;
  $sent = [$sent] if (!UNIVERSAL::isa($sent,'ARRAY'));
  @$sent = map {toToken($_)} @$sent;
  my $doc = toDocument([toSentence($sent)]);
  $anl->analyzeDocument($doc, { ($opts ? %$opts : qw()), doAnalyzeLocal=>0});
  return $doc->{body}[0];
}

## $rpc_xml_base64 = $anl->analyzeData($data_str,\%opts)
##  + analyze a raw (formatted) data string $data_str with internal parsing & formatting
##  + wrapper for $anl->analyzeDocument()
sub analyzeData {
  require RPC::XML;
  my ($anl,$doc0,$opts) = @_;

  ##-- parsing & formatting options
  my $reader = $opts && $opts->{reader} ? $opts->{reader} : {}; ##-- reader options
  my $writer = $opts && $opts->{writer} ? $opts->{writer} : {}; ##-- writer options

  ##-- get format reader,writer
  my $ifmt = DTA::CAB::Format->newReader(%$reader);
  my $ofmt = DTA::CAB::Format->newWriter(class=>ref($ifmt), %$writer);

  ##-- parse, analyze, format
  my $doc = $ifmt->parseString($doc0);
  #$doc = DTA::CAB::Utils::deep_decode('UTF-8', $doc); ##-- this should NOT be necessary!
  $doc = $anl->analyzeDocument($doc,$opts);
  my $str = $ofmt->flush->putDocument($doc)->toString;
  $ofmt->flush;

  return RPC::XML::base64->new($str);
}

##------------------------------------------------------------------------
## Methods: Analysis: Closure Utilities (optional)

## \&closure = $anl->analyzeClosure($which)
##  + returns cached $anl->{"_analyze${which}"} if present
##  + otherwise calls $anl->getAnalyzeClosure($which) & caches result
##  + optional utility for closure-based analysis
sub analyzeClosure {
  my ($anl,$which) = @_;
  return $anl->{"_analyze${which}"} if (defined($anl->{"_analyze${which}"}));
  return $anl->{"_analyze${which}"} = $anl->getAnalyzeClosure($which);
}

## \&closure = $anl->getAnalyzeClosure($which)
##  + returns closure \&closure for analyzing data of type "$which"
##    (e.g. Word, Type, Token, Sentence, Document, ...)
##  + default implementation calls $anl->getAnalyze"${which}"Closure() if
##    available, otherwise croak()s
sub getAnalyzeClosure {
  my ($anl,$which) = @_;
  my $getsub = $anl->can("getAnalyze${which}Closure");
  weaken($anl);
  return $getsub->($anl) if ($getsub);
  $anl->logconfess("getAnalyzeClosure('$which'): no getAnalyze${which}Closure() method defined!");
}

##------------------------------------------------------------------------
## Methods: Analysis: (Token-)Accessor Closures

## $closure = $anl->accessClosure( $methodName, %opts);
## $closure = $anl->accessClosure(\&codeRef,    %opts);
## $closure = $anl->accessClosure( $codeString, %opts);
## $closure = $anl->accessClosure(\%opts );
##  + returns accessor-closure $closure for $anl
##  + passed argument can be one of the following:
##    - a CODE ref resolves to itself
##    - a method name resolves to $anl->can($methodName)
##    - anything else resolves to a string passed to eval()
##      + if the string contains no /\bsub\b/, it will be wrapped
##        as "sub {$codeString}"
##      + $codeString may reference the closure variable $anl
##        (and maybe others; see 'pre' and 'vars' options)
##  + %opts
##     code => $codeRefOrMethodNameOrCodeString, ##-- clobbers first argument
##     pre => $code_str,   ##-- for $codeString accessors, prefix for eval (e.g. 'my ($lexVar);')
##     vars => \@vars,     ##-- adds lexical vars 'my ('.join(',',@varNames).');'
##     cache => $bool,     ##-- enable/disable use of %CLOSURE_CACHE (default=enabled)
sub accessClosure {
  my ($anl,$code,%opts) = @_;
  if (UNIVERSAL::isa($code,'HASH')) {
    %opts = (%$code,%opts);
    $code = undef;
  }
  $code = $opts{code} if (defined($opts{code}));
  $code = ';' if (!defined($code));
  return $code if (UNIVERSAL::isa($code,'CODE'));
  return $anl->can($code) if ($anl->can($code));
  $code = (''
	   .($opts{pre}  ? "$opts{pre}; " : '')
	   .($opts{vars} ? ('my ('.join(',',@{$opts{vars}}).'); ') : '')
	   .($code =~ /\bsub\b/ ? $code : "sub { $code }")
	  );

  print STDERR
    ((ref($anl)||$anl), "->accessClosure():\n$code\n") if (0 || (ref($anl) && $anl->{debugAccessClosure}));

  my $do_cache = !exists($opts{cache}) || $opts{cache};
  my $sub      = ($do_cache ? $CLOSURE_CACHE{$anl}{$code} : undef);
  my $cached   = $sub ? 1 : 0;

  weaken($anl);
  $sub       ||= eval $code;
  $anl->logcluck("accessClosure(): could not compile closure {$code}: $@") if (!$sub);
  $CLOSURE_CACHE{$anl}{$code} = $sub if ($do_cache && !$cached);

  return $sub;
}

## PACKAGE::_am_xlit($tokvar='$_')
##  + access-closure macro (EXPR): get text (xlit.latin1Text << text) for token $$tokvar
##  + evaluates to a string:
##    ($$tokvar->{xlit} ? $$tokvar->{xlit}{latin1Text} : $$tokvar->{text})
sub _am_xlit {
  my $tokvar = shift || '$_';
  return "($tokvar\->{xlit} ? $tokvar\->{xlit}{latin1Text} : $tokvar\->{text}) ##== _am_xlit\n";
}

## PACKAGE::_am_xtext($tokvar='$_')
##  + access-closure macro (EXPR): get (exlex << xlit.latin1Text << text) for token $$tokvar
##  + evaluates to a string:
##    (defined($$tokvar->{exlex}) ? $$tokvar->{exlex} : $${am_xlit($tokvar)})
sub _am_xtext {
  my $tokvar = shift || '$_';
  return ("(defined($tokvar\->{exlex})"
	  ." ? $tokvar\->{exlex}"
	  ." : ($tokvar\->{xlit} ? $tokvar\->{xlit}{latin1Text} : $tokvar\->{text})"
	  .") ##== _am_xtext\n"
	 );
}

## PACKAGE::_am_lts($tokvar='$_')
##  + access-closure macro (EXPR) for first LTS analysis of token $$tokvar
##  + evaluates to string:
##    ($$tokvar->{lts} && @{$$tokvar->{lts}} ? $$tokvar->{lts}[0]{hi} : $$tokvar->{text})
sub _am_lts {
  my $tokvar = shift || '$_';
  return "($tokvar\->{lts} && \@{$tokvar\->{lts}} ? $tokvar\->{lts}[0]{hi} : $tokvar\->{text}) ##== _am_lts\n";
}

## PACKAGE::_am_rw($tokvar='$_')
##  + access-closure macro (EXPR) for rw output(s) for token $$tokvar
##  + evaluates to string:
##    ($$tokvar->{rw} ? (map {$_->{hi}} @{$$tokvar->{rw}}) : qw())
sub _am_rw {
  my $tokvar = shift || '$_';
  return "($tokvar\->{rw} ? (map {\$_->{hi}} \@{$tokvar\->{rw}}) : qw()) ##== _am_rw\n";
}

## PACKAGE::_am_tt_list($ttvar='$_')
##  + access-closure macro (EXPR) for a TT-style list of strings $$ttvar
##  + evaluatees to a list: "split(/\\t/,$$ttvar)"
sub _am_tt_list {
  my $ttvar = shift || '$_';
  return "split(/\\t/,$ttvar) ##== _am_tt_list\n";
}

## PACKAGE::_am_tt_fst($ttvar='$_')
##  + access-closure macro (EXPR) for a single TT-style FST analysis $$ttvar
##  + formerly mutliply defined in sub-packages as SUBPACKAGE::parseFstString()
##  + evaluates to a FST-analysis hash {hi=>$hi,w=>$w,lo=>$lo,lemma=>$lemma}:
##    (
##     $$ttvar =~ /^(?:(.*?) \: )?(?:(.*?) \@ )?(.*?)(?: \<([\d\.\+\-eE]+)\>)?$/
##     ? {(defined($1) ? (lo=>$1) : qw()), (defined($2) ? (lemma=>$2) : qw()), hi=>$3, w=>($4||0)}
##     : {hi=>$$ttvar}
##    )
sub _am_tt_fst {
  my $ttvar = shift || '$_';
  return ("($ttvar".' =~ /^(?:(.*?) \: )?(?:(.*?) \@ )?(.*?)(?: \<([\d\.\+\-eE]+)\>)?$/'
	  .' ? {(defined($1) ? (lo=>$1) : qw()), (defined($2) ? (lemma=>$2) : qw()), hi=>$3, w=>($4||0)}'
	  ." : {hi=>$ttvar})"
	  ." ##== _am_tt_fst\n");
}

## PACKAGE::_parseFstString($ttstr)
##  + actual subroutine for parsing an fst string
sub parseFstString {
  return ($_[0] =~ /^(?:(.*?) \: )?(?:(.*?) \@ )?(.*?)(?: \<([\d\.\+\-eE]+)\>)?$/
	  ? {(defined($1) ? (lo=>$1) : qw()), (defined($2) ? (lemma=>$2) : qw()), hi=>$3, w=>($4||0)}
	  : {hi=>$_[0]});
}

## PACKAGE::_am_id_fst($tokvar='$_', $wvar='0')
##  + access-closure macro (EXPR) for a identity FST analysis
##  + really just a wrapper for _am_xlit_fst()
sub _am_id_fst {
  return _am_xlit_fst(@_);
}

## PACKAGE::_am_xlit_fst($tokvar='$_', $wvar='0')
##  + access-closure macro (EXPR) for a xlit-FST analysis
##  + evaluates to a single fst analysis hash:
##    {hi=>_am_xlit($tokvar), w=>$$wvar}
sub _am_xlit_fst {
  my $tokvar = shift || '$_';
  my $wvar   = shift || '0';
  return '{hi=>'._am_xlit($tokvar).', w=>'.$wvar.'}'." ##== _am_id_fst\n";
}

## PACKAGE::_am_fst_wcp($fstvar='$_', $wexpr=$fstvar.'->{w}')
##  + access-closure macro (EXPR) for a re-weighted copy of FST analysis $$fstvar
##  + evaluates to a copy of $$fstvar with $$wexpr replacing $$fstvar->{w}:
##    {%$$fstvar,w=>$$wexpr}
sub _am_fst_wcp {
  my $fstvar  = shift || '$_';
  my $wexpr   = shift || $fstvar.'->{w}';
  return "{ %{$fstvar}, w=>$wexpr } ##-- _am_fst_wcp\n";
}

## PACKAGE::_am_fst_wcp_list($listvar='@_', $wexpr='$_->{w}')
##  + access-closure macro (EXPR) for a list of weighted copies of FST analysis-list $$listvar
##  + evaluates to a list of copies of $$listvar analyses with $$wexpr replacing $_->{w}:
##    (map { $${_am_fst_wcp('$_',$wexpr)} } $$listvar)
sub _am_fst_wcp_list {
  my $listvar  = shift || '@_';
  my $wexpr   = shift || '$_->{w}';
  return "(map {"._am_fst_wcp('$_',$wexpr)."} $listvar) ##-- _am_fst_wcp_list\n";
}

## PACKAGE::_am_fst_wcp_listref($listrefvar='$_->{rw}', $wexpr='$_->{w}')
##  + access-closure macro (EXPR) for a list of weighted copies of FST analysis-listref $$listrefvar
##  + accepts undef $$listrefvar
##  + evaluates to a list of copies of $$listvar analyses with $$wexpr replacing $_->{w}:
##    ($$listvar ? (map { $${_am_fst_wcp('$_',$wexpr)} } @{$$listvar}) : qw())
sub _am_fst_wcp_listref {
  my $listrefvar  = shift || '$_->{rw}';
  my $wexpr   = shift;
  return "($listrefvar ? "._am_fst_wcp_list("\@{$listrefvar}",$wexpr)." : qw()) ##-- _am_fst_wcp_listref\n";
}

## PACKAGE::_am_tt_fst_list($ttvar='$_')
##  + access-closure macro (EXPR) for a list of TT-style FST analyses $$ttvar
##  + evaluates to a list of fst analysis hashes:
##    (map {_am_tt_fst('$_')} split(/\t/,$$ttvar))
sub _am_tt_fst_list {
  my $ttvar = shift || '$_';
  return '(map {'._am_tt_fst('$_').'} split(/\t/,'.$ttvar.'))'." ##== _am_tt_fst_list\n";
}

## PACKAGE::_am_tt_fst_eqlist($ttvar='$tt', $tokvar='$_', $wvar='0')
##  + access-closure macro (EXPR) for a list of TT-style FST analyses $$ttvar
##  + evaluates to a list of fst analysis hashes:
##    (_am_id_fst($tokvar,$wvar), _am_tt_fst_list($ttvar))
sub _am_tt_fst_eqlist {
  my $ttvar  = shift || '$tt';
  my $tokvar = shift || '$_';
  my $wvar   = shift || '0';
  return "("._am_id_fst($tokvar,$wvar).', '._am_tt_fst_list($ttvar).')'." ##== _am_tt_fst_eqlist\n";
}

## PACKAGE::_am_fst_sort($listvar='@_')
##  + access-closure macro (EXPR) to sort a list of FST analyses $$listvar by weight
##  + evaluates to a sorted list of fst analysis hashes:
##    (sort {($a->{w}||0) <=> ($b->{w}||0) || ($a->{hi}||"") cmp ($b->{hi}||"")} $$listvar)
sub _am_fst_sort {
  my $listvar = shift || '@_';
  return '(sort {($a->{w}||0) <=> ($b->{w}||0) || ($a->{hi}||"") cmp ($b->{hi}||"")} '.$listvar.')'." ##== _am_fst_sort\n";
}

## PACKAGE::_am_fst_rsort($listvar='@_')
##  + access-closure macro (EXPR) to reverse-sort a list of FST analyses $$listvar by weight
##  + evaluates to a sorted list of fst analysis hashes:
##    (sort {($b->{w}||0) <=> ($a->{w}||0) || ($a->{hi}||"") cmp ($b->{hi}||"")} $$listvar)
sub _am_fst_rsort {
  my $listvar = shift || '@_';
  return '(sort {($b->{w}||0) <=> ($a->{w}||0) || ($a->{hi}||"") cmp ($b->{hi}||"")} '.$listvar.')'." ##== _am_fst_rsort\n";
}

## PACKAGE::_am_fst_uniq($listvar='@_', $tmpvar='$val')
##  + access-closure macro (EXPR) for a unique list of TT-style FST analyses $$listvar
##  + only the weight-minimal analysis is kept
##  + evaluates to a list of upper-unique fst analysis hashes:
##    (map {$$val && $$val->{hi} eq $_->{hi} ? qw() : ($$val=$_)} sort {$a->{hi} cmp $b->{hi} || ($a->{w}||0) <=> ($b->{w}||0)} $$listvar)
##  + assumes $$tmpvar is initialized to undef at start of evaluation
sub _am_fst_uniq {
  my $listvar = shift || '@_';
  my $tmpvar  = shift || '$val';
  return ("(map {$tmpvar && $tmpvar\->{hi} eq \$_->{hi} ? qw() : ($tmpvar=\$_)}"
	  .' sort {($a->{hi}//"") cmp ($b->{hi}//"") || ($a->{w}//0) <=> ($b->{w}//0)}'
	  ." $listvar)"
	  ." ##== _am_fst_uniq\n"
	 );
}

## PACKAGE::_am_fst_usort($listvar='@_', $tmpvar='$val')
##  + wrapper for _am_fst_sort(_am_fst_uniq($listvar,$tmpvar))
sub _am_fst_usort {
  return _am_fst_sort(_am_fst_uniq(@_));
}

## PACKAGE::_am_clean($hashvar='$_->{$lab}')
##  + access-closure macro (STMT) to delete a hash entry if undefined; evaluates to
##    delete($$hashvar) if (!defined($$hashvar));
sub _am_clean {
  my $hashvar = shift || '$_->{$lab}';
  return "delete($hashvar) if (!defined($hashvar)); ##== _am_clean\n"
}

## PACKAGE::_am_tag($mootvar='$_->{moot}', $defaultvar='undef')
##  + access-closure macro (EXPR) for a moot or dmoot tag; evaluates to
##    ($$mootvar ? $$mootvar->{tag} : $defaultvar)
sub _am_tag {
  my $mootvar = shift||'$_->{moot}';
  my $default = shift||'undef';
  return "($mootvar ? $mootvar\->{tag} : $default) ##== _am_tag\n";
}

## PACKAGE::_am_word($mootvar='$_->{moot}', $defaultvar='undef')
##  + access-closure macro (EXPR) for a moot or dmoot tag; evaluates to
##    ($$mootvar ? $$mootvar->{word} : $defaultvar)
sub _am_word {
  my $mootvar = shift||'$_->{moot}';
  my $default = shift||'undef';
  return "($mootvar ? $mootvar\->{word} : $default) ##== _am_word\n";
}

## PACKAGE::_am_lemma($mootvar='$_->{moot}', $defaultvar='undef')
##  + access-closure macro (EXPR) for a moot lemma; evaluates to
##    ($$mootvar ? $$mootvar->{word} : $defaultvar)
sub _am_lemma {
  my $mootvar = shift||'$_->{moot}';
  my $default = shift||'undef';
  return "($mootvar ? $mootvar\->{lemma} : $default) ##== _am_lemma\n";
}

## PACKAGE::_am_tagh_fst2moota($taghvar='$_')
##  + access-closure macro (EXPR): single moot token analysis from TAGH-style fst analysis
##  + requires: $$taghvar->{hi}; evaluates to:
##    {details=>$taghvar->{hi}, prob=>($$taghvar->{w}||0), tag=>($$taghvar->{hi} =~ /\[\_?([A-Z0-9]+)\]/ ? \$1 : $$taghvar->{hi})}
sub _am_tagh_fst2moota {
  my $taghvar = shift||'$_';
  return ("{details=>$taghvar\->{hi},"
	  ." prob=>($taghvar\->{w}||0),"
	  ." tag=>($taghvar\->{hi} =~ /\\[\\_?((?:[A-Za-z0-9\.]+|\\\$[^\\]]+))\\]/ ? \$1 : $taghvar\->{hi})" ##-- allow e.g. [$(] tags from tokenizer!
	  ."} ##-- _am_tagh_fst2moota\n");
}

## PACKAGE::_am_tagh_list2moota($listvar='@{$_->{morph}}')
##  + access-closure macro (EXPR): moot token analysis-list from TAGH-style fst analysis-list
##  + evaluates to (something like):
##    (map { $${_am_tagh_fst2moota('$_')} } $$listvar)
sub _am_tagh_list2moota {
  my $listvar = shift||'@{$_->{morph}}';
  #return "(map {ref(\$_) ? "._am_tagh_fst2moota('$_')." : {details=>\$_,tag=>\$_,prob=>0}} $listvar) ##-- _am_tagh_list2moota\n";
  return "(map {"._am_tagh_fst2moota('$_')."} map {ref(\$_) ? \$_ : {hi=>\$_}} $listvar) ##-- _am_tagh_list2moota\n";
}

## PACKAGE::_am_tagh_moota_uniq($listvar='@_', $tmpvar='$val')
##  + access-closure macro (EXPR) for a unique (by details) list of moot analyses $$listvar
##  + only the prob-minimal analysis is kept for each 'details'
##  + evaluates to a list of details-unique fst analysis hashes:
##    (map {$$val && $$val->{details} eq $_->{details} ? qw() : ($$val=$_)} sort {$a->{details} cmp $b->{details} || ($a->{prob}//0) <=> ($b->{prob}//0)} $$listvar)
##  + assumes $$tmpvar is initialized to undef at start of evaluation
sub _am_tagh_moota_uniq {
  my $listvar = shift || '@_';
  my $tmpvar  = shift || '$val';
  return ("(map {$tmpvar && $tmpvar\->{details} eq \$_->{details} ? qw() : ($tmpvar=\$_)}"
	  .' sort {($a->{details}//"") cmp ($b->{details}//"") || ($a->{prob}//0) <=> ($b->{prob}//0)}'
	  ." $listvar)"
	  ." ##== _am_tagh_moota_uniq\n"
	 );
}

## PACKAGE::_am_tagh_list2moota_uniq($listvar, $tmpvar)
##  + wrapper for _am_tagh_moota_uniq( _am_tagh_list2moota($listvar), $tmpvar )
sub _am_tagh_list2moota_uniq {
  return _am_tagh_moota_uniq( _am_tagh_list2moota($_[0]), $_[1] );
}

## PACKAGE::_am_dmoot_fst2moota($fstvar='$_')
##  + access-closure macro (EXPR): single dmoot token analysis from fst analysis
##  + requires: $$fstvar->{hi}; evaluates to:
##    {tag=>$$fstvar->{hi}, prob=>($$fstvar->{w}||0)}
sub _am_dmoot_fst2moota {
  my $fstvar = shift||'$_';
  return "{tag=>$fstvar\->{hi}, prob=>($fstvar\->{w}||0)} ##-- _am_dmoot_fst2moota\n";
}

## PACKAGE::_am_dmoot_list2moota($listvar='@_')
##  + access-closure macro (EXPR): dmoot token analysis-list from fst analysis-list
##  + evaluates to:
##    (map { $${_am_dmoot_fst2moota('$_')} } $$listvar)
sub _am_dmoot_list2moota {
  my $listvar = shift||'@_';
  return "(map {"._am_dmoot_fst2moota('$_')."} $listvar) ##-- _am_dmoot_list2moota\n";
}

## $regex_str = PACKAGE::_am_wordlike_regex()
##  + for use e.g. by Analyzer::Automaton subclass {allowTextRegex} property defaults
sub _am_wordlike_regex {
  return '^(?:(?:[[:alpha:]\p{Combining_Diacritical_Marks}\-\@\x{ac}]*[[:alpha:]\p{CombiningDiacriticalMarks}]+)|(?:[[:alpha:]\p{CombiningDiacriticalMarks}]+[[:alpha:]\p{CombiningDiacriticalMarks}\-\@\x{ac}]+))(?:[\'\x{2018}\x{2019}]s)?$';
}


##==============================================================================
## Methods: XML-RPC
##==============================================================================

## \@sigs = $anl->xmlRpcSignatures()
##  + returns an array-ref of valid XML-RPC signatures:
##    [ "$returnType1 $argType1_1 $argType1_2 ...", ..., "$returnTypeN ..." ]
##  + known types (see http://www.xmlrpc.com/spec):
##    Tag	          Type                                             Example
##    "i4" or "int"	  four-byte signed integer                         42
##    "boolean"	          0 (false) or 1 (true)                            1
##    "string"	          string                                           hello world
##    "double"            double-precision signed floating point number    -24.7
##    "dateTime.iso8601"  date/time	                                   19980717T14:08:55
##    "base64"	          base64-encoded binary                            eW91IGNhbid0IHJlYWQgdGhpcyE=
##    "struct"            complex structure                                { x=>42, y=>24 }
##  + Default returns "string string struct"
#sub xmlRpcSignature { return ['string string']; }

## $str = $anl->xmlRpcHelp()
##  + returns help string for default XML-RPC procedure
#sub xmlRpcHelp { return '?'; }

## \%opts = $anl->mergeOptions(\%defaultOptions,\%userOptions)
##  + returns options hash like (%defaultOptions,%userOptions) [user clobbers default]
sub mergeOptions {
  my ($anl,$defaults,$user) = @_;
  return { ($defaults ? %$defaults : qw()), ($user ? %$user : qw()) };
}


## @procedures = $anl->xmlRpcMethods()
## @procedures = $anl->xmlRpcMethods($prefix,\%opts)
##  + returns a list of procedures suitable for passing to RPC::XML::Server::add_proc()
##  + additional keys recognized in procedure specs: see DTA::CAB::Server::XmlRpc::prepareLocal()
##  + "${prefix}." is appended to procedure 'name' key if $prefix is specified
##  + \%opts are passed to analyze methods if defined
sub xmlRpcMethods {
  my ($anl,$prefix,$opts) = @_;
  $prefix = $prefix ? "${prefix}." : '';
  return (
	  {
	   ##-- Analyze: Type (v1.x)
	   name      => "${prefix}analyzeType",
	   code      => sub { $anl->analyzeType($_[0],$anl->mergeOptions($opts,$_[1])) },
	   signature => [ 'struct string', 'struct string struct',  ## string ?opts -> struct
			  'struct struct', 'struct struct struct',  ## struct ?opts -> struct
			],
	   help      => 'Analyze a single token (text string or struct with "text" string field)',
	   wrapEncoding => 1,
	  },
	  {
	   ##-- Analyze: Token (v1.x)
	   name      => "${prefix}analyzeToken",
	   code      => sub {
	     #$anl->trace("analyzeToken(", (ref($_[0]) ? $_[0]{text} : $_[0]), ")"); ##-- DEBUG
	     $anl->analyzeToken($_[0],$anl->mergeOptions($opts,$_[1]));
	   },
	   signature => [ 'struct string', 'struct string struct',  ## string ?opts -> struct
			  'struct struct', 'struct struct struct',  ## struct ?opts -> struct
			],
	   help      => 'Analyze a single token (text string or struct with "text" string field)',
	   wrapEncoding => 1,
	  },
	  {
	   ##-- Analyze: Sentence (v1.x)
	   name      => "${prefix}analyzeSentence",
	   code      => sub { $anl->analyzeSentence($_[0],$anl->mergeOptions($opts,$_[1])) },
	   signature => [ 'struct array',  'struct array struct',  ## array ?opts -> struct
			  'struct struct', 'struct struct struct', ## struct ?opts -> struct
			],
	   help      => 'Analyze a single sentence (array of tokens or struct with "tokens" array field)',
	   wrapEncoding => 1,
	  },
	  {
	   ##-- Analyze: Document (v1.x)
	   name      => "${prefix}analyzeDocument",
	   code      => sub { $anl->analyzeDocument($_[0],$anl->mergeOptions($opts,$_[1])) },
	   signature => [
			 'struct array',  'struct array struct',   ## array ?opts -> struct
			 'struct struct', 'struct struct struct',  ## struct ?opts -> struct
			],
	   help      => 'Analyze a whole document (array of sentences or struct with "body" array field)',
	   wrapEncoding => 1,
	  },
	  ##-- Analyze: raw data (v1.x)
	  {
	   name => "${prefix}analyzeData",
	   code => sub { $anl->analyzeData($_[0],$anl->mergeOptions($opts,$_[1])) },
	   signature => [
			 #'string string',        ## string -> string
			 #'string string struct', ## string ?opts -> string
			 ##--
			 'base64 base64',        ## base64 -> base64
			 'base64 base64 struct', ## base64 ?opts -> base64
			],
	   help => 'Analyze raw document data with server-side parsing & formatting',
	   wrapEncoding => 0,
	  },
	 );
}


1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer - generic analyzer API

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Analyzer;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = $CLASS_OR_OBJ->new(%args);
 undef = $anl->initialize();
 undef = $anl->dropClosures();
 $label = $anl->defaultLabel();
 $class = $anl->analysisClass();
 @keys = $anl->typeKeys(\%opts);
 
 ##========================================================================
 ## Methods: I/O
 
 $bool = $anl->ensureLoaded();
 $bool = $anl->prepare();
 
 ##========================================================================
 ## Methods: Persistence: Perl
 
 @keys = $class_or_obj->noSaveKeys();
 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);
 
 @keys = $class_or_obj->noSaveBinKeys();
 $loadedObj = $CLASS_OR_OBJ->loadBinRef($ref);
 
 ##========================================================================
 ## Methods: Analysis: Utils
 
 $bool = $anl->canAnalyze();
 $bool = $anl->doAnalyze(\%opts, $name);
 $bool = $anl->enabled(\%opts);
 $bool = $anl->autoEnable();
 undef = $anl->initInfo();
 \@analyzers = $anl->subAnalyzers();
 
 ##========================================================================
 ## Methods: Analysis: API
 
 $doc = $anl->analyzeDocument($doc,\%opts);
 $doc = $anl->analyzeTypes($doc,\%types,\%opts);
 $doc = $anl->analyzeTokens($doc,\%opts);
 $doc = $anl->analyzeSentences($doc,\%opts);
 $doc = $anl->analyzeLocal($doc,\%opts);
 $doc = $anl->analyzeClean($doc,\%opts);
 
 ##========================================================================
 ## Methods: Analysis: Type-wise
 
 \%types = $anl->getTypes($doc);
 $doc = $anl->expandTypes($doc,\%types,\%opts);
 $doc = $anl->clearTypes($doc);
 
 ##========================================================================
 ## Methods: Analysis: Wrappers
 
 $tok = $anl->analyzeToken($tok_or_string,\%opts);
 $tok = $anl->analyzeSentence($sent_or_array,\%opts);
 $rpc_xml_base64 = $anl->analyzeData($data_str,\%opts);
 
 ##========================================================================
 ## Methods: Analysis: Closure Utilities
 
 \&closure = $anl->analyzeClosure($which);
 \&closure = $anl->getAnalyzeClosure($which);
 
 $closure = $anl->accessClosure( $methodName);

 PACKAGE::_am_xlit($tokvar);
 PACKAGE::_am_lts($tokvar);
 PACKAGE::_am_tt_list($ttvar);
 PACKAGE::_am_tt_fst($ttvar);
 PACKAGE::_am_id_fst($tokvar, $wvar);
 PACKAGE::_am_tt_fst_list($ttvar);
 PACKAGE::_am_fst_sort($listvar);
 PACKAGE::_am_fst_clean($hashvar);
 
 ##========================================================================
 ## Methods: XML-RPC
 
 \%opts = $anl->mergeOptions(\%defaultOptions,\%userOptions);
 @procedures = $anl->xmlRpcMethods();
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Analyzer
is an abstract class and API specification for representing
arbitrary semi-independent document analysis algorithms.
Each
analyzer sub-class should define at least one of the
analyzeXYZ() methods (analyzeTypes(), analyzeTokens(), etc.),
and each analyzer instance should set a 'name' key.
Analyzer objects are assumed to be HASH refs, and should define
at least a 'label' key to identify the analyzer object e.g. in
a multi-analyzer processing chain.

DTA::CAB::Analyzer inherits from
L<DTA::CAB::Persistent|DTA::CAB::Persistent>
(and thus indirectly from L<DTA::CAB::Logger|DTA::CAB::Logger>),
and provides some basic hooks for extending the
L<DTA::CAB::Persistent|DTA::CAB::Persistent> functionality.
These routines are especially useful e.g. for defining
analyzer parameters in a configuration file which can be passed
to the L<dta-cab-analyze.perl|dta-cab-analyze.perl> comman-line
script via the "-config" option.

See L<DTA::CAB::Analyzer::Common|DTA::CAB::Analyzer::Common> for
a list of common analyzer sub-classes.

See L<DTA::CAB::Chain|DTA::CAB::Chain> for an abstract analyzer class
representing simple linear analysis chains (aka "pipelines"),
and see
L<DTA::CAB::Chain::Multi|DTA::CAB::Chain::Multi> for an abstract
analyzer class representing a set of named analysis pipelines.  Since
analysis chains are themselves implemented as subclasses of
DTA::CAB::Analyzer, analysis chains may be nested to arbitrary depth (at least in theory).

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

%$obj, %args:

 label => $label,    ##-- analyzer label (default: from class name)
 aclass => $class,   ##-- analysis class (optional; see $anl->analysisClass() method; default=undef)
 typeKeys => \@keys, ##-- analyzer type keys for $anl->typeKeys()
 enabled => $bool,   ##-- set to false, non-undef value to disable this analyzer
 initQuiet => $bool, ##-- if true, initInfo() will not print any output

=item initialize

 undef = $anl->initialize();

Initialize the analyzer.
Default implementation does nothing

=item dropClosures

 undef = $anl->dropClosures();

B<OBSOLETE>: drops '_analyze*' closures.
This method is a relic of an obsolete API, and should go away.
The method name is still used with (basically) its original semantics
by the (unmaintained) subclass L<DTA::CAB::Analyzer::Dyn|DTA::CAB::Analyzer::Dyn>.

Currently does nothing.

=item defaultLabel

 $label = $anl->defaultLabel();

Returns default label for this class.
Default implementation returns the final segment of the Perl class-name.

=item analysisClass

 $class = $anl->analysisClass();

B<DEPRECATED>: Gets cached $anl-E<gt>{aclass} if exists, otherwise returns undef.
Really just an ugly wrapper for $anl-E<gt>{aclass}.

This method is an (unused) relic of an abandoned attempt to force all analysis outputs
to be bless()ed Perl objects.  Try to avoid it.

=item typeKeys

 @keys = $anl->typeKeys(\%opts);

Returns list of type-wise keys to be expanded for this analyzer by expandTypes().
Default returns @{$anl-E<gt>{typeKeys}} if defined, otherwise ($anl-E<gt>{label}).

The default is really annoying and potentially dangerous if you're not writing a
type-wise analyzer, but most of the current analyzers do operate type-wise, so
it was convenient.  Override if necessary.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: I/O
=pod

=head2 Methods: I/O

=over 4

=item ensureLoaded

 $bool = $anl->ensureLoaded();
 $bool = $anl->ensureLoaded(\%opts);

Ensures analysis data is loaded from default files, or that
no data is available to be loaded.
Should return false only if user has requested data to be loaded
and that data cannot be loaded.  "Empty" analyzers should return
true here.

Default implementation always returns true.

This method is poorly named, and almost entirely useless, since some
analyzers require it to be called very early, before other potentially
relevant options have been evaluated.  Returning false here may cause
a host application (e.g. dta-cab-analyze.perl) to die().  Such behavior
may not be desirable however if no analysis source data (e.g. dictionary files)
was found (perhaps because it was undefined);
see the canAnalyze() and autoDisable() methods for workarounds.

=item prepare

 $bool = $anl->prepare();
 $bool = $anl->prepare(\%opts)

Wrapper for ensureLoaded(), autoEnable(), initInfo().
Should probably replace top-level calls to ensureLoaded() in host applications.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Returns list of keys not to be saved.
Default implementation just greps for CODE-refs.

=item loadPerlRef

 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);

Default implementation just clobbers $CLASS_OR_OBJ with $ref and blesses.

=item noSaveBinKeys

 @keys = $class_or_obj->noSaveBinKeys();

Returns list of keys not to be saved for binary mode
Default just greps for CODE-refs.

=item loadBinRef

 $loadedObj = $CLASS_OR_OBJ->loadBinRef($ref);

Implicitly calls $OBJ-E<gt>dropClosures().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: Analysis: Utils
=pod

=head2 Methods: Analysis: Utils

=over 4

=item canAnalyze

 $bool = $anl->canAnalyze();
 $bool = $anl->canAnalyze(\%opts);

Returns true iff analyzer can perform its function (e.g. data is loaded & non-empty).
Default implementation always returns true.

=item doAnalyze

 $bool = $anl->doAnalyze(\%opts, $name);

Alias for $anl-E<gt>can("analyze${name}") && (!exists($opts{"doAnalyze${name}"}) || $opts{"doAnalyze${name}"}).

=item enabled

 $bool = $anl->enabled(\%opts);

Returns true if analyzer SHOULD operate, acording to %opts.
Default returns:

 (!defined($anl->{enabled}) || $anl->{enabled})                           ##-- globally enabled
 &&
 (!$opts || !defined($opts{"${lab}_enabled"} || $opts{"${lab}_enabled"})  ##-- ... and locally enabled

=item autoEnable

 $bool = $anl->autoEnable();
 $bool = $anl->autoEnable(\%opts);

Sets $anl-E<gt>{enabled} flag if not already defined.
Calls $anl-E<gt>canAnalyze(\%opts).
Returns new value of $anl-E<gt>{enabled}.
Implicitly calls autoEnable() on all sub-analyzers.

=item autoDisable

Alias for autoEnable().

=item initInfo

 undef = $anl->initInfo();

Logs initialization info.
Default method reports values of {label}, enabled().
Sets $anl-E<gt>{initQuiet}=1 (don't report multiple times).

=item subAnalyzers

 \@analyzers = $anl->subAnalyzers();
 \@analyzers = $anl->subAnalyzers(\%opts)

Returns a list of all sub-analyzers for this object.
Default returns all DTA::CAB::Analyzer subclass instances in values(%$anl).

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: Analysis: API
=pod

=head2 Methods: Analysis: API

=over 4

=item analyzeDocument

 $doc = $anl->analyzeDocument($doc,\%opts);

Top-level API routine:
analyze a DTA::CAB::Document $doc.
Default implementation just calls:

 $doc = toDocument($doc);
 if ($anl->doAnalyze('Types')) {
   $types = $anl->getTypes($doc);
   $anl->analyzeTypes($doc,$types,\%opts);
   $anl->expandTypes($doc,$types,\%opts);
   $anl->clearTypes($doc);
 }
 $anl->analyzeTokens($doc,\%opts)    if ($anl->doAnalyze(\%opts,'Tokens'));
 $anl->analyzeSentences($doc,\%opts) if ($anl->doAnalyze(\%opts,'Sentences'));
 $anl->analyzeLocal($doc,\%opts)     if ($anl->doAnalyze(\%opts,'Local'));
 $anl->analyzeClean($doc,\%opts)     if ($anl->doAnalyze(\%opts,'Clean'));


=item analyzeTypes

 $doc = $anl->analyzeTypes($doc,\%types,\%opts);

Perform type-wise analysis of all (text) types in \%types (default is $doc-E<gt>{types}).
Default implementation does nothing.

=item analyzeTokens

 $doc = $anl->analyzeTokens($doc,\%opts);

Perform token-wise analysis of all tokens $doc-E<gt>{body}[$si]{tokens}[$wi].
Default implementation does nothing.

=item analyzeSentences

 $doc = $anl->analyzeSentences($doc,\%opts);

Perform sentence-wise analysis of all sentences $doc-E<gt>{body}[$si].
Default implementation does nothing.

=item analyzeLocal

 $doc = $anl->analyzeLocal($doc,\%opts);

Perform analyzer-local document-level analysis of $doc.
Default implementation does nothing.

=item analyzeClean

 $doc = $anl->analyzeClean($doc,\%opts);

Cleanup any temporary data associated with $doc.
Default implementation does nothing.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: Analysis: Type-wise
=pod

=head2 Methods: Analysis: Type-wise

=over 4

=item getTypes

 \%types = $anl->getTypes($doc);

Returns a hash

 \%types = ($typeText => $typeToken, ...)

mapping token text to
basic token objects (with only 'text' key defined).
Default implementation just calls $doc-E<gt>types().

=item expandTypes

 $doc = $anl->expandTypes($doc,\%types,\%opts);

Expands \%types into $doc-E<gt>{body} tokens.
Default implementation just calls $doc-E<gt>expandTypeKeys(\@typeKeys,\%types),
where \@typeKeys is derived from $anl-E<gt>typeKeys().

=item clearTypes

 $doc = $anl->clearTypes($doc);

Clears cached type-E<gt>object map in $doc-E<gt>{types}.
Default just calls $doc-E<gt>clearTypes().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: Analysis: Wrappers
=pod

=head2 Methods: Analysis: Wrappers

=over 4

=item analyzeToken

 $tok = $anl->analyzeToken($tok_or_string,\%opts);

Compatibility wrapper:
perform type- and token- analyses on $tok_or_string.
Really just a wrapper for $anl-E<gt>analyzeDocument().

=item analyzeSentence

 $tok = $anl->analyzeSentence($sent_or_array,\%opts);

Compatibility wrapper:
perform type- and token-, and sentence- analyses on $sent_or_array.
Really just a wrapper for $anl-E<gt>analyzeDocument().

=item analyzeData

 $rpc_xml_base64 = $anl->analyzeData($data_str,\%opts);

Analyze a raw (formatted) data string $data_str with internal parsing & formatting.
Really just a wrapper for $anl-E<gt>analyzeDocument().

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: Analysis: Closure Utilities (optional)
=pod

=head2 Methods: Analysis: Closure Utilities (optional)

=over 4

=item analyzeClosure

 \&closure = $anl->analyzeClosure($which);

Optional utility for closure-based analysis.
Returns cached $anl-E<gt>{"_analyze${which}"} if present;
otherwise calls $anl-E<gt>getAnalyzeClosure($which) & caches result.

=item getAnalyzeClosure

 \&closure = $anl->getAnalyzeClosure($which);

Returns closure \&closure for analyzing data of type "$which"
(e.g. Word, Type, Token, Sentence, Document, ...).
Default implementation calls $anl-E<gt>getAnalyze"${which}"Closure() if
available, otherwise croak()s.

=item accessClosure

 $closure = $anl->accessClosure(\&codeRef,    %opts);
 $closure = $anl->accessClosure( $methodName, %opts);
 $closure = $anl->accessClosure( $codeString, %opts);

Returns accessor-closure $closure for $anl.
Passed argument can be one of the following:

=over 4

=item $codeRef

a CODE ref resolves to itself

=item $methodName

a method name resolves to $anl-E<gt>can($methodName)

=item $codeString

any other string resolves to 'sub { $codeString }';
which may reference the closure variable $anl

=back

Additional options for $codeString pseudo-accessors can be passed in %opts:

 pre => $prefix,     ##-- compiles as "${prefix}; sub {$code}"
 vars => \@vars,     ##-- compiles as 'my ('.join(',',@vars).'); '."sub {$code}"

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: Analysis: Closure Utilities: Macros
=pod

=head3 Methods: Analysis: Closure Utilities: Macros

In order to facilitate development of analyzer-local accessor code in string form,
the following "macros" are defined as exportable functions.  Their arguments and
return values are B<strings> suitable for inclusion in acccessor macros.  These
macros are exported by the tags ':access', ':child', and ':all'.

=over 4

=item _am_xlit

 PACKAGE::_am_xlit($tokvar='$_');

access-closure macro: get xlit or text for token $$tokvar;
evaluates to a string:
($$tokvar-E<gt>{xlit} ? $$tokvar-E<gt>{xlit}{latin1Text} : $$tokvar-E<gt>{text})

=item _am_lts

 PACKAGE::_am_lts($tokvar='$_');

access-closure macro for first LTS analysis of token $$tokvar;
evaluates to string:
($$tokvar-E<gt>{lts} && @{$$tokvar-E<gt>{lts}} ? $$tokvar-E<gt>{lts}[0]{hi} : $$tokvar-E<gt>{text})

=item _am_tt_list

 PACKAGE::_am_tt_list($ttvar='$_');

access-closure macro for a TT-style list of strings $$ttvar;
evaluates to a list: split(/\\t/,$$ttvar)

=item _am_tt_fst

 PACKAGE::_am_tt_fst($ttvar='$_');

(formerly mutliply defined in sub-packages as SUBPACKAGE::parseFstString())

access-closure macro for a single TT-style FST analysis $$ttvar;
evaluates to a FST-analysis hash {hi=E<gt>$hi,w=E<gt>$w,lo=E<gt>$lo,lemma=E<gt>$lemma}:

    (
     $$ttvar =~ /^(?:(.*?) \: )?(?:(.*?) \@ )?(.*?)(?: \<([\d\.\+\-eE]+)\>)?$/
     ? {(defined($1) ? (lo=>$1) : qw()), (defined($2) ? (lemma=>$2) : qw()), hi=>$3, w=>($4||0)}
     : {hi=>$$ttvar}
    )

=item _am_id_fst

 PACKAGE::_am_id_fst($tokvar='$_', $wvar='0');

access-closure macro for a identity FST analysis;
evaluates to a single fst analysis hash:
{hi=E<gt>_am_xlit($tokvar), w=E<gt>$$wvar}

=item _am_tt_fst_list

 PACKAGE::_am_tt_fst_list($ttvar='$_');

access-closure macro for a list of TT-style FST analyses $$ttvar;
evaluates to a list of fst analysis hashes:
(map {_am_tt_fst('$_')} split(/\t/,$$ttvar))

=item _am_tt_fst_eqlist

 PACKAGE::_am_tt_fst_eqlist($ttvar='$tt', $tokvar='$_', $wvar='0');

access-closure macro for a list of TT-style FST analyses $$ttvar;
evaluates to a list of fst analysis hashes:
(_am_id_fst($tokvar,$wvar), _am_tt_fst_list($ttvar))

=item _am_fst_sort

 PACKAGE::_am_fst_sort($listvar='@_');

access-closure macro to sort a list of FST analyses $$listvar by weight;
evaluates to a sorted list of fst analysis hashes:
(sort {($a-E<gt>{w}||0) E<lt>=E<gt> ($b-E<gt>{w}||0) || ($a-E<gt>{hi}||"") cmp ($b-E<gt>{hi}||"")} $$listvar)

=item _am_fst_clean

 PACKAGE::_am_fst_clean($hashvar='$_->{$lab}');

access-closure macro to delete undefined hash entries;
evaluates to:
delete($$hashvar) if (!defined($$hashvar));

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer: Methods: XML-RPC
=pod

=head2 Methods: XML-RPC

=over 4

=item mergeOptions

 \%opts = $anl->mergeOptions(\%defaultOptions,\%userOptions);

Returns options hash like (%defaultOptions,%userOptions) [user clobbers default].

=item xmlRpcMethods

 @procedures = $anl->xmlRpcMethods();
 @procedures = $anl->xmlRpcMethods($prefix,\%opts);

=over 4

=item *

returns a list of procedures suitable for passing to RPC::XML::Server::add_proc()

=item *

additional keys recognized in procedure specs: see DTA::CAB::Server::XmlRpc::prepareLocal()

=item *

"${prefix}." is appended to procedure 'name' key if $prefix is specified

=item *

\%opts are passed to analyze methods if defined

=back

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl
=pod



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

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Analyzer::Common(3pm)|DTA::CAB::Analyzer::Common>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB::Chain::Multi(3pm)|DTA::CAB::Chain::Multi>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
