package Data::DynamicValidator;
{
  $Data::DynamicValidator::VERSION = '0.03';
}
#ABSTRACT: JPointer-like and Perl union for flexible perl data structures validation

use strict;
use warnings;

use Carp;
use Devel::LexAlias qw(lexalias);
use PadWalker qw(peek_sub);
use Scalar::Util qw/looks_like_number/;
use Storable qw(dclone);

use aliased qw/Data::DynamicValidator::Error/;
use aliased qw/Data::DynamicValidator::Filter/;
use aliased qw/Data::DynamicValidator::Label/;
use aliased qw/Data::DynamicValidator::Path/;

use overload
    fallback => 1,
    '&{}' => sub {
        my $self = shift;
        return sub { $self->validate(@_) }
    };

use parent qw/Exporter/;
our @EXPORT_OK = qw/validator/;

use constant DEBUG => $ENV{DATA_DYNAMICVALIDATOR_DEBUG} || 0;








sub validator {
    return Data::DynamicValidator->new(@_);
}

sub new {
    my ($class, $data) = @_;
    my $self = {
        _data   => $data,
        _errors => [],
        _bases  => [],
    };
    return bless $self => $class;
}


sub validate {
    my ($self, %args) = @_;

    my $on      = $args{on     };
    my $should  = $args{should };
    my $because = $args{because};
    my $each    = $args{each   };

    croak("Wrong arguments: 'on', 'should', 'because' should be specified")
        if(!$on || !$should || !$because);

    warn "-- validating : $on \n" if DEBUG;

    my $errors = $self->{_errors};
    my $selection_results;
    if ( !@$errors ) {
        my $success;
        my $current_base = $self->current_base;
        my $selector = $self->_rebase_selector($on);
        ($success, $selection_results) = $self->_apply($selector, $should);
        $self->report_error($because, $selector)
            unless $success;
    }
    # OK, now going to child rules if there is no errors
    if ( !@$errors && $each  ) {
        warn "-- no errors, will check children\n" if DEBUG;
        $self->_validate_children($selection_results, $each);
    }

    return $self;
}


sub report_error {
    my ($self, $reason, $path) = @_;
    $path //= $self->{_current_path};
    croak "Can't report error unless path is undefined"
        unless defined $path;
    push @{ $self->{_errors} }, Error->new($reason, $path);
}


sub is_valid { @{ $_[0]->{_errors} } == 0; }



sub errors { $_[0]->{_errors} }


sub rebase {
    my ($self, $expandable_route, $rule) = @_;
    my $current_base = $self->current_base;
    my $selector = $self->_rebase_selector($expandable_route);
    my $scenario = $self->_select($selector);
    my $number_of_routes = @{ $scenario->{routes} };
    carp "The route '$expandable_route' is ambigious for rebasing (should be unique)"
        if $number_of_routes > 1;

    return $self if $number_of_routes == 0;

    push @{ $self->{_bases} }, $scenario->{routes}->[0];
    $rule->($self);
    pop @{ $self->{_bases} };
    return $self;
}


sub current_base {
    my $bases = $_[0]->{_bases};
    return undef unless @$bases;
    return $bases->[-1];
}

### private/implementation methods

sub _rebase_selector {
    my ($self, $selector) = @_;
    my $current_base = $self->current_base;
    my $add_base = $current_base && $selector !~ /^\/{2,}/;
    my $rebased = $add_base ? $current_base . $selector : $selector;
    warn "-- Rebasing selector $selector to $rebased \n" if DEBUG;
    return $rebased;
}

sub _validate_children {
    my ($self, $selection_results, $each) = @_;
    my ($routes, $values) = @{$selection_results}{qw/routes values/};
    my $errors = $self->{_errors};
    my $data = $self->{_data};
    for my $i (0 .. @$routes-1) {
        my $route = $routes->[$i];
        push @{ $self->{_bases} }, $route;
        my $value = $values->[$i];
        my $label_for = { map { $_ => 1 } ($route->labels) };
        # prepare context
        my $pad = peek_sub($each);
        while (my ($var, $ref) = each %$pad) {
            my $var_name = substr($var, 1); # chomp sigil
            next unless exists $label_for->{$var_name};
            my $label_obj = Label->new($var_name, $route, $data);
            lexalias($each, $var, \$label_obj);
        }
        # call
        $self->{_current_path} = $route;
        $each->($self, local $_ = Label->new('_', $route, $data));
        pop @{ $self->{_bases} };
        last if(@$errors);
    }
}


# Takes path-like expandable expression and returns hashref of path with corresponding
# values from data, e.g.

#  validator({ a => [5,'z']})->_select('/a/*');
#  # will return
#  # {
#  #   routes => ['/a/0', '/a/1'],
#  #   values => [5, z],
#  # }

# Actualy routes are presented by Path objects.

sub _select {
    my ($self, $expession) = @_;
    my $data = $self->{_data};
    my $routes = $self->_expand_routes($expession);
    my $values = [ map { $_->value($data) } @$routes ];
    return {
        routes => $routes,
        values => $values,
    };
}



# Takes xpath-like expandable expression and sorted array of exapnded path e.g.
#  validator({ a => [5,'z']})->_expand_routes('/a/*');
#  # will return [ '/a/0', '/a/1' ]
#  validator({ a => [5,'z']})->_expand_routes('/a');
#  # will return [ '/a' ]
#  validator({ a => { b => [5,'z'], c => ['y']} })->_expand_routes('/a/*/*');
#  # will return [ '/a/b/0', '/a/b/1', '/a/c/0' ]

sub _expand_routes {
    my ($self, $expression) = @_;
    warn "-- Expanding routes for $expression\n" if DEBUG;
    # striping leading slashes
    $expression =~ s/\/{2,}/\//;
    my @routes = ( Path->new($expression) );
    my $result = [];
    while (@routes) {
        my $route = shift(@routes);
        my $current = $self->{_data};
        my $elements = $route->components;
        my $i;
        my $can_be_accessed = 0;
        for ($i = 0; $i < @$elements; $i++) {
            $can_be_accessed = 0;
            my $element = $elements->[$i];
            # no futher examination if current value is undefined
            last unless defined($current);
            next if($element eq '');
            my $filter;
            ($element, $filter) = _filter($element);
            my $type = ref($current);
            my $generator;
            my $advancer;
            if ($element eq '*') {
                if ($type eq 'HASH') {
                    my @keys = keys %$current;
                    my $idx = 0;
                    $generator = sub {
                        while($idx < @keys) {
                            my $key = $keys[$idx++];
                            my $match = $filter->($current->{$key}, {key => $key});
                            return $key if($match);
                        }
                        return undef;
                    };
                } elsif ($type eq 'ARRAY') {
                    my $idx = 0;
                    $generator = sub {
                        while($idx < @$current) {
                            my $index = $idx++;
                            my $match = $filter->($current->[$index], {index => $index});
                            return $index if($match);
                        }
                        return undef;
                    };
                }
            }elsif ($type eq 'HASH' && exists $current->{$element}) {
                $advancer = sub { $current->{$element} };
            }elsif ($type eq 'ARRAY' && looks_like_number($element)
                && (
                    ($element >= 0 && $element < @$current)
                    || ($element < 0 && abs($element) <= @$current)
                   )
                ){
                $advancer = sub { $current->[$element] };
            }
            if ($generator) {
                while ( defined( my $new_element = $generator->()) ) {
                    my $new_path = dclone($route);
                    $new_path->components->[$i] = $new_element;
                    push @routes, $new_path;
                }
                $current = undef;
                last;
            }
            if ($advancer) {
                $current = $advancer->();
                $can_be_accessed = 1;
                next;
            }
            # the current element isn't hash nor array
            # we can't traverse further, because there is more
            # else current path
            $current = undef;
            $can_be_accessed = 0;
        }
        my $do_expansion = defined $current
            || ($can_be_accessed && $i == @$elements);
        warn "-- Expanded route : $route \n" if(DEBUG && $do_expansion);
        push @$result, $route if($do_expansion);
    }
    return [ sort @$result ];
}

sub _filter {
    my $element = shift;
    my $filter;
    my $condition_re = qr/(.+?)(\[(.+)\])/;
    my @parts = $element =~ /$condition_re/;
    if (@parts == 3 && defined($parts[2])) {
        $element = $parts[0];
        my $condition = $parts[2];
        $filter = Filter->new($condition);
    } else {
        $filter = sub { 1 }; # always true
    }
    return ($element, $filter);
}


# Takes the expandable expression and validation closure, then
# expands it, and applies the closure for every data piese,
# obtainted from expansion.

# Returns the list of success validation mark and the hash
# of details (obtained via _select).

sub _apply {
    my ($self, $on, $should) = @_;
    my $selection_results = $self->_select($on);
    my $values = $selection_results->{values};
    my $result = $values && @$values && $should->( @$values );
    return ($result, $selection_results);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DynamicValidator - JPointer-like and Perl union for flexible perl data structures validation

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 my $my_complex_config = {
    features => [
        "a/f",
        "application/feature1",
        "application/feature2",
    ],
    service_points => {
        localhost => {
            "a/f" => { job_slots => 3, },
            "application/feature1" => { job_slots => 5 },
            "application/feature2" => { job_slots => 5 },
        },
        "127.0.0.1" => {
            "application/feature2" => { job_slots => 5 },
        },
    },
    mojolicious => {
    	hypnotoad => {
            pid_file => '/tmp/hypnotoad-ng.pid',
            listen  => [ 'http://localhost:3000' ],
        },
    },
 };

 use Data::DynamicValidator qw/validator/;
 use Net::hostent;

 my $errors = validator($cfg)->(
   on      => '/features/*',
   should  => sub { @_ > 0 },
   because => "at least one feature should be defined",
   each    => sub {
     my $f = $_->();
     shift->(
       on      => "//service_points/*/`$f`/job_slots",
       should  => sub { defined($_[0]) && $_[0] > 0 },
       because => "at least 1 service point should be defined for feature '$f'",
     )
   }
 )->(
   on      => '/service_points/sp:*',
   should  => sub { @_ > 0 },
   because => "at least one service point should be defined",
   each    => sub {
     my $sp;
     shift->report_error("SP '$sp' isn't resolvable")
       unless gethost($sp);
   }
 )->(
  on      => '/service_points/sp:*/f:*',
  should  => sub { @_ > 0 },
  because => "at least one feature under service point should be defined",
  each    => sub {
    my ($sp, $f);
    shift->(
      on      => "//features/`*[value eq '$f']`",
      should  => sub { 1 },
      because => "Feature '$f' of service point '$sp' should be decrlared in top-level features list",
    )
  },
  })->rebase('/mojolicious/hypnotoad' => sub {
    shift->(
      on      => '/pid_file',
      should  => sub { @_ == 1 },
      because => "hypnotoad pid_file should be defined",
    )->(
      on      => '/listen/*',
      should  => sub { @_ > 0 },
      because => "hypnotoad listening interfaces defined",
    );
  })->errors;

 print "all OK\n"
  unless(@$errors);

=head2 RATIONALE

There are complex data configurations, e.g. application configs. Not to
check them on applicaiton startup is B<wrong>, because of sudden
unexpected runtime errors can occur, which are not-so-pleasent to detect.
Write the code, that does full exhaustive checks, is B<boring>.

This module tries to offer to use DLS, that makes data validation fun
for developer yet understandable for the person, which provides the data.

=head1 DESCRIPTION

First of all, you should create Validator instance:

 use Data::DynamicValidator qw/validator/;

 my $data = { ports => [2222] };
 my $v = validator($data);

Then, actually do validation:

 $v->(
   on      => '/ports/*',
   should  => sub { @_ > 0 },
   because => 'At least one port should be defined at "ports" section',
 );

The C<on> parameter defines the data path, via JSON-pointer like expression;
the C<should> parameter provides the closure, which will check the values
gathered on via pointer. If the closure returns false, then the error will
be recorded, with description, provided by C<because> parameter.

To get the results of validation, you can call:

 $v->is_valid; # returns true, if there is no validation errors
 $v->errors;   # returns array reference, consisting of the met Errors

C<on>/C<should> parameters are convenient for validation of presense of
something, but they aren't so handy in checking of B<individual> values.
It should be mentioned, that C<should> closure, always takes an array of
the selected by C<on>, even if only one element has been selected.

To handle B<individual> values in more convenient way  the optional
C<each> parameter has been introduced.

 my $data = { ports => [2222, 3333] };
 $v->(
   on      => '/ports/*',
   should  => sub { @_ > 0 },
   because => 'At least one port should be defined at "ports" section',
   each    => sub {
     my $port = $_->();
     $v->report_error("All ports should be greater than 1000")
      unless $port > 1000;
   },
 );

So, C<report_error> could be used for custom errors reporting on current
path or current data value. The C<$_> is the an implicit alias or B<label>
to the last componenet of the current path, i.e. on our case the current
path in C<each> closure will be C</ports/0> and C</ports/1>, so the C<$_>
will be 0 and 1 respectively. To get the I<value> of the label, you should
"invoke" it, as showed previously. A label stringizes to the last data
path component, e.g. to "0" and "1" respectively.

The C<each> closure single argrument is the validator instance itself. The
previous example could be rewriten with explicit label like:

 $v->(
   on      => '/ports/port:*',
   should  => sub { @_ > 0 },
   because => 'At least one port should be defined at "ports" section',
   each    => sub {
     my $port;
     my $port_value = $port->();
     shift->report_error("All ports should be greater than 1000")
      unless $port_value > 1000;
   },
 );

Providing aliases for array indices may be not so handy as for keys
of hashes. Please note, that the label C<port> was previously "declated"
in C<on> rule, and only then "injected" into C<$port> variable in
C<each> closure.

Consider the following example:

 my $data = {
  ports => [2000, 3000],
  2000  => 'tcp',
  3000  => 'udp',
 };

Let's validate it. The validation rule sounds as: there is 'ports' section,
where at least one port > 1000 should be declated, and then the same port
should appear at top-level, and it should be either 'tcp' or 'upd' type.

 use List::MoreUtils qw/any/;

 my $errors = validator($data)->(
   on      => '/ports/*[value > 1000 ]',
   should  => sub { @_ > 0 },
   because => 'At least one port > 1000 should be defined in "ports" section',
   each    => sub {
     my $port = $_->();
     shift->(
       on      => "//*[key eq $port]",
       should  => sub { @_ == 1 && any { $_[0] eq $_ } (qw/tcp udp/)  },
       because => "The port $port should be declated at top-level as tcp or udp",
      )
   }
  )->errors;

As you probably noted, the the path expression contains two slashes at C<on> rule
inside C<each> rule. This is required to search data from the root, because
the current element is been set as B<base> before calling C<each>, so all expressions
inside C<each> are relative to the current element (aka base).

You can change the base explicit way via C<rebase> method:

 my $data = {
    mojolicious => {
    	hypnotoad => {
            pid_file => '/tmp/hypnotoad-ng.pid',
            listen  => [ 'http://localhost:3000' ],
        },
    },
 };

 $v->rebase('/mojolicious/hypnotoad' => sub {
    shift->(
      on      => '/pid_file',
      should  => sub { @_ == 1 },
      because => "hypnotoad pid_file should be defined",
    )->(
      on      => '/listen/*',
      should  => sub { @_ > 0 },
      because => "hypnotoad listening interfaces defined",
    );
 })->errors;

=head2 DATA PATH EXPRESSIONS

 my $data = [qw/a b c d e/];
 '/2'   # selects the 'c' value in $data array
 '/-1'  # selects the 'e' value in $data array

 $data = { abc => 123 };
 '/abc' # selects the '123' value in hashref under key 'abc'

 $data = {
   mojolicious => {
     hypnotoad => {
       pid_file => '/tmp/hypnotoad-ng.pid',
     }
   }
 };
 '/mojolicious/hypnotoad/pid_file'  # point to pid_file
 '//mojolicious/hypnotoad/pid_file' # point to pid_file (independently of current base)

 # Escaping by back-quotes sample
 $data => { "a/b" => { c => 5 } }
 '/`a/b`/c' # selects 5

 $data = {abc => [qw/a b/]};   # 1
 $data = {abc => { c => 'd'}}; # 2
 $data = {abc => 7};           # 3
 '/abc/*' # selects 'a' and 'b' in 1st case
          # the 'd' in 2nd case
          # the number 7 in 3rd case

 # Filtering capabilities samples:

 '/abc/*[size == 5]'    # filter array/hash by size
 '/abc/*[value eq "z"]' # filter array/hash by value equality
 '/abc/*[index > 5]'    # finter array by index
 '/abc/*[key =~ /def/]' # finter hash by key

=head2 DEBUGGING

You can set the DATA_DYNAMICVALIDATOR_DEBUG environment variable
to get some advanced diagnostics information printed to "STDERR".

 DATA_DYNAMICVALIDATOR_DEBUG=1

=head1 METHODS

=head2 validate

Performs validation based on C<on>, C<should>, C<because> and optional C<each>
parameters. Returns the validator itself (C<$self>), to allow further C<chain>
invocations. The validation will not be performed, if some errors already
have been detected.

It is recommended to use overloaded function call, instead of this method
call. (e.g. C<$validator->(...)> instead of C<$validato->validate(...)> )

=head2 report_error

The method is used for custom errors reporing. It is mainly usable in C<each>
closure.

 validator({ ports => [1000, 2000, 3000] })->(
   on      => '/ports/port:*',
   should  => sub { @_ > 0 },
   because => "At least one listening port should be defined",
   each    => sub {
     my $port;
     my $port_value = $port->();
     shift->report_error("Port value $port_value isn't acceptable, because < 1000")
       if($port_value < 1000);
   }
 );

=head2 is_valid

Checks, whether validator already has errors

=head2 errors

Returns internal array of errors

=head2 rebase

Temporaly sets the new base to the specified route, and invokes the closure
with the validator instance, i.e.

 $v->('/a' => $closure->($v))

If the data can't be found at the specified route, the C<closure> is not
invoked.

=head2 current_base

Returns the current base, which is set only inside C<rebase> call or C<each> closure.
Returns undef is there is no current base.

=head1 FUNCTIONS

=head2 validator

The enter point for DynamicValidator.

 my $errors = validator(...)->(
   on => "...",
   should => sub { ... },
   because => "...",
 )->errors;

=head1 RESOURCES

=over 4

=item * Data::DPath

L<https://metacpan.org/pod/Data::DPath>

=back

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
