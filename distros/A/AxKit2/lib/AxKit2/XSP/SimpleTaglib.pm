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

# Apache::AxKit::XSP::Language::SimpleTaglib - alternate taglib helper code
package AxKit2::XSP::SimpleTaglib;
require 5.006;
use strict;
use base 'AxKit2::Transformer::XSP';
use Data::Dumper;
eval { require WeakRef; };
eval { require XML::Smart; };
use attributes;
our $VERSION = 0.3;

# utility functions

sub makeSingleQuoted($) { $_ = shift; s/([\\%])/\\$1/g; 'q%'.$_.'%'; }
sub _makeAttributeQuoted(@) { $_ = join(',',@_); s/([\\()])/\\$1/g; '('.$_.')'; }
sub makeVariableName($) { $_ = shift; s/[^a-zA-Z0-9]/_/g; $_; }

my $dumper = new Data::Dumper([]);
$dumper->Quotekeys(0);
$dumper->Terse(1);
$dumper->Indent(0);

# perl attribute handlers

my %handlerAttributes;

use constant PLAIN => 0;
use constant EXPR => 1;
use constant EXPRORNODE => 2;
use constant NODE => 3;
use constant EXPRORNODELIST => 4;
use constant NODELIST => 5;
use constant STRUCT => 6;

# Memory leak ahead! The '&' construct may create circular references, which perl
# can't clean up. But this has only an effect if a taglib is reloaded, which shouldn't
# happen on production machines. Moreover, '&' is rather unusual.
# If you have the WeakRef module installed, this warning does not apply.
sub parseChildStructSpec {
    my ($specs, $refs) = @_;
    for my $spec ($_[0]) {
        my $result = {};
        while (length($spec)) {
            $spec = substr($spec,1), return $result if (substr($spec,0,1) eq '}');
            (my ($type, $token, $next) = ($spec =~ m/^([!\&\@\*\$]?)([^ {}]+)(.|$)/))
                 || die("childStruct specification invalid. Parse error at: '$spec'");
            substr($spec,0,length($token)+1+($type?1:0)) = '';
            #warn("type: $type, token: $token, next: $next, spec: $spec");
            my ($realtoken, $params);
            if ((($realtoken,$params) = ($token =~ m/^([^\(]+)((?:\([^ \)]+\))+)$/))) {
                my $i = 0;
                $token = $realtoken;
                $$result{$token}{'param'} = { map { $_ => $i++ } ($params =~ m/\(([^ )]+)\)/g) };
            }
            if ($type eq '&') {
                ($$result{$token} = $$refs{$token})
                    || die("childStruct specification invalid. '&' reference not found.");
                die("childStruct specification invalid. '&' cannot be used on '*' nodes.")
                    if ($$result{$token}{'type'} eq '*');
                die("childStruct specification invalid. '&' may only take a reference.")
                    if $$result{'param'};
                eval { WeakRef::weaken($$result{$token}) };
                return $result if (!$next || $next eq '}');
                next;
            }
            $$result{$token}{'type'} = $type || '$';
            die("childStruct specification invalid. '${type}' cannot be used with '{'.")
                if ($next eq '{' and ($type eq '*' || $type eq '!'));
            die("childStruct specification invalid. '${type}' cannot be used with '(,,,)'.")
                if ($$result{$token}{'param'} and ($type eq '*' || $type eq '!'));
            die("childStruct specification invalid. '**' is not supported.")
                if ($token eq '*' and $type eq '*');
            $$result{''}{'name'} = $token if ($type eq '*');
            $$result{$token}{'name'} = $token;
            return $result if (!$next || $next eq '}');
            ($$result{$token}{'sub'} = parseChildStructSpec($spec, { %$refs, $token => $$result{$token} })) || return undef if $next eq '{';
        }
        return $result;
    }
}

sub serializeChildStructSpec {
    my ($struct, $refs) = @_;
    my $result = '';
    my $first = 1;
    foreach my $token (keys %$struct) {
        next unless length($token);
        $result .= ' ' unless $first;
        undef $first;
        if (exists $$refs{$$struct{$token}}) {
            $result .= '&'.$token;
            next;
        }
        $result .= $$struct{$token}{'type'};
        $result .= $token;
        if (exists $$struct{$token}{'param'}) {
            my %keys = reverse %{$$struct{$token}{'param'}};
            $result .= '('.join(')(',@keys{0..(scalar(%keys)-1)}).')'
        }
        $result .= '{'.serializeChildStructSpec($$struct{$token}{'sub'},{ %$refs, $$struct{$token} => undef }).'}'
            if exists $$struct{$token}{'sub'};
    }
    return $result;
}

sub MODIFY_CODE_ATTRIBUTES {
    my ($pkg,$sub,@attr) = @_;
    return unless defined $sub;
    my @rest;
    $handlerAttributes{$sub} ||= {};
    my $handlerAttributes = $handlerAttributes{$sub};
    foreach my $a (@attr) {
        #warn("attr: $a");
        my ($attr,$param) = ($a =~ m/([^(]*)(?:\((.*)\))?$/);
        my $warn = 0;
        $attr =~ s/^XSP_// || $warn++;
        $param = (defined $param?eval "q($param)":"");
        my @param = split(/,/,$param);

        if ($attr eq 'expr') {
            $$handlerAttributes{'result'} = EXPR;
        } elsif ($attr eq 'node') {
            $$handlerAttributes{'result'} = NODE;
            $$handlerAttributes{'nodename'} = $param[0] || 'value';
        } elsif ($attr eq 'exprOrNode') {
            $$handlerAttributes{'result'} = EXPRORNODE;
            $$handlerAttributes{'nodename'} = $param[0] || 'value';
            $$handlerAttributes{'resultparam'} = $param[1] || 'as';
            $$handlerAttributes{'resultnode'} = $param[2] || 'node';
        } elsif ($attr eq 'nodelist') {
            $$handlerAttributes{'result'} = NODELIST;
            $$handlerAttributes{'nodename'} = $param[0] || 'value';
        } elsif ($attr eq 'exprOrNodelist') {
            $$handlerAttributes{'result'} = EXPRORNODELIST;
            $$handlerAttributes{'nodename'} = $param[0] || 'value';
            $$handlerAttributes{'resultparam'} = $param[1] || 'as';
            $$handlerAttributes{'resultnode'} = $param[2] || 'node';
        } elsif ($attr eq 'struct') {
            $$handlerAttributes{'result'} = STRUCT;
            $$handlerAttributes{'namespace'} = $param[0];
        } elsif ($attr eq 'stack') {
            $$handlerAttributes{'stack'} = $param[0];
        } elsif ($attr eq 'smart') {
            $$handlerAttributes{'smart'} = 1;
            $$handlerAttributes{'capture'} = 1;
        } elsif ($attr eq 'nodeAttr') {
            my %namespace;
            while (@param > 1) {
                my ($ns, $prefix, $name) = parse_namespace($param[0]);
                $namespace{$prefix} = $ns if $ns and $prefix;
                $param[0] = "{$namespace{$prefix}}$prefix:$name" if $prefix;
                $$handlerAttributes{'resultattr'}{$param[0]} = $param[1];
                shift @param; shift @param;
            }
        } elsif ($attr eq 'attrib') {
            foreach my $param (@param) {
                $$handlerAttributes{'attribs'}{$param} = undef;
            }
        } elsif ($attr eq 'child') {
            foreach my $param (@param) {
                $$handlerAttributes{'children'}{$param} = undef;
            }
        } elsif ($attr eq 'attribOrChild') {
            foreach my $param (@param) {
                $$handlerAttributes{'attribs'}{$param} = undef;
                $$handlerAttributes{'children'}{$param} = undef;
            }
        } elsif ($attr eq 'childStruct') {
            my $spec = $param[0];
            #warn("parsing $spec");
            $spec =~ s/\s+/ /g;
            $spec =~ s/ ?{ ?/{/g;
            $spec =~ s/ ?} ?/}/g;
            $$handlerAttributes{'struct'} = parseChildStructSpec($spec,{});
            #warn("parsed $param[0], got ".serializeChildStructSpec($$handlerAttributes{'struct'}));
            die("childStruct parse error") unless $$handlerAttributes{'struct'};
        } elsif ($attr eq 'keepWhitespace') {
            $$handlerAttributes{'keepWS'} = 1;
        } elsif ($attr eq 'captureContent') {
            $$handlerAttributes{'capture'} = 1;
        } elsif ($attr eq 'compile') {
            $$handlerAttributes{'compile'} = 1;
        } elsif ($attr eq 'XSP' && $warn) {
            $warn = 0;
            $$handlerAttributes{'xsp'} = 1;
        } else {
            push @rest, $a;
            $warn = 0;
        }
        warn("Please prefix your XSP attributes with 'XSP_' (${pkg}::${sub} : $attr)") if $warn;
    }
    delete $handlerAttributes{$sub} if not keys %$handlerAttributes;
    return @rest;
}

sub FETCH_CODE_ATTRIBUTES {
    my ($pkg,$sub) = @_;
    my @attr;
    my $handlerAttributes = $handlerAttributes{$sub};
    return () if !defined $handlerAttributes;
    if (exists $$handlerAttributes{'result'}) {
        if ($$handlerAttributes{'result'} == NODELIST) {
            push @attr, 'XSP_nodelist'._makeAttributeQuoted($$handlerAttributes{'nodename'});
        } elsif ($$handlerAttributes{'result'} == EXPRORNODELIST) {
            push @attr, 'XSP_exprOrNodelist'._makeAttributeQuoted($$handlerAttributes{'nodename'},$$handlerAttributes{'resultparam'},$$handlerAttributes{'resultnode'});
        } elsif ($$handlerAttributes{'result'} == NODE) {
            push @attr, 'XSP_node'._makeAttributeQuoted($$handlerAttributes{'nodename'});
        } elsif ($$handlerAttributes{'result'} == EXPRORNODE) {
            push @attr, 'XSP_exprOrNode'._makeAttributeQuoted($$handlerAttributes{'nodename'},$$handlerAttributes{'resultparam'},$$handlerAttributes{'resultnode'});
        } elsif ($$handlerAttributes{'result'} == EXPR) {
            push @attr, 'XSP_expr';
        } elsif ($$handlerAttributes{'result'} == STRUCT) {
            push @attr, 'XSP_struct';
            $attr[-1] .= _makeAttributeQuoted($$handlerAttributes{'namespace'})
              if defined $$handlerAttributes{'namespace'};
        }
    }
    push @attr, 'XSP_nodeAttr'._makeAttributeQuoted(%{$$handlerAttributes{'resultattr'}}) if $$handlerAttributes{'resultattr'};
    push @attr, 'XSP_stack'._makeAttributeQuoted($$handlerAttributes{'stack'}) if $$handlerAttributes{'stack'};
    push @attr, 'XSP_smart' if $$handlerAttributes{'smart'};
    push @attr, 'XSP_keepWhitespace' if $$handlerAttributes{'keepWS'};
    push @attr, 'XSP_captureContent' if $$handlerAttributes{'capture'};
    push @attr, 'XSP_compile' if $$handlerAttributes{'compile'};

    push @attr, 'XSP_childStruct'._makeAttributeQuoted(serializeChildStructSpec($$handlerAttributes{'struct'},{}))
        if ($$handlerAttributes{'struct'});

    my (@attribs, @children, @both);
    foreach my $param (keys %{$$handlerAttributes{'attribs'}}) {
        if (exists $$handlerAttributes{'children'}{$param}) {
            push @both, $param;
        } else {
            push @attribs, $param;
        }
    }
    foreach my $param (keys %{$$handlerAttributes{'children'}}) {
        if (!exists $$handlerAttributes{'attribs'}{$param}) {
            push @children, $param;
        }
    }
    push @attr, 'XSP_attrib'._makeAttributeQuoted(@attribs) if @attribs;
    push @attr, 'XSP_child'._makeAttributeQuoted(@children) if @children;
    push @attr, 'XSP_attribOrChild'._makeAttributeQuoted(@both) if @both;
    push @attr, 'XSP' if !@attr;
    return @attr;
}

sub import {
    my $pkg = caller;
    #warn("making $pkg a SimpleTaglib");
    {
        no strict 'refs';
        *{$pkg.'::Handlers::MODIFY_CODE_ATTRIBUTES'} = \&MODIFY_CODE_ATTRIBUTES;
        *{$pkg.'::Handlers::FETCH_CODE_ATTRIBUTES'} = \&FETCH_CODE_ATTRIBUTES;
        push @{$pkg.'::ISA'}, 'AxKit2::XSP::SimpleTaglib';

    }
    return undef;
}

# companions to start_expr

sub start_expr {
    my $e = shift;
    my $cur = $e->{Current_Element};
    my $rc = $e->start_expr(@_);
    $e->{Current_Element} = $cur;
    return $rc;
}

sub start_elem {
    my ($e, $nodename, $attribs, $default_prefix, $default_ns) = @_;
    my($ns, $prefix, $name) = parse_namespace($nodename);
    #$prefix = $e->generate_nsprefix($ns) if $ns and not $prefix;
    if (not defined $ns and not defined $prefix) {
        $ns = $default_ns; $prefix = $default_prefix;
    }
    $name = $prefix.':'.$name if $prefix;
    if ($ns) {
        $e->append_to_script('{ my $elem = $document->createElementNS('.makeSingleQuoted($ns).','.makeSingleQuoted($name).');');
    }
    else {
        $e->append_to_script('{ my $elem = $document->createElement('.makeSingleQuoted($name).');');
    }
    $e->append_to_script('$parent->appendChild($elem); $parent = $elem; }' . "\n");
    if ($attribs) {
        while (my ($key, $value) = each %$attribs) {
            start_attr($e, $key); $e->append_to_script('.'.$value); end_attr($e);
        }
    }
    $e->manage_text(0);
}

sub end_elem {
    my ($e) = @_;
    $e->append_to_script('$parent = $parent->getParentNode;'."\n");
}

sub start_attr {
    my ($e, $attrname, $default_prefix, $default_ns) = @_;
    my($ns, $prefix, $name) = parse_namespace($attrname);
    #$prefix = $e->generate_nsprefix($ns) if $ns and not $prefix;
    if (not defined $ns and not defined $prefix) {
        $ns = $default_ns; $prefix = $default_prefix;
    }
    $name = $prefix.':'.$name if $prefix;

    if ($ns and defined $prefix) {
        $e->append_to_script('$parent->setAttributeNS('.makeSingleQuoted($ns).','.makeSingleQuoted($name).', ""');
    }
    else {
        $e->append_to_script('$parent->setAttribute('.makeSingleQuoted($name).', ""');
    }
    $e->manage_text(0);
}

sub end_attr {
    my ($e) = @_;
    $e->append_to_script(');'."\n");
}

# global variables
# FIXME - put into $e (are we allowed to?)

my %structStack = ();
my %frame = ();
my @globalframe = ();
my $structStack;
my %stacklevel = ();
my %stackcur = ();

# generic tag handler subs

sub set_attribOrChild_value__open {
    my ($e, $tag) = @_;
    $globalframe[0]{'capture'} = 1;
    return '$attr_'.makeVariableName($tag).' = ""';
}

sub set_attribOrChild_value : XSP_keepWhitespace {
    return '; ';
}

my @ignore;
sub set_childStruct_value__open {
    my ($e, $tag, %attribs) = @_;
    my $var = '$_{'.makeSingleQuoted($tag).'}';
    if ($$structStack[0][0]{'param'} && exists $$structStack[0][0]{'param'}{$tag}) {
        $e->append_to_script('.do { $param_'.$$structStack[0][0]{'param'}{$tag}.' = ""');
        $globalframe[0]{'capture'} = 1;
        return '';
    }
    my $desc = $$structStack[0][0]{'sub'}{$tag};
    if (!$desc) {
        $desc = $$structStack[0][0]{'sub'}{'*'};
        #warn("$tag desc: ".Data::Dumper::Dumper($desc));
    }
    die("Tag $tag not found in childStruct specification.") if (!$desc);
    push(@ignore, 1), return '' if ($$desc{'type'} eq '!');
    push @ignore, 0;
    unshift @{$$structStack[0]},$desc;
    if ($$desc{'param'}) {
        $e->append_to_script("{ \n");
        foreach my $key (keys %{$$desc{'param'}}) {
            $_ = $$desc{'param'}{$key};
            $e->append_to_script("my \$param_$_; ");
            $e->append_to_script("\$param_$_ = ".makeSingleQuoted($attribs{$key}).'; ')
                if exists $attribs{$key};
        }
        $e->append_to_script('local ($_) = ""; ');
        $var = '$_';
    }
    if ($$desc{'type'} eq '@') {
        $e->append_to_script("$var ||= []; push \@{$var}, ");
    } else {
        $e->append_to_script("$var = ");
    }
    if ($$desc{'sub'}) {
        $e->append_to_script('do {');
        $e->append_to_script('local (%_) = (); ');
        foreach my $attrib (keys %attribs) {
            next if $$desc{'sub'}{$attrib}{'type'} eq '%';
            $e->append_to_script('$_{'.makeSingleQuoted($attrib).'} = ');
            $e->append_to_script('[ ') if $$desc{'sub'}{$attrib}{'type'} eq '@';
            $e->append_to_script(makeSingleQuoted($attribs{$attrib}));
            $e->append_to_script(' ]') if $$desc{'sub'}{$attrib}{'type'} eq '@';
            $e->append_to_script('; ');
        }
        my $textname = $$desc{'sub'}{''}{'name'};
        if ($textname) {
            $e->append_to_script(' $_{'.makeSingleQuoted($textname).'} = ""');
            $globalframe[0]{'capture'} = 1;
        }
    } else {
        $e->append_to_script('""');
        $globalframe[0]{'capture'} = 1;
    }
    return '';
}

sub set_childStruct_value {
    my ($e, $tag) = @_;
    if ($$structStack[0][0]{'param'} && exists $$structStack[0][0]{'param'}{$tag}) {
        $e->append_to_script('; }');
        return '';
    }
    my $desc = $$structStack[0][0];
    my $ignore = pop @ignore;
    return '' if ($ignore);
    shift @{$$structStack[0]};
    if ($$desc{'sub'}) {
        $e->append_to_script(' \%_; }; ');
    }
    if ($$desc{'param'}) {
        my $var = '$_{'.makeSingleQuoted($tag).'}';
        for (0..(scalar(%{$$desc{'param'}})-1)) {
            $var .= "{\$param_$_}";
        }
        if ($$desc{'type'} eq '@') {
            $e->append_to_script("$var ||= []; push \@{$var}, \@{\$_};");
        } else {
            $e->append_to_script("$var = \$_;");
        }
        $e->append_to_script(" }\n");
    }
    return '';
}

sub set_XmlSmart_value__open {
    my ($e, $tag, %attribs) = @_;
    $dumper->Values([\%attribs]);
    return 'XML::Smart::Tree::_Start($xml_subtree_parser,'.makeSingleQuoted($tag).','.$dumper->Dumpxs().');'."\n";
}

sub set_XmlSmart_value : XSP_captureContent {
    my ($e, $tag) = @_;
    return 'XML::Smart::Tree::_Char($xml_subtree_parser,$_) if (length($_));'."\n".
      'XML::Smart::Tree::_End($xml_subtree_parser,'.makeSingleQuoted($tag).');"";'."\n";
}


# code called from compiled XSP scripts
sub parse_namespace {
    local( $_ ) = shift;

    # These forms will return ns and prefix as follows:
    # *1.  {ns}prefix:name => ns specified, prefix specified (fully specified)
    # *2a. {ns}name        => ns specified, prefix undefined (generate prefix)
    #  2b. {ns}:name       => ns specified, prefix undefined (generate prefix)
    # *3a. prefix:name     => ns undefined, prefix specified (lookup ns)
    #  3b. {}prefix:name   => ns undefined, prefix specified (lookup ns)
    # *4a. {}name          => ns is '',     prefix is ''     (no ns)
    #  4b. {}:name         => ns is '',     prefix is ''     (no ns)
    #  4c. :name           => ns is '',     prefix is ''     (no ns)
    # *5.  name            => ns undefined, prefix undefined (default ns)
    # The canonical forms are starred.
    # (Note that neither a ns of '0' nor a prefix of '0' is allowed;
    # they will be treated as empty strings.)

    # The following tests can be used:
    # if $ns and $prefix                         => fully specified
    # if $ns and not $prefix                     => generate prefix
    # if not $ns and $prefix                     => lookup ns
    # if not $ns and defined $ns                 => no ns
    # if not defined $ns and not defined $prefix => default ns

    # This pattern match will almost give the desired results:
    my ($ns, $prefix, $name) = m/^(?:{(.*)})? (?:([^:]*):)? (.*)$/x;

    # These cases are fine with the pattern match:
    # 1.  {ns}prefix:name => ns specified, prefix specified
    # 2a. {ns}name        => ns specified, prefix undefined
    # 3a. prefix:name     => ns undefined, prefix specified
    # 4b. {}:name         => ns is '',     prefix is ''
    # 5.  name            => ns undefined, prefix undefined

    # These cases need to be adjusted:

    # 2b. {ns}:name       => ns specified, prefix ''        <= actual result
    # 2b. {ns}:name       => ns specified, prefix undefined <= desired result
    $prefix = undef if $ns and not $prefix;

    # 3b. {}prefix:name   => ns '',        prefix specified <= actual result
    # 3b. {}prefix:name   => ns undefined, prefix specified <= desired result
    $ns = undef if not $ns and $prefix;

    # 4a. {}name,         => ns is '',     prefix undefined <= actual result
    # 4a. {}name,         => ns is '',     prefix is ''     <= desired result
    $prefix = '' if not $prefix and defined $ns and $ns eq '';

    # 4c. :name           => ns undefined, prefix is ''     <= actual result
    # 4c. :name           => ns is '',     prefix is ''     <= desired result
    $ns = '' if not $ns and defined $prefix and $prefix eq '';

    ($ns, $prefix, $name);
}

sub _lookup_prefix {
    my ($ns, $namespaces) = @_;
    my $i = 0;
    foreach my $namespace (@$namespaces) {
        my ($nsprefix, $nsuri) = @$namespace;
        ++$i;
        next unless $nsuri eq $ns;
        #$nsprefix = "stlns$i" if $nsprefix eq '' and $nsuri ne '';
        return $nsprefix;
    }
    #return "stlns$i";
    return "";
}

sub _lookup_ns {
    my ($prefix, $namespaces) = @_;
    $prefix ||= '';
    my $i = 0;
    foreach my $namespace (@$namespaces) {
        my ($nsprefix, $nsuri) = @$namespace;
        #++$i;
        next unless $nsprefix eq $prefix;
        #$nsprefix = "stlns$i" if $nsprefix eq '' and $nsuri ne '';
        return wantarray ? ($nsuri, $nsprefix) : $nsuri;
    }
    my ($nsprefix, $nsuri) = @{$namespaces->[-1]}; # default namespace
    return wantarray ? ($nsuri, $nsprefix) : $nsuri;
}


sub xmlize {
    my ($document, $parent, $namespaces, @data) = @_;
    foreach my $data (@data) {
        if (UNIVERSAL::isa($data,'XML::LibXML::Document')) {
            $data = $data->getDocumentElement();
        }
        if (UNIVERSAL::isa($data,'XML::LibXML::Node')) {
            $document->importNode($data);
            $parent->appendChild($data);
            next;
        }
        die 'data is not a hash ref or DOM fragment!' unless ref($data) eq 'HASH';
        while (my ($key, $val) = each %$data) {
            my $outer_namespaces_added = 0;
            if (substr($key,0,1) eq '@') {
                $key = substr($key,1);
                die 'attribute value is not a simple scalar!' if ref($val);
                next if $key =~ m/^xmlns(?::|$)/; # already processed these
                my ($ns, $prefix, $name) = parse_namespace($key);
                #$prefix = _lookup_prefix($ns, $namespaces) if $ns and not $prefix;
                $ns = _lookup_ns($prefix, $namespaces) if not $ns and $prefix;
                $name = $prefix.':'.$name if $prefix;
                if ($ns and $prefix) {
                    $parent->setAttributeNS($ns,$name,$val);
                } else {
                    $parent->setAttribute($name,$val);
                }
                next;
            }

            my ($ns, $prefix, $name) = parse_namespace($key);
            $prefix = _lookup_prefix($ns, $namespaces) if $ns and not $prefix;
            if (defined $ns) {
                unshift @$namespaces, [ $prefix => $ns ];
                $outer_namespaces_added++;
            }
            my @data = ref($val) eq 'ARRAY'? @$val:$val;
            foreach my $data (@data) {
                my $namespaces_added = 0;
                if (ref($data) and ref($data) eq 'HASH') {
                    # search for namespace declarations in attributes
                    while (my ($key, $val) = each %$data) {
                        if ($key =~ m/^\@xmlns(?::|$)(.*)/) {
                            unshift @$namespaces, [ $1 => $val ];
                            $namespaces_added++;
                        }
                    }
                }

                my $elem;
                if (length($key)) {
                    my($nsuri, $nsprefix, $local) = ($ns, $prefix, $name);
                    ($nsuri, $nsprefix) = _lookup_ns($nsprefix, $namespaces) if not defined $nsuri;
                    $local = $nsprefix.':'.$local if $nsprefix;
                    if ($nsuri) {
                        $elem = $document->createElementNS($nsuri,$local);
                    } else {
                        $elem = $document->createElement($local);
                    }
                    $parent->appendChild($elem);
                } else {
                    $elem = $parent;
                }

                if (ref($data)) {
                    xmlize($document, $elem, $namespaces, $data);
                } else {
                    my $tn = $document->createTextNode($data);
                    $elem->appendChild($tn);
                }
                splice(@$namespaces, 0, $namespaces_added) if $namespaces_added; # remove added namespaces
            }
            splice(@$namespaces, 0, $outer_namespaces_added) if $outer_namespaces_added; # remove added namespaces
        }
    }
}

# event handlers

sub characters {
    my ($e, $node) = @_;
    my $text = $node->{'Data'};
    if ($globalframe[0]{'ignoreWS'}) {
        $text =~ s/^\s*//;
        $text =~ s/\s*$//;
    }
    return '' if $text eq '';
    return '.'.makeSingleQuoted($text);
}

sub start_element
{
    my ($e, $element) = @_;
    my %attribs = map { $_->{'Name'} => $_->{'Value'} } @{$element->{'Attributes'}};
    my $tag = $element->{'Name'};
    #warn("Element: ".join(",",map { "$_ => ".$$element{$_} } keys %$element));
    my $ns = $element->{'NamespaceURI'};
    my $frame = ($frame{$ns} ||= []);
    $structStack = ($structStack{$ns} ||= []);
    my $rtpkg = $AxKit2::Transformer::XSP::tag_lib{$ns};
    my $pkg = $rtpkg."::Handlers";
    my ($sub, $subOpen, $rtsub, $rtsubOpen);
    my $attribs = {};
    my $longtag;
    #warn("full struct: ".serializeChildStructSpec($$structStack[0][$#{$$structStack[0]}]{'sub'})) if $$structStack[0];
    #warn("current node: ".$$structStack[0][0]{'name'}) if $$structStack[0];
    #warn("rest struct: ".serializeChildStructSpec($$structStack[0][0]{'sub'})) if $$structStack[0];
    if ($$structStack[0][0]{'param'} && exists $$structStack[0][0]{'param'}{$tag}) {
        $sub = \&set_childStruct_value;
        $subOpen = \&set_childStruct_value__open;
    } elsif ($$structStack[0][0]{'sub'} && (exists $$structStack[0][0]{'sub'}{$tag} || exists $$structStack[0][0]{'sub'}{'*'})) {
        my $tkey = $tag;
        $tkey = '*' if (!exists $$structStack[0][0]{'sub'}{$tag});
        if ($$structStack[0][0]{'sub'}{$tkey}{'sub'}) {
            foreach my $key (keys %{$$structStack[0][0]{'sub'}{$tkey}{'sub'}}) {
                $$attribs{$key} = $attribs{$key} if exists $attribs{$key};
            }
        }
        if ($$structStack[0][0]{'sub'}{$tkey}{'param'}) {
            foreach my $key (keys %{$$structStack[0][0]{'sub'}{$tkey}{'param'}}) {
                $$attribs{$key} = $attribs{$key} if exists $attribs{$key};
            }
        }
        $sub = \&set_childStruct_value;
        $subOpen = \&set_childStruct_value__open;
    } else {
        for my $i (0..$#{$frame}) {
            if (exists $$frame[$i]{'vars'}{$tag}) {
                #warn("variable: $tag");
                $sub = \&set_attribOrChild_value;
                $subOpen = \&set_attribOrChild_value__open;
                last;
            }
        }
        if (!$sub) {
            my @backframes = (reverse(map{ ${$_}{'name'} } @{$frame}),$tag);
            #warn("frames: ".@$frame.", backframes: ".join(",",@backframes));
            my $i = @backframes+1;
            while ($i) {
                $longtag = join('___', @backframes) || '_default';
                shift @backframes;
                $i--;
                #warn("checking for $longtag");
                if ($sub = $pkg->can(makeVariableName($longtag))) {
                    $subOpen = $pkg->can(makeVariableName($longtag)."__open");
                }
                if ($handlerAttributes{$rtsub} and $rtsub = $rtpkg->can(makeVariableName($longtag))) {
                    $rtsubOpen = $rtpkg->can(makeVariableName($longtag)."__open");
                }
                die("Simultaneous run-time and compile-time handlers for one tag not supported") if $sub and $rtsub;
                last if $sub or $rtsub;
            }
        }
    }
    if (((!$sub && !$rtsub) || $longtag eq '_default') && $frame{smart}) {
        $sub = &set_XmlSmart_value;
        $subOpen = &set_XmlSmart_value__open;
    }
    die "invalid tag: $tag (namespace: $ns, package $pkg, parents ".join(", ",map{ ${$_}{'name'} } @{$frame}).")" unless $sub or $rtsub;

    my $handlerAttributes = $handlerAttributes{$sub || $rtsub};
    if ($$handlerAttributes{'compile'}) {
        $sub = $rtsub;
        undef $rtsub;
        $subOpen = $rtsubOpen;
        undef $rtsubOpen;
    }

    if ($$handlerAttributes{'result'} == STRUCT || !$$handlerAttributes{'result'} ||
        $$handlerAttributes{'result'} == NODELIST ||
        ($$handlerAttributes{'result'} == EXPRORNODELIST &&
         $attribs{$$handlerAttributes{'resultparam'}} eq
         $$handlerAttributes{'resultnode'})) {

        # FIXME: this can give problems with non-SimpleTaglib-taglib interaction
        # it must autodetect whether to use '.do' or not like xsp:expr, but as
        # that one doesn't work reliably neither, it probably doesn't make any
        # difference
        $e->append_to_script('.') if ($globalframe[0]{'capture'});
        $e->append_to_script('do { ') if ($element->{Parent});

    } elsif ($$handlerAttributes{'result'} == NODE ||
        ($$handlerAttributes{'result'} == EXPRORNODE
        && $attribs{$$handlerAttributes{'resultparam'}} eq
        $$handlerAttributes{'resultnode'})) {

        $e->append_to_script('.') if ($globalframe[0]{'capture'});
        $e->append_to_script('do { ');
        start_elem($e,$$handlerAttributes{'nodename'},$$handlerAttributes{'resultattr'},$element->{'Prefix'},$ns);
        start_expr($e,$tag);
    } else {
        $e->append_to_script('.') if ($globalframe[0]{'capture'} && $element->{Parent}->{Name} =~ /^(.*:)?(logic|expr)$/);
        start_expr($e,$tag);
    }

    foreach my $attrib (keys %{$$handlerAttributes{'attribs'}}) {
        $$attribs{$attrib} = $attribs{$attrib}
            unless exists $$handlerAttributes{'children'}{$attrib};
    }
    $$attribs{$$handlerAttributes{'resultparam'}} = $attribs{$$handlerAttributes{'resultparam'}}
        if $$handlerAttributes{'resultparam'};

    unshift @{$frame}, {};
    unshift @globalframe,{};
    if (!$stacklevel{$rtpkg}) {
        $stacklevel{$rtpkg} = [];
        $stackcur{$rtpkg} = [0];
        $e->append_to_script('my @'.makeVariableName($rtpkg)."_stack = ({});\n");
        $e->append_to_script('my $'.makeVariableName($rtpkg).'_stack = $'.makeVariableName($rtpkg)."_stack[0];\n");
    }
    if ($$handlerAttributes{'stack'}) {
        unshift @{$stacklevel{$rtpkg}}, $$handlerAttributes{'stack'};
        unshift @{$stackcur{$rtpkg}}, 0;
        $e->append_to_script('unshift @'.makeVariableName($rtpkg)."_stack, {};\n");
        $e->append_to_script('$'.makeVariableName($rtpkg).'_stack = $'.makeVariableName($rtpkg)."_stack[0];\n");
    } elsif ($attribs{$stacklevel{$rtpkg}[0]}) {
        unshift @{$stackcur{$rtpkg}}, (@{$stacklevel{$rtpkg}}-$attribs{$stacklevel{$rtpkg}[0]});
        $e->append_to_script('$'.makeVariableName($rtpkg).'_stack = $'.makeVariableName($rtpkg).'_stack['.$stackcur{$rtpkg}[0]."];\n");
    }
    $$frame[0]{'attribs'} = $attribs;
    $$frame[0]{'smart'} = $$frame[1]{'smart'};
    $globalframe[0]{'ignoreWS'} = !$$handlerAttributes{'keepWS'};
    $globalframe[0]{'capture'} = $$handlerAttributes{'capture'};
    $globalframe[0]{'pkg'} = ($sub?$pkg:$rtpkg);
    $globalframe[0]{'ns'} = ($sub?$pkg:$rtpkg);
    $$frame[0]{'name'} = $tag;
    $$frame[0]{'sub'} = $sub;
    $$frame[0]{'rtsub'} = $rtsub;
    if ($$handlerAttributes{'struct'}) {
        unshift @{$structStack}, [{ 'sub' => $$handlerAttributes{'struct'}, 'name' => $tag }];
        $$frame[0]{'struct'} = 1;
        $e->append_to_script('local(%_) = (); ');
    }

    $e->append_to_script('my ($attr_'.join(', $attr_',map { makeVariableName($_) } keys %{$$handlerAttributes{'children'}}).'); ')
        if $$handlerAttributes{'children'} && %{$$handlerAttributes{'children'}};
    foreach my $var (keys %{$$handlerAttributes{'children'}}) {
        next unless exists $attribs{$var};
        $e->append_to_script('$attr_'.makeVariableName($var).' = '.makeSingleQuoted($attribs{$var}).'; ');
    }
    $$frame[0]{'vars'} = $$handlerAttributes{'children'};

    $e->append_to_script($subOpen->($e,$tag,%$attribs)) if $subOpen;
    $e->append_to_script("${rtpkg}::".makeVariableName($longtag)."__open(".makeSingleQuoted($tag).",{".join(",",map { makeSingleQuoted($_)."=>".makeSingleQuoted($$attribs{$_}) } keys %$attribs).'}, $'.makeVariableName($rtpkg)."_stack);\n") if $rtsubOpen;

    if ($$handlerAttributes{'smart'}) {
        $$frame[0]{'smart'} = 1;
        $e->append_to_script("my \$xml_subtree_parser = {};\n");
        $e->append_to_script(set_XmlSmart_value__open($e,$tag,%attribs));
    }
    if ($$handlerAttributes{'capture'}) {
        $e->append_to_script('local($_) = ""');
        $e->{'Current_Element'}->{'SimpleTaglib_SavedNS'} = $e->{'Current_Element'}->{'NamespaceURI'};
        $e->{'Current_Element'}->{'NamespaceURI'} = $ns;
    }

    return '';
}

sub end_element {
    my ($e, $element) = @_;

    my $tag = $element->{'Name'};
    my $ns = $element->{'NamespaceURI'};
    my $frame = $frame{$ns};
    $structStack = $structStack{$ns};
    my $rtpkg = $AxKit2::Transformer::XSP::tag_lib{$ns};
    my $pkg = $rtpkg."::Handlers";
    my $longtag;
    my $sub = $$frame[0]{'sub'};
    my $rtsub = $$frame[0]{'rtsub'};
    die "invalid closing tag: $tag (namespace: $ns, package $pkg, sub ".makeVariableName($tag).")" unless $sub or $rtsub;
    my $handlerAttributes = $handlerAttributes{$sub || $rtsub};

    if ($globalframe[0]{'capture'}) {
        $e->append_to_script('; ');
    }

    if ($$handlerAttributes{'result'}) {
        $e->append_to_script(' my @_res = do {');
    }

    my $attribs = $$frame[0]{'attribs'};
    if ($$handlerAttributes{'smart'}) {
        $e->append_to_script(set_XmlSmart_value($e,$tag));
        $e->append_to_script("my \$xml_subtree = new XML::Smart('');\n");
        $e->append_to_script("\$xml_subtree->{tree} = XML::Smart::Tree::_Final(\$xml_subtree_parser);\n");
    }
    shift @{$structStack} if $$frame[0]{'struct'};
    shift @{$frame};
    shift @globalframe;
    if ($sub) {
        $e->append_to_script($sub->($e, $tag, %{$attribs}));
    } else {
        foreach my $attrib (keys %{$$handlerAttributes{'attribs'}}, keys %{$$handlerAttributes{'children'}}) {
            if (exists $$handlerAttributes{'children'}{$attrib}) {
                $$attribs{$attrib} = '$attr_'.makeVariableName($attrib);
            } else {
                $$attribs{$attrib} = makeSingleQuoted($$attribs{$attrib});
            }
        }
        $$attribs{$$handlerAttributes{'resultparam'}} = makeSingleQuoted($$attribs{$$handlerAttributes{'resultparam'}})
          if $$handlerAttributes{'resultparam'};
        $e->append_to_script("${rtpkg}::".makeVariableName($longtag)."(".makeSingleQuoted($tag).",{".join(",",map { makeSingleQuoted($_)."=>".$$attribs{$_} } keys %$attribs).'},$'.makeVariableName($rtpkg)."_stack,".($$handlerAttributes{'smart'}?'$xml_subtree':'undef').");");
    }

    if (defined $e->{'Current_Element'}->{'SimpleTaglib_SavedNS'}) {
        $e->{'Current_Element'}->{'NamespaceURI'} = $e->{'Current_Element'}->{'SimpleTaglib_SavedNS'};
        delete $e->{'Current_Element'}->{'SimpleTaglib_SavedNS'};
    }

    if ($$handlerAttributes{'result'} == NODELIST ||
        ($$handlerAttributes{'result'} == EXPRORNODELIST
         && $$attribs{$$handlerAttributes{'resultparam'}} eq
         $$handlerAttributes{'resultnode'})) {

        $e->append_to_script('}; foreach my $_res (@_res) {');
        start_elem($e,$$handlerAttributes{'nodename'},$$handlerAttributes{'resultattr'},$element->{'Prefix'},$ns);
        start_expr($e,$$handlerAttributes{'nodename'});
        $e->append_to_script('$_res');
        $e->end_expr();
        end_elem($e);
        $e->append_to_script("} ");
        if ($globalframe[0]{'capture'}) {
            $e->append_to_script("\"\"; }\n");
        } else {
            $e->append_to_script(" };\n");
        }
    } elsif ($$handlerAttributes{'result'} == NODE ||
        ($$handlerAttributes{'result'} == EXPRORNODE
         && $$attribs{$$handlerAttributes{'resultparam'}} eq
         $$handlerAttributes{'resultnode'})) {

        $e->append_to_script('}; ');
        $e->append_to_script('join("",@_res);');
        $e->end_expr($tag);
        end_elem($e);
        if ($globalframe[0]{'capture'}) {
            $e->append_to_script("\"\"; }\n");
        } else {
            $e->append_to_script(" };\n");
        }
    } elsif ($$handlerAttributes{'result'} == STRUCT) {
        $e->append_to_script('}; ');
        my ($nsuri, $nsprefix);
        if (not $$handlerAttributes{'namespace'}) {
            $nsuri = $ns;
            $nsprefix = $element->{'Prefix'};
        }
        elsif ($$handlerAttributes{'namespace'} =~ m/^{(.*)}([^:]*):?$/) {
            # "{ns}prefix:", "{ns}prefix", "{ns}:", "{ns}", "{}:", "{}"
            ($nsuri, $nsprefix) = ($1, $2);
            $nsprefix = '' unless $nsuri; # assume "{}prefix" meant "{}"
            #$nsprefix = $e->generate_nsprefix($nsuri) if $nsuri and not $nsprefix;
        }
        else {
            # "ns", '""', "''"
            $nsuri = $$handlerAttributes{'namespace'};
            $nsuri = '' if $nsuri eq '""' or $nsuri eq "''";
            #$nsprefix = $e->generate_nsprefix($nsuri) if $nsuri;
            $nsprefix = '';
        }
        if (AxKit2::Transformer::XSP::is_xsp_namespace($element->{'Parent'}->{'NamespaceURI'})) {
            if (!$e->manage_text() || $element->{'Parent'}->{'Name'} =~ /^(.*:)?content$/) {
                $e->append_to_script('AxKit2::XSP::SimpleTaglib::xmlize($document,$parent,[['.makeSingleQuoted($nsprefix).'=>'.makeSingleQuoted($nsuri).']],@_res); ');
            } else {
                $e->append_to_script('eval{if (wantarray) { @_res; } else { join("",@_res); }}');
            }
        } else {
            $e->append_to_script('AxKit2::XSP::SimpleTaglib::xmlize($document,$parent,[['.makeSingleQuoted($nsprefix).'=>'.makeSingleQuoted($nsuri).']],@_res); ');
        }
        if ($globalframe[0]{'capture'}) {
            $e->append_to_script("\"\"; }\n");
        } else {
            $e->append_to_script(" };\n");
        }
    } elsif ($$handlerAttributes{'result'}) {
        $e->append_to_script('}; eval{if (wantarray) { @_res; } else { join("",@_res); }} ');
        $e->end_expr();
    } else {
        if ($globalframe[0]{'capture'}) {
            $e->append_to_script("\"\"; }\n");
        } else {
            $e->append_to_script(" };\n") if ($element->{Parent});
        }
    }
    if ($$handlerAttributes{'stack'}) {
        shift @{$stacklevel{$rtpkg}};
        shift @{$stackcur{$rtpkg}};
        $e->append_to_script('shift @'.makeVariableName($rtpkg)."_stack;\n");
        $e->append_to_script('$'.makeVariableName($rtpkg).'_stack = $'.makeVariableName($rtpkg)."_stack[".$stackcur{$rtpkg}[0]."];\n");
    } elsif ($$attribs{$stacklevel{$rtpkg}[0]}) {
        shift @{$stackcur{$rtpkg}};
        $e->append_to_script('$'.makeVariableName($rtpkg).'_stack = $'.makeVariableName($rtpkg).'_stack['.$stackcur{$rtpkg}[0]."];\n");
    }
    #warn('script len: '.length($e->{XSP_Script}).', end tag: '.$tag);
    return '';
}

1;

__END__

=pod

=head1 NAME

AxKit2::XSP::SimpleTaglib - alternate XSP taglib helper

=head1 SYNOPSIS

    package Your::XSP::Package;
    use AxKit2::XSP::SimpleTaglib;

    ... more initialization stuff, start_document handler, utility functions, whatever
	you like, but no parse_start/end handler needed - if in doubt, just leave empty ...

    sub some_tag : XSP_attrib(id) XSP_attribOrChild(some-param) XSP_node(result) XSP_keepWhitespace {
        my ($tag, $attr, $stack, $struct) = @_;
        return do_something($$attr{'some-param'},$$attr{'id'});
    }
    
    # old style usage no longer documented, but still supported


=head1 DESCRIPTION

This taglib helper allows you to easily write tag handlers with most of the common
behaviours needed. It manages all 'Design Patterns' from the XSP man page plus
several other useful tag styles, including object-like access as in ESQL.

=head2 Simple handler subs

A tag "<yourNS:foo>" will trigger a call to sub "foo" during the closing tag event.
What happens in between can be configured in many ways
using Perl function attributes. In the rare cases where some action has to happen during
the opening tag event, you may provide a sub "foo__open" (double underscore)
which will be called at the appropriate time. Usually you would only do that for 'if'-
style tags which enclose some block of code. 'if'-style tags usually also need the C<XSP_compile>
flag.

Contrary to the former behaviour, your tag handler is called during the XSP execution stage,
so you should directly return the result value. The C<XSP_compile> flag is available to
have your handler called in the parse stage, when the XSP script is being constructed. Then,
it is the responsibility of the handler to return a I<Perl code fragment> to be appended to
the XSP script.

As a comparison, TaglibHelper subs are strictly run-time called, while plain taglibs without
any helper are strictly compile-time called.

B<Warning:> The old usage is still fully supported, but you should not use it anymore. It may
become deprecated in a future release and will be removed entirely afterwards. Porting it
to the new style usage is quite easy: remove the line reading "package I<your-taglib>::Handler;",
then prefix "XSP_" to all Perl attributes (e.g., "childStruct" becomes "XSP_childStruct"), and add
"XSP_compile" to every handler sub. If after your refactoring some handler sub doesn't carry any
Perl attribute anymore, add a plain "XSP" Perl attribute.

Perl attributes without the 'XSP_' prefix cause a warning (actually, sometimes even two, one from Perl
and one from SimpleTaglib), as lower-case Perl attributes are reserved for Perl itself.

=head2 Context sensitive handler subs

A sub named "foo___bar" (triple underscore) gets called on the following XML input:
"<yourNS:foo><yourNS:bar/></yourNS:foo>". Handler subs may have any nesting depth.
The rule for opening tag handlers applies here as well. The sub name must represent the
exact tag hierarchy (within your namespace).

=head2 Names, parameters, return values

Names for subs and variables get created by replacing any non-alphanumeric characters in the
original tag or attribute to underscores. For example, 'get-id' becomes 'get_id'.

In the default (run-time called) mode, subs get 4 parameters: the tag name, a hashref
containing attributes and child tags specified through C<XSP_child>/C<XSP_attribOrChild>, a
hashref for taglib private data (the current C<XSP_stack> hashref, if C<XSP_stack> is used),
and the C<XSP_smart> object, if applicable.

In C<XSP_compile> mode, the called subs get passed 3 parameters: The parser object, the tag name,
and an attribute hash (no ref!). This hash only contains XML attributes declared using the
'attrib()' Perl function attribute. (Try not to confuse these two meanings of 'attribute' -
unfortunately XML and Perl both call them that way.) The other declared parameters get converted
into local variables with prefix 'attr_', or, in the case of 'XSP_smart', converted into the
'$xml_subtree' object. These local variables are only available inside your code fragment which
becomes part of the XSP script, unlike the attribute hash which is passed directly to
your handler as the third parameter.

If a sub has an output attribute ('node', 'expr', etc.), the sub (or code fragment) will be run
in list context. If necessary, returned lists get converted to scalars by joining them
without separation. Code fragments from plain subs (without an output attribute) inherit
their context and have their return value left unmodified.

=head2 Precedence

If more than one handler matches a tag, the following rules determine which one is chosen.
Remember, though, that only tags in your namespace are considered.

=over 4

=item 1.

If any surrounding tag has a matching 'child' or 'attribOrChild'
attribute, the internal handler for the innermost matching tag gets chosen.

=item 2.

If any, the handler sub with the deepest tag hierarchy gets called.

=item 3.

If any parent tag carries the C<XSP_smart> attribute, the tag is collected in the
XML::Smart object tree.

=item 4.

If no handler sub matches, sub "_default" is tried.

=back

=head2 Utility functions

AxKit2::Transformer::XSP contains a few handy utility subs to help build your code fragment:

=over 4

=item start_elem, end_elem, start_attr, end_attr

these create elements and attributes
in the output document. Call them just like you call start_expr and end_expr.

=item makeSingleQuoted

given a scalar as input, it returns a scalar which yields
the exact input value when evaluated; handy when using unknown text as-is in code fragments.

=item makeVariableName

creates a valid, readable perl identifier from arbitrary input text.
The return values might overlap.

=back

=head1 PERL ATTRIBUTES

Perl function attributes are used to define how XML output should be generated from your
code fragment and how XML input should be presented to your handler.  Note that
parameters to attributes get handled as if 'q()' enclosed them (explicit quote marks are
not needed). Furthermore, commas separate parameters (except for childStruct), so a
parameter cannot contain a comma.

=head2 Output attributes

Choose exactly one of these to select output behaviour.

=head3 C<XSP>

Makes this tag behave not special at all. If merely flags this sub as being a valig tag handler.
For security and stability reasons, only subs carrying any XSP attribute are available as tags.

=head3 C<XSP_expr>

Makes this tag behave like an '<xsp:expr>' tag, creating text nodes or inline text as appropriate.
Choose this if you create plain text which may be used everywhere, including inside code. This
attribute has no parameters.

=head3 C<XSP_node(name)>

Makes this tag create an XML node named C<name>. The tag encloses all content as well as the
results of the handler sub.
Choose this if you want to create one XML node with all your output.

=head3 C<XSP_nodelist(name)>

Makes this tag create a list of XML nodes named C<name>. The tag(s) do not enclose content nodes,
which become preceding siblings of the generated nodes. The return value gets converted to a
node list by enclosing each element with an XML node named C<name>.
Choose this if you want to create a list of uniform XML nodes with all your output.

=head3 C<XSP_exprOrNode(name,attrname,attrvalue)>

Makes this tag behave described under either 'node()' or 'expr', depending on the value of
XML attribute C<attrname>. If that value matches C<attrvalue>, it will work like 'node()',
otherwise it will work like 'expr'. C<attrname> defaults to 'as', C<attrvalue> defaults to
'node', thus leaving out both parameters means that 'as="node"' will select 'node()' behaviour.
Choose this if you want to let the XSP author decide what to generate.

=head3 C<XSP_exprOrNodelist(name,attrname,attrvalue)>

Like exprOrNode, selecting between 'expr' and 'nodelist()' behaviour.

=head3 C<XSP_struct>

Makes this tag create a more complex XML fragment. You may return a single hashref or an array
of hashrefs, which get converted into an XML structure. Each hash element may contain a scalar,
which gets converted into an XML tag with the key as name and the value as content. Alternatively,
an element may contain an arrayref, which means that an XML tag encloses each single array element.
Finally, you may use hashrefs in place of scalars to create substructures. To create attributes on
tags, use a hashref that contain the attribute names prefixed by '@'. A '' (empty
string) as key denotes the text contents of that node.

You can also use a XML::LibXML::Document or XML::LibXML::Node object in place of a hashref. You
can, for example, simply return an XML::LibXML::Document object and it gets inserted at the current
location. You may also return an array of documents/nodes, and you may even mix plain hashrefs
with DOM objects as you desire.

Finally, you may also return an XML::Simple object.

In an expression context, passes on the unmodified return value.

=head2 Other output attributes

These may appear more than once and modify output behaviour.

=head3 C<XSP_compile>

Makes this tag called at XSP compile time, not run time. It must return a Perl code fragment.
For more details, see the sections above.

=head3 C<XSP_nodeAttr(name,expr,...)>

Adds an XML attribute named C<name> to all generated nodes. C<expr> gets evaluated at run time.
Evaluation happens once for each generated node. Of course, this tag only makes sense with
'node()' type handlers.

=head2 Input attributes

These tags specify how input gets handled. Most may appear more than once, if that makes sense.

=head3 C<XSP_attrib(name,...)>

Declares C<name> as a (non-mandatory) XML attribute. All attributes declared this way get
passed to your handler sub in the attribute hash (the third argument to your handler).

=head3 C<XSP_child(name,...)>

Declares a child tag C<name>. It always lies within the same namespace as the taglib itself. The
contents of the tag, if any, get saved in a local variable named $attr_C<name> and made
available to your code fragment. If the child tag appears more than once, the last value
overrides any previous value.

=head3 C<XSP_attribOrChild(name,...)>

Declares an attribute or child tag named C<name>. A variable is created just like for 'child()',
containing the attribute or child tag contents. If both appear, the contents of the child tag take
precedence.

=head3 C<XSP_keepWhitespace>

Makes this tag preserve contained whitespace.

=head3 C<XSP_captureContent>

Makes this tag store the enclosed content in '$_' for later retrieval in your code fragment instead
of adding it to the enclosing element. Non-text nodes will not work as expected.

=head3 C<XSP_stack(attrname)>

This will create a stack of objects for your taglib. Each taglib has exactly one stack, however.

Stacks work like this:

Whenever a tag is encountered that is flagged with C<XSP_stack>, a new empty stack frame (hashref) is created.
ALL handler subs get this hashref as their third argument where they may store/retrieve any data.

If the user wants to access a outer stack frame (object), she may add the I<attrname> attribute to ANY of your
tags. The value of that attribute specifies how much to go back: 0 is the innermost stack frame, 1 is
the surrounding one, and so on. The tag with I<attrname> and ALL tags below then get the selected stack frame
instead of the innermost one until another I<attrname> selects a new frame, or another C<XSP_stack> opens a
new one.

Most prominent example of this mode of operation is ESQL, which uses this technique to nest SQL queries.

=head3 C<XSP_smart>

Collects all unknown tags (that are in your taglib's name space) in an XML::Smart object and
passes it as the fourth element to your handler sub.

You must have XML::Smart installed to use this feature.

B<Note:> This attribute replaces the former childStruct attribute, which was way too complex.
The code is not yet removed, however, so legacy taglibs will still work. Backwards compatibility
will be removed in a future release.

=head1 XML NAMESPACES

By default, all output element nodes are placed in the same namespace
as the tag library.  To specify a different namespace or no namespace,
the desired namespace can be placed within curly braces before the
node name in an output attribute:

  {namespaceURI}name

To specify a prefix, place it after the namespace:

  {namespaceURI}prefix:name

For example, to create an XML node named C<otherNS:name> and associate
the prefix 'otherNS' with the namespace 'http://mydomain/NS/other/v1':

  node({http://mydomain/NS/other/v1}otherNS:name)

To create an XML node with no namespace, use an empty namespace:

  node({}name)

This notation for specifying namespaces can also be used in the
C<struct> output attribute.  Alternatively, the standard "xmlns" XML
attribute may be used to specify namespaces.  For example, the
following are equivalent:

  sub sample_struct : XSP_struct {
    return { '{http://mydomain/NS/other/v1}otherNS:name' => 'value' };
  }

  sub sample_struct : XSP_struct {
    return {
        'otherNS:name' =>
        { '@xmlns:otherNS' => 'http://mydomain/NS/other/v1',
          '' => 'value' }
    };
  }

Namespace scoping in the hashref is patterned after XML documents.
You may refer to previously declared namespaces by using the same
prefix, and you may override previously declared namespaces with new
declarations (either with the curly-braced notation or by using
"xmlns" XML attributes).

To specify a default namespace for all unqualified node names in the
hashref, state it as a parameter to the C<struct> output attribute:

  XSP_struct(namespaceURI)

You may also specify a prefix:

  XSP_struct({namespaceURI}prefix)

For example, the following is equivalent to the previous example:

  sub sample_struct : XSP_struct({http://mydomain/NS/other/v1}otherNS) {
    return { 'name' => 'value' };
  }

To turn off the default namespace for all node names, use an empty
namespace:

  sub sample_struct : XSP_struct({}) {
    return { 'name' => 'value' };
  }

By default, XML attributes created with the C<nodeAttr> output
attribute are not in a namespace.  The curly-braced notation can be
used to specify a namespace.  For example:

  XSP_nodeAttr({http://www.w3.org/TR/REC-html40}html:href,'http://www.axkit.org/')

If you are specifying more than one attribute in the same namespace,
you can refer to previously declared namespaces by using the same
prefix:

  XSP_nodeAttr({http://www.w3.org/TR/REC-html40}html:href,'http://www.axkit.org/',html:class,'link')

A prefix is required to associate a namespace with an attribute. Default namespaces
(those without a prefix) do not apply to attributes and are ignored.


=head1 EXAMPLES

Refer to the Demo tag libraries included in the AxKit distribution and look at the source
code of AxKit::XSP::Sessions and AxKit::XSP::Auth for full-featured examples. Beware, though,
they probably still use the old syntax.

=head1 BUGS AND HINTS

=head2 Miscellaneous

Because of the use of perl attributes, SimpleTaglib will only work with Perl 5.6.0 or later.
This software is already tested quite well and works for a number of simple and complex
taglibs. Still, you may have to experiment with the attribute declarations, as the differences
can be quite subtle but decide between 'it works' and 'it doesn't'. XSP can be quite fragile if
you start using heavy trickery.

If some tags don't work as expected, try surrounding the offending tag with
<xsp:content>, this is a common gotcha (but correct and intended). If you find you need
<xsp:expr> around a tag, please contact the author, that is probably a bug.

=head1 AUTHOR

Jörg Walter <jwalt@cpan.org>

=head1 COPYRIGHT

Copyright 2001-2003 Jörg Walter <jwalt@cpan.org>
All rights reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as AxKit itself.

=head1 SEE ALSO

AxKit, AxKit2::Transformer::XSP, AxKit2::XSP::TaglibHelper, XML::Smart

=cut
