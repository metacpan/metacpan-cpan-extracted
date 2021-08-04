use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/Record/Serialize.pm',
    'lib/Data/Record/Serialize/Encode/dbi.pm',
    'lib/Data/Record/Serialize/Encode/ddump.pm',
    'lib/Data/Record/Serialize/Encode/json.pm',
    'lib/Data/Record/Serialize/Encode/null.pm',
    'lib/Data/Record/Serialize/Encode/rdb.pm',
    'lib/Data/Record/Serialize/Encode/yaml.pm',
    'lib/Data/Record/Serialize/Error.pm',
    'lib/Data/Record/Serialize/Role/Base.pm',
    'lib/Data/Record/Serialize/Role/Default.pm',
    'lib/Data/Record/Serialize/Role/Encode.pm',
    'lib/Data/Record/Serialize/Role/EncodeAndSink.pm',
    'lib/Data/Record/Serialize/Role/Sink.pm',
    'lib/Data/Record/Serialize/Sink/array.pm',
    'lib/Data/Record/Serialize/Sink/null.pm',
    'lib/Data/Record/Serialize/Sink/stream.pm',
    'lib/Data/Record/Serialize/Types.pm',
    'lib/Data/Record/Serialize/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/boolean.t',
    't/bugs/duplicate-fields.t',
    't/bugs/rename-field-to-self.t',
    't/constructor.t',
    't/encoders/dbi.t',
    't/encoders/ddump.t',
    't/encoders/json.t',
    't/encoders/null.t',
    't/encoders/rdb.t',
    't/encoders/yaml.t',
    't/field_format.t',
    't/field_names.t',
    't/field_type_selection.t',
    't/field_types.t',
    't/lib/Data/Record/Serialize/Encode/types_nis.pm.orig',
    't/lib/My/Test/Encode/both.pm',
    't/lib/My/Test/Encode/store.pm',
    't/lib/My/Test/Encode/types_nis.pm',
    't/lib/My/Test/Encode/types_ns.pm',
    't/lib/My/Test/Util.pm',
    't/nullify.t',
    't/numify.t',
    't/stringify.t'
);

notabs_ok($_) foreach @files;
done_testing;
