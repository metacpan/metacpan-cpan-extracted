package Ace::Browser::SiteDefs;

=head1 NAME

Ace::Browser::SiteDefs - Access to AceBrowser configuration files

=head1 SYNOPSIS

  use Ace;
  use Ace::Browser::AceSubs;
  use CGI qw(:standard);

  my $configuration = Configuration;
  my $docroot  = $configuration->Docroot;
  my @pictures = @{$configuration->Pictures};
  my %displays = %{$configuration->Displays};
  my $coderef  = $configuration->Url_mapper;
  $coderef->($param1,$param2);

=head1 DESCRIPTION

Ace::Browser::SiteDefs evaluates an AceBrowser configuration file and
returns a configuration object ("config object" for short).  A config
object is a bag of dynamically-generated methods, derived from the
scalar variables, arrays, hashes and subroutines in the configuration
file.

The config object methods are a canonicalized form of the
configuration file variables, in which the first character of the
method is uppercase, and subsequent characters are lower case.  For
example, if the configuration variable was $ROOT, the method will be
$config_object->Root.

=head2 Working with Configuration Objects

To fetch a configuration object, use the Ace::Browser::AceSubs
Configuration() function.  This will return a configuration object for 
the current database:

  $config_object = Configuration();

Thereafter, it's just a matter of making the proper method calls.

   If the Configuration file is a....    The method call returns a...
   ----------------------------------    ----------------------------

   Scalar variable                       Scalar
   Array variable                        Array reference
   Hash variable                         Hash reference
   Subroutine                            Code reference

If a variable is not defined, the corresponding method will return undef.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Object>, L<Ace::Browser::AceSubs>, L<Ace::Browsr::SearchSubs>, 
the README.ACEBROWSER file.

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use CGI();
use Ace();

use strict;
use Carp;
use vars qw($AUTOLOAD);

# get location of configuration file
use Ace::Browser::LocalSiteDefs '$SITE_DEFS';

my %CONFIG;
my %CACHETIME;
my %CACHED;

sub getConfig {
  my $package = shift;
  my $name    = shift;
  croak "Usage: getConfig(\$database_name)" unless defined $name;
  $package = ref $package if ref $package;
  my $file    = "${name}.pm";

  # make search relative to SiteDefs.pm file
  my $path = $package->get_config || $package->resolveConf($file);

  return unless -r $path;
  return $CONFIG{$name} if exists $CONFIG{$name} and $CACHETIME{$name} >= (stat($path))[9];
  return unless $CONFIG{$name} = $package->_load($path);
  $CONFIG{$name}->{'name'} ||= $name;  # remember name
  $CACHETIME{$name} = (stat($path))[9];
  return $CONFIG{$name};
}

sub modtime {
  my $package = shift;
  my $name = shift;
  if (!$name && ref($package)) {
    $name = $package->Name;
  }
  return $CACHETIME{$name};
}

sub AUTOLOAD {
    my($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
    my $self = shift;
    croak "Unknown field \"$func_name\"" unless $func_name =~ /^[A-Z]/;
    return $self->{$func_name} = $_[0] if defined $_[0];
    return $self->{$func_name} if defined $self->{$func_name};
    # didn't find it, so get default
    return if (my $dflt = $pack->getConfig('default')) == $self;
    return $dflt->{$func_name};
}

sub DESTROY { }

sub map_url {
  my $self = shift;
  my ($display,$name,$class) = @_;
  $class ||= $name->class if ref($name) and $name->can('class');

  my (@result,$url);

  if (my $code = $self->Url_mapper) {
    if (@result = $code->($display,$name,$class)) {
      return @result;
    }
  }

  # if we get here, then take the first display
  my @displays = $self->displays($class,$name);
  push @displays,$self->displays('default') unless @displays;
  my $n = CGI::escape($name);
  my $c = CGI::escape($class);
  return ($displays[0],"name=$n;class=$c") if $displays[0];

  return unless @result = $self->getConfig('default')->Url_mapper->($display,$name,$class);
  return unless $url = $self->display($result[0],'url');
  return ($url,$result[1]);
}

sub searches {
  my $self = shift;
  return unless my $s = $self->Searches;
  return @{$s} unless defined $_[0];
  return $self->Search_titles->{$_[0]};
}

# displays()                   => list of display names
# displays($name)              => hash reference for display
# displays($name=>$field)      => displays at {field}
sub display {
  my $self = shift;
  return unless my $d = $self->Displays;
  return keys %{$d}     unless defined $_[0];
  return                unless exists $d->{$_[0]}; 
  return $d->{$_[0]}    unless defined $_[1];
  return $d->{$_[0]}{$_[1]};
}

sub displays {
  my $self = shift;
  return unless my $d = $self->Classes;
  return keys %$d unless @_;

  my ($class,$name) = @_;
  my $type = ucfirst(lc($class));
  return  unless exists $d->{$type};
  my $value = $d->{$type};
  if (ref $value eq 'CODE') { # oh, wow, a subroutine
    my @v = $value->($type,$name);  # invoke to get list of displays
    return wantarray ? @v : \@v;
  } else {
    return  wantarray ? @{$value} : $value;
  }
}

sub class2displays {
  my $self = shift;
  my ($class,$name) = @_;

  # No class specified.  Return name of all defined classes.
  return $self->displays unless defined $class;

  # A class is specified.  Map it into the list of display records.
  my @displays = map {$self->display($_)} $self->displays($class,$name);
  return @displays;
}

sub _load {
  my $package = shift;
  my $file    = shift;
  no strict 'vars';
  no strict 'refs';

  $file =~ m!([/a-zA-Z0-9._-]+)!;
  my $safe = $1;

  (my $ns = $safe) =~ s/\W/_/g;
  my $namespace = __PACKAGE__ . '::Config::' . $ns;
  unless (eval "package $namespace; require '$safe';") {
    die "compile error while parsing config file '$safe': $@\n";
  }
  # build the object up from the values compiled into the $namespace area
  my %data;

  # get the scalars
  local *symbol;
  foreach (keys %{"${namespace}::"}) {
    *symbol = ${"${namespace}::"}{$_};
    $data{ucfirst(lc $_)} = $symbol if defined($symbol);
    $data{ucfirst(lc $_)} = \%symbol if defined(%symbol);
    $data{ucfirst(lc $_)} = \@symbol if defined(@symbol);
    $data{ucfirst(lc $_)} = \&symbol if defined(&symbol);
    undef *symbol unless defined &symbol;  # conserve  some memory
  }

  # special case: get the search scripts as both an array and as a hash
  if (my @searches = @{"$namespace\:\:SEARCHES"}) {
    $data{Searches} = [ @searches[map {2*$_} (0..@searches/2-1)] ];
    %{$data{Search_titles}} = @searches;
  }

  # return this thing as a blessed object
  return bless \%data,$package;
}

sub resolvePath {
  my $self = shift;
  my $file = shift;
  my $root = $self->Root || '/cgi-bin';
  return "$root/$file";
}

sub resolveConf {
  my $pack = shift;
  my $file = shift;

  unless ($SITE_DEFS) {
    (my $rpath = __PACKAGE__) =~ s{::}{/}g;
    my $path = $INC{"${rpath}.pm"} 
      || warn "Unexpected error: can't locate acebrowser SiteDefs.pm file";
    $path =~ s![^/]*$!!;  # trim to directory
    $SITE_DEFS = $path;
  }
  return "$SITE_DEFS/$file";
}

sub get_config {
  my $pack = shift;

  return unless exists $ENV{MOD_PERL};
  my $r    = Apache->request;
  return $r->dir_config('AceBrowserConf');
}

sub Name {
  Ace::Browser::AceSubs->get_symbolic();
}

1;
