
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::HTML::CommentVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{parent} = shift;
    return $self;
}

sub _get_defn {
    my $self = shift;
    my ($defn) = @_;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{parent}->{symbtab}->Lookup($defn);
    }
}

sub _get_name {
    my $self = shift;
    my ($node) = @_;
    return $node->visit($self->{parent}->{html_name},$self->{parent}->{scope});
}

sub _extract_doc {
    my $self = shift;
    my ($node) = @_;
    my $doc = undef;
    my @tags = ();
    unless ($node->isa('Parameter')) {
        $self->{scope} = $node->{full};
        $self->{scope} =~ s/::[0-9A-Z_a-z]+$//;
    }
    if (exists $node->{doc}) {
        my @lines = split /\n/, $node->{doc};
        foreach (@lines) {
            if    (/^\s*@\s*([\s0-9A-Z_a-z]+):\s*(.*)/) {
                my $tag = $1;
                my $value = $2;
                $tag =~ s/\s*$//;
                push @tags, [$tag, $value];
            }
            elsif (/^\s*@\s*([A-Z_a-z][0-9A-Z_a-z]*)\s+(.*)/) {
                push @tags, [$1, $2];
            }
            else {
                $doc .= $_;
                $doc .= "\n";
            }
        }
    }
    # adds tag from pragma
    if (exists $node->{id}) {
        push @tags, ['Repository ID', $node->{id}];
    }
    else {
        if (exists $node->{version}) {
            push @tags, ['version', $node->{version}];
        }
    }
    return ($doc, \@tags);
}

sub _lookup {
    my $self = shift;
    my ($name) = @_;
    my $defn;
#   print "_lookup: '$name'\n";
    if    ($name =~ /^::/) {
        # global name
        return $self->{parent}->{parser}->YYData->{symbtab}->___Lookup($name);
    }
    elsif ($name =~ /^[0-9A-Z_a-z]+$/) {
        # identifier alone
        my $scope = $self->{scope};
        while (1) {
            # Section 3.15.3 Special Scoping Rules for Type Names
            my $g_name = $scope . '::' . $name;
            $defn = $self->{parent}->{parser}->YYData->{symbtab}->__Lookup($scope, $g_name, $name);
            last if (defined $defn || $scope eq q{});
            $scope =~ s/::[0-9A-Z_a-z]+$//;
        };
        return $defn;
    }
    else {
        # qualified name
        my @list = split /::/, $name;
        return undef unless (scalar @list > 1);
        my $idf = pop @list;
        my $scoped_name = $name;
        $scoped_name =~ s/(::[0-9A-Z_a-z]+$)//;
#       print "qualified name : '$scoped_name' '$idf'\n";
        my $scope = $self->_lookup($scoped_name);       # recursive
        if (defined $scope) {
            $defn = $self->{parent}->{parser}->YYData->{symbtab}->___Lookup($scope->{full} . '::' . $idf);
        }
        return $defn;
    }
}

sub _process_text {
    my $self = shift;
    my ($text) = @_;

    # keep track of leading and trailing white-space
    my $lead  = ($text =~ s/\A(\s+)//s ? $1 : q{});
    my $trail = ($text =~ s/(\s+)\Z//s ? $1 : q{});

    # split at space/non-space boundaries
    my @words = split( /(?<=\s)(?=\S)|(?<=\S)(?=\s)/, $text );

    # process each word individually
    foreach my $word (@words) {
        # skip space runs
        next if $word =~ /^\s*$/;
        if ($word =~ /^[\w:]+$/) {
            # looks like a IDL identifier
            my $node = $self->_lookup($word);
            if (        defined $node
                    and exists $node->{file_html}
                    and $word =~ /$node->{idf}/ ) {
                my $anchor = $node->{html_name} || $node->{idf};
                $word = "<a href='" . $node->{file_html} . "#" . $anchor . "'>" . $word . "</a>";
            }
        }
        elsif ($word =~ /^\w+:\/\/\w/) {
            # looks like a URL
            # Don't relativize it: leave it as the author intended
            $word = "<a href='" . $word . "'>" . $word . "</a>";
        }
        elsif ($word =~ /^[\w.-]+\@[\w.-]+/) {
            # looks like an e-mail address
            $word = "<a href='mailto:" . $word . "'>" . $word . "</a>";
        }
    }

    # put everything back together
    return $lead . join(q{}, @words) . $trail;
}

sub _format_doc_bloc {
    my $self = shift;
    my ($doc, $FH) = @_;
    if (defined $doc) {
        $doc = $self->_process_text($doc);
        print $FH "    <p class='comment'>",$doc,"</p>\n";
    }
}

sub _format_doc_line {
    my $self = shift;
    my ($node, $doc, $FH) = @_;
    my $anchor = q{};
    unless ($node->isa('Parameter')) {
        $anchor = "<a id='" . $node->{html_name} . "' name='" . $node->{html_name} . "'/>\n";
    }
    if (defined $doc) {
        $doc = $self->_process_text($doc);
        print $FH "    <li>",$anchor,$node->{idf}," : <span class='comment'>",$doc,"</span></li>\n";
    }
    else {
        print $FH "    <li>",$anchor,$node->{idf},"</li>\n";
    }
}

sub _format_tags {
    my $self = shift;
    my ($tags, $FH, $javadoc) = @_;
    print $FH "    <p>\n" if (scalar(@{$tags}));
    foreach (@{$tags}) {
        my $entry = ${$_}[0];
        my $doc = ${$_}[1];
        next if (defined $javadoc and lc($entry) eq "param");
        $doc = $self->_process_text($doc);
        print $FH "      <span class='tag'>",$entry," : </span><span class='comment'>",$doc,"</span>\n";
        print $FH "      <br />\n";
    }
    print $FH "    </p>\n" if (scalar(@{$tags}));
}

#
#   3.6     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node, $FH) = @_;
    foreach (@{$node->{list_decl}}) {
        my ($doc, $tags) = $self->_extract_doc($_);
        $self->_format_doc_bloc($doc, $FH);
        $self->_format_tags($tags, $FH);
    }
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

#
#   3.9     Value Declaration
#
#   3.9.1   Regular Value Type
#

sub visitStateMember {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

sub visitInitializer {
    shift->visitOperation(@_);
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

sub visitNativeType {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    my $doc_member = 0;
    foreach (@{$node->{list_member}}) {
        $doc_member ++
                if (exists $self->_get_defn($_)->{doc});
    }
    if ($doc_member) {
#       print $FH "  <br />\n";
        print $FH "  <ul>\n";
        foreach (@{$node->{list_member}}) {
            $self->_get_defn($_)->visit($self, $FH);        # member
        }
        print $FH "  </ul>\n";
    }
    $self->_format_tags($tags, $FH);
}

sub visitMember {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_line($node, $doc, $FH);
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    my $doc_member = 0;
    foreach (@{$node->{list_expr}}) {
        $doc_member ++
                if (exists $self->_get_defn($_->{element}->{value})->{doc});
    }
    if ($doc_member) {
#       print $FH "  <br />\n";
        print $FH "  <ul>\n";
        foreach (@{$node->{list_expr}}) {
            $self->_get_defn($_->{element}->{value})->visit($self, $FH);        # member
        }
        print $FH "  </ul>\n";
    }
    $self->_format_tags($tags, $FH);
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    my $doc_member = 0;
    foreach (@{$node->{list_expr}}) {
        $doc_member ++
                if (exists $_->{doc});
    }
    if ($doc_member) {
#       print $FH "    <br />\n";
        print $FH "    <ul>\n";
        foreach (@{$node->{list_expr}}) {
            $_->visit($self, $FH);          # enum
        }
        print $FH "    </ul>\n";
    }
    $self->_format_tags($tags, $FH);
}

sub visitEnum {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_line($node, $doc, $FH);
}

#
#   3.12    Exception Declaration
#

sub visitException {
    shift->visitStructType(@_);
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}}) + scalar(@{$node->{list_out}})) {
#       print $FH "  <br />\n";
        print $FH "  <ul>\n";
        if (scalar(@{$node->{list_in}})) {
            if (scalar(@{$node->{list_in}}) > 1) {
                print $FH "    <li>Parameters IN :\n";
            }
            else {
                print $FH "    <li>Parameter IN :\n";
            }
            print $FH "      <ul>\n";
            foreach (@{$node->{list_in}}) {
                $self->_parameter($node, $_, $FH);
            }
            print $FH "      </ul>\n";
            print $FH "    </li>\n";
        }
        if (scalar(@{$node->{list_inout}})) {
            if (scalar(@{$node->{list_inout}}) > 1) {
                print $FH "    <li>Parameters INOUT :\n";
            }
            else {
                print $FH "    <li>Parameter INOUT :\n";
            }
            print $FH "      <ul>\n";
            foreach (@{$node->{list_inout}}) {
                $self->_parameter($node, $_, $FH);
            }
            print $FH "      </ul>\n";
            print $FH "    </li>\n";
        }
        if (scalar(@{$node->{list_out}})) {
            if (scalar(@{$node->{list_out}}) > 1) {
                print $FH "    <li>Parameters OUT :\n";
            }
            else {
                print $FH "    <li>Parameter OUT :\n";
            }
            print $FH "      <ul>\n";
            foreach (@{$node->{list_out}}) {
                $self->_parameter($node, $_, $FH);
            }
            print $FH "      </ul>\n";
            print $FH "    </li>\n";
        }
        print $FH "  </ul>\n";
    }
    $self->_format_tags($tags, $FH, 1);
}

sub _parameter {
    my $self = shift;
    my ($parent, $node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    unless (defined $doc) {
        ($doc, $tags) = $self->_extract_doc($parent);
        foreach (@{$tags}) {
            my $entry = ${$_}[0];
            my $javadoc = ${$_}[1];
            if (lc($entry) eq 'param' and $javadoc =~ /^$node->{idf}/) {
                $doc = $javadoc;
                $doc =~ s/^$node->{idf}//;
                last;
            }
        }
    }
    if (defined $doc) {
        $doc = $self->_process_text($doc);
        print $FH "    <li>",$node->{idf}," : <span class='comment'>",$doc,"</span></li>\n";
    }
    else {
        print $FH "    <li>",$node->{idf},"</li>\n";
    }
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

#
#   3.17    Component Declaration
#

sub visitProvides {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

sub visitUses {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

sub visitPublishes {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

sub visitEmits {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

sub visitConsumes {
    my $self = shift;
    my ($node, $FH) = @_;
    my ($doc, $tags) = $self->_extract_doc($node);
    $self->_format_doc_bloc($doc, $FH);
    $self->_format_tags($tags, $FH);
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    shift->visitOperation(@_);
}

sub visitFinder {
    shift->visitOperation(@_);
}

1;

