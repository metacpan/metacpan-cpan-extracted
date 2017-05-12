package CGI::Application::URIMapping;

use strict;
use warnings;

use CGI;
use CGI::Application;
use List::MoreUtils qw(uniq);
use URI::Escape;

use base qw/CGI::Application::Dispatch Exporter/;

our %EXPORT_TAGS = (
    constants => [
        qw/URI_IS_PERMALINK URI_UNKNOWN_PARAM URI_PATH_PARAM_IN_QUERY/,
        qw/URI_PARAM_NOT_IN_ORDER URI_OMITTABLE_PARAM/,
    ],
);
$EXPORT_TAGS{all} = [ uniq map { @$_ } values %EXPORT_TAGS ];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

our $VERSION = 0.04;

use constant URI_IS_PERMALINK        => 0;
use constant URI_UNKNOWN_PARAM       => 1;
use constant URI_PATH_PARAM_IN_QUERY => 2;
use constant URI_PARAM_NOT_IN_ORDER  => 3;
use constant URI_OMITTABLE_PARAM     => 4;

our %dispatch_table;
our %uri_table;
our %app_init_map;

sub register {
    my ($self, @entries) = @_;

    my $dispatch_table = ($dispatch_table{ref($self) || $self} ||= {});
    my $uri_table = ($uri_table{ref($self) || $self} ||= {});
    
    foreach my $entry (@entries) {
        $entry = {
            path => $entry,
        } unless ref $entry;
        my $app = $entry->{app} || (caller)[0];
        my $host = $entry->{host} || '*';
        my $proto = $entry->{protocol} || 'http';
        my $uri_table_entry;
        my $rm;
        unless ($rm = $entry->{rm}) {
            unless (ref $entry->{path}) {
                (split '/:', $entry->{path}, 2)[0] =~ m|([^/]+)/?$|
                    and $rm = $1;
            }
        }
        die "no 'rm'\n" unless $rm;
        if (ref($entry->{path}) eq 'ARRAY') {
            die "unexpected number of elements in 'path'\n"
                unless @{$entry->{path}} && @{$entry->{path}} % 2 == 0;
            while (@{$entry->{path}}) {
                my $path = shift @{$entry->{path}};
                my $action = shift @{$entry->{path}};
                $action->{app} = $app;
                $action->{rm} = $rm;
                my $host2 = delete $action->{host} || $host;
                my $proto2 = delete $action->{protocol} || $proto;
                $dispatch_table->{$host} ||= [];
                push @{$dispatch_table->{$host2}}, $path, $action;
                $uri_table_entry ||= _build_uri_table_entry({
                    %$entry,
                    protocol => $proto2,
                    host     => $host2,
                    path     => $path,
                    query    => delete $action->{query} || [],
                    action   => $action,
                });
            }
        } else {
            my $action = {
                app => $app,
                rm  => $rm,
            };
            $dispatch_table->{$host} ||= [];
            push @{$dispatch_table->{$host}}, $entry->{path}, $action;
            $uri_table_entry ||= _build_uri_table_entry({
                %$entry,
                protocol => $proto,
                host     => $host,
                path     => $entry->{path},
                query    => $entry->{query} || [],
                action   => $action,
            });
        }
        $uri_table_entry->{build_uri} = $entry->{build_uri} || undef;
        $uri_table->{"$app/$rm"} = $uri_table_entry;
        unless ($app_init_map{$app}) {
            $app_init_map{$app} = 1;
            no strict 'refs';
            my $self_klass = ref($self) || $self;
            $app->add_callback(
                'prerun',
                sub {
                    my $app = shift;
                    _setup_runmodes($app, $self_klass);
                },
            );
            *{"${app}::_uri_mapping"} = sub {
                _uri_mapping_of($self_klass, $app, $_[1]);
            };
        }
    };
}

sub dispatch_args {
    my $self = shift;
    my $dispatch_table = ($dispatch_table{ref($self) || $self} ||= {});
    
    return {
        prefix => '',
        table  => $dispatch_table->{CGI::virtual_host()}
            || $dispatch_table->{'*'}
                || {},
    };
}

*CGI::Application::all_param = sub {
    my $app = shift;
    
    if (@_ == 1) {
        my $n = shift;
        my $v = $app->param($n);
        return $v
            if defined $v && $v ne '';
        return $app->query->param($n);
    }
    
    $app->param(@_);
};

*CGI::Application::uri_mapping = sub {
    my $app = shift;
    my $mapping;
    
    eval {
        $mapping = $app->_uri_mapping(@_);
    };
    die "no mapping for $app, did you register the class?\n"
        unless $mapping;
    
    $mapping;
};

*CGI::Application::build_uri = sub {
    my ($app, $args) = @_;
    my $rm = $args->{rm} || undef
        if ref($args) eq 'HASH';
    
    _build_uri($app->uri_mapping($rm), $args);
};

*CGI::Application::validate_uri = sub {
    my ($app, $args) = @_;
    my $mapping = $app->uri_mapping($args->{rm} || undef);
    
    return _validate_uri($mapping, $app, $args->{extra} || []);
};

*CGI::Application::normalize_uri = sub {
    my ($app, $args) = @_;
    my $mapping = $app->uri_mapping($args->{rm} || undef);
    
    return
        if _validate_uri($mapping, $app, $args->{extra} || [])
            == URI_IS_PERMALINK;
    
    return $app->redirect(_build_uri(
        $mapping,
        {
            rm     => $args->{rm} || undef,
            params => [
                $app,
            ],
        },
    ));
};

sub _run_modes_of {
    my ($self, $app) = @_;
    my $dispatch_table = ($dispatch_table{ref($self) || $self} ||= []);
    
    $dispatch_table = $dispatch_table->{CGI::virtual_host()}
        || $dispatch_table->{'*'};
    
    my @rm = uniq map {
        $_->{rm}
    } grep {
        ref($_) && $_->{app} eq $app
    } @$dispatch_table;
    
    \@rm;
}

sub _uri_mapping_of {
    my ($self, $app, $rm) = @_;
    
    $rm ||= _pkg2rm($app);
    
    my $mapping = ($uri_table{ref($self) || $self} ||= {})->{"$app/$rm"}
        or die "mapping for $app/$rm not found, did you register $app?\n";
    
    $mapping;
}

sub _build_uri {
    my ($prototype, $args) = @_;
    
    $args = { params => $args }
        if ref($args) eq 'ARRAY';
    my $params = $args->{params} || [];
    
    ($prototype->{build_uri} || \&_default_build_uri)->(
        {
            %$prototype,
            protocol => $args->{protocol} || $prototype->{protocol},
        },
        sub {
            my $n = shift;
            foreach my $h (@$params) {
                if (ref $h eq 'HASH') {
                    return ($h->{$n}) if exists $h->{$n};
                } else {
                    my @v;
                    local $@ = undef;
                    eval {
                        @v = $h->all_param($n);
                    };
                    @v = $h->param($n)
                        if $@;
                    return wantarray ? @v : $v[0]
                        if @v;
                }
            }
            ();
        });
}

sub _default_build_uri {
    my ($prototype, $get_param) = @_;
    
    # determine hostport
    my $host = $prototype->{host};
    $host = CGI::virtual_host() if $host eq '*';
    # build path
    my @path;
    foreach my $p (@{$prototype->{path_array}}) {
        if ($p =~ m|^:(.*?)(\??)$|) {
            my ($n, $optional) = ($1, $2);
            my @v = $get_param->($n);
            unless (@v) {
                die "required parameter '$n' is missing\n"
                    unless $optional;
                last;
            }
            die "more than one value assigned for path parameter: '$n'\n"
                if @v != 1;
            push @path, @v;
        } else {
            push @path, $p;
        }
    }
    # build query params
    my @qp;
    foreach my $p (@{$prototype->{query}}) {
        my @v = $get_param->($p->{name});
        foreach my $v (@v) {
            if ($p->{omit}) {
                next if $v eq $p->{omit};
            }
            push @qp, "$p->{name}=" . uri_escape($v);
        }
    }
    # build and return
    my $uri = "$prototype->{protocol}://$host/" . join('/', @path);
    $uri .= '?' . join('&', @qp)
        if @qp;
    $uri;
}

sub _validate_uri {
    my ($mapping, $app, $extra) = @_;
    my $param_map = $mapping->{param_map};
    my $query = $app->query;
    my $meth = $query->request_method || 'GET';
    $extra = { map { $_ => 1 } @$extra };
    
    return URI_IS_PERMALINK
        unless $meth eq 'GET' || $meth eq 'HEAD';
    
    my $max_rank = 0;
    foreach my $n (
        map { (split '=', $_, 2)[0] } split(/[&;]/, $query->query_string)
    ) {
        if (my $ref = $param_map->{$n}) {
            return URI_PATH_PARAM_IN_QUERY
                if $ref->{rank} < 0;
            return URI_PARAM_NOT_IN_ORDER
                if $ref->{rank} < $max_rank;
            if (my $omit = $ref->{omit}) {
                foreach my $v ($query->param($n)) {
                    return URI_OMITTABLE_PARAM
                        if $v eq $omit;
                }
            }
            $max_rank = $ref->{rank};
        } else {
            return URI_UNKNOWN_PARAM
                unless $extra->{$n};
        }
    }
    
    URI_IS_PERMALINK;
}

sub _setup_runmodes {
    my ($app, $mapping) = @_;
    $app->run_modes(_run_modes_of($mapping, ref $app));
}

sub _build_uri_table_entry {
    my $table = shift;
    
    # setup path_array
    my $p = $table->{path};
    $p =~ s|^/?(.*)/?$|$1|;
    $table->{path_array} = [ split '/', $p ];
    
    # normalize query array
    $table->{query} ||= [];
    foreach my $p (@{$table->{query}}) {
        $p = {
            name => $p,
        } unless ref $p;
    }
    
    # setup param_map
    $table->{param_map} = {};
    for (my $i = 0; $i < @{$table->{query}}; $i++) {
        $table->{param_map}->{$table->{query}->[$i]->{name}} = {
            rank => $i + 1,
            omit => $table->{query}->[$i]->{omit} || undef,
        };
    }
    foreach my $e (@{$table->{path_array}}) {
        if ($e =~ /^:(.*?)\??$/) {
            $table->{param_map}->{$1} = {
                rank => -1,
            };
        }
    }
    
    # set build_uri
    $table->{build_uri} ||= \&_default_build_uri;
    
    $table;
}

sub _pkg2rm {
    my $pkg = shift;
    
    $pkg =~ m|[^:]*$|;
    my $rm = $&;
    $rm =~ s/([a-z]?)([A-Z])/($1 ? "$1_" : '') . lc($2)/ego;
    
    $rm;
}

1;

__END__

=head1 NAME

CGI::Application::URIMapping - A dispatcher and permalink builder

=head1 SYNOPSIS

  # your.cgi
  use MyApp::URIMapping;
  
  MyApp::URIMapping->dispatch();
  
  
  package MyApp::URIMapping;
  
  use base qw/CGI::Application::URIMapping/;
  use MyApp::Page1;
  use MyApp::Page2;
  
  
  package MyApp::Page1;
  
  use base qw/CGI::Application/;
  
  # registers subroutine ``page1'' for given path
  MyApp::URIMapping->register({
    path  => 'page1/:p1/:p2?',
    query => [ qw/q1 q2 q3/ ]
  });
  
  sub page1 {
    my $self = shift;
    
    # if URI is not in permalink style, redirect
    return if $self->normalize_uri;
    
    ...
  }
  
  # build_uri, generates: http://host/page1/p-one?q1=q-one&q3=q-three
  my $permalink = MyApp::Page1->build_uri([{
    p1 => 'p-one',
    q1 => 'q-one',
    q3 => 'q-three',
  }]);

=head1 DESCRIPTION

C<CGI::Application::URIMapping> is a dispatcher / permalink builder for CGI::Application.  It is implemented as a wrapper of L<CGI::Application::Dispatch>.

As can be seen in the synopsis, C<CGI::Application::URIMapping> is designed to be used as a base class for defining a mapping for each L<CGI::Application>-based web application.

=head1 METHODS

=head2 register

The class method assigns a runmode to more than one paths.  There are various ways of calling the function.  Runmodes of the registered packages are automatically setup, and C<Build_uri> method will be added to the packages.

  MyApp::URIMapping->register('path');
  MyApp::URIMapping->register('path/:required_param/:optional1?/:optional2?');
  
  MyApp::URIMapping->register({
    path  => 'path',
    query => [ qw/n1 n2/ ],
  });
  
  MyApp::URIMapping->register({
    rm       => 'run_mode',
    path     => 'path',
    protocol => 'https',
    host     => 'myapp.example.com',
  });
  
  MyApp::URIMapping->register({
    app  => 'MyApp::Page2',
    rm   => 'run_mode',
    path => [
      'path1/:p1/:p2?/:p3?' => {
        query => [ qw/n1 n2/ ],
      },
      'path2' => {
        query => [ qw/p1 p2 p3 n1 n2/ ],
      },
    ],
  });

The attributes recognized by the function is as follows.

=head3 app

Name of the package in which the run mode is defined.  If ommited, name of the current package is being used.

=head3 rm

Name of the runmode.  If omitted, basename of the first C<path> attribute is being used.

=head3 path

A path (or an array of paths) to be registered for the runmode.  The syntax of the paths are equivalent to that of L<CGI::Application::Dispatch> with the following exceptions.  The attributes C<app> and C<rm> need not be defined for each path, since they are already specified.  C<Procotol>, C<host>, C<query> attributes are accepted.

=head3 protocol

Specifies protocol to be used for given runmode when building a permalink.

=head3 host

Limits the registration to given host if specified.

=head3 query

List of parameters to be marshallised when building a premalink.  The parameters will be marshallized in the order of the array.

=head2 all_param

The function is an accessor / mutator for uniformly handling path parameters and query parameters.

  my $value = $cgi_app->all_param($name);   # read paramater
  
  $cgi_app->all_param($name, $value);       # set parameter

The setter first tries to read from $cgi_app->param($name), and then $cgi_app->query->param($name).  The getter sets the value to $cgi_app->param($name, $value).

=head2 build_uri

The function is automatically setup for the registered CGI::Application packages.

  MyApp::Page1->build_uri();      # builds default URI for page1
  
  MyApp::Page1->build_uri({       # explicitly set runmode
    rm  => 'page1',
  });
  
  MyApp::Page1->build_uri({       # specify parameters and protocol
    params   => [{
      p1 => 'p-one',
      n1 => 'n-one',
    }],
    procotol => 'https',
  });
  
  MyApp::Page1->build_uri({       # just override 'p1'
    params => [
      {
        p1 => 'p-one',
      },
      $cgi_app,
      $cgi_app->query,
    ],
  });

If called with a hash as the only argument, the function recognizes the following attributes.  If called with an array as the only argument, the array is considered as the params attribute.

=head3 rm

Name of the runmode.  If omitted, the last portion of the package name will be used uncamelized.

=head3 protocol

Protocol.

=head3 params

An array of hashes or object containing values to be filled in when building the URI.  The parameters are searched from the begging of the array to the end, and the first-found value is used.  If the array element is an object, its C<param> method is called in order to obtain the variable.

=head2 validate_uri

The function, which is automaticaly setup as a instance method of CGI::Application, checks whether the current URI is conforms to the registered format.

  $cgi_app->validate_uri();
  
  $cgi_app->validate_uri({        # explicitly specify runmode
     rm => 'page1',
  };
  
  $cgi_app->validate_uri({        # set extra query parameters to be allowed
     extra => [ qw/__extra1 __extra2/ ],
  });

The function accepts following attributes.

=head3 rm

Runmode.  If omitted, uncamelized basename of the package is used.

=head3 extra

Array of query args to be ignored while validating the parameters received.

The return value of the function is one of the following constants.

=head3 URI_IS_PERMALINK

Current URI conforms the registered format.

=head3 URI_UNKNOWN_PARAM

Current URI contains an unknown query parameter.

=head3 URI_PATH_PARAM_IN_QUERY

A parameter expected in path_info is being received as a query parameter.

=head3 URI_OMITTABLE_PARAM

A parameter that should be omitted (since it contains the default value) exists.

The constants are importable by specifying C<:constants> attribute.

  use CGI::Application::URIMapping qw/:constants/;

=head1 AUTHOR

Copyright (c) 2007 Cybozu Labs, Inc.  All rights reserved.

written by Kazuho Oku E<lt>kazuhooku@gmail.comE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under th
e same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
