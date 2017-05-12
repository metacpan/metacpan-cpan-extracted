package Data::FlexSerializer;
use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::Moose qw(ArrayRef HashRef Maybe Bool Int Str Object CodeRef);
use MooseX::Types::Structured qw(Dict Tuple Map);
use MooseX::Types -declare => [ qw(
    FormatHandler
    FormatBool
) ];
use autodie;

our $VERSION = '1.10';

# Get the DEBUG constant from $Data::FlexSerializer::DEBUG or
# $ENV{DATA_FLEXSERIALIZER_DEBUG}
use Constant::FromGlobal DEBUG => { int => 1, default => 0, env => 1 };

use List::Util qw(min);
use Storable qw();
use JSON::XS qw();
use Sereal::Decoder qw();
use Sereal::Encoder qw();
use Compress::Zlib qw(Z_DEFAULT_COMPRESSION);
use IO::Uncompress::AnyInflate qw();
use Carp ();
use Data::Dumper qw(Dumper);

subtype FormatHandler,
  as Dict [
      detect      => CodeRef,
      serialize   => CodeRef,
      deserialize => CodeRef,
  ],
  message { 'A format needs to be passed as an hashref with "serialize", "deserialize" and "detect" keys that point to a coderef to perform the respective action' };

subtype FormatBool,
  as Map[Str, Bool];

coerce FormatBool,
  from ArrayRef,
    via { { map lc $_ => 1, @$_ } },
  from Str,
    via { { lc $_ => 1 } },
;

class_has formats => (
    traits   => ['Hash'],
    is      => 'rw',
    isa     => HashRef[FormatHandler],
    default => sub {
        {
            json => {
                detect      => sub { $_[1] =~ /^(?:\{|\[)/ },
                serialize   => sub { shift; goto \&JSON::XS::encode_json },
                deserialize => sub { shift; goto \&JSON::XS::decode_json },
            },
            storable => {
                detect      => sub { $_[1] =~ s/^pst0// }, # this is not a real detector.
                                                           # It just removes the storable
                                                           # file magic if necessary.
                                                           # Tho' storable needs to be last
                serialize   => sub { shift; goto \&Storable::nfreeze },
                deserialize => sub { shift; goto \&Storable::thaw },
            },
            sereal => {
                detect      => sub { shift->{sereal_decoder}->looks_like_sereal(@_) },
                serialize   => sub { shift->{sereal_encoder}->encode(@_) },
                deserialize => sub { my $structure; shift->{sereal_decoder}->decode($_[0], $structure); $structure },
            },
        }
    },
    handles => {
        add_format        => 'set',
        get_format        => 'get',
        has_format        => 'exists',
        supported_formats => 'keys',
    },
);

has output_format => (
    is      => 'ro',
    isa     => Str,
    default => 'json',
);

has detect_formats => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => FormatBool,
    default => sub { { json => 1, sereal => 0, storable => 0 } },
    coerce  => 1,
    handles => {
        detect_json     => [ get => 'json' ],
        detect_storable => [ get => 'storable' ],
        detect_sereal   => [ get => 'sereal' ],
        _set_detect_json     => [ set => 'json' ],
        _set_detect_storable => [ set => 'storable' ],
        _set_detect_sereal   => [ set => 'sereal' ],
        list_detect_formats  => 'kv',
    }
);

has assume_compression => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has detect_compression => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has compress_output => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has compression_level => (
    is      => 'ro',
    isa     => Maybe[Int],
);

has sereal_encoder => (
    is         => 'ro',
    isa        => Object,
    lazy_build => 1,
);

sub _build_sereal_encoder { Sereal::Encoder->new }

has sereal_decoder => (
    is         => 'ro',
    isa        => Object,
    lazy_build => 1,
);

sub _build_sereal_decoder { Sereal::Decoder->new }

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    # We change the default on assume_compression to "off" if the
    # user sets detect_compression explicitly
    if (exists $args{detect_compression} and
        not exists $args{assume_compression}) {
        $args{assume_compression} = 0;
    }

    if ($args{assume_compression} and $args{detect_compression}) {
        die "Can't assume compression and auto-detect compression at the same time. That makes no sense.";
    }

    my %detect_formats = map {
        exists $args{"detect_$_"} ? ($_ => $args{"detect_$_"}) : ()
    } $class->supported_formats;

    if (%detect_formats) {
        if ($args{detect_formats}) {
            $args{detect_formats} = [ $args{detect_formats} ] unless ref $args{detect_formats};
            if (ref $args{detect_formats} eq 'ARRAY') {
                for my $format (@{$args{detect_formats}}) {
                    die "Can't have $format in detect_formats and detect_$format set to false at the same time"
                      if exists $detect_formats{$format} && !$detect_formats{$format};
                    $detect_formats{$format} = 1;
                }
            } else {
                for my $format (keys %{$args{detect_formats}}) {
                    die "Can't have $format in detect_formats and detect_$format set to false at the same time"
                      if exists $detect_formats{$format}
                      && exists $args{detect_formats}{$format}
                      && $detect_formats{$format} != $args{detect_formats}{$format};
                    $detect_formats{$format} = 1;
                }
            }
        } else {
            $args{detect_formats} = \%detect_formats;
        }
    }

    $args{output_format} = lc $args{output_format} if $args{output_format};

    for my $format (
      ( $args{output_format}  ? $args{output_format}          : () ),
      ( $args{detect_formats} ? keys %{$args{detect_formats}} : () )) {
        die "'$format' is not a supported format" unless $class->has_format($format);
    }

    my $rv = $class->$orig(%args);

    if (DEBUG) {
        warn "Dumping the new FlexSerializer object.\n" . Dumper($rv);
    }

    return $rv;
};

sub BUILD {
    my ($self) = @_;

    # build Sereal::{Decoder,Encoder} objects if necessary
    $self->sereal_decoder if $self->detect_sereal;
    $self->sereal_encoder if $self->output_format eq 'sereal';

    # For legacy reasons json should be on by default
    $self->_set_detect_json(1) unless defined $self->detect_json;

    $self->{serializer_coderef}   = $self->make_serializer;
    $self->{deserializer_coderef} = $self->make_deserializer;

    return;
}

sub serialize   { goto $_[0]->{serializer_coderef} }
sub deserialize { goto $_[0]->{deserializer_coderef} }

sub make_serializer {
    my $self = shift;
    my $compress_output = $self->compress_output;
    my $output_format = $self->output_format;
    my $comp_level;
    $comp_level = $self->compression_level if $compress_output;

    if (DEBUG) {
        warn(sprintf(
            "FlexSerializer using the following options for serialization: "
            . "compress_output=%s, compression_level=%s, output_format=%s",
            map {defined $self->{$_} ? $self->{$_} : '<undef>'}
            qw(compress_output compression_level output_format)
        ));
    }

    {
        no strict 'refs';
        my $class = ref $self;
        *{"$class\::__serialize_$output_format"} =
          $self->get_format($output_format)->{serialize}
            or die "PANIC: unknown output format '$output_format'";
    }

    my $code = "__serialize_$output_format(\$self, \$_)";

    if ($compress_output) {
        my $comp_level_code = defined $comp_level ? $comp_level : 'Z_DEFAULT_COMPRESSION';
        $code = "Compress::Zlib::compress(\\$code,$comp_level_code)";
    }

    $code = sprintf q{
        sub {
          # local *__ANON__= "__ANON__serialize__";
          my $self = shift;

          my @out;
          push @out, %s for @_;

          return wantarray ? @out
               : @out >  1 ? die( sprintf "You have %%d serialized structures, please call this method in list context", scalar @out )
               :            $out[0];

          return @out;
        };
    }, $code;

    warn $code if DEBUG >= 2;

    my $coderef = eval $code or do{
        my $error = $@ || 'Zombie error';
        die "Couldn't create the deserialization coderef: $error\n The code is: $code\n";
    };

    return $coderef;
}

sub make_deserializer {
    my $self = shift;

    my $assume_compression = $self->assume_compression;
    my $detect_compression = $self->detect_compression;

    my %detectors = %{$self->detect_formats};

    # Move storable to the end of the detectors list.
    # We don't know how to detect it.
    delete $detectors{storable} if exists $detectors{storable};
    my @detectors = grep $detectors{$_}, $self->supported_formats;
    push @detectors, 'storable' if $self->detect_storable;

    if (DEBUG) {
        warn "Detectors: @detectors";
        warn("FlexSerializer using the following options for deserialization: ",
            join ', ', (map {defined $self->$_ ? "$_=@{[$self->$_]}" : "$_=<undef>"}
            qw(assume_compression detect_compression)),
            map { "detect_$_->[0]=$_->[1]" } $self->list_detect_formats
        );
    }

    my $uncompress_code;
    if ($assume_compression) {
        $uncompress_code = '
        local $_ = Compress::Zlib::uncompress(\$serialized);
        unless (defined $_) {
            die "You\'ve told me to assume compression but calling uncompress() on your input string returns undef";
        }';
    }
    elsif ($detect_compression) {
        $uncompress_code = '
        local $_;
        my $inflatedok = IO::Uncompress::AnyInflate::anyinflate(\$serialized => \$_);
        warn "FlexSerializer: Detected that the input was " . ($inflatedok ? "" : "not ") . "compressed"
            if DEBUG >= 3;
        $_ = $serialized if not $inflatedok;';
    }
    else {
        warn "FlexSerializer: Not using compression" if DEBUG;
        $uncompress_code = '
        local $_ = $serialized;';
    }

    my $code_detect = q!
        warn "FlexSerializer: %2$s that the input was %1$s" if DEBUG >= 3;
        warn sprintf "FlexSerializer: This was the %1$s input: '%s'",
            substr($_, 0, min(length($_), 100)) if DEBUG >= 3;
        push @out, __deserialize_%1$s($self, $_)!;

    my $detector = '__detect_%1$s($self, $_)';
    my $body     = "\n$code_detect\n    }";

    my $code = @detectors == 1
        # Just one detector => skip the if()else gobbledigook
        ? sprintf $code_detect, $detectors[0], 'Assuming'
        # Multiple detectors
        : join('', map {
              sprintf(
                  ($_ == 0           ? "if ( $detector ) { $body"
                  :$_ == $#detectors ? " else { $detector; $body"
                  :                    " elsif ( $detector ) { $body"),
                  $detectors[$_],
                  ($_ == $#detectors ? 'Assuming' : 'Detected'),
              );
          } 0..$#detectors
        );

    $code = sprintf(q{
        sub {
          # local *__ANON__= "__ANON__deserialize__";
          my $self = shift;

          my @out;
          for my $serialized (@_) {
            %s

            %s
          }

          return wantarray ? @out
               : @out >  1 ? die( sprintf "You have %%d deserialized structures, please call this method in list context", scalar @out )
               :            $out[0];

          return @out;
        };},
        $uncompress_code, $code
    );

    warn $code if DEBUG >= 2;

    # inject the deserializers and detectors in the symbol table
    # before we eval the code.
    for (@detectors) {
        my $class = ref $self;
        no strict 'refs';
        my $format = $self->get_format($_);
        *{"$class\::__deserialize_$_"} = $format->{deserialize};
        *{"$class\::__detect_$_"} = $format->{detect};
    }

    my $coderef = eval $code or do{
        my $error = $@ || 'Clobbed';
        die "Couldn't create the deserialization coderef: $error\n The code is: $code\n";
    };

    return $coderef;
}

sub deserialize_from_file {
    my $self = shift;
    my $file = shift;

    if (not defined $file or not -r $file) {
        Carp::croak("Need filename argument or can't read file");
    }

    open my $fh, '<', $file;
    local $/;
    my $data = <$fh>;
    my ($rv) = $self->deserialize($data);
    return $rv;
}

sub serialize_to_file {
    my $self = shift;
    my $data = shift;
    my $file = shift;

    if (not defined $file) {
        Carp::croak("Need filename argument");
    }

    open my $fh, '>', $file;
    print $fh $self->serialize($data);
    close $fh;

    return 1;
}

sub deserialize_from_fh {
    my $self = shift;
    my $fd = shift;

    if (not defined $fd) {
        Carp::croak("Need file descriptor argument");
    }

    local $/;
    my $data = <$fd>;
    my ($rv) = $self->deserialize($data);

    return $rv;
}

sub serialize_to_fh {
    my $self = shift;
    my $data = shift;
    my $fd = shift;

    if (not defined $fd) {
        Carp::croak("Need file descriptor argument");
    }

    print $fd $self->serialize($data);

    return 1;
}


1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::FlexSerializer - Pluggable (de-)serialization to/from compressed/uncompressed JSON/Storable/Sereal/Whatever

=head1 DESCRIPTION

This module was written to convert away from Storable throughout the
Booking.com codebase to other serialization formats such as Sereal and
JSON.

Since we needed to do these migrations in production we had to do them
with zero downtime and deal with data stored on disk, in memcached or
in a database that we could only gradually migrate to the new format
as we read/wrote it.

So we needed a module that deals with dynamically detecting what kind
of existing serialized data you have, and can dynamically convert it
to something else as it's written again.

That's what this module does. Depending on the options you give it it
can read/write any combination of
B<compressed>/B<uncompressed>/B<maybe compressed>
B<Storable>/B<JSON>/B<Sereal> data. You can also easily extend it to
add support for your own input/output format in addition to the
defaults.

=head1 SYNOPSIS

When we originally wrote this we meant to convert everything over from
Storable to JSON. Since then mostly due to various issues with JSON
not accurately being able to represent Perl datastructures
(e.g. preserve encoding flags) we've started to migrate to
L<Sereal::Encoder|Sereal> (a L<new serialization
format|http://blog.booking.com/sereal-a-binary-data-serialization-format.html>
we wrote) instead.

However the API of this module is now slightly awkward because now it
needs to deal with the possible detection and emission of multiple
formats, and it still uses the JSON format by default which is no
longer the recommended way to use it.

  # For all of the below
  use Data::FlexSerializer;

=head2 Reading and writing compressed JSON

  # We *only* read/write compressed JSON by default:
  my $strict_serializer = Data::FlexSerializer->new;
  my @blobs = $strict_serializer->serialize(@perl_datastructures);
  my @perl_datastructures = $strict_serializer->deserialize(@blobs);

=head2 Reading maybe compressed JSON and writing compressed JSON

  # We can optionally detect compressed JSON as well, will accept
  # mixed compressed/uncompressed data. This works for all the input
  # formats.
  my $lax_serializer = Data::FlexSerializer->new(
    detect_compression => 1,
  );

=head2 Reading definitely compressed JSON and writing compressed JSON

  # If we know that all our data is compressed we can skip the
  # detection step. This works for all the input formats.
  my $lax_compress = Data::FlexSerializer->new(
    assume_compression => 1,
    compress_output => 1, # This is the default
  );

=head2 Migrate from maybe compressed Storable to compressed JSON

  my $storable_to_json = Data::FlexSerializer->new(
    detect_compression => 1, # check whether the input is compressed
    detect_storable => 1, # accept Storable images as input
    compress_output => 1, # This is the default
  );

=head2 Migrate from maybe compressed JSON to Sereal

  my $storable_to_sereal = Data::FlexSerializer->new(
    detect_sereal => 1,
    output_format => 'sereal',
  );

=head2 Migrate from Sereal to JSON

  my $sereal_backcompat = Data::FlexSerializer->new(
    detect_sereal => 1, # accept Sereal images as input
  );

=head2 Migrate from JSON OR Storable to Sereal

  my $flex_to_json = Data::FlexSerializer->new(
    detect_compression => 1,
    detect_json => 1, # this is the default
    detect_sereal => 1,
    detect_storable => 1,
    output_format => 'sereal',
  );

=head2 Migrate from JSON OR Storable to Sereal with custom Sereal objects

  my $flex_to_json = Data::FlexSerializer->new(
    detect_compression => 1,
    detect_json => 1, # this is the default
    detect_sereal => 1,
    detect_storable => 1,
    output_format => 'sereal',
    sereal_decoder => Sereal::Decoder->new(...),
    sereal_encoder => Sereal::Encoder->new(...),
  );

=head2 Add your own format using Data::Dumper.

See L<the documentation for add_format|add_format> below.

=head1 ATTRIBUTES

This is a L<Moose>-powered module so all of these are keys you can
pass to L</new>. They're all read-only after the class is constructed,
so you can look but you can't touch.

=head1 METHODS

=head2 assume_compression

C<assume_compression> is a boolean flag that makes the deserialization
assume that the data will be compressed. It won't have to guess,
making the deserialization faster. Defaults to true.

You almost definitely want to turn L</compress_output> off too if you
turn this off, unless you're doing a one-off migration or something.

=head2 detect_compression

C<detect_compression> is a boolean flag that also affects only the
deserialization step.

If set, it'll auto-detect whether the input is compressed. Mutually
exclusive with C<assume_compression> (we'll die if you try to set
both).

If you set C<detect_compression> we'll disable this for you, since it
doesn't make any sense to try to detect when you're going to assume.

Defaults to false.

=head2 compress_output

C<compress_output> is a flag indicating whether compressed or uncompressed
dumps are to be generated during the serialization. Defaults to true.

You probably to turn L</assume_compression> off too if you turn this
off, unless you're doing a one-off migration or something.

=head2 compression_level

C<compression_level> is an integer indicating the compression level (0-9).

=head2 output_format

C<output_format> can be either set to the string C<json> (default),
C<storable>, C<sereal> or your own format that you've added via L</add_format>.

=head2 detect_FORMAT_NAME

Whether we should detect this incoming format. By default only
C<detect_json> is true. You can also set C<detect_storable>,
C<detect_sereal> or C<detect_YOUR_FORMAT> for formats added via
L</add_format>.

=head2 sereal_encoder

=head2 sereal_decoder

You can supply C<sereal_encoder> or C<sereal_decoder> arguments with
your own Serial decoder/encoder objects. Handy if you want to pass
custom options to the encoder or decoder.

By default we create objects for you at BUILD time. So you don't need
to supply this for optimization purposes either.

=head1 METHODS

=head2 serialize

Given a list of things to serialize, this does the job on each of them and
returns a list of serialized blobs.

In scalar context, this will return a single serialized blob instead of a
list. If called in scalar context, but passed a list of things to serialize,
this will croak because the call makes no sense.

=head2 deserialize

The opposite of C<serialize>, doh.

=head2 deserialize_from_file

Given a (single!) file name, reads the file contents and deserializes them.
Returns the resulting Perl data structure.

Since this works on one file at a time, this doesn't return a list of
data structures like C<deserialize()> does.

=head2 serialize_to_file

  $serializer->serialize_to_file(
    $data_structure => '/tmp/foo/bar'
  );

Given a (single!) Perl data structure, and a (single!) file name,
serializes the data structure and writes the result to the given file.
Returns true on success, dies on failure.

=head1 CLASS METHODS

=head2 add_format

C<add_format> class method to add support for custom formats.

  Data::FlexSerializer->add_format(
      data_dumper => {
          serialize   => sub { shift; goto \&Data::Dumper::Dumper },
          deserialize => sub { shift; my $VAR1; eval "$_[0]" },
          detect      => sub { $_[1] =~ /\$[\w]+\s*=/ },
      }
  );

  my $flex_to_dd = Data::FlexSerializer->new(
    detect_data_dumper => 1,
    output_format => 'data_dumper',
  );

=head1 AUTHOR

Steffen Mueller <smueller@cpan.org>

Ævar Arnfjörð Bjarmason <avar@cpan.org>

Burak Gürsoy <burak@cpan.org>

Elizabeth Matthijsen <liz@dijkmat.nl>

Caio Romão Costa Nascimento <cpan@caioromao.com>

Jonas Galhordas Duarte Alves <jgda@cpan.org>

=head1 ACKNOWLEDGMENT

This module was originally developed at and for Booking.com.
With approval from Booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2011, 2012, 2013 Steffen Mueller and others. All rights reserved.

 This code is available under the same license as Perl version
 5.8.1 or higher.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
