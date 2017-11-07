package Dancer2::Plugin::OpenAPIRoutes;

use strict;
use warnings;

# ABSTRACT: A Dancer2 plugin for creating routes from a Swagger2 spec
our $VERSION = '0.02';    # VERSION
use File::Spec;
use Dancer2::Plugin;
use Module::Load;
use Carp;
use JSON ();
use JSON::Pointer;
use YAML::XS;
use Data::Walk;

sub _path2mod {
    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
    map {s/[\W_]([[:lower:]])/\u$1/g; ucfirst} @_;
}

sub _build_path_map {
    my $schema = $_[0];
    my $paths  = $schema->{paths};
    #<<<
    my @paths = 
      map {
        my $p  = $_;
        my $ps = $_;
        $p =~ s!/\{[^{}]+\}!!g;
        (
            $p,
            [
                map { +{ method => $_, pspec => $ps } }
                  grep { !/^x-/ }
                  keys %{ $paths->{$_} }
            ]
          )
      }
      sort {    ## no critic (BuiltinFunctions::RequireSimpleSortBlock)
        my @a = split m{/}, $a;
        my @b = split m{/}, $b;
        @b <=> @a;
      }
      grep { !/^x-/ && 'HASH' eq ref $paths->{$_} }
      keys %{$paths};
    #>>>
    my %paths;
    ## no critic (ControlStructures::ProhibitCStyleForLoops)
    for (my $i = 0; $i < @paths; $i += 2) {
        my $p  = $paths[$i];
        my $ma = $paths[$i + 1];
        my $m;
        my $mn = @$ma;
        if ($mn == 1 && !exists $paths{$p}) {
            my @p = split m{/}, $p;
            if (@p > 2) {
                $m = pop @p;
            }
            $p = join "/", @p;
        }
        if ($m) {
            push @{$paths{$p}}, $m;
            my $ps     = $ma->[0]{pspec};
            my $method = $ma->[0]{method};
            $paths->{$ps}{$method}{'x-path-map'} = {
                module_path => $p,
                func        => $m
            };
        } else {
            for (@$ma) {
                my $ps     = $_->{pspec};
                my $method = $_->{method};
                push @{$paths{$p}}, $method;
                $paths->{$ps}{$method}{'x-path-map'} = {
                    module_path => $p,
                    func        => $method
                };

            }
        }
    }
    return \%paths;
}

my %http_methods_func_map_orig = (
    get     => 'fetch',
    post    => 'create',
    patch   => 'update',
    put     => 'replace',
    delete  => 'remove',
    options => 'choices',
    head    => 'check'
);

my %http_methods_func_map;

sub _path_to_fqfn {
    my ($config, $schema, $path_spec, $method) = @_;
    my $paths = $schema->{paths};
    my $module_name;
    my $func = $paths->{$path_spec}{$method}{'x-path-map'}{func};
    my @pwsr = split m{/}, $paths->{$path_spec}{$method}{'x-path-map'}{module_path};
    $module_name = join "::", map {_path2mod $_ } @pwsr;
    if ($http_methods_func_map{"$method:$path_spec"}) {
        my ($mf, $mm) = split /:/, $http_methods_func_map{"$method:$path_spec"}, 2;
        $func        = $mf if $mf;
        $module_name = $mm if $mm;
    }
    if ($module_name eq '') {
        $module_name = $config->{default_module} || $config->{appname};
    } else {
        $module_name = $config->{namespace} . $module_name;
    }
    my $rfunc = $http_methods_func_map{$func} ? $http_methods_func_map{$func} : $func;
    if ($rfunc eq 'create' && $func eq 'post' && $path_spec =~ m{/\{[^/{}]*\}$}) {
        $rfunc = 'update';
    }
    $rfunc =~ s/\W+/_/g;
    return ($module_name, $rfunc);
}

sub load_schema {
    my $config = shift;
    croak "Need schema file" if not $config->{schema};
    my $schema;
    my $file = File::Spec->catfile($config->{app}->location, $config->{schema});
    if ($config->{schema} =~ /\.json/i) {
        require Path::Tiny;
        $schema = JSON::from_json(path($file)->slurp_utf8);
    } elsif ($config->{schema} =~ /\.yaml/i) {
        $schema = YAML::XS::LoadFile $file;
    }
    if ($schema && 'HASH' eq ref $schema) {
        walkdepth + {
            wanted => sub {
                if (   "HASH" eq ref $_
                    && exists $_->{'$ref'}
                    && !ref $_->{'$ref'}
                    && keys %$_ == 1)
                {
                    (my $r = $_->{'$ref'}) =~ s/^#//;
                    my $rp = JSON::Pointer->get($schema, $r);
                    if ('HASH' eq ref $rp) {
                        %$_ = %$rp;
                    } else {
                        croak "Can't load schema part: " . YAML::XS::Dump($_);
                    }
                }
            }
        }, $schema;
    }
    return $schema;
}

sub _make_handler_params {
    my ($mpath, $parameters) = @_;
    my $param_eval = '';
    for my $parameter_spec (@$parameters) {
        next if $parameter_spec =~ /^x-/;
        my $in       = $parameter_spec->{in};
        my $name     = $parameter_spec->{name};
        my $required = $parameter_spec->{required};
        my $req_code = "push \@errors, \"required parameter '$name'" . " is absent\" if not exists \$input{\"$name\"};\n ";
        my $src;
        ## no critic (ControlStructures::ProhibitCascadingIfElse)
        if ($in eq 'body') {
            $req_code
                = $required
                ? "push \@errors, \"required parameter '$name'" . " is absent\" if not keys %{\$input{\"$name\"}};"
                : '';
              #<<<
            $param_eval .=
                "{ my \$value;\n"
              . "  if (\$app->request->header(\"Content-Type\")\n"
              . "    && \$app->request->header(\"Content-Type\") =~ m{application/json}) {\n"
              . "    \$value = JSON::decode_json (\$app->request->body)\n } else {\n"
              . "    \$value = \$app->request->body }\n"
              . "  \$input{\"$name\"} = \$value if defined \$value; $req_code" 
              . "}\n";
              #>>>
            $req_code = '';
        } elsif ($in eq 'header') {
            $param_eval .= "\$input{\"$name\"} = \$app->request->header(\"$name\");\n";
        } elsif ($in eq 'query') {
            $src = "\$app->request->params('query')";
        } elsif ($in eq 'path') {
            if ($parameter_spec->{type} && $parameter_spec->{type} eq 'integer') {
                $mpath =~ s/:$name\b/\\E(?<$name>\\d+)\\Q/;
                $src = "\$app->request->captures";
            } else {
                $src = "\$app->request->params('route')";
            }
        } elsif ($in eq 'formData') {
            if ($parameter_spec->{type} && $parameter_spec->{type} eq 'file') {
                $param_eval .= "\$input{\"$name\"} = \$app->request->upload(\"$name\");\n";
            } else {
                $src = "\$app->request->params('body')";
            }
        }
        if ($src) {
            $param_eval .= "{ my \$src = $src; \$input{\"$name\"} = " . "\$src->{\"$name\"} if 'HASH' eq ref \$src; }\n";
        }
        $param_eval .= $req_code if $required;
    }
    $param_eval .= "if(\@errors) { \$dsl->status('unprocessable_entity'); \$res = { errors => \\\@errors }; }\n";
    if ($mpath =~ /\(\?</) {
        $mpath = "\\Q$mpath\\E";
        $mpath =~ s/\\Q(.*?)\\E/quotemeta($1)/eg;
        $mpath = qr|$mpath|;
    }
    return ($mpath, $param_eval);
}

sub _path_compare {
    my $ssc = sub {
        length($_[1]) >= length($_[0])
            && substr($_[1], 0, 1 + length $_[0]) eq "$_[0]/";
    };
    return 0 if $a eq $b;
    if ($ssc->($a, $b)) {
        return 1;
    }
    if ($ssc->($b, $a)) {
        return -1;
    }
    return $a cmp $b;
}

register OpenAPIRoutes => sub {
    my ($dsl, $debug, $custom_map) = @_;
    my $json = JSON->new->utf8->allow_blessed->convert_blessed;
    my $app  = $dsl->app;
    local $SIG{__DIE__} = sub {Carp::confess(@_)};
    my $config = plugin_setting;
    $config->{app}     = $app;
    $config->{appname} = $dsl->config->{appname};
    my $schema = load_schema($config);
    my $paths  = $schema->{paths};
    _build_path_map($schema);
    %http_methods_func_map = %http_methods_func_map_orig;

    if ($custom_map && 'HASH' eq ref $custom_map) {
        my @cmk = keys %$custom_map;
        @http_methods_func_map{@cmk} = @{$custom_map}{@cmk};
    }
    for my $path_spec (sort _path_compare keys %$paths) {
        next if $path_spec =~ /^x-/;
        my $path = $path_spec;
        $path =~ s/\{([^{}]+?)\}/:$1/g;
        for my $method (sort keys %{$paths->{$path_spec}}) {
            next if $method =~ /^x-/;
            my ($module_name, $module_func) = _path_to_fqfn($config, $schema, $path_spec, $method);
            my @parameters;
            if ($paths->{$path_spec}{$method}{parameters}) {
                @parameters = @{$paths->{$path_spec}{$method}{parameters}};
            }
            my ($mpath, $param_eval) = _make_handler_params($path, \@parameters);
            my $dancer_method = $method eq 'delete' ? 'del' : $method;
            my $get_env = '';
            for (grep {/^x-env-/} keys %{$paths->{$path_spec}{$method}}) {
                my $name = $paths->{$path_spec}{$method}{$_};
                my ($env_var) = /^x-env-(.+)/;
                $env_var = uc $env_var;
                $env_var =~ s/\W/_/;
                $get_env .= "\$input{'$name'} = \$app->request->env->{'$env_var'} // '';\n";
            }
            my $prolog_code_src = <<"EOS";
            sub {
                my %input  = ();
                my \@errors = ();
                my \$res;
                my \$status;
                my \$callback;
                $param_eval;
                $get_env;
                (\$res, \$status, \$callback) = eval {${module_name}::$module_func( \\%input, \$dsl )} if not \$res;
                if(\$callback && 'CODE' eq ref \$callback) {
                    \$callback->();
                }
                if( \$app->request->header(\"Accept\")
                    && \$app->request->header(\"Accept\") =~ m{application/json}
                    && (\$\@ || ref \$res)) {
                    \$dsl->content_type("application/json");
                    if (not defined \$res) {
                        \$res = { error => \$\@ };
                        \$res->{error} =~ s/ at .*? line \\d+\.\\n?//;
                        \$dsl->status('bad_request');
                    } else {
                        \$dsl->status(\$status) if \$status;
                    }
                    return \$json->encode(\$res);
                } else {
                    die \$\@ if \$\@ and not defined \$res; 
                    \$dsl->status(\$status) if \$status;
                    if(!\$status && \$res && ref(\$res) && "\$res" =~ /^(HASH|ARRAY|SCALAR|CODE)\\(/ ) {
                        \$dsl->status('not_acceptable');
                        return; 
                    }
                    return \$res;
                }
            }
EOS
## no critic (BuiltinFunctions::ProhibitStringyEval)
            my $prolog_code = eval $prolog_code_src;
            if ($@) {
                my $error = $@;
                $dsl->error("$method $mpath ($error): $prolog_code_src");
                croak "Route $method $mpath cant be compiled: $error";
            }
            my $route = Dancer2::Core::Route->new(
                method => $method,
                regexp => $mpath,
                code   => $prolog_code,
                prefix => $app->prefix
            );
            if ($app->route_exists($route)) {
                croak "Route $method $mpath is already exists";
            }
            $debug && $dsl->debug("$dancer_method $path_spec -> $module_func in $module_name\n");
            my $success_load = eval {load $module_name; 1};
            croak "Can't load module $module_name for path $path_spec: $@"
                if not $success_load or $@;
            my $cref = "$module_name"->can($module_func);
            croak "Can't find function $module_func in module $module_name for path $path_spec"
                if not $cref;
            $dsl->$dancer_method($mpath => $prolog_code);
        }
    }
};

register_plugin;

1;

__END__

=encoding utf8

=head1 NAME
 
Dancer2::Plugin::OpenAPIRoutes - automatic routes creation 
from Swagger specification file.
 
=head1 SYNOPSIS
 
  use Dancer2;
  use Dancer2::Plugin::OpenAPIRoutes;
  OpenAPIRoutes(0);
 
=head1 DESCRIPTION
 
Automatically creates Dancer's routes from Swagger specification file.
Extracts request parameters according to given spec. Uploaded files are  
L<Dancer2::Core::Request::Upload> objects.

Automatically decodes JSON parameters if "Content-Type" is application/json.
Automatically encodes answers to application/json if "Accept" header asks for
it and returned value is reference. It checks also whether parameter is 
required or not but doesn't do real validation yet.

Catches thrown exceptions and makes JSON error messages if "Accept" 
is application/json. 

Makes very smart mapping from route to Module::handler_function.
For example:

  /order:
    post:
    ...
  /order/{id}
    delete:
    ...
    patch:
    ...

will be mapped to Order::create(), Order::remove() and Order::update() 
accordingly.

=head1 CONFIGURATION
 
Schema details will be taken from your Dancer2 application config file, and
should be specified as, for example: 
 
  plugins:
    OpenAPIRoutes:
      schema: public/swagger.yaml
      namespace: MyApp
      default_module: MyApp

=over

=item B<schema>

Location of the Swagger spec file relative to the project root.

=item B<namespace>

Starting namespace for generated module name.

=item B<default_module>

Module name to put root's routes.

=back

You have to call C<OpenAPIRoutes([$debug_flag, $custom_map])> 
in your main application module.
Optionally you can pass true value as first argument to see how it 
maps routes to Modules and functions.

=head1 SMART MAPPING

This is probably the most crucial feature of this plugin. It automatically
makes your application structured according to given spec file. 
It also makes your application less dependent on Dancer2 framework -
you have to think more about application logic and less 
about framework details. Mapping is complicated but intuitive. 

=head2 MAPPING RULES

Both the route and its HTTP method are used to compose the mapping.

=head3 HTTP METHOD MAPPING

This is starting point of the mapping algorithm. If route has only one
method, then route's last part can be used as function name in module
which name made of previous route parts. 

=over

=item B<POST>

In RESful terms B<POST> means creation of some resource. That's why
usually it maps to C<create()> function with one exception: if
route ends with B</{someId}> then it means C<update()>.

=item B<GET>

This methis is mapped to function C<fetch()>.

=item B<DELETE>

This method is mapped to C<remove()>. Perl language already has C<delete()>
function and it's better not to reuse its name.

=item B<PUT>

In RESful terms B<PUT> means full replacement of some resource. This method
is mapped to C<replace()>

=item B<PATCH>

In RESful terms B<PATCH> means partial update of some resource. This method
is mapped to C<update()>

=item B<OPTIONS>

This method is mapped to C<choices()>

=item B<HEAD>

This method is mapped to C<check()>

=back

You don't usually have to define B<HEAD> method because it's done automatically
from B<GET> throwing away real answer.

=head3 ROUTES MAPPING

Basic idea is very simple: /resource/subresource is mapped to 
Resource::Subresource module and function name is mapped according HTTP
method. Then there're special cases (from OpenAPI example spec): 

=over

=item B<POST> C</pet/{petId}/uploadImage> 

=item B<GET> C</pet/findByTags> 

=item B<GET> C</pet/findByStatus> 

=back

It would be silly to put these three routes with single method in separate 
modules C<Pet::UploadImage>, C<Pet::FindByTags> and C<Pet::FindByStatus>.
That's why routes with only one method are mapped to theirs "parents" with
function name from last route part.

B<NOTICE>: It's important to describe path parameters twice: in route and
in B<parameters> method's section. Because they are extracted as 
C<regexp captures> and routes with integer parameters should be dispatched 
first to avoid collision between C</pet/{petId}> and C</pet/findByTags>
type of routes.

=head2 INTERFACE

=head3 ENVIRONMENT VARIABLES

When you need some variable from B<PSGI>'s environment, like
B<REMOTE_USER>, then it's really inconvenient to get directly from
L<Dancer2> framework. There's a support to get it automatic using
OpenAPI extension keyword B<x-env-{environment-variable}> like
B<x-env-remote-user: user>. This keyword should be put in HTTP 
method section. Directive B<x-env-remote-user: user> will put
value of B<PSGI>'s environment variable C<REMOTE_USER> into
input hash parameter key C<user>.

=head3 FUNCTION INTERFACE 

Mapped route's function is called like this:

  ($result, $status, $callback) = ${module_name}::$module_func( \%input, $dsl );

Function receives hash reference with extracted parameters 
according to Swagger spec and C<Dancer2> C<DSL> object. 
This object is rarely needed but sometimes you need to have access to 
application's object, for example: 

  $dsl->app->send_file(...);

Most of the time function can return only one result like this:

  sub fetch {
    my $input   = $_[0];
    my $pet = schema->get_pet( $input->{petId} );
    return $pet;
  }

Sometimes you want to change response status:

  sub remove {
    my $input = $_[0];
    my $error = schema->delete_pet( $input->{petId} );
    if ($error) {
        return ( { error => $error }, 'bad_request' );
    }
    return ( '', 'no_content' );
  }

In some odd cases when you use old L<Dancer2>, then you have to call 
specific functions directly from route handler using callback:

  sub downloadFile {
    my $dsl      = $_[1];
    # ... 
    return (
      undef, undef,
      sub {
        $dsl->app->send_file(
          $filename,
          filename     => $filename,
          content_type => 
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        );
      }
    );
  }

=head2 CUSTOM MAPPING

When you need some customization to your routes mapping, you
can do it passing hash reference as second parameter to 
C<OpenAPIRoutes([$debug, $castom_map])>. You can change mapping
for HTTP method for all paths or only for specific ones like this:

  OpenAPIRoutes(1, {"get:/store/order/{orderId}" => "remove"});

(Very naughty joke): Instead of calling "fetch" for this specific
path it will call "remove". The whole schema:

  OpenAPIRoutes(1, {"$method[:$path]" => "[$function]:[$full::module::name]"});

like this:

  OpenAPIRoutes(1, {
      "put"               => "update",
      "post:/store/order" => "create_order",
      "post:/store/image" => "upload_image",
      # and so on ...
  });

=head1 AUTHOR
 
This module was written and is maintained by:
 
=over
 
=item * Anton Petrusevich
 
=back

=cut
