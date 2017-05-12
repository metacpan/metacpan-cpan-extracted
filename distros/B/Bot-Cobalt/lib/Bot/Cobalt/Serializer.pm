package Bot::Cobalt::Serializer;
$Bot::Cobalt::Serializer::VERSION = '0.021003';
use strictures 2;
use Carp;
use Scalar::Util 'reftype';

## These two must be present anyway:
use YAML::XS ();
use JSON::MaybeXS ();

use Fcntl ':flock';
use Time::HiRes  'sleep';
use Scalar::Util 'blessed';

use Bot::Cobalt::Common ':types';

use Moo;


has Format => (
  is        => 'rw',
  isa       => Str,
  builder   => sub { 'YAMLXS' },
  trigger   => sub {
    my ($self, $format) = @_;
    $format = uc($format);
    confess "Unknown format $format"
      unless grep { $_ eq $format } keys %{ $self->_types };
    confess "Requested format $format but can't find a module for it"
      unless $self->_check_if_avail($format)
  },
);

has _types => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashRef,
  builder   => sub {
    +{
      YAML   => 'YAML::Syck',
      YAMLXS => 'YAML::XS',
      JSON   => 'JSON::MaybeXS',
    }
  },
);

has yamlxs_from_ref => (
  is        => 'rw',
  lazy      => 1,
  coerce    => sub { YAML::XS::Dump($_[0]) },
);

has ref_from_yamlxs => (
  is        => 'rw',
  lazy      => 1,
  coerce    => sub { YAML::XS::Load($_[0]) },
);

has yaml_from_ref => (
  is        => 'rw',
  lazy      => 1,
  coerce    => sub { require YAML::Syck; YAML::Syck::Dump($_[0]) },
);

has ref_from_yaml => (
  is        => 'rw',
  lazy      => 1,
  coerce    => sub { require YAML::Syck; YAML::Syck::Load($_[0]) },
);

has json_from_ref => (
  is        => 'rw',
  lazy      => 1,
  coerce    => sub {
    my $jsify = JSON::MaybeXS->new(
      utf8 => 1, allow_nonref => 1, convert_blessed => 1
    );
    $jsify->utf8->encode($_[0]);
  },
);

has ref_from_json => (
  is        => 'rw',
  lazy      => 1,
  coerce => sub {
    my $jsify = JSON::MaybeXS->new(
      utf8 => 1, allow_nonref => 1
    );
    $jsify->utf8->decode($_[0])
  },
);


sub BUILDARGS {
  my ($class, @args) = @_;
  ## my $serializer = Bot::Cobalt::Serializer->new( %opts )
  ## Serialize to YAML using YAML::XS:
  ## ->new()
  ## - or -
  ## ->new($format)
  ## ->new('JSON')  # f.ex
  ## - or -
  ## ->new( Format => 'JSON' )   ## --> to JSON
  ## - or -
  ## ->new( Format => 'YAML' ) ## --> to YAML1.0
  @args == 1 ? { Format => $args[0] } : { @args }
}

sub freeze {
  ## ->freeze($ref)
  my ($self, $ref) = @_;
  unless (defined $ref) {
    carp "freeze() received no data";
    return
  }

  my $method = lc( $self->Format );
  $method = $method . "_from_ref";

  $self->$method($ref)
}

sub thaw {
  ## ->thaw($data)
  my ($self, $data) = @_;
  unless (defined $data) {
    carp "thaw() received no data";
    return
  }

  my $method = lc( $self->Format );
  $method = "ref_from_" . $method ;

  $self->$method($data)
}

sub writefile {
  my ($self, $path, $ref, $opts) = @_;
  ## $serializer->writefile($path, $ref [, { Opts });

  if (!$path) {
    confess "writefile called without path argument"
  } elsif (!defined $ref) {
    confess "writefile called without data to serialize"
  }

  my $frozen = $self->freeze($ref);

  $self->_write_serialized($path, $frozen, $opts)
}

sub readfile {
  my ($self, $path, $opts) = @_;
  ## my $ref = $serializer->readfile($path)

  if (!$path) {
    confess "readfile called without path argument";
  } elsif (!-e $path ) {
    confess "readfile called on nonexistant file $path";
  }

  my $data = $self->_read_serialized($path, $opts);

  $self->thaw($data)
}

sub version {
  my ($self) = @_;

  my $module = $self->_types->{ $self->Format };
  { local $@; eval "require $module" }
  return($module, $module->VERSION);
}



sub _check_if_avail {
  my ($self, $type) = @_;

  my $module;
  return unless $module = $self->_types->{$type};

  {
    local $@;
    eval "require $module";
    return if $@;
  }

  return $module
}


sub _read_serialized {
  my ($self, $path, $opts) = @_;
  return unless defined $path;

  my $lock = 1;
  if (defined $opts && ref $opts && reftype $opts eq 'HASH') {
    $lock = $opts->{Locking} if defined $opts->{Locking};
  }

  if (blessed $path && $path->can('slurp_utf8')) {
    return $path->slurp_utf8
  } else {
    open(my $in_fh, '<:encoding(UTF-8)', $path)
      or confess "open failed for $path: $!";

    if ($lock) {
      flock($in_fh, LOCK_SH)
        or confess "LOCK_SH failed for $path: $!";
     }

    my $data = join '', <$in_fh>;

    flock($in_fh, LOCK_UN) if $lock;

    close($in_fh)
      or carp "close failed for $path: $!";

    return $data
  }
}

sub _write_serialized {
  my ($self, $path, $data, $opts) = @_;
  return unless $path and defined $data;

  my $lock    = 1;
  my $timeout = 2;

  if (defined $opts && ref $opts && reftype $opts eq 'HASH') {
    $lock    = $opts->{Locking} if defined $opts->{Locking};
    $timeout = $opts->{Timeout} if $opts->{Timeout};
  }

  open(my $out_fh, '>>:encoding(UTF-8)', $path)
    or confess "open failed for $path: $!";

  if ($lock) {
    my $timer = 0;

    until ( flock $out_fh, LOCK_EX | LOCK_NB ) {
      confess "Failed writefile lock ($path), timed out ($timeout)"
        if $timer > $timeout;

      sleep 0.01;
      $timer += 0.01;
    }

  }

  seek($out_fh, 0, 0)
    or confess "seek failed for $path: $!";
  truncate($out_fh, 0)
    or confess "truncate failed for $path";

  print $out_fh $data;

  flock($out_fh, LOCK_UN) if $lock;

  close($out_fh)
    or carp "close failed for $path: $!";

  return 1
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Serializer - Bot::Cobalt serialization wrapper

=head1 SYNOPSIS

  use Bot::Cobalt::Serializer;

  ## Spawn a YAML (1.1) handler:
  my $serializer = Bot::Cobalt::Serializer->new;

  ## Spawn a JSON handler:
  my $serializer = Bot::Cobalt::Serializer->new('JSON');
  ## ...same as:
  my $serializer = Bot::Cobalt::Serializer->new( Format => 'JSON' );

  ## Serialize some data to our Format:
  my $ref = { Stuff => { Things => [ 'a', 'b'] } };
  my $frozen = $serializer->freeze( $ref );

  ## Turn it back into a Perl data structure:
  my $thawed = $serializer->thaw( $frozen );

  ## Serialize some $ref to a file at $path
  ## The file will be overwritten
  ## Returns false on failure
  $serializer->writefile( $path, $ref );

  ## Do the same thing, but without locking
  $serializer->writefile( $path, $ref, { Locking => 0 } );

  ## Turn a serialized file back into a $ref
  ## Boolean false on failure
  my $ref = $serializer->readfile( $path );

  ## Do the same thing, but without locking
  my $ref = $serializer->readfile( $path, { Locking => 0 } );


=head1 DESCRIPTION

Various pieces of L<Bot::Cobalt> need to read and write serialized perl data
from/to disk.
This simple OO frontend makes it trivially easy to work with a selection of
serialization formats, automatically enabling Unicode encode/decode and 
optionally providing the ability to read/write files directly.

Errors will typically throw fatal exceptions (usually with a stack 
trace) via L<Carp/confess> -- you may want to look into L<Try::Tiny> for 
handling them cleanly.

=head1 METHODS

=head2 new

  my $serializer = Bot::Cobalt::Serializer->new;
  my $serializer = Bot::Cobalt::Serializer->new( $format );
  my $serializer = Bot::Cobalt::Serializer->new( %opts );

Spawn a serializer instance. Will croak with a stack trace if you are 
missing the relevant serializer module; see L</Format>, below.

The default is to spawn a B<YAML::XS> (YAML1.1) serializer with error 
logging to C<carp>.

You can spawn an instance using a different Format by passing the name 
of the format as an argument:

  $handle_syck = Bot::Cobalt::Serializer->new('YAML');
  $handle_yaml = Bot::Cobalt::Serializer->new('YAMLXS');
  $handle_json = Bot::Cobalt::Serializer->new('JSON');

=head3 Format

Specify an input and output serialization format; this determines the 
serialization method used by L</writefile>, L</readfile>, L</thaw>, and 
L</freeze> methods. (You can change formats on the fly by calling 
B<Format> as a method.)

Currently available formats are:

=over

=item *

B<YAML> - YAML1.0 via L<YAML::Syck>

=item *

B<YAMLXS> - YAML1.1 via L<YAML::XS>  I<(default)>

=item *

B<JSON> - JSON via L<JSON::MaybeXS>

=back

The default is YAML I<(YAML Ain't Markup Language)> 1.1 (B<YAMLXS>)

YAML is very powerful, and the appearance of the output makes it easy for 
humans to read and edit.

JSON is a more simplistic format, often more suited for network transmission 
and talking to other networked apps. JSON is noticably faster than YAML.

=head2 freeze

Turn the specified reference I<$ref> into the configured B<Format>.

  my $frozen = $serializer->freeze($ref);

Upon success returns a scalar containing the serialized format, suitable for 
saving to disk, transmission, etc.


=head2 thaw

Turn the specified serialized data (stored in a scalar) back into a Perl 
data structure.

  my $ref = $serializer->thaw($data);


(Try L<Data::Dumper> if you're not sure what your data actually looks like.)


=head2 writefile

L</freeze> the specified C<$ref> and write the serialized data to C<$path>

  $serializer->writefile($path, $ref);

Will croak with a stack trace if the specified path/data could not be 
written to disk due to an error.

Locks the file by default; blocks for up to 2 seconds attempting to 
gain a lock. You can turn this behavior off entirely:

  $serializer->writefile($path, $ref, { Locking => 0 });

... or change the lock timeout (defaults to 2 seconds):

  $serializer->writefile($path, $ref,
    { Locking => 1, Timeout => 5 }
  );


=head2 readfile

Read the serialized file at the specified C<$path> (if possible) and 
L</thaw> the data structures back into a reference.

  my $ref = $serializer->readfile($path);

By default, attempts to gain a shared (LOCK_SH) lock on the file in a 
blocking manner.
You can turn this behavior off:

  $serializer->readfile($path, { Locking => 0 });

Will croak with a stack trace if $path cannot be read or deserialized.


=head2 version

Obtains the backend serializer and its VERSION for the current instance.

  my ($module, $modvers) = $serializer->version;

Returns a list of two values: the module name and its version.

  ## via Devel::REPL:
  $ Bot::Cobalt::Serializer->new->version
  $VAR1 = 'YAML::Syck';
  $VAR2 = 1.19;


=head1 SEE ALSO

=over

=item *

L<YAML::Syck> -- YAML1.0: L<http://yaml.org/spec/1.0/>

=item *

L<YAML::XS> -- YAML1.1: L<http://yaml.org/spec/1.1/>

=item *

L<JSON>, L<JSON::MaybeXS> -- JSON: L<http://www.json.org/>

=back


=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
