## Copyright (c) 2000, 2001
## Carnegie Mellon University Sphinx Group, Kevin A. Lenzo, Alan W Black
## This software is available under the same terms as Perl itself.
## Thanks much to Martijn van Beers (LotR)

=head1 NAME

Class::MethodMapper - Abstract Class wrapper for AutoLoader

=head1 SYNOPSIS

  BEGIN {
    @MMDerived::ISA = qw(Class::MethodMapper 
                                  Exporter AutoLoader); 
  }

  sub new { 
    my $class = shift;
    my @args = @_;

    my $self = Class::MethodMapper->new();
    bless $self, $class;

    my %map = (
      'time_style' => {
        'type'  => 'parameter', 
        'doc'   => 'How recording duration is decided',
        'domain' => 'enum',
        'options' => [qw(track prompt fixed click_stop deadman)],
        'value' => 'prompt',
      },

      'iter_plan' => {
        'type'  => 'volatile',
        'doc'   => 'Currently active plan for iteration: perl code.',
        'value' => 'play; color("yellow"); hold(0.75); color("red"); '
                     . 'record; color;' ,  # see FestVox::ScriptLang 

      },
    );

    $self->set_map(%map);  
    $self->set(@args) if @args;
    $self;
  }

=head1 DESCRIPTION

Class::MethodMapper takes a hash of hashes and creates 
get() and set() methods, with (some) validation, for the
maps listed.  Generally, a C<parameter> is something that
can be saved and restored, whereas a C<volatile> is not
serialized at save-time.

=cut


package Class::MethodMapper;
$Class::MethodMapper::VERSION = "1.0";
use strict;

use Exporter;
use AutoLoader;
use English;
use Cwd;
use Sys::Hostname;
use UNIVERSAL qw(isa);
use IO::File;
use Data::Dumper;

BEGIN {
  @MethodMapper::ISA = qw(Exporter AutoLoader); 
}

=head1 CONSTRUCTORS

=over 4

=item new(@args)

Creates and initializes an empty Class::MethodMapper. 
Calls C<set()> with its arguments.

=back

=head1 BUILT-IN METHODS

=over 4

=cut

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  
  $self->set(@_) if @_;

  return $self;
}

sub clone {
  my $self = shift;

  my %map = ($self->get_map('parameter'), $self->get_map('volatile'));
  foreach my $key (keys %map) {
    my $foo = {value => $map{$key}};
    my $type = $self->get_meta ('type', $key);
    $type && ($foo->{type} = $type);
    my $doc = $self->get_meta ('doc', $key);
    $doc && ($foo->{doc} = $doc);
    my $domain = $self->get_meta ('domain', $key);
    $domain && ($foo->{domain} = $domain);
    my $options = $self->get_meta ('options', $key);
    $options && ($foo->{options} = $options);
    $map{$key} = $foo;
  }
  my $new = new Class::MethodMapper;
  bless $new, ref ($self);
  $new->set_map (%map);
  $new->set (@_) if @_;
  return $new;
}

=item set_map(%map)

Sets the complete map for this object.  See FestVox::InitMap
for a good example of a method map; it is the big one that
FestVox::PointyClicky itself uses.  This should be generalized
to let you set B<which> map, as C<get_map()> below.

=cut

sub set_map {
  my $self = shift;
  my %map  = @_;

  for my $k (keys %map) {
    $self->{$k} = $map{$k};
  }
  $self;
}

=item get_map($type)

Get the map of a particular type, e.g. C<parameter>.  Note
that the object itself is the top-level (complete) map,
since Class::MethodMapper writes into variables in the object
of the same name; the 'map' itself is just the variables
of that C<type>.

=cut

sub get_map {
  my $self = shift;
  my $type  = shift;
  my %map;

  for my $var (grep $self->{$_}->{type} eq $type, keys %$self) {
    # bare metal here since it'll be called all the time.
    $map{$var} = $self->{$var}->{value};
  }
  %map;
}

=item delete_map(@mapnames)

Delete the mapping for each variable in C<@mapnames>.

=cut

sub delete_map {
  my $self = shift;
  while (my $k = shift) {
    delete $self->{$k};
  }
  $self;
}

=item get_meta('type', 'var')

Get the C<meta> data of a given type for a named variable
in th method map.  

  type     e.g. 'volatile', 'parameter'
  doc      some human-readable string do describe this
  value    current value; useful for initialization
  domain   e.g. 'enum' or 'ref'
  options  if domain is 'enum', an array reference of allowed values
           if domain is 'ref', 'ARRAY', 'HASH' or the name of a class.

=cut

sub get_meta {
  my $self = shift;
  my $what = shift;
  my $method = shift;
  if (defined $self->{$method} 
      and defined $self->{$method}->{$what}) {
    my $it = $self->{$method}->{$what};
    # do something with ARRAY and HASH refs?
    return($it);
  } else {
    undef;
    # warn "$method does't have a meta type $what";
  }
}

=item set_meta('type', 'var', value)

Just what you would think.  Sets the C<meta> variable C<type>
of C<var> to C<value>.

=cut

sub set_meta {
  my $self = shift;
  my $what = shift;
  my $method = shift;
  my $value = shift;
  if (defined $self->{$method}) {
    $self->{$method}->{$what} = $value;
  } else {
    # warn "$method does't have a meta type $what";
  }
  $self;
}


sub _enum_set {
  my ($self, $key, $val) = @_;
  my ($class) = $self =~ /^(.*?)=/g;

  if (defined (my $options = $self->{$key}->{options})) {
    if (grep { $_ eq $val } @$options) {
      $self->{$key}->{value} = $val;
    } else {
      if ($self =~ /^(.*?)=/) {
	my $sane = $options->[0];
	my $o = join ', ', @$options;
	warn "${class}->$key: '$val' is not one of ($o). "
	  . "Using '$sane' instead.\n";
	$self->{$key}->{value} = $sane;
      }
    }
  } else {
    $self->{$key}->{value} = $val;
  }
}

sub _ref_set {
  my ($self, $key, $val) = @_;
  my ($class) = $self =~ /^(.*?)=/g;

  my $ref = $self->{$key}->{options};
  if (isa ($val, $ref)) {
    $self->{$key}->{value} = $val;
  } else {
    warn "${class}->$key: '$val' is not a $ref\-ref. "
      . "Using 'undef' instead.\n";
    $self->{$key}->{value} = undef;
  }
}

=item set('var' => 'value')

Set the variable C<var> to 
the value C<'value'>.  Checks if C<var> is in the method
map, and complains if it is not.  Does basic type checking 
if the C<meta> variable C<domain> is defined.

This means it checks if the value is an element in the array
reference in C<options> if C<domain> is 'enum' and checks if
the value is indeed a reference of the specified type
if C<domain> is 'ref'

=cut

sub set {
  my $self = shift;

  if (@_) {
    my $class;
    if ($self =~ /^(.*?)=/) {
      $class = $1;
    }
	
    while (my $key = shift @_) {
      my $val = shift @_;
      if (not defined $self->{$key}) {
	my ($p,$f,$l) = caller;
	warn "$class doesn't have a(n) '$key' method [$f line $l]\n"
	    if $class;
      } else {
	no strict 'refs';
	my $domain = $self->{$key}->{domain};
	if ($domain) {
	  my $func = "_$domain\_set";
	  $self->$func ($key, $val);
	} else {
	  $self->{$key}->{value} = $val;
	}
      }
    }
  }
}

=item get('var')

Return the value of 'var' if it is defined and in the
method map.

=cut

sub get {
  my $self = shift;
  my $method = shift;
  my $caller_file = shift;
  my $caller_line = shift;

  if ($self =~ m/^(.*?)=/) {
    my $class = $1;
    
    if (not defined $self->{$method}) {
      warn "MethodMapper: $self Can't AutoLoad instance method $method at $caller_file line $caller_line\n";
      return undef;
    } else {
      if (not defined $self->{$method}->{type}) {
	# warn "Unknown method call $method of type $type at $caller_file line $caller_line\n";
	return undef;
      }
      return $self->{$method}->{value};
    }
  } else {
    warn "MethodMapper: Can't invoke $method on $self at $caller_file line $caller_line\n";
    return undef;
  }
}

sub AUTOLOAD {
  my $self = shift ;

  # for $AUTOLOAD
  no strict 'vars';

  my $method = $AUTOLOAD;
  $method =~ s/^.*:://;

  if (@_) {
    $self->set($method => $_[0]);
  } else {
    my ($p, $file, $line) = caller;
    $self->get($method, $file, $line);
  }
}


sub DESTROY {
  my $self = shift;

  for my $type (keys %$self) {
    for my $param (keys %{$self->{$type}}) {
      undef $self->{$type}->{$param};
    }
  }
  #FIXME: find out what this was for, and how to change it to
  #make it not give warnings on subclasses
  #$self->SUPER::DESTROY;
}

=item save('type', \&callback, @args)

loops over all the keys that have type 'type' and calls

    &$callback ($self, $key, $value, @args);

for each of them, where $key is the value of each key and $value
is the hashref for its value.

=cut

sub save {
    my ($self, $type, $callback, @args) = @_;

    my %copy = $self->get_map($type);
    foreach my $key (keys %copy) {
      &$callback ($self, $key, $self->{$key}, @args);
   }
}

=item save_config ('filename')

saves all 'parameter' type key/value pairs to 'filename'

=cut

sub save_config {
  my $self = shift;
  my $file = shift;

  my $fh = new IO::File (">$file");
  unless (defined $fh) {
    warn "MethodMapper: couldn't save state to $file: $!";
    return 0;
  }

  my $host = Sys::Hostname::hostname;
  my $username = getpwuid($REAL_USER_ID);

  $self =~ /^(.*?)=/;
  my $class = $1;

  print $fh "#\n";
  print $fh "# $class Configuration\n";
  print $fh "# Last modified: $username\@$host ".localtime()."\n";
  print $fh "#\n\n";

  my $cb = sub {
    my ($self, $key, $value) = @_;
    my $v = '';

    if (not defined $value->{value}) {
      $v = '';
    } else {
      $v = $value->{value};
    }

    my $t = sprintf "%-20s", $key;
    print $fh "\n";

    print $fh "# $value->{doc}\n";
    if ($value->{domain} eq 'ref') {
      local $Data::Dumper::Indent = 1;
      local $Data::Dumper::Terse = 1;
      print $fh "$t => ", Data::Dumper->Dump ([$v]);
    } else {
      print $fh "$t => $v\n";
    }
  };

  $self->save ('parameter', $cb);
  print $fh "\n";
  $fh->close;

  return 1;
}

=item (\&callback, @args)

loads earlier saved values of the object keys back by calling

    &$callback ($self, @args);

it expects the callback to return a ($key, $value) list. keeps
looping till the callback function returns an undefined key.

=cut

sub restore {
  my ($self, $callback, @args) = @_;

  while (1) {
    my ($key, $value) = &$callback ($self, @args);
    return unless defined $key;
    if (defined $value) {
      $self->set ($key, $value);
    }
  }
}

=item restore_config ('filename')

loads values from the file 'filename', which is in the format that
save_config writes out.

=cut

sub restore_config {
  my ($self, $file) = @_;
  my $fh = new IO::File ($file);

  unless (defined $fh) {
    warn "MethodMapper: couldn't restore state from $file: $!\n";
    return 0;
  }
  my $cb = sub {
    my ($self) = @_;

    # we only do one var, but we need the while for multiline stuff
    return undef if $fh->eof;
    my ($reffirst, $key, $value);
    while (<$fh>) {
      #my $line = <$fh>;

      unless (/\S/) {
	# try to catch runaway multilines by not allowing them to
	# contain empty lines.
	$reffirst = '';
	next;
      }
      next if /^\#/;    # comment: FIRST char is a # 

      chomp;
      if ($reffirst ne '') {
	my $last = ']' if $reffirst eq '[';
	$last = '}' if $reffirst eq '{';
	my $line = $_;
	$line =~ s/^\s+/ /;
	$value .= $line;
	next unless /^$last$/;
	return ($key, eval ($value));
	$reffirst = '';
      }
      ($key, $value) = split /\s+=>\s+/, $_, 2;
      if (defined $key) {
	if ($self->{$key}->{domain} eq 'ref') {
	  if ($value eq '[' or $value eq '{') {
	    $reffirst = $value;
	  }
	} else {
	  return ($key, $value);
	}
      }
    }
  };

  $self->restore ($cb);
  close $fh;

  return 1;
}


1;
__END__

=item var()

C<var> itself is promoted to method status; if given no
argument, it is considered a C<get()>, and if given 
argument(s), it is considered a C<set()>.  Thus, if you
had a parameter called C<active> in the method map, 
Class::MethodMapper would use AutoLoader to create a C<active()>
method (if ever called), so that C<$self->active> would
return the current value, and C<$self->active(1)> would
set it to C<1>.

=back

=head1 BUGS

Terribly underdocumented.

=head1 AUTHOR

Copyright (c) 2000 Kevin A. Lenzo and Alan W Black, Carnegie 
Mellon Unversity.
