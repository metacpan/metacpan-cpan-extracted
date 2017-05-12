package CGI::Application::Plugin::ActionDispatch;

use strict;
use Data::Dumper;
use Class::Inspector;
use CGI::Application::Plugin::ActionDispatch::Attributes;
require Exporter;

our $VERSION = '0.99';
our @ISA = qw(Exporter);
our @EXPORT = qw(action_args);

our %_attr_cache;
my %methods;

sub CGI::Application::Path :ATTR {
  my ($class, $referent, $attr, $data) = @_;

  $data ||='';
  $data =~ s/\/$//;
  unless( $data =~ /^\// ) {
    $data = "/" . $data;
  }

  my $regex = qr/^$data\/?(\/.*)?$/;
  push(@{ $_attr_cache{$class}{$attr} }, [ $referent, $regex ]);
}

sub CGI::Application::Regex :ATTR {
  my ($package, $referent, $attr, $data) = @_;
  my $regex = qr/$data/;
  push(@{ $_attr_cache{$package}{$attr} }, [$referent, $regex ]);
}

sub CGI::Application::Runmode :ATTR {
  my ($package, $referent, $attr, $data) = @_;

  $data = $methods{$referent};
  my $regex = qr/^\/$data\/?$/;
  push(@{ $_attr_cache{$package}{$attr} }, [ $referent, $regex ]);
}

sub CGI::Application::Default :ATTR {
  my ($package, $referent, $attr, $data) = @_;
  $_attr_cache{$package}{$attr} = $referent;
}

sub CGI::Application::ErrorRunmode :ATTR {
  my ($package, $referent, $attr, $data) = @_;
  $_attr_cache{$package}{$attr} = $referent;
}

sub import {
  my $caller = caller;
  $caller->add_callback('init', \&_ad_init);
  $caller->add_callback('prerun', \&_ad_prerun);
  goto &Exporter::import;
}

sub _ad_init {
  my $self = shift;
  my $class = ref $self || $self;

  # Setup a hash table of all the methods in the class.
  $methods{$self->can($_)} = $_
    foreach @{ Class::Inspector->methods($class) || [] }; #NOTE: This will search through ISA also.
  
  CGI::Application::Plugin::ActionDispatch::Attributes::init();

  if(defined $_attr_cache{$class}{'Default'}) {
    my $runmode = $methods{$_attr_cache{$class}{'Default'}};
    $self->start_mode($runmode);
    $self->run_modes($runmode => $runmode);
  }

  if(defined $_attr_cache{$class}{'ErrorRunmode'}) {
    $self->error_mode($methods{$_attr_cache{$class}{'ErrorRunmode'}});
  }
}

sub _ad_prerun {
  my $self = shift;
  my $class = ref $self || $self;

  return unless defined $ENV{PATH_INFO};

  my $start_mode = $self->start_mode();
  ATTR: foreach my $type (qw( Runmode Regex Path )) {
    my($code, @args) = _match_type($class, $type, $ENV{PATH_INFO});
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
        if(defined($args[0])) {
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
	
1;
__END__

=head1 NAME

CGI::Application::Plugin::ActionDispatch - Perl extension

=head1 SYNOPSIS

  # In "WebApp.pm"...
  package WebApp;

  use base 'CGI::Application';
  use CGI::Application::Plugin::ActionDispatch;

  sub do_stuff : Path('do/stuff') { ... }
  sub do_more_stuff : Regex('^/do/more/stuff\/?$') { ... }
  sub do_something_else : Regex('do/something/else/(\w+)/(\d+)$') { ... }
  
=head1 DESCRIPTION

CGI::Application::Plugin::ActionDispatch adds attribute based support for
parsing the PATH_INFO of the incoming request. For those who are familiar with
Catalyst. The interface works very similar.

This plugin is plug and play and shouldn't interrupt the default behavior of
CGI::Application.

=head1 CAVEATS

Be aware though, this plugin will not likely work with other modules that use
attributes.

This module should work with mod_perl. It however has not be thoroughly tested
as such. If you have used it with mod_perl please e-mail me with your
experience.

=head1 METHODS

=over 4

=item action_args()

If using capturing parentheses in a Regex action. The captured values are
accessible using this method.

  sub addElement : Regex('add/(\d+)/(\d+)') {
    my $self = shift;
    my($column, $row) = $self->action_args();
    ...
  }

The Path action will store everything after the matched path into the action args.

  # http://example.com/state/pa/philadelphia
  sub find_state_and_city : Path('state/') {
    my $self = shift;
    my($state, $city) = $self->action_args();
	# $state == pa, $city == philadelphia
    ...
  }

=back
	
=head1 ACTIONS

=over 4

=item Regex

Regex action is used for regular expression matching against PATH_INFO. If
capturing parentheses are used; the matched parameters are accesssible using
the action_args() method.

  Regex('^blah/foo');

The Regex action either matches or it doesn't. There are no secrets to it.

It is important to note Regex action takes priority. It is assumed if a Path
and Regex action both match. The Regex action will take priority, which may
not always be the outcome of least suprise, for instance:

# http://example.com/music/the_clash
sub clash : Path('/music/the_clash') {} # This is an exact match, BUT.
sub the_class : Regex('/music/the_clash') {} # This takes priority. Beware.

=item Path

The Path action is basically a shortcut for a commonly used Regex action.

  # http://example.com/products/movies/2
  sub show_product : Path('products/') {
    my $self = shift;
    my($category, $id) = $self->action_args();
    ....
  }

Is basically the same thing as.

  sub show_product : Regex('^/products/(\w+)/(\d+)') {
    my $self = shift; 
    my($category, $id) = $self->action_args();
    ...
  }

For those that care, the Path('products/') will be converted to the regular
expression "^/products\/?(\/.*)$"; then split('/') is run on the captured
value and stored in action_args().

=item Runmode

This action will take the method name and run a match on that.

# http://example.com/foobar

sub foobar : Runmode {}

=item Default

The default run mode if no match is found. Essentially the equivalent of the
start_mode() method.

sub default_mode : Default {}

=back

=head1 EXAMPLE

In CGI::Application module:

  package WebApp;
  
  use base 'CGI::Application';
  use CGI::Application::Plugin::ActionDispatch;
  use strict;

  sub setup {
    my $self = shift;
    self->mode_param('test_rm');
    $self->run_modes(
      basic_runmode => 'basic_runmode'
    );
  }

  # Regular runmodes should work.
  sub basic_runmode {
    my $self = shift
  }

The product() runmode will match anything starting with "/products" in the
PATH_INFO.

  # http://example.com/myapp.cgi/products/this/is/optional/and/stored/in/action_args/
  sub product : Path('products/') {  
    my $self = shift;
    my($category, $product) = $self->action_args();
  }

The music() runmode will match anything starting with "/products/music" in the
PATH_INFO. The product() runmode also matches "/products/music". However since
this runmode matches closer it takes priority over product().

  # http://example.com/myapp.cgi/products/music/product/
  sub music : Path('products/music/') {
    my $self = shift; 
    my $product = $self->action_args();
    ...
  }

This beatles() runmode will match ONLY "/product/music/beatles" or
"/product/music/beatles/". Regex takes priority over Path so the previous
runmodes which match this PATH_INFO are not run.

  # http://example.com/myapp.cgi/products/music/beatles/
  sub beatles : Regex('^/products/music/beatles\/?')  { 
    my $self = shift; 
    ...
  }

=head1 SEE ALSO

L<CGI::Application>, L<CGI::Application::Dispatch>

http://github.com/jaywhy/cgi-application-plugin-actiondispatch

=head1 AUTHOR

Jason Yates, E<lt>jaywhy@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Jason Yates

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.7 or, at your option,
any later version of Perl 5 you may have available.


=cut
