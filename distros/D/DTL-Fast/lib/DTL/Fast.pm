package DTL::Fast;
use strict; use warnings FATAL => 'all'; 
use Exporter 'import';
use Digest::MD5 qw(md5_hex);

use 5.010;
our $VERSION = '1.623'; # ==> ALSO update the version in the pod text below!

# loaded modules
our %TAG_HANDLERS;
our %FILTER_HANDLERS;
our %OPS_HANDLERS;

# known but not loaded modules
our %KNOWN_TAGS;        # plain map tag => module
our %KNOWN_SLUGS;       # reversed module => tag
our %KNOWN_FILTERS;     # plain map filter => module
our %KNOWN_OPS;         # complex map priority => operator => module
our %KNOWN_OPS_PLAIN;   # plain map operator => module
our @OPS_RE = ();

# modules hash to avoid duplicating on deserializing
our %LOADED_MODULES;

require XSLoader;
XSLoader::load('DTL::Fast', $VERSION);

our $RUNTIME_CACHE;

our @EXPORT_OK = qw(
    count_lines
    get_template
    select_template
    register_tag
    preload_operators
    register_operator
    preload_tags
    register_filter
    preload_filters
    );

sub get_template
{
    my( $template_name, %kwargs ) = @_;
    
    die  "Template name was not specified" 
        if not $template_name;

    die "Template directories array was not specified"
        if
            not defined $kwargs{'dirs'}
            or ref $kwargs{'dirs'} ne 'ARRAY'
            or not scalar @{$kwargs{'dirs'}}
        ;

    my $cache_key = _get_cache_key( $template_name, %kwargs );

    my $template;

    $RUNTIME_CACHE //= DTL::Fast::Cache::Runtime->new();

    if( 
        $kwargs{'no_cache'}
        or not defined ( $template = $RUNTIME_CACHE->get($cache_key))
    )
    {
        $template = read_template($template_name, %kwargs );
        
        if( defined $template )
        {
            $RUNTIME_CACHE->put($cache_key, $template);
        }
        else
        {
            die  sprintf( <<'_EOT_', $template_name, join("\n", @{$kwargs{'dirs'}}));
Unable to find template %s in directories: 
%s
_EOT_
        }
    }
   
    return $template;
}

sub _get_cache_key
{
    my( $template_name, %kwargs ) = @_;
    
    return md5_hex(
        sprintf( '%s:%s:%s:%s'
            , __PACKAGE__
            , $template_name
            , join( ',', @{$kwargs{'dirs'}} )
            , join( ',', @{$kwargs{'ssi_dirs'}//[]})
            # shouldn't we pass uri_handler here?
        )
    )
    ;
}

sub read_template
{
    my( $template_name, %kwargs ) = @_;
    
    my $template = undef;
    my $template_path = undef;

    die "Template directories array was not specified"
        if not defined $kwargs{'dirs'}
            or not ref $kwargs{'dirs'}
            or not scalar @{$kwargs{'dirs'}}
        ;
    
    my $cache_key = _get_cache_key( $template_name, %kwargs );

    if( 
        $kwargs{'no_cache'}
        or not exists $kwargs{'cache'} 
        or not $kwargs{'cache'}
        or not $kwargs{'cache'}->isa('DTL::Fast::Cache')
        or not defined ($template = $kwargs{'cache'}->get($cache_key))
    )
    {
        ($template, $template_path) = _read_file($template_name, $kwargs{'dirs'});
        
        if( defined $template )
        {
            $kwargs{'file_path'} = $template_path;
            $template = DTL::Fast::Template->new( $template, %kwargs);
    
            $kwargs{'cache'}->put( $cache_key, $template )
                if 
                    defined $template
                    and exists $kwargs{'cache'}
                    and $kwargs{'cache'}
                    and $kwargs{'cache'}->isa('DTL::Fast::Cache')
                ;
        }
    }
    
    if( defined $template )
    {
        $template->{'cache'} = $kwargs{'cache'} if $kwargs{'cache'};
        $template->{'url_source'} = $kwargs{'url_source'} if $kwargs{'url_source'};
    }
    
    return $template;
}

sub _read_file
{
    my $template_name = shift;
    my $dirs = shift;
    my $template;
    my $template_path;
    
    foreach my $dir (@$dirs)
    {
        $dir =~ s/[\/\\]+$//xgsi;
        $template_path = sprintf '%s/%s', $dir, $template_name;
        if( 
            -e $template_path
            and -f $template_path
            and -r $template_path
        )
        {
            $template = __read_file( $template_path );
            last;
        }        
    }
    
    return ($template, $template_path);
}


sub __read_file
{
    my( $file_name ) = @_;
    my $result;
    
    if( open my $IF, '<', $file_name )
    {
        local $/ = undef;
        $result = <$IF>;
        close $IF;
    }
    else
    {
        die  sprintf(
            'Error opening file %s, %s'
            , $file_name
            , $!
        );
    }
    return $result;
}

# result should be cached with full list of params
sub select_template
{
    my( $template_names, %kwargs ) = @_;
    
    die  "First parameter must be a template names array reference" 
        if(
            not ref $template_names
            or ref $template_names ne 'ARRAY'
            or not scalar @$template_names
        );

    my $result = undef;
    
    foreach my $template_name (@$template_names)
    {
        if( ref ( $result = get_template( $template_name, %kwargs )) eq 'DTL::Fast::Template' )
        {
            last;
        }
    }
    
    return $result;
}

# registering tag as known
sub register_tag
{
    my( %tags ) = @_;
    
    while( my( $slug, $module) = each %tags )
    {
        $DTL::Fast::KNOWN_TAGS{lc($slug)} = $module;
        $DTL::Fast::KNOWN_SLUGS{$module} = $slug;
    }
    
    return;
}

# registering tag as known
sub preload_tags
{
    require Module::Load;
    
    while( my( $keyword, $module) = each %KNOWN_TAGS )
    {
        Module::Load::load($module);
        $LOADED_MODULES{$module} = time;
        delete $TAG_HANDLERS{$keyword} if exists $TAG_HANDLERS{$keyword} and $TAG_HANDLERS{$keyword} ne $module;
    }
    
    return 1;
}


# registering filter as known
sub register_filter
{
    my( %filters ) = @_;
    
    while( my( $slug, $module) = each %filters )
    {
        $DTL::Fast::KNOWN_FILTERS{$slug} = $module;
        delete $FILTER_HANDLERS{$slug} if exists $FILTER_HANDLERS{$slug} and $FILTER_HANDLERS{$slug} ne $module;
    }
    
    return;
}

sub preload_filters
{
    require Module::Load;
    
    while( my( undef, $module) = each %KNOWN_FILTERS )
    {
        Module::Load::load($module);
        $LOADED_MODULES{$module} = time;
    }
    
    return 1;
}

# invoke with parameters:
#
#   '=' => [ priority, module ]
#
sub register_operator
{
    my %ops = @_;
    
    my %recompile = ();
    foreach my $operator (keys %ops)
    {
        my($priority, $module) = @{$ops{$operator}};
        
        die "Operator priority must be a number from 0 to 8"
            if $priority !~ /^[012345678]$/;
        
        $KNOWN_OPS{$priority} //= {};
        $KNOWN_OPS{$priority}->{$operator} = $module;
        $recompile{$priority} = 1;
        $KNOWN_OPS_PLAIN{$operator} = $module;
        delete $OPS_HANDLERS{$operator} if exists $OPS_HANDLERS{$operator} and $OPS_HANDLERS{$operator} ne $module;
    }
    
    foreach my $priority (keys(%recompile))
    {
        my @ops = sort{ length $b <=> length $a } keys(%{$KNOWN_OPS{$priority}});
        my $ops = join '|', map{ "\Q$_\E" } @ops;
        $OPS_RE[$priority] = $ops;
    }
}


sub preload_operators
{
    require Module::Load;
    
    while( my( undef, $module) = each %KNOWN_OPS_PLAIN )
    {
        Module::Load::load($module);
        $LOADED_MODULES{$module} = time;
    }
    
    return 1;
}


require DTL::Fast::Template;
require DTL::Fast::Cache::Runtime;

1;

__END__ 
=head1 NAME

DTL::Fast - Perl implementation of Django templating language.

=head1 VERSION

Version 1.623

=head1 SYNOPSIS

Complie and render template from code:

    use DTL::Fast;
    my $tpl = DTL::Fast::Template->new('Hello, {{ username }}!');
    print $tpl->render({ username => 'Alex'});
    
Or create a file: template.txt in /home/alex/templates with contents:

    Hello, {{ username }}!
    
And load and render it:

    use DTL::Fast qw( get_template );
    my $tpl = get_template( 'template.txt', dirs => ['/home/alex/templates'] );
    print $tpl->render({ username => 'Alex'});

=head1 DESCRIPTION

This module is a Perl and stand-alone templating system, cloned from Django templating sytem, described in L<here|https://docs.djangoproject.com/en/1.8/topics/templates/>.

=head2 Goals

Goals of this implementation are:

=over

=item * Speed in mod_perl/FCGI environment

=item * Possibility to cache using files/memcached

=item * Maximum compatibility with original Django templates

=back

=head2 Current status

Current release implements almost all tags and filters documented on Django site. Also, some extensions has been made to the tags, filters and operators.

Some optimisation has been done and some critical section been implemeted in C.

Internationalization and localization are not yet implemented.

=head1 BASICS

You may get template object using three ways. 

=head2 Constructor


Using DTL::Fast::Template constructor:

    use DTL::Fast;
    
    my $tpl = DTL::Fast::Template->new(
        $template_text,                             # template itself
        'dirs' => [ $dir1, $dir2, ... ],            # optional, directories list to look for parent templates and includes
        'ssi_dirs' => [ $ssi_dir1, $ssi_dir1, ...]  # optional, directories list allowed to used in ssi tag (ALLOWED_INCLUDE_ROOTS in Django)
        'url_source' => \&uri_getter                # optional, reference to a function, that can return url template by model name (necessary for url tag)
    );

=head2 get_template
    
    use DTL::Fast qw(get_template);
    
    my $tpl = get_template(
        $template_path,                             # path to the template, relative to directories from second argument
        'dirs' => [ $dir1, $dir2, ... ],            # mandatory, directories list to look for parent templates and includes
        'ssi_dirs' => [ $ssi_dir1, $ssi_dir1, ...]  # optional, directories list allowed to used in ssi tag (ALLOWED_INCLUDE_ROOTS in Django)
        'url_source' => \&uri_getter                # optional, reference to a function, that can return url template by model name (necessary for url tag)
    );
    
when you are using C<get_template> helper function, framework will try to find template in following files: C<$dir1/$template_path, $dir2/$template_path ...> Searching stops on first occurance.

=head2 select_template

    use DTL::Fast qw(select_template);
    
    my $tpl = select_template(
        [ $template_path1, $template_path2, ...],   # paths to templates, relative to directories from second argument
        'dirs' => [ $dir1, $dir2, ... ],            # mandatory, directories list to look for parent templates and includes
        'ssi_dirs' => [ $ssi_dir1, $ssi_dir1, ...]  # optional, directories list allowed to used in ssi tag (ALLOWED_INCLUDE_ROOTS in Django)
        'url_source' => \&uri_getter                # optional, reference to a function, that can return url template by model name (necessary for url tag)
    );
    
when you are using C<select_template> helper function, framework will try to find template in following files: C<$dir1/$template_path1, $dir1/$template_path2 ...> Searching stops on first occurance.

=head2 render

After parsing template using one of the methods above, you may render it using context. Context is basically a hash of values, that will be substituted into template. Hash may contains scalars, hashes, arrays, objects and methods. Into C<render> method you may pass a Context object or just a hashref (in which case Context object will be created automatically).

    use DTL::Fast qw(get_template);
    
    my $tpl = get_template(
        'hello_template.txt',          
        'dirs' => [ '/srv/wwww/templates/' ]
    );
    
    print $tpl->render({ name => 'Alex' });
    print $tpl->render({ name => 'Ivan' });
    print $tpl->render({ name => 'Sergey' });

or

    use DTL::Fast qw(get_template);
    
    my $tpl = get_template(
        'hello_template.txt',          
        'dirs' => [ '/srv/wwww/templates/' ]
    );
    
    my $context = DTL::Fast::Context->new({
        'name' => 'Alex'
    });
    print $tpl->render($context);
    
    $context->set('name' => 'Ivan');
    print $tpl->render($context);

    $context->set('name' => 'Sergey');
    print $tpl->render($context);

=head2 register_tag

    use DTL::Fast qw(register_tag);
    
    register_tag(
        'mytag' => 'MyTag::Module'
    );
    
This method registers or overrides registered tag keyword with handler module. Module will be loaded when first encountered during template parsing. About handler modules you may read in L</CUSTOM TAGS> section.

=head2 preload_tags

    use DTL::Fast qw(preload_tags);
    
    preload_tags();
    
Preloads all registered tags modules. Mostly for debugging purposes or persistent environment stability.

=head2 register_filter

    use DTL::Fast qw(register_filter);
    
    register_filter(
        'myfilter' => 'MyFilter::Module'
    );
    
This method registers or overrides registered filter keyword with handler module. Module will be loaded when first encountered during template parsing. About handler modules you may read in L</CUSTOM FILTERS> section.

=head2 preload_filters

    use DTL::Fast qw(preload_filters);
    
    preload_filters();
    
Preloads all registered filters modules. Mostly for debugging purposes or persistent environment stability.

=head2 register_operator

    use DTL::Fast qw(register_operator);
    
    register_operator(
        'xor' => [ 1, 'MyOps::XOR' ],
        'myop' => [ 0, 'MyOps::MYOP' ],
    );

This method registers or overrides registered operator handlers. Handler module will be loaded when first encountered during template parsing. 

Arguments hash is:

    'operator_keyword' => [ precedence, handler_module ]

Currently there are 9 precedences from 0 to 8, the lower is less prioritised. You may see built-in precedence in the C<DTL::Fast::Expression::Operator> module.

More about custom operators you may read in L</CUSTOM OPERATORS> section.

=head2 preload_operators

    use DTL::Fast qw(preload_operators);
    
    preload_operators();
    
Preloads all registered operators modules. Mostly for debugging purposes or persistent environment stability.
  
=head2 html_protect

    my $protected_text = DTL::Fast::html_protect($raw_text);

This function protects string for a safe HTML output by replacing characters: E<lt> E<gt> & " ' with their HTML equivalents. Function written in C and works pretty fast. If you want it to properly treat UTF-8 characters you must set utf8 flag for C<$raw_text>.

=head2 spaceless

    my $spaceless_text = DTL::Fast::spaceless($raw_text);

This function implements spaceless tag, by removing spaces, tabs and newlines between E<lt> and E<gt> symbols. Written in C and works pretty fast.If you want it to properly treat UTF-8 characters you must set utf8 flag for C<$raw_text>.

=head2 eval_sequence

    eval 'some code ... ';
    my $sequence = DTL::Fast::eval_sequence();
    
This function returns internal perl eval counter. This counter being increased on every C<eval $string;> operation. Counter may be useful for debugging purposes with multiple evals, in order to detect in which exact eval error occured. Perl's C<die> method says smth like: C<error in eval(42) ...>. 42 in this example is eval sequence counter.
  
=head1 TEMPLATING LANGUAGE

=head2 Operators and Expressions

Expressions used in C<if> tag consists of variables, operators and brackets. All operators MUST have at least one space symbol before and after it. This is an after-effect of custom parsing algorythm. 

    {% if var1 == var2 %}   # correct
    {% if var1==var2 %}     # not correct, no spaces around ==
    
Module supports following operators (with precedence):

    pow, **                     # left operand in power of the right one
    defined                     # check if right operand is defined
    not                         # negating the right operand
    in, not in                  # check that left operand exists in a hash or an array (right operand)
    *, /, %, mod                # multiplying, dividing and modulus
    +, -                        # plus and minus
    ==, !=, <>, <, >, <=, >=    # comparision operators
    and                         # logical and
    or                          # logical or

=head2 Tags

This module supports almost all built-in tags documented on L<official Django site|https://docs.djangoproject.com/en/1.8/ref/templates/builtins/#built-in-tag-reference>. Don't forget to read L<incompatibilities|/INCOMPATIBILITIES WITH DJANGO TEMPLATES> and L<extensions|/EXTENSIONS OF DJANGO TEMPLATES> sections.

=head3 block_super

New tag for using with inheritance in order to render a parent block. In Django you are using C<{{ block.super }}> which is also currently supported, but depricated and will be removed in future versions.

=head3 firstofdefined

New tag, that works like C<firstof> tag, but checks if value is defined (not true)

=head3 sprintf

    {% sprintf pattern var1 var2 ... varn %}
    
Works exactly like a perl's sprintf function with pattern and substitutions. This tag was recently implemented and should be considered as experimental.

=head3 url

C<url> tag works a different way. Because there is no framework around, we can't obtain model's path the same way. But you may pass C<url_source> parameter into template constructor or C<get_template>/C<select_template> function. This parameter MUST be a reference to a function, that will return to templating engine url template by some 'model path' (first parameter of C<url> tag). Second parameter passed to the C<url_source> handler will be a reference to array of argument values (in case of positional arguments) or reference to a hash of arguments (in case of named ones). Url source handler may just return a regexp template by model path and templating engine will try to restore it with specified arguments. Or, you may restore it yourself, alter replacement arguments or do whatever you want. 

=head3 dump

    {% dump var1 var2 ... varn %}

C<dump> tag is useful for development and debugging. Dumps context variables using L<C<Data::Dumper>> to the rendered template as is.

=head3 dump_html

    {% dump_html var1 var2 ... varn %}

Works exactly as the C<dump> tag, but escapes result and writes it to the rendered template, wrapped with C<textarea> tags. Textarea has C<dtl_fast_dump_area> class selector, so you may do any styling on your side. Useful for debugging HTML pages.

=head3 dump_warn

    {% dump_warn var1 var2 ... varn %}

Works exactly as the C<dump> tag, warns output, instead of putting it into the rendered template.


=head2 Filters

This module supports all built-in filters documented on L<official Django site|https://docs.djangoproject.com/en/1.8/ref/templates/builtins/#built-in-filter-reference>. Don't forget to read L<incompatibilities|/INCOMPATIBILITIES WITH DJANGO TEMPLATES> and L<extensions|/EXTENSIONS OF DJANGO TEMPLATES> sections.

=head3 numberformat

    {{ var1|numberformat }}
    
Formats 12345678.9012 as
    
    12 345 678.9012

Split integer part of the number by 3 digits, separated by spaces.

=head3 reverse

Reverses data depending on type:

=over

=item * Scalar will be reversed literally: "hi there" => "ereht ih"

=item * Array will be reversed using perl's reverse function

=item * Hash will be reversed using perl's reverse function

=item * Object may provide reverse method to be used with this filter

=back

=head3 split

    {{ var1|split:"\s+"|slice:":2"|join:"," }}
    
Splitting variable with specified pattern, using Perl's split function. Current implementation uses //s regexp. Filter returns array. This filter was recently implemented and should be considered as experimental.

=head3 strftime

Formatting timestamp using L<C<Date::Format>> module. This is C-style date formatting, not PHP one.

=head1 CUSTOM CACHE CLASSES

To do...

=head1 CUSTOM TAGS

You may extend C<DTL::Fast> with your own custom tags. It's pretty simple process. There are two types of tags in the library: simple tags and block tags. Simple tag just doing something, like
including file and block tags contains other blocks and affects their rendering in some way, like for loop.

Every tag is a separate class inherited from certain prototype.

=head2 Simple tags

Every simple tag implemented as class, inherited from L<C<DTL::Fast::Tag::Simple>>:

    package CustomTags::MyTag;                          # your tag class
    use strict; use utf8; use warnings FATAL => 'all';  # make a clean code
    use parent 'DTL::Fast::Tag::Simple';                # parent class
    
    $DTL::Fast::TAG_HANDLERS{'my_tag'} = __PACKAGE__;   # register your tag keyword with your package in tag handlers
    
    # You may need to override a constructor in case you need to support some complex syntax
    # if you don't need to do something special, just don't override it
    # invoked once on parse phase
    sub new
    {
        my(
            $proto,         # well, this is a class proto
            $parameter,     # this is a text with everything after your tag: {% my_tag ...this is a parameter if any... %}
            %kwargs         # additional named arguments may be passed to the constructor
        ) = @_;
        
        ....
        
        my $self = $proto->SUPER::new($parameter, %kwargs);
        
        ....
        
        return $self;
    }
    
    # Parameter parsing method, invoked once on parsing phase. Parent constructor stores passed $parameter
    # into the $self->{'parameter'} hash entry and invokes parse_parameter method.
    # here you may make some preparations for rendering, parse arguments and do whatever you want.
    sub parse_parameters
    {
        my $self = shift;   # reference to the tag object
        
        ....
        
        return $self;       # IMPORTANT, method must return $self, because it's being used in chain call
    }

    # Rendering method. Invoked on every rendering iteration
    # The main work is being done here
    sub render
    {
        my(
            $self,          # object reference
            $context,       # context object
            $global_safe    # this flag is set to true, if somehow global safety is turned on, means disabled HTML escaping
        ) = @_;
        
        ...
        
        return $result;     # this is just a string generated by tag. If your tag is silent, just return an empty string
    }
    
After creating your tag class, you need to register it in C<DTL::Fast>, so library knew which module to load on tag keyword:

    use DTL::Fast qw(register_tag);

    register_tag( 'my_tag' => 'CustomTags::MyTag' );
    
Basically, that's all. For more information you may view through the sources of buit-in simple tags.

=head2 Block tags

Every block tag in the library implemented as class, inherited from L<C<DTL::Fast::Tag>>:

    package CustomTags::MyBlockTag;                     # your tag class
    use strict; use utf8; use warnings FATAL => 'all';  # make a clean code
    use parent 'DTL::Fast::Tag';                        # parent class is Tag, not Tag::Simple
    
    $DTL::Fast::TAG_HANDLERS{'my_block_tag'} = __PACKAGE__;   # register your tag opening keyword with your package in tag handlers

    # constructor and parameters parser are the same as in simple tags    

    # method must be defined and must return block close tag, so parser would know where block is ended    
    sub get_close_tag{ return 'end_my_tag';}
    
    # optional. Method invoked on parsing phase with next parsed chunk of current block tag contents
    # this method being used, for example, in the 'if' tag to push chunks into sub-branches, not if block itself
    sub add_chunk
    {
        my(
            $self,      # reference to the tag object
            $chunk      # parsed chunk object, if chunk must be ignored, it would be undefined
        ) = @_;
        
        ... here you may alter chunk or put it in some other place, like subblocks...
        
        return $self;   # don't forget to return self
    }
    
    # optional. Method invoked on parsing phase for every {% ... .%} construction.
    # if there is no special controlling keywords, don't override this method
    sub parse_tag_chunk
    {
        my(
            $self,       # reference to the tag object
            $tag_name,   # tag keyword
            $tag_param,  # everything after tag keyword (constructor's $parameter)
            $chunk_lines # chunk size in lines, used for proper debugging output
        ) = @_;
        
        my $result;
        
        # here you may interpret additional tag keywords, like else, elsif and so on.
        if( $tag_name eq 'my_tag_else' )
        {
            ... do smth special
            $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines; # set proper line number for next source block
        }
        elsif( $tag_name eq 'my_tag_alternative_end' )
        {
            $self->{'raw_chunks'} = []; # this construction ends current block parsing
            $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines; # set proper line number for next source block
        }
        else    # if it was not special keyword, just do regular work
        {
            $result = $self->SUPER::parse_tag_chunk($tag_name, $tag_param, $chunk_lines);
        }
        
        return $result;  # result must be a generated chunk or undef if there is no one
    }

    # Rendering method. Invoked on every rendering iteration
    # The main work is being done here
    sub render
    {
        my(
            $self,          # object reference
            $context,       # context object
            $global_safe    # this flag is set to true, if somehow global safety is turned on, means disabled HTML escaping
        ) = @_;
        
        ...
        
        my $result = $self->SUPER::render($context, $global_safe);   # in order to render current block contents, invoke the parent renderer
        
        ...
        
        return $result;     # this is just a string generated by tag. If your tag is silent, just return an empty string
    }

After creating your tag class, you need to register it in C<DTL::Fast>, so library knew which module to load on tag keyword:

    use DTL::Fast qw(register_tag);

    register_tag( 'my_block_tag' => 'CustomTags::MyBlockTag' );
    
Basically, that's all. For more information you may view through the sources of buit-in block tags.

=head1 CUSTOM FILTERS

Every filter in the library implemented as a class, inherited from L<C<DTL::Fast::Filter>>:

    package CustomFilters::MyFilter;                    # class name
    use strict; use utf8; use warnings FATAL => 'all';  # make your code clean
    use parent 'DTL::Fast::Filter';                     # parent class
    
    $DTL::Fast::FILTER_HANDLERS{'myfilter'} = __PACKAGE__;   # register your module as a filter handler
    
    # optional parameter parser, invoked on parsing phase.
    # If your filter is parametrised, you may need to override this method to parse parameters, stored in
    # the $self->{'parameter'} which is an array of DTL::Fast::Variable objects, one for each parameter
    sub parse_parameters
    {
        my( $self ) = @_;
        
        ... here you may process your input parameters...
        
        return $self;   # important to return $self
    }
    
    # main method 
    sub filter
    {
        my( 
            $self,              # filter object reference
            $filter_manager,    # filter manager object reference
            $value,             # filtering value
            $context            # current context for parametrised filters
        ) = @_;
        
        # here you may modify $value. Don't forget to make a shallow copies on arrays and hashes
        ....
        
        return $value;
    }

After creating your filter class, you need to register it in C<DTL::Fast>, so library knew which module to load on filter keyword:

    use DTL::Fast qw(register_filter);

    register_filter( 'myfilter' => 'CustomFilters::MyFilter' );
    
Basically, that's all. For more information you may view through the sources of buit-in filters.

=head1 CUSTOM OPERATORS

To do...

=head1 INCOMPATIBILITIES WITH DJANGO TEMPLATES

=over

=item * hashes being iterated differently from Python's. You can iterate hash only as C<key, val in hash>. No C<hash.items>, C<hash.keys>, C<hash.values> are supported.

=item * C<{{ block.super }}> construction is currently supported, but depricated in favor of C<{% block_super %}> tag.

=item * Django's setting C<ALLOWED_INCLUDE_ROOTS> should be passed to tempalte constructor/getter as C<ssi_dirs> argument.

=item * C<csrf_token> tag is not implemented, too well connected with Django.

=item * C<_dtl_*> variable names in context are reserved for internal system purposes. Don't use them.

=item * output from following tags: C<cycle>, C<firstof>, C<firstofdefined> are being escaped by default (like in later versions of Django)

=item * C<escapejs> filter works other way. It's not translating every non-ASCII character to the codepoint, but just escaping single and double quotes and C<\n \r \t \0>. Utf-8 symbols are pretty valid for javascript/json.

=item * C<fix_ampersands> filter is not implemented, because it's marked as depricated and will beremoved in Django 1.8

=item * C<pprint> filter is not implemented.

=item * C<iriencode> filter works like C<urlencode> for the moment.

=item * C<urlize> filter takes well-formatted url and makes link with this url and text generated by urldecoding and than escaping url link.

=item * wherever filter in Django returns C<True/False> values, C<DTL::Fast> returns C<1/0>.

=item * C<url> tag works a different way. Because there is no framework around, we can't obtain model's path the same way. But you may pass C<url_source> parameter into template constructor or C<get_template>/C<select_template> function. This parameter MUST be a reference to a function, that will return to templating engine url template by some 'model path' (first parameter of C<url> tag). Second parameter passed to the C<url_source> handler will be a reference to array of argument values (in case of positional arguments) or reference to a hash of arguments (in case of named ones). Url source handler may just return a regexp template by model path and templating engine will try to restore it with specified arguments. Or, you may restore it yourself, alter replacement arguments or do whatever you want. 

=back

=head1 EXTENSIONS OF DJANGO TEMPLATES

May be some of this features implemented in Django itself. Let me know about it.

=over

=item * filters may accept several arguments, and context variables can be used in them, like {{ var|filter1:var2:var3:...:varn }}

=item * C<defined> logical operator. In logical constructions you may use C<defined> operator, which works exactly like perl's C<defined>

=item * alternatively, in logical expresisons you may compare (==,!=) value to C<undef> or C<None> which are synonims

=item * C<slice> filter works with ARRAYs, HASHes and SCALARs (or SCALARrefs):

=over

=item * Arrays slicing supports Python's indexing rules and Perl's indexing rules (but Perl's one has no possibility to index from the end of the list).

=item * Scalars slicing works as substring from_index ... to_index. Supports both Perl's and Python's indexes.

=item * Hash slicing options should be a comma-separated keys.

=back

=item * You may use brackets in logical expressions to override natural precedence

=item * C<forloop> context hash inside a C<for> block tag contains additional fields: C<odd>, C<odd0>, C<even> and C<even0>

=item * variables rendering: if any code reference encountered due variable traversing, is being invoked with context argument. Like:

    {{ var1.key1.0.func.var2 }} 
    
is being rendered like: 

    $context->{'var1'}->{'key1'}->[0]->func($context)->{'var2'}

=item * you may use filters with static variables. Like:

    {{ "text > test"|safe }}

=item * objects behaviour methods. You may extend your objects, stored in context to make them work properly with some tags and operations:

=over

=item * C<as_bool>           - returns logical representation of object

=item * C<and(operand)>      - makes logical `and` between object and operand

=item * C<or(operand)>       - makes logical `or` between object and operand

=item * C<div(operand)>      - divides object by operand

=item * C<equal(operand)>    - checks if object is equal with operand

=item * C<compare(operand)>  - compares object with operand, returns -1, 0, 1 on less than, equal or greater than respectively

=item * C<in(operand)>       - checks if object is in operand

=item * C<contains(operand)> - checks if object contains operand

=item * C<minus(operand)>    - substitutes operand from object

=item * C<plus(operand)>     - adds operand to object

=item * C<mod(operand)>      - returns reminder from object division to operand

=item * C<mul(operand)>      - multiplicates object by operand

=item * C<pow(operand)>      - returns object powered by operand

=item * C<not()>             - returns object inversion

=item * C<reverse()>         - returns reversed object

=item * C<as_array()>        - returns array representation of object

=item * C<as_hash()>        - returns hash representation of object

=back 

=back

=head1 BENCHMARKS

I've compared module speed with previous abandoned implementation: L<C<Dotiac::DTL>> in both modes: FCGI and CGI. Test template and scripts are in /timethese directory.
Django templating in Python with cache works about 80% slower than C<DTL::Fast>.

=head2 FCGI/mod_perl

Template parsing permormance with software cache wiping on each iteration:

    Benchmark: timing 5000 iterations of DTL::Fast  , Dotiac::DTL...
    
    DTL::Fast  :  5 wallclock secs ( 4.59 usr +  0.12 sys =  4.71 CPU) @ 1061.36/s (n=5000)
    Dotiac::DTL: 41 wallclock secs (38.66 usr +  2.22 sys = 40.88 CPU) @ 122.30/s (n=5000)

C<DTL::Fast> parsing templates 8.67 times faster, than L<C<Dotiac::DTL>>.

To run this test, you need to alter L<C<Dotiac::DTL>> module and change declaration of C<my %cache;> to C<our %cache;>. 
    
Rendering of pre-compiled template (software cache):

    Benchmark: timing 3000 iterations of DTL::Fast  , Dotiac::DTL...
    
    DTL::Fast  : 34 wallclock secs (33.86 usr +  0.39 sys = 34.25 CPU) @ 87.59/s (n=3000)
    Dotiac::DTL: 53 wallclock secs (52.93 usr +  0.62 sys = 53.55 CPU) @ 56.02/s (n=3000)

Tests shows, that C<DTL::Fast> works a 56% faster, than L<C<Dotiac::DTL>> in persistent environment.

=head2 CGI

This test rendered test template many times by external script, invoked via C<system> call:

    Benchmark: timing 300 iterations of Dotiac render     , Fast cached render, Fast render
    
    DTL::Fast  : 40 wallclock secs ( 0.00 usr  0.12 sys + 35.14 cusr  4.98 csys = 40.24 CPU) @  7.45/s (n=300)
    Dotiac::DTL: 51 wallclock secs ( 0.00 usr  0.12 sys + 38.29 cusr 12.63 csys = 51.04 CPU) @  5.88/s (n=300)

Tests shows, that C<DTL::Fast> works 27% faster, than L<C<Dotiac::DTL>> in CGI environment.

=head2 DTL::Fast steps performance

    1 Cache key  :  0 wallclock secs ( 0.19 usr +  0.00 sys =  0.19 CPU) @ 534759.36/s (n=100000)
    2 Decompress :  0 wallclock secs ( 0.27 usr +  0.00 sys =  0.27 CPU) @ 377358.49/s (n=100000)
    3 Serialize  :  4 wallclock secs ( 3.73 usr +  0.00 sys =  3.73 CPU) @ 26824.03/s (n=100000)
    4 Deserialize:  5 wallclock secs ( 4.26 usr +  0.00 sys =  4.26 CPU) @ 23479.69/s (n=100000)
    5 Compress   : 10 wallclock secs (10.50 usr +  0.00 sys = 10.50 CPU) @ 9524.72/s (n=100000)
    6 Validate   : 11 wallclock secs ( 3.12 usr +  8.05 sys = 11.17 CPU) @ 8952.55/s (n=100000)

    7 Parse      :  1 wallclock secs ( 0.44 usr +  0.23 sys =  0.67 CPU) @ 1492.54/s (n=1000)
    8 Render     : 11 wallclock secs ( 9.30 usr +  1.14 sys = 10.44 CPU) @ 95.82/s (n=1000)    

=head1 SEE ALSO

=over

=item * Main project repository and bugtracker: L<https://github.com/hurricup/DTL-Fast>

=item * CPAN Testers reports: L<http://www.cpantesters.org/distro/D/DTL-Fast.html>

=item * Testers matrix: L<http://matrix.cpantesters.org/?dist=DTL-Fast>
        
=item * AnnoCPAN, Annotated CPAN documentation: L<http://annocpan.org/dist/DTL-Fast>

=item * CPAN Ratings: L<http://cpanratings.perl.org/d/DTL-Fast>

=item * Original Django templating documentation: L<https://docs.djangoproject.com/en/1.8/topics/templates/>

=item * Other implementaion: L<http://search.cpan.org/~maluku/Dotiac-0.8/lib/Dotiac/DTL.pm>

=back

=head1 LICENSE

This module is published under the terms of the MIT license, which basically means "Do with it whatever you want". For more information, see the LICENSE file that should be enclosed with this distributions. A copy of the license is (at the time of writing) also available at L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Copyright (C) 2014-2015 by Alexandr Evstigneev (L<hurricup@evstigneev.com|mailto:hurricup@evstigneev.com>)

=cut

