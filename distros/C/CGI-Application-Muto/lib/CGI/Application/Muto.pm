package CGI::Application::Muto;

use base 'CGI::Application';

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '0.02';

# Load our recommended plugins
use CGI::Application::Plugin::DBH qw/dbh_config dbh/;
use CGI::Application::Plugin::ConfigAuto qw/cfg_file cfg/;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::LogDispatch;
use CGI::Application::Plugin::Session;


# Load our magic maker plugins
use Class::Inspector;
use CGI::Application::Muto::MethodAttributes;
use Data::Dumper;
use Module::Load;


# We overload the CGI::App run method to provide some extra functionality
# of our own
sub run {

    my $self = shift;

    $self->_init_controllers();
    $self->_init_controller_methods();

    #Some callbacks
    $self->add_callback('prerun', \&_fetch_controller_method);
    $self->add_callback('prerun', \&_check_protected_methods);

    return $self->SUPER::run(); #call CGI::App run method

}


sub _init_controllers{

    my $self = shift;

    # @controller_paths define the search path where we want to search for
    # plugins
    our @controller_paths = ('Muto::App::Controller');
    push @controller_paths, $self->param('controller_path') if $self->param('controller_path');

    # Using Module::Pluggable we fetch the list of all available plugins
    # and have them available by the '_contr' method in our namespace
    use Module::Pluggable search_path => \@controller_paths,
                          sub_name => '_contr';

    # We iterate through the plugin list and using Module::Load we
    # attempt to load them
    for my $Controller( $self->_contr ){
        load $Controller;
    }

    return;
}


# We are gonna provide a really cool way of making our methods work similar to
# the ones on Catalyst
# This code has been taken almost entirely from the module
# CGI::Application::Plugin::ActionDispatch by Jason Yates, E<lt>jaywhy@gmail.comE<gt>
# so all credit goes to him on this aspect of the code
our %_attr_cache;
my %methods;
my $init_attr_handlers = 1;

sub CGI::Application::Muto::Path :ATTR {
  my ($class, $referent, $attr, $data) = @_;

  $data ||='';
  $data =~ s/\/$//;
  unless( $data =~ /^\// ) {
    $data = "/" . $data;
  }

  my $regex = qr/^$data\/?(\/.*)?$/;
  push(@{ $_attr_cache{$class}{$attr} }, [ $referent, $regex ]);
}

sub CGI::Application::Muto::Regex :ATTR {
  my ($package, $referent, $attr, $data) = @_;
  my $regex = qr/$data/;
  push(@{ $_attr_cache{$package}{$attr} }, [$referent, $regex ]);
}

sub CGI::Application::Muto::Runmode :ATTR {
  my ($package, $referent, $attr, $data) = @_;

  $data = $methods{$referent};
  my $regex = qr/^\/$data\/?$/;
  push(@{ $_attr_cache{$package}{$attr} }, [ $referent, $regex ]);
}

sub CGI::Application::Muto::Default :ATTR {
  my ($package, $referent, $attr, $data) = @_;
  $_attr_cache{$package}{$attr} = $referent;
}

sub CGI::Application::Muto::ErrorRunmode :ATTR {
  my ($package, $referent, $attr, $data) = @_;
  $_attr_cache{$package}{$attr} = $referent;
}

# We register the methods into CGI::App's run mode map
sub _init_controller_methods {

  my $self = shift;
  my $class = ref $self || $self;

  # Setup a hash table of all the methods in the class.
  $methods{$self->can($_)} = $_
    foreach @{ Class::Inspector->methods($class) || [] }; #NOTE: This will search through ISA also.

  CGI::Application::Muto::MethodAttributes::init();

  if(defined $_attr_cache{$class}{'Default'}) {
    my $runmode = $methods{$_attr_cache{$class}{'Default'}};
    $self->start_mode($runmode);
    $self->run_modes($runmode => $runmode);
  }

  if(defined $_attr_cache{$class}{'ErrorRunmode'}) {
    $self->error_mode($methods{$_attr_cache{$class}{'ErrorRunmode'}});
  }

}

# Based on the 'path_env' variable we try to identify the correct
# method to execute
sub _fetch_controller_method {

  my $self = shift;
  my $class = ref $self || $self;

  my $_TEST_PATH_ON = $self->param('path_env') || 'PATH_INFO';
  my $_PATH_PREFIX = $self->param('path_prefix') || '';

  return unless defined $ENV{$_TEST_PATH_ON};

  my $_PATH_INFO = $ENV{$_TEST_PATH_ON};

  $_PATH_INFO =~ s/\?.*$//;

  if( $_PATH_PREFIX ){
    $_PATH_INFO =~ s/^$_PATH_PREFIX//;
  }

  my $start_mode = $self->start_mode();
  ATTR: foreach my $type (qw( Runmode Regex Path )) {
    my($code, @args) = _match_type($class, $type, $_PATH_INFO);
    if($code) {
      # Make sure the runmode isn't set already and prerun_mode isn't set.
      if(! $self->prerun_mode()) {
              # Sorta of a hack here to actually get the runmode to run.
        my $runmode = $methods{$code};
        $self->run_modes($runmode => $runmode);
        $self->prerun_mode($runmode);

              # Set the action_args array.
              $self->action_args(@args);
      }

      last ATTR;
    }
  }

}

# This little function tries to match the method on the $path_info
# if several methods mathc, then it uses the one that matches
# the closest
sub _match_type {

  my($class, $type, $path_info) = @_;

  my $min;
  my(@path_args, $code);
  foreach my $attr (@{ $_attr_cache{$class}{$type} }) {
    if(my @args = ($path_info =~ $attr->[1])) {
      # We want to match the most accurate Path().  This is
      # done by counting the args, and finding the Path with
      # the fewest amount of args left over.
      if($type eq 'Path') {
        if(@args && $args[0]) {
          $args[0] =~ s/^\///;
          @path_args = split('/', $args[0]);
        }

        # Set min if not defined.
        $min = scalar(@path_args) if( not defined $min );

        # If complete match return.
        if( scalar(@path_args) == 0 ) {
          return ($attr->[0], undef);
        } elsif(scalar(@path_args) <= $min) {
          # Has fewest @path_args so far.
          $min = scalar(@path_args);
          $code = $attr->[0];
        }
      } else {
              return ($attr->[0], @args);
      }
    }
  }
  return @path_args ? ($code, @path_args) : 0;

}


sub action_args {
  my($self, @args) = @_;

  # If args are passed set them.
  if(@args) {
    $self->{__CAP_ACTION_ARGS} = [ @args ];
    return;
  }

  return undef unless defined $self->{__CAP_ACTION_ARGS};
  return wantarray ? @{$self->{__CAP_ACTION_ARGS}} : shift @{$self->{__CAP_ACTION_ARGS}};
}




# Add run mode protection
sub protect_rm{

    my $self = shift;
    my %args = @_;

    if( !$args{'Regex'} && !$args{'Path'} ){
        return;
    }
    elsif(!$args{'auth_check'}
          || !ref($args{'auth_check'})
          ||  ref($args{'auth_check'}) ne 'CODE' ){
        return;
    }
    elsif( !$args{'login_page'} ){
        return;
    }

    #Register the new protected rm
    push @{$self->{'_PROTECTED_RM'}}, \%args;

    return 1;

}


# This function checks if the path that is about to be executed
# is protected
sub _check_protected_methods{

    my $self = shift;

    my $_TEST_PATH_ON = $self->param('path_env') || 'PATH_INFO';
    my $_PATH_PREFIX = $self->param('path_prefix') || '';

    return unless defined $ENV{$_TEST_PATH_ON};

    my $_PATH_INFO = $ENV{$_TEST_PATH_ON};

    $_PATH_INFO =~ s/\?.*$//;

    if( $_PATH_PREFIX ){
        $_PATH_INFO =~ s/^$_PATH_PREFIX//;
    }

    $_PATH_INFO =~ s/^\///;

    my $_IS_PROTECTED = 0;
    my $_PRM;

    for my $prm( @{$self->{'_PROTECTED_RM'}} ){

        if( $prm->{'Path'} && $prm->{'Path'} eq $_PATH_INFO ){
            $_IS_PROTECTED = 1;
            $_PRM = $prm;
            last;
        }
        elsif( $prm->{'Regex'} && $_PATH_INFO =~ $prm->{'Regex'} ){
            $_IS_PROTECTED = 1;
            $_PRM = $prm;
            last;
        }

    }


    #we are on a protected method
    if( $_IS_PROTECTED && $_PRM ){
        if( $_PRM->{'auth_check'}->($self) ){
            return 1;
        }
        else{
            return $self->redirect($_PRM->{'login_page'});
        }
    }
    else{
        return 1;
    }

}

1;
__END__


=head1 NAME

CGI::Application::Muto - A wrapper for CGI::App with some cool features


=head1 SYNOPSIS

  # In "App.pm"...
  package App;
  use base 'CGI::Application::Muto';

  sub main_index : Default{ ... }

  sub user_profile : Regex('profile/user/(\d+)'){ ... }

  sub terms : Path('page/terms'){ ... }

  1;


  ### In "app.cgi"...
  use App;
  my $webapp = App->new(
                    PARAMS => {
                          #optional config attributes
                    }
                );

  $webapp->run();


=head1 INTRODUCTION

CGI::Application::Muto is my attempt to create a wrapper around CGI::Application
to provide some additional functionality. Muto comes from the latin for
to change, alter/exchange.

I recommend you read the CGI::Application documentation as I will only explain
here the new functions this module brings into the table.


=head1 DESCRIPTION

You should use CGI::Application::Muto so that your main application module
it's implemented as a sub-class, in the following way:

  package App;
  use base 'CGI::Application::Muto';

=head2 Application States

In CGI::App you have to register your run modes on the setup() function. The
run modes are but a map that allows CGI::App to know which method to call upon
a specific CGI request.

Muto provides a way to sweeten that process by approaching in a way similar to
Catalyst. You will be able to use attributes within your function declarations
that will allow Muto to correctly map the request to the method.

This functionality has been basically taken from CGI::Application::Plugin::ActionDispatch
by Jason Yates.

Muto doesn't rely on the run_modes() function allthough you can still use it.
Instead as with Catalyst you should use specific function attributes that will
tell Muto the state you wish the function to represent.

When a request is received by Muto it will try to match the PATH_INFO against
all your function attributes, smartly calling the correct method.

You will have four different ways to be able to do so:

=head3 Regex

Will use regular expressions to match against the PATH_INFO. In the case that
you use capturing parentheses, the captured that will be available for you via
the action_args() method.

  sub user_profile : Regex('user/(\d+)'){ }

All the Regex methods will take priority, in case that a Path or Regex method
match, the Regex method will be used

=head3 Path

This attribute works like a shortcut of Regex. For example:

  #Path: shirt/small
  sub view_shirt : Path('shirt/'){
      my $self = shift;

      my ($shirt_size) = $self->action_args();

      ...
  }

Which is basically the same thing if we have done:

  sub view_shirt : Regex('^/shirt/(\w+)'){
      my $self = shift;

      my ($shirt_size) = $self->action_args();

      ...
  }

For those that care, the Path('products/') will be converted to the regular
expression C<"^/products\/?(\/.*)$";> then split('/') is run on the captured
value and stored in action_args().

=head3 Runmode

This attribute will take the method name and match it to the PATH_INFO.

  sub foo : Runmode{ ... } #will match /foo

=head3 Default

If no match is found then Muto will attempt to run the method with this attribute,
which can be considered an equivalent functionality to start_mode().

  sub main_index : Default{ ... }

=head3 Path arguments with action_args()

Path and Regex can capture arguments provided in the PATH_INFO. You can access
the captured arguments by invoking the action_args() method on Muto, which will
return an array of the captured arguments.

  my @captured_args = $app->action_args();

=head2 Controllers

As CGI::App doesn't provide and easy and straight-forward way to organize your
different application states or methods over different files, Muto attempts
to fix this.

Muto uses and approach very similar to Catalyst, in which you are able to add
your Controllers which will be auto-discovered by Muto and made accesible for
your application.

Muto will look for any modules found under the Muto::App::Controller namespace,
for example:

  # In "Muto/App/Controller/Books.pm"

  package Muto::App::Controller::Books;

  sub App::book_browse : Path('book/browse'){ ... }

  sub App::book_read : Regex('book/read/(\d+)'){

      my $self = shift;

      my ($book_id) = $self->action_args();

      ...

  }

  1;

Your methods should be declared on the namespace of your main application. In
this example that is C<App>.

Now your controller will be immediately available and accesed by your
application.

NOTE: Since all methods are imported into your application namespace, you have
to be careful with name clash of your method names.

=head2 Protected Run-Modes

Muto gives you the availability of protecting certain run modes. Since I wanted
this to be as open as possible, Muto doesn't do any authentication, but instead
calls a method that should return true or false if the user has been authenticated.

This gives you complete control over how you choose to authenticate or open
access to your protected run modes.

You should declare your protected run modes on cgiapp_init(), to do so:

  sub cgiapp_init {

      my $self = shift;

      $self->protect_rm(
                'Regex' => '^protected(.*)',
                'auth_check' => \&_check_user_permissions,
                'login_page' => 'http://mysite.com/login',
            );

  }

The protect_rm() method receives three different arguments:

=over 4

=item (Regex|Path)

You have to send either a Regex or Path with the expression as it's value. This
works the same as with the method attributes, except that Path matches exactly
the expression against the PATH_INFO.

=item auth_check

This should be a reference to a sub-routine with the authentication check. This
function should return 1 if the user is authenticated, and 0 if it's not. If the
user is authenticated then it will gain access to the application state, otherwise
it will be redirected to the login page.

=item login_page

The URL to which your users should be redirected in case they haven't been
authenticated.

You can add as many protected run-modes as you desire, each with it's own
authentication if you choose to do so. Simply call protect_rm() for each
protected run-mode or area you want to add.

=back

  sub cgiapp_init {

      my $self = shift;

      #protects everything under /protected
      $self->protect_rm(
                'Regex' => '^protected(.*)',
                'auth_check' => \&_check_user_permissions,
                'login_page' => 'http://mysite.com/login',
            );

      #protects only /ultra/secret/text
      $self->protect_rm(
                'Path' => 'ultra/secret/text',
                'auth_check' => \&_check_higher_permissions,
                'login_page' => 'http://mysite.com/ultra/login',
            );

  }

Since Muto realies completely on your auth_check method to give or deny access,
it's really important that you verify that your method returns the correct value.

You can use the different CGI::Application::Plugins available for this to achieve
this purposes.

=head2 Advanced Configuration

When you create a new Muto object you can send it some arguments to
tweak the way Muto behaves.

  use My::App;

  my $webapp = App->new(
                    PARAMS => {
                        'controller_path' => 'My::App::Controllers',
                        'path_env' => 'REQUEST_URI',
                        'path_prefix' => '/myapp',
                    }
                );

  $webapp->run();

The three configuration settings you can modify are:

=over

=item controller_path

Muto will search for default the Muto::App::Controller namespace for new
controllers to import. With this setting you can add a new namespace to search
for. This will be additional to the default one.

=item path_env

For default Muto will use $ENV{PATH_INFO} as the PATH_INFO value to render all
the appropiate application states:

  http://mysite.com/index.cgi/path/here

I find it that you may want to do something nicer using mod_rewrite, so with this
setting you can actually tell Muto which %ENV variable to use, for example, if
you use 'REQUEST_URI' then you can do:

  http://mysite.com/path/here

You may need to do this in conjunction of mod_rewrite with a .htaccess that looks
something like this:

    RewriteEngine On

    RewriteCond %{SCRIPT_FILENAME} !-f
    RewriteCond %{SCRIPT_FILENAME} !-d

    RewriteRule (.*) /index.cgi [NC,QSA]

=item path_prefix

Muto will remove the value of this setting before attempting to do any matching
on your methods.

=back

=head1 BUGS

This distribution is currently in beta state, this means that it can have some
bugs that I'm not yet aware of.

Please report any bugs or feature requests through the web interface at
https://rt.cpan.org.

=head1 AUTHOR

Uriel Lizama  <uriel at baboonsoftware.com>

=head1 ACKNOWLEDGMENTS

The method attributes feature of Muto is heavily based on the module
L<CGI::Application::Dispatch> by Jason Yates.

Many thanks to Matt S. Trout who took time from his hectic life to advice me on
the directions I took.

Thanks to Marco A. Manzo (amnesiac) who was always avilable when I bugged him
with suggestions.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
