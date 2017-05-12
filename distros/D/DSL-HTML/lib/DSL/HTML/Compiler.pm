package DSL::HTML::Compiler;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;

use Exporter::Declare qw/import default_exports/;
use HTML::TreeBuilder;

default_exports qw{
    compile_from_html
    compile_from_file
};

sub delimiters {
    return qw{
        '
        "
        `
        /
        |
        :
        ~
        !
        -
        ⌁
    }
}

sub compile_from_file {
    my ($name, $file) = @_;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($file);
    return compile_from_tree($name, $tree);
}

sub compile_from_html {
    my ($name, $text) = @_;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($text);
    $tree->eof;
    return compile_from_tree($name, $tree);
}

sub compile_from_tree {
    my ($name, $tree) = @_;
    $tree->elementify;

    my $out;

    $out = "use strict;\nuse warnings;\nuse utf8;\nuse DSL\::HTML;\n\ntemplate $name {\n";
    process_element( \$out, $tree, 1 );
    $out .= "}\n\n1;\n";

    return $out;
}

sub find_delimiter {
    my ($content) = @_;
    for my $d ( delimiters(), 'a' .. 'z', 'A' .. 'Z' ) {
        return $d unless $content =~ m/$d/;
    }

    croak "Could not find a usable delimiter";
}

sub process_element {
    my ($out, $elem, $indent) = @_;

    my $prefix = "    " x $indent;

    unless (ref $elem) {
        my $d = find_delimiter($elem);
        $$out .= "${prefix}text q${d}${elem}${d};\n";
        return;
    }

    my $has_content = $elem->content_list;

    if ( !$has_content && $elem->tag =~ m/^script$/i && $elem->attr('src')) {
        my $src = $elem->attr('src');
        my $d = find_delimiter($src);
        $$out .= qq|${prefix}js q${d}${src}${d};\n|;
        return;
    }

    if ( !$has_content && $elem->tag =~ m/^link$/i ) {
        my %attr = $elem->all_attr;
        if ($attr{rel} && $attr{href} && $attr{type} eq 'text/css') {
            my $href = $attr{href};
            my $d = find_delimiter($href);
            $$out .= qq|${prefix}css q${d}${href}${d};\n|;
            return;
        }
    }

    unless ($elem->tag =~ m/^(html|body)$/i) {
        my $tag = $elem->tag;
        my $attr = build_attr($elem);
        $$out .= "${prefix}tag ${tag}${attr} {";
        if ($has_content) {
            $$out .= "\n";
            process_children($out, $elem, $indent + 1);
            $$out .= "${prefix}";
        }
        $$out .= "}\n";
        return;
    }

    process_children($out, $elem, $indent);
}

sub process_children {
    my ($out, $elem, $indent) = @_;
    my @children = $elem->content_list;
    for ( my $i = 0; $i < @children; $i++ ) {
        process_element($out, $children[$i], $indent);
        $$out .= "\n" unless $i == (@children - 1);
    }
}

sub build_attr {
    my ($elem) = @_;
    my %attr = $elem->all_attr;
    my @keys = sort grep { $_ !~ m/^_/ && $_ ne '/' } keys %attr;

    return "" unless @keys;

    my $text = join ", " => map {
        my $v = $attr{$_};
        my $d = find_delimiter($v);
        qq|'$_' => q${d}${v}${d}|
    } @keys;

    return "($text)";
}

1;

__END__

=encoding UTF-8

=head1 NAME

DSL::HTML::Compiler - Compile HTML into L<DSL::HTML> templates

=head1 DESCRIPTION

This module provides functions that let you take HTML files or strings and
convert them into L<DSL::HTML> templates. This is particularily useful if you
have a designer build your page layout in HTML and need to convert it to a
template before adding logic.

=head1 SYNOPSYS

    use strict;
    use warnings;
    use utf8;
    use DSL::HTML::Compiler;

    my $tc = compile_from_file( 'bar', "/path/to/file.html" );

    my $template_code = compile_from_html( 'foo', <<EOT );
    <html>
        <head>
            <title>foo</title>
            <link href="b.css" rel="stylesheet" type="text/css" />
            <script src="a.js"></script>
        </head>

        <body>
            <div id="foo" class="bar baz">
                xxx
            </div>
            <p>
            yyyy
            <div id="foo" class="bar baz">
                xxx
            </div>
        </body>
    </html>
    EOT

    # Only necessary if your html contains utf8, or in some cases when no ascii
    # character can be used as a delimiter due to text content.
    binmode STDOUT, ":utf8";
    print $template_code;

This will print the following that can be inserted into a perl module:

    use strict;
    use warnings;
    use utf8;
    use DSL::HTML;

    template foo {
        tag head {
            tag title {
                text q'foo';
            }

            css q'b.css';

            js q'a.js';
        }

        tag div('class' => q'bar baz', 'id' => q'foo') {
            text q' xxx ';
        }

        tag p {
            text q' yyyy ';

            tag div('class' => q'bar baz', 'id' => q'foo') {
                text q' xxx ';
            }
        }
    }

    1;

Delimiter for qX...X is chosen via a fall-through (see C<delimiters>)

=head1 DELIMITERS

Delimiter is chosen from this list, the first delimiter not found in the string
being quoted is used. If no valid delimiter can be found then an exception is
thrown.

=over 4

=item '

=item "

=item `

=item /

=item |

=item :

=item ~

=item !

=item -

=item ⌁

This one is unicode

=item a..z A..Z

If all else fails try a-z and A-Z.

=back

=head1 EXPORTS

=over 4

=item my $perl_code = compile_from_html( $name, $html )

Build perl code from html text.

=item my $perl_code = compile_from_file( $name, $file )

Build perl code from an html file.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

DSL-HTML is free software; Standard perl license (GPL and Artistic).

DSL-HTML is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
