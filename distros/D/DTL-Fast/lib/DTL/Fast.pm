package DTL::Fast;
use strict;
use warnings FATAL => 'all';
use Exporter 'import';
use Digest::MD5 qw(md5_hex);

use 5.010;
our $VERSION = '2017.1'; # ==> ALSO update the version in the pod text below!

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
    my ( $template_name, %kwargs ) = @_;

    die  "Template name was not specified"
        if (not $template_name);

    die "Template directories array was not specified"
        if
            (not defined $kwargs{dirs}
                or ref $kwargs{dirs} ne 'ARRAY'
                or not scalar @{$kwargs{dirs}})
    ;

    my $cache_key = _get_cache_key( $template_name, %kwargs );

    my $template;

    $RUNTIME_CACHE //= DTL::Fast::Cache::Runtime->new();

    if (
        $kwargs{no_cache}
            or not defined ( $template = $RUNTIME_CACHE->get($cache_key))
    )
    {
        $template = read_template($template_name, %kwargs );

        if (defined $template)
        {
            $RUNTIME_CACHE->put($cache_key, $template);
        }
        else
        {
            die  sprintf( <<'_EOT_', $template_name, join("\n", @{$kwargs{dirs}}));
Unable to find template %s in directories: 
%s
_EOT_
        }
    }

    return $template;
}

sub _get_cache_key
{
    my ( $template_name, %kwargs ) = @_;

    return md5_hex(
        sprintf( '%s:%s:%s:%s'
            , __PACKAGE__
            , $template_name
            , join( ',', @{$kwargs{dirs}} )
            , join( ',', @{$kwargs{ssi_dirs} // [ ]})
            # shouldn't we pass uri_handler here?
        )
    )
    ;
}

sub read_template
{
    my ( $template_name, %kwargs ) = @_;

    my $template = undef;
    my $template_path = undef;

    die "Template directories array was not specified"
        if (not defined $kwargs{dirs}
            or not ref $kwargs{dirs}
            or not scalar @{$kwargs{dirs}})
    ;

    my $cache_key = _get_cache_key( $template_name, %kwargs );

    if (
        $kwargs{no_cache}
            or not exists $kwargs{cache}
            or not $kwargs{cache}
            or not $kwargs{cache}->isa('DTL::Fast::Cache')
            or not defined ($template = $kwargs{cache}->get($cache_key))
    )
    {
        ($template, $template_path) = _read_file($template_name, $kwargs{dirs});

        if (defined $template)
        {
            $kwargs{file_path} = $template_path;
            $template = DTL::Fast::Template->new( $template, %kwargs);

            $kwargs{cache}->put( $cache_key, $template )
                if
                    (defined $template
                        and exists $kwargs{cache}
                        and $kwargs{cache}
                        and $kwargs{cache}->isa('DTL::Fast::Cache'))
            ;
        }
    }

    if (defined $template)
    {
        $template->{cache} = $kwargs{cache} if ($kwargs{cache});
        $template->{url_source} = $kwargs{url_source} if ($kwargs{url_source});
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
        if (
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
    my ( $file_name ) = @_;
    my $result;

    if (open my $IF, '<', $file_name)
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
    my ( $template_names, %kwargs ) = @_;

    die  "First parameter must be a template names array reference"
        if (
            not ref $template_names
                or ref $template_names ne 'ARRAY'
                or not scalar @$template_names
        );

    my $result = undef;

    foreach my $template_name (@$template_names)
    {
        if (ref ( $result = get_template( $template_name, %kwargs )) eq 'DTL::Fast::Template')
        {
            last;
        }
    }

    return $result;
}

# registering tag as known
sub register_tag
{
    my ( %tags ) = @_;

    while( my ( $slug, $module) = each %tags )
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

    while( my ( $keyword, $module) = each %KNOWN_TAGS )
    {
        Module::Load::load($module);
        $LOADED_MODULES{$module} = time;
        delete $TAG_HANDLERS{$keyword} if (exists $TAG_HANDLERS{$keyword} and $TAG_HANDLERS{$keyword} ne $module);
    }

    return 1;
}


# registering filter as known
sub register_filter
{
    my ( %filters ) = @_;

    while( my ( $slug, $module) = each %filters )
    {
        $DTL::Fast::KNOWN_FILTERS{$slug} = $module;
        delete $FILTER_HANDLERS{$slug} if (exists $FILTER_HANDLERS{$slug} and $FILTER_HANDLERS{$slug} ne $module);
    }

    return;
}

sub preload_filters
{
    require Module::Load;

    while( my ( undef, $module) = each %KNOWN_FILTERS )
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
        my ($priority, $module) = @{$ops{$operator}};

        die "Operator priority must be a number from 0 to 8"
            if ($priority !~ /^[012345678]$/);

        $KNOWN_OPS{$priority} //= { };
        $KNOWN_OPS{$priority}->{$operator} = $module;
        $recompile{$priority} = 1;
        $KNOWN_OPS_PLAIN{$operator} = $module;
        delete $OPS_HANDLERS{$operator} if (exists $OPS_HANDLERS{$operator} and $OPS_HANDLERS{$operator} ne $module);
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

    while( my ( undef, $module) = each %KNOWN_OPS_PLAIN )
    {
        Module::Load::load($module);
        $LOADED_MODULES{$module} = time;
    }

    return 1;
}


require DTL::Fast::Template;
require DTL::Fast::Cache::Runtime;

1;

