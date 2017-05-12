
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::HTML::HtmlVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use File::Basename;
use CORBA::HTML::NameVisitor;
use CORBA::HTML::DeclVisitor;
use CORBA::HTML::CommentVisitor;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{parser} = $parser;
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{frameset} = exists $parser->YYData->{opt_f};
    $self->{html_name} = new CORBA::HTML::NameVisitor($parser);
    $self->{html_decl} = new CORBA::HTML::DeclVisitor($self);
    $self->{html_comment} = new CORBA::HTML::CommentVisitor($self);
    $self->{scope} = q{};
    $self->{css} = $parser->YYData->{opt_s};
    $self->{style} = q{
        a.index { font-weight : bold; }
        h2 { color : red; }
        p.comment { color : green; }
        span.comment { color : green; }
        span.decl { font-weight : bold; }
        span.tag { font-weight : bold; }
        hr { text-align : center; }
    };
    return $self;
}

sub _get_defn {
    my $self = shift;
    my($defn) = @_;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{symbtab}->Lookup($defn);
    }
}

sub _get_name {
    my $self = shift;
    my ($node) = @_;
    return $node->visit($self->{html_name}, $self->{scope});
}

sub _print_decl {
    my $self = shift;
    my ($node) = @_;
    $node->visit($self->{html_decl}, \*OUT);
}

sub _print_comment {
    my $self = shift;
    my ($node) = @_;
    $node->visit($self->{html_comment}, \*OUT);
    print OUT "  <p />\n";
}

sub _sep_line {
    my $self = shift;
    print OUT "    <hr />\n";
}

sub _format_head {
    my $self = shift;
    my ($title, $frameset, $target) = @_;
    my $now = localtime();
#   print OUT "<?xml version='1.0' encoding='ISO-8859-1'?>\n";
    if ($frameset) {
        print OUT "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Frameset//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd'>\n";
    }
    else {
        print OUT "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>\n";
    }
    print OUT "<html xmlns='http://www.w3.org/1999/xhtml'>\n";
    print OUT "\n";
    print OUT "  <head>\n";
    print OUT "    <meta name='generator' content='idl2html ",$CORBA::HTML::VERSION," (Perl ",$],")' />\n";
    print OUT "    <meta name='date' content='",$now,"' />\n";
    print OUT "    <meta http-equiv='Content-Type' content='text/html; charset=ISO-8859-1' />\n";
    print OUT "    <title>",$title,"</title>\n" if ($title);
    unless ($frameset) {
        print OUT "    <base target='",$target,"' />\n" if (defined $target);
        if ($self->{css}) {
            print OUT "    <link href='",$self->{css},".css' rel='stylesheet' type='text/css'/>\n";
        }
        else {
            print OUT "    <style type='text/css'>\n";
            print OUT $self->{style},"\n";
            print OUT "    </style>\n";
        }
    }
    print OUT "  </head>\n";
    print OUT "\n";
}

sub _format_head_main {
    my $self = shift;
    my ($title) = @_;
    $self->_format_head($title, 0);
    print OUT "  <body>\n";
    print OUT "    <h1><a id='__Top__' name='__Top__'/>",$title,"</h1>\n";
    print OUT "    <p><a href='index.html'>Global index</a></p>\n"
            unless ($self->{frameset});
    print OUT "    <hr />\n";
}

sub _format_head_global_index {
    my $self = shift;
    my $title = 'Global index';
    if ($self->{frameset}) {
        $self->_format_head($title, 0, 'local');
        print OUT "  <body>\n";
    }
    else {
        $self->_format_head($title, 0);
        print OUT "  <body>\n";
        print OUT "    <h1><a id='__Top__' name='__Top__'/>",$title,"</h1>\n";
        print OUT "    <hr />\n";
    }
}

sub _format_head_index {
    my $self = shift;
    my ($title) = @_;
    $self->_format_head('Index ' . $title, 0, 'main');
    print OUT "  <body>\n";
    print OUT "    <h1><a href='_",$title,".html#__Top__'>",$title,"</a></h1>\n";
}

sub _format_tail {
    my $self = shift;
    my ($frameset) = @_;
    unless ($frameset) {
        print OUT "\n";
        print OUT "  </body>\n";
    }
    print OUT "\n";
    print OUT "</html>\n";
}

sub _format_index {
    my $self = shift;
    my ($node, $rlist) = @_;
    my $nb = 0;
    foreach (@{$rlist}) {
        my $idx = 'index_' . $_;
        if (keys %{$node->{$idx}}) {
            $nb ++;
            my $title = ucfirst $_;
            $title =~ s/_/ /g;
            print OUT "<h2>",$title," index.</h2>\n";
            print OUT "<dl>\n";
            foreach (sort keys %{$node->{$idx}}) {
                my $child = $node->{$idx}->{$_};
                print OUT "    <dt><a class='index' href='",$child->{file_html},"#",$_,"'>";
                print OUT $_,"</a></dt>\n";
            }
            print OUT "</dl>\n";
        }
    }
    unless ($self->{frameset}) {
        $self->_sep_line() if ($nb);
    }
}

sub _format_decl {
    my $self = shift;
    my ($node, $rlist) = @_;
    my $nb = 0;
    foreach (@{$rlist}) {
        my $idx = 'index_' . $_;
        if (keys %{$node->{$idx}}) {
            $nb ++;
            my $title = ucfirst $_;
            $title =~ s/_/ /g;
            print OUT "<h2>",$title,"s.</h2>\n";
            if (scalar keys %{$node->{$idx}}) {
                print OUT "<ul>\n";
                foreach (sort keys %{$node->{$idx}}) {
                    my $child = $node->{$idx}->{$_};
                    print OUT "    <li>\n";
                    print OUT "      <h3><a id='",$_,"' name='",$_,"'/>",$_,"</h3>\n";
                    $self->_print_decl($child);
                    $self->_print_comment($child);
                    print OUT "    </li>\n";
                }
                print OUT "</ul>\n";
            }
        }
    }
    $self->_sep_line() if ($nb);
    print OUT "    <div><cite>Generated by idl2html</cite></div>\n";
}

sub _format_decl_file {
    my $self = shift;
    my ($node, $rlist, $filename) = @_;
    my $nb = 0;
    foreach (@{$rlist}) {
        my $idx = 'index_' . $_;
        if (keys %{$node->{$idx}}) {
            $nb ++;
            my $title = ucfirst $_;
            $title =~ s/_/ /g;
            print OUT "<h2>",$title,"s.</h2>\n";
            if (scalar keys %{$node->{$idx}}) {
                my $n = 0;
                foreach (sort values %{$node->{$idx}}) {
                    $n ++ if ($_->{filename} eq $filename);
                }
                if ($n) {
                    print OUT "<ul>\n";
                    foreach (sort keys %{$node->{$idx}}) {
                        my $child = $node->{$idx}->{$_};
                        next unless ($child->{filename} eq $filename);
                        print OUT "    <li>\n";
                        print OUT "      <h3><a id='",$_,"' name='",$_,"'/>",$_,"</h3>\n";
                        $self->_print_decl($child);
                        $self->_print_comment($child);
                        print OUT "    </li>\n";
                    }
                    print OUT "</ul>\n";
                }
            }
        }
    }
    $self->_sep_line() if ($nb);
    print OUT "    <div><cite>Generated by idl2html</cite></div>\n";
}

sub _examine_index {
    my $self = shift;
    my ($node, $idx, $htree) = @_;

    while (my ($idf, $defn) = each %{$node->{index_module}}) {
        $htree->{$idf} = {}
                if (!exists $htree->{$idf} or $htree->{$idf} == 1);
        $self->_examine_index($defn, $idx, $htree->{$idf});
        delete $htree->{$idf}
                unless (scalar keys %{$htree->{$idf}});
    }
    foreach (keys %{$node->{$idx}}) {
        $htree->{$_} = 1
                unless (exists $htree->{$_});
    }
}

sub _format_global_index {
    my $self = shift;
    my ($idx, $htree, $basename) = @_;

    print OUT "<ul>\n";
    foreach (sort keys %{$htree}) {
        my $full = $basename ? $basename . '::' . $_ : $_;
        my $filename = $full;
        $filename =~ s/::/_/g;
        $self->{first_filename} = $filename
                unless (exists $self->{first_filename});
        if ($self->{frameset}) {
            print OUT "    <li><a class='index' href='index._",$filename,".html'>";
        }
        else {
            print OUT "    <li><a class='index' href='_",$filename,".html#__Top__'>";
        }
        if ($htree->{$_} == 1) {
            print OUT $full,"</a></li>\n";
        }
        else {
            print OUT $full,"</a>\n";
            $self->_format_global_index($idx, $htree->{$_}, $full);
            print OUT "</li>\n";
        }
    }
    print OUT "</ul>\n";
}

sub _format_toc {
    my $self = shift;
    my ($idx, $htree, $basename) = @_;

    print OUT "        <UL>\n";     # no XHTML
    foreach (sort keys %{$htree}) {
        my $full = $basename ? $basename . '::' . $_ : $_;
        my $filename = $full;
        $filename =~ s/::/_/g;
        print OUT "          <LI> <OBJECT type=\"text/sitemap\">\n";
        print OUT "              <param name=\"Name\" value=\"",$_,"\">\n";
        print OUT "              <param name=\"Local\" value=\"_",$filename,".html\">\n";
        print OUT "            </OBJECT>\n";
        unless ($htree->{$_} == 1) {
            $self->_format_toc($idx, $htree->{$_}, $full);
        }
    }
    print OUT "        </UL>\n";
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;

    my @list_call = (
        'module',
        'interface',
        'value',
        'event',
        'component',
        'home'
    );
    foreach (@list_call) {
        my $idx = 'index_' . $_;
        foreach (values %{$node->{$idx}}) {
            $_->visit($self);
        }
    }

    my @list_decl = (
        'boxed_value',
        'type',
        'exception',
        'constant'
    );
    my %alone;
    foreach (@list_decl) {
        my $idx = 'index_' . $_;
        foreach (values %{$node->{$idx}}) {
            my $defn = $self->_get_defn($_);
            $alone{$defn->{filename}} = 1;
        }
    }
    foreach (keys %alone) {
        my $filename = '__' . basename($_, '.idl') . '.html';
        open OUT, '>', $filename
                or die "can't open $filename ($!).\n";

        $self->_format_head_main($filename);
        $self->_format_decl_file($node, \@list_decl, $_);
        $self->_format_tail(0);

        close OUT;
    }

    foreach (@list_call) {
        my $idx = 'index_' . $_;
        $self->_examine_index($node, $idx, $main::global->{$idx});
    }
    my $nb = 0;
    foreach (@list_call) {
        my $idx = 'index_' . $_;
        foreach (sort keys %{$main::global->{$idx}}) {
            $nb ++;
        }
    }
    if ($nb) {
        open OUT, '>', 'index.html'
                or die "can't open index.html ($!).\n";
        $self->{out} = \*OUT;

        $self->_format_head_global_index();
        foreach (@list_call) {
            my $idx = 'index_' . $_;
            if (keys %{$main::global->{$idx}}) {
                my $title = ucfirst $_;
                print OUT "<h2>All ",$title," index.</h2>\n";
                $self->_format_global_index($idx, $main::global->{$idx}, q{});
            }
        }
        unless ($self->{frameset}) {
            $self->_sep_line();
            print OUT "    <div><cite>Generated by idl2html</cite></div>\n";
        }
        $self->_format_tail(0);

        close OUT;
    }

    if ($self->{frameset}) {
        open OUT, '>', 'frame.html'
                or die "can't open frame.html ($!).\n";
        $self->{out} = \*OUT;

        $self->_format_head('Global index', 1);
        print OUT "  <frameset cols='25%,75%'>\n";
        print OUT "    <frameset rows='40%,60%'>\n";
        print OUT "      <frame src='index.html' id='global' name='global'/>\n";
        print OUT "      <frame src='index._",$self->{first_filename},"' id='local' name='local'/>\n";
        print OUT "    </frameset>\n";
        print OUT "    <frame src='_",$self->{first_filename},"#__Top__' id='main' name='main'/>\n";
        print OUT "    <noframes>\n";
        print OUT "      <body>\n";
        print OUT "        <h1>Sorry!</h1>\n";
        print OUT "        <h3>This page must be viewed by a browser that is capable of viewing frames.</h3>\n";
        print OUT "      </body>\n";
        print OUT "    </noframes>\n";
        print OUT "  </frameset>\n";
        $self->_format_tail(1);

        close OUT;
    }
    else {
        my $outfile = $self->{parser}->YYData->{opt_o} || 'htmlhelp';
        open OUT, '>', "$outfile.hhp"
                or die "can't open $outfile.hhp ($!).\n";

        my $title = $self->{parser}->YYData->{opt_t};
        print OUT "[OPTIONS]\n";
        print OUT "Binary TOC=Yes\n";
        print OUT "Compatibility=1.1 or later\n";
        print OUT "Compiled file=",$outfile,".chm\n";
        print OUT "Contents file=toc.hhc\n";
        print OUT "Default Window=Main\n";
        print OUT "Default topic=index.html\n";
        print OUT "Display compile progress=Yes\n";
        print OUT "Full-text search=Yes\n";
        print OUT "Index file=index.hhk\n";
        print OUT "Language=0x0409 English (UNITED STATES)\n";
        print OUT "Title=",$title,"\n" if ($title);
        print OUT "\n";
        print OUT "[WINDOWS]\n";
        print OUT "Main=,\"toc.hhc\",\"index.hhk\",\"index.html\",\"index.html\",,,,,0x22520,,0x603006,,,,,,,,0\n";
        print OUT "\n";
        print OUT "[FILES]\n";
        print OUT "index.html\n";
        foreach (@list_call) {
            my $idx = 'index_' . $_;
            foreach (sort keys %{$main::global->{$idx}}) {
                print OUT "_",$_,".html\n"
                        if ($main::global->{$idx}->{$_} == 1 or $idx eq 'index_module');
            }
        }

        close OUT;

        open OUT, '>', 'toc.hhc'
                or die "can't open toc.hhc ($!).\n";

        print OUT "<HTML>\n";       # no XHTML
        print OUT "  <HEAD>\n";
        print OUT "    <meta name=\"generator\" content=\"idl2html ",$CORBA::HTML::VERSION," (Perl ",$],")\">\n";
        print OUT "  </HEAD>\n";
        print OUT "  <BODY>\n";
        print OUT "    <OBJECT type=\"text/site properties\">\n";
        print OUT "      <param name=\"ImageType\" value=\"Folder\">\n";
        print OUT "    </OBJECT>\n";
        print OUT "    <UL>\n";
        foreach (@list_call) {
            my $idx = 'index_' . $_;
            if (keys %{$main::global->{$idx}}) {
                my $title = ucfirst $_;
                print OUT "      <LI> <OBJECT type=\"text/sitemap\">\n";
                print OUT "          <param name=\"Name\" value=\"",$title,"\">\n";
                print OUT "          <param name=\"ImageNumber\" value=\"1\">\n";
                print OUT "        </OBJECT>\n";
                $self->_format_toc($idx, $main::global->{$idx}, q{});
            }
        }
        print OUT "    </UL>\n";
        print OUT "  </BODY>\n";
        print OUT "</HTML>\n";

        close OUT;

        foreach my $scope (values %{$self->{symbtab}->{scopes}}) {
            foreach my $defn (values %{$scope->{entry}}) {
                next unless (exists $defn->{file_html});
                if (       $defn->isa('StateMember')
                        or $defn->isa('Initializer')
                        or $defn->isa('BoxedValue')
                        or $defn->isa('Constant')
                        or $defn->isa('TypeDeclarator')
                        or $defn->isa('StructType')
                        or $defn->isa('UnionType')
                        or $defn->isa('EnumType')
                        or $defn->isa('Enum')
                        or $defn->isa('Exception')
                        or $defn->isa('Provides')
                        or $defn->isa('Uses')
                        or $defn->isa('Emits')
                        or $defn->isa('Publishes')
                        or $defn->isa('Consumes')
                        or $defn->isa('Factory')
                        or $defn->isa('Finder') ) {
                    my $anchor = $defn->{file_html} . "#" . $defn->{idf};
                    $main::global->{index_entry}->{$anchor} = $defn->{idf};
                }
            }
        }

        open OUT, '>', 'index.hhk'
                or die "can't open index.hhk ($!).\n";

        print OUT "<HTML>\n";       # no XHTML
        print OUT "  <HEAD>\n";
        print OUT "    <meta name=\"generator\" content=\"idl2html ",$CORBA::HTML::VERSION," (Perl ",$],")\">\n";
        print OUT "  </HEAD>\n";
        print OUT "  <BODY>\n";
        print OUT "    <UL>\n";
        while (my ($key, $val) = each %{$main::global->{index_entry}}) {
            print OUT "      <LI> <OBJECT type=\"text/sitemap\">\n";
            print OUT "          <param name=\"Name\" value=\"",$val,"\">\n";
            print OUT "          <param name=\"Local\" value=\"",$key,"\">\n";
            print OUT "        </OBJECT>\n";
        }
        print OUT "    </UL>\n";
        print OUT "  </BODY>\n";
        print OUT "</HTML>\n";

        close OUT;
    }
    if ($self->{css}) {
        my $outfile = $self->{css} . '.css';
        unless ( -e $outfile) {
            open OUT, '>', $outfile
                    or die "can't open $outfile ($!)\n";
            print OUT $self->{style};
            close OUT;
        }
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    my $scope_save = $self->{scope};
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list_call = (
        'module',
        'interface',
        'value',
        'event',
        'component',
        'home'
    );
    my @list_idx = (
        'module',
        'interface',
        'value',
        'type',
        'exception',
        'constant',
        'event',
        'component',
        'home'
    );
    my @list_decl = (
        'boxed_value',
        'type',
        'exception',
        'constant'
    );

    foreach (@list_call) {
        my $idx = 'index_' . $_;
        foreach (values %{$node->{$idx}}) {
            $_->visit($self);
        }
    }

    foreach (keys %{$node->{index_boxed_value}}) {
        $node->{index_value}->{$_} = $node->{index_boxed_value}->{$_};
    }

    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Module ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list_idx)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list_decl);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list_idx);
        $self->_format_tail(0);

        close OUT;
    }

    $self->{scope} = $scope_save;
}

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my ($node) = @_;
    my $scope_save = $self->{scope};
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Interface ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }

    $self->{scope} = $scope_save;
}

sub visitAbstractInterface {
    my $self = shift;
    my ($node) = @_;
    my $scope_save = $self->{scope};
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Abstract Interface ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }

    $self->{scope} = $scope_save;
}

sub visitLocalInterface {
    my $self = shift;
    my ($node) = @_;
    my $scope_save = $self->{scope};
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Local Interface ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }

    $self->{scope} = $scope_save;
}

#
#   3.9     Value Declaration
#

sub visitRegularValue {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant',
        'state_member',
        'initializer'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Value Type ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }
}

sub visitAbstractValue {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Abstract Value Type ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }
}

#
#   3.16    Event Declaration
#

sub visitRegularEvent {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant',
        'state_member',
        'initializer'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Event Type ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }
}

sub visitAbstractEvent {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Abstract Event Type ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'provides',
        'uses',
        'publishes',
        'consumes',
        'attribute'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Component ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }
}

#
#   3.18    Home Declaration
#

sub visitHome {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    $self->{scope} =~ s/^:://;
    my $title = $self->{scope};
    my @list = (
        'operation',
        'attribute',
        'type',
        'exception',
        'constant',
        'factory',
        'finder'
    );
    open OUT, '>', $node->{file_html}
            or die "can't open $node->{file_html} ($!).\n";

    $self->_format_head_main('Home ' . $title);
    $self->_print_decl($node);
    $self->_print_comment($node);
    $self->_sep_line();
    $self->_format_index($node, \@list)
            unless ($self->{frameset});
    $self->_format_decl($node, \@list);
    $self->_format_tail(0);

    close OUT;

    if ($self->{frameset}) {
        open OUT, '>', "index.$node->{file_html}"
                or die "can't open index.$node->{file_html} ($!).\n";

        $self->_format_head_index($title);
        $self->_format_index($node, \@list);
        $self->_format_tail(0);

        close OUT;
    }
}

1;

