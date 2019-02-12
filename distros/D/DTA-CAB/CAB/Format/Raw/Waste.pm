## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::Raw::Waste.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser: raw untokenized text (using moot/waste)

package DTA::CAB::Format::Raw::Waste;
use DTA::CAB::Format;
use DTA::CAB::Format::TT;
use DTA::CAB::Datum ':all';
use DTA::CAB::Utils qw(file_mtime timestamp_str);
use IO::File;
use Cwd qw(abs_path);
use Encode qw(encode decode);
use Moot::Waste;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'raw-waste', filenameRegex=>qr/\.(?i:raw-waste|txt-waste)$/);
}

our @DEFAULT_WASTERC_PATHS =
  (
   ($ENV{TOKWRAP_RCDIR} ? "$ENV{TOKWRAP_RCDIR}/waste/waste.rc" : qw()),
   (defined($DTA::TokWrap::Version::VERSION) ? "$DTA::TokWrap::Version::RCDIR/waste/waste.rc" : qw()),
   (defined $ENV{HOME} ? "$ENV{HOME}/.wasterc" : qw()),
   "/etc/wasterc",
   "/etc/default/wasterc"
  );

## $logLoad : default logLoad option
our $logLoad = 'trace';

## $logCache : default logCache option
our $logCache = undef;

## $logRun : default logRun option
our $logRun = undef;

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    {
##     ##-- Input
##     doc => $doc,                    ##-- buffered input document
##     wasterc => $rcFile,             ##-- waste .rc file; default: "$HOME/.wasterc" || "/etc/wasterc" || "/etc/default/waste"
##
##     ##-- Runtime
##     wmodel => \%wmodel              ##-- waste model; %wmodel=(
##                                     #    config   => \%config,  #-- parsed rcfile (see loadModelConfig())
##                                     #    loaded   => $time,     #-- unix timestamp of last model load
##                                     #    wscanner => $scanner,  #-- waste scanner
##                                     #    wlexer   => $lexer,    #-- waste lexer
##                                     #    wtagger  => $tagger,   #-- waste tagger
##                                     #    wdecoder => $decoder,  #-- waste decoder
##                                     #    wannotator => $wannot, #-- waste annotator
##                                     #    wwriter => $wwriter,   #-- native-format writer (hack)
##                                     # )
##
##     ##-- logging (in order of increasing verbosity)
##     logLoad => $level,              # log-level for model loading (default=$logLoad)
##     logCache => $level,             # cache operation log-level (default=$logCache)
##     logRun => $level,               # runtime operation log-level (default=$logRun)
##
##     ##-- Common
##     #utf8 => $bool,		       ##-- utf8 mode always on
sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- common
		   utf8 => 1,

		   ##-- input
		   doc => undef,
		   wasterc => undef,

		   ##-- runtime
		   wmodel => undef,

		   ##-- logging
		   logLoad => $logLoad,
		   logCache => $logCache,
		   logRun => $logRun,

		   ##-- user args
		   @_
		  }, ref($that)||$that);
  return $fmt;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + default just returns empty list
sub noSaveKeys {
  return (shift->SUPER::noSaveKeys(), qw(doc wmodel wscanner wlexer wtagger wdecoder wannotator wwriter));
}

##==============================================================================
## Methods: Local: log levels

## $logLoad = $CLASS_OR_OBJECT->logLevelLoad()
sub logLevelLoad { return ref($_[0]) ? $_[0]{logLoad} : $logLoad; }

## $logCache = $CLASS_OR_OBJECT->logLevelCache()
sub logLevelCache { return ref($_[0]) ? $_[0]{logCache} : $logCache; }

## $logRun = $CLASS_OR_OBJECT->logLevelRun()
sub logLevelRun { return ref($_[0]) ? $_[0]{logRun} : $logRun; }


##==============================================================================
## Methods: Local: model caching

## %MODELS : cached models ("$wasterc_abspath:$PID" => \%wmodel)
our %MODELS = qw();

END {
  ##-- END block clears cached waste models for this PID
  my @cached = grep {/:${$}$/} keys %MODELS;
  __PACKAGE__->vlog(__PACKAGE__->logLevelCache, "clearing model cache for PID $$: ", join(' ', @cached));
  delete @MODELS{@cached};
}

## \%wmodel_or_undef = $fmt->ensureModel()
## \%wmodel_or_undef = $fmt->ensureModel($wasterc)
## \%wmodel_or_undef = CLASS->ensureModel($wasterc)
##  + loads cached model if available; otherwise populates cache
sub ensureModel {
  my ($fmt,$rcfile) = @_;
  $rcfile = $fmt->{rcfile} if (ref($fmt) && !$rcfile);

  ##-- get rc file
  if (!$rcfile) {
    $rcfile = (grep {-f $_} @DEFAULT_WASTERC_PATHS)[0];
    $fmt->logconfess("getModel(): no wasterc specified!") if (!$rcfile);
  }

  ##-- cache lookup
  my $mkey   = abs_path($rcfile).":$$";
  my $wmodel = $MODELS{$mkey};
  ##-- debug
  if (defined($wmodel)) {
    $fmt->vlog($fmt->logLevelCache, "found cached waste model: $mkey");

    my $modeltime = int(file_mtime($rcfile));
    if ($wmodel->{loaded} >= $modeltime) {
      $fmt->vlog($fmt->logLevelCache, "using cached waste model: $mkey");
      return $wmodel;
    } else {
      $fmt->vlog($fmt->logLevelCache,
		 "cached waste model is stale (".timestamp_str($wmodel->{loaded}).' < '.timestamp_str($modeltime)."): $mkey");
    }
  } else {
    $fmt->vlog($fmt->logLevelCache, "no cached waste model found: $mkey");
  }

  ##-- not cached or stale: create a new model & update the cache
  $fmt->vlog($fmt->logLevelCache, "updating waste model cache: $mkey");
  my $config = $fmt->loadModelConfig($rcfile);
  $wmodel = $MODELS{$mkey} =
    {
     config   => $config,
     loaded   => time(),
     wscanner => Moot::Waste::Scanner->new( $Moot::ioFormat{text}|$Moot::ioFormat{location} ),
     wlexer   => Moot::Waste::Lexer->new( $Moot::ioFormat{wd}|$Moot::ioFormat{location} ),
     wtagger  => Moot::HMM->new(),
     wdecoder => Moot::Waste::Decoder->new( $Moot::ioFormat{m}|$Moot::ioFormat{location} ),
     wannotator => Moot::Waste::Annotator->new( $Moot::ioFormat{mr}|$Moot::ioFormat{location} ),
     wwriter  => Moot::TokenWriter::Native->new( $Moot::ioFormat{mr}|$Moot::ioFormat{location} ),
    };

  ##-- load model from configuration options
  $wmodel->{wlexer}->abbrevs->load($config->{abbrevs}) if ($config->{abbrevs});
  $wmodel->{wlexer}->conjunctions->load($config->{conjunctions}) if ($config->{conjunctions});
  $wmodel->{wlexer}->stopwords->load($config->{stopwords}) if ($config->{stopwords});
  $wmodel->{wlexer}->dehyphenate($config->{dehyphenate} ? 1 : 0) if (exists $config->{dehyphenate});
  if ($config->{hmm}) {
    $wmodel->{wtagger}->load($config->{hmm}) or $fmt->logconfess("failed to load waste model '$config->{hmm}'");
  } else {
    $fmt->logconfess("no 'hmm' key specified in waste rc-file '$rcfile'");
  }

  return $wmodel;
}

## \%config = CLASS_OR_OBJECT->loadModelConfig($wasterc)
##   + loads rc-file with keys qw(abbrevs conjunctions stopwords dehyphenate hmm)
sub loadModelConfig {
  my ($fmt,$rcfile) = @_;
  $fmt->vlog($fmt->logLevelCache, "loading waste model configuration $rcfile");

  open(my $rc,"<$rcfile")
    or $fmt->logconfess("open failed for waste-rc $rcfile: $!");
  my $config = {rcfile=>$rcfile};
  while (defined($_=<$rc>)) {
    next if (/^\#/ || /^\s*$/);
    chomp;
    my ($opt,$val) = split(/\s/,$_,2);
    if    ($opt =~ /^abbr/) { $config->{abbrevs}=$val }
    elsif ($opt =~ /^conj/) { $config->{conjunctions}=$val; }
    elsif ($opt =~ /^stop/) { $config->{stopwords}=$val; }
    elsif ($opt =~ /^dehyph/) { $config->{dehyphenate}=$val; }
    elsif ($opt =~ /^no-dehyph/) { $config->{dehyphenate}=$val; }
    elsif ($opt =~ /^(?:hmm|model)/) { $config->{hmm}=$val; }
    else {
      ; ##-- ignore other options
    }
  }
  close($rc);

  $fmt->vlog($fmt->logLevelLoad, "loaded waste model configuration $rcfile");
  return $config;
}

##==============================================================================
## Methods: Model I/O

## $fmt_or_undef = $fmt->ensureLoaded()
sub ensureLoaded {
  my $fmt = shift;
  return $fmt if ($fmt->{wmodel} && $fmt->{wmodel}{wtagger});

  ##-- get rc file
  if (!$fmt->{wasterc}) {
    $fmt->{wasterc} = (grep {-f $_} @DEFAULT_WASTERC_PATHS)[0];
    $fmt->logconfess("cannot tokenize without a model -- specify wasterc!") if (!$fmt->{wasterc});
  }
  #$fmt->vlog($fmt->logLevelRun, "using waste model configuration $fmt->{wasterc}");

  return $fmt->loadModel();
}

## $fmt_or_undef = $fmt->loadModel()
## $fmt_or_undef = $fmt->loadModel($rcfile)
##  + backwards-compatible
sub loadModel {
  my ($fmt,$rcfile) = @_;
  $rcfile //= $fmt->{wasterc};
  $fmt->{wasterc} = $rcfile;
  $fmt->vlog($fmt->logLevelRun, "using waste model $rcfile");
  $fmt->{wmodel} = $fmt->ensureModel($rcfile)
    or $fmt->logconfess("failed to load waste model '$rcfile': $!");

  return $fmt;
}

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->close()
sub close {
  delete($_[0]{doc});
  return $_[0]->SUPER::close(@_[1..$#_]);
}

## $fmt = $fmt->fromString( $string)
## $fmt = $fmt->fromString(\$string)
##  + select input from string $string
##  + default calls fromFh()
sub fromString {
  my $fmt = shift;
  my $ref = ref($_[0]) ? $_[0] : \$_[0];
  return $fmt->SUPER::fromString(@_) if (!utf8::is_utf8($$ref));

  my $raw = $$ref;
  utf8::encode($raw);
  return $fmt->SUPER::fromString(\$raw);
}

## $fmt = $fmt->fromFh($fh)
sub fromFh {
  my ($fmt,$fh) = @_;
  $fmt->ensureLoaded();

  my ($ttstr);
  my $wmodel = $fmt->{wmodel};
  $wmodel->{wlexer}->close();
  $wmodel->{wscanner}->close();
  $wmodel->{wscanner}->from_fh($fh);
  $wmodel->{wlexer}->scanner($wmodel->{wscanner});
  $wmodel->{wwriter}->to_string($ttstr);
  $wmodel->{wdecoder}->sink($wmodel->{wannotator});
  $wmodel->{wannotator}->sink($wmodel->{wwriter});
  $wmodel->{wtagger}->tag_stream($wmodel->{wlexer},$wmodel->{wdecoder});
  $wmodel->{wdecoder}->close();
  $wmodel->{wannotator}->close();
  $wmodel->{wwriter}->close();

  ##-- construct & buffer document
  utf8::decode($ttstr) if (!utf8::is_utf8($ttstr));
  $fmt->{doc} = DTA::CAB::Format::TT->parseTokenizerString(\$ttstr);
  return $fmt;
}

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
sub parseDocument {
  return $_[0]{doc};
}


##==============================================================================
## Methods: Output
##  + output not supported
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + default returns text/plain
sub mimeType { return 'text/plain'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.raw'; }


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl
=pod

=cut

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::Raw::Waste - Datum parser: raw untokenized text (using moot/waste)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Format::Raw::Waste;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = CLASS_OR_OBJ->new(%args);
 
 ##========================================================================
 ## Methods: Persistence
 
 @keys = $class_or_obj->noSaveKeys();
 
 ##========================================================================
 ## Methods: Local: model caching
 
 \%wmodel_or_undef = $fmt->ensureModel();
 \%config = CLASS_OR_OBJECT->loadModelConfig($wasterc);
 
 ##========================================================================
 ## Methods: Model I/O
 
 $fmt_or_undef = $fmt->ensureLoaded();
 $fmt_or_undef = $fmt->loadModel();
 
 ##========================================================================
 ## Methods: Input: Input selection
 
 $fmt = $fmt->close();
  + default calls fromFh();
 
 ##========================================================================
 ## Methods: Input: Generic API
 
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output: Generic
 
 $type = $fmt->mimeType();
 $ext = $fmt->defaultExtension();
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

Inherits from L<DTA::CAB::Format|DTA::CAB::Format>.

=item Variable: @DEFAULT_WASTERC_PATHS

List of default paths to search for waste.rc config files; see L<mootfiles|mootfiles(5)>;
default value:

 ($ENV{TOKWRAP_RCDIR} ? "$ENV{TOKWRAP_RCDIR}/waste/waste.rc" : qw()),
 (defined($DTA::TokWrap::Version::VERSION) ? "$DTA::TokWrap::Version::RCDIR/waste/waste.rc" : qw()),
 "$ENV{HOME}/.wasterc",
 "/etc/wasterc",
 "/etc/default/wasterc"

=item Variable: $logLoad

=item Variable: $logCache

=item Variable: $logRun

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

object structure: assumed HASH

    {
     ##-- Input
     doc => $doc,                    ##-- buffered input document
     wasterc => $rcFile,             ##-- waste .rc file; default: "$HOME/.wasterc" || "/etc/wasterc" || "/etc/default/waste"
 
     ##-- Runtime
     wmodel => \%wmodel              ##-- waste model; %wmodel=(
                                     #    config   => \%config,  #-- parsed rcfile (see loadModelConfig())
                                     #    loaded   => $time,     #-- unix timestamp of last model load
                                     #    wscanner => $scanner,  #-- waste scanner
                                     #    wlexer   => $lexer,    #-- waste lexer
                                     #    wtagger  => $tagger,   #-- waste tagger
                                     #    wdecoder => $decoder,  #-- waste decoder
                                     #    wannotator => $wannot, #-- waste annotator
                                     #    wwriter => $wwriter,   #-- native-format writer (hack)
                                     # )
 
     ##-- logging (in order of increasing verbosity)
     logLoad => $level,              # model loading log-level (default=$logLoad)
     logCache => $level,             # cache operation log-level (default=$logCache)
     logRun => $level,               # runtime operation log-level (default=$logRun)
 
     ##-- Common
     #utf8 => $bool,		       ##-- utf8 mode always on

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();


Returns list of keys not to be saved; override appends
C<qw(doc wmodel wscanner wlexer wtagger wdecoder wannotator wwriter)>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Methods: Local: model caching
=pod

=head2 Methods: Local: model caching

=over 4

=item Variable: %MODELS

Cached models (C<"$wasterc_abspath:$PID" =E<gt> \%wmodel>)

=item ensureModel

 \%wmodel_or_undef = $fmt->ensureModel();
 \%wmodel_or_undef = $fmt->ensureModel($wasterc)
 \%wmodel_or_undef = CLASS->ensureModel($wasterc)

Loads cached model if available; otherwise populates cache.

=item loadModelConfig

 \%config = CLASS_OR_OBJECT->loadModelConfig($wasterc);

loads rc-file with keys C<qw(abbrevs conjunctions stopwords dehyphenate hmm)>

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Methods: Model I/O
=pod

=head2 Methods: Model I/O

=over 4

=item ensureLoaded

 $fmt_or_undef = $fmt->ensureLoaded();

ensures model is loaded.

=item loadModel

 $fmt_or_undef = $fmt->loadModel();
 $fmt_or_undef = $fmt->loadModel($rcfile);

backwards-compatible method wraps L<ensureModel|ensureModel()>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Methods: Input: Input selection
=pod

=head2 Methods: Input: Input selection

=over 4

=item close

 $fmt = $fmt->close();

(undocumented)

=item fromFh

 $fmt = $fmt->fromFh($fh)

select input from a filehandle.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Methods: Input: Generic API
=pod

=head2 Methods: Input: Generic API

=over 4

=item parseDocument

 $doc = $fmt->parseDocument();

just returns $fmt-E<gt>{doc}.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Raw::Waste: Methods: Output: Generic
=pod

=head2 Methods: Output: Generic

=over 4

=item mimeType

 $type = $fmt->mimeType();

default returns C<text/plain>

=item defaultExtension

 $ext = $fmt->defaultExtension();

returns default filename extension for this format (C<.raw>)

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

Copyright (C) 2011-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<dta-cab-http-server.perl(1)|dta-cab-http-server.perl>,
L<dta-cab-http-client.perl(1)|dta-cab-http-client.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB::Server(3pm)|DTA::CAB::Server>,
L<DTA::CAB::Client(3pm)|DTA::CAB::Client>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
