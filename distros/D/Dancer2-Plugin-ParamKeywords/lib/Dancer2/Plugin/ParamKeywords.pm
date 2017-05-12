use 5.16.0;
use strict;
use warnings;

package Dancer2::Plugin::ParamKeywords;
use Dancer2::Plugin;

our $VERSION = 'v0.1.5';

foreach my $source ( qw( route query body ) ) {
    register "$source\_param" => sub {
        my ($dsl, $param)  = @_;
        $dsl->app->request->params($source)->{$param};
    };
    
    register "$source\_params" => sub {
        my $dsl  = shift;
        $dsl->app->request->params($source); 
    };
}

register munged_params => sub {
     my $dsl = shift;
     my $conf = plugin_setting->{munge_precedence};
     die 'Please configure the plugin settings for ParamKeywords to use munged_params'
       unless ref($conf) eq 'ARRAY';

     my %params = map { $dsl->app->request->params($_) } reverse @$conf;
     wantarray ? %params : \%params;
};

register munged_param => sub {
     my ($dsl, $param) = @_;
     my $conf = plugin_setting->{munge_precedence};
     die 'Please configure the plugin settings for ParamKeywords to use munged_param'
       unless ref($conf) eq 'ARRAY';

     my %params = map { $dsl->app->request->params($_) } reverse @$conf;
     $params{$param};
};

register_plugin for_versions => [ 2 ] ;

1;

# ABSTRACT: Sugar for the params() keyword (DEPRECATED)
# PODNAME: Dancer2::Plugin::ParamKeywords

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::ParamKeywords - Sugar for the params() keyword (DEPRECATED)

=head1 VERSION

version v0.1.5

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::ParamKeywords;

    any '/:some_named_parameter' => sub {
        my $route_param = route_param('some_named_parameter');
        my $get_param   = query_param('some_named_parameter');
        my $post_param  = body_param('some_named_parameter');
    };

=head1 DESCRIPTION

This module is deprecated with the release of L<Dancer2>'s
L<Hash::MultiValue> parameter keywords: route_parameters,
query_parameters, and body_parameters.  Use this plugin
only if you are unable to upgrade your installation of
L<Dancer2>.

The default L<Dancer2::Core::Request params
accessor|Dancer2::Core::Request/"params($source)">
munges parameters in the following precedence from
highest to lowest: C<POST> parameters, named route parameters,
and C<GET> parameters.

Consider the following route:

    post '/people/:person_id' => sub {
        my $person_id = param('person_id');
        ...
        # Perform some operation using $person_id as a key
    };

In the above example, if the browser/client sends a parameter
C<person_id> with a value of 2 in the C<POST> body to route C</people/1>,
C<$person_id> will equal 2 while still matching the route C</people/1>.

This plugin provides keywords that wrap around C<params($source)>
for convenience to fetch parameter values from specific sources.

=head2 CONFIGURATION

The L</munged_params> and L</munged_param> keywords require you to configure an order of
precedence by which to prefer parameter sources.  Please see 
L<Dancer2::Core::Request params accessor|Dancer2::Core::Request/"params($source)">
for a list of valid sources.

    # In config.yml
    plugins:
      ParamKeywords:
        munge_precedence:
          - route
          - body
          - query

If you won't be using the munged_* keywords, you don't need to bother configuring
this plugin.

=head1 KEYWORDS

=head2 munged_param(Str)

Returns the value of a given parameter from the L</munged_params> hash.

=head2 munged_params

Returns a hash in list context or a hash reference in scalar context of
parameters munged according to the precedence provided in the configuration
file (from highest to lowest).

=head2 query_param(Str)

Returns the value supplied for a given parameter in the query string.

=head2 query_params

Returns the arguments and values supplied by query string. Returns a hash in list context or a hasref in scalar context.

=head2 body_param(Str)

Returns the value supplied for a given parameter in the C<POST> arguments.

=head2 body_params

Returns arguments and values supplied by a C<POST> request.  Returns a hash in list context or a hasref in scalar context.

=head2 route_param(Str)

Returns the value supplied for a given named parameter in the route.

=head2 route_params

Returns the arguments and values suppled by the route. Returns a hash in list context or a hasref in scalar context.

=head1 VERSIONING

This module follows semantic versioning (L<http://www.semver.org>).

=head1 AUTHOR

Chris Tijerina

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Tijerina.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
