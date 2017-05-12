use strict;
use warnings;
use autodie;
use Data::FlexSerializer;
use Storable qw/nfreeze thaw/;
use Compress::Zlib qw(Z_DEFAULT_COMPRESSION);
use JSON::XS qw/encode_json decode_json/;
use Sereal::Encoder qw(encode_sereal);
use Test::More;
use File::Spec;

BEGIN {
  unshift @INC, -d 't' ? File::Spec->catdir(qw(t lib)) : 'lib';
}
use Data::FlexSerializer::EmptySubclass;

foreach my $class ('Data::FlexSerializer', 'Data::FlexSerializer::EmptySubclass') {

  # Test default settings
  my $default_szer = $class->new();
  isa_ok($default_szer, $class);
  my %defaults = (
    assume_compression => 1,
    detect_compression => 0,
    compress_output => 1,
    compression_level => undef,
    detect_storable => 0,
    output_format => 'json',
    detect_sereal => 0,
  );
  foreach my $setting (sort keys %defaults) {
    is($default_szer->$setting, $defaults{$setting}, "defaults for $setting");
  }

  # Test constructor coercion cases
  for my $output_format (qw(json storable JSON STORABLE jSON stORABLE sereal Sereal sEreal)) {
      my $object = $class->new(output_format => $output_format);
      isa_ok($object, $class, "We can construct with output_format => $output_format");
      cmp_ok($object->output_format, 'eq', lc $output_format, "Once constructed the output_format is normalized");
  }

  # Test insane construction arguments
  {
      local $@;
      my $error = '';
      eval {
          $class->new(
              assume_compression => 1,
              detect_compression => 1,
          );
          1;
      } or do {
          $error = $@;
      };
      ok($error, "We got an error with assume_compression and detect_compression passed to the constructor: $error");
  }
  {
      local $@;
      my $error = '';
      eval {
          $class->new;
          $class->output_format('sereal');
          1;
      } or do {
          $error = $@;
      };
      ok($error, "We can't set the output format at runtime: $error");
  }
  for my $method (qw(detect_json detect_storable detect_sereal)) {
      local $@;
      my $error = '';
      eval {
          $class->new;
          $class->$method(1);
          1;
      } or do {
          $error = $@;
      };
      ok($error, "We can't call $method after construction: $error");
  }

  # check whether assume_compression is turned off implicitly if detect_compression is set
  SCOPE: {
    my %opt = %defaults;
    delete $opt{assume_compression};
    $opt{detect_compression} = 1;
    my $s = $class->new(%opt);
    ok(!$s->assume_compression, "detect_compression implies assume_compression==0");
  }

  my %opt_no_compress = (
    assume_compression => 0,
    detect_compression => 0,
    compress_output => 0,
  );
  my %opt_accept_compress = (
    assume_compression => 0,
    detect_compression => 1,
    compress_output => 0,
  );
  my %opt_flex_in = (
    %opt_accept_compress,
    detect_storable => 1,
    detect_sereal => 1,
  );
  my %opt_storable = (
    output_format => 'storable',
    detect_storable => 1,
  );
  my %opt_sereal = (
    output_format => 'sereal',
    detect_sereal => 1,
  );

  my %serializers = (
    default => $default_szer,
    json_compress => $default_szer,
    json_no_compress => $class->new(%opt_no_compress),
    json_flex_compress => $class->new(%opt_accept_compress, compress_output => 1),
    # Accept everything
    flex_compress => $class->new(detect_storable => 1, detect_sereal => 1, compress_output => 1),
    flex_no_compress => $class->new(%opt_flex_in, %opt_no_compress),
    flex_flex_compress => $class->new(%opt_flex_in),
    # Storable
    s_compress => $class->new(%opt_storable),
    s_no_compress => $class->new(%opt_storable, %opt_no_compress),
    s_flex_compress => $class->new(%opt_storable, %opt_accept_compress, compress_output => 1),
    # Sereal
    sereal_compress => $class->new(%opt_sereal),
    sereal_no_compress => $class->new(%opt_sereal, %opt_no_compress),
    sereal_flex_compress => $class->new(%opt_sereal, %opt_accept_compress, compress_output => 1),
  );

  isa_ok($serializers{$_}, $class, 'Serializer for "$_"') for sort keys %serializers;

  my %data = (
    raw => {foo => 'bar', baz => [2, 3, 4]},
    garbage => 'asdkj2qdal2djalkd',
  );
  $data{storable} = nfreeze($data{raw});
  $data{json} = encode_json($data{raw});
  $data{sereal} = encode_sereal($data{raw});
  $data{comp_json} = Compress::Zlib::compress(\$data{json}, Z_DEFAULT_COMPRESSION);
  $data{comp_storable} = Compress::Zlib::compress(\$data{storable}, Z_DEFAULT_COMPRESSION);
  $data{comp_sereal} = Compress::Zlib::compress(\$data{sereal}, Z_DEFAULT_COMPRESSION);
  $data{comp_garbage} = Compress::Zlib::compress(\$data{garbage}, Z_DEFAULT_COMPRESSION); # dubious

  # assert that serialize and deserialize die if called in scalar context and
  # passed multiple args:
  ok(
    not(eval {my $x = $serializers{flex_flex_compress}->serialize([], {}); 1}),
    "serialize dies if called in scalar context with multiple arguments"
  );
  ok(
    not(eval {my $x = $serializers{flex_flex_compress}->deserialize(@data{qw(json storable)}); 1}),
    "deserialize dies if called in scalar context with multiple arguments"
  );

  # input is implied to be the raw data on serialization, output listed
  my %results_serialize = (
    'default' => 'comp_json',
    'json_compress' => 'comp_json',
    'json_no_compress' => 'json',
    'json_flex_compress' => 'comp_json',
    'flex_compress' => 'comp_json',
    'flex_no_compress' => 'json',
    'flex_flex_compress' => 'json',
    # Storable
    's_compress' => 'comp_storable',
    's_no_compress' => 'storable',
    's_flex_compress' => 'comp_storable',
    # Sereal
    'sereal_compress' => 'comp_sereal',
    'sereal_no_compress' => 'sereal',
    'sereal_flex_compress' => 'comp_sereal',
  );
  foreach my $s_name (sort keys %results_serialize) {
    my $serializer = $serializers{$s_name} or die "We don't have '\$serializers{$s_name}'";
    my $is_sereal = $s_name =~ /sereal/;
    my $data = $data{raw}; # always raw input for serialization
    my $tname = "serialization with $s_name";
    my $res;
    my @res;
    eval {$res = $serializer->serialize($data); 1} && defined $res
      ? pass("$tname in scalar context does not crash and returns non-undef")
      : fail("$tname in scalar context throws exception or results in undef");
    
    eval {@res = $serializer->serialize($data); 1} && @res == 1 && defined($res[0])
      ? pass("$tname in array context does not crash and returns non-undef")
      : fail("$tname in array context throws exception or results in undef");

    is($res, $res[0], "$tname same result in array and scalar context");

    # test actual output
    my $expected_output = $data{ $results_serialize{$s_name} } or die "We don't have \$results_serialize{$s_name}";
    TODO: {
      local $TODO = $is_sereal ? "Different serialized strings are OK if they decode to the same results" : undef;
      is($res, $expected_output, "$tname output as expected");
    }

    # Test that we either serialize or don't serialize plain SvPV's
    my $eval_died = not eval {
      $res = $serializer->serialize($data{garbage});
      1;
    };
    if ($is_sereal) {
      ok(!$eval_died, "Under Sereal we support serializing plain SvPV");
    } else {
      ok($eval_died, "We should die under Storable and JSON when fed a plain SvPV");
    }
  }

  # maps input => expected output for each serializer.
  # \undef output means exception
  my %results_deserialize = (
    'default' => {
      'comp_json' => 'raw',
      (map {$_ => \undef} qw(json storable comp_storable garbage)),
    },
    'json_compress' => {
      'comp_json' => 'raw',
      (map {$_ => \undef} qw(json storable comp_storable garbage)),
    },
    'json_no_compress' => {
      'json' => 'raw',
      (map {$_ => \undef} qw(comp_json storable comp_storable garbage)),
    },
    'json_flex_compress' => {
      (map {$_ => 'raw'} qw(comp_json json)),
      (map {$_ => \undef} qw(storable comp_storable garbage)),
    },
    'flex_compress' => {
      (map {$_ => 'raw'} qw(comp_json comp_storable)),
      (map {$_ => \undef} qw(storable json garbage)),
    },
    'flex_no_compress' => {
      (map {$_ => 'raw'} qw(json storable)),
      (map {$_ => \undef} qw(comp_json comp_storable garbage)),
    },
    'flex_flex_compress' => {
      (map {$_ => 'raw'} qw(json comp_json storable comp_storable)),
      (map {$_ => \undef} qw(garbage)),
    },
    's_compress' => {
      (map {$_ => 'raw'} qw(comp_json comp_storable)),
      (map {$_ => \undef} qw(json storable garbage)),
    },
    's_no_compress' => {
      (map {$_ => 'raw'} qw(json storable)),
      (map {$_ => \undef} qw(comp_json comp_storable garbage)),
    },
    's_flex_compress' => {
      (map {$_ => 'raw'} qw(comp_json comp_storable json storable)),
      (map {$_ => \undef} qw(garbage)),
    },
    'sereal_compress' => {
      (map {$_ => 'raw'} qw(comp_json comp_sereal)),
      (map {$_ => \undef} qw(json sereal garbage)),
    },
    'sereal_no_compress' => {
      (map {$_ => 'raw'} qw(json sereal)),
      (map {$_ => \undef} qw(comp_json comp_sereal garbage)),
    },
    'sereal_flex_compress' => {
      (map {$_ => 'raw'} qw(comp_json comp_sereal json sereal)),
      (map {$_ => \undef} qw(garbage)),
    },
  );

  foreach my $s_name (sort keys %results_deserialize) {
    my $serializer = $serializers{$s_name} or die;
    my $testset = $results_deserialize{$s_name};

    foreach my $input_data_name (sort keys %$testset) {
      my $exp_out = $testset->{$input_data_name};
      my $input_data = $data{$input_data_name};
      my $tname = "deserialization with $s_name for input '$input_data_name'";

      my $res;
      my @res;
      if (ref $exp_out && not defined $$exp_out) { # exception expected
        ok(not eval {$res = $serializer->deserialize($input_data); 1} );
        ok(not eval {@res = $serializer->deserialize($input_data); 1} );
      }
      else {
        $exp_out = $data{$exp_out};
        eval {$res = $serializer->deserialize($input_data); 1} && defined $res
          ? pass("$tname in scalar context does not crash and returns non-undef")
          : fail("$tname in scalar context throws exception or results in undef");
        is_deeply($res, $exp_out, "$tname in scalar context yields correct result");

        eval {@res = $serializer->deserialize($input_data); 1} && @res == 1 && defined($res[0])
          ? pass("$tname in array context does not crash and returns non-undef")
          : fail("$tname in array context throws exception or results in undef");
        is_deeply($res[0], $exp_out, "$tname in array context yields correct result");
      }
    }
  }
}

# TODO test file read/write logic
# TODO test debugging facilities

done_testing();
