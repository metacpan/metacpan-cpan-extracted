# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::Transformer::XSP;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(AxKit2::Transformer);

use AxKit2::Constants;
use AxKit2::Client;

AxKit2::Config->add_config_param('AddXSPTaglib', \&AxKit2::Config::TAKE1,
        sub {
            my ($config, $package) = @_;
            eval "require $package;";
            die $@ if $@;
            $package->register();
        }
    );

sub new {
    my $class = shift;
    
    my $self = bless {}, $class;
    
    return $self;
}

sub transform {
    my $self = shift;
    my ($pos, $processor) = @_;
    
    $self->log(LOGINFO, "Transformer::XSP running");
    
    # always need this
    my $dom = XML::LibXML::Document->createDocument("1.0", "UTF-8");
    
    my $key = $processor->path . $pos;
    my $package = get_package_name($key);
    
    if ($processor->input || !defined &{"${package}::xml_generator"}) {
        # not already compiled or we have "input" so we need to recompile
        $self->log(LOGDEBUG, "XSP (re)compiling $key");
        $processor->input ? $self->log(LOGDEBUG, "... because we have input")
                          : $self->log(LOGDEBUG, "... because we can't see the function");
        $self->compile($key, $package, $processor);
    }
    
    my $cv = $package->can("handler") || die "Unable to get handler method";
    my $rc = eval { $package->$cv($self->client, $dom); };
    die $@ if $@;
    
    $self->client->headers_out->code($rc);
    
    return $dom;
}

sub compile {
    my $self = shift;
    my ($key, $package, $processor) = @_;
    
    my $handler = AxKit2::XSP::SAXHandler->new_handler(
            XSP_Package => $package,
            XSP_Line => $key,
            XSP_Debug => 0,
            );
    my $parser = AxKit2::XSP::SAXParser->new(
            Handler => $handler,
            );
    
    my $to_eval = $parser->parse($processor->dom);
    eval $to_eval;
    if ($@) {
        open(my $fh, ">/tmp/bad.xsp");
        print $fh $to_eval;
        close($fh);
        die $@;
    }
}

sub register {
    my $class = shift;
    no strict 'refs';
    $class->register_taglib(${"${class}::NS"});
}

sub register_taglib {
    my $class = shift;
    my $namespace = shift;

#    warn "Register taglib: $namespace => $class\n";

    $AxKit2::Transformer::XSP::tag_lib{$namespace} = $class;
}

sub is_xsp_namespace {
    my ($ns) = @_;

    # a uri of the form "res:perl/<spec>" turns into an implicit loading of
    # the module indicated by <spec> (after slashes are turned into
    # double-colons). an example uri is "res:perl/My/Cool/Module".
    if ($AxKit2::Transformer::XSP::ResNamespaces && $ns =~ m/^res:perl\/(.*)$/) {
       my $package = $1;
       $package =~ s/\//::/g;
       AxKit::load_module($package);
       $package->register();
    }
    
    return 1 if $ns && $AxKit2::Transformer::XSP::tag_lib{$ns};
}

sub get_package_name {
    my $filename = shift;
    
    # Escape everything into valid perl identifiers
    $filename =~ s/([^A-Za-z0-9_\/])/sprintf("_%2x",unpack("C",$1))/eg;

    # second pass cares for slashes and words starting with a digit
    $filename =~ s{
                  (/+)       # directory
                  (\d?)      # package's first character
                 }[
                   "::" . (length $2 ? sprintf("_%2x",unpack("C",$2)) : "")
                  ]egx;

    return "AxKit2::Transformer::XSP::ROOT$filename";
}

sub makeSingleQuoted($) {
    my $value = shift;
    $value =~ s/([\\|])/\\$1/g;
    return 'q|'.$value.'|';
}

############################################################
# SAX Handler code
############################################################

package AxKit2::XSP::SAXHandler;

sub new_handler {
    my ($type, %self) = @_;
    return bless \%self, $type;
}

sub start_expr {
    my ($e) = @_;
    my $element = { Name => "expr",
                    NamespaceURI => $AxKit2::XSP::Core::NS,
                    Attributes => [ ],
                    Parent => $e->{Current_Element}->{Parent},
#                    OldParent => $e->{Current_Element},
            };
#    warn "start_expr: $e->{Current_Element}->{Name}\n";
    $e->start_element($element);
}

sub end_expr {
    my ($e) = @_;
    my $parent = $e->{Current_Element}->{Parent};
    my $element = { Name => "expr",
                    NamespaceURI => $AxKit2::XSP::Core::NS,
                    Attributes => [ ],
                    Parent => $parent,
            };
#    warn "end_expr: $parent->{Name}\n";
    $e->end_element($element);
}

sub append_to_script {
    my ($e, $code) = @_;
    my (undef, $file, $line) = caller;
    $e->{XSP_Script} .= $e->location_debug_string($file,$line).$code;
}

sub manage_text {
    my ($e, $set, $go_back) = @_;

    $go_back ||= 0;

    my $depth = $e->depth();
    if (defined($set) && $set >= 0) {
        $e->{XSP_Manage_Text}[$depth - $go_back] = $set;
    }
    else {
        if (defined($set) && $set == -1) {
            # called from characters handler, rather than expr
            return $e->{XSP_Manage_Text}[$depth];
        }
        return $e->{XSP_Manage_Text}[$depth - 1];
    }
}

sub depth {
    my ($e) = @_;
    my $element = $e->{Current_Element};
    
    my $depth = 0;
    while ($element = $element->{Parent}) {
        $depth++;
    }
    
    return $depth;
}

sub current_element {
    my $e = shift;
    my $tag = $e->{Current_Element}{Name};
    $tag =~ s/^(.*:)//;
    return $tag;
}

sub location_debug_string {
  my ($e, $file, $line) = @_;
  return '' if !$e->{XSP_Debug} || $file =~ m/^AxKit2::XSP::Core::/;
  (undef, $file, $line) = caller if (@_ < 3);
  $file =~ s/"/''/;
  $file =~ s/\n/ /;
  return "\n# line $line \"XSP generated by $file\"\n";
}

sub start_document {
    my $e = shift;
    $e->{XSP_chars} = 0;
    $e->{XSP_Script} = join("\n", 
                $e->location_debug_string,
                "package $e->{XSP_Package};",
                "use AxKit2::Constants;",
                "use XML::LibXML;",
                "AxKit2::Transformer::XSP::Page->import( qw(__mk_expr_node __mk_text_node __mk_comment_node __mk_ns_element_node __mk_element_node) );",
                ($] >= 5.008?"use utf8;":""),
                );

    foreach my $ns (keys %AxKit2::Transformer::XSP::tag_lib) {
        my $pkg = $AxKit2::Transformer::XSP::tag_lib{$ns};
        my $sub;
        local $AxKit2::XSP::TaglibPkg = $pkg;
        if (($sub = $pkg->can("start_document")) && ($sub != \&start_document)) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::start_document",1).$sub->($e);
        }
        elsif ($sub = $pkg->can("parse_init")) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::parse_init",1).$sub->($e);
        }
    }
}

sub end_document {
    my $e = shift;
    $e->{XSP_chars} = 0;
    foreach my $ns (keys %AxKit2::Transformer::XSP::tag_lib) {
        my $pkg = $AxKit2::Transformer::XSP::tag_lib{$ns};
        my $sub;
        local $AxKit2::XSP::TaglibPkg = $pkg;
        if (($sub = $pkg->can("end_document")) && ($sub != \&end_document)) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::end_document",1).$sub->($e);
        }
        elsif ($sub = $pkg->can("parse_final")) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::parse_final",1).$sub->($e);
        }
    }

    ## we assume that if $e->{XSP_User_Root} is true, somebody, somewhere
    ## (most likely the default start_element() sub) must have started the
    ## "sub xml_generator {" declaration, and that we need to close it
    if ($e->{XSP_User_Root}) {
        $e->{XSP_Script} .= $e->location_debug_string."return OK;\n}\n";
    }
    else {
        die("No user root element found")
           unless $AxKit2::Transformer::XSP::AllowNoUserRoot;
    }

    return $e->{XSP_Script};
}

sub start_element {
    my $e = shift;
    my $element = shift;
    $e->{XSP_chars} = 0;

    $element->{Parent} ||= $e->{Current_Element};

    $e->{Current_Element} = $element;

    my $ns = $element->{NamespaceURI};

#    warn "START-NS: $ns : $element->{Name}\n";

    my @attribs;

    for my $attr (@{$element->{Attributes}}) {
        if ($attr->{Name} eq 'xmlns') {
            unless (AxKit2::Transformer::XSP::is_xsp_namespace($attr->{Value})) {
                $e->{Current_NS}{'#default'} = $attr->{Value};
            }
        }
        elsif ($attr->{Name} =~ /^xmlns:(.*)$/) {
            my $prefix = $1;
            unless (AxKit2::Transformer::XSP::is_xsp_namespace($attr->{Value})) {
                $e->{Current_NS}{$prefix} = $attr->{Value};
            }
        }
        else {
            push @attribs, $attr;
        }
    }

    $element->{Attributes} = \@attribs;

    if (!defined($ns) || 
        !exists($AxKit2::Transformer::XSP::tag_lib{ $ns })) 
    {
        $e->manage_text(0); # set default for non-xsp tags
        $e->{XSP_Script} .= AxKit2::XSP::DefaultHandler::start_element($e, $element);
    }
    else {
        $element->{Name} =~ s/^(.*)://;
        my $prefix = $1;
        my $tag = $element->{Name};
        my %attribs;
        # this is probably a bad hack to turn xsp:name="value" into name="value"
        for my $attr (@{$element->{Attributes}}) {
            $attr->{Name} =~ s/^\Q$prefix\E://;
            $attribs{$attr->{Name}} = $attr->{Value};
        }
        $e->manage_text(1); # set default for xsp tags
        my $pkg = $AxKit2::Transformer::XSP::tag_lib{ $ns };
        my $sub;
        local $AxKit2::XSP::TaglibPkg = $pkg;
        if (($sub = $pkg->can("start_element")) && ($sub != \&start_element)) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::start_element",1).$sub->($e, $element);
        }
        elsif ($sub = $pkg->can("parse_start")) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::parse_start",1).$sub->($e, $tag, %attribs);
        }
    }
}

sub end_element {
    my $e = shift;
    my $element = shift;
    $e->{XSP_chars} = 0;

    my $ns = $element->{NamespaceURI};
    
#    warn "END-NS: $ns : $_[0]\n";
    
    if (!defined($ns) || 
        !exists($AxKit2::Transformer::XSP::tag_lib{ $ns })) 
    {
        $e->{XSP_Script} .= AxKit2::XSP::DefaultHandler::end_element($e, $element);
    }
    else {
        $element->{Name} =~ s/^(.*)://;
        my $tag = $element->{Name};
        my $pkg = $AxKit2::Transformer::XSP::tag_lib{ $ns };
        my $sub;
        local $AxKit2::XSP::TaglibPkg = $pkg;
        if (($sub = $pkg->can("end_element")) && ($sub != \&end_element)) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::end_element",1).$sub->($e, $element);
        }
        elsif ($sub = $pkg->can("parse_end")) {
            $e->{XSP_Script} .= $e->location_debug_string("${pkg}::parse_end",1).$sub->($e, $tag);
        }
    }
    
    $e->{Current_Element} = $element->{Parent} || $e->{Current_Element}->{Parent};
}

sub characters {
    my $e = shift;
    my $text = shift;
    my $ns = $e->{Current_Element}->{NamespaceURI};

#    warn "CHAR-NS: $ns\n";
    
    if (!defined($ns) || 
        !exists($AxKit2::Transformer::XSP::tag_lib{ $ns }) ||
        !$e->manage_text(-1))
    {
        $e->{XSP_Script} .= AxKit2::XSP::DefaultHandler::characters($e, $text);
    }
    else {
        my $pkg = $AxKit2::Transformer::XSP::tag_lib{ $ns };
        my $sub;
        local $AxKit2::XSP::TaglibPkg = $pkg;
        if (($sub = $pkg->can("characters")) && ($sub != \&characters)) {
            $e->{XSP_Script} .= $sub->($e, $text);
        }
        elsif ($sub = $pkg->can("parse_char")) {
            $e->{XSP_Script} .= $sub->($e, $text->{Data});
        }
    }
    $e->{XSP_chars} = 1;
}

sub comment {
    my $e = shift;
    my $comment = shift;

    my $ns = $e->{Current_Element}->{NamespaceURI};

    if (!defined($ns) || 
        !exists($AxKit2::Transformer::XSP::tag_lib{ $ns })) 
    {
        $e->{XSP_Script} .= AxKit2::XSP::DefaultHandler::comment($e, $comment);
    }
    else {
        my $pkg = $AxKit2::Transformer::XSP::tag_lib{ $ns };
        my $sub;
        local $AxKit2::XSP::TaglibPkg = $pkg;
        if (($sub = $pkg->can("comment")) && ($sub != \&comment)) {
            $e->{XSP_Script} .= $sub->($e, $comment);
        }
        elsif ($sub = $pkg->can("parse_comment")) {
            $e->{XSP_Script} .= $sub->($e, $comment->{Data});
        }
    }
}

sub processing_instruction {
    my $e = shift;
    my $pi = shift;

    my $ns = $e->{Current_Element}->{NamespaceURI};
 
    if (!defined($ns) || 
        !exists($AxKit2::Transformer::XSP::tag_lib{ $ns })) 
    {
        $e->{XSP_Script} .= AxKit2::XSP::DefaultHandler::processing_instruction($e, $pi);
    }
    else {
        my $pkg = $AxKit2::Transformer::XSP::tag_lib{ $ns };
        my $sub;
        local $AxKit2::XSP::TaglibPkg = $pkg;
        if (($sub = $pkg->can("processing_instruction")) && ($sub != \&processing_instruction)) {
            $e->{XSP_Script} .= $sub->($e, $pi);
        }
        elsif ($sub = $pkg->can("parse_pi")) {
            $e->{XSP_Script} .= $sub->($e, $pi->{Target}, $pi->{Data});
        }
    }
}

############################################################
# Functions implementing xsp:* processing
############################################################

package AxKit2::XSP::Core;

*makeSingleQuoted = \&AxKit2::Transformer::XSP::makeSingleQuoted;

our @ISA = ('AxKit2::Transformer::XSP');

our $NS = 'http://apache.org/xsp/core/v1';

__PACKAGE__->register();

# hack for backwards compatibility:
__PACKAGE__->register_taglib("http://www.apache.org/1999/XSP/Core");


sub start_document {
    return "#initialize xsp namespace\n";
}

sub end_document {
    return '';
}

sub comment {
    return '';
}

sub processing_instruction {
    return '';
}

sub characters {
    my ($e, $node) = @_;

    my $text = $node->{Data};
    
#     Ricardo writes: "<xsp:expr> produces either an [object]
# _expression_ (not necessarily a String) or a character event depending
# on context. When  <xsp:expr> is enclosed in another XSP tag (except
# <xsp:content>), it's replaced by the code it contains. Otherwise it
# should be treated as a text node and, therefore, coerced to String to be
# output through a characters SAX event."

    if ($e->current_element() =~ /^(content|element)$/) {
        if ($text =~ /\S/ || $e->{XSP_Indent}) {
            $text = makeSingleQuoted($text);
            return "__mk_text_node(\$document,\$parent,$text);";
        }
        return '';
    }
    elsif ($e->current_element() =~ /^(attribute|comment|name)$/) {
        return '' if ($e->current_element() eq 'attribute' && !$e->{attrib_seen_name});
        $text =~ s/^\s*//; $text =~ s/\s*$//;
        $text = makeSingleQuoted($text);
        return ". $text";
    }
    
#    return '' unless $e->{XSP_User_Root};
    
    my $debug = "";
    if (!$e->{XSP_chars}) {
        $e->{XSP_Debug_Section} ||= 1;
        my $lineno = $node->{LineNumber};
        if (!$lineno) {
            $debug = $e->location_debug_string("expr|logic section nr. ".$e->{XSP_Debug_Section},1);
        } else {
            $debug = $e->location_debug_string("XSP page",$lineno);
        }
        $e->{XSP_Debug_Section}++;
    }
    return $debug.$text;
}

sub start_element {
    my ($e, $node) = @_;
    
    my ($tag, %attribs);
    
    $tag = $node->{Name};
    
    foreach my $attrib (@{$node->{Attributes}}) {
        $attribs{$attrib->{Name}} = $attrib->{Value};
    }
    
    if ($tag eq 'page') {
        if ($attribs{language} && lc($attribs{language}) ne 'perl') {
            die "Only Perl XSP pages supported at this time!";
        }
        if ($attribs{'indent-result'} && $attribs{'indent-result'} eq 'yes') {
            $e->{XSP_Indent} = 1;
        }
        if (exists $attribs{'base-class'}) {
            if (! $attribs{'base-class'}->can("handler") ) {
                die "base-class used but cannot find a handler() method in the " . 
                    $attribs{'base-class'} . " class. Did you remember to add PerlModule " . 
                    $attribs{'base-class'} . " to httpd.conf?";
            }
            $e->{XSP_Base_Class} = $attribs{'base-class'};
        }
        if (my $i = lc $attribs{'attribute-value-interpolate'}) {
            if ($i eq 'no') {
                $e->{XSP_No_Attr_Interpolate} = 1;
            }
            elsif ($i eq 'yes') {
                $e->{XSP_No_Attr_Interpolate} = 0;
            }
            else {
                die "Unknown value for attribute-value-interpolate: $i";
            }
        }
    }
    elsif ($tag eq 'structure') {
    }
    elsif ($tag eq 'dtd') {
    }
    elsif ($tag eq 'include') {
        return "warn \"xsp:include is deprecated\"; use ";
    }
    elsif ($tag eq 'content') {
    }
    elsif ($tag eq 'logic') {
    }
    elsif ($tag eq 'import') {
        return "use ";
    }
    elsif ($tag eq 'element') {
        if ($node->{Parent}->{Name} eq 'attribute' &&
            AxKit2::Transformer::XSP::is_xsp_namespace($node->{Parent}->{NamespaceURI}))
        {
            die("[Core] Can't have element as child of attributes!");
        }
        if (my $name = $attribs{name}) {
            $e->manage_text(0);
            return '$parent = __mk_element_node($document, $parent, ' . makeSingleQuoted($name) . ');';
        }
    }
    elsif ($tag eq 'attribute') {
        if (my $uri = $attribs{uri}) {
            # handle NS attributes
            my $prefix = $attribs{prefix} || die "No prefix given";
            my $name = $attribs{name} || die "No name given";
            $e->{attrib_seen_name} = 1;
            return '$parent->setNamespace('.makeSingleQuoted($uri).', '.
                                            makeSingleQuoted($prefix).', 0);'.
                   '$parent->setAttributeNS('.makeSingleQuoted($uri).', '.
                                              makeSingleQuoted($name).', ""';
        }
        if (my $name = $attribs{name}) {
            $e->{attrib_seen_name} = 1;
            # handle prefixed names
            if ($name =~ s/^(.*?)://) {
                my $prefix = $1;
                return 'my $nsuri = $parent->lookupNamespaceURI(' . makeSingleQuoted($prefix) . ')'.
                        ' || die "No namespace found with given prefix";'."\n".
                        '$parent->setAttributeNS($nsuri,'.makeSingleQuoted($name).', ""';
            }
            return '$parent->setAttribute('.makeSingleQuoted($name).', ""';
        }
        $e->{attrib_seen_name} = 0;
    }
    elsif ($tag eq 'name') {
        if ($node->{Parent}->{Name} =~ /^(.*:)?element$/) {
            return '$parent = __mk_element_node($document, $parent, ""';
        }
        elsif ($node->{Parent}->{Name} =~ /^(.*:)?attribute$/) {
            $e->{attrib_seen_name} = 1;
            return '$parent->setAttribute(""';
        }
        else {
            die "xsp:name parent node: $node->{Parent}->{Name} not valid";
        }
    }
    elsif ($tag eq 'pi') {
    }
    elsif ($tag eq 'comment') {
        return '__mk_comment_node($document, $parent, ""';
    }
    elsif ($tag eq 'text') {
        return '__mk_text_node($document, $parent, ""';
    }
    elsif ($tag eq 'expr') {
        #warn "expr: parent = {", $node->{Parent}->{NamespaceURI}, "}", $node->{Parent}->{Name}, "\n";

        if (AxKit2::Transformer::XSP::is_xsp_namespace($node->{Parent}->{NamespaceURI})) {
            if (!$e->manage_text() || $node->{Parent}->{Name} =~ /^(?:.*:)?(?:content|element)$/) {
                return $attribs{'as-xml'}
                            ? '__mk_expr_node($document, $parent, 1, do {'
                            : '__mk_expr_node($document, $parent, 0, do {';
            }
            elsif ($node->{Parent}->{Name} =~ /^(.*:)?(logic|expr)$/) {
                # <xsp:expr> within <xsp:expr>...
                return 'do {';
            }
            # <xsp:expr> inside a taglib
            return ' . do {';
        }
        else {
            return $attribs{'as-xml'}
                        ? '__mk_expr_node($document, $parent, 1, do {'
                        : '__mk_expr_node($document, $parent, 0, do {';
        }
        warn("EEEK - Should never get here!!!");
#        warn "start Expr: CurrentEl: ", $e->current_element, "\n";
    }
    else {
        warn("Unrecognised tag: $tag");
    }

    return '';
}

sub end_element {
    my ($e, $node) = @_;
    
    my $tag = $node->{Name};

    if ($tag eq 'page') {
    }
    elsif ($tag eq 'structure') {
    }
    elsif ($tag eq 'dtd') {
    }
    elsif ($tag eq 'include') {
        return ";\n";
    }
    elsif ($tag eq 'import') {
        return ";\n";
    }
    elsif ($tag eq 'content') {
    }
    elsif ($tag eq 'logic') {
    }
    elsif ($tag eq 'element') {
        return '$parent = $parent->getParentNode;' . "\n";
    }
    elsif ($tag eq 'attribute') {
        # ends function from either start('attribute') or end('name)
        # as in either <xsp:attribute name="foo">
        #           vs <xsp:attrubute><xsp:name>foo</xsp:name>
        return ");\n";
    }
    elsif ($tag eq 'name') {
        if ($node->{Parent}->{Name} =~ /^(.*:)?element$/) {
            return ");\n";
        }
        elsif ($node->{Parent}->{Name} =~ /^(.*:)?attribute$/) {
            return ', ""';
        }
    }
    elsif ($tag eq 'pi') {
    }
    elsif ($tag eq 'comment') {
        return ");\n";
    }
    elsif ($tag eq 'text') {
        return ");\n";
    }
    elsif ($tag eq 'expr') {
#        warn "expr: -2 = {", $node->{Parent}->{NamespaceURI}, "}", $node->{Parent}->{Name}, "\n";
        if (AxKit2::Transformer::XSP::is_xsp_namespace($node->{Parent}->{NamespaceURI})) {
            if (!$e->manage_text() || $node->{Parent}->{Name} =~ /^(?:.*:)?(?:content|element)$/) {
                return "}); # xsp tag\n";
            }
            elsif ($node->{Parent}->{Name} =~ /^(.*:)?(logic|expr)$/) {
                return '}';
            }
            else {
                return '}';
            }
        }
        else {
            return "}); # non xsp tag\n";
        }
    }
    
    return '';
}

1;

############################################################
## Default (non-xsp-namespace) handlers
############################################################

package AxKit2::XSP::DefaultHandler;

*makeSingleQuoted = \&AxKit2::Transformer::XSP::makeSingleQuoted;

sub _undouble_curlies {
    my $value = shift;
    $value =~ s/\{\{/\{/g;
    $value =~ s/\}\}/\}/g;
    return $value;
}

sub _attr_value_template {
    my ($e, $value) = @_;
    if ($e->{XSP_No_Attr_Interpolate}) {
        return makeSingleQuoted($value);
    }
    # warn("Transforming: '$value'\n");
    return makeSingleQuoted($value) unless $value =~ /{/;
    my $output = "''";
    while ($value =~ /\G([^{]*){/gc) {
        $output .= "." . makeSingleQuoted(_undouble_curlies($1)) if $1;
        if ($value =~ /\G{/gc) {
            $output .= ".q|{|";
            next;
        }
        # otherwise we're in code now...
        $output .= ".do{";
        # while ($value =~ /\G([^'"}]*)}/gc) {
        while ($value =~ /\G([^}]*)}/gc) {
            $output .= _undouble_curlies($1);
            if ($value =~ /\G}/gc) {
                $output .= "}";
                next;
            }
            $output .= "}";
            last;
        }
    }
    $value =~ /\G(.*)$/gc and $output .= "." . makeSingleQuoted(_undouble_curlies($1));
    # warn("Changed to: $output\n");
    return $output;
}

sub start_element {
    my ($e, $node) = @_;

    my $code;
    if (!$e->{XSP_User_Root}) {
        my $base_class = $e->{XSP_Base_Class} ||
          'AxKit2::Transformer::XSP::Page';
        $e->{XSP_Script} .= join("\n",
                $e->location_debug_string(),
                "\@$e->{XSP_Package}::ISA = ('$base_class');",
                'sub xml_generator {',
                'my $class = shift;',
                'my ($cgi, $document, $parent) = @_;',
                'my $client = $cgi;',
                "\n",
                );
        $e->{XSP_User_Root} = 1;

        foreach my $ns (keys %AxKit2::Transformer::XSP::tag_lib) {
            my $pkg = $AxKit2::Transformer::XSP::tag_lib{$ns};
            local $AxKit2::XSP::TaglibPkg = $pkg;
            if (my $sub = $pkg->can("start_xml_generator")) {
                $e->{XSP_Script} .= $e->location_debug_string("${pkg}::start_xml_generator",1).$sub->($e);
            }
        }

        # Note: No debugging here, to reduce bloat. Shouldn't be neccessary anyways.
        if ($node->{NamespaceURI}) {
            $code = '$parent = __mk_ns_element_node($document, $parent, '.
              makeSingleQuoted($node->{NamespaceURI}).','.
              makeSingleQuoted($node->{Name}).");\n";
        }
        else {
            $code = '$parent = __mk_element_node($document, $parent, '.
              makeSingleQuoted($node->{Name}).");\n";
        }
    }
    else {
        if ($node->{Parent}->{Name} eq 'attribute' &&
            AxKit2::Transformer::XSP::is_xsp_namespace($node->{Parent}->{NamespaceURI}))
        {
            die("[Default] Can't have element as child of attributes!");
        }
        if ($node->{NamespaceURI}) {
            $code = '$parent = __mk_ns_element_node($document, $parent, ' .
              makeSingleQuoted($node->{NamespaceURI}).','.
              makeSingleQuoted($node->{Name}).");\n";
        }
        else {
            $code = '$parent = __mk_element_node($document, $parent, ' .
              makeSingleQuoted($node->{Name}).");\n";
        }
    }

    for my $attr (@{$node->{Attributes}}) {
        my $value = _attr_value_template($e, $attr->{Value});
        if ($attr->{NamespaceURI}) {
            $code .= '$parent->setAttributeNS('.makeSingleQuoted($attr->{NamespaceURI}).','.makeSingleQuoted($attr->{Name}).
                ",$value);\n";
        } else {
        $code .= '$parent->setAttribute('.makeSingleQuoted($attr->{Name}).
                ",$value);\n";
    }
    }

    for my $ns (keys %{$e->{Current_NS}}) {
        if ($ns eq '#default') {
            $code .= '$parent->setAttributeNS("","xmlns",' .
                    makeSingleQuoted($e->{Current_NS}{$ns}) . ');';
        }
        else {
            $code .= '$parent->setAttribute("xmlns:" . '.makeSingleQuoted($ns).',' .
                    makeSingleQuoted($e->{Current_NS}{$ns}) . ');';
        }

    }

    push @{ $e->{NS_Stack} },
            { %{ $e->{Current_NS} || {} } };

    $e->{Current_NS} = {};

    return $code;
}

sub end_element {
    my ($e, $element) = @_;

    $e->{Current_NS} = pop @{ $e->{NS_Stack} };

    return '$parent = $parent->getParentNode;' . "\n";
}

sub characters {
    my ($e, $node) = @_;

    my $text = $node->{Data};
    
    return '' unless $e->{XSP_User_Root}; # should not happen!
    
    if (!$e->{XSP_Indent}) {
        return '' unless $text =~ /\S/;
    }
    
    return '__mk_text_node($document, $parent, '.makeSingleQuoted($text).");\n";
}

sub comment {
    return '';
}

sub processing_instruction {
    return '';
}

1;

######################################################
## SAXParser
######################################################

package AxKit2::XSP::SAXParser;

use XML::LibXML;

sub new {
    my ($type, %self) = @_; 
    return bless \%self, $type;
}

sub parse {
    my ($self, $thing) = @_;

    my $doc;

    if (ref($thing) ne 'XML::LibXML::Document') {
        my $parser = XML::LibXML->new();
        $parser->expand_entities(1);
        eval {
            $parser->line_numbers(1);
        } if $self->{Handler}->{XSP_Debug};

        if (ref($thing)) {
            $doc = $parser->parse_fh($thing);
        }
        else {
            $doc = $parser->parse_string($thing);
        }
        $doc->process_xinclude;
    } else {
        $doc = $thing;
    }

    my $encoding = $doc->getEncoding() || 'UTF-8';
    my $document = { Parent => undef };
    $self->{Handler}->start_document($document);

    my $root = $doc->getDocumentElement;
    if ($root) {
        process_node($self->{Handler}, $root, $encoding);
    }

    $self->{Handler}->end_document($document);
}

sub process_node {
    my ($handler, $node, $encoding) = @_;

    my $lineno = eval { $node->lineNumber; } if $handler->{XSP_Debug};

    my $node_type = $node->getType();
    if ($node_type == XML_COMMENT_NODE) {
        $handler->comment( { Data => $node->getData, LineNumber => $lineno } );
    }
    elsif ($node_type == XML_TEXT_NODE || $node_type == XML_CDATA_SECTION_NODE) {
        # warn($node->getData . "\n");
        $handler->characters( { Data => encodeToUTF8($encoding,$node->getData()), LineNumber => $lineno } );
    }
    elsif ($node_type == XML_ELEMENT_NODE) {
        # warn("<" . $node->getName . ">\n");
        process_element($handler, $node, $encoding);
        # warn("</" . $node->getName . ">\n");
    }
    elsif ($node_type == XML_ENTITY_REF_NODE) {
        foreach my $kid ($node->getChildnodes) {
            # warn("child of entity ref: " . $kid->getType() . " called: " . $kid->getName . "\n");
            process_node($handler, $kid, $encoding);
        }
    }
    elsif ($node_type == XML_DOCUMENT_NODE) {
        # just get root element. Ignore other cruft.
        foreach my $kid ($node->getChildnodes) {
            if ($kid->getType() == XML_ELEMENT_NODE) {
                process_element($handler, $kid, $encoding);
                last;
            }
        }
    }
    elsif ($node_type == XML_XINCLUDE_START || $node_type == XML_XINCLUDE_END) {
            # ignore
    }
    else {
        warn("unknown node type: $node_type");
    }
}

sub process_element {
    my ($handler, $element, $encoding) = @_;

    my @attr;
    my $debug = $handler->{XSP_Debug};

    foreach my $attr ($element->getAttributes) {
        my $lineno = eval { $attr->lineNumber; } if $debug;
        if ($attr->getName) {
            push @attr, {
                Name => encodeToUTF8($encoding,$attr->getName),
                Value => encodeToUTF8($encoding,$attr->getData),
                NamespaceURI => encodeToUTF8($encoding,$attr->getNamespaceURI),
                Prefix => encodeToUTF8($encoding,$attr->getPrefix),
                LocalName => encodeToUTF8($encoding,$attr->getLocalName),
                LineNumber => $lineno,
            };
        }
        else {
            push @attr, {
                Name => "xmlns",
                Value => "",
                NamespaceURI => "",
                Prefix => "",
                LocalName => "",
                LineNumber => $lineno,
            };
        }
    }
    
    no warnings 'uninitialized';
    my $lineno = eval { $element->lineNumber; } if $debug;
    my $node = {
        Name => encodeToUTF8($encoding,$element->getName),
        Attributes => \@attr,
        NamespaceURI => encodeToUTF8($encoding,$element->getNamespaceURI),
        Prefix => encodeToUTF8($encoding,$element->getPrefix),
        LocalName => encodeToUTF8($encoding,$element->getLocalName),
        LineNumber => $lineno,
    };

    $handler->start_element($node);

    foreach my $child ($element->getChildnodes) {
        process_node($handler, $child, $encoding);
    }

    $handler->end_element($node);
}

############################################################
# Base page class
############################################################

package AxKit2::Transformer::XSP::Page;
use Exporter ();
@AxKit2::Transformer::XSP::Page::ISA = qw(Exporter);
@AxKit2::Transformer::XSP::Page::EXPORT_OK = 
  qw(
      __mk_expr_node
      __mk_text_node
      __mk_element_node
      __mk_comment_node
      __mk_ns_element_node
  );

sub has_changed {
    my $class = shift;
    my $mtime = shift;
    return 1;
}

sub cache_params {
    my $class = shift;
    my ($r, $cgi) = @_;
    return '';
}

sub handler {
    my $class = shift;
    $class->xml_generator(@_);
}

sub __mk_text_node {
    my ($document, $parent, $text) = @_;
    my $node = $document->createTextNode($text);
    $parent->appendChild($node);
}

sub __mk_expr_node {
    my ($document, $parent, $as_xml, @data) = @_;
    for my $data (@data) {
        if ($as_xml) {
            $parent->appendWellBalancedChunk($data);
            return;
        }
        
        if (my $ref = ref($data)) {
            if ($ref eq 'ARRAY') {
                my $i = 0;
                for my $item (@$data) {
                    my $node = $document->createElement('item');
                    $node->setAttribute('idx' => $i++);
                    __mk_expr_node($document, $node, $as_xml, $item);
                    $parent->appendChild($node);
                }
            }
            elsif ($ref eq 'HASH') {
                for my $k (keys %$data) {
                    my $item = $data->{$k};
                    my $node;
                    if ($k =~ s/^(.*?)://) {
                        my $prefix = $1;
                        my $uri = $parent->lookupNamespaceURI($prefix)
                            || die "No namespace URI for prefix '$prefix'";
                        $node = $document->createElementNS($uri, $k);
                    }
                    else {
                        $node = $document->createElement($k);
                    }
                    __mk_expr_node($document, $node, $as_xml, $item);
                    $parent->appendChild($node);
                }
            }
            else {
                die "expr can't yet handle ref type: $ref";
            }
        }
        else {
            # we stringify here to make sure we don't pass undef in.
            my $node = $document->createTextNode("$data");
            $parent->appendChild($node);
        }
    }
}

sub __mk_element_node {
    my ($document, $parent, $name) = @_;
    if ($name =~ s/^(.*?)://) {
        my $prefix = $1;
        my $uri = $parent->lookupNamespaceURI($prefix)
            || die "No namespace URI for prefix '$prefix'";
        return __mk_ns_element_node($document, $parent, $uri, $name);
    }
    my $elem = $document->createElement($name);
    if ($parent) {
        $parent->appendChild($elem);
    }
    else {
        $document->setDocumentElement($elem);
    }
    return $elem;
}

sub __mk_ns_element_node {
    my ($document, $parent, $ns, $name) = @_;
    my $elem = $document->createElementNS($ns, $name);
    if ($parent) {
        $parent->appendChild($elem);
    }
    else {
        $document->setDocumentElement($elem);
    }
    return $elem;
}

sub __mk_comment_node {
    my ($document, $parent, $text) = @_;
    my $node = $document->createComment($text);
    $parent->appendChild($node);
}

1;

__END__
=pod

=head1 NAME

AxKit2::Transformer::XSP - eXtensible Server Pages

=head1 SYNOPSIS

  <xsp:page
    xmlns:xsp="http://apache.org/xsp/core/v1">

    <xsp:structure>
        <xsp:import>Time::Piece</xsp:import>
    </xsp:structure>

    <page>
        <title>XSP Test</title>
        <para>
        Hello World!
        </para>
        <para>
        Good 
        <xsp:logic>
        if (localtime->hour >= 12) {
            <xsp:content>Afternoon</xsp:content>
        }
        else {
            <xsp:content>Morning</xsp:content>
        }
        </xsp:logic>
        </para>
    </page>
    
  </xsp:page>

=head1 DESCRIPTION

XSP implements a tag-based dynamic language that allows you to develop
your own tags, examples include sendmail and sql taglibs. It is AxKit's
way of providing an environment for dynamic pages. XSP is originally part
of the Apache Cocoon project, and so you will see some Apache namespaces
used in XSP.

Also, use only one XSP processor in a pipeline.  XSP is powerful enough
that you should only need one stage, and this implementation allows only
one stage.  If you have two XSP processors, perhaps in a pipeline that
looks like:

    ... => XSP => XSLT => XSLT => XSP => ...

it is pretty likely that the functionality of the intermediate XSLT
stages can be factored in to either upstream or downstream XSLT:

    ... => XSLT => XSP => XSLT => ...

This design is likely to lead to a clearer and more maintainable
implementation, if only because generating code, especially embedded
Perl code, in one XSP processor and consuming it in another is often
confusing and even more often a symptom of misdesign.

Likewise, you may want to lean towards using Perl taglib modules instead
of upstream XSLT "LogicSheets".  Upstream XSLT LogicSheets work fine,
mind you, but using Perl taglib modules results in a simpler pipeline,
simpler configuration (just load the taglib modules in httpd.conf, no
need to have the correct LogicSheet XSLT page included whereever you
need that taglib), a more flexible coding environment, the ability to
pretest your taglibs before installing them on a server, and better
isolation of interface (the taglib API) and implementation (the Perl
module behind it).  LogicSheets work, and can be useful, but are often
the long way home.  That said, people used to the Cocoon environment may
prefer them.

=head2 Result Code

You can specify the result code of the request in two ways. Both actions
go inside a <xsp:logic> tag.

If you want to completely abort the current request, throw an exception:

    throw Apache::AxKit::Exception::Retval(return_code => FORBIDDEN);

If you want to send your page but have a custom result code, return it:

    return FORBIDDEN;

In that case, only the part of the document that was processed so far gets
sent/processed further.

=head2 Debugging

If you have PerlTidy installed (get it from L<http://perltidy.sourceforge.net>),
the compiled XSP scripts can be formatted nicely to spot errors easier. Enable
AxDebugTidy for this, but be warned that reformatting is quite slow, it can
take 20 seconds or more I<on each XSP run> for large scripts.

If you enable AxTraceIntermediate, your script will be dumped alongside the
other intermediate files, with an extension of ".XSP". These are unnumbered,
thus only get one dump per request. If you have more than one XSP run in a
single request, the last one will overwrite the dumps of earlier runs.

=head1 Tag Reference

=head2 C<< <xsp:page> >>

This is the top level element, although it does not have to be. AxKit's
XSP implementation can process XSP pages even if the top level element
is not there, provided you use one of the standard AxKit ways to turn
on XSP processing for that page. See L<AxKit>.

The attribute C<language="Perl"> can be present, to mandate the language.
This is useful if you expect people might mistakenly try and use this
page on a Cocoon system. The default value of this attribute is "Perl".

XSP normally swallows all whitespace in your output. If you don't like
this feature, or it creates invalid output, then you can add the
attribute: C<indent-result="yes">

By default all non-XSP and non-taglib attributes are interpolated in
a similar way to XSLT attributes - by checking for C<{ code }> in the
attributes. The C<code> can be any perl code, and is treated exactly
the same as having an C<< <xsp:expr>code</xsp:expr> >> in the
attribute value. In order to turn this I<off>, simply specify the
attribute C<attribute-value-interpolate="no">. The default is C<yes>
which enables the interpolation.

=head2 C<< <xsp:structure> >>

  parent: <xsp:page>

This element appears at the root level of your page before any non-XSP
tags. It defines page-global "things" in the C<<xsp:logic>> and
C<<xsp:import>> tags.

=head2 C<< <xsp:import> >>

  parent: <xsp:structure>

Use this tag for including modules into your code, for example:

  <xsp:structure>
    <xsp:import>DBI</xsp:import>
  </xsp:structure>

=head2 C<< <xsp:logic> >>

  parent: <xsp:structure>, any

The C<<xsp:logic>> tag introduces some Perl code into your page.

As a child of C<<xsp:structure>>, this element allows you to define
page global variables, or functions that get used in the page. Placing
functions in here allows you to get around the Apache::Registry
closures problem (see the mod_perl guide at http://perl.apache.org/guide
for details).

Elsewhere the perl code contained within the tags is executed on every
view of the XSP page.

B<Warning:> Be careful - the Perl code contained within this tag is still
subject to XML's validity constraints. Most notably to Perl code is that
the & and < characters must be escaped into &amp; and &lt; respectively.
You can get around this to some extent by using CDATA sections. This is
especially relevant if you happen to think something like this will work:

  <xsp:logic>
    if ($some_condition) {
      print "<para>Condition True!</para>";
    }
    else {
      print "<para>Condition False!</para>";
    }
  </xsp:logic>

The correct way to write that is simply:

  <xsp:logic>
    if ($some_condition) {
      <para>Condition True!</para>
    }
    else {
      <para>Condition False!</para>
    }
  </xsp:logic>

The reason is that XSP intrinsically knows about XML!

=head2 C<< <xsp:content> >>

  parent: <xsp:logic>

This tag allows you to temporarily "break out" of logic sections to generate
some XML text to go in the output. Using something similar to the above
example, but without the surrounding C<<para>> tag, we have:

  <xsp:logic>
    if ($some_condition) {
      <xsp:content>Condition True!</xsp:content>
    }
    else {
      <xsp:content>Condition False!</xsp:content>
    }
  </xsp:logic>

=head2 C<< <xsp:element> >>

This tag generates an element of name equal to the value in the attribute
C<name>. Alternatively you can use a child element C<<xsp:name>> to specify
the name of the element. Text contents of the C<<xsp:element>> are created
as text node children of the new element.

=head2 C<< <xsp:attribute> >>

Generates an attribute. The name of the attribute can either be specified
in the C<name="..."> attribute, or via a child element C<<xsp:name>>. The
value of the attribute is the text contents of the tag.

=head2 C<< <xsp:comment> >>

Normally XML comments are stripped from the output. So to add one back in
you can use the C<<xsp:comment>> tag. The contents of the tag are the
value of the comment.

=head2 C<< <xsp:text> >>

Create a plain text node. The contents of the tag are the text node to be
generated. This is useful when you wish to just generate a text node while
in an C<<xsp:logic>> section.

=head2 C<< <xsp:expr> >>

This is probably the most useful, and most important (and also the most
complex) tag. An expression is some perl code that executes, and the results
of which are added to the output. Exactly how the results are added to the
output depends very much on context.

The default method for output for an expression is as a text node. So for
example:

  <p>
  It is now: <xsp:expr>localtime</xsp:expr>
  </p>

Will generate a text node containing the time.

If the expression is contained within an XSP namespaces, that is either a
tag in the xsp:* namespace, or a tag implementing a tag library, then an
expression generally does not create a text node, but instead is simply
wrapped in a Perl C<do {}> block, and added to the perl script. However,
there are anti-cases to this. For example if the expression is within
a C<<xsp:content>> tag, then a text node is created.

Needless to say, in every case, C<<xsp:expr>> should just "do the right
thing". If it doesn't, then something (either a taglib or XSP.pm itself)
is broken and you should report a bug.

=head1 Writing Taglibs

Writing your own taglibs can be tricky, because you're using an event
based API to write out Perl code. You may want to take a look at the
AxKit2::Transformer::XSP::TaglibHelper module, which comes with
AxKit and allows you to easily publish a taglib without writing
XML event code. Recently, another taglib helper has been developed,
AxKit2::Transformer::XSP::SimpleTaglib. The latter manages all the
details described under 'Design Patterns' for you, so you don't really
need to bother with them anymore.

A warning about character sets: All string values are passed in and
expected back as UTF-8 encoded strings. So you cannot use national characters
in a different encoding, like the widespread ISO-8859-1. This applies to
Taglib source code only. The XSP XML-source is of course interpreted according
to the XML rules. Your taglib module may want to 'use utf8;' as well, see
L<perlunicode> and L<utf8> for more information.

=head1 Design Patterns


These patterns represent the things you may want to achieve when 
authoring a tag library "from scratch".

=head2 1. Your tag is a wrapper around other things.

Example:

  <mail:sendmail>...</mail:sendmail>

Solution:

Start a new block, so that you can store lexical variables, and declare
any variables relevant to your tag:

in parse_start:

  if ($tag eq 'sendmail') {
    return '{ my ($to, $from, $sender);';
  }

Often it will also be relevant to execute that code when you see the end
tag:

in parse_end:

  if ($tag eq 'sendmail') {
    return 'Mail::Sendmail::sendmail( 
            to => $to, 
            from => $from, 
            sender => $sender 
            ); }';
  }

Note there the closing of that original opening block.

=head2 2. Your tag indicates a parameter for a surrounding taglib.

Example:

  <mail:to>...</mail:to>

Solution:

Having declared the variable as above, you simply set it to the empty
string, with no semi-colon:

in parse_start:

  if ($tag eq 'to') {
    return '$to = ""';
  }

Then in parse_char:

sub parse_char {
  my ($e, $text) = @_;
  $text =~ s/^\s*//;
  $text =~ s/\s*$//;

  return '' unless $text;

  $text = AxKit2::Transformer::XSP::makeSingleQuoted($text);
  return ". $text";
}

Note there's no semi-colon at the end of all this, so we add that:

in parse_end:

  if ($tag eq 'to') {
    return ';';
  }

All of this black magic allows other taglibs to set the thing in that
variable using expressions.

=head2 3. You want your tag to return a scalar (string) that does the right thing
depending on context. 

For example, generates a Text node in one place or generates a scalar in another 
context.

Solution:

use $e->start_expr(), $e->append_to_script(), $e->end_expr().

Example:

  <example:get-datetime format="%Y-%m-%d %H:%M:%S"/>

in parse_start:

  if ($tag eq 'get-datetime') {
    $e->start_expr($tag); # creates a new { ... } block
    my $local_format = lc($attribs{format}) || '%a, %d %b %Y %H:%M:%S %z';
    return 'my ($format); $format = q|' . $local_format . '|;';
  }

in parse_end:

  if ($tag eq 'get-datetime') {
    $e->append_to_script('use Time::Piece; localtime->strftime($format);');
    $e->end_expr();
    return '';
  }

Explanation:

This is more complex than the first 2 examples, so it warrants some 
explanation. I'll go through it step by step.

  $e->start_expr($tag)

This tells XSP that this really generates a <xsp:expr> tag. Now we don't
really generate that tag, we just execute the handler for it. So what
happens is the <xsp:expr> handler gets called, and it looks to see what
the current calling context is. If its supposed to generate a text node,
it generates some code to do that. If its supposed to generate a scalar, it
does that too. Ultimately both generate a do {} block, so we'll summarise 
that by saying the code now becomes:

  do {

(the end of the block is generated by end_expr()).

Now the next step (ignoring the simple gathering of the format variable), is
a return, which appends more code onto the generated perl script, so we
get:

  do {
    my ($format); $format = q|%a, %d %b %Y %H:%M:%S %z|;

Now we immediately receive an end_expr, because this is an empty element
(we'll see why we formatted it this way in #5 below). The first thing we
get is:

  $e->append_to_script('use Time::Piece; localtime->strftime($format);');

This does exactly what it says, and the script becomes:

  do {
    my ($format); $format = q|%a, %d %b %Y %H:%M:%S %z|;
    use Time::Piece; localtime->strftime($format);

Finally, we call:

  $e->end_expr();

which closes the do {} block, leaving us with:

  do {
    my ($format); $format = q|%a, %d %b %Y %H:%M:%S %z|;
    use Time::Piece; localtime->strftime($format);
  }

Now if you execute that in Perl, you'll see the do {} returns the last
statement executed, which is the C<localtime->strftime()> bit there,
thus doing exactly what we wanted.

=head2 4. Your tag can take as an option either an attribute, or a child tag.

Example:

  <util:include-uri uri="http://server/foo"/>

or

  <util:include-uri>
    <util:uri><xsp:expr>$some_uri</xsp:expr></util:uri>
  </util:include-uri>

Solution:

There are several parts to this. The simplest is to ensure that whitespace
is ignored. We have that dealt with in the example parse_char above. Next
we need to handle that variable. Do this by starting a new block with the
tag, and setting up the variable:

in parse_start:

  if ($tag eq 'include-uri') {
    my $code = '{ my ($uri);';
    if ($attribs{uri}) {
      $code .= '$uri = q|' . $attribs{uri} . '|;';
    }
    return $code;
  }

Now if we don't have the attribute, we can expect it to come in the 
C<<util:uri>> tag:

in parse_start:

  if ($tag eq 'uri') {
    return '$uri = ""'; # note the empty string!
  }

Now you can see that we're not explicitly setting C<$uri>, that's because the
parse_char we wrote above handles it by returning '. q|$text|'. And if we
have a C<<xsp:expr>> in there, that's handled automagically too.

Now we just need to wrap things up in the end handlers:

in parse_end:

  if ($tag eq 'uri') {
    return ';';
  }
  if ($tag eq 'include-uri') {
    return 'Taglib::include_uri($uri); # execute the code
            } # close the block
    ';
  }

=head2 5. You want to return a scalar that does the right thing in context, but also can take a parameter as an attribute I<or> a child tag.

Example:

  <esql:get-column column="user_id"/>

vs

  <esql:get-column>
    <esql:column><xsp:expr>$some_column</xsp:expr></esql:column>
  </esql:get-column>

Solution:

This is a combination of patterns 3 and 4. What we need to do is change
#3 to simply allow our variable to be added as in #4 above:

in parse_start:

  if ($tag eq 'get-column') {
    $e->start_expr($tag);
    my $code = 'my ($col);'
    if ($attribs{col}) {
      $code .= '$col = q|' . $attribs{col} . '|;';
    }
    return $code;
  }
  if ($tag eq 'column') {
    return '$col = ""';
  }

in parse_end:

  if ($tag eq 'column') {
    return ';';
  }
  if ($tag eq 'get-column') {
    $e->append_to_script('Full::Package::get_column($col)');
    $e->end_expr();
    return '';
  }

=head2 6. You have a conditional tag

Example:

  <esql:no-results>
    No results!
  </esql:no-results>

Solution:

The problem here is that taglibs normally recieve character/text events
so that they can manage variables. With a conditional tag, you want
character events to be handled by the core XSP and generate text events.
So we have a switch for that:

  if ($tag eq 'no-results') {
    $e->manage_text(0);
    return 'if (AxKit2::XSP::ESQL::get_count() == 0) {';
  }

Turning off manage_text with a zero simply ensures that immediate children
text nodes of this tag don't fire text events to the tag library, but
instead get handled by XSP core, thus creating text nodes (and doing
the right thing, generally).

=head2 <xsp:expr> (and start_expr, end_expr) Notes

B<Do not> consider adding in the 'do {' ... '}' bits yourself. Always
leave this to the start_expr, and end_expr functions. This is because the
implementation could change, and you really don't know better than
the underlying XSP implementation. You have been warned.

=cut

1;
