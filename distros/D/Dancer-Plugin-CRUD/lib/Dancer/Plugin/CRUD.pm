use strict;
use warnings;

package Dancer::Plugin::CRUD;

# ABSTRACT: A plugin for writing RESTful apps with Dancer

use Carp 'croak';
use Dancer ':syntax';
use Dancer::Plugin;
use Sub::Name;
use Text::Pluralize;
use Validate::Tiny ();

our $VERSION = '1.031';    # VERSION

our $SUFFIX = '_id';

my $content_types = {
    json  => 'application/json',
    yml   => 'text/x-yaml',
    xml   => 'application/xml',
    dump  => 'text/x-perl',
    jsonp => 'text/javascript',
};

my %triggers_map = (
    get   => \&get,
    index => \&get,
    read  => \&get,

    post   => \&post,
    create => \&post,

    put    => \&put,
    update => \&put,

    del    => \&del,
    delete => \&del,

    patch => \&patch,
);

my %alt_syntax = (
    get  => 'read',
    post => 'create',
    put  => 'update',
    del  => 'delete',
);

my %http_codes = (

    # 1xx
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',

    # 2xx
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',
    210 => 'Content Different',

    # 3xx
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    310 => 'Too many Redirect',

    # 4xx
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Time-out',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Requested range unsatisfiable',
    417 => 'Expectation failed',
    418 => 'Teapot',
    422 => 'Unprocessable entity',
    423 => 'Locked',
    424 => 'Method failure',
    425 => 'Unordered Collection',
    426 => 'Upgrade Required',
    449 => 'Retry With',
    450 => 'Parental Controls',

    # 5xx
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Time-out',
    505 => 'HTTP Version not supported',
    507 => 'Insufficient storage',
    509 => 'Bandwidth Limit Exceeded',
);

our $default_serializer;
my $stack = [];

sub _generate_sub {
    my %options = %{ shift() };

    my $resname = $options{stack}->[-1]->{resname};

    my $rules = [
        map  { $_->{validation_rules}->{generic} }
        grep { exists $_->{validation_rules} } reverse @{ $options{stack} }
    ];

    if ( @$rules > 0 ) {
        push @$rules,
          $options{stack}->[-1]->{validation_rules}->{ $options{action} }
          if exists $options{stack}->[-1]->{validation_rules}
          ->{ $options{action} };

        $rules = {
            fields => [
                map  { ( @{ $_->{fields} } ) }
                grep { exists $_->{fields} } @$rules
            ],
            checks => [
                map    { ( @{ $_->{checks} } ) }
                  grep { exists $_->{checks} } @$rules
            ],
            filters => [
                map    { ( @{ $_->{filters} } ) }
                  grep { exists $_->{filters} } @$rules
            ],
        };
    }
    else {
        $rules = undef;
    }

    my $chain = [
        map {
            {
                fn   => $_->{chain},
                fnid => $_->{chain_id},
                name => $_->{resname}
            }
        } @{ $options{stack} }
    ];

    my @idfields = map { $_->{resname} . $SUFFIX }
      grep {
        (         ( $options{action} =~ m'^(index|create)$' )
              and ( $_->{resname} eq $resname ) )
          ? 0
          : 1
      } @{ $options{stack} };

    my $subname = join( '_', $resname, $options{action} );

    return subname(
        $subname,
        sub {
            if ( defined $rules ) {
                my $input = {
                    %{ params('query') },
                    %{ params('body') },
                    %{ captures() || {} }
                };
                my $result = Validate::Tiny->new(
                    $input,
                    {
                        %$rules, fields => [ @idfields, @{ $rules->{fields} } ]
                    }
                );
                unless ( $result->success ) {
                    status(400);
                    return { error => $result->error };
                }
                var validate => $result;
            }

            {
                my @chain = @$chain;

                #unless ($options{action} ~~ [qw[ read update delete patch ]]) {
                #	pop @chain;
                #}
                my %cap = %{ captures() || {} };
                foreach my $ci (@chain) {
                    my ( $name, $fn, $fnid ) =
                      map { $ci->{$_} } qw(name fn fnid);
                    if ( exists $cap{ $name . $SUFFIX }
                        and ref $fnid eq 'CODE' )
                    {
                        $fnid->( $cap{ $name . $SUFFIX } );
                    }
                    elsif ( ref $fn eq 'CODE' ) {
                        $fn->();
                    }
                }
            }

            my @ret =
              $options{coderef}->( map { $_->{resname} } @{ $options{stack} } );

            if (    @ret
                and defined $ret[0]
                and ref $ret[0] eq ''
                and $ret[0] =~ m{^\d{3}$} )
            {
                # return ($http_status_code, ...)
                if ( $ret[0] >= 400 ) {

                    # return ($http_error_code, $error_message)
                    status( $ret[0] );
                    return { error => $ret[1] };
                }
                else {
                    # return ($http_success_code, $payload)
                    status( $ret[0] );
                    return $ret[1];
                }
            }
            elsif ( status eq '200' ) {

                # http status wasn't changed yet
                if    ( $options{action} eq 'create' ) { status(201) }
                elsif ( $options{action} eq 'update' ) { status(202) }
                elsif ( $options{action} eq 'delete' ) { status(202) }
            }

            # return payload
            return ( wantarray ? @ret : $ret[0] );
        }
    );
}

sub _prefix {
    my ( $prefix, $cb ) = @_;

    my $app = Dancer::App->current;

    my $app_prefix = defined $app->app_prefix ? $app->app_prefix : "";
    my $previous = Dancer::App->current->prefix;

    if ( $app->on_lexical_prefix ) {
        if ( ref $previous eq 'Regexp' ) {
            $app->prefix(qr/${previous}${prefix}/);
        }
        else {
            my $previous_ = quotemeta($previous);
            $app->prefix(qr/${previous_}${prefix}/);
        }
    }
    else {
        if ( ref $app_prefix eq 'Regexp' ) {
            $app->prefix(qr/${app_prefix}${prefix}/);
        }
        else {
            my $app_prefix_ = quotemeta($app_prefix);
            $app->prefix(qr/${app_prefix_}${prefix}/);
        }
    }

    if ( ref($cb) eq 'CODE' ) {
        $app->incr_lexical_prefix;
        eval { $cb->() };
        my $e = $@;
        $app->dec_lexical_prefix;
        $app->prefix($previous);
        die $e if $e;
    }
}

register prepare_serializer_for_format => sub () {
    my $conf        = plugin_setting;
    my $serializers = {
        'json'  => 'JSON',
        'jsonp' => 'JSONP',
        'yml'   => 'YAML',
        'xml'   => 'XML',
        'dump'  => 'Dumper',
        ( exists $conf->{serializers} ? %{ $conf->{serializers} } : () )
    };

    hook(
        before => sub {

            # remember what was there before
            $default_serializer ||= setting('serializer');

            my $format = defined captures() ? captures->{format} : undef;
            $format ||= param('format') or return;

            my $serializer = $serializers->{$format}
              or return halt(
                Dancer::Error->new(
                    code    => 404,
                    title   => "unsupported format requested",
                    message => "unsupported format requested: " . $format
                )->render
              );

            set( serializer => $serializer );

            # check if we were supposed to deserialize the request
            Dancer::Serializer->process_request( Dancer::SharedData->request );

            content_type( $content_types->{$format}
                  || setting('content_type') );
        }
    );

    hook(
        after => sub {

            # put it back the way it was
            set( serializer => $default_serializer );
        }
    );
};

register(
    resource => sub ($%) {
        my $resource = my $resource1 = my $resource2 = shift;
        my %triggers = @_;

        {
            my $c = quotemeta '()|{}';
            if ( $resource =~ m{[$c]} ) {
                $resource1 = pluralize( $resource1, 1 );
                $resource2 = pluralize( $resource2, 2 );
            }
        }

        my %options;
        push @$stack => \%options;

        $options{resname} = $resource1;

        my $altsyntax = 0;
        if ( exists $triggers{altsyntax} ) {
            $altsyntax = delete $triggers{altsyntax};
        }

        my $idregex = qr{[^\/\.\:\?]+};

        if ( exists $triggers{idregex} ) {
            $idregex = delete $triggers{idregex};
        }

        $options{prefix} = qr{/\Q$resource2\E};
        $options{prefix_id} =
          qr{/\Q$resource1\E/(?<$resource1$SUFFIX>$idregex)};

        if ( exists $triggers{validation} ) {
            $options{validation_rules} = delete $triggers{validation};
        }

        if ( exists $triggers{chain} ) {
            $options{chain} = delete $triggers{chain};
        }

        if ( exists $triggers{"chain$SUFFIX"} ) {
            $options{chain_id} = delete $triggers{"chain$SUFFIX"};
        }

        if ( exists $triggers{ 'prefix' . $SUFFIX } ) {
            my $subref = delete $triggers{ 'prefix' . $SUFFIX };
            $options{prefixed_with_id} = 1;
            my @prefixes =
              map { $_->{prefixed_with_id} ? $_->{prefix_id} : $_->{prefix} }
              grep { exists $_->{prefix} } @$stack;
            local $" = '';
            _prefix( qr{@prefixes}, $subref );
            delete $options{prefixed_with_id};
        }

        if ( exists $triggers{prefix} ) {
            my $subref = delete $triggers{'prefix'};
            $options{prefixed_with_id} = 0;
            my @prefixes =
              map { $_->{prefixed_with_id} ? $_->{prefix_id} : $_->{prefix} }
              grep { exists $_->{prefix} } @$stack;
            local $" = '';
            _prefix( qr{@prefixes}, $subref );
            delete $options{prefixed_with_id};
        }

        my %routes;

        foreach my $action (qw(index create read delete update patch)) {
            next unless exists $triggers{$action};

            my $route;

            if ( $action eq 'index' ) {
                $route = qr{/\Q$resource2\E};
            }
            elsif ( $action eq 'create' ) {
                $route = qr{/\Q$resource1\E};
            }
            else {
                $route = qr{/\Q$resource1\E/(?<$resource1$SUFFIX>$idregex)};
            }

            my $sub = _generate_sub(
                {
                    stack   => $stack,
                    action  => $action,
                    coderef => $triggers{$action},
                }
            );

            $routes{$action} = [];

            if ($altsyntax) {
                push @{ $routes{$action} } => $triggers_map{get}
                  ->( qr{$route/\Q$action\E\.(?<format>json|jsonp|yml|xml|dump)}
                      => $sub );
                push @{ $routes{$action} } =>
                  $triggers_map{get}->( qr{$route/\Q$action\E} => $sub );
            }
            push @{ $routes{$action} } => $triggers_map{$action}
              ->( qr{$route\.(?<format>json|jsonp|yml|xml|dump)} => $sub );
            push @{ $routes{$action} } =>
              $triggers_map{$action}->( $route => $sub );
        }

        pop @$stack;

        return %routes;
    }
);

register(
    wrap => sub($$$) {
        my ( $action, $route, $coderef ) = @_;

        my @route = grep { defined and length } split m{/+}, $route;

        my $parent = @$stack ? $stack->[-1] : undef;
        foreach my $route (@route) {
            push @$stack => { resname => $route };
        }

        if ( defined $parent ) {
            if (    exists $parent->{validation_rules}
                and exists $parent->{validation_rules}->{wrap}
                and exists $parent->{validation_rules}->{wrap}->{$action}
                and
                exists $parent->{validation_rules}->{wrap}->{$action}->{$route}
              )
            {
                $stack->[-1]->{validation_rules} =
                  { lc($action) =>
                      $parent->{validation_rules}->{wrap}->{$action}->{$route}
                  };
            }
        }

        my $sub = _generate_sub(
            {
                action  => lc($action),
                stack   => $stack,
                coderef => $coderef,
            }
        );

        pop @$stack for @route;

        my @routes;

        push @routes => $triggers_map{ lc($action) }
          ->( qr{/\Q$route\E\.(?<format>json|jsonp|yml|xml|dump)} => $sub );
        push @routes =>
          $triggers_map{ lc($action) }->( qr{/\Q$route\E} => $sub );

        return @routes;
    }
);

register send_entity => sub {

    # entity, status_code
    status( $_[1] || 200 );
    $_[0];
};

for my $code ( keys %http_codes ) {
    my $helper_name = lc( $http_codes{$code} );
    $helper_name =~ s/[^\w]+/_/gms;
    $helper_name = "status_${helper_name}";

    register $helper_name => sub {
        if ( $code >= 400 ) {
            send_entity( { error => $_[0] }, $code );
        }
        else {
            send_entity( $_[0], $code );
        }
    };
}

register_plugin;
1;

__END__

=pod

=head1 NAME

Dancer::Plugin::CRUD - A plugin for writing RESTful apps with Dancer

=head1 VERSION

version 1.031

=head1 DESCRIPTION

This plugin is derived from L<Dancer::Plugin::REST|Dancer::Plugin::REST> and helps you write a RESTful webservice with Dancer.

=head1 METHODS

=head2 C<< prepare_serializer_for_format >>

When this pragma is used, a before filter is set by the plugin to automatically
change the serializer when a format is detected in the URI.

That means that each route you define with a B<:format> token will trigger a
serializer definition, if the format is known.

This lets you define all the REST actions you like as regular Dancer route
handlers, without explicitly handling the outgoing data format.

=head2 C<< resource >>

This keyword lets you declare a resource your application will handle.

Derived from L<Dancer::Plugin::REST|Dancer::Plugin::REST>, this method has rewritten to provide a more slightly convention. C<get> has been renamed to C<read> and three new actions has been added: C<index>, C<patch>, C<prefix> and C<prefix_id>

Also, L<Text::Pluralize|Text::Pluralize> is applied to resource name with count=1 for singular variant and count=2 for plural variant. If you don't provide a singular/plural variant (i.e. resource name contains parenthesis) the singular and the plural becomes same.

The id name is derived from singular resource name, appended with C<_id>.

    resource 'user(s)' =>
        index  => sub { ... }, # return all users
        read   => sub { ... }, # return user where id = captures->{user_id}
        create => sub { ... }, # create a new user with params->{user}
        delete => sub { ... }, # delete user where id = captures->{user_id}
        update => sub { ... }, # update user with params->{user}
        patch  => sub { ... }, # patches user with params->{user}
        prefix => sub {
          # prefixed resource in plural
		  # routes are only possible with regex!
          get qr{/foo} => sub { ... },
        },
        prefix_id => sub {
          # prefixed resource in singular with id
		  # captures->{user_id}
		  # routes are only possible with regex!
          get qr{/bar} => sub { ... },
        };

    # this defines the following routes:
    # prefix_id =>
    #   GET /user/:user_id/bar
    # prefix =>
    #   GET /users/foo
    # index =>
    #   GET /users.:format
    #   GET /users
    # create =>
    #   POST /user.:format
    #   POST /user
    # read =>
    #   GET /user/:id.:format
    #   GET /user/:id
    # delete =>
    #   DELETE /user/:id.:format
    #   DELETE /user/:id
    # update =>
    #   PUT /user/:id.:format
    #   PUT /user/:id
    # patch =>
    #   PATCH /user.:format
    #   PATCH /user

The routes are created in the above order.

Returns a hash with arrayrefs of all created L<Dancer::Route|Dancer::Route> objects.

Hint: resources can be stacked with C<prefix>/C<prefix_id>:

	resource foo =>
		prefix => sub {
			get '/bar' => sub {
				return 'Hi!'
			};
		}, # GET /foo/bar
		prefix_id => sub {
			get '/bar' => sub {
				return 'Hey '.captures->{foo_id}
			}; # GET /foo/123/bar
			resource bar =>
				read => sub {
					return 'foo is '
						. captures->{foo_id}
						.' and bar is '
						. captures->{bar_id}
					}
				}; # GET /foo/123/bar/456
		};

When is return value is a HTTP status code (three digits), C<status(...)> is applied to it. A second return value may be the value to be returned to the client itself:

	sub {
		return 200
	};
	
	sub {
		return 404 => 'This object has not been found.'
	}
	
	sub {
		return 201 => { ... }
	};

The default HTTP status code ("200 OK") differs in some actions: C<create> response with "201 Created", C<delete> and C<update> response with "202 Accepted".

=head3 Change of suffix

The appended suffix, C<_id> for default, can be changed by setting C<< $Dancer::Plugin::CRUD::SUFFIX >>. This affects both captures names and the suffix of parameterized C<prefix> method:

	$Dancer::Plugin::CRUD::SUFFIX = 'Id';
	resource 'User' => prefixId => sub { return captures->{'UserId'} };

=head3 Automatic validation of parameters

Synopsis:

    resource foo =>
        validation => {
            generic => {
                checks => [
                    foo_id => Validate::Tiny::is_like(qr{^\d+})
                ]
            },
        },
        read => sub {
            $foo_id = var('validate')->data('foo_id');
        },
	;

The keyword C<validation> specifies rules for L<Validation::Tiny|Validation::Tiny>.

The parameter input resolves to following order: C<params('query')>, C<params('body')>, C<captures()>.

The rules and the result of C<Dancer::params()> are applied to C<Validate::Tiny::new> and stored in C<var('validate')>.

The hashref C<validation> accepts seven keywords:

=over 4

=item I<generic>

These are generic rules, used in every action. For the actions I<index> and I<create>, the fields I<<< C<< $resource >>_id >>> are ignored, since they aren't needed.

=item I<index>, I<create>, I<read>, I<update>, I<delete>

These rules are merged together with I<generic>.

=item I<prefix>, I<prefix_id>

These rules are merged together with I<generic>, but they can only used when C<resource()> is used in the prefix subs.

=item I<wrap>

These rules apply when in a prefix or prefix_id routine the I<wrap> keyword is used:

	resource foo =>
		validation => {
			wrap => {
				GET => {
					bar => {
						fields => [qw[ name ]]
					}
				}
			}
		},
		prefix => sub {
			wrap GET => bar => sub { ... }
		};

=back

The id-fields (I<<< C<< $resource >>_id >>>, ...) are automatically prepended to the I<fields> param of Validate::Tiny. There is no need to define them especially.

An advantage is the feature of stacking resources and to define validation rules only once.

Example:

    resource foo =>
        validation => {
            generic => {
                checks => [
                    foo_id => Validate::Tiny::is_like(qr{^\d+})
                ]
            },
        },
		prefix_id => sub {
			resource bar =>
				validation => {
					generic => {
						checks => [
							bar_id => Validate::Tiny::is_like(qr{^\d+})
						]
					},
				},
				read => sub {
					$foo_id = var('validate')->data('foo_id');
					$bar_id = var('validate')->data('foo_id');
				},
			;
		},
	;

=head3 Chaining actions together

To avoid redundant code, the keywords I<chain> and I<chain_id> may used to define coderefs called every time the resource (and possible parent resources) is triggered, respective of the method.

I<chain> applies to method I<index> only. I<chain_id> (where the suffix I<_id> depends on what C<$SUFFIX> says) applies to all other methods. I<chain_id> is called with a single parameter: the value of the corresponding capture.

Example:

    resource foo =>
		chain_id => sub { var my_foo_id => shift },
		read => sub { return var('my_foo_id') }
        prefix_id => sub {
            resource bar =>
				chain_id => sub { var my_bar_id => shift },
				read => sub { return var('my_foo_id').var('my_bar_id') },
			;
        },
	;

When resource I</foo/123> is triggered, the variable C<my_foo_id> is set to 123 and the single text 123 is returned. When resource I</foo/123/bar/456> is triggered, the variable C<my_foo_id> is set to 123 and, of course, C<my_bar_id> is set to 456 and the single return text is 123456. 

This is useful to obtain parent objects from DB and store it into the var stack.

B<HINT>: In a earlier release the keyword I<chain> applied to all methods. If you have ever used version 1.03, please keep in mind that this behaviour has changed meanwhile.

=head2 C<< wrap >>

This keyword wraps validation rules and format accessors. For return values see C<resource>.

Synopsis:

	resource foo =>
		prefix_id => sub {
			wrap GET => bar => sub {
				# same as get('/bar', sub { ... });
				# and get('/bar.:format', sub { ... });
				# var('validate') is also availble,
				# when key 'validation' is defined
			};
		},
	;

I<wrap> uses the same wrapper as for the actions in I<resource>. Any beviour there also applies here. For a better explaination, these resolves to the same routes:

	resource foo => read => sub { ... };
	wrap read => foo => sub { ... };

The first argument is an CRUD action (I<index>, I<create>, I<read>, I<update>, I<delete>) or a HTTP method (I<GET>, I<POST>, I<PUT>, I<DELETE>, I<PATCH>) and is case-insensitve. The second argument is a route name. A leading slash will be prepended if the route contains to slashes. The third argument is the well known coderef.

Please keep in mind that I<wrap> creates two routes: I<<< /C<< $route >> >>> and I<<< /C<< $route >>.:format >>>.

Returns a list of all created L<Dancer::Route|Dancer::Route> objects.

=head2 helpers

Some helpers are available. This helper will set an appropriate HTTP status for you.

=head3 status_ok

    status_ok({users => {...}});

Set the HTTP status to 200

=head3 status_created

    status_created({users => {...}});

Set the HTTP status to 201

=head3 status_accepted

    status_accepted({users => {...}});

Set the HTTP status to 202

=head3 status_bad_request

    status_bad_request("user foo can't be found");

Set the HTTP status to 400. This function as for argument a scalar that will be used under the key B<error>.

=head3 status_not_found

    status_not_found("users doesn't exists");

Set the HTTP status to 404. This function as for argument a scalar that will be used under the key B<error>.

=head1 SYNOPSYS

	package MyWebService;
	
	use Dancer;
	use Dancer::Plugin::CRUD;
	
	prepare_serializer_for_format;
	
	my $userdb = My::UserDB->new(...);
	
	resource('user',
		'read' => sub { $userdb->find(captures()->{'user_id'}) }
	);
	
	# curl http://mywebservice/user/42.json
	{ "id": 42, "name": "John Foo", email: "john.foo@example.com"}
	
	# curl http://mywebservice/user/42.yml
	--
	id: 42
	name: "John Foo"
	email: "john.foo@example.com"

=head1 SEE ALSO

=over 4

=item * L<Dancer>

=item * L<http://en.wikipedia.org/wiki/Representational_State_Transfer>

=item * L<Dancer::Plugin::REST>

=item * L<Text::Pluralize>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer-plugin-crud-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

David Zurborg <zurborg@cpan.org>

=item *

Alexis Sukrieh <sukria@sukria.net> (Author of Dancer::Plugin::REST)

=item *

Franck Cuny <franckc@cpan.org> (Author of Dancer::Plugin::REST)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Zurborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
