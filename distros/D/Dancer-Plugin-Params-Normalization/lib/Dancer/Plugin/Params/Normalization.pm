#
# This file is part of Dancer-Plugin-Params-Normalization
#
# This software is copyright (c) 2011 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer::Plugin::Params::Normalization;
{
  $Dancer::Plugin::Params::Normalization::VERSION = '0.52';
}

# ABSTRACT: A plugin for normalizing query parameters in Dancer

use Dancer ':syntax';
use Dancer::Plugin;

my $conf = plugin_setting;

# method that does nothing. It's optimized to nothing at compile time
my $void = sub(){};

# set the params_filter
my $params_filter = sub () { 1; };
if (defined $conf->{params_filter}) {
    my $re = $conf->{params_filter};
    $params_filter = sub {
        return scalar($_[0] =~ /$re/) };
}

# method that loops on a hashref and apply a given method on its keys
my $apply_on_keys = sub {
    my ($h, $func) = @_;
    my $new_h = {};
    while (my ($k, $v) = each (%$h)) {
        my $new_k = $params_filter->($k) ? $func->($k) : $k;
        exists $new_h->{$new_k} && ! ($conf->{no_conflict_warn} || 0)
          and warn "paramater names conflict while doing normalization of parameters '$k' : it produces '$new_k', which alreay exists.";
        $new_h->{$new_k} = $v;
    }
    return $new_h;
};


# default normalization method is passthrough (do nothing)
my $normalization_fonction = $void;
if (defined $conf->{method} && $conf->{method} ne 'passthrough') {
	my $method;
    if      ($conf->{method} eq 'lowercase') {
        $method = sub { my ($h) = @_; $apply_on_keys->($h, sub { lc($_[0]) } ) };
    } elsif ($conf->{method} eq 'uppercase') {
        $method = sub { my ($h) = @_; $apply_on_keys->($h, sub { uc($_[0]) } ) };
    } elsif ($conf->{method} eq 'ucfirst') {
        $method = sub { my ($h) = @_; $apply_on_keys->($h, sub { ucfirst($_[0]) } ) };
    } else {
        my $class = $conf->{method};
        my $class_name = $class;
        $class_name =~ s!::|'!/!g;
        $class_name .= '.pm';
        if ( ! $class->can('new') ) {
            eval { require $class_name };
            $@ and die "error while requiring custom normalization class '$class' : $@";
        }
        my $abstract_classname = __PACKAGE__ . '::Abstract';
        $class->isa(__PACKAGE__ . '::Abstract')
          or die "custom normalization class '$class' doesn't inherit from '$abstract_classname'";
        my $instance = $class->new();
        # using a custom normalization is incompatible with params filters
        defined $conf->{params_filter}
          and die "your configuration contains a 'params_filter' fields, and a custom 'method' normalization class name. The two fields are incompatible";
        # todo : use *method = \&{$class->normalize} or somethin'
        $method = sub { $instance->normalize($_[0]) };
    }

    my $params_types = $conf->{params_types};
    # default value
    defined $params_types
      or $params_types = [ qw(query body) ];
    ref $params_types eq 'ARRAY'
      or die "configuration field 'params_types' should be an array";

    my %params_types = map { $_ => 1 } @$params_types;
    my $params_type_query = delete $params_types{query};
    my $params_type_body = delete $params_types{body};
    my $params_type_route = delete $params_types{route};
    keys %params_types
      and die "your configuration contains '" . join(', ', keys %params_types) .
        "' as 'params_types' field(s), but only these are allowed : 'query', 'body', 'route'";

    $normalization_fonction = sub { 
        my ($new_query_params,
            $new_body_params,
            $new_route_params) = map { scalar(params($_)) } qw(query body route);
        $params_type_query and $new_query_params = $method->($new_query_params);
        $params_type_body and $new_body_params = $method->($new_body_params);
        $params_type_route and $new_route_params = $method->($new_route_params);

        request->{params} = {};

        request->_set_query_params($new_query_params);
        request->_set_body_params($new_body_params);
        request->_set_route_params($new_route_params);
    };
}

if (defined $conf->{general_rule}) {
    $conf->{general_rule} =~ /^always$|^ondemand$/
      or die 'configuration field general_rule must be one of : always, ondemand';      
    if ($conf->{general_rule} eq 'ondemand') {
        register normalize => sub{ $normalization_fonction->() };
    } else {
        hook before => $normalization_fonction;
    }
} else {
    hook before => $normalization_fonction;
}

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::Params::Normalization - A plugin for normalizing query parameters in Dancer

=head1 VERSION

version 0.52

=head1 DESCRIPTION

This plugin helps you normalize the query parameters in Dancer.

=head1 SYNOPSYS

In configuration file :

  plugins:
    Params::Normalization:
      method: lowercase

In your Dancer App :

  package MyWebService;

  use Dancer;
  use Dancer::Plugin::Params::Normalization;

  get '/hello' => sub {
      'Hello ' . params->{name};
  };

Requests 

  # This will work, as NAME will be lowercased to name
  curl http://mywebservice/test?NAME=John

=head1 CONFIGURATION

The behaviour of this plugin is primarily setup in the configuration file, in
your main config.yml or environment config file.

  # Example 1 : always lowercase all parameters
  plugins:
    Params::Normalization:
      method: lowercase

  # Example 2 : always uppercase all parameters
  plugins:
    Params::Normalization:
      method: uppercase

  # Example 3 : on-demand uppercase parameters that starts with 'a'
  plugins:
    Params::Normalization:
      general_rule: ondemand
      method: uppercase
      params_filter: ^[aA]

Here is a list of configuration fields:

=head2 general_rule

This field specifies if the normalization should always happen, or on demand.

Value can be of:

=over

=item always

Parameters will be normalized behind the scene, automatically.

=item ondemand

Parameters are not normalized by default. The code in the route definition
needs to call normalize_params to have the parameters normalized

=back

B<Default value>: C<always>

=head2 method

This field specifies what kind of normalization to do.

Value can be of:

=over

=item lowercase

parameters names are lowercased

=item uppercase

parameters names are uppercased

=item ucfirst

parameters names are ucfirst'ed

=item Custom::Class::Name

Used to execute a custom normalization method.

The given class should inherit
L<Dancer::Plugin::Params::Normalization::Abstract> and implement the method
C<normalize>. this method takes in argument a hashref of the parameters, and
returns a hashrefs of the normalized parameters. It can have an C<init> method
if it requires initialization.

As an example, see C<Dancer::Plugin::Params::Normalization::Trim>, contributed
by Sam Batschelet, and part of this distribution.

Using a custom normalization is incompatible with C<params_filter> (see below).

=item passthrough

Doesn't do any normalization. Useful to disable the normalization without to
change the code

=back

B<Default value>: C<passthrough>

=head2 params_types

Optional, used to specify on which parameters types the normalization should
apply. The value is an array, that can contain any combination of these
strings:

=over

=item query

If present in the array, the parameters from the query string will be normalized

=item body

If present in the array, the parameters from the request's body will be normalized

=item route

If present in the array, the parameters from the route definition will be normalized

=back

B<Default value>: [ 'query', 'body']

=head2 params_filter

Optional, used to filters which parameters the normalization should apply to.

The value is a regexp string that will be evaluated against the parameter names.

=head2 no_conflict_warn

Optional, if set to a true value, the plugin won't issue a warning when parameters name
conflict happens. See L<PARAMETERS NAMES CONFLICT>.

=head1 KEYWORDS

=head2 normalize

The general usage of this plugin is to enable normalization automatically in the configuration.

However, If the configuration field C<general_rule> is set to C<ondemand>, then
the normalization doesn't happen automatically. The C<normalize> keyword can
then be used to normalize the parameters on demand.

All you have to do is add 

  normalize;

to your route code

=head1 PARAMETERS NAMES CONFLICT

if two normalized parameters names clash, a warning is issued. Example, if
while lowercasing parameters the route receives two params : C<param> and
C<Param>, they will be both normalized to C<param>, which leads to a conflict.
You can avoid the warning being issued by adding the configuration key
C<no_conflict_warn> to a true value.

=head1 SEE ALSO

L<Dancer>

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
