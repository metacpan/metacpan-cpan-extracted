## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::SynCoPe
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA chain: RPC-XML query of an existing SynCoPe server
##  + sets $tok->{mapclass}

package DTA::CAB::Analyzer::SynCoPe;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Format::SynCoPe::CSV;
use RPC::XML::Client;
use Encode qw(encode_utf8 decode_utf8);
use XML::Parser;
use Carp;
use strict;
our @ISA = qw(DTA::CAB::Analyzer);

##======================================================================
## Methods

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure, %args:
##     server => $url,		##-- xml-rpc server url (default: http://localhost:8081/RPC2)
##     label  => $label,        ##-- analysis label (default: 'syncope')
##     method => $method,       ##-- xml-rpc analysis method (default: 'syncop.ne.analyse')
##     useragent => \@args,	##-- args for LWP::UserAgent behind RPC::XML::Client; default: [timeout=>60]
##
##  + low-level object data:
##     client => $cli,          ##-- XML::RPC client for this object
##     xp     => $xp,           ##-- XML::Parser for parsing responses
sub new {
  my $that = shift;
  my $asub = $that->SUPER::new(
			       ##-- analysis selection
			       label => 'syncope',
			       server => 'http://localhost:8081',
			       method => 'syncop.ne.analyse',
			       useragent=>[timeout=>60],

			       ##-- low-level data
			       client => undef,
			       xp     => undef,

			       ##-- user args
			       @_
			      );
  return $asub;
}

## $bool = $anl->doAnalyze(\%opts, $name)
##  + override: only allow analyzeSentences()
sub doAnalyze {
  my $anl = shift;
  return 0 if (defined($_[1]) && $_[1] ne 'Sentences');
  return $anl->SUPER::doAnalyze(@_);
}

## $doc = $anl->Sentences($doc,\%opts)
##  + post-processing for 'moot' object
sub analyzeSentences {
  my ($anl,$doc,$opts) = @_;
  return $doc if (!$anl->enabled($opts));

  my $label = $anl->{label};
  my $qsref = $anl->doc2qstr($doc);
  my $rsp   = $anl->query($qsref);
  $anl->spliceback($doc,$rsp);

  return $doc;
}

##======================================================================
## Local utilities: query preparaion

## \$querystr = $anl->doc2qstr($doc)
## \$querystr = $anl->doc2qstr($doc,$docname)
##  + get query string for document
##  + child classes should override this
##  + default implementation is appropriate for Didakowski/Drotschmann ne-recognizer v1.2.0.4
##  + see http://odo.dwds.de/twiki/bin/view/DWDS/EigennamenErkennung for details
sub doc2qstr {
  my ($anl,$doc,$docname) = @_;
  my $fmt  = DTA::CAB::Format::SynCoPe::CSV->new();
  my $qstr = '';
  $fmt->toString(\$qstr)->putDocument($doc)->flush();
  return \$qstr;
}

##======================================================================
## Local utilities: query

## $cli = $anl->client()
##  + returns xml-rpc client
sub client {
  return $_[0]{client} if (defined($_[0]{client}));
  return $_[0]{client} = RPC::XML::Client->new($_[0]{server}, useragent=>($_[0]{useragent}||[]));
}

## $response_stringref_or_undef = $anl->query(\$qstr)
##  + warns if something goes wrong
sub query {
  my ($anl,$qsr) = @_;
  local $RPC::XML::ENCODING = "UTF-8";
  local $RPC::XML::FORCE_STRING_ENCODING = 1;
  $$qsr = Encode::encode_utf8($$qsr) if (utf8::is_utf8($$qsr));
  my $rsp = $anl->client->simple_request($anl->{method},$$qsr,'tab','xml(2)');
  $anl->logwarn("Warning: XML-RPC analysis failed: $RPC::XML::ERROR") if (!defined($rsp));
  $anl->logwarn("Warning: XML-RPC analysis failed: $rsp->{faultString}") if (UNIVERSAL::isa($rsp,'HASH') && $rsp->{faultString});
  return $rsp && UNIVERSAL::isa($rsp,'ARRAY') ? \$rsp->[0] : (ref($rsp) ? $rsp : \$rsp);
}

##======================================================================
## Local utilities: response

##----------------------------------------------------------------------
## $doc = $anl->spliceback($doc, \$syncope_xml_response_string, %opts)
##  + %opts: (none)
sub spliceback {
  my ($anl,$doc,$rsp,%opts) = @_;

  ##-- define the expat parser (we need $doc as a local callback!)
  my $alabel = $anl->{label};
  my ($_xp,$_elt,%_attrs);
  my (%id2t,%id2n,@stack);

  ## undef = cb_start($expat,$elt,%attrs)
  my ($w,$a,$starti,$endi, $si,$wi,$sid,$wid);
  my $cb_start = sub {
    ($_xp,$_elt,%_attrs) = @_;

    if ($_elt eq 'terminal') {
      if (defined($_attrs{offset}) && defined($_attrs{'token-pos'})) {
	##-- new (>=2012-08-22)
	($si,$wi,$sid,$wid) = split(/ /,$_attrs{offset},4);
      } elsif (defined($_attrs{line}) && defined($_attrs{pos})) {
	##-- old (<2012-08-22)
	($si,$wi) = @_attrs{qw(line pos)};
      } else {
	$anl->logconfess("spliceback(): could not parse terminal attributes for ", $_xp->original_string())
      }
      $w = $doc->{body}[$si]{tokens}[$wi];
      $w->{$alabel} = $id2t{$_attrs{id}} = [ $a = { nid=>$_attrs{id} } ];
      push(@stack,$a);
    }
    elsif ($_elt eq 'nonterminal') {
      $a = $id2n{$_attrs{id}} = { nid=>$_attrs{id}, start=>$_attrs{start}, end=>$_attrs{end}, depth=>$_attrs{depth} };
      $starti = ($a->{start}=~/^T([0-9]+)$/ ? $1 : undef);
      $endi   = ($a->{end}  =~/^T([0-9]+)$/ ? $1 : undef);
      foreach (grep {defined($_)} @id2t{defined($starti) && defined($endi) ? (map {"T$_"} ($starti..$endi)) : qw()}) {
	push(@$_, $a);
      }
      push(@stack,$a);
    }
    elsif ($_elt =~ /^category(?:\-(?:open|close))?$/) {
      $a->{cat} = $_attrs{name};
    }
    elsif ($_elt eq 'function') {
      $a->{func} = $_attrs{name};
    }
    elsif ($_elt eq 'label') {
      @$a{qw(labid label)} = @_attrs{qw(id name)};
      $a->{label} = "#$a->{label}" if ($a->{label} !~ /^\#/);
    }
  };

  ## undef = cb_end($expat,$elt)
  my $cb_end = sub {
    pop(@stack) if ($_[1] eq 'terminal' || $_[1] eq 'nonterminal');
    $a = $stack[$#stack];
  };

  ## undef = cb_init($expat)
  my $cb_init = sub {
    @stack = %id2t = %id2n = %_attrs = qw();
    $_elt = $_xp = $w = $a = $starti = $endi = undef;
  };

  ## undef = cb_final($expat)
  my $cb_final = sub {
    @stack = %id2t = %id2n = %_attrs = qw();
    $_elt = $_xp = $w = $a = $starti = $endi = undef;
  };

  ##-- parser
  my $xp = XML::Parser->new(
			    ErrorContext => 1,
			    ProtocolEncoding => 'UTF-8',
			    Handlers => {
					 Init  => $cb_init,
					 Start => $cb_start,
					 End   => $cb_end,
					 Final => $cb_final,
					},
			   )
    or $anl->logconfess("spliceback(): could not create XML::Parser");
  $xp->parse(ref($rsp) ? $$rsp : $rsp);

  return $doc;
}


1; ##-- be happy

__END__
