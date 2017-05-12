package Class::CGI;

use warnings;
use strict;

use CGI::Simple 0.077;
use File::Spec::Functions 'catfile';
use HTML::Entities ();
use base 'CGI::Simple';

=head1 NAME

Class::CGI - Fetch objects from your CGI object

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';

=head1 SYNOPSIS

    use Class::CGI
        handlers => {
            customer_id => 'My::Customer::Handler'
        };

    my $cgi      = Class::CGI->new;
    my $customer = $cgi->param('customer_id');
    my $name     = $customer->name;
    my $email    = $cgi->param('email'); # behaves like normal

    if ( my %errors = $cgi->errors ) {
       # do error handling
    }

=head1 DESCRIPTION

For small CGI scripts, it's common to get a parameter, untaint it, pass it to
an object constructor and get the object back. This module would allow one to
to build C<Class::CGI> handler classes which take the parameter value,
automatically perform those steps and just return the object. Much grunt work
goes away and you can get back to merely I<pretending> to work.

=head1 ALPHA CODE

Note that this work is still under development.  It is not yet suitable for
production work as the interface may change.  Join the mailing list in the
L<SUPPORT> section if you would like to influence the future direction of this
project.

=head1 EXPORT

None.

=head1 BASIC USE

The simplest method of using C<Class::CGI> is to simply specify each form
parameter's handler class in the import list:

  use Class::CGI
    handlers => {
      customer => 'My::Customer::Handler',
      sales    => 'Sales::Loader'
    };

  my $cgi = Class::CGI->new;
  my $customer = $cgi->param('customer');
  my $email    = $cgi->param('email');
  # validate email
  $customer->email($email);
  $customer->save;

Note that there is no naming requirement for the handler classes and any form
parameter which does not have a handler class behaves just like a normal form
parameter.  Each handler class is expected to have a constructor named C<new>
which takes the B<raw> form value and returns an object corresponding to that
value.  All untainting and validation is expected to be dealt with by the
handler.  See L<WRITING HANDLERS>.

If you need different handlers for the same form parameter names (this is
common in persistent environments) you may omit the import list and use the
C<handlers> method.

=head1 LOADING THE HANDLERS

When the handlers are specified, either via the import list or the
C<handlers()> method, we verify that the handler exists and C<croak()> if it
is not.  However, we do not load the handler until the parameter for that
handler is fetched.  This allows us to not load unused handlers but still have
a semblance of safety that the handlers actually exist.

=head1 METHODS

=cut

my %class_for;

sub import {
    my $class = shift;

    my ( $config, $use_profiles );
    @_ = @_;    # this avoids the "modification of read-only value" error when
                # we assign undef the elements
    foreach my $i ( 0 .. $#_ ) {

        # we sometimes hit unitialized values due to "undef"ing array elements
        no warnings 'uninitialized';
        my ( $arg, $value ) = @_[ $i, $i + 1 ];
        if ( 'handlers' eq $arg ) {
            if ( !ref $value || 'HASH' ne ref $value ) {
                $class->_croak("No handlers defined");
            }
            while ( my ( $profile, $handler ) = each %$value ) {
                $class_for{$profile} = $handler;
            }
            @_[ $i, $i + 1 ] = ( undef, undef );
            next;
        }
        if ( 'use' eq $arg ) {
            $value = [$value] unless 'ARRAY' eq ref $value;
            $use_profiles = $value;
            @_[ $i, $i + 1 ] = ( undef, undef );
            next;
        }
        if ( 'profiles' eq $arg ) {
            if ( -f $value ) {
                require Config::Std;
                Config::Std->import;
                read_config( $value => \$config );
            }
            else {

                # eventually we may want to allow them to specify a config
                # class instead of a file.
                $class->_croak("Can't find profile file '$value'");
            }
            @_[ $i, $i + 1 ] = ( undef, undef );
        }
    }
    if ($config) {
        unless ($use_profiles) {
            while ( my ( $profile, $handler )
                = each %{ $config->{profiles} } )
            {

                # the "unless" is here because users may override profile
                # parameter specifications in their code, if they prefer
                $class_for{$profile} = $handler
                  unless exists $class_for{$profile};
            }
        }
        else {
            foreach my $profile (@$use_profiles) {
                my $handler = $config->{profiles}{$profile}
                  or
                  $class->_croak("No handler found for parameter '$profile'");
                $class_for{$profile} = $handler;
            }
        }
    }

    @_ = grep {defined} @_;
    $class->_verify_installed( values %class_for );
    goto &CGI::Simple::import;    # don't update the call stack
}

# testing hook
sub _clear_global_handlers {
    %class_for = ();
}

sub _verify_installed {
    my ( $proto, @modules ) = @_;
    my @not_installed_modules;
    foreach my $module (@modules) {
        _module_exists($module)
          or push @not_installed_modules => $module;
    }
    if (@not_installed_modules) {
        $proto->_croak(
            "The following modules are not installed: (@not_installed_modules)"
        );
    }
    return $proto;
}

##############################################################################

=head2 new

  my $cgi = Class::CGI->new(@args);

This method takes the same arguments (if any) as L<CGI::Simple>'s constructor.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{class_cgi_handlers}       = {};
    $self->{class_cgi_args}           = {};
    $self->{class_cgi_errors}         = {};
    $self->{class_cgi_missing}        = {};
    $self->{class_cgi_required}       = {};
    $self->{class_cgi_error_encoding} = undef;
    return $self;
}

##############################################################################

=head2 handlers

  use Class::CGI;
  my $cust_cgi = Class::CGI->new;
  $cust_cgi->handlers(
    customer => 'My::Customer::Handler',
  );
  my $order_cgi = Class::CGI->new($other_params);
  $order_cgi->handlers(
    order    => 'My::Order::Handler',
  );
  my $customer = $cust_cgi->param('customer');
  my $order    = $order_cgi->param('order');
  $order->customer($customer);

  my $handlers = $cgi->handlers; # returns hashref of current handlers
 
Sometimes we get our CGI parameters from different sources.  This commonly
happens in a persistent environment where the class handlers for one form may
not be appropriate for another form.  When this occurs, you may set the
handler classes on an instance of the C<Class::CGI> object.  This overrides
global class handlers set in the import list:

  use Class::CGI handlers => { 
      customer => "Some::Customer::Handler",
      order    => "My::Order::Handler"
  };
  my $cgi = Class::CGI->new;
  $cgi->handlers( customer => "Some::Other::Customer::Handler" );

In the above example, the C<$cgi> object will not use the
C<Some::Customer::Handler> class.  Further, the "order" handler will B<not> be
available.  Setting hanlders on an makes the global handlers unavailable.  If
you also needed the "order" handler, you need to specify that in the
C<&handlers> method.

If called without arguments, returns a hashref of the current handlers in
effect.

=cut

sub handlers {
    my $self = shift;
    if ( my %handlers = @_ ) {
        $self->{class_cgi_handlers} = \%handlers;
        $self->_verify_installed( values %handlers );
        return $self;
    }

    # else called without arguments
    if ( my %handlers = %{ $self->{class_cgi_handlers} } ) {
        return \%handlers;
    }
    return \%class_for;
}

##############################################################################

=head2 profiles

  $cgi->profiles($profile_file, @use);

If you prefer, you can specify a config file listing the available
C<Class::CGI> profile handlers and an optional list stating which of the
profiles to use.  If the C<@use> list is not specified, all profiles will be
used.  Otherwise, only those profiles listed in C<@use> will be used.  These
profiles are used on a per instance basis, similar to C<&handlers>.

See L<DEFINING PROFILES> for more information about the profile configuration
file.

=cut

sub profiles {
    my ( $self, $profiles, @use ) = @_;
    unless ( -f $profiles ) {

        # eventually we may want to allow them to specify a config
        # class instead of a file.
        $self->_croak("Can't find profile file '$profiles'");
    }

    require Config::Std;
    Config::Std->import;
    read_config( $profiles => \my %config );
    my %handler_for = %{ $config{profiles} };
    if (@use) {
        my %used;
        foreach my $profile (@use) {
            if ( exists $handler_for{$profile} ) {
                $used{$profile} = 1;
            }
            else {
                $self->_croak("No handler found for parameter '$profile'");
            }
        }
        foreach my $profile ( keys %handler_for ) {
            delete $handler_for{$profile} unless $used{$profile};
        }
    }
    $self->handlers(%handler_for);
}

##############################################################################

=head2 param

 use Class::CGI
     handlers => {
         customer => 'My::Customer::Handler'
     };

 my $cgi = Class::CGI->new;
 my $customer = $cgi->param('customer'); # returns an object, if found
 my $email    = $cgi->param('email');    # returns the raw value
 my @sports   = $cgi->param('sports');   # behaves like you would expect

If a handler is defined for a particular parameter, the C<param()> calls the
C<new()> method for that handler, passing the C<Class::CGI> object and the
parameter's name.  Returns the value returned by C<new()>.  In the example
above, for "customer", the return value is essentially:

 return My::Customer::Handler->new( $self, 'customer' );

=cut

sub param {
    my $instance_handlers = $_[0]->{class_cgi_handlers};
    my $handler_for = %$instance_handlers ? $instance_handlers : \%class_for;
    if ( 2 != @_ || ( 2 == @_ && !exists $handler_for->{ $_[1] } ) ) {

        # this allows multi-valued params for parameters which do not have
        # helper classes and also allows for my @params = $cgi->param;
        goto &CGI::Simple::param;
    }
    my ( $self, $param ) = @_;
    my $class = $handler_for->{$param};
    eval "require $class";
    $self->_croak("Could not load '$class': $@") if $@;
    my $result;
    eval { $result = $class->new( $self, $param ) };
    if ( my $error = $@ ) {
        $self->add_error( $param, $error );
        return;
    }
    return $result;
}

##############################################################################

=head2 raw_param

  my $id = $cgi->raw_param('customer');

This method returns the actual value of a parameter, ignoring any handlers
defined for it.

=cut

sub raw_param {
    my $self = shift;
    return $self->SUPER::param(@_);
}

##############################################################################

=head2 args

  $cgi->args('customer', \@whatever_you_want);

  my $args = $cgi->args($param);

This method allows you to pass extra arguments to a handler.  Specify the name
of the parameter for which you wish to provide the arguments and then provide
a I<single> argument (it may be a reference).  In your handler, you can access
it like this:

  package Some::Handler;

  sub new {
      my ( $class, $cgi, $param ) = @_;

      my $args = $cgi->args($param);
      ...
  }

=cut

sub args {
    my $self    = shift;
    my $param   = shift;
    my $arg_for = $self->{class_cgi_args};
    {
        no warnings 'uninitialized';
        return $arg_for->{$param} unless @_;
    }

    $arg_for->{$param} = shift;
    return $self;
}

##############################################################################

=head2 errors

  if ( my %errors = $cgi->errors ) {
      ...
  }

Returns exceptions thrown by handlers, if any.  In scalar context, returns a
hash reference.  Note that these exceptions are generated via the overloaded
C<&param> method.  For example, let's consider the following:

    use Class::CGI
        handlers => {
            customer => 'My::Customer::Handler',
            date     => 'My::Date::Handler',
            order    => 'My::Order::Handler',
        };

    my $cgi      = Class::CGI->new;
    my $customer = $cgi->param('customer');
    my $date     = $cgi->param('date');
    my $order    = $cgi->param('order');

    if ( my %errors = $cgi->errors ) {
       # do error handling
    }

If errors are generated by the param statements, returns a hash of the errors.
The keys are the param names and the values are whatever exception the handler
throws.  Returns a hashref in scalar context.

If no errors were generated, this method simply returns.  This allows you to
do this:

  if ( $cgi->errors ) { ... }

If any of the C<< $cgi->param >> calls generates an error, it will B<not> throw
an exception.  Instead, control will pass to the next statement.  After all
C<< $cgi->param >> calls are made, you can check the C<&errors> method to see
if any errors were generated and, if so, handle them appropriately.

This allows the programmer to validate the entire set of form data and report
all errors at once.  Otherwise, you wind up with the problem often seen on Web
forms where a customer will incorrectly fill out multiple fields and have the
Web page returned for the first error, which gets corrected, and then the page
returns the next error, and so on.  This is very frustrating for a customer
and should be avoided at all costs.

=cut

sub errors {
    my $self   = shift;
    my $errors = $self->{class_cgi_errors};
    return unless %$errors;
    return wantarray ? %$errors : $errors;
}

##############################################################################

=head2 clear_errors 

  $cgi->clear_errors;

Deletes all errors returned by the C<&errors> method.

=cut

sub clear_errors {
    my $self = shift;
    $self->{class_cgi_errors} = {};
    return $self;
}

##############################################################################

=head2 add_error

  $cgi->add_error( $param, $error );

This method add an error for the given parameter.

=cut

sub add_error {
    my ( $self, $param, $error ) = @_;
    $error = HTML::Entities::encode_entities( $error, $self->error_encoding );
    $self->{class_cgi_errors}{$param} = $error;
    return $self;
}

##############################################################################

=head2 add_missing

  $cgi->add_missing( $param, $optional_error_message );

Helper function used in handlers to note that a parameter is "missing".  This
should only be used for "required" parameters.  Calling this method with a
non-required parameter is a no-op.  See the L<required> and C<is_required>
methods.

Missing parameters will be reported via the L<errors> and
L<is_missing_required> methods.

=cut

sub add_missing {
    my ( $self, $param, $message ) = @_;
    return unless $self->is_required($param);
    $self->{class_cgi_missing}{$param} = 1;
    $self->add_error( 
        $param,
        $message || "You must supply a value for $param"
    );
    return $self;
}

##############################################################################

=head2 is_missing_required

  if ( $cgi->is_missing_required( $param ) ) {
      ...
  }

Returns a boolean value indicating whether or not a required parameter is
missing.  Always return false for parameters which are not required.

Note that this value is set via the L<add_missing> method.

=cut

sub is_missing_required {
    my ( $self, $param ) = @_;
    return $self->{class_cgi_missing}{$param} || ();
}

##############################################################################

=head2 error_encoding 

  $cgi->error_encoding( $unsafe_characters );

Error messages must be properly escaped for display in HTML.  We use
C<HTML::Entities> to handle the encoding.  By default, this encodes control
characters, high bit characters, and the "<", "&", ">", "'" and """
characters.  This should suffice for most uses.

If you need to specify a different set of characters to encode, you may set
them with this method.  See the C<encode_entities> documentation in
L<HTML::Entities> for details on the C<$unsafe_characters>.

=cut

sub error_encoding {
    my $self = shift;
    return $self->{class_cgi_error_encoding} || () unless @_;
    $self->{class_cgi_error_encoding} = shift;
    return $self;
}

##############################################################################

=head2 required

  $cgi->required(@required_parameters);

Allows you to set which parameters are required for this C<Class::CGI> object.
Any previous "required" parameters will be cleared.

=cut

sub required {
    my $self = shift;
    $self->{class_cgi_required} = {};
    foreach my $param (@_) {
        $self->{class_cgi_required}{$param} = 1;
    }
    return 1;
}

##############################################################################

=head3 is_required

  if ( $cgi->is_required($param) ) {
      ...
  }

Generally used in handlers, this method returns a boolean value indicating
whether or not a given parameter is required.

=cut

sub is_required {
    my ( $self, $param ) = @_;
    return exists $self->{class_cgi_required}{$param};
}

sub _croak {
    my ( $proto, $message ) = @_;
    require Carp;
    Carp::croak $message;
}

sub _module_exists {
    my $module_name = shift;
    my @parts = split /(?:::|')/, $module_name;
    $parts[-1] .= '.pm';

    for (@INC) {
        return 1 if -f catfile( $_, @parts );
    }
    return;
}

=head1 WRITING HANDLERS

=head2 A basic handler

Handlers are usually pretty easy to write.  There are a few simple rules to
remember. 

=over 4

=item * Inherit from L<Class::CGI::Handler>.  

=item * Provide a method named C<handle> which takes C<$self> as an argument.

=item * Return whatever value you want.

=item * For virtual parameters, override the C<has_param> method.

=back

And that's pretty much it. See the L<Class::CGI::Handler> documentation for
what methods are available to call on C<$self>.  The ones which will probably
always be used are the C<cgi> and C<param> methods.

Writing a handler is a fairly straightforward affair.  Let's assume that our
form has a parameter named "customer" and this parameter should point to a
customer ID.  The ID is assumed to be a positive integer value.  For this
example, we assume that our customer class is named C<My::Customer> and we
load a customer object with the C<load_from_id()> method.  The handler might
look like this:

  package My::Customer::Handler;
  
  use base 'Class::CGI::Handler';
  
  use My::Customer;
  
  sub handle {
      my $self  = shift;
      my $cgi   = $self->cgi;
      my $param = $self->param;
      
      my $id = $cgi->raw_param($param);
      
      unless ( $id && $id =~ /^\d+$/ ) {
          die "Invalid id ($id) for $class";
      }
      return My::Customer->load_from_id($id)
          || die "Could not find customer for ($id)";
  }
  
  1;

Pretty simple, eh?

Using this in your code is as simple as:

  use Class::CGI
    handlers => {
      customer => 'My::Customer::Handler',
    };

If C<Class::CGI> is being used in a persistent environment and other forms
might have a param named C<customer> but this param should not become a
C<My::Customer> object, then set the handler on the instance instead:

  use Class::CGI;
  my $cgi = Class::CGI->new;
  $cgi->handlers( customer => 'My::Customer::Handler' );

B<Important>:  Note that earlier versions of C<Class::CGI> listed handlers
with names like C<Class::CGI::Order>.  It is recommended that you not use the
C<Class::CGI::> namespace to avoid possibly conflicts with handlers which may
be released to the CPAN in this namespace I<unless> you also intend to release
your module to the CPAN in this namespace.

=head2 A more complex example

As a more common example, let's say you have the following data in a form:

  <select name="month">
    <option value="01">January</option>
    ...
    <option value="12">December</option>
  </select>
  <select name="day">
    <option value="01">1</option>
    ...
    <option value="31">31</option>
  </select>
  <select name="year">
    <option value="2006">2006</option>
    ...
    <option value="1900">1900</option>
  </select>

Ordinarily, pulling all of that out, untainting it is a pain.  Here's a
hypothetical handler for it:

  package My::Date::Handler;

  use base 'Class::CGI::Handler';
  use My::Date;

  sub handle {
      my $self = shift;
      my $cgi  = $self->cgi;
      my $month = $cgi->raw_param('month');
      my $day   = $cgi->raw_param('day');
      my $year  = $cgi->raw_param('year');
      return My::Date->new(
        month => $month,
        day   => $day,
        year  => $year,
      );
  }

  # because this is a virtual parameter, we must override the has_param()
  # method.
  sub has_param {
      my $self = shift;
      return $self->has_virtual_param( date => qw/day month year/ );
  }

  1;

And in the user's code:

  use Class::CGI
    handlers => {
      date => 'My::Date::Handler',
    };

  my $cgi  = Class::CGI->new;
  my $date = $cgi->param('date');
  my $day  = $date->day;

Note that this does not even require an actual param named "date" in the form.
The handler encapsulates all of that and the end user does not need to know
the difference.

=head2 Virtual parameters

Note that the parameter a user fetches might not exist on the form.  In the
C<< $cgi->param('date') >> example above, there is no "date" parameter.
Instead, it's a composite formed of other fields.  It's strongly recommended
that if you have a handler which uses virtual parameters that you B<do not>
use a parameter with the same name.  If you must, you can still access the
value of the real parameter with C<< $cgi->raw_param('date'); >>.

=head2 Reusing handlers

Sometimes you might want to use a handler more than once for the same set of
data.  For example, you might want to have more than one date on a page.  To
handle issues like this, we pass in the parameter name to the constructor so
you can know I<which> date you're trying to fetch.

So for example, let's say their are three dates in a form.  One is the
customer birth date, one is an order date and one is just a plain date.  Maybe
our code will look like this:

 $cgi->handlers(
     birth_date => 'My::Date::Handler',
     order_date => 'My::Date::Handler',
     date       => 'My::Date::Handler',
 );

One way of handling that would be the following:

 package My::Date::Handler;
 
 use base 'Class::CGI::Handler';
 use strict;
 use warnings;
 
 use My::Date;
 
 sub handle {
     my $self  = shift;
     my $cgi   = $self->cgi;
     my $param = $self->param;

     my $prefix;
     if ( 'date' eq $param ) {
         $prefix = '';
     }
     else {
         ($prefix = $param) =~ s/date$//;
     }
     my ( $day,  $month, $year )  =
       grep {defined}
       map  { $cgi->raw_param($_) } $self->components;

     return My::Date->new(
         day   => $day,
         month => $month,
         year  => $year,
     );
 }

 sub components {
     my $self  = shift;
     my $cgi   = $self->cgi;
     my $param = $self->param;

     my $prefix;
     if ( 'date' eq $param ) {
         $prefix = '';
     }
     else {
         ($prefix = $param) =~ s/date$//;
     }
     return map { "$prefix$_" } qw/day month year/;
 }

 sub has_param {
    my $self = shift;
    return $self->has_virtual_param( $self->param, $self->components );
 }
 
 1;

For that, the birthdate will be built from params named C<birth_day>,
C<birth_month> and C<birth_year>.  The order date would be C<order_day> and so
on.  The "plain" date would be built from params named C<day>, C<month>, and
C<year>.  Thus, all three could be accessed as follows:

 my $birthdate  = $cgi->param('birth_date');
 my $order_date = $cgi->param('order_date');
 my $date       = $cgi->param('date');

=head1 DEFINING PROFILES

Handlers for parameters may be defined in an import list:

  use Class::CGI
      handlers => {
          customer   => 'My::Customer::Handler',
          order_date => 'My::Date::Handler',
          order      => 'My::Order::Handler',
      };

=head2 Creating a profile file

For larger sites, it's not very practical to replicate this in all code which
needs it.  Instead, C<Class::CGI> allows you to define a "profiles" file.
This is a configuration file which should match the C<Config::Std> format.  At
the present time, only one section, "profiles", is supported.  This should be
followed by a set of colon-delimited key/value pairs specifying the CGI
parameter name and the handler class for the parameter.  The above import list
could be listed like this in the file:

  [profiles]
  customer:   My::Customer::Handler
  order_date: My::Date::Handler
  order:      My::Order::Handler

You may then use the profiles in your code as follows:

  use Class::CGI profiles => $location_of_profile_file;

It may be the case that you don't want all of the profiles.  In that case, you
can list a "use" section for that:

  use Class::CGI 
    profiles => $location_of_profile_file,
    use      => [qw/ order_date order /];
    
As with C<&handlers>, you may find that you don't want the profiles globally
applied.  In that case, use the C<&profiles> method described above:

  $cgi->profiles( $profile_file, @optional_list_of_profiles_to_use );

=head1 DESIGN CONSIDERATIONS

=head2 Subclassing CGI::Simple

Because this module is a subclass of C<CGI::Simple>, all of C<CGI::Simple>'s
methods and behaviors should be available.  We do not subclass off of C<CGI>
because C<CGI::Simple> is faster and it's assumed that if we're going the full
OO route that we are already using templates.  Thus, the C<CGI> HTML
generation methods are not available and should not be needed.  This decision
may be revisited in the future.

More to the point, CGI.pm, while being faster and more lightweight than most
people give it credit for, is a pain to subclass.  Further, it would need to
be subclassed without exposing the functional interface due to the need to
maintain state in C<Class::CGI>.

=head2 Delayed loading

When handlers are specified, either at compile time or setting them on an
instance, the existence of the handlers is verified.  However, the handlers
are not loaded until used, thus reducing memory usage if they are not needed.

In a similar vein, if you choose to use a profile file (see L<Creating a
profile file>), C<Config::Std> is used.  However, that module is also not
loaded unless needed.

=head2 Why not Data::FormValidator?

The biggest complaint about C<CGI::Simple> seems to be that it's "reinventing
the wheel".  Before you agree with that complaint, see
L<http://www.perlmonks.org/?node_id=543742>.  Pointy-haired boss summary of
that link:  you had better reinvent the wheel if you're creating a motorcycle
instead of a car.

There's nothing wrong with C<Data::FormValidator>.  It's fast, powerful, and
well-proven in its approach.  C<Class::CGI>, in fact, can easily benefit from
C<Data::FormValidator> inside of handler classes.  However, the approach we
take is fundamentally different.  First, instead of learning a list of
required hash keys and trying to remember what C<optional_regexp>, C<filters>,
C<field_filter_regexp_map>, C<dependency_groups> and so on do, you just need
to know that a handler constructor takes a C<Class::CGI> instance and the
parameter name.  Everything else is just normal Perl code, no memorization
required.

With C<Class::CGI>, you can pick and choose what handlers you wish to support
for a given piece of code.  You can have a global set of handlers to enforce
consistency in your Web site or you can have "per page" handlers set up as
needed.

=head1 TODO

This module should be considered alpha code.  It probably has bugs.  Comments
and suggestions welcome.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 SUPPORT

There is a mailing list at L<http://groups.yahoo.com/group/class_cgi/>.
Currently it is low volume.  That might change in the future.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-cgi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-CGI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

If you are unsure if a particular behavior is a bug, feel free to send mail to
the mailing list.

=head1 SEE ALSO

This module is based on the philosophy of building super-simple code which
solves common problems with a minimum of memorization.  That being said, it
may not be the best fit for your code.  Here are a few other options to
consider.

=over 4

=item * 
Data::FormValidator - Validates user input based on input profile

=item *
HTML::Widget - HTML Widget And Validation Framework 

=item *
Rose::HTML::Objects - Object-oriented interfaces for HTML

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Aristotle for pointing out how useful passing the parameter name to
the handler would be.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
