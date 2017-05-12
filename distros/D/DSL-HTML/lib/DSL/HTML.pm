package DSL::HTML;
use strict;
use warnings;

use Carp qw/croak carp/;
use Scalar::Util qw/blessed/;

use Exporter::Declare::Magic qw{
    import
    export
    default_export
    gen_export
    gen_default_export
};

use DSL::HTML::Parser;
use DSL::HTML::Template;
use DSL::HTML::Rendering;
use HTML::Element;

our $VERSION = '0.006';

sub after_import {
    my $class = shift;
    my ( $importer, $specs ) = @_;

    inject_meta($importer);
}

sub inject_meta {
    my ($importer) = @_;

    return $importer->DSL_HTML
        if $importer->can('DSL_HTML');

    my $meta = {};

    {
        no strict 'refs';
        *{"$importer\::DSL_HTML"} = sub { $meta };
    }

    return $meta;
}

default_export import {
    my $class = shift;

    my $caller = caller;
    my $imeta  = inject_meta($caller);
    my $meta   = $class->DSL_HTML;

    my @want = @_ ? @_ : keys %$meta;

    for my $template (@want) {
        if ( $imeta->{$template} ) {
            carp "'$template' already defined in class '$caller', not replacing";
            next;
        }

        $imeta->{$template} = $meta->{$template}
            || carp "'$template' is not defined by '$class'";
    }

    return 1 if $caller->can('build_template');

    no strict 'refs';
    *{"$caller\::build_template"} = \&build_template;

    return 1;
}

default_export template dsl_html {
    my $name = shift;
    die "Template name is required" unless $name;
    my ( $params, $block );
    if ( @_ == 1 ) {
        $block  = pop @_;
        $params = {};
    }
    else {
        $params = {@_};
        $block  = delete $params->{block};
    }

    my $template = DSL::HTML::Template->new( $name, $params, $block );
    return $template if defined wantarray;

    caller->DSL_HTML->{$name} = $template;
}

default_export tag dsl_html {
    my $name = shift;
    croak "tag name is required" unless $name;
    my ( $params, $block );
    if ( @_ == 1 ) {
        $block  = pop @_;
        $params = {};
    }
    else {
        $params = {@_};
        $block  = delete $params->{block};
    }

    check_nesting('tag');
    my $rendering = DSL::HTML::Rendering->current;

    my $tag;
    if ( $name =~ m/^head$/i ) {
        $tag = $rendering->head;
    }
    elsif ( $name =~ m/^body$/i ) {
        $tag = $rendering->body;
    }
    elsif ( $name =~ m/^html$/i ) {
        $tag = $rendering->root;
    }
    else {
        $tag = HTML::Element->new( $name, %$params );
        $rendering->insert($tag);
    }

    $rendering->push_tag($tag);
    my @result;
    my $success = eval {
        @result = $block->($tag);
        1;
    };
    my $error = $@;
    $rendering->pop_tag($tag);
    die $error unless $success;

    $tag->push_content(@result)
        if @result && !ref $result[0] && !$tag->content_list;

    return;
}

default_export get_template {
    my $name = pop;
    my $from = $_[0] || caller;
    return $from->DSL_HTML->{$name};
}

default_export 'build_template';

sub build_template {
    my ( $template, @args ) = @_;
    my $caller = caller;

    $template->compile(@args)
        if blessed($template)
        && $template->isa('DSL::HTML::Template');

    croak "No such template '$template'"
        unless $caller->DSL_HTML->{$template};

    return $caller->DSL_HTML->{$template}->compile(@args);
}

default_export include {
    my ( $template, @args ) = @_;
    my $caller = caller;

    check_nesting('include');

    my $tmp =
        blessed($template)
        ? $template
        : $caller->DSL_HTML->{$template};

    croak "No such template '$template'"
        unless $tmp;

    DSL::HTML::Rendering->current->include( $tmp, @args );

    return;
}

default_export text {
    my ($content) = @_;
    check_nesting('text');
    DSL::HTML::Rendering->current->peek_tag->push_content("$content");
    return;
}

default_export css {
    check_nesting('css');
    DSL::HTML::Rendering->current->add_css(@_);
    return;
}

default_export js {
    check_nesting('js');
    DSL::HTML::Rendering->current->add_js(@_);
    return;
}

default_export attr {
    check_nesting('attr');
    my $tag = DSL::HTML::Rendering->current->peek_tag;
    return unless @_;
    my $attrs = @_ < 2 ? shift : {@_};
    $tag->attr( $_ => $attrs->{$_} ) for keys %$attrs;
    return;
}

default_export add_class {
    check_nesting('add_class');

    my $tag = DSL::HTML::Rendering->current->peek_tag;
    my $existing = $tag->attr('class') || "";

    my %seen;
    my $new = join " ", sort grep { !$seen{$_}++ } @_, split /\s+/, $existing;
    $tag->attr( class => $new );

    return;
}

default_export del_class {
    check_nesting('del_class');

    my $tag = DSL::HTML::Rendering->current->peek_tag;
    my $existing = $tag->attr('class') || "";

    my %seen = map { $_ => 1 } @_;
    my $new = join " ", sort grep { !$seen{$_}++ } split /\s+/, $existing;
    $tag->attr( class => $new );

    return;
}

sub check_nesting {
    my ($sub) = @_;
    return if DSL::HTML::Rendering->current;
    croak "No template stack found, '$sub()' must have been called outside of a template.";
}

1;

__END__

=head1 NAME

DSL::HTML - Declarative DSL(domain specific language) for writing HTML
templates within perl.

=head1 DESCRIPTION

B<Templating systems suck.> This sucks less.

In most cases a templating system lets you write html files with embedded
logic. The embedded logic can be a template specific language, or it can let
you embed code from the projects programming language.

An alternative that has been played with is constructing the HTML directly in
your application language. In most cases this B<sucks more>. OOP, where objects
are built and then associated via method calls is B<NOT> a friendly way to
build a complex tree.

DSL::HTML takes the alternative approach, but does it in a significantly more
elegent way. Instead of forcing you to construct objects and build a tree
manually via methods, you define the tree via nested subroutines. This is sort
of a functional approach to tree building.

=head2 EARLY VERSION WARNING

B<THIS IS AN EARLY VERSION!> Basically I have not decided 100% that the API
will remain as-is (though it likely will not change much). I am also embarrased
to admit that this code is very poorly tested (Yes, this is more embarrasing
considering I wrote L<Fennec>).

=head2 BENEFITS

=over 4

=item The template language is perl

There is no embedded template language, your logic is all in perl, you treat
all tags like perl objects. The nested block syntax allows this while also
saving you from the PITA of direct object manipulation; that is you do not need
to say C<$tag-E<gt>insert(Tag-E<gt>new)> or similar.

=item No need to hand-write html

Hand-written HTML is easy to screw up. You might forget to close a tag, or nest
things improperly. The nature of browsers it to try to make it work anyway, so
you can sometimes spend hours debugging broken html.

=item Syntax checking is done by perl

The nested-blok syntax is checked by perl. If you make a syntax error, or a
typo, perl will typically catch your mistake when you try to build the package.

=item Templates and tags are built like subroutines

This means you call your template with argumnets similar to how you can any
function with arguments.

=item Templates can be imported/exported between modules.

You can create perl modules that are simply template libraries, other modules
can load these libraries to gain access to the templates.

=back

=head1 SYNOPSYS

    # Note: This brings in an import() method.
    # See the EXPORTS - import() section later in this doc for more info.
    use DSL::HTML;

    template my_template {
        my @options = @_;

        # The lexical variable '$tag' is defined for you automatically and is a
        # reference to the current tag on the stack (usually <body>)
        $tag->attr( foo => 'bar' );

        css 'my/css/file.css'; # Goes to the header

        tag h1 { "Welcome!" }

        tag h2 { "Choices:" }

        # Tags nest naturally, here is a <ul> with nested <li>s
        # Tags can be nested to any depth.
        tag ul {
            my $n = 1;
            for my $option (@options) {
                my $zebra = $n++ % 2 ? 'odd' : 'even';

                tag li(class => $zebra) { $option }
            }
        }

        # Include another template, with arguments if desired.
        include some_other_template => ( ... );

        tag div(class => 'footer') {
            # the lexical $tag is defined for you, and is the tag currently
            # being built.
            $tag->attr( foo => 'bar' );
            tag span { 'copyright &copy;' }
            text "foobar incorperated";
        }
    }

    my $html1 = build_template my_template => qw/foo bar baz/;
    my $html2 = build_template my_template => qw/bat ban boo/;

B<Note:> Any source file that uses the package defined above would
automatically gain all the templates defined within, as well as the
'build_template' function.

=head1 GUTS

This package works via a stack system. When you build a template a rendering
object is pushed onto a stack, the codeblock you provided is then executed. Any
tags defined at this point get added to the rendering object at the top of the
stack.

When a tag is defined it is pushed to the top of the stack, then the codeblock
for it is run. In this way you can create a nested HTML structure. After all
the nested codeblocks are executed, the html content is built from the object
tree.

Because of this stack system you can also write helper objects or functions
which themselves call tag, or any other export provided by this package, so
long as those helpers are called (no matter how indirectly) from within a
template codeblock you are fine.

=head1 CONVERTING EXISTING HTML INTO TEMPLATES

L<DSL::HTML::Compiler> can be used to convert existing HTML into DSL::HTML
templates.

=head1 STANDARD TEMPLATE LIBRARY

L<DSL::HTML::STL> is a library of templates available to use.

=head1 EXPORTS

=over 4

=item import()

When you C<use> L<DSL::HTML> it will inject a method called C<import> into your
package. This is done so that anyone that loads your package via C<use> will
gain all your templates, as well as the C<build_template> function.

B<Note:> This will cause a conflict if you use it in any module that uses
L<Exporter>, L<Exporter::Declare>, or similar exporter modules. To prevent this
you can tell L<DSL::HTML> not to inject C<import()> at use time, either by
rejecting it specifically, or by specifying with functions you do want:

Outright rejection:

    use DSL::HTML qw/-default !import/;

Just what you want:

    use DSL::HTML qw/template tag css js build_template get_template include/;

If you do either of these then loading your template package will NOT make your
templates available to the package loading it, but you can get them via:

    use Your::Package();
    my $tmp = Your::Package->get_template('the_template');
    my $html = $tmp->compile( ... );

=item template NAME(%PARAMS) { ... }

=item template NAME { ... }

=item $t = template NAME(%PARAMS) { ... }

=item $t = template NAME { ... }

Define a template. If the return value is ignored the template will be inserted
into the current package metadata. If you capture the return value then nothing
is stored in the meta-data.

Parameters are optional, currently the only used parameter is 'indent' which
can be set to any string, but you probably want "\t" or "    ".

B<Note:> the lexical variable C<$tag> is defined for you, and contains the tag
currently being built. In most cases this is the C<body> tag, however when you
C<include '...'> a template the tag will be whatever tag the template is
included into.

An L<DSL::HTML::Template> object is created.

=item tag NAME(%ATTRIBUTES) { ... }

=item tag NAME { ... }

=item tag NAME { "simple text" }

Define a tag. Never returns anything. All attributes are optional, any may be
specified.

B<Note:> the lexical variable C<$tag> is defined for you. This variable
contains the tag being built (the one your block is defining.)

Calls to tag must be made within a template, they will not work anywhere else
(though because of the stack you may call tag() within a function or method
that you call within a template).

If the codeblock does not add any text or tag elements to the tag, and you
return a simple string from the codelbock, the string will be added as a text
element. This allows for shortcutting tags that only contain basic text.

B<Note:> the 'head', 'body' and 'html' tags have special handling. Every time
you call C<tag head {...}> within a template you get the same tag object. The
same behavior applies to the body tag.

You can and should nest calls to tag, this allows you to create a tag tree.

    template foo {
        tag parent {
            tag child {
                ...
            }
        }
    }

Under the hood an L<HTML::Element> is created for each tag.

=item text "...";

Define a text element in the current template/tag.

Under the hood an L<HTML::Element> is created.

=item css "path/to/file.css";

Append a css file to the header. This can be called multiple times, each path
will only be included once.

=item js "path/to/file.js";

Append a js file to the end of the <html> tag. This can be called multiple times, each path
will only be included once.

=item attr name => 'val', ...;

=item attr { name => 'val' };

Set specific attributes in the current tag. Arguments may be hashref or
key/value list.

=item add_class 'name';

Add a class to the current tag.

=item del_class 'name';

Remove a class from the current tag.

=item $html = build_template $TEMPLATE => @ARGS

=item $html = build_template $TEMPLATE, @ARGS

=item $html = build_template $TEMPLATE

Build html from a template given specific arguments (optional). Template may be
a template name which will can be found in the current package meta-data, or it
can be an L<DSL::HTML::Template> object.

=item include $TEMPLATE => @ARGS

=item include $TEMPLATE, @ARGS

=item include $TEMPLATE

Nest the result of building another template within the current one.

=item $tmp = get_template($name)

=item $tmp = PACKAGE->get_template($name)

=item $tmp = $INSTANCE->get_template($name)

Get a template. When used as a function it will find the template in the
current package meta-data. When called as a method on a class or instance it
will find the template in the metadata for that package.

=back

=head1 WHOAH! NICE SYNTAX

The syntax is provided via L<Exporter::Declare> which uses L<Devel::Declare>.

=head1 EXAMPLES

=head2 TEMPLATE PACKAGE

    package My::Templates;
    use strict;
    use warnings;

    use DSL::HTML;

    template ulist {
        # DSL::HTML::Rendering.
        my @items = @_;

        css 'ulist.css';

        tag ul(class => 'my_ulist') {
            for my $item (@items) {
                tag li { $item }
            }
        }
    }

    template list_pair {
        my ($items_a, $items_b) = @_;
        include ulist => @$items_a; # Using the ulist template above
        include ulist => @$items_b; # " "
    }

    1;

Now to use it:

    # This will import the 'build_template' function, as well as all the
    # templates defined by the package. You can request only specific templates
    # by passing them as arguments to the use statement.
    use My::Templates;

    my $html = build_template list_pair => (
        [qw/red green blue/],
        [qw/one two three/],
    );

    print $html;

Should give us:

    <html>
        <head>
            <link type="text/css" rel="stylesheet" href="ulist.css" />
        </head>

        <body>
            <ul class="my_ulist">
                <li>
                    red
                </li>
                <li>
                    green
                </li>
                <li>
                    blue
                </li>
            </ul>
            <ul class="my_ulist">
                <li>
                    one
                </li>
                <li>
                    two
                </li>
                <li>
                    three
                </li>
            </ul>
        </body>
    </html>


=head2 TEMPLATE OBJECT

If you do not like defining templates as package meta-data you can use them in
a less-meta form:

    use strict;
    use warnings;

    use DSL::HTML;

    my $ulist = template ulist {
        # DSL::HTML::Rendering.
        my @items = @_;

        css 'ulist.css';

        tag ul(class => 'my_ulist') {
            for my $item (@items) {
                tag li { $item }
            }
        }
    }

    my $list_pair = template list_pair {
        my ($items_a, $items_b) = @_;
        $ulist->include( @$items_a ); # Using the ulist template above
        $ulist->include( @$items_b ); # " "

        # Alternatively you could do:
        # include $ulist => ...;
        # the 'include' keyword works with at emplate object as an argument
    }

    my $html = $list_pair->compile(
        [qw/red green blue/],
        [qw/one two three/],
    );

    # You could also do:
    # build_template $list_pair => (...);

    print $html;

Should give us:

    <html>
        <head>
            <link type="text/css" rel="stylesheet" href="ulist.css" />
        </head>

        <body>
            <ul class="my_ulist">
                <li>
                    red
                </li>
                <li>
                    green
                </li>
                <li>
                    blue
                </li>
            </ul>
            <ul class="my_ulist">
                <li>
                    one
                </li>
                <li>
                    two
                </li>
                <li>
                    three
                </li>
            </ul>
        </body>
    </html>


=head1 SEE ALSO

=over 4

=item HTML::Declare

L<HTML::Declare> seems to be a similar idea, but I dislike the feel of it. That
said still have to give the author props for doing it as good as possible
without L<Devel::Declare>.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

DSL-HTML is free software; Standard perl license (GPL and Artistic).

DSL-HTML is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
