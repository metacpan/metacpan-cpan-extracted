package Catalyst::View::ByCode;
$Catalyst::View::ByCode::VERSION = '0.28';
use Moose;
extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

has extension    => (is => 'rw', default => '.pl');
has root_dir     => (is => 'rw', default => 'root/bycode');
has wrapper      => (is => 'rw', default => 'wrapper.pl');
has include      => (is => 'rw', default => sub { [] });
has content_type => (is => 'rw', default => 'text/html ; charset=utf-8');

# Config Options:
#    root_dir => 'bycode',
#    extension => '.pl',
#    wrapper => 'wrapper.pl', # will be overridden by stash{wrapper}
#    include => [...] -- packages to use in every template
#
# Stash Variables:
#    template => 'path/to/template'
#    yield => { name => 'path/to/yield' }
#    wrapper => 'path/to/wrapper'
#
#    set by Catalyst (we need them!):
#      - current_view 
#      - current_view_instance
#
#

use Catalyst::View::ByCode::Renderer qw(:markup);
use Catalyst::Utils;
use UUID::Random;
use Path::Class::File;
use File::Spec;

our $compiling_package; # local() ized during a compile

=head1 NAME

Catalyst::View::ByCode - Templating using pure Perl code

=head1 VERSION

version 0.28

=head1 SYNOPSIS

    # 1) use the helper to create your View
    ./script/myapp_create.pl view ByCode ByCode


    # 2) inside your Controllers do business as usual:
    sub index :Path :Args(0) {
        my ($self, $c) = @_;
        
        # unless defined as default_view in your config, specify:
        $c->stash->{current_view} = 'ByCode';
        
        $c->stash->{title} = 'Hello ByCode';
        
        # if omitted, would default to 
        # controller_namespace / action_namespace .pl
        $c->stash->{template} = 'hello.pl';
    }


    # 3) create a simple template eg 'root/bycode/hello.pl'
    # REMARK: 
    #    use 'c' instead of '$c'
    #    prefer 'stash->{...}' to 'c->stash->{...}'
    template {
        html {
            head {
                title { stash->{title} };
                load Js => 'site.js';
                load Css => 'site.css';
            };
            body {
                div header.noprint {
                    ul.topnav {
                        li { 'home' };
                        li { 'surprise' };
                    };
                };
                div content {
                    h1 { stash->{title} };
                    div { 'hello.pl is running!' };
                    img(src => '/static/images/catalyst_logo.png');
                };
            };
        };
    };
    # 274 characters without white space
    
    
    # 4) expect to get this HTML generated:
    <html>
      <head>
        <title>Hello ByCode!</title>
        <script src="http://localhost:3000/js/site.js"
                type="text/javascript">
        </script>
        <link rel="stylesheet"
              href="http://localhost:3000/css/site.css"
              type="text/css" />
      </head>
      <body>
        <div id="header" style="noprint">
          <ul class="topnav">
            <li>home</li>
            <li>surprise</li>
          </ul>
        </div>
        <div class="content">
          <h1>Hello ByCode!</h1>
          <div>hello.pl is running!</div>
          <img src="/static/images/catalyst_logo.png" />
        </div>
      </body>
    </html>
    # 453 characters without white space

=head1 DESCRIPTION

C<Catalyst::View::ByCode> tries to offer an efficient, fast and robust
solution for generating HTML and XHTML markup using standard perl code
encapsulating all nesting into code blocks.

Instead of typing opening and closing HTML-Tags we simply call a
sub named like the tag we want to generate:

    div { 'hello' }
    
generates:

    <div>hello</div>

There is no templating language you will have to learn, no quirks with
different syntax rules your editor might not correctly follow and no
indentation problems.

The whole markup is initially constructed as a huge tree-like
structure in memory keeping every reference as long as possible to
allow greatest flexibility and enable deferred construction of every
building block until the markup is actially requested.

Every part of the markup can use almost every type of data with some
reasonable behavior during markup generation.

=head2 Tags

Every tag known in HTML (or defined in L<HTML::Tagset> to be precise) gets
exported to a template's namespace during its compilation and can be used as
expected. However, there are some exceptions which would collide with CORE
subs or operators

=over 12

=item choice

generates a E<lt>selectE<gt> tag

=item link_tag

generates a E<lt>linkE<gt> tag

=item trow

generates a E<lt>trE<gt> tag

=item tcol

generates a E<lt>tdE<gt> tag

=item subscript

generates a E<lt>subE<gt> tag

=item superscript

generates a E<lt>supE<gt> tag

=item meta_tag

generates a E<lt>metaE<gt> tag

=item quote

generates a E<lt>qE<gt> tag

=item strike

generates a E<lt>sE<gt> tag

=item map_tag

generates a E<lt>mapE<gt> tag

=back

Internally, every tag subroutine is defined with a prototype like

    sub div(;&@) { ... }

Thus, the first argument of this sub is expected to be a coderef, which allows
to write code like the examples above. Nesting tags is just a matter of
nesting calls into blocks.

=head2 Content

There are several ways to generate content which is inserted between the
opening and the closing tag:

=over

=item

The return value of the last expression of a code block will get appended to
the content inside the tag. The content will get escaped when needed.

=item

To append any content (getting escaped) at any point of the markup generation,
the C<OUT> glob can be used:

    print OUT 'some content here.';

=item

To append unescaped content eg JavaScript or the content of another
markup-generating subsystem like C<HTML::FormFu> simple use the <RAW> glob:

    print RAW '<?xxx must be here for internal reasons ?>';

=back

=head2 Attributes

As usual for Perl, there is always more than one way to do it:

=over

=item old-school perl

    # appending attributes after tag
    div { ... content ... } id => 'top', 
                            class => 'noprint silver',
                            style => 'display: none';

the content goes into the curly-braced code block immediately following the
tag. Every extra argument after the code block is converted into the tag's
attributes.

=item special content

    # using special methods
    div {
        id 'top';
        class 'noprint silver';
        attr style => 'display: none';
        
        'content'
    };

Every attribute may be added to the latest opened tag using the C<attr> sub. However, there are some shortcuts:

=over 8

=item id 'name'

is equivalent to C<<< attr id => 'name' >>>

=item class 'class'

is the same as C<<< attr class => 'class' >>>

However, the C<class> method is special. It allows to specify a
space-separated string, a list of names or a combination of both. Class names
prefixed with C<-> or C<+> are treated special. After a minus prefixed class
name every following name is subtracted from the previous list of class names.
After a plus prefixed name all following names are added to the class list. A
list of class names without a plus/minus prefix will start with an empty class
list and then append all subsequentially following names.

    # will yield 'abc def ghi'
    div.foo { class 'abc def ghi' };
    
    # will yield 'foo def xyz'
    div.foo { class '+def xyz' };
    
    # will yield 'bar'
    div.foo { class '-foo +bar' };

=item on handler => 'some javascript code'

produces the same result as C<attr onhandler => 'some javascript code'>

    div {
        on click => q{alert('you clicked me')};
    };

=back

=item tricky arguments

    div top.noprint.silver(style => 'display: none') {'content'};

=item even more tricky arguments

    div top.noprint.silver(style => {display => 'none'}) {'content'};

=item tricky arguments and CamelCase

    div top.noprint.silver(style => {marginTop => '20px'}) {'foo'};

C<marginTop> or C<margin_top> will get converted to C<margin-top>.

=item handling scalar refs

    div (data_something => \'<abcd>') { ... };

will not escape the ref-text <abcd>.

=item code refs

    div (id => \&get_next_id) { ... };

will call get_next_id() and set its return value as a value for id and in case
of special characters, escapes it.

=back

Every attribute may have almost any datatype you might think of:

=over

=item scalar

Scalar values are taken verbatim.

=item hashref

Hash references are converted to semicolon-delimited pairs of the key, a colon
and a value. The perfect solution for building inline CSS. Well, I know,
nobody should do something, but sometimes...

Keys consisting of underscore characters and CAPITAL letters are converted to
dash-separated names. C<dataTarget> or C<data_target> both become C<data-target>.

=item arrayref

Array references are converted to space separated things.

=item coderef -- FIXME: do we like this?

no idea if we like this

=item other refs

all other references simply are stringified. This allows the various objects
to forward stringification to their class-defined code.

=back


=head2 Exported subs

=over

=item attr

Setter or Getter for attribute values. Using the C<attr> sub refers to the
latest open tag and sets or gets its attribute(s):

    div {
        attr(style => 'foo:bar');  # set 'style' attribute
        attr('id'); # get 'id' attribute (or undef)
        
        ... more things ...
        a {
            attr(href => 'http://foo.bar'); # refers to 'a' tag
        };
        
        attr(lang => 'de'); # sets attribute in 'div' tag
    };

=item block

define a block that may be used like a tag. If a block is defined in a
package, it is automatically added to the package's C<@EXPORT> array.

    # define a block
    block navitem {
        my $id   = attr('id');
        my $href = attr('href');
        li {
            id $id if ($id);
            a(href => $href || 'http://foo.bar') {
                block_content;
            };
        };
    };
    
    # use the block like a tag
    navitem some_id (href => 'http://bar.baz') {
        # this gets rendered by block_content() -- see above
        'some text or other content';
    }
    
    # will generate:
    <li id="some_id">
        <a href="http://bar.baz">some text or other content</a>
    </li>

=item block_content

a simple shortcut to render the content of the block at a given point. See
example above.

=item c

holds the content of the C<$c> variable. Simple write C<<< c->some_method >>>
instead of C<<< $c->some_method >>>.

=item class

provides a shortcut for defining class names. All examples below will generate
the same markup:

    div { class 'class_name'; };
    div { attr class => 'class_name'; };
    div { attr('class', 'class_name'); };
    div.class_name {};

Using the C<class()> subroutine allows to prefix a class name with a C<+> or
C<-> sign. Every class name written after a C<+> sign will get appended to the
class, each name written after a C<-> sign will be erased from the class.

=item doctype

a very simple way to generate a DOCTYPE declatation. Without any arguments, a
HTML 5 doctype declaration will be generated. The arguments (if any) will
consist of either of the words C<html> or C<xhtml> optionally followed by one
or more version digits. The doctypes used are taken from
L<http://hsivonen.iki.fi/doctype/>.

some examples:

    doctype;                # HTML 5
    doctype 'html';         # HTML 5
    doctype html => 4;      # HTML 4.01
    doctype 'html 4';       # HTML 4.01
    doctype 'html 4s';      # HTML 4.01 strict
    doctype 'html 4strict'; # HTML 4.01 strict

    doctype 'xhtml';        # XHTML 1.0
    doctype 'xhtml 1 1';    # XHTML 1.1

=item id

provides a shortcut for defining id names. All examples here will generate the
same markup:

    div { id 'id_name'; };
    div { attr id => 'id_name'; };
    div { attr('id', 'id_name'); };
    div id_name {};

=item load

an easy way to include assets into a page. Assets currently are JavaScript or
CSS. The first argument to this sub specifies the kind of asset, the second
argument is the URI to load the asset from.

Some examples will clearify:

    load js => '/static/js/jquery.js';
    load css => '/static/css/site.css';

If you plan to develop your JavaScript or CSS files as multiple files and like
to combine them at request-time (with caching of course...), you might like to
use L<Catalyst::Controller::Combine>. If your controllers are named C<Js> and
C<Css>, this will work as well:

    load Js => 'name_of_combined.js';

=item on

provides a syntactic sugar for generating inline JavaScript handlers.

    a(href => '#') {
        on click => q{alert('you clicked me'); return false};
    };

=item params

generates a series of C<param> tags.

    applet ( ... ) {
        params(
            quality => 'foo',
            speed => 'slow',
        );
    };

=item stash

is a shortcut for C<<< c->stash >>>.

=item template

essentially generates a sub named C<RUN> as the main starting point of every
template file. Both constructs will be identical:

    sub RUN {
        div { ... };
    }
    
    template {
        div { ... };
    };

Be careful to add a semicolon after the C<template> definition if you add code
after it!!!

=item yield

Without arguments, C<yield> forwards exection to the next template in the
ordinary execution chain. Typically this is the point in a wrapper template
that includes the main template.

With an argument, it forwards execution to the template given as the argument.
These values are possible:

=over

=item just a symbolic name

if a symbolic name is given, this name is searched in the C<<< stash->{yield}->{...} >>>
hashref. If it is found, the file-name or subref stored there will be executed
and included at the given point.

=item a path name

if a template file exists at the path name given as the argument, this
template is compiled and executed.

=item a code-ref

a code ref is directly executed.

=back

If yield is not able to find something, simply nothing happens. This behavior
could be useful to add hooks at specified positions in your markup that may
get filled when needed.


=back

=head2 Building Reusable blocks

You might build a reusable block line the following calls:

    block 'block_name', sub { ... };
    
    # or:
    block block_name => sub { ... };
    
    # or shorter:
    block block_name { ... };

The block might get used like a tag:

    block_name { ... some content ... };

If a block-call contains a content it can get rendered inside the block using
the special sub C<block_content>. A simple example makes this clearer:

    # define a block:
    block infobox {
        # attr() values must be read before generating markup
        my $headline = attr('headline') || 'untitled';
        my $id       = attr('id');
        my $class    = attr('class');
        
        # generate some content
        div.infobox {
            id $id       if ($id);
            class $class if ($class);
            
            div.head { $headline };
            div.info { block_content };
        };
    };
    
    # later we use the block:
    infobox some_id.someclass(headline => 'Our Info') {
        'just my 2 cents' 
    };
    
    # this HTML will get generated:
    <div class="someclass" id="some_id">
      <div class="head">Our Info</div>
      <div class="info">just my 2 cents</div>
    </div>

every block defined in a package is auto-added to the packages C<@EXPORT>
array and mangled in a special way to make the magic calling syntax work after
importing it into another package.

=head1 CONFIGURATION

A simple configuration of a derived Controller could look like this:

    __PACKAGE__->config(
        # Change extension (default: .pl)
        extension => '.pl',
        
        # Set the location for .pl files (default: root/bycode)
        root_dir => cat_app->path_to( 'root', 'bycode' ),
        
        # This is your wrapper template located in root_dir
        # (default: wrapper.pl)
        wrapper => 'wrapper.pl',
        
        # all these modules are use()'d automatically
        include => [Some::Module Another::Package],
    );

By default a typical standard configuration setting is constructed by issuing
the Helper-Module. It looks like this and describes all default settings:

    __PACKAGE__->config(
        # # Change default
        # extension => '.pl',
        # 
        # # Set the location for .pl files
        # root_dir => 'root/bycode',
        # 
        # # This is your wrapper template located in the 'root_dir'
        # wrapper => 'wrapper.pl',
        #
        # # specify packages to use in every template
        # include => [ qw(My::Package::Name Other::Package::Name) ]
    );

The following configuration options are available:

=over

=item root_dir

With this option you may define a location that is the base of all template
files. By default, the directory F<root/bycode> inside your application will
be used.

=item extension

This is the default file extension for template files. As an example, if your
Controller class is named C<MyController> and your action method calls
C<MyAction> then by default a template located at
F<root_dir/mycontroller/myaction.pl> will get used to render your markup. The
path and file name will get determined by concatenating the
controller-namespace, the action namespace and the extension configuration
directive.

If you like to employ another template, you may specifiy a different path
using the stash variable C<template>. See L<STASH VARIABLES> below.

=item wrapper

A wrapper is a template that is rendered before your main template and
includes your main template at a given point. It "wraps" something around your
template. This might be useful if you like to avoid repeating the standard
page-setup code for every single page you like to generate.

The default wrapper is named F<wrapper.pl> and is found directoy inside root_dir.

See L<TRICKS/Using a wrapper> below.

=item include

As every template is a perl module, you might like to add other modules using
Perl's C<use> directive. Well, you may do that at any point inside your
template. However, if you repeatedly need the same modules, you could simply
add them as a hashref using this configuration option.

=back

=head1 STASH VARIABLES

The following stash variables are used by C<Catalyst::View::ByCode>:

=over

=item template

If you like to override the default behavior, you can directly specify the
template containing your rendering. Simply enter a relative path inside the
root directory into this stash variable.

If the template stash variable is left empty, the template used to render your
markup will be determined by concatenating the action's namespace and the
extension.

=item wrapper

Overriding the default wrapper is the job of this stash variable. Simply
specify a relative path to a wrapping template into this stash variable.

=item yield

Yielding is a powerful mechanism. The C<yield> stash variable contains a
hashref that contains a template or an array-ref of templates for certain
keys. Every template might be a path name leading to a template or a code-ref
able that should be executed as the rendering code.

C<<< $c->stash->{yield}->{content} >>> is an entry that is present by default. It
contains in execution order the wrapper and the template to get executed.

Other keys may be defined and populated in a similar way in order to provide
hooks to magic parts of your markup generation.

See L<TRICKS/Setting hooks at various places> below.

=back

=head1 TRICKS

=head2 Using a wrapper

If you construct a website that has lots of pages using the same layout, a
wrapper will be your friend. Using the default settings, a simple file
F<wrapper.pl> sitting in the root directory of your templates will do the job.
As two alternatives you could set the C<<< $c->stash->{wrapper} >>> variable to
another path name or specify a wrapper path as a config setting.

    # wrapper.pl
    html {
        head {
            # whatever you need
        };
        body {
            # maybe heading, etc.
            
            # include your template here
            yield; 
        };
    };

=head2 Setting hooks at various places

If you need to sometimes add things at different places, simply mark these positions like:

    # in your wrapper:
    html {
        head {
            # whatever you need
            
            # a hook for extra headings
            yield 'head_extras';
        };
        body {
            # a hook for something at the very beginning
            yield 'begin';
            
            # maybe heading, etc.
            
            # a hook for something after your navigation block
            yield 'after_navigation';
            
            # include your template here
            yield; 
            
            # a hook for something after your content
            yield 'end';
        };
    };
    
    # in an action of your controller:
    $c->stash->{yield}->{after_navigation} = 'path/to/foo.pl';

In the example above, some hooks are defined. In a controller, for the hook
C<after_navigation>, a path to a template is filled. This template will get
executed at the specified position and its content added before continuing
with the wrapper template. If a hook's name is not a part of the
C<<< stash->{yield} >>> hashref, it will be ignored. However, an I<info> log entry
will be generated.

=head2 Avoiding repetitions

Every template is a perl module. It resides in its own package and every thing
you are not used to type is mangled into your source code before compilation.
It is up to you to C<use> every other module you like. A simple module could
look like this:

    package MyMagicPackage;
    use strict;
    use warnings;
    use base qw(Exporter);
    
    use Catalyst::View::ByCode::Renderer ':default';
    
    our @EXPORT = qw(my_sub);
    
    sub my_sub {
        # do something...
    }
    
    block my_block {
        # do something else
    };
    
    1;

Using the Renderer class above gives your module everything a template has.
You can use every Tag-sub you want.

To use this module in every template you write within an application you
simply populate the config of your View:

    __PACKAGE__->config(
        include => [ qw(MyMagicPackage) ]
    );

=head2 Including FormFu or FormHandler

If you are using one of the above packages to render forms, generating the
markup is done by the libraries. There are a couple of ways to get the
generated markup into our code:

    # assume stash->{form} contains a form object
    # all of these ways will work:
    
    # let the form object render itself
    print RAW stash->{form}->render();
    
    # use the form object's stringification
    print RAW "${\stash->{form}}";
    
    # inside any tag, let me auto-stringify
    div { stash->{form} };

=head2 Create your own error page

=head2 Using ByCode markup for other things.

Very simple:

    # in an action of your controller:
    my $html = $c->forward('View::ByCode', render => [qw(list of files)]);

=head2 Shortcuts

Some attributes behave in a way that looks intuitive but also generates
correct markup. The examples below do not need futher explanation.

    # both things generate the same markup:
    input(disabled => 1);
    input(disabled => 'disabled');
    
    input(checked => 1);
    input(checked => 'checked');

    input(required => 1);
    input(required => 'required');

    option(selected => 1);
    option(selected => 'selected');

    textarea(readonly => 1);
    textarea(readonly => 'readonly');
    
    # remember that choice() generates a E<lt>selectE<gt> tag...
    choice(multiple => 1);
    choice(multiple => 'multiple');

beside these examples all currently defined HTML-5 boolean attributes are
available: disabled, checked, hidden, inert, multiple, readonly, selected,
required.

=head1 METHODS

=cut

sub BUILD {
    my $self = shift;
    
    # no need to do that -- C::Component does it for us!!!
    # #my $c = $self->_app;
    # if (exists($self->config->{extension})) {
    #     $self->extension($self->config->{extension});
    # }
    # if (exists($self->config->{root_dir})) {
    #     $self->root_dir($self->config->{root_dir});
    # }
    # #$c->log->warn("directory '" . $self->root_dir . "' not present.")
    # #    if (!-d $c->path_to('root', $self->root_dir));
    # if (exists($self->config->{wrapper})) {
    #     $self->wrapper($self->config->{wrapper});
    # }
}

#
# intercept dies and correct
#  - file-name to template
#  - line-number by subtracting top-added part
#
sub _handle_die {
    my $msg = shift;
    die $msg if (ref($msg)); # exceptions will forward...
    
    my $package = $compiling_package || caller();
    die _correct_message($package, $msg);
}

#
# intercept warns and correct
#  - file-name to template
#  - line-number by subtracting top-added part
#
# then log then using Catalyst's logging facility
#
# will be called by a curried sub... -- see below
#
sub _handle_warn {
    my $logger = shift;
    my $msg = shift;
    
    my $package = $compiling_package || caller(1);
    $logger->warn(_correct_message($package, $msg));
}

#
# common handling for warn- and error-verbosing
#
sub _correct_message {
    my $package = shift;
    my $msg = shift;

    my ($start, $file, $line, $end)
     = ($msg =~ m{\A (.+? \s at) \s (/.+?)\s+ line \s+ (\d+) \s* (.*) \z}xmsg);
    
    no strict 'refs';
    if ($file && 
        ${"$package\::_tempfile"} && 
        $file eq ${"$package\::_tempfile"}) {
        #
        # exception/warning inside a template
        #
        my $offset = ${"$package\::_offset"};
        my $template = $package;
        $template =~ s{\A .+ :: Template}{}xms;
        $template =~ s{::}{/}xmsg;
        
        # replace all file-names and line-numbers
        $msg =~ s{at \s+ /.+? \s+ line \s+ (\d+)}{sprintf "at Template:$template line %d", $1-$offset}exmsg;
    }
    
    return $msg;
}

=head2 render

will be called by process to render things. If render is called with extra
arguments, they are treated as wrapper, template, etc...

returns the template result

=cut

sub render {
    my $self = shift;
    my $c = shift;
    my @yield_list = @_;
    
    #
    # beautify dies by replacing our strange file names
    # with the relative path of the wrapper or template
    #
    local $SIG{__DIE__}  = \&_handle_die;
    local $SIG{__WARN__} = sub { _handle_warn($c->log, @_) };
    
    #
    # must render - find template and wrapper
    # unless given as arguments
    #
    if (!scalar(@_)) {
        my $template = $c->stash->{template}
            ||  $c->action . $self->extension;
        if (!defined $template) {
            $c->log->error('No template specified for rendering');
            return 0;
        } else {
            my $path = $self->_find_template($c, $template);
            my $sub;
            if ($path && ($sub = $self->_compile_template($c, $path))) {
                $c->log->debug("FOUND template '$template' -> '$path'") if $c->debug;
                push @yield_list, $sub;
            } else {
                $c->log->error("requested template '$template' not found or not compilable");
                return 0;
            }
        }
        
        my $wrapper = exists($c->stash->{wrapper})
            ? $c->stash->{wrapper}
            : $self->wrapper;
        if ($wrapper) {
            my $path = $self->_find_template($c, $wrapper, $template); ### FIXME: must chop off last part from $template
            my $sub;
            if ($path && ($sub = $self->_compile_template($c, $path))) {
                unshift @yield_list, $sub;
            } else {
                $c->log->error("wrapper '$wrapper' not found or not compilable");
            }
        } else {
            $c->log->info('no wrapper wanted') if $c->debug;
        }
    }
    
    #
    # run render-sequence
    #
    $c->stash->{yield} ||= {};
    $c->stash->{yield}->{content} = \@yield_list;
    init_markup($self, $c);
    
    Catalyst::View::ByCode::Renderer::yield();
    
    my $content = get_markup();
    clear_markup;
    
    return $content;
}

=head2 process

fulfill the request (called from Catalyst)

=cut

sub process {
    my $self = shift;
    my $c = shift;
    
    $c->response->content_type($self->content_type);
    $c->response->body($self->render($c));
    
    return 1; # indicate success
}

#
# convert a template filename to a package name
#
sub _template_to_package {
    my $self = shift;
    my $c = shift;
    my $template = shift;  # relative path
    
    $template =~ s{\.\w+\z}{}xms;
    $template =~ s{/+}{::}xmsg;
    
    my $package_prefix = Catalyst::Utils::class2appclass($self);
    my $package = "$package_prefix\::Template\::$template";
    
    return $package;
}

#
# helper: find a given template
#     returns: relative path to template (including extension)
#
# FIXME: is it wise to always climb up the directory? Think!
#
sub _find_template {
    my $self = shift;
    my $c = shift;
    my $template = shift;  # relative path
    my $start_dir = shift || '';
    
    my $root_dir = $c->path_to($self->root_dir);
    my $ext = $self->extension;
    $ext =~ s{\A \.+}{}xms;
    my $count = 100; # prevent endless loops in case of logic errors
    while (--$count > 0) {
        ### FIXME: these constructs will probably fail under Windows.
        if (-f "$root_dir/$start_dir/$template") {
            # we found it
            return $start_dir ? "$start_dir/$template" : $template;
        } elsif (-f "$root_dir/$start_dir/$template.$ext") {
            # we found it after appending extension
            return $start_dir ? "$start_dir/$template.$ext" : "$template.$ext";
        }
        last if (!$start_dir);
        $start_dir =~ s{/*[^/]*/*\z}{}xms;
    };
    
    #
    # no success
    #
    return;
}

#
# helper: find and compile a template
#
sub _compile_template {
    my $self = shift;
    my $c = shift;
    my $template = shift;
    my $sub_name = shift || 'RUN';
    
    return 42 if (!$template); # 42 is not a code-ref (!)
    $c->log->debug("compiling: $template") if $c->debug;
    
    #
    # convert between path and package
    #
    my $template_path;
    my $template_package;
    if ($template =~ m{::}xms) {
        #
        # this is a package name
        #
        $template_package = $template;
        $template_path = $template;
        $template_path =~ s{::}{/}xmsg;
    } else {
        #
        # this is a path
        #
        $template_path = $template;
        $template_package = $template;
        $template_package =~ s{/}{::}xmsg;
        $template_package =~ s{\.\w+\z}{}xms;
    }

    #
    # see if we already know the package
    #
    my $package = $self->_template_to_package($c, $template_path);

    no strict 'refs';
    my $full_path = ${"$package\::_filename"};
    my $package_mtime = ${"$package\::_mtime"};
    my $file_mtime = $full_path && -f $full_path
        ? (stat $full_path)[9]
        : 0;
    use strict 'refs';
    
    if (!$full_path || !$file_mtime) {
        # we don't know the template or it has vanished somehow
        my $full_path = $c->path_to($self->root_dir, $template_path);
        if (-f $full_path) {
            # found!
            $self->__compile($c, "$full_path" => $package);
        }
    } elsif ($file_mtime != $package_mtime) {
        # we need a recompile
        $self->__compile($c, $full_path => $package);
    }
    
    # important: must stringify method to avoid Log::Log4perl::Catalyst
    #            to call it.
    my $method = $package->can($sub_name);
    $c->log->debug("can run: $method") if $c->debug;
    
    return $method;
}

# low level compile
sub __compile {
    my $self = shift;
    my $c = shift;
    my $path = shift;
    my $package = shift;
    
    # allow meaningful warnings during compile
    local $compiling_package = $package;
    
    $c->log->debug("compile template :: $path --> $package") if $c->debug;
    
    #
    # clear target package's namespace before we start
    #
    no strict 'refs';
    %{*{"$package\::"}} = ();
    use strict 'refs';

    #
    # slurp in the file
    #
    my $file_contents;
    if (open(my $file, '<', $path)) {
        local $/ = undef;
        $file_contents = <$file>;
        close($file);
    } else {
        $c->log->error('Error opening template file $file');
        return; ### FIXME: throw exception is better
    }

    #
    # build some magic code around the template's code
    #
    ### my $include = join("\n", map {"use $_;"} @{$self->include});
    my $now = localtime(time);
    my $mtime = (stat($path))[9];
    my $code = <<PERL;
# auto-generated code - do not modify
# generated by Catalyst::View::ByCode at $now
# original filename: $path

package $package;
use strict;
use warnings;
use utf8;

# use Devel::Declare(); ### do we need D::D ?
${ \join("\n", map { "use $_;" } @{$self->include}) }
use Catalyst::View::ByCode::Renderer qw(:default);

# subs that are overloaded here would warn otherwise
no warnings 'redefine';
PERL

    # count lines created so far (@lines added to avoid warnings)
    my $header_lines = scalar(my @lines = split(/\n/, $code));

    $code .= "\n$file_contents;\n\n1;\n";
    
    #
    # Devel::Declare does not work well with eval()'ed code...
    #                thus, we need to save into a TEMP-file
    #
    my $tempfile = Path::Class::File->new(File::Spec->tmpdir,
                                          UUID::Random::generate . '.pl');
    $c->log->debug("tempfile = $tempfile") if $c->debug;
    open(my $tmp, '>', $tempfile);
    print $tmp $code;
    close($tmp);
    
    #
    # create some magic _variables
    #
    no strict 'refs';
    ${"$package\::_filename"} = $path;
    ${"$package\::_offset"}   = $header_lines + 1;
    ${"$package\::_mtime"}    = $mtime;
    ${"$package\::_tempfile"} = "$tempfile";
    use strict 'refs';

    #
    # compile that
    #
    my $compile_result = do $tempfile;
    unlink $tempfile;
    if ($@) {
        #
        # error during compile
        #
        $c->error('compile error: ' . _correct_message($package, $@));
        #die "compile error ($package)";
    } elsif (!$compile_result) {
        #
        # compiled template did not return a true value
        #
        $c->error("Template $package did not return a true value");
    }
    $c->log->debug('compiling done') if $c->debug;
    
    #
    # done
    #
    return 1;

}

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
