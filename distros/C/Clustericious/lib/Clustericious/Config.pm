package Clustericious::Config;

use strict;
use warnings;
use 5.010;
use Clustericious;
use List::Util ();
use YAML::XS ();
use Mojo::Template;
use Log::Log4perl qw( :nowarn );
use Storable ();
use Clustericious::Config::Helpers ();
use Mojo::URL;
use File::Spec;
use File::Temp ();
use Carp ();

# ABSTRACT: Configuration files for Clustericious nodes.
our $VERSION = '1.29'; # VERSION


our %singletons;

our $class_suffix = {};
sub Clustericious::_config_uncache {
  my($class, $name) = @_;
  delete $singletons{$name};
  $class_suffix->{$name} //= 1;
  $class_suffix->{$name}++;
}


sub new {
  my $class = shift;

  my $logger = Log::Log4perl->get_logger(__PACKAGE__);

  # (undocumented; for now)
  # callback is used by the configdebug command;
  # may be used elsewise at a later time
  my $callback = ref $_[-1] eq 'CODE' ? pop : sub {};

  my %t_args = (ref $_[-1] eq 'ARRAY' ? @{( pop )} : () );

  my $arg = $_[0];
  ($arg = caller) =~ s/:.*$// unless $arg; # Determine from caller's class
  return $singletons{$arg} if exists($singletons{$arg});

  my $conf_data;

  state $package_counter = 0;
  my $namespace = "Clustericious::Config::TemplatePackage::Package$package_counter";
  eval qq{ package $namespace; use Clustericious::Config::Helpers; };
  die $@ if $@;
  $package_counter++;
    
  my $mt = Mojo::Template->new(namespace => $namespace)->auto_escape(0);
  $mt->prepend( join "\n", map " my \$$_ = q{$t_args{$_}};", sort keys %t_args );

  if(ref $arg eq 'HASH')
  {
    $conf_data = Storable::dclone $arg;
  }
  else
  {
    my $filename;
  
    if($arg =~ /\.conf$/)
    {
      $filename = $arg;
    }
    else
    {
      my $name = $arg;
      $name =~ s/::/-/g;      
      ($filename) = 
        List::Util::first { -f $_ } 
        map { File::Spec->catfile($_, "$name.conf") } 
        Clustericious->_config_path;
      
      unless($filename)
      {
        $logger->trace("could not find $name file.") if $logger->is_trace;
        $conf_data = {};
      }
    }

    if ($filename) {
      $logger->trace("reading from config file $filename") if $logger->is_trace;
      $callback->(pre_rendered => $filename);
      my $rendered = $mt->render_file($filename);
      $callback->(rendered => $filename => $rendered);

      die $rendered if ( (ref $rendered) =~ /Exception/ );

      $conf_data = eval { YAML::XS::Load($rendered) };
      $logger->logdie("Could not parse\n-------\n$rendered\n---------\n$@\n") if $@;
    } else {
      $callback->('not_found' => "$arg");
    }
  }

  $conf_data ||= {};
  Clustericious::Config::Helpers->_do_merges($conf_data);

  # Use derived classes so that AUTOLOADING keeps namespaces separate
  # for various apps.
  if ($class eq __PACKAGE__)
  {
    if(ref $arg)
    {
      $arg = "$arg";
      $arg =~ tr/a-zA-Z0-9//cd;
    }
    elsif($arg =~ s/\.conf$//)
    {
      # NOTE: may revisit this later.
      $arg = "cwd::$arg" unless $arg =~ s{^/+}{root::};
      $arg =~ s{[\\/]}{::}g;
      $arg =~ s{\.\.::}{__up__::}g;
      $arg =~ tr/a-zA-Z0-0_://cd;
      $arg =~ s/:{3,}/::/g;
    }
    $arg =~ s/-/::/g;
    $class = join '::', $class, 'App', $arg;
    $class .= $class_suffix->{$arg} if $class_suffix->{$arg};
    my $dome = '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . '@'."$class"."::ISA = ('".__PACKAGE__. "')";
    eval $dome;
    die "error setting ISA : $@" if $@;
  }
  bless $conf_data, $class;
}

# defined so that AUTOLOAD doesn't get called
# when config falls out of scope.
sub DESTROY {
}

sub AUTOLOAD {
  my($self, %args) = @_;
  
  # NOTE: I hope to deprecated and later remove defining defaults in this way in the near future.
  my $default = $args{default};
  my $default_exists = exists $args{default};

  our $AUTOLOAD;
  my $called = $AUTOLOAD;
  $called =~ s/.*:://g;

  my $value = $self->{$called};
  my $invocant = ref $self;
  my $obj = ref $value eq 'HASH' ? $invocant->new($value) : undef;

  my $sub = sub {
    my $self = shift;
    my $value;
          
    if(exists $self->{$called})
    {
      $value = $self->{$called};
    }
    elsif($default_exists)
    {
      $value = $self->{$called} = ref $default eq 'CODE' ? $default->() : $default;
      $obj = ref $value eq 'HASH' ? $invocant->new($value) : undef;
    }
    else
    {
      Carp::croak "'$called' configuration item not found.  Values present: @{[keys %$self]}";
    }

    my $ref = ref $value;
    if($ref)
    {
      if(wantarray)
      {
        return %$value if $ref eq 'HASH';
        return @$value if $ref eq 'ARRAY'; 
      }
      return $obj if $obj;
      $value = $value->execute if eval { $value->can('execute') };
    }
    $value;
  };
  do { no strict 'refs'; *{ $invocant . "::$called" } = $sub };
  $sub->($self);
}


package Clustericious::Config::Callback;

use JSON::MaybeXS qw( encode_json );

sub new
{
  my($class, @args) = @_;
  bless [@args], $class;
}

sub args { @{ shift() } }

sub execute { '' }

sub to_yaml
{
  my($self) = @_;
  "!!perl/array:@{[ ref $self ]} @{[ encode_json [@$self] ]}";
}

package Clustericious::Config::Callback::Password;

use base qw( Clustericious::Config::Callback );

sub execute
{
  state $pass;
  $pass //= do { require Term::Prompt; Term::Prompt::prompt('p', 'Password:', '', '') };
  $pass;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Config - Configuration files for Clustericious nodes.

=head1 VERSION

version 1.29

=head1 SYNOPSIS

In your ~/etc/MyApp.conf file:

 ---
 % extends_config 'global';
 % extends_config 'hypnotoad', url => 'http://localhost:9999', app => 'MyApp';

 url : http://localhost:9999
 start_mode : hypnotoad
 hypnotoad :
   - heartbeat_timeout : 500
 
 arbitrary_key: value

In your ~/etc/globa.conf file:

 ---
 somevar : somevalue

In your ~/etc/hypnotoad.conf:

 listen :
   - <%= $url %>
 # home uses ~ to find the calling users'
 # home directory
 pid_file : <%= home %>/<%= $app %>/hypnotoad.pid
 env :
   MOJO_HOME : <%= home %>/<%= $app %>

From a L<Clustericious::App>:

 package MyApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 package MyApp::Routes;
 
 use Clustericious::RouteBuilder;
 
 get '/' => sub {
   my $c = shift;
   my $config = $c; # $config isa Clustericious::Config
   
   # returns the value if it is defined, foo otherwise
   my $value1 = $config->arbitrary_key1(default => 'foo');
   
   # returns the value if it is defined, bar otherwise
   # code reference is only called if the value is NOT
   # defined
   my $value2 = $config->arbitrary_key2(default => sub { 'bar' });
 };

From a script:

 use Clustericious::Config;
 
 my $c = Clustericious::Config->new("MyApp");
 my $c = Clustericious::Config->new( \%config_data_structure );

 print $c->url;
 print $c->{url};

 print $c->hypnotoad->listen;
 print $c->hypnotoad->{listen};
 my %hash = $c->hypnotoad;
 my @ary  = $c->hypnotoad;

 # Supply a default value for a missing configuration parameter :
 $c->url(default => "http://localhost:9999");
 print $c->this_param_is_missing(default => "something_else");

=head1 DESCRIPTION

Clustericious::Config reads configuration files which are Mojo::Template's
of JSON or YAML files.  There should generally be an entry for
'url', which may be used by either a client or a server depending on
how this node in the cluster is being used.

After rendering the template and parsing the JSON, the resulting
object may be called using method calls or treated as hashes.

Config files are looked for in the following places (in order, where
"MyApp" is the name of the app) :

 $CLUSTERICIOUS_CONF_DIR/MyApp.conf
 $HOME/etc/MyApp.conf
 /etc/MyApp.conf

The helper "extends_config" may be used to read default settings
from another config file.  The first argument to extends_config is the
basename of the config file.  Additional named arguments may be passed
to that config file and used as variables within that file.  After
reading another file, the hashes are merged (i.e. with Hash::Merge);
so values anywhere inside the data structure may be overridden.

YAML config files must begin with "---", otherwise they are interpreted
as JSON.

This module provides a number of helpers
which can be used to get system details (such as the home directory of
the calling user or to prompt for passwords).  See L<Clustericious::Config::Helpers>
for details.

=head1 CONSTRUCTOR

=head2 new

Create a new Clustericious::Config object.  See the SYNOPSIS for
possible invocations.

=head1 CAVEATS

Some filesystems do not support filenames with a colon (:) character in 
them, so for applications with a double colon in them (for example 
L<Clustericious::HelloWorld>), a single dash character will be 
substituted for the name (for example C<Clustericious-HelloWorld.conf>).

L<Clustericious::Config> uses C<AUTOLOAD> to perform its magic, so some 
configuration keys that are reserved by Perl cannot be used.  Notably 
C<new>, C<can>, C<isa>, etc.

=head1 SEE ALSO

L<Mojo::Template>, L<Hash::Merge>, L<Clustericious>, L<Clustericious::Client>, L<Clustericious::Config::Helpers>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
