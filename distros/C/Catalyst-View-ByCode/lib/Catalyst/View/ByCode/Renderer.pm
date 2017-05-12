package Catalyst::View::ByCode::Renderer;
$Catalyst::View::ByCode::Renderer::VERSION = '0.28';
use strict;
use warnings;
use base qw(Exporter);

use Devel::Declare();
use Catalyst::View::ByCode::Declare;
use Scalar::Util 'blessed';
use HTML::Tagset;
# use HTML::Entities; ### TODO: think about -- but pollutes our namespaces

our @EXPORT_OK  = qw(clear_markup init_markup get_markup);

our @EXPORT     = qw(template block block_content
                     load
                     yield
                     params
                     attr
                     class id on
                     stash c _
                     doctype boilerplate
                     nbsp
                    );
our %EXPORT_TAGS = (
    markup  => [ qw(clear_markup init_markup get_markup) ],
    default => [ @EXPORT ],
);

our @IS_KNOWN = (
    # HTML5 tags not defined in HTML::Tagset
    qw( article aside audio
        bdi bdo
        canvas
        data datalist details dialog
        figcaption figure footer
        header
        keygen
        main mark markup menu menuitem meter
        nav
        output
        progress
        rd rp rt ruby
        section source summary
        time track
        video ),
    grep { m{\A \w}xms }
    keys(%HTML::Tagset::isKnown)
);

our %EMPTY_ELEMENT = (
    (
        map { ($_=>1) }
        qw(source) ### FIXME: more needed!!!
    ),
    %HTML::Tagset::emptyElement
);

#
# define variables -- get local() ized at certain positions
#
our @m;             # whole content: initialized with &init_markup()
our @top = ( \@m ); # contains open tags
our $stash;         # current stash
our $c;             # current context
our $view;          # ByCode View instance
our $block_content; # code for executing &content()

#
# some constants
#
our $NEED_ESCAPE = qr{[\"<>&\x{0000}-\x{001f}\x{007f}-\x{ffff}]};

#
# some tags get changed by simply renaming them
#
#                   'html tag'  'sub name'
our %change_tags = ('select' => 'choice',
                    'link'   => 'link_tag',
                    'tr'     => 'trow',
                    'td'     => 'tcol',
                    'sub'    => 'subscript',
                    'sup'    => 'superscript',
                    'meta'   => 'meta_tag',    # Moose needs &meta()...
                    'q'      => 'quote',
                    's'      => 'strike',
                    'map'    => 'map_tag',
);

######################################## IMPORT
#
# just importing this module...
#
sub import {
    my $module = shift; # eat off 'Catalyst::View::ByCode::Renderer';

    my $calling_package = caller;

    my $default_export = grep {$_ eq ':default'} @_;

    #
    # do Exporter's Job on Catalyst::View::ByCode::Renderer's @EXPORT
    #
    $module->export_to_level(1, $module, grep {!ref $_} @_);

    #
    # overwrite (or create) &import in calling_package which
    #   - auto-imports all block() directives
    #   - adds a Devel::Declare-setup for every block() directive
    #
    if ($default_export && !UNIVERSAL::can($calling_package, '_import')) {
        no strict 'refs';

        # save original -- in doubt use Exporter::import
        local *_old_import = (*{"$calling_package\::import"}{CODE})
            ? *{"$calling_package\::import"}
            : *{"Exporter::import"};

        *{"$calling_package\::_import"} = *_old_import;
        *{"$calling_package\::import"}  = \&overloaded_import;
    }

    #
    # build HTML Tag-subs into caller's namespace
    #
    _construct_functions($calling_package)
        if ($default_export);

    #
    # create *OUT and *RAW in calling package to allow 'print' to work
    #   'print OUT' works, Components use a 'select OUT' to allow 'print' alone
    #
    no strict 'refs';
    if ($default_export || !scalar(@_)) {
        tie *{"$calling_package\::OUT"}, $module, 1; # escaped:   OUT
        tie *{"$calling_package\::RAW"}, $module, 0; # unescaped: RAW
        tie *{"$calling_package\::STDOUT"}, $module, 1; # escaped: STDOUT

        # stupid hack to make -w happy ;-)
        my $dummy0 = *{"$calling_package\::OUT"};
        my $dummy1 = *{"$calling_package\::RAW"};
        my $dummy2 = *{"$calling_package\::STDOUT"};
    }
}

#
# our importing packages' import() routine...
#
sub overloaded_import {
    my $imported_package = $_[0];
    my $calling_package = caller;

    no strict 'refs';

    if (scalar(@{"$imported_package\::EXPORT_BLOCK"})) {
        #
        # process every recorded block() directive
        #
        my %declare;

        foreach my $symbol (@{"$imported_package\::EXPORT_BLOCK"}) {
            ### FIXME: aliasing makes trouble in case of overwriting !!!!!
            *{"$calling_package\::$symbol"} = *{"$imported_package\::$symbol"};
            # *{"$calling_package\::$symbol"} = eval qq{ sub { goto $imported_package\::$symbol } };
            # *{"$calling_package\::$symbol"} = eval qq{ sub { $imported_package\::$symbol(\@_) } };

            $declare{$symbol} = {
                const => Catalyst::View::ByCode::Declare::tag_parser
            };
        }

        if (scalar(keys(%declare))) {
            Devel::Declare->setup_for($calling_package, \%declare);
        }
    }

    #
    # proceed with the original import
    #
    goto &{"$imported_package\::_import"};
}

######################################## FILE HANDLE MANAGEMENT
#
# IN/OUT stuff using a tied thing
#
sub TIEHANDLE {
    my $class  = shift; # my class (Catalyst::View::ByCode::Renderer)
    my $handle = shift; # escaping on or off -- use this scalar as a handle
                        # and its value to decide escaping
                        # -- see PRINT below

    return bless \$handle, $class;
}

sub PRINT {
    my $handle = shift;

    push @{$top[-1]},
         map {
             blessed($_) && $_->can('render')
             ? $_->render()
             : $$handle
                 ? do { my $text = "$_";
                        $text =~ s{($NEED_ESCAPE)}{'&#' . ord($1) . ';'}oexmsg;
                        $text; }
                 : "$_"
         }
         @_;
    return;
}

sub PRINTF { $_[0]->PRINT(sprintf(@_[1..$#_])) }

######################################## MARKUP
#
#
#
sub clear_markup {
    @m = ();
    @top = ( \@m );
    undef $c;
    undef $stash;
    undef $view;
}

sub init_markup {
    clear_markup();

    $view  = shift;
    $c     = shift;
    $stash = $c && $c->can('stash')
        ? $c->stash
        : {}; # primitive fallback
}

sub get_markup { _render(@m) }

sub _render {
    no warnings 'uninitialized'; # we might have undef sometimes

    join ('',
         map {
             ref($_) eq 'ARRAY'
               # a Tag is [ 'tag', {attrs}, content, ... ]
               ? do {
                   my $attr = $_->[1];

                   $_->[0]
                     # tag structure is named => <tag ...>
                     ? "<$_->[0]" .
                       # render attribute(s)
                       join('',
                            map {
                                my $k = $_;
                                my $v = $attr->{$k};

                                if (!defined $v) {
                                    " $k";
                                } elsif ($k eq 'autofocus'      ||
                                    $k eq 'checked'        ||
                                    $k eq 'disabled'       ||
                                    $k eq 'formnovalidate' ||
                                    $k eq 'hidden'         ||
                                    $k eq 'inert'          ||
                                    $k eq 'multiple'       ||
                                    $k eq 'novalidate'     ||
                                    $k eq 'readonly'       ||
                                    $k eq 'selected'       ||
                                    $k eq 'required') {
                                    # special handling for magic names that require magic values
                                    $v ? qq{ $k="$k"} : '';
                                } else {
                                    # not a special attribute name
                                    if (ref $v eq 'SCALAR') {
                                        $v = $$v;
                                    } elsif (ref $v) {
                                        # handle ref values differently
                                        $v = ref $v eq 'ARRAY'
                                            ? join(' ', @{$v})
                                          : ref $v eq 'HASH'
                                            ? join(';',
                                                    map { my $k = $_;
                                                        $k =~ s{([A-Z])|_}{-\l$1}oxmsg;
                                                        "$k:$v->{$_}" }
                                                    keys %{$v})
                                          : ref $v eq 'CODE'
                                            ? $v->()
                                          : "$v";
                                        $v =~ s{($NEED_ESCAPE)}{'&#' . ord($1) . ';'}oexmsg;
                                    } else {
                                        $v =~ s{($NEED_ESCAPE)}{'&#' . ord($1) . ';'}oexmsg;
                                    }

                                    # convert key into dash-separaed version,
                                    # dataId -> data-id, data_id => data-id
                                    $k =~ s{([A-Z])|_}{-\l$1}oxmsg;

                                    # compose attr="value"
                                    qq{ $k="$v"};
                                }
                            }
                            sort # not needed but nice for testing/guessing
                            keys %{$attr}
                       ) .

                       # closing tag or content?
                       (exists($EMPTY_ELEMENT{$_->[0]})
                          ? ' />'
                          : '>' .
                            _render(@{$_}[2 .. $#$_]) .
                            "</$_->[0]>")

                     # tag is unnamed -- just render content
                     : _render(@{$_}[2 .. $#$_])
                 }

               # everything else is stringified
               : "$_"
         } @_);
}

######################################## EXPORTED FUNCTIONS
#
# a template definition instead of sub RUN {}
#
sub template(&) {
    my $package = caller;

    my $code = shift;
    no strict 'refs';
    *{"$package\::RUN"} = sub {
        push @{$top[-1]}, [ '', {} ];

        push @top, $top[-1]->[-1];

        my $text = $code->();
        if (ref($text) && UNIVERSAL::can($text, 'render')) {
            push @{$top[-1]}, $text->render;
        } else {
            no warnings 'uninitialized'; # we might see undef values
            $text =~ s{($NEED_ESCAPE)}{'&#' . ord($1) . ';'}oexmsg;
            push @{$top[-1]}, $text;
        }

        pop @top;
        return;
    };

    return;
}

#
# a block definition
#
sub block($&;@) {
    my $name = shift;
    my $code = shift;

    my $package = caller;

    no strict 'refs';
    no warnings 'redefine';

    #
    # generate a sub in our namespace
    #
    *{"$package\::$name"} = sub(;&@) {
        local $block_content = $_[0];

        push @{$top[-1]}, [ '', { @_[1 .. $#_] } ];

        if ($code) {
            push @top, $top[-1]->[-1];
            push @{$top[-1]}, $code->();
            pop @top;
        }

        return;
    };

    #
    # mark this sub as a special exportable
    #
    ${"$package\::EXPORT_BLOCK"}{$name} = 1;
}

#
# execute a block's content
#
sub block_content {
    push @{$top[-1]}, $block_content->(@_) if ($block_content);
    return;
}

#
# a simple shortcut for multiple param(name => ..., value => ...) sequences
#
sub params {
    my %params = @_;

    while (my ($name, $value) = each %params) {
        push @{$top[-1]}, [ 'param', { name => $name, value => $value } ];
    }

    return;
}

#
# a simple shortcut for css/js handling
# usage:
#   load js => '/url/to/file.js';
#   load css => '/url/to/file.js';
#
#   load <<Controller_name>> => file_name [.js]
#
### FIXME: build more logic into load() -- accumulate calls
###        and resolve as late as possible
#
sub load {
    my $kind  = shift;

    return if (!$kind || ref($kind));

    if ($kind eq 'css') {
        #
        # simple static CSS inserted just here and now
        #
        push @{$top[-1]},
             map { [ 'link',
                     {
                         rel => 'stylesheet',
                         type => 'text/css',
                         href => $_
                     }
                   ] } @_;
    } elsif ($kind eq 'js') {
        #
        # simple static JS inserted just here and now
        #
        push @{$top[-1]},
             map { [ 'script',
                     {
                         type => 'text/javascript',
                         src => $_
                     }
                   ] } @_;
    } elsif ((my $controller = $c->controller($kind)) &&
             ($kind eq 'Js' || $kind eq 'Css')) {
        ### FIXME: are Hardcoded controller names wise???
        #
        # some other kind of load operation we have a controller for
        #
        # $c->log->debug("LOAD: kind=$kind, ref(controller)=" . ref($controller));

        if ($kind eq 'Css') {
            push @{$top[-1]},
                 [ 'link',
                   {
                       rel => 'stylesheet',
                       type => 'text/css',
                       href =>$c->uri_for($controller->action_for('default'), @_)
                   }
                 ];
        } else {
            push @{$top[-1]},
                 [ 'script',
                   {
                       type => 'text/javascript',
                       src => $c->uri_for($controller->action_for('default'), @_)
                   }
                 ];
        }
    }

    return;
}

#
# a special sub-rendering command like Rails ;-)
#
# yield \&name_of_a_sub;
# yield a_named_yield;
# yield 'content';
# yield;   # same as 'content'
# yield 'path/to/template.pl'
# ### TODO: yield package::subname
# ### TODO: yield +package::package::package::subname
#
sub yield(;*@) {
    my $yield_name = shift || 'content';

    $c->log->debug("yield '$yield_name' executing...") if  $c->debug;

    _yield(exists($c->stash->{yield}->{$yield_name})
            ? $c->stash->{yield}->{$yield_name}
            : $yield_name)
        or $c->log->info("could not yield '$yield_name'");

    return;
}

# helper for recursive resolution
sub _yield {
    my $thing = shift;

    if (!$thing) {
        return;
    } elsif (ref($thing) eq 'ARRAY') {
        my $result;
        while (my $x = shift(@{$thing})) {
            _yield($x) and $result = 1;
        }
        return $result;
    } elsif (ref($thing) eq 'CODE') {
        $thing->();
        return 1;
    } elsif (!ref($thing)) {
        return _yield($view->_compile_template($c, $thing));
    }
}

#
# get/set attribute(s) of latest open tag
#
sub attr {
    # FIXME: better discovery of set/get !defined wantarray (?)
    
    return $top[-1]->[1]->{$_[0]} if scalar @_ == 1 && defined wantarray;

    no warnings; # avoid odd no of elements in hash
    %{ $top[-1]->[1] } = ( %{ $top[-1]->[1] }, @_ );
    return;
}

#
# set a class inside a tag
#
sub class {
    my @args = @_
        or return;

    #
    # class 'huhu';              - set 'huhu' (replacing previous name)
    # class 'huhu zzz';          - set 'huhu' and 'zzz' (replacing previous name/s)
    # class '-bar';              - remove 'bar'
    # class '-bar baz';          - remove 'bar' and 'baz'
    # class '+foo';              - add 'foo'
    # class '+foo moo'           - add 'foo' and 'moo'
    # class '+foo -bar baz'      - add 'foo', remove 'bar' and 'baz'
    # class '+foo','-bar','baz'  - add 'foo', remove 'bar' and 'baz'
    # class qw(+foo -bar baz)    - same thing.
    #
    my $class_name = $top[-1]->[1]->{class} || '';
    my %class = map {($_ => 1)}
                grep {$_}
                split(qr{\s+}xms, $class_name);

    my $operation = 0; # -1 = sub, 0 = set, +1 = add
    foreach my $name (grep {length} map {split qr{\s+}xms} grep {!ref && defined && length} @args) {
        if ($name =~ s{\A([-+])}{}xms) {
            $operation = $1 eq '-' ? -1 : +1;
        }
        if ($operation < 0) {
            delete $class{$name};
        } elsif ($operation > 0) {
            $class{$name} = 1;
        } else {
            %class = ($name => 1);
            $operation = +1;
        }
    }

    $top[-1]->[1]->{class} = join(' ', sort keys(%class));
    return;
}

#
# set an ID
#
sub id { $top[-1]->[1]->{id} = $_[0]; return; }

#
# define a javascript-handler
#
sub on { $top[-1]->[1]->{"on$_[0]"} = join('', @_[1..$#_]); return; }

#
# simple getters
#
sub stash { $stash }
sub c { $c }

#
# generate a proper doctype line
#
sub doctype {
    my $kind = join(' ', @_);

    # see http://hsivonen.iki.fi/doctype/ for details on these...
    my @doctype_finder = (
        [qr(html(?:\W*5))                 => 'html5'],
        [qr(html)                         => 'html5'],

        [qr(html(?:\W*4[0-9.]*)?\W*s)     => 'html4_strict'],
        [qr(html(?:\W*4[0-9.]*)?\W*[tl])  => 'html4_loose'],

        [qr(xhtml\W*1\W*1)                => 'xhtml1_1'],
        [qr(xhtml(?:\W*1[0-9.]*)?\W*s)    => 'xhtml1_strict'],
        [qr(xhtml(?:\W*1[0-9.]*)?\W*[tl]) => 'xhtml1_trans'],
        [qr(xhtml)                        => 'xhtml1'],
    );

    my %doctype_for = (
        default      => q{<!DOCTYPE html>},
        html5        => q{<!DOCTYPE html>},
        html4        => q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">},
        html4_strict => q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" } .
                        q{"http://www.w3.org/TR/html4/strict.dtd">},
        html4_loose  => q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" } .
                        q{"http://www.w3.org/TR/html4/loose.dtd">},
        xhtml1_1     => q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" } .
                        q{"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">},
        xhtml1       => q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.0//EN" } .
                        q{"http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd">},
        xhtml1_strict=> q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" } .
                        q{"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">},
        xhtml1_trans => q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" } .
                        q{"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">},
    );

    my $doctype = 'default';
    foreach my $d (@doctype_finder) {
        if ($kind =~ m{\A $d->[0]}xmsi) {
            $doctype = $d->[1];
            last;
        }
    }

    push @{$top[-1]}, $doctype_for{$doctype};
}

sub boilerplate(;&) {
    my $code = shift;

    push @{$top[-1]}, <<HTML;
<!--[if lt IE 7 ]> <html class="no-js ie6" lang="en"> <![endif]-->
<!--[if IE 7 ]>    <html class="no-js ie7" lang="en"> <![endif]-->
<!--[if IE 8 ]>    <html class="no-js ie8" lang="en"> <![endif]-->
<!--[if (gte IE 9)|!(IE)]><!--> <html class="no-js" lang="en"> <!--<![endif]-->
HTML

    if ($code) {
        $code->();
    }

    push @{$top[-1]}, '</html>';
}

######################################## Locale stuff
#
# get a localized version of something
#
{
no warnings 'redefine';
sub _ { return $c->localize(@_) }
}

sub nbsp { "\x{00a0}" } # bad hack in the moment...

#
# define a function for every tag into a given namespace
#
sub _construct_functions {
    my $namespace  = shift;

    no warnings 'redefine'; # in case of a re-compile.

    my %declare;

    # tags with content are treated the same as tags without content
    foreach my $tag_name (@IS_KNOWN) {
        my $sub_name = $change_tags{$tag_name}
            || $tag_name;

        # install a tag-named sub in caller's namespace
        no strict 'refs';
        *{"$namespace\::$sub_name"} = sub (;&@) {
            push @{$top[-1]}, [ $tag_name, { @_[1 .. $#_] } ];

            if ($_[0]) {
                push @top, $top[-1]->[-1];
            
                #### TODO: find out why ->render does not work for HTML::FormFu !!!
            
                my $text = $_[0]->(@_);
                if (ref $text && UNIVERSAL::can($text, 'render')) {
                    push @{$top[-1]}, $text->render;
                } elsif (ref $text eq 'SCALAR') {
                    push @{$top[-1]}, $$text;
                } else {
                    no warnings 'uninitialized'; # we might see undef values
                    $text =~ s{($NEED_ESCAPE)}{'&#' . ord($1) . ';'}oexmsg;
                    push @{$top[-1]}, $text;
                }
            
                pop @top;
            }

            ### TODO: can we call _render() here and save text instead of a structure?
            ###       would convert [ tag => {attr}, content ] to <tag attr>content</tag>
            # $top[-1] = _render($top[-1]);

            return;
        };
        use strict 'refs';

        # remember me to generate a magic tag-parser that applies extra magic
        $declare{$sub_name} = {
            const => Catalyst::View::ByCode::Declare::tag_parser
        };
    }

    # add logic for block definitions
    $declare{block} = {
        const => Catalyst::View::ByCode::Declare::block_parser
    };

    # install all tag-parsers collected above
    Devel::Declare->setup_for($namespace, \%declare);
}

1;
