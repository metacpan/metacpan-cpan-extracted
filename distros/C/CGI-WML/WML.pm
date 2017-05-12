package CGI::WML;

use vars qw($VERSION $RCSVERSION @ISA @EXPORT @EXPORT_OK $USEXMLPARSER
            %WBML_TAGS %WBML_ATTRS %WBML_VALUES %WBML_NO_CLOSE_TAGS
            $AUTOLOAD @ISA @EXPORT @EXPORT_OK);

$USEXMLPARSER=1;

use HTML::TokeParser;
use HTML::TableExtract;
use IO::Handle;
use IO::File;
use Carp;
require Exporter;

# Big fat manual import list, since the 'header' routine is in the :cgi pack,
# but we define our own, and we have to avoid the 'sub foo redefined..' warning
# We also take care just to import WML-ok routines.

use CGI qw(:internal :ssl param upload path_info path_translated url self_url
  	   script_name cookie raw_cookie request_method query_string Accept
  	   user_agent remote_host content_type remote_addr referer server_name
  	   server_software server_port server_protocol protocol virtual_host
  	   remote_ident auth_type http save_parameters restore_parameters
  	   param_fetch remote_user user_name redirect import_names put delete
	   delete_all url_param cgi_error escapeHTML charset cache);

use CGI::Util qw(rearrange make_attributes unescape escape expires);

if ($USEXMLPARSER) {
    require XML::Parser;
    import XML::Parser;
}

@ISA = qw(Exporter CGI CGI::Util);  # Inherit from CGI.pm

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();

$VERSION = "0.09";
$RCSVERSION = do{my@r=q$Revision: 1.67 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

my $DEFAULT_DTD     = '-//WAPFORUM//DTD WML 1.1//EN';
my $DEFAULT_DTD_URL = 'http://www.wapforum.org/DTD/wml_1.1.xml';

my $DOTABLE = 1; # Whether to use string tables.
my ($WBML_RETBUFF,%TEMP_STRTAB,%STRTAB);

# Wireless Binary Markup Language, as defined in WAP forum docs
my $WBML_INLINE_STRING     = 0x03;
my $WBML_INLINE_STRING_END = 0x00;
my $WBML_STRINGTABLE_REF   = 0x83;
my $WMLTC_ATTRIBUTES       = 0x80;
my $WMLTC_CONTENT          = 0x40;
my $WMLTC_END              = 0x01;
 
%WBML_TAGS = (      # dec      # hex 
        'pre'       => '27',     # 0x1B
        'a'         => '28',     # 0x1C 
        'td'        => '29',     # 0x1D 
        'tr'        => '30',     # 0x1E 
        'Tr'        => '30',     # 0x1E
        'table'     => '31',     # 0x1F
        'p'         => '32',     # 0x20
        'postfield' => '33',     # 0x21
        'anchor'    => '34',     # 0x22
        'access'    => '35',     # 0x23
        'b'         => '36',     # 0x24
        'big'       => '37',     # 0x25
        'br'        => '38',     # 0x26
        'card'      => '39',     # 0x27
        'do'        => '40',     # 0x28
        'em'        => '41',     # 0x29
        'fieldset'  => '42',     # 0x2A
        'go'        => '43',     # 0x2B
        'head'      => '44',     # 0x2C
        'i'         => '45',     # 0x2D
        'img'       => '46',     # 0x2E
        'input'     => '47',     # 0x2F
        'meta'      => '48',     # 0x30
        'noop'      => '49',     # 0x31
        'prev'      => '50',     # 0x32
        'onevent'   => '51',     # 0x33
        'optgroup'  => '52',     # 0x34
        'option'    => '53',     # 0x35
        'refresh'   => '54',     # 0x36
        'select'    => '55',     # 0x37
        'small'     => '56',     # 0x38
        'strong'    => '57',     # 0x39
        'UNUSED'    => '58',     # 0x3A
        'template'  => '59',     # 0x3B
        'timer'     => '60',     # 0x3C
        'u'         => '61',     # 0x3D
        'setvar'    => '62',     # 0x3E
        'wml'       => '63',     # 0x3F
             );

%WBML_ATTRS = (              # dec           # hex
        'accept-charset'    => '05',         # 0x05
        'align="bottom"'    => '06',         # 0x06
        'align="center"'    => '07',         # 0x07
        'align="left"'      => '08',         # 0x08
        'align="middle"'    => '09',         # 0x09
        'align="right"'     => '10',         # 0x0A
        'align="top"'       => '11',         # 0x0B
        'alt'               => '12',         # 0x0C
        'content'           => '13',         # 0x0D
        'NULL,'             => '14',         # 0x0E
        'domain'            => '15',         # 0x0F
        'emptyok="false"'   => '16',         # 0x10
        'emptyok="true"'    => '17',         # 0x11
        'format'            => '18',         # 0x12
        'height'            => '19',         # 0x13
        'hspace'            => '20',         # 0x14
        'ivalue'            => '21',         # 0x15
        'iname'             => '22',         # 0x16
        'NULL,'             => '23',         # 0x17
        'label'             => '24',         # 0x18
        'localsrc'          => '25',         # 0x19
        'maxlength'         => '26',         # 0x1A
        'method="get"'      => '27',         # 0x1B
        'method="post"'     => '28',         # 0x1C
        'mode="nowrap"'     => '29',         # 0x1D
        'mode="wrap"'       => '30',         # 0x1E
        'multiple="false"'  => '31',         # 0x1F
        'multiple="true"'   => '32',         # 0x20
        'name'              => '33',         # 0x21
        'newcontext="false"' => '34',        # 0x22
        'newcontext="true"'  => '35',        # 0x23
        'onpick'            => '36',         # 0x24
        'onenterbackward'   => '37',         # 0x25
        'onenterforward'    => '38',         # 0x26
        'ontimer'           => '39',         # 0x27
        'optional="false"'  => '40',         # 0x28
        'optional="true"'   => '41',         # 0x29
        'path'              => '42',         # 0x2A
        'NULL,'             => '43',         # 0x2B
        'NULL,'             => '44',         # 0x2C
        'NULL,'             => '45',         # 0x2D
        'scheme'            => '46',         # 0x2E
        'sendreferer="false"' => '47',       # 0x2F
        'sendreferer="true"'  => '48',       # 0x30
        'size'              => '49',         # 0x31
        'src'               => '50',         # 0x32
        'ordered="true"'    => '51',         # 0x33
        'ordered="false"'   => '52',         # 0x34
        'tabindex'          => '53',         # 0x35
        'title'             => '54',         # 0x36
        'type'              => '55',         # 0x37
        'type="accept"'     => '56',         # 0x38
        'type="delete"'     => '57',         # 0x39
        'type="help"'       => '58',         # 0x3A
        'type="password"'   => '59',         # 0x3B
        'type="onpick"'     => '60',         # 0x3C
        'type="onenterbackward"' => '61',    # 0x3D
        'type="onenterforward"'  => '62',    # 0x3E
        'type="ontimer"'    => '63',         # 0x3F
        'NULL,'             => '64',         # 0x40
        'NULL,'             => '65',         # 0x41
        'NULL,'             => '66',         # 0x42
        'NULL,'             => '67',         # 0x43
        'NULL,'             => '68',         # 0x44
        'NULL,'             => '69',         # 0x45
        'type="prev"'       => '70',         # 0x46
        'type="reset"'      => '71',         # 0x47
        'type="text"'       => '72',         # 0x48
        'type="vnd."'       => '73',         # 0x49
        'href'              => '74',         # 0x4A
        'href="http://'     => '75',         # 0x4B
        'href="https://'    => '76',         # 0x4C
        'value'             => '77',         # 0x4D
        'vspace'            => '78',         # 0x4E
        'width'             => '79',         # 0x4F
        'xml:lang'          => '80',         # 0x50
        'NULL,'             => '81',         # 0x51
        'align'             => '82',         # 0x52
        'columns'           => '83',         # 0x53
        'class'             => '84',         # 0x54
        'id'                => '85',         # 0x55
        'forua="false"'     => '86',         # 0x56
        'forua="true"'      => '87',         # 0x57
        'src="http://'      => '88',         # 0x58
        'src="https://'     => '89',         # 0x59
        'http-equiv'        => '90',         # 0x5A
        'http-equiv="Content-Type"' => '91',                   # 0x5B
        'content="application/vnd.wap.wmlc;charset=' => '92',  # 0x5C
        'http-equiv="Expires"' => '93',                        # 0x5D
        'accesskey'         => '94',                           # 0x5E 
        'enctype'           => '95',                           # 0x5F
        'enctype="application/x-www-from-urlencoded"' => '96', # 0x60
        'enctype="multipart/form-data"'               => '97', # 0x61
      );

%WBML_VALUES = (      # dec              # hex
        '.com/'     => '133',            # 0x85 
        '.edu/'     => '134',            # 0x86
        '.net/'     => '135',            # 0x87 
        '.org/'     => '136',            # 0x88
        'accept'    => '137',            # 0x89
        'bottom'    => '138',            # 0x8A
        'clear'     => '139',            # 0x8B
        'delete'    => '140',            # 0x8C
        'help'      => '141',            # 0x8D
        'http://'   => '142',            # 0x8E
        'http://www.'  => '143',         # 0x8F
        'https://'     => '144',         # 0x90
        'https://www.' => '145',         # 0x91
        'NULL'      => '146',            # 0x92
        'middle'    => '147',            # 0x93
        'nowrap'    => '148',            # 0x94
        'onpick'    => '149',            # 0x95
        'onenterbackward' => '150',      # 0x96
        'onenterforward'  => '151',      # 0x97
        'ontimer'   => '152',            # 0x98
        'options'   => '153',            # 0x99
        'password'  => '154',            # 0x9A
        'reset'     => '155',            # 0x9B
        'NULL'      => '156',            # 0x9C
        'text'      => '157',            # 0x9D
        'top'       => '158',            # 0x9E
        'unknown'   => '159',            # 0x9F
        'wrap'      => '160',            # 0xA0
        'www.'      => '161');           # 0xA1

%WBML_NO_CLOSE_TAGS = (              
        'br'     => '1',                 
        'go'     => '1',                 
        'input'  => '1',                 
        'noop'   => '1',                 
        'prev'   => '1',                 
        'img'    => '1',                 
        'meta'   => '1',                 
        'timer'  => '1',                 
        'setvar' => '1');

# HTML->WML conversion constants
# Ignore these HTML and iMode tags completely.
my %IGNORE_TAG = map {$_ => 1} qw(abbr acronym address applet area basefont
				  bdo body cite col colgroup del dfn dir div
				  dl dt fieldsset font frame frameset head
				  html iframe legend link noframes noscript 
				  object param script span style textarea
				  tfoot thead var);

# Straightforward one to one tag mapping
my %TAGMAP = map {$_ => 1} qw(em strong i b u big small pre tr td); 

my (%Open_Tags,@Open_Tables,$Open_Form_Url,
    @Open_Vars,%Hidden_Vars,$F_Got_Body_Tag);

### 
##  End of global variable setting. 
###

### Method: header
# Override the CGI.pm header default with the WML one.
# Contributed by Wilbert Smits <wilbert@telegraafnet.nl>
###
sub header {
    local($^W)=0;
    my($self,@p) = &CGI::self_or_default(@_);
    my($type, @leftover) = rearrange([TYPE],@p);
    my %leftover;
    foreach (@leftover) {
        next unless my($header,$value) = /([^\s=]+)=\"?([^\"]+)\"?/;
        $leftover{$header} = $value;
    }
    if(!defined $type) {$type = "text/vnd.wap.wml"}
    return $self->SUPER::header("-type"=>$type, %leftover);
}

### Method: start_wml
# Guess what this does!
###
sub start_wml {
    my($self,@p) = &CGI::self_or_default(@_);
    my($meta,$dtd,$dtd_url,$lang,$encoding) =
	rearrange([META,DTD,DTD_URL,LANG,ENCODING],@p);
    
    if (!defined $encoding) { $encoding="iso-8859-1";}
    
    my(@result);
    push @result,qq(<?xml version="1.0" encoding="$encoding"?>);
    $dtd = $DEFAULT_DTD unless $dtd && $dtd =~ m|^-//|;
    $dtd_url = $DEFAULT_DTD_URL unless $dtd_url && $dtd_url =~ m|^http|;
    push(@result,qq(\n<!DOCTYPE wml PUBLIC "$dtd" 
	            "$dtd_url">\n)) if $dtd && $dtd_url;

    push(@result,qq(<wml));
    push(@result,qq(xml:lang="$lang")) if (defined $lang);
    push(@result,">");

    if (defined $meta) {
        push(@result,"<head>");
        if ($meta && ref($meta) && (ref($meta) eq 'HASH')) {
            foreach (keys %$meta) {
                push(@result,qq(<meta $_ $meta->{$_}/>\n));
            }
        }
        push(@result,"</head>");
    }

    return join(" ",@result);
}

### Method: card
# make a complete WML card
####
sub card {
    my ($self,@p) = &CGI::self_or_default(@_);
    my ($id,$title,$content,$ontimer,$timer,$onenterforward,$onenterbackward,
	$newcontext,$ordered,$class,$lang) =
        rearrange([ID,TITLE,CONTENT,ONTIMER,TIMER,ONENTERFORWARD,ONENTERBACKWARD,NEWCONTEXT,ORDERED,CLASS,LANG],@p);
    
    my @ret;
 
    push(@ret,qq(\n<card id="$id"));
    push(@ret,qq(title="$title")) if (defined $title);
    push(@ret,qq(newcontext="$newcontext")) if (defined $newcontext);
    push(@ret,qq(ontimer="$ontimer")) if (defined $ontimer);
    push(@ret,qq(onenterforward="$onenterforward"))if(defined $onenterforward);
    push(@ret,qq(onenterbackward="$onenterbackward"))if(defined $onenterbackward);
    push(@ret,qq(xml:lang="$lang")) if (defined $lang);
    push(@ret,qq(ordered="$ordered")) if (defined $ordered);
    push(@ret,qq(class="$class")) if (defined $class);

    push(@ret,qq(>));
    push(@ret,qq($timer)) if (defined $timer);
    push(@ret,qq( $content </card>)) if (defined $content);

    return join (" ",@ret);
}

### Method: dialtag
# make a 'call this number' tag
####
sub dialtag {
    my ($self,@p) = @_;
    my ($number,$label) = rearrange([NUMBER,LABEL],@p);
    
    $label = $number unless (defined $label);
    my $ret = "<anchor>$label<go href='wtai://wp/mc/;$number'/></anchor>";
    return $ret;
}

### Method: do
# make a 'do' tag
####
sub do {
    # Oh no! Geoworks patent infringment ahead!
    my ($self,@p) = @_;
    my ($type,$class,$label,$name,$content,$optional) = 
	rearrange([TYPE,CLASS,LABEL,NAME,CONTENT,OPTIONAL],@p);

    my @ret;
    push(@ret,qq(<do type="$type"));
    push(@ret,qq(optional="$optional")) if (defined $optional);
    push(@ret,qq(name="$name")) if (defined $name);
    push(@ret,qq(class="$class")) if (defined $class);
    push(@ret,qq(label="$label")) if (defined $label);
    push(@ret,qq(>$content</do>));

    return join(" ",@ret);
}
    
### Method: template
# make a 'template' card for a deck
####
sub template {
    my ($self,@p) = @_;
    my ($content) = rearrange([CONTENT],@p);
    
    my @ret;
    push(@ret,qq(<template>$content</template>));

    return join(" ",@ret);
}

### Method: go
# Make a 'go' block
###
sub go {
    my ($self,@p) = @_;
    my ($method,$href,$postfields) = rearrange([METHOD,HREF,POSTFIELDS],@p);

    my @ret;
    
    push(@ret,qq(<go href="$href"));
    push(@ret,qq(method="$method")) if (defined $method);
    
    if (defined $postfields) {
      if ($postfields && ref($postfields) && (ref($postfields) eq 'HASH')) {
          push(@ret,">");
          foreach (keys %$postfields) {
              push(@ret,qq(<postfield name="$_" value="$postfields->{$_}"/>));
          }
      }
      push(@ret,"</go>");
    } else {
      push(@ret,"/>");
    }
   
    return join(" ",@ret);
}

### Method: prev
# Canned "back" method
###
sub prev {
    my ($self,@p) = @_;
    my ($label) = rearrange([LABEL],@p);

    my $ret = qq(<do type="accept" label="Back"><prev/></do>);
    $ret =~ s/Back/$label/ if (defined $label);
    
    return $ret;
}

sub back {
   &prev;
}

### Method: timer
# Make a WML timer element
####
sub timer {
    my ($self,@p) = @_;
    my ($name,$value) = rearrange([NAME,VALUE],@p);
    
    return qq(<timer name="$name" value="$value"/>);
}

#### Method: end_wml
# End an WML document.
# Trivial method for completeness.  Just returns "</wml>"
####
sub end_wml {
    return "</wml>\n";
}

# AJM Added a new line to terminate the file
#### Method: input
# Make a text-entry box.
####

sub input {
    my ($self,@p) = @_;
    my ($name,$value,$type,$format,$title,$size,$maxlength,$emptyok) =
     rearrange([NAME,VALUE,TYPE,FORMAT,TITLE,SIZE,MAXLENGTH,EMPTYOK],@p);
    
 
    my @ret;
    push(@ret,qq(<input name="$name"));
    push(@ret,qq(value="$value")) if (defined $value);
    push(@ret,qq(type="$type")) if (defined $type);
    push(@ret,qq(format="$format")) if (defined $format);
    push(@ret,qq(title="$title")) if (defined $title);
    push(@ret,qq(size="$size")) if (defined $size);
    push(@ret,qq(emptyok="$emptyok")) if (defined $emptyok);
    push(@ret,qq(maxlength="$maxlength")) if (defined $maxlength);
    push(@ret,qq(/>));

    return join(" ",@ret);
}

#### Method: onevent
# Make an "onevent" block
####

sub onevent {
    my ($self,@p) = @_;
    my ($type,$content) = rearrange([TYPE,CONTENT],@p);

    return qq(<onevent type="$type">$content</onevent>);
}

### Method: img
# make an image tag
####
sub img {
    my ($self,@p) = @_;
    my ($alt, $src, $localsrc, $vspace, $hspace, $align, $height, $width) =
        rearrange([ALT, SRC, LOCALSRC, VSPACE, HSPACE, ALIGN, HEIGHT, WIDTH],@p);
    my @ret;
    $alt = "image" if (! defined $alt); # alt text is manditory in WML

    push (@ret,qq(<img));
    push (@ret,qq(alt="$alt"))           if (defined $alt);
    push (@ret,qq(src="$src"))           if (defined $src);
    push (@ret,qq(localsrc="$localsrc")) if (defined $localsrc);
    push (@ret,qq(vspace="$vspace"))     if (defined $vspace);
    push (@ret,qq(hspace="$hspace"))     if (defined $hspace);
    push (@ret,qq(align="$align"))       if (defined $align);
    push (@ret,qq(height="$height"))     if (defined $height);
    push (@ret,qq(width="$width"))       if (defined $width);
    push (@ret,qq( />));
    return join(" ",@ret);
}

sub p {
    my ($self, @p) = @_;

    my ($content, $align, $mode) = rearrange([CONTENT, ALIGN, MODE], @p);
    my @ret;

    push ( @ret, qq(<p));
    push ( @ret, qq(align="$align")) if $align;
    push ( @ret, qq(mode="$mode"))   if $mode;    
    push ( @ret, qq(>$content</p>));
    return join (" ", @ret);  
} 

#### Method: wml_to_wmlc
# Convert textal WML to binary WML, not indented to replace the WML
# compiler on the gateway.
####

sub wml_to_wmlc {

    my ($streamheader,$wbml,$parser,$testparser,$stringtable);
    my ($self,@p) = @_;
    my ($wml,$errorcontext) = rearrange([WML,ERRORCONTEXT],@p);
 
    if ($USEXMLPARSER == 0) {
        croak("Error: Routine disabled at installation.");
        return undef;
    }
    
    (defined $errorcontext) || ($errorcontext = 0);
    $parser = new XML::Parser(ErrorContext=>$errorcontext);

    $stringtable = build_string_table($parser,$wml);
    
    $WBML_RETBUFF = sprintf("%c%c%c%c%s",
			    0x01,   # "WBXML 1"
			    0x04,   # "WML 1.1"
			    0x6A,   # Charset (UTF-8) XXX make this an option
			    length($stringtable), # Number of bytes in table
			    $stringtable);

    $parser->setHandlers(Start=>\&wml_start,
                         End=>\&wml_end,
                         Char=>\&wml_char,
                         Final=>\&wml_final);

    # This is a bit merciless, but it really improves the
    # string table performance.
    $wml =~ s/\r//g;
    $wml =~ s/\n//g;
    $wml =~ s/\s+\>/\>/g;
    $wml =~ s/\s+\</\</g;

    $testparser = eval '$parser->parse($wml); return 1';
    
    if (!defined $testparser) {
        warn ("Error: XML parser failed. Bad WML ?\n");
        if ($errorcontext) {
            # This is going to throw a die(), since we know the
            # document is not well formed.
            $parser->parse($wml);
        }
        return undef;
    } else {
        return $WBML_RETBUFF;
    }
}

###
# Non-public function, used by wml_to_wmlc.
# Does the job of returning the buffer of WBML to the calling routine.
###
sub wml_final {
    return $WBML_RETBUFF;
}

### 
# Non-public function, used by wml_to_wmlc
# Called by start of tag XML event, encodes tag and property/value pairs
###
sub wml_start {
    
    my ($parser,$element,@props) = @_;
    my ($tok,$prop,$val,$propandval,$count);
    
    # Get the element token, and say wether it has contents and/or 
    # attributes. 
    $tok = $WBML_TAGS{$element};
    if (! defined($WBML_NO_CLOSE_TAGS{$element})) { 
        $tok |= $WMLTC_CONTENT;
    }
        
    if (scalar(@props) > 0) { $tok |= $WMLTC_ATTRIBUTES;}

    $WBML_RETBUFF .= chr($tok);
    
    for ($count = 0 ; $count < scalar(@props); $count++) {
        $prop = $props[$count];
        $val = $props[++$count];
        $propandval = $prop."=\"".$val."\"";
        $propandval =~ s/\ //g;
	
	# Look for a single attib val first, and if not, break it in
	# to parts and tokenise them.
	
        if ($WBML_ATTRS{$propandval}) { # We got a single value

            $WBML_RETBUFF .= chr($WBML_ATTRS{$propandval});
	    
        }else{  # Break it up and encode the parts
	    
            $WBML_RETBUFF .= chr($WBML_ATTRS{$prop});
	    
            if ($WBML_VALUES{$val}) {
                $WBML_RETBUFF .= chr($WBML_VALUES{$val});
            }else{
                #if ($prop =~ /href/){ # Special case for URLS
                #    if ($val =~ /^http\:\/\//) {
                #	accum(pack('c',chr($WBML_VALUES{"http://"})));
                #	$val =~ s%^http://%%g;
                #    }
                #}
                if ($WBML_VALUES{$val}) {
                    $WBML_RETBUFF .= chr($WBML_VALUES{$val});
                } else {
                    if (defined $STRTAB{$val}) {
                        $WBML_RETBUFF .= pack('CC',
					    $WBML_STRINGTABLE_REF,
					    $STRTAB{$val});
                    } else {
                        $WBML_RETBUFF .= chr($WBML_INLINE_STRING);
                        $WBML_RETBUFF .= $val;
                        $WBML_RETBUFF .= chr($WBML_INLINE_STRING_END);
                    }
                }
            }
        }
    }
    
    if ($count) {
        # If there was an attribute list, we've got to mark it's 
        # end. Is there a better way of doing this? an Expat option perhaps?
        $WBML_RETBUFF .= chr($WMLTC_END);
    }
}

### 
# Non-public function, used by wml_to_wmlc
# Called by XML parser when an end-of-tag tag is hit.
###
sub wml_end {
    # Just return 0x01, unless it's in the "no closures" hash
    my ($parser,$tag) = @_;
    if (! defined($WBML_NO_CLOSE_TAGS{$tag})) {
        $WBML_RETBUFF .= chr($WMLTC_END);
    }
}    

### 
# Non-public function, used by wml_to_wmlc 
# Called by XML parser to encode strings within tags
###
sub wml_char {
    my $parser = shift;
    my $charstr = shift;
    my ($char,$buff,$f_white,$word);
    
    $char = $buff = "";
    $f_white = 0;
    
    # Strip out whitespace.
    $charstr =~ s/\s+/ /g;

    # If it's in the string table, then take it from there, else
    # add it in as an inline string.
    if  ($charstr !~ /^\s$/) { 
        if ($DOTABLE) {
            if (defined $STRTAB{$charstr}) {
                $WBML_RETBUFF .= chr($WBML_STRINGTABLE_REF) .
                                 chr($STRTAB{$charstr});
            } else {
                $WBML_RETBUFF .= chr($WBML_INLINE_STRING) .
                                 $charstr .
                                 chr($WBML_INLINE_STRING_END);
            }
        } else {
            $WBML_RETBUFF .= chr($WBML_INLINE_STRING) .
                             $charstr .
                             chr($WBML_INLINE_STRING_END);
        }
    }
}

########
## String table routines
########
    
sub build_string_table {
    
    # Set up the XML parser to make a pass through the 
    # document whipping out all the strings.
    
    my $parser = shift;
    my $doc  = shift;
    
    $parser->setHandlers(Start=>\&accum_string_table,
                         Char=>\&accum_string_table,
                         Final=>\&accum_string_final);
    $parser->parse($doc);
 
    # Note! No 'return()', accum_string_final bounces past this
    # to the caller. Yuk, I know.
}

sub accum_string_table {
    
    # Bash the strings down, and put them in a hash

    my $parser = shift;
    my $charstr = shift;
    my @props = @_;

    my ($char,$buff,$word,$count);

    # Compress and trim whitespace
    $charstr =~ s/\s+/ /g;
    $charstr =~ s/^\s+//g;
    $charstr =~ s/\s+$//g;

    return if ($charstr =~ /^\s$/);

    for ($count = 1 ; $count < scalar(@props); $count+=2) {
        $charstr =~ s/\s+/ /g;
        $TEMP_STRTAB{$props[$count]}++;
    }

    return if (defined $WBML_TAGS{$charstr});

    $TEMP_STRTAB{$charstr}++;
}

sub accum_string_final {
    
    # Build the string table, and the token stream header.
    my ($word,$occurances,$count,$stringtable,%temptable);

    $stringtable = ""; # Stop "use of uninitialized value..."
    $count = 0;

    # Only use stringtable where there is a saving, i.e. the string
    # is used 2 or more times in the code, and it's over two chars,
    # since that is the length of a stringtable reference anyway.

    while (($word,$occurances) = each %TEMP_STRTAB) {
       if ( ($occurances >= 2) && (length($word) > 2) ) {
           $STRTAB{$word} = 1;
       }
    }

    while (($word,$occurances) = each %STRTAB) {
        $STRTAB{$word} = length($stringtable); # For index purposes.
        $stringtable .= $word . chr(0x00);
        $count++;
    }
    
    # Horror. This is the last return, so the wml_to_wmlc() function gets
    # this value even though it was not called from there, but even
    # so I'll have to work out a better way of getting it back.
    return $stringtable;
}

###
# HTML to WML conversion, not particularly good conversion though. YMMV
#
# Inspired by Taneli Leppa's "html2wml" distributed with the
# Kannel Open Source WAP gateway.
###

sub html_to_wml {

    my ($self,@p) = @_;
    my ($arg,$redirect_via,$redirect_var,$breaks_after_links) = rearrange([HTML,URL,VARNAME,LINKBREAKS],@p);

    my ($parser,$title,$content,$ioref,$filename,$tmpfile);
    $filename = "";

    return undef unless (defined $arg);

    ($redirect_via = "0") if (!defined $redirect_via);
    ($redirect_var = "0") if (!defined $redirect_var);
    ($breaks_after_links = "0") if (!defined $breaks_after_links);

    if (ref($arg) and UNIVERSAL::isa($arg, 'IO::Handler')) {
        # We've got a filehandle.
        $ioref = $arg;
    } else {
        eval {
            $ioref = *{$arg}{IO};
        };
    }

    if (! defined $ioref ) {
        # We've got a scalar, put it in a tempfile.
	
        # Whipped from CGI.pm.

        # choose a relatively unpredictable tmpfile sequence number
        my $seqno = unpack("%16C*",join('',localtime,values %ENV));

        for (my $cnt=10;$cnt>0;$cnt--) {
            next unless $tmpfile = new CGITempFile($seqno);
            $filename = $tmpfile->as_string;

            last if defined ($ioref = new IO::File "> $filename");
            $ioref->autoflush(1);
	    
            $seqno += int rand(100);
        }

        croak("Can't get a tempfile") unless (defined $ioref);

        print $ioref $arg || croak ($!);
        $ioref->close;
	
        open($ioref,$filename) || croak ($!);
	html_to_wml_gettables($ioref);
	$ioref->close;

	open($ioref,$filename) || croak ($!);
    }

    #html_to_wml_gettables($ioref);

    $parser = HTML::TokeParser->new($ioref);

   
    $parser->get_tag("title");
    $title = $parser->get_text;
    $content  = html_to_wml_getcontent($self,$parser,$redirect_via,
                                       $redirect_var,$breaks_after_links);
    (-e $filename) && (unlink($filename) || warn("Couldn't unlink $filename"));
    return ($title,$content);
}

###
# Non-public function, used by 'html_to_wml' routine
# Extract tables in document on to global so we can reformat them
# properly.
###
sub html_to_wml_gettables{

    my $ioref = shift;
    undef @Open_Tables;
    my ($te,$table,$row,$cellcontent,$tmp); 
    
    $te = new HTML::TableExtract();
    $te->parse_file($ioref);


    foreach $table ($te->table_states) {
        $tmp = sprintf("<table columns='%d'>", (scalar $table->rows));
	push @Open_Tables,$tmp;
    }
}

### 
# Non-public function, used by 'html_to_wml' routine, extracts 
# text and does limited tag conversion.
###
sub html_to_wml_getcontent {
    
    my $self = shift;
    my $p = shift;
    my $redirect_via = shift;
    my $redirect_var = shift;
    my $breaks_after_links = shift;
    my ($wml,$wmlbit,$token,$tag);
    
    $F_Got_Body_Tag = 0;
    while ($token = $p->get_token) {
	if ($token->[1]) {
	    $_ = $token->[0];
	  TAGTYPE: {
	      /S/ && do { $wmlbit = _start_tag($self,$p,$token->[1],
					       $token->[2],
					       $redirect_via,
					       $redirect_var,
					       $breaks_after_links);
			  last TAGTYPE;
		      };
	      /E/ && do { $wmlbit = _end_tag($token->[1]);
			  last TAGTYPE;
		      };
	      /T/ && do { $wmlbit = $token->[1];
			  $wmlbit =~ s/\&copy\;/\(c\)/g;
			  chomp $wmlbit;
			  last TAGTYPE;
		      };
	  }  
	}
	#print STDERR "\n\tXX $wmlbit\n";
        $wml .= $wmlbit if $wmlbit;
    }
    
    foreach $tag (%Open_Tags) {
        if ( (defined $Open_Tags{$tag}) && ($Open_Tags{$tag} >= 1)) {
            $wml .="</$tag>";
        }
    }

    # In case we got plain text...
    if ($F_Got_Body_Tag == 1) {
	$wml .= "</p>";
    }
    
    return $wml;
}

### 
# Non-public function, used by 'html_to_wml' routine
###
sub _start_tag {
    my $self = shift;
    my $p = shift;
    my $tag = shift;
    my $attrs = shift;
    my $redirect_via = shift;
    my $redirect_var = shift;
    my $breaks_after_links = shift;
   
    if ($breaks_after_links) {
        $breaks_after_links = "<br/>\n";
    }else{
        $breaks_after_links = " ";
    }

    my ($y,$x,$type,$varname,%pfs);


    # We have to check for duplicate "<body>" tags.
    if (lc($tag) eq 'body') {
	    if ($F_Got_Body_Tag == 0) {
	        $F_Got_Body_Tag = 1;
	        return "<p>";

	    }
        else {
	        return "";
	    }
    }

    return if $IGNORE_TAG{$tag};
    
    if ($TAGMAP{$tag}) {
        if ( (defined $Open_Tags{$tag}) && ($Open_Tags{$tag} > 1)) {
	        $Open_Tags{$tag}++;
	        return lc("</$tag><$tag>");
        }else{
	        $Open_Tags{$tag}++;
	        return lc("<$tag>");
        }
    }
    
    for ($tag) {
	
	# Tag-to-tag mapping.

        /^a$/ && do {
            if (!defined $attrs->{'href'}) {
                # <a name='foo> probably
                return "";
            }
            $y = $attrs->{'href'};
	    $y =~ s%&%&amp;%g;

            if ($y !~ /^http/) {
                $y = "_URIBASE_" . $y;
            }

            if (defined $redirect_via) {
                 $y = qq($redirect_via?$redirect_var=$y);
            }
            return sprintf("<a href='%s' %s>%s",
                           $y,
                           ( (defined $attrs->{'accesskey'} ? 
                             "accesskey = '" . $attrs->{'accesskey'} . "'" :
                             "")),
                           $breaks_after_links);
        };
        
        /^img$/ && do {
            $y = $attrs->{'src'};
            $x = $attrs->{'alt'};
            $x = "image" unless $x;
            
            return "<$tag src='$y' alt='$x'/>";
	};
	
	/^hr$/ && do {
	    return "<br/>------<br/>";
	};
	
	/^dd$/ && do {
	    return "<br/>";
	};
	
	/^dl/ && do {
	    return "<br/>";
	};
	    

	/^form$/ && do {
	    $Open_Form_Url = $attrs->{'action'};
	    return "";
	};

	/^select$/ && do {
	    push @Open_Vars, $attrs->{'name'};
	    return sprintf("<select name='%s'>",$attrs->{'name'});
	};

	/^option$/ && do {
	    return
		sprintf ("<option value='%s'>%s</option>",
			 $attrs->{'value'},
			 $p->get_text);
	};

	/^table$/ && do {
	    # Becase of the requirement in WML for the <table> tag to
            # contain the column count <table columns='4'> we have
            # previous to this routine in html_to_wml_gettables()
            # made an array of the table tags in the order they appear
            # in the document. We return the first one in the array and
            # shorten the array.
	    $y = shift @Open_Tables;
	    return $y;
	};

	/^input$/ && do {

	    # Transforming input tags isn't much fun.
	    $type = lc($attrs->{'type'});

	    ($type eq "hidden") && do {
		$Hidden_Vars{$attrs->{'name'}} = $attrs->{'value'};
	    };

	    ($type eq "text") && do {
		push @Open_Vars, $attrs->{'name'};
		return $self->input(-name=>$attrs->{'name'},
				    -value=>$attrs->{'value'},
				    -size=>$attrs->{'size'},
				    -maxlength=>$attrs->{'maxlength'});
	    };

	    ($type eq "submit") && do{
    
                # It's a submit. Collapse all the form bits we've got
                # so far in to a WML 'go'

		my $url = $Open_Form_Url;

		foreach $varname (@Open_Vars) {
		    $pfs{$varname} = "\$($varname:e)";
		}
		foreach $varname (keys %Hidden_Vars) {
		    $pfs{$varname} = $Hidden_Vars{$varname};
		}

		undef @Open_Vars;

		return $self->do(-type=>"accept",
				 -label=>($attrs->{'value'} || "Send"),
				 -content=>$self->go(-method=>"post",
						     -href=>$Open_Form_Url,
						     -postfields=>\%pfs));
	    };
	};
    }
}

### 
# Non-public function, used by 'html_to_wml' routine
###
sub _end_tag {
    
    my $tag = shift;

    return if $IGNORE_TAG{$tag};

    if ($TAGMAP{$tag}) {
        $Open_Tags{$tag}--;
        return lc("</$tag>");
    }
    
    for ($tag) {
	/^a$/     && return "</a>";     # This block looks a bit silly, but
	/^p$/     && return "<br/>";    # I need it here to have better control
	/^h[0-9]/ && return "<br/>";    # over the tag mapping.
	/^dl$/    && return "<br/>";
	/^li$/    && return "<br/>";
	/^select$/&& return "</select>";
	/^table$/ && return "</table>";
    }
}

# Here is the AUTOLOAD to save some work on making standard tags.  This is 
# inspired by the work done by LDS in CGI.pm.  Here we check to see if the
# AUTOLOAD is a valid WML tag.  If it is we pass it to the private function
# _make_tags.  If it is not a valid WML tag we pass the call to CGI.pm's
# AUTOLOAD method.  So simple I think I am doing something wrong.  I may
# be adding other AUTOLOAD methods here at a later date. 
#
#  Added by AJM 06 July 2000.

sub AUTOLOAD {

    $CGI::AUTOLOAD_DEBUG = 0;
    print STDERR "CGI::WML::AUTOLOAD for $AUTOLOAD\n" if $CGI::AUTOLOAD_DEBUG;
    
    $AUTOLOAD =~ s/.*:://;

    if ($WBML_TAGS{$AUTOLOAD}) {
        _make_tags($AUTOLOAD, @_);
    }
}

# If AUTOLOAD is called for a valid WML tag, this is where it is made.  
# first we clean up the array we are sent to make sure the first element
# is not a ref to an object.  Next we make sure the last element is a real
# value we can work with.  If there is only one element in the array after 
# that we can assume that it is the content for the tag.  If there is an even 
# number of elements in the array then we assume that it is in the form
#
#     attribute_name value attribute_name value
#
# so we pass that to the private function _make_attrib which will give us
# back a hash of the with the attribute_name as the key and the following
# value as the value.  Finally we find out if the tag is an empty tag or
# not and print out the correct mark up for the tag.  The value of
# $attribs{content} is always between the opening and closing tags on
# containter tags, it is never an attribute of a tag.
#
#  Added by AJM 06 July 2000

sub _make_tags {

    my $tag = shift;

    my (%attribs, $ret);

    my @p = @_;

    if (@p) {
        if ( ref($p[0]) ) {
            shift @p;
        }
        unless (defined $p[$#p]){
            pop @p;
        }
    }

    my $pc = @p;

    #  here for debugging only
    #for (my $i = 0; $i < $pc; $i++) { print "p_ref[$i] is \'$p_ref[$i]\'\n"; }

    if (@p) {
        if ($pc == 1) { 
            $attribs{'content'} = $p[0];
        }
        elsif ( ($pc % 2) == 0 ) {
            _make_attrib(\%attribs, \@p)  ;
        }
        else {
            croak("Error: The attribs for $tag has an odd count.");
        }
    }

    if ($WBML_NO_CLOSE_TAGS{$tag} ) {
        $ret = qq (\L<$tag\E);
        foreach (keys %attribs) {
            $ret .= qq (\L$_="$attribs{$_}");
        }
        $ret.= qq( />\n);
            
        return $ret;
    }
    else {

        $ret = qq (\L<$tag\E ) ;
        foreach (keys %attribs) { $ret .= qq (\L$_="$attribs{$_}" )  unless $_ eq 'content'; }
        $ret .= qq (>);
        $ret .= qq($attribs{'content'}) if $attribs{'content'};            
        $ret .= qq(\L</$tag>\E\n);
           
        return $ret;
    }
}

# This is a private function that makes a hash of the attributes for a tag
# that will be AUTOLOADed.  It takes a ref to an array, cleans up the array, 
# then iterates over the array putting the attribute name as the hash key 
# and the attib value as the value of the key.  (kind of a no brainer,
# huh? :-) 
# The hash is passed back and forth by reference.
#
# Added by AJM 06 July 2000.

sub _make_attrib {

    my $attribs_ref = shift;
    my @p_ref = shift;

    my $ac = @$p_ref;

    #  here for debugging only
    #print "ac => $ac \n"; 
    
    if ($attribs_ref) {
        if ( ref(@$p_ref[0]) ) { shift @$p_ref; }
        unless (defined @$p_ref[$#p_ref]){ pop @p_ref; }
    }

    #  here for debugging only
    #for (my $i = 0; $i < $ac; $i++) { print "p_ref[$i] is \'@$p_ref[$i]\'\n"; }

    for (my $i = 0; $i < @$p_ref; $i++) {
        my $j = $i+1;
        if (substr(@$p_ref[$i],0,1) eq '-') {
            @$p_ref[$i] =~ s/^-//;
            $attribs_ref->{@$p_ref[$i]} = @$p_ref[$j];
        } 
    }
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

CGI::WML - Subclass LDS's "CGI.pm" for WML output and WML methods

=head1 SYNOPSIS

  use CGI::WML;

  $query = new CGI::WML;

  $content =  $query->p("Hello WAP world");

  print
     $query->header(),
     $query->start_wml(),
     $query->template(-content=>$query->prev()),
     $query->card(-id=>"first_card",
              -title=>"First card",
              -content=>$content),
     $query->end_wml();

  print
     $query->wml_to_wmlc(-wml=>$wml_buffer,
                         -errorcontext=>2);

  ($page_title,$content) = $query->html_to_wml($buffer);

=head1 DESCRIPTION

This is a library of perl functions to allow CGI.pm-style programming
to be applied to WAP/WML. Since this is a subclass of Lincoln Stein's
CGI.pm all the normal CGI.pm methods are available. See B<perldoc CGI>
if you are not familiar with CGI.pm

The most up to date version of this module is available at
http://cgi-wml.sourceforge.net/

=head1 FUNCTIONS

The library provides an object-oriented method of creating correct WML, 
together with some canned methods for often-used tasks. As this module
is a subclass of CGI.pm, the same argument-passing method is used, and
arguments may be passed in any order.

=head2 CREATING A WML DECK

=over 2

=item B<header()>

This function now overrides the default CGI.pm 'Content-type: ' header
to be 'text/vnd.wap.wml' by default. All the standard CGI.pm header functions
are still available for use.

print $query->header();

	-or-
print $query->header(-expires=>"+1m",
                     -Refresh=>'20; URL='/newplace.wml');

=item B<start_wml()>
Use the start_wml method to create the start of a WML deck, if you
wish you can pass paramaters to the method to define a custom DTD,
XML language value and any 'META' information. If a DTD is not specified
then the default is to use C<WML 1.1>

$query->start_wml(-dtd      => '-//WAPFORUM//DTD WML 5.5//EN',
                  -dtd_url  => 'http://www.wapforum.org/DTD/wml_5.5.xml',
                  -lang     => 'en-gb',
                  -encoding => 'iso-8859-1',
                  -meta     => {'scheme'=>'foobar',
                                'name'  =>'mystuff'} );

There is no direct support for the HTTP-EQUIV type of <meta> tag. This is
because you can modify the HTTP header directly with the header() method.
For example, if you want to send the Cache-control: header, do it in the
header() method:

$q->header(-cache_control=>'No-cache; forua=true');

=item B<end_wml()>

Use end_wml() to end the WML deck. Just included for completeness.

=back

=head2 CREATING WML CARDS

=over 2

=item B<card()>

Cards are created whole, by passing paramaters to the card() method, as
well as the card attributes, a timer may be added to the start of the 
card.

$query->card(-id=>"card_id",
             -title=>"First Card",
             -ontimer=>"#next_card",
             -timer=>$query->C<timer>(-name=>"timer1",-value=>"30"),
             -newcontext=>"true",
             -onenterforward=>"#somecard",
             -onenterbackward=>"#othercard",
             -content=>"<p>Hello WAP world</p>");

The 'ID' and 'Content' elements are manditory, and have no defaults.
At least one paragraph tag is also required.  If you get everything
else correct and nothing is diplayed, that may be the reason.  All
other parameters are optional.

An other way of making the above card would be this:

$content =  $query->p("Hello WAP world");

$query->card(-id=>"card_id",
             -title=>"First Card",
             -ontimer=>"#next_card",
             -timer=>$query->C<timer>(-name=>"timer1",-value=>"30"),
             -newcontext=>"true",
             -onenterforward=>"#somecard",
             -onenterbackward=>"#othercard",
             -content=>$content);


=head2 TEMPLATES

The template() method creates a template for placing at the start
of a card. If you just need to add a B<back> link, use the prev()
method.

$query->template(-content=>$query->prev(-label=>"Go Back"));

=head2 TIMERS

A card timer is used with the card() method to trigger an action, the
function takes two arguments, the name of the timer and it's value in
milliseconds.

$query->timer(-name=>"mytimer",
              -value=>"30");

=head2 GO BLOCKS

A E<lt>go block is created either as a single line

$query-E<gt>go(-method=>"get",
            -href=E<gt>"http://www.example.com/");
C<
E<lt>go href="http://www.example.com/" method="get"/E<gt>
>
or as a block

%pfs = ('var1'=E<gt>'1',
        'var2'=E<gt>'2',
        'varN'=E<gt>'N');

$query-E<gt>go(-method=E<gt>"post",
           -href=E<gt>"http://www.example.com/",
           -postfields=>\%pfs);

E<lt>go href="http://www.example.com/" method="get"E<gt>
  E<lt>postfield name="var1" value="1"/E<gt>
  E<lt>postfield name="var2" value="2"/E<gt>
  E<lt>postfield name="varN" value="N"/E<gt>
E<lt>/goE<gt> 

depending on wether it is passed a hash of postfields.

=head2 DO 

$query-E<gt>do(-type=>"options",
              -label=>"Menu",
              -content=>qq(go href="#menu"/>));
gives 

<do type="options" label="Menu" >
  <go href="#menu"/>
</do>

=head2 PREV

A canned 'back' link, takes an optional label argument. Default label
is 'Back'. For use in B<templates>

$query->prev(-label=>"Reverse");

<do type="accept" label="Reverse"><prev/></do>

=head2 INPUT

Create an input entry field. No defaults, although not all arguments need
to be specified.

$query->input(-name=>"pin",
              -value=>"1234",
              -type=>"text",
              -size=>4,
              -title=>"Enter PIN",
              -format=>"4N",
              -maxlength=>4,
              -emptyok=>"false");

=head2 ONEVENT

An B<onevent> element may contain one of 'go','prev','noop' or 'refresh'
and be of type 'onenterforward', 'onenterbackward' or 'ontimer'.

$query->onevent(-type=>"onenterforward",
                -content=>qq(<refresh>
                              <setvar name="x" value="1"/>
                             </refresh>));

=head2 IMG

An image can be created with the following attributes:

 alt       Text to display in case the image is not displayed
 align     can be top, middle, bottom
 src       The absolute or relative URI to the image
 localsrc  a variable (set using the setvar tag) that refers to an image
           this attribute takes precedence over the B<src> tag
 vspace    
 hspace    amount of white space to inserted to the left and right 
           of the image [hspace] or above and below the image [vspace] 
 height    
 width     These attributes are a hint to the user agent to leave space
           for the image while the page is rendering the page.  The 
           user agent may ignore the attributes.  If the number length 
           is passed as a percent the resulting image size will be
           relative to the amount of available space, not the image size.

my $img = $query->img(
                 -src      => '/icons/blue_boy.wbmp',
                 -alt      => 'Blue Boy',
                 -localsrc => '$var',
                 -vspace   => '25',
                 -hspace   => '30
                 -align    => 'bottom',
                 -height   => '15',
                 -width    => '10');

I<NOTE> the B<localsrc> element, and formatting elements are not supported
consistently by the current generation of terminals, however they B<should>
simply ignore the attributes they do not understand.

=head2 Dial Tags

When using cell phones in WAP you can make calls.  When a dial tag is
selected the phone drops out of the WAP stack and into what ever is the 
protocol used for phone calls.  At the conclusion of the call the phone 
I<should> return to the WAP stack in the same place that you linked to
the phone number.  

The tag looks much like a regular link, but has some special syntax.  

$query->dialtag(-label =>"Joe's Pizza",
                -number=>"12125551212");

The recieving terminal must support WTAI for this link to work.

=head1 WML SHORTCUTS

I<p> I<b> I<br> I<table> etc. etc. Just like the original CGI.pm, this
module includes functions for creating correct WML by calling methods of
a query object.

WML Shortcuts may be called in two ways; 

With a single parameter, which will be the content of the tag, for
example;

       Perl code                           WML Result
     ---------------------            ---------------------
     $query->b("Bold text);               <b>bold</b>
     $query->p("Hello");                  <p>Hello</p>

     $query->p($query->b("Hello"));       <p><b>Hello</b></p> 

     $query->br();                        <br/> # "No-close" tags are
                                                # automatically dealt with

Alternatively, they can be called with a list of arguments, specifying
content and attibutes.

      Perl code                           WML Result
      ---------------------            ---------------------
      $query->p(-align=>"left",        <p align="left">Hi there</p>
                -content=>"Hi there");
      
 When being called with the second syntax, the 'content' parameter
 specifies the content of tags. 

 All WML 1.1 tags are available via this method.

=head1 COMPILING WML DECKS

$query->wml_to_wmlc(-wml=>$buffer,
                    -errorcontext=>2);  # default 0

A WML to WBXML converter/compiler is included for convinience purposes,
although it is not intended to replace the compiler on the WAP
gateway it may prove useful, for example measuring what the compiled
document size will be.

     $size = length($query->wml_to_wmlc(-wml=>$wml,
                                        -errorcontext=>0));

=over 4

I<NOTE> WBXML string tables are used to compress the document size down as small
as possible, giving excellent document size performance. Because of this
though, the size returned by the function may be smaller than the size
of the WBXML document created by the WAP gateway. Turning this feature
off will be an option in future releases.

=back

The function takes two arguments, a buffer of textual WML and an optional
argument specifiying that should the XML parser fail then X many lines of
the buffer before and after the point where the error occured will be printed
to show the context of the error. 

=head2 ERRORCONTEXT
I<WARNING> Setting this to any non-zero value will cause your program to
exit if the routine is passed WML which is not "well formed" this is due
to the fact that XML::Parser calls die() upon such events.

If you wish to test wether a WML document is well formed, then set this
value to zero and check the return value of the function. The function
returns undef upon failiure and issues a warning, anything other than
undef indicates success.

=head1 HTML TO WML CONVERSION

($title,$content) = $query->html_to_wml($buffer);

-or-

($title,$content) = $query->html_to_wml(\*FILEHANDLE);

A limited HTML to WML converter is included in this package. Be warned
that only pretty well marked-up HTML will convert cleanly to WML.
Dave Ragget's excellent B<tidy> utility 
[ see http://www.w3.org/People/Raggett/tidy/ ]
will clean up most HTML into a parseable state.

The main purpose of this function is for converting server error messages 
and the "Compact HTML" used on "I-Mode" systems to readable WML, not for
general page translation.

Potential users of this function are encouraged to read the source to this
module to gain a better understanding of the underlying mechanics of the
translation.

=back

=head1 AUTHOR

Version 0.06 - 0.09

Andy Murren <amurren@users.sourceforge.net>

Versions 0.01 - 0.05

Angus Wood <angus@z-y-g-o.com>, with loads of additions and
improvements by Andy Murren <amurren@users.sourceforge.net>

=head1 CREDITS

=item Wilbert Smits <wilbert@telegraafnet.nl> for the header()
      function content-type override.

=head1 CHANGES

See Changes file distributed with the module.

=head1 SEE ALSO

perl(1), perldoc CGI, tidy(1)

=cut

