#line 1
package Catalyst;

use Moose;
use Moose::Meta::Class ();
extends 'Catalyst::Component';
use Moose::Util qw/find_meta/;
use B::Hooks::EndOfScope ();
use Catalyst::Exception;
use Catalyst::Exception::Detach;
use Catalyst::Exception::Go;
use Catalyst::Log;
use Catalyst::Request;
use Catalyst::Request::Upload;
use Catalyst::Response;
use Catalyst::Utils;
use Catalyst::Controller;
use Devel::InnerPackage ();
use File::stat;
use Module::Pluggable::Object ();
use Text::SimpleTable ();
use Path::Class::Dir ();
use Path::Class::File ();
use URI ();
use URI::http;
use URI::https;
use Tree::Simple qw/use_weak_refs/;
use Tree::Simple::Visitor::FindByUID;
use Class::C3::Adopt::NEXT;
use List::MoreUtils qw/uniq/;
use attributes;
use utf8;
use Carp qw/croak carp shortmess/;

BEGIN { require 5.008004; }

has stack => (is => 'ro', default => sub { [] });
has stash => (is => 'rw', default => sub { {} });
has state => (is => 'rw', default => 0);
has stats => (is => 'rw');
has action => (is => 'rw');
has counter => (is => 'rw', default => sub { {} });
has request => (is => 'rw', default => sub { $_[0]->request_class->new({}) }, required => 1, lazy => 1);
has response => (is => 'rw', default => sub { $_[0]->response_class->new({}) }, required => 1, lazy => 1);
has namespace => (is => 'rw');

sub depth { scalar @{ shift->stack || [] }; }
sub comp { shift->component(@_) }

sub req {
    my $self = shift; return $self->request(@_);
}
sub res {
    my $self = shift; return $self->response(@_);
}

# For backwards compatibility
sub finalize_output { shift->finalize_body(@_) };

# For statistics
our $COUNT     = 1;
our $START     = time;
our $RECURSION = 1000;
our $DETACH    = Catalyst::Exception::Detach->new;
our $GO        = Catalyst::Exception::Go->new;

#I imagine that very few of these really need to be class variables. if any.
#maybe we should just make them attributes with a default?
__PACKAGE__->mk_classdata($_)
  for qw/components arguments dispatcher engine log dispatcher_class
  engine_class context_class request_class response_class stats_class
  setup_finished/;

__PACKAGE__->dispatcher_class('Catalyst::Dispatcher');
__PACKAGE__->engine_class('Catalyst::Engine::CGI');
__PACKAGE__->request_class('Catalyst::Request');
__PACKAGE__->response_class('Catalyst::Response');
__PACKAGE__->stats_class('Catalyst::Stats');

# Remember to update this in Catalyst::Runtime as well!

our $VERSION = '5.80019';
$VERSION = eval $VERSION;

sub import {
    my ( $class, @arguments ) = @_;

    # We have to limit $class to Catalyst to avoid pushing Catalyst upon every
    # callers @ISA.
    return unless $class eq 'Catalyst';

    my $caller = caller();
    return if $caller eq 'main';

    my $meta = Moose::Meta::Class->initialize($caller);
    unless ( $caller->isa('Catalyst') ) {
        my @superclasses = ($meta->superclasses, $class, 'Catalyst::Controller');
        $meta->superclasses(@superclasses);
    }
    # Avoid possible C3 issues if 'Moose::Object' is already on RHS of MyApp
    $meta->superclasses(grep { $_ ne 'Moose::Object' } $meta->superclasses);

    unless( $meta->has_method('meta') ){
        $meta->add_method(meta => sub { Moose::Meta::Class->initialize("${caller}") } );
    }

    $caller->arguments( [@arguments] );
    $caller->setup_home;
}

sub _application { $_[0] }

#line 367

sub forward { my $c = shift; no warnings 'recursion'; $c->dispatcher->forward( $c, @_ ) }

#line 382

sub detach { my $c = shift; $c->dispatcher->detach( $c, @_ ) }

#line 412

sub visit { my $c = shift; $c->dispatcher->visit( $c, @_ ) }

#line 430

sub go { my $c = shift; $c->dispatcher->go( $c, @_ ) }

#line 457

around stash => sub {
    my $orig = shift;
    my $c = shift;
    my $stash = $orig->($c);
    if (@_) {
        my $new_stash = @_ > 1 ? {@_} : $_[0];
        croak('stash takes a hash or hashref') unless ref $new_stash;
        foreach my $key ( keys %$new_stash ) {
          $stash->{$key} = $new_stash->{$key};
        }
    }

    return $stash;
};


#line 491

sub error {
    my $c = shift;
    if ( $_[0] ) {
        my $error = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
        croak @$error unless ref $c;
        push @{ $c->{error} }, @$error;
    }
    elsif ( defined $_[0] ) { $c->{error} = undef }
    return $c->{error} || [];
}


#line 520

sub clear_errors {
    my $c = shift;
    $c->error(0);
}

sub _comp_search_prefixes {
    my $c = shift;
    return map $c->components->{ $_ }, $c->_comp_names_search_prefixes(@_);
}

# search components given a name and some prefixes
sub _comp_names_search_prefixes {
    my ( $c, $name, @prefixes ) = @_;
    my $appclass = ref $c || $c;
    my $filter   = "^${appclass}::(" . join( '|', @prefixes ) . ')::';
    $filter = qr/$filter/; # Compile regex now rather than once per loop

    # map the original component name to the sub part that we will search against
    my %eligible = map { my $n = $_; $n =~ s{^$appclass\::[^:]+::}{}; $_ => $n; }
        grep { /$filter/ } keys %{ $c->components };

    # undef for a name will return all
    return keys %eligible if !defined $name;

    my $query  = ref $name ? $name : qr/^$name$/i;
    my @result = grep { $eligible{$_} =~ m{$query} } keys %eligible;

    return @result if @result;

    # if we were given a regexp to search against, we're done.
    return if ref $name;

    # skip regexp fallback if configured
    return
        if $appclass->config->{disable_component_resolution_regex_fallback};

    # regexp fallback
    $query  = qr/$name/i;
    @result = grep { $eligible{ $_ } =~ m{$query} } keys %eligible;

    # no results? try against full names
    if( !@result ) {
        @result = grep { m{$query} } keys %eligible;
    }

    # don't warn if we didn't find any results, it just might not exist
    if( @result ) {
        # Disgusting hack to work out correct method name
        my $warn_for = lc $prefixes[0];
        my $msg = "Used regexp fallback for \$c->${warn_for}('${name}'), which found '" .
           (join '", "', @result) . "'. Relying on regexp fallback behavior for " .
           "component resolution is unreliable and unsafe.";
        my $short = $result[0];
        # remove the component namespace prefix
        $short =~ s/.*?(Model|Controller|View):://;
        my $shortmess = Carp::shortmess('');
        if ($shortmess =~ m#Catalyst/Plugin#) {
           $msg .= " You probably need to set '$short' instead of '${name}' in this " .
              "plugin's config";
        } elsif ($shortmess =~ m#Catalyst/lib/(View|Controller)#) {
           $msg .= " You probably need to set '$short' instead of '${name}' in this " .
              "component's config";
        } else {
           $msg .= " You probably meant \$c->${warn_for}('$short') instead of \$c->${warn_for}('${name}'), " .
              "but if you really wanted to search, pass in a regexp as the argument " .
              "like so: \$c->${warn_for}(qr/${name}/)";
        }
        $c->log->warn( "${msg}$shortmess" );
    }

    return @result;
}

# Find possible names for a prefix
sub _comp_names {
    my ( $c, @prefixes ) = @_;
    my $appclass = ref $c || $c;

    my $filter = "^${appclass}::(" . join( '|', @prefixes ) . ')::';

    my @names = map { s{$filter}{}; $_; }
        $c->_comp_names_search_prefixes( undef, @prefixes );

    return @names;
}

# Filter a component before returning by calling ACCEPT_CONTEXT if available
sub _filter_component {
    my ( $c, $comp, @args ) = @_;

    if ( eval { $comp->can('ACCEPT_CONTEXT'); } ) {
        return $comp->ACCEPT_CONTEXT( $c, @args );
    }

    return $comp;
}

#line 636

sub controller {
    my ( $c, $name, @args ) = @_;

    if( $name ) {
        my @result = $c->_comp_search_prefixes( $name, qw/Controller C/ );
        return map { $c->_filter_component( $_, @args ) } @result if ref $name;
        return $c->_filter_component( $result[ 0 ], @args );
    }

    return $c->component( $c->action->class );
}

#line 669

sub model {
    my ( $c, $name, @args ) = @_;
    my $appclass = ref($c) || $c;
    if( $name ) {
        my @result = $c->_comp_search_prefixes( $name, qw/Model M/ );
        return map { $c->_filter_component( $_, @args ) } @result if ref $name;
        return $c->_filter_component( $result[ 0 ], @args );
    }

    if (ref $c) {
        return $c->stash->{current_model_instance}
          if $c->stash->{current_model_instance};
        return $c->model( $c->stash->{current_model} )
          if $c->stash->{current_model};
    }
    return $c->model( $appclass->config->{default_model} )
      if $appclass->config->{default_model};

    my( $comp, $rest ) = $c->_comp_search_prefixes( undef, qw/Model M/);

    if( $rest ) {
        $c->log->warn( Carp::shortmess('Calling $c->model() will return a random model unless you specify one of:') );
        $c->log->warn( '* $c->config(default_model => "the name of the default model to use")' );
        $c->log->warn( '* $c->stash->{current_model} # the name of the model to use for this request' );
        $c->log->warn( '* $c->stash->{current_model_instance} # the instance of the model to use for this request' );
        $c->log->warn( 'NB: in version 5.81, the "random" behavior will not work at all.' );
    }

    return $c->_filter_component( $comp );
}


#line 722

sub view {
    my ( $c, $name, @args ) = @_;

    my $appclass = ref($c) || $c;
    if( $name ) {
        my @result = $c->_comp_search_prefixes( $name, qw/View V/ );
        return map { $c->_filter_component( $_, @args ) } @result if ref $name;
        return $c->_filter_component( $result[ 0 ], @args );
    }

    if (ref $c) {
        return $c->stash->{current_view_instance}
          if $c->stash->{current_view_instance};
        return $c->view( $c->stash->{current_view} )
          if $c->stash->{current_view};
    }
    return $c->view( $appclass->config->{default_view} )
      if $appclass->config->{default_view};

    my( $comp, $rest ) = $c->_comp_search_prefixes( undef, qw/View V/);

    if( $rest ) {
        $c->log->warn( 'Calling $c->view() will return a random view unless you specify one of:' );
        $c->log->warn( '* $c->config(default_view => "the name of the default view to use")' );
        $c->log->warn( '* $c->stash->{current_view} # the name of the view to use for this request' );
        $c->log->warn( '* $c->stash->{current_view_instance} # the instance of the view to use for this request' );
        $c->log->warn( 'NB: in version 5.81, the "random" behavior will not work at all.' );
    }

    return $c->_filter_component( $comp );
}

#line 760

sub controllers {
    my ( $c ) = @_;
    return $c->_comp_names(qw/Controller C/);
}

#line 771

sub models {
    my ( $c ) = @_;
    return $c->_comp_names(qw/Model M/);
}


#line 783

sub views {
    my ( $c ) = @_;
    return $c->_comp_names(qw/View V/);
}

#line 808

sub component {
    my ( $c, $name, @args ) = @_;

    if( $name ) {
        my $comps = $c->components;

        if( !ref $name ) {
            # is it the exact name?
            return $c->_filter_component( $comps->{ $name }, @args )
                       if exists $comps->{ $name };

            # perhaps we just omitted "MyApp"?
            my $composed = ( ref $c || $c ) . "::${name}";
            return $c->_filter_component( $comps->{ $composed }, @args )
                       if exists $comps->{ $composed };

            # search all of the models, views and controllers
            my( $comp ) = $c->_comp_search_prefixes( $name, qw/Model M Controller C View V/ );
            return $c->_filter_component( $comp, @args ) if $comp;
        }

        # This is here so $c->comp( '::M::' ) works
        my $query = ref $name ? $name : qr{$name}i;

        my @result = grep { m{$query} } keys %{ $c->components };
        return map { $c->_filter_component( $_, @args ) } @result if ref $name;

        if( $result[ 0 ] ) {
            $c->log->warn( Carp::shortmess(qq(Found results for "${name}" using regexp fallback)) );
            $c->log->warn( 'Relying on the regexp fallback behavior for component resolution' );
            $c->log->warn( 'is unreliable and unsafe. You have been warned' );
            return $c->_filter_component( $result[ 0 ], @args );
        }

        # I would expect to return an empty list here, but that breaks back-compat
    }

    # fallback
    return sort keys %{ $c->components };
}

#line 889

around config => sub {
    my $orig = shift;
    my $c = shift;

    croak('Setting config after setup has been run is not allowed.')
        if ( @_ and $c->setup_finished );

    $c->$orig(@_);
};

#line 941

sub debug { 0 }

#line 967

sub path_to {
    my ( $c, @path ) = @_;
    my $path = Path::Class::Dir->new( $c->config->{home}, @path );
    if ( -d $path ) { return $path }
    else { return Path::Class::File->new( $c->config->{home}, @path ) }
}

#line 989

sub plugin {
    my ( $class, $name, $plugin, @args ) = @_;

    # See block comment in t/unit_core_plugin.t
    $class->log->warn(qq/Adding plugin using the ->plugin method is deprecated, and will be removed in Catalyst 5.81/);

    $class->_register_plugin( $plugin, 1 );

    eval { $plugin->import };
    $class->mk_classdata($name);
    my $obj;
    eval { $obj = $plugin->new(@args) };

    if ($@) {
        Catalyst::Exception->throw( message =>
              qq/Couldn't instantiate instant plugin "$plugin", "$@"/ );
    }

    $class->$name($obj);
    $class->log->debug(qq/Initialized instant plugin "$plugin" as "$name"/)
      if $class->debug;
}

#line 1024

sub setup {
    my ( $class, @arguments ) = @_;
    croak('Running setup more than once')
        if ( $class->setup_finished );

    unless ( $class->isa('Catalyst') ) {

        Catalyst::Exception->throw(
            message => qq/'$class' does not inherit from Catalyst/ );
    }

    if ( $class->arguments ) {
        @arguments = ( @arguments, @{ $class->arguments } );
    }

    # Process options
    my $flags = {};

    foreach (@arguments) {

        if (/^-Debug$/) {
            $flags->{log} =
              ( $flags->{log} ) ? 'debug,' . $flags->{log} : 'debug';
        }
        elsif (/^-(\w+)=?(.*)$/) {
            $flags->{ lc $1 } = $2;
        }
        else {
            push @{ $flags->{plugins} }, $_;
        }
    }

    $class->setup_home( delete $flags->{home} );

    $class->setup_log( delete $flags->{log} );
    $class->setup_plugins( delete $flags->{plugins} );
    $class->setup_dispatcher( delete $flags->{dispatcher} );
    $class->setup_engine( delete $flags->{engine} );
    $class->setup_stats( delete $flags->{stats} );

    for my $flag ( sort keys %{$flags} ) {

        if ( my $code = $class->can( 'setup_' . $flag ) ) {
            &$code( $class, delete $flags->{$flag} );
        }
        else {
            $class->log->warn(qq/Unknown flag "$flag"/);
        }
    }

    eval { require Catalyst::Devel; };
    if( !$@ && $ENV{CATALYST_SCRIPT_GEN} && ( $ENV{CATALYST_SCRIPT_GEN} < $Catalyst::Devel::CATALYST_SCRIPT_GEN ) ) {
        $class->log->warn(<<"EOF");
You are running an old script!

  Please update by running (this will overwrite existing files):
    catalyst.pl -force -scripts $class

  or (this will not overwrite existing files):
    catalyst.pl -scripts $class

EOF
    }

    if ( $class->debug ) {
        my @plugins = map { "$_  " . ( $_->VERSION || '' ) } $class->registered_plugins;

        if (@plugins) {
            my $column_width = Catalyst::Utils::term_width() - 6;
            my $t = Text::SimpleTable->new($column_width);
            $t->row($_) for @plugins;
            $class->log->debug( "Loaded plugins:\n" . $t->draw . "\n" );
        }

        my $dispatcher = $class->dispatcher;
        my $engine     = $class->engine;
        my $home       = $class->config->{home};

        $class->log->debug(sprintf(q/Loaded dispatcher "%s"/, blessed($dispatcher)));
        $class->log->debug(sprintf(q/Loaded engine "%s"/, blessed($engine)));

        $home
          ? ( -d $home )
          ? $class->log->debug(qq/Found home "$home"/)
          : $class->log->debug(qq/Home "$home" doesn't exist/)
          : $class->log->debug(q/Couldn't find home/);
    }

    # Call plugins setup, this is stupid and evil.
    # Also screws C3 badly on 5.10, hack to avoid.
    {
        no warnings qw/redefine/;
        local *setup = sub { };
        $class->setup unless $Catalyst::__AM_RESTARTING;
    }

    # Initialize our data structure
    $class->components( {} );

    $class->setup_components;

    if ( $class->debug ) {
        my $column_width = Catalyst::Utils::term_width() - 8 - 9;
        my $t = Text::SimpleTable->new( [ $column_width, 'Class' ], [ 8, 'Type' ] );
        for my $comp ( sort keys %{ $class->components } ) {
            my $type = ref $class->components->{$comp} ? 'instance' : 'class';
            $t->row( $comp, $type );
        }
        $class->log->debug( "Loaded components:\n" . $t->draw . "\n" )
          if ( keys %{ $class->components } );
    }

    # Add our self to components, since we are also a component
    if( $class->isa('Catalyst::Controller') ){
      $class->components->{$class} = $class;
    }

    $class->setup_actions;

    if ( $class->debug ) {
        my $name = $class->config->{name} || 'Application';
        $class->log->info("$name powered by Catalyst $Catalyst::VERSION");
    }

    # Make sure that the application class becomes immutable at this point,
    B::Hooks::EndOfScope::on_scope_end {
        return if $@;
        my $meta = Class::MOP::get_metaclass_by_name($class);
        if (
            $meta->is_immutable
            && ! { $meta->immutable_options }->{replace_constructor}
            && (
                   $class->isa('Class::Accessor::Fast')
                || $class->isa('Class::Accessor')
            )
        ) {
            warn "You made your application class ($class) immutable, "
                . "but did not inline the\nconstructor. "
                . "This will break catalyst, as your app \@ISA "
                . "Class::Accessor(::Fast)?\nPlease pass "
                . "(replace_constructor => 1)\nwhen making your class immutable.\n";
        }
        $meta->make_immutable(
            replace_constructor => 1,
        ) unless $meta->is_immutable;
    };

    if ($class->config->{case_sensitive}) {
        $class->log->warn($class . "->config->{case_sensitive} is set.");
        $class->log->warn("This setting is deprecated and planned to be removed in Catalyst 5.81.");
    }

    $class->setup_finalize;
    # Should be the last thing we do so that user things hooking
    # setup_finalize can log..
    $class->log->_flush() if $class->log->can('_flush');
    return 1; # Explicit return true as people have __PACKAGE__->setup as the last thing in their class. HATE.
}


#line 1203

sub setup_finalize {
    my ($class) = @_;
    $class->setup_finished(1);
}

#line 1251

sub uri_for {
    my ( $c, $path, @args ) = @_;

    if (blessed($path) && $path->isa('Catalyst::Controller')) {
        $path = $path->path_prefix;
        $path =~ s{/+\z}{};
        $path .= '/';
    }

    undef($path) if (defined $path && $path eq '');

    my $params =
      ( scalar @args && ref $args[$#args] eq 'HASH' ? pop @args : {} );

    carp "uri_for called with undef argument" if grep { ! defined $_ } @args;
    s/([^$URI::uric])/$URI::Escape::escapes{$1}/go for @args;
    if (blessed $path) { # Action object only.
        s|/|%2F|g for @args;
    }

    if ( blessed($path) ) { # action object
        my $captures = [ map { s|/|%2F|g; $_; }
                        ( scalar @args && ref $args[0] eq 'ARRAY'
                         ? @{ shift(@args) }
                         : ()) ];
        my $action = $path;
        $path = $c->dispatcher->uri_for_action($action, $captures);
        if (not defined $path) {
            $c->log->debug(qq/Can't find uri_for action '$action' @$captures/)
                if $c->debug;
            return undef;
        }
        $path = '/' if $path eq '';
    }

    unshift(@args, $path);

    unless (defined $path && $path =~ s!^/!!) { # in-place strip
        my $namespace = $c->namespace;
        if (defined $path) { # cheesy hack to handle path '../foo'
           $namespace =~ s{(?:^|/)[^/]+$}{} while $args[0] =~ s{^\.\./}{};
        }
        unshift(@args, $namespace || '');
    }

    # join args with '/', or a blank string
    my $args = join('/', grep { defined($_) } @args);
    $args =~ s/\?/%3F/g; # STUPID STUPID SPECIAL CASE
    $args =~ s!^/+!!;
    my $base = $c->req->base;
    my $class = ref($base);
    $base =~ s{(?<!/)$}{/};

    my $query = '';

    if (my @keys = keys %$params) {
      # somewhat lifted from URI::_query's query_form
      $query = '?'.join('&', map {
          my $val = $params->{$_};
          s/([;\/?:@&=+,\$\[\]%])/$URI::Escape::escapes{$1}/go;
          s/ /+/g;
          my $key = $_;
          $val = '' unless defined $val;
          (map {
              my $param = "$_";
              utf8::encode( $param ) if utf8::is_utf8($param);
              # using the URI::Escape pattern here so utf8 chars survive
              $param =~ s/([^A-Za-z0-9\-_.!~*'() ])/$URI::Escape::escapes{$1}/go;
              $param =~ s/ /+/g;
              "${key}=$param"; } ( ref $val eq 'ARRAY' ? @$val : $val ));
      } @keys);
    }

    my $res = bless(\"${base}${args}${query}", $class);
    $res;
}

#line 1363

sub uri_for_action {
    my ( $c, $path, @args ) = @_;
    my $action = blessed($path)
      ? $path
      : $c->dispatcher->get_action_by_path($path);
    unless (defined $action) {
      croak "Can't find action for path '$path'";
    }
    return $c->uri_for( $action, @args );
}

#line 1380

sub welcome_message {
    my $c      = shift;
    my $name   = $c->config->{name};
    my $logo   = $c->uri_for('/static/images/catalyst_logo.png');
    my $prefix = Catalyst::Utils::appprefix( ref $c );
    $c->response->content_type('text/html; charset=utf-8');
    return <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
    <meta http-equiv="Content-Language" content="en" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>$name on Catalyst $VERSION</title>
        <style type="text/css">
            body {
                color: #000;
                background-color: #eee;
            }
            div#content {
                width: 640px;
                margin-left: auto;
                margin-right: auto;
                margin-top: 10px;
                margin-bottom: 10px;
                text-align: left;
                background-color: #ccc;
                border: 1px solid #aaa;
            }
            p, h1, h2 {
                margin-left: 20px;
                margin-right: 20px;
                font-family: verdana, tahoma, sans-serif;
            }
            a {
                font-family: verdana, tahoma, sans-serif;
            }
            :link, :visited {
                    text-decoration: none;
                    color: #b00;
                    border-bottom: 1px dotted #bbb;
            }
            :link:hover, :visited:hover {
                    color: #555;
            }
            div#topbar {
                margin: 0px;
            }
            pre {
                margin: 10px;
                padding: 8px;
            }
            div#answers {
                padding: 8px;
                margin: 10px;
                background-color: #fff;
                border: 1px solid #aaa;
            }
            h1 {
                font-size: 0.9em;
                font-weight: normal;
                text-align: center;
            }
            h2 {
                font-size: 1.0em;
            }
            p {
                font-size: 0.9em;
            }
            p img {
                float: right;
                margin-left: 10px;
            }
            span#appname {
                font-weight: bold;
                font-size: 1.6em;
            }
        </style>
    </head>
    <body>
        <div id="content">
            <div id="topbar">
                <h1><span id="appname">$name</span> on <a href="http://catalyst.perl.org">Catalyst</a>
                    $VERSION</h1>
             </div>
             <div id="answers">
                 <p>
                 <img src="$logo" alt="Catalyst Logo" />
                 </p>
                 <p>Welcome to the  world of Catalyst.
                    This <a href="http://en.wikipedia.org/wiki/MVC">MVC</a>
                    framework will make web development something you had
                    never expected it to be: Fun, rewarding, and quick.</p>
                 <h2>What to do now?</h2>
                 <p>That really depends  on what <b>you</b> want to do.
                    We do, however, provide you with a few starting points.</p>
                 <p>If you want to jump right into web development with Catalyst
                    you might want to start with a tutorial.</p>
<pre>perldoc <a href="http://cpansearch.perl.org/dist/Catalyst-Manual/lib/Catalyst/Manual/Tutorial.pod">Catalyst::Manual::Tutorial</a></code>
</pre>
<p>Afterwards you can go on to check out a more complete look at our features.</p>
<pre>
<code>perldoc <a href="http://cpansearch.perl.org/dist/Catalyst-Manual/lib/Catalyst/Manual/Intro.pod">Catalyst::Manual::Intro</a>
<!-- Something else should go here, but the Catalyst::Manual link seems unhelpful -->
</code></pre>
                 <h2>What to do next?</h2>
                 <p>Next it's time to write an actual application. Use the
                    helper scripts to generate <a href="http://cpansearch.perl.org/search?query=Catalyst%3A%3AController%3A%3A&amp;mode=all">controllers</a>,
                    <a href="http://cpansearch.perl.org/search?query=Catalyst%3A%3AModel%3A%3A&amp;mode=all">models</a>, and
                    <a href="http://cpansearch.perl.org/search?query=Catalyst%3A%3AView%3A%3A&amp;mode=all">views</a>;
                    they can save you a lot of work.</p>
                    <pre><code>script/${prefix}_create.pl -help</code></pre>
                    <p>Also, be sure to check out the vast and growing
                    collection of <a href="http://search.cpan.org/search?query=Catalyst">plugins for Catalyst on CPAN</a>;
                    you are likely to find what you need there.
                    </p>

                 <h2>Need help?</h2>
                 <p>Catalyst has a very active community. Here are the main places to
                    get in touch with us.</p>
                 <ul>
                     <li>
                         <a href="http://dev.catalyst.perl.org">Wiki</a>
                     </li>
                     <li>
                         <a href="http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst">Mailing-List</a>
                     </li>
                     <li>
                         <a href="irc://irc.perl.org/catalyst">IRC channel #catalyst on irc.perl.org</a>
                     </li>
                 </ul>
                 <h2>In conclusion</h2>
                 <p>The Catalyst team hopes you will enjoy using Catalyst as much
                    as we enjoyed making it. Please contact us if you have ideas
                    for improvement or other feedback.</p>
             </div>
         </div>
    </body>
</html>
EOF
}

#line 1549

sub dispatch { my $c = shift; $c->dispatcher->dispatch( $c, @_ ) }

#line 1562

sub dump_these {
    my $c = shift;
    [ Request => $c->req ],
    [ Response => $c->res ],
    [ Stash => $c->stash ],
    [ Config => $c->config ];
}

#line 1581

sub execute {
    my ( $c, $class, $code ) = @_;
    $class = $c->component($class) || $class;
    $c->state(0);

    if ( $c->depth >= $RECURSION ) {
        my $action = $code->reverse();
        $action = "/$action" unless $action =~ /->/;
        my $error = qq/Deep recursion detected calling "${action}"/;
        $c->log->error($error);
        $c->error($error);
        $c->state(0);
        return $c->state;
    }

    my $stats_info = $c->_stats_start_execute( $code ) if $c->use_stats;

    push( @{ $c->stack }, $code );

    no warnings 'recursion';
    eval { $c->state( $code->execute( $class, $c, @{ $c->req->args } ) || 0 ) };

    $c->_stats_finish_execute( $stats_info ) if $c->use_stats and $stats_info;

    my $last = pop( @{ $c->stack } );

    if ( my $error = $@ ) {
        if ( blessed($error) and $error->isa('Catalyst::Exception::Detach') ) {
            $error->rethrow if $c->depth > 1;
        }
        elsif ( blessed($error) and $error->isa('Catalyst::Exception::Go') ) {
            $error->rethrow if $c->depth > 0;
        }
        else {
            unless ( ref $error ) {
                no warnings 'uninitialized';
                chomp $error;
                my $class = $last->class;
                my $name  = $last->name;
                $error = qq/Caught exception in $class->$name "$error"/;
            }
            $c->error($error);
            $c->state(0);
        }
    }
    return $c->state;
}

sub _stats_start_execute {
    my ( $c, $code ) = @_;
    my $appclass = ref($c) || $c;
    return if ( ( $code->name =~ /^_.*/ )
        && ( !$appclass->config->{show_internal_actions} ) );

    my $action_name = $code->reverse();
    $c->counter->{$action_name}++;

    my $action = $action_name;
    $action = "/$action" unless $action =~ /->/;

    # determine if the call was the result of a forward
    # this is done by walking up the call stack and looking for a calling
    # sub of Catalyst::forward before the eval
    my $callsub = q{};
    for my $index ( 2 .. 11 ) {
        last
        if ( ( caller($index) )[0] eq 'Catalyst'
            && ( caller($index) )[3] eq '(eval)' );

        if ( ( caller($index) )[3] =~ /forward$/ ) {
            $callsub = ( caller($index) )[3];
            $action  = "-> $action";
            last;
        }
    }

    my $uid = $action_name . $c->counter->{$action_name};

    # is this a root-level call or a forwarded call?
    if ( $callsub =~ /forward$/ ) {
        my $parent = $c->stack->[-1];

        # forward, locate the caller
        if ( exists $c->counter->{"$parent"} ) {
            $c->stats->profile(
                begin  => $action,
                parent => "$parent" . $c->counter->{"$parent"},
                uid    => $uid,
            );
        }
        else {

            # forward with no caller may come from a plugin
            $c->stats->profile(
                begin => $action,
                uid   => $uid,
            );
        }
    }
    else {

        # root-level call
        $c->stats->profile(
            begin => $action,
            uid   => $uid,
        );
    }
    return $action;

}

sub _stats_finish_execute {
    my ( $c, $info ) = @_;
    $c->stats->profile( end => $info );
}

#line 1703

sub finalize {
    my $c = shift;

    for my $error ( @{ $c->error } ) {
        $c->log->error($error);
    }

    # Allow engine to handle finalize flow (for POE)
    my $engine = $c->engine;
    if ( my $code = $engine->can('finalize') ) {
        $engine->$code($c);
    }
    else {

        $c->finalize_uploads;

        # Error
        if ( $#{ $c->error } >= 0 ) {
            $c->finalize_error;
        }

        $c->finalize_headers;

        # HEAD request
        if ( $c->request->method eq 'HEAD' ) {
            $c->response->body('');
        }

        $c->finalize_body;
    }

    if ($c->use_stats) {
        my $elapsed = sprintf '%f', $c->stats->elapsed;
        my $av = $elapsed == 0 ? '??' : sprintf '%.3f', 1 / $elapsed;
        $c->log->info(
            "Request took ${elapsed}s ($av/s)\n" . $c->stats->report . "\n" );
    }

    return $c->response->status;
}

#line 1750

sub finalize_body { my $c = shift; $c->engine->finalize_body( $c, @_ ) }

#line 1758

sub finalize_cookies { my $c = shift; $c->engine->finalize_cookies( $c, @_ ) }

#line 1766

sub finalize_error { my $c = shift; $c->engine->finalize_error( $c, @_ ) }

#line 1774

sub finalize_headers {
    my $c = shift;

    my $response = $c->response; #accessor calls can add up?

    # Check if we already finalized headers
    return if $response->finalized_headers;

    # Handle redirects
    if ( my $location = $response->redirect ) {
        $c->log->debug(qq/Redirecting to "$location"/) if $c->debug;
        $response->header( Location => $location );

        if ( !$response->has_body ) {
            # Add a default body if none is already present
            $response->body(
                qq{<html><body><p>This item has moved <a href="$location">here</a>.</p></body></html>}
            );
        }
    }

    # Content-Length
    if ( $response->body && !$response->content_length ) {

        # get the length from a filehandle
        if ( blessed( $response->body ) && $response->body->can('read') )
        {
            my $stat = stat $response->body;
            if ( $stat && $stat->size > 0 ) {
                $response->content_length( $stat->size );
            }
            else {
                $c->log->warn('Serving filehandle without a content-length');
            }
        }
        else {
            # everything should be bytes at this point, but just in case
            $response->content_length( length( $response->body ) );
        }
    }

    # Errors
    if ( $response->status =~ /^(1\d\d|[23]04)$/ ) {
        $response->headers->remove_header("Content-Length");
        $response->body('');
    }

    $c->finalize_cookies;

    $c->engine->finalize_headers( $c, @_ );

    # Done
    $response->finalized_headers(1);
}

#line 1839

sub finalize_read { my $c = shift; $c->engine->finalize_read( $c, @_ ) }

#line 1847

sub finalize_uploads { my $c = shift; $c->engine->finalize_uploads( $c, @_ ) }

#line 1855

sub get_action { my $c = shift; $c->dispatcher->get_action(@_) }

#line 1864

sub get_actions { my $c = shift; $c->dispatcher->get_actions( $c, @_ ) }

#line 1872

sub handle_request {
    my ( $class, @arguments ) = @_;

    # Always expect worst case!
    my $status = -1;
    eval {
        if ($class->debug) {
            my $secs = time - $START || 1;
            my $av = sprintf '%.3f', $COUNT / $secs;
            my $time = localtime time;
            $class->log->info("*** Request $COUNT ($av/s) [$$] [$time] ***");
        }

        my $c = $class->prepare(@arguments);
        $c->dispatch;
        $status = $c->finalize;
    };

    if ( my $error = $@ ) {
        chomp $error;
        $class->log->error(qq/Caught exception in engine "$error"/);
    }

    $COUNT++;

    if(my $coderef = $class->log->can('_flush')){
        $class->log->$coderef();
    }
    return $status;
}

#line 1910

sub prepare {
    my ( $class, @arguments ) = @_;

    # XXX
    # After the app/ctxt split, this should become an attribute based on something passed
    # into the application.
    $class->context_class( ref $class || $class ) unless $class->context_class;

    my $c = $class->context_class->new({});

    # For on-demand data
    $c->request->_context($c);
    $c->response->_context($c);

    #surely this is not the most efficient way to do things...
    $c->stats($class->stats_class->new)->enable($c->use_stats);
    if ( $c->debug ) {
        $c->res->headers->header( 'X-Catalyst' => $Catalyst::VERSION );
    }

    #XXX reuse coderef from can
    # Allow engine to direct the prepare flow (for POE)
    if ( $c->engine->can('prepare') ) {
        $c->engine->prepare( $c, @arguments );
    }
    else {
        $c->prepare_request(@arguments);
        $c->prepare_connection;
        $c->prepare_query_parameters;
        $c->prepare_headers;
        $c->prepare_cookies;
        $c->prepare_path;

        # Prepare the body for reading, either by prepare_body
        # or the user, if they are using $c->read
        $c->prepare_read;

        # Parse the body unless the user wants it on-demand
        unless ( ref($c)->config->{parse_on_demand} ) {
            $c->prepare_body;
        }
    }

    my $method  = $c->req->method  || '';
    my $path    = $c->req->path;
    $path       = '/' unless length $path;
    my $address = $c->req->address || '';

    $c->log->debug(qq/"$method" request for "$path" from "$address"/)
      if $c->debug;

    $c->prepare_action;

    return $c;
}

#line 1972

sub prepare_action { my $c = shift; $c->dispatcher->prepare_action( $c, @_ ) }

#line 1980

sub prepare_body {
    my $c = shift;

    return if $c->request->_has_body;

    # Initialize on-demand data
    $c->engine->prepare_body( $c, @_ );
    $c->prepare_parameters;
    $c->prepare_uploads;

    if ( $c->debug && keys %{ $c->req->body_parameters } ) {
        my $t = Text::SimpleTable->new( [ 35, 'Parameter' ], [ 36, 'Value' ] );
        for my $key ( sort keys %{ $c->req->body_parameters } ) {
            my $param = $c->req->body_parameters->{$key};
            my $value = defined($param) ? $param : '';
            $t->row( $key,
                ref $value eq 'ARRAY' ? ( join ', ', @$value ) : $value );
        }
        $c->log->debug( "Body Parameters are:\n" . $t->draw );
    }
}

#line 2010

sub prepare_body_chunk {
    my $c = shift;
    $c->engine->prepare_body_chunk( $c, @_ );
}

#line 2021

sub prepare_body_parameters {
    my $c = shift;
    $c->engine->prepare_body_parameters( $c, @_ );
}

#line 2032

sub prepare_connection {
    my $c = shift;
    $c->engine->prepare_connection( $c, @_ );
}

#line 2043

sub prepare_cookies { my $c = shift; $c->engine->prepare_cookies( $c, @_ ) }

#line 2051

sub prepare_headers { my $c = shift; $c->engine->prepare_headers( $c, @_ ) }

#line 2059

sub prepare_parameters {
    my $c = shift;
    $c->prepare_body_parameters;
    $c->engine->prepare_parameters( $c, @_ );
}

#line 2071

sub prepare_path { my $c = shift; $c->engine->prepare_path( $c, @_ ) }

#line 2079

sub prepare_query_parameters {
    my $c = shift;

    $c->engine->prepare_query_parameters( $c, @_ );

    if ( $c->debug && keys %{ $c->request->query_parameters } ) {
        my $t = Text::SimpleTable->new( [ 35, 'Parameter' ], [ 36, 'Value' ] );
        for my $key ( sort keys %{ $c->req->query_parameters } ) {
            my $param = $c->req->query_parameters->{$key};
            my $value = defined($param) ? $param : '';
            $t->row( $key,
                ref $value eq 'ARRAY' ? ( join ', ', @$value ) : $value );
        }
        $c->log->debug( "Query Parameters are:\n" . $t->draw );
    }
}

#line 2102

sub prepare_read { my $c = shift; $c->engine->prepare_read( $c, @_ ) }

#line 2110

sub prepare_request { my $c = shift; $c->engine->prepare_request( $c, @_ ) }

#line 2118

sub prepare_uploads {
    my $c = shift;

    $c->engine->prepare_uploads( $c, @_ );

    if ( $c->debug && keys %{ $c->request->uploads } ) {
        my $t = Text::SimpleTable->new(
            [ 12, 'Parameter' ],
            [ 26, 'Filename' ],
            [ 18, 'Type' ],
            [ 9,  'Size' ]
        );
        for my $key ( sort keys %{ $c->request->uploads } ) {
            my $upload = $c->request->uploads->{$key};
            for my $u ( ref $upload eq 'ARRAY' ? @{$upload} : ($upload) ) {
                $t->row( $key, $u->filename, $u->type, $u->size );
            }
        }
        $c->log->debug( "File Uploads are:\n" . $t->draw );
    }
}

#line 2146

sub prepare_write { my $c = shift; $c->engine->prepare_write( $c, @_ ) }

#line 2171

sub read { my $c = shift; return $c->engine->read( $c, @_ ) }

#line 2179

sub run { my $c = shift; return $c->engine->run( $c, @_ ) }

#line 2187

sub set_action { my $c = shift; $c->dispatcher->set_action( $c, @_ ) }

#line 2195

sub setup_actions { my $c = shift; $c->dispatcher->setup_actions( $c, @_ ) }

#line 2212

sub setup_components {
    my $class = shift;

    my $config  = $class->config->{ setup_components };

    my @comps = sort { length $a <=> length $b }
                $class->locate_components($config);
    my %comps = map { $_ => 1 } @comps;

    my $deprecatedcatalyst_component_names = grep { /::[CMV]::/ } @comps;
    $class->log->warn(qq{Your application is using the deprecated ::[MVC]:: type naming scheme.\n}.
        qq{Please switch your class names to ::Model::, ::View:: and ::Controller: as appropriate.\n}
    ) if $deprecatedcatalyst_component_names;

    for my $component ( @comps ) {

        # We pass ignore_loaded here so that overlay files for (e.g.)
        # Model::DBI::Schema sub-classes are loaded - if it's in @comps
        # we know M::P::O found a file on disk so this is safe

        Catalyst::Utils::ensure_class_loaded( $component, { ignore_loaded => 1 } );

        # Needs to be done as soon as the component is loaded, as loading a sub-component
        # (next time round the loop) can cause us to get the wrong metaclass..
        $class->_controller_init_base_classes($component);
    }

    for my $component (@comps) {
        $class->components->{ $component } = $class->setup_component($component);
        for my $component ($class->expand_component_module( $component, $config )) {
            next if $comps{$component};
            $class->_controller_init_base_classes($component); # Also cover inner packages
            $class->components->{ $component } = $class->setup_component($component);
        }
    }
}

#line 2261

sub locate_components {
    my $class  = shift;
    my $config = shift;

    my @paths   = qw( ::Controller ::C ::Model ::M ::View ::V );
    my $extra   = delete $config->{ search_extra } || [];

    push @paths, @$extra;

    my $locator = Module::Pluggable::Object->new(
        search_path => [ map { s/^(?=::)/$class/; $_; } @paths ],
        %$config
    );

    my @comps = $locator->plugins;

    return @comps;
}

#line 2287

sub expand_component_module {
    my ($class, $module) = @_;
    return Devel::InnerPackage::list_packages( $module );
}

#line 2296

# FIXME - Ugly, ugly hack to ensure the we force initialize non-moose base classes
#         nearest to Catalyst::Controller first, no matter what order stuff happens
#         to be loaded. There are TODO tests in Moose for this, see
#         f2391d17574eff81d911b97be15ea51080500003
sub _controller_init_base_classes {
    my ($app_class, $component) = @_;
    return unless $component->isa('Catalyst::Controller');
    foreach my $class ( reverse @{ mro::get_linear_isa($component) } ) {
        Moose::Meta::Class->initialize( $class )
            unless find_meta($class);
    }
}

sub setup_component {
    my( $class, $component ) = @_;

    unless ( $component->can( 'COMPONENT' ) ) {
        return $component;
    }

    my $suffix = Catalyst::Utils::class2classsuffix( $component );
    my $config = $class->config->{ $suffix } || {};
    # Stash catalyst_component_name in the config here, so that custom COMPONENT
    # methods also pass it. local to avoid pointlessly shitting in config
    # for the debug screen, as $component is already the key name.
    local $config->{catalyst_component_name} = $component;

    my $instance = eval { $component->COMPONENT( $class, $config ); };

    if ( my $error = $@ ) {
        chomp $error;
        Catalyst::Exception->throw(
            message => qq/Couldn't instantiate component "$component", "$error"/
        );
    }

    unless (blessed $instance) {
        my $metaclass = Moose::Util::find_meta($component);
        my $method_meta = $metaclass->find_method_by_name('COMPONENT');
        my $component_method_from = $method_meta->associated_metaclass->name;
        my $value = defined($instance) ? $instance : 'undef';
        Catalyst::Exception->throw(
            message =>
            qq/Couldn't instantiate component "$component", COMPONENT() method (from $component_method_from) didn't return an object-like value (value was $value)./
        );
    }
    return $instance;
}

#line 2351

sub setup_dispatcher {
    my ( $class, $dispatcher ) = @_;

    if ($dispatcher) {
        $dispatcher = 'Catalyst::Dispatcher::' . $dispatcher;
    }

    if ( my $env = Catalyst::Utils::env_value( $class, 'DISPATCHER' ) ) {
        $dispatcher = 'Catalyst::Dispatcher::' . $env;
    }

    unless ($dispatcher) {
        $dispatcher = $class->dispatcher_class;
    }

    Class::MOP::load_class($dispatcher);

    # dispatcher instance
    $class->dispatcher( $dispatcher->new );
}

#line 2378

sub setup_engine {
    my ( $class, $engine ) = @_;

    if ($engine) {
        $engine = 'Catalyst::Engine::' . $engine;
    }

    if ( my $env = Catalyst::Utils::env_value( $class, 'ENGINE' ) ) {
        $engine = 'Catalyst::Engine::' . $env;
    }

    if ( $ENV{MOD_PERL} ) {
        my $meta = Class::MOP::get_metaclass_by_name($class);

        # create the apache method
        $meta->add_method('apache' => sub { shift->engine->apache });

        my ( $software, $version ) =
          $ENV{MOD_PERL} =~ /^(\S+)\/(\d+(?:[\.\_]\d+)+)/;

        $version =~ s/_//g;
        $version =~ s/(\.[^.]+)\./$1/g;

        if ( $software eq 'mod_perl' ) {

            if ( !$engine ) {

                if ( $version >= 1.99922 ) {
                    $engine = 'Catalyst::Engine::Apache2::MP20';
                }

                elsif ( $version >= 1.9901 ) {
                    $engine = 'Catalyst::Engine::Apache2::MP19';
                }

                elsif ( $version >= 1.24 ) {
                    $engine = 'Catalyst::Engine::Apache::MP13';
                }

                else {
                    Catalyst::Exception->throw( message =>
                          qq/Unsupported mod_perl version: $ENV{MOD_PERL}/ );
                }

            }

            # install the correct mod_perl handler
            if ( $version >= 1.9901 ) {
                *handler = sub  : method {
                    shift->handle_request(@_);
                };
            }
            else {
                *handler = sub ($$) { shift->handle_request(@_) };
            }

        }

        elsif ( $software eq 'Zeus-Perl' ) {
            $engine = 'Catalyst::Engine::Zeus';
        }

        else {
            Catalyst::Exception->throw(
                message => qq/Unsupported mod_perl: $ENV{MOD_PERL}/ );
        }
    }

    unless ($engine) {
        $engine = $class->engine_class;
    }

    Class::MOP::load_class($engine);

    # check for old engines that are no longer compatible
    my $old_engine;
    if ( $engine->isa('Catalyst::Engine::Apache')
        && !Catalyst::Engine::Apache->VERSION )
    {
        $old_engine = 1;
    }

    elsif ( $engine->isa('Catalyst::Engine::Server::Base')
        && Catalyst::Engine::Server->VERSION le '0.02' )
    {
        $old_engine = 1;
    }

    elsif ($engine->isa('Catalyst::Engine::HTTP::POE')
        && $engine->VERSION eq '0.01' )
    {
        $old_engine = 1;
    }

    elsif ($engine->isa('Catalyst::Engine::Zeus')
        && $engine->VERSION eq '0.01' )
    {
        $old_engine = 1;
    }

    if ($old_engine) {
        Catalyst::Exception->throw( message =>
              qq/Engine "$engine" is not supported by this version of Catalyst/
        );
    }

    # engine instance
    $class->engine( $engine->new );
}

#line 2494

sub setup_home {
    my ( $class, $home ) = @_;

    if ( my $env = Catalyst::Utils::env_value( $class, 'HOME' ) ) {
        $home = $env;
    }

    $home ||= Catalyst::Utils::home($class);

    if ($home) {
        #I remember recently being scolded for assigning config values like this
        $class->config->{home} ||= $home;
        $class->config->{root} ||= Path::Class::Dir->new($home)->subdir('root');
    }
}

#line 2526

sub setup_log {
    my ( $class, $levels ) = @_;

    $levels ||= '';
    $levels =~ s/^\s+//;
    $levels =~ s/\s+$//;
    my %levels = map { $_ => 1 } split /\s*,\s*/, $levels;

    my $env_debug = Catalyst::Utils::env_value( $class, 'DEBUG' );
    if ( defined $env_debug ) {
        $levels{debug} = 1 if $env_debug; # Ugly!
        delete($levels{debug}) unless $env_debug;
    }

    unless ( $class->log ) {
        $class->log( Catalyst::Log->new(keys %levels) );
    }

    if ( $levels{debug} ) {
        Class::MOP::get_metaclass_by_name($class)->add_method('debug' => sub { 1 });
        $class->log->debug('Debug messages enabled');
    }
}

#line 2556

#line 2562

sub setup_stats {
    my ( $class, $stats ) = @_;

    Catalyst::Utils::ensure_class_loaded($class->stats_class);

    my $env = Catalyst::Utils::env_value( $class, 'STATS' );
    if ( defined($env) ? $env : ($stats || $class->debug ) ) {
        Class::MOP::get_metaclass_by_name($class)->add_method('use_stats' => sub { 1 });
        $class->log->debug('Statistics enabled');
    }
}


#line 2590

{

    sub registered_plugins {
        my $proto = shift;
        return sort keys %{ $proto->_plugins } unless @_;
        my $plugin = shift;
        return 1 if exists $proto->_plugins->{$plugin};
        return exists $proto->_plugins->{"Catalyst::Plugin::$plugin"};
    }

    sub _register_plugin {
        my ( $proto, $plugin, $instant ) = @_;
        my $class = ref $proto || $proto;

        Class::MOP::load_class( $plugin );
        $class->log->warn( "$plugin inherits from 'Catalyst::Component' - this is decated and will not work in 5.81" )
            if $plugin->isa( 'Catalyst::Component' );
        $proto->_plugins->{$plugin} = 1;
        unless ($instant) {
            no strict 'refs';
            if ( my $meta = Class::MOP::get_metaclass_by_name($class) ) {
              my @superclasses = ($plugin, $meta->superclasses );
              $meta->superclasses(@superclasses);
            } else {
              unshift @{"$class\::ISA"}, $plugin;
            }
        }
        return $class;
    }

    sub setup_plugins {
        my ( $class, $plugins ) = @_;

        $class->_plugins( {} ) unless $class->_plugins;
        $plugins ||= [];

        my @plugins = Catalyst::Utils::resolve_namespace($class . '::Plugin', 'Catalyst::Plugin', @$plugins);

        for my $plugin ( reverse @plugins ) {
            Class::MOP::load_class($plugin);
            my $meta = find_meta($plugin);
            next if $meta && $meta->isa('Moose::Meta::Role');

            $class->_register_plugin($plugin);
        }

        my @roles =
            map { $_->name }
            grep { $_ && blessed($_) && $_->isa('Moose::Meta::Role') }
            map { find_meta($_) }
            @plugins;

        Moose::Util::apply_all_roles(
            $class => @roles
        ) if @roles;
    }
}

#line 2668

sub use_stats { 0 }


#line 2679

sub write {
    my $c = shift;

    # Finalize headers if someone manually writes output
    $c->finalize_headers;

    return $c->engine->write( $c, @_ );
}

#line 2695

sub version { return $Catalyst::VERSION }

#line 3009

no Moose;

__PACKAGE__->meta->make_immutable;

1;
