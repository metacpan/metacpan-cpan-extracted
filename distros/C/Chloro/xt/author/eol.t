use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Chloro.pm',
    'lib/Chloro/Error/Field.pm',
    'lib/Chloro/Error/Form.pm',
    'lib/Chloro/ErrorMessage.pm',
    'lib/Chloro/Field.pm',
    'lib/Chloro/Group.pm',
    'lib/Chloro/Manual.pod',
    'lib/Chloro/Manual/Groups.pod',
    'lib/Chloro/Manual/Intro.pod',
    'lib/Chloro/Result/Field.pm',
    'lib/Chloro/Result/Group.pm',
    'lib/Chloro/ResultSet.pm',
    'lib/Chloro/Role/Error.pm',
    'lib/Chloro/Role/Form.pm',
    'lib/Chloro/Role/FormComponent.pm',
    'lib/Chloro/Role/Result.pm',
    'lib/Chloro/Role/ResultSet.pm',
    'lib/Chloro/Role/Trait/HasFormComponents.pm',
    'lib/Chloro/Trait/Application.pm',
    'lib/Chloro/Trait/Application/ToClass.pm',
    'lib/Chloro/Trait/Application/ToRole.pm',
    'lib/Chloro/Trait/Class.pm',
    'lib/Chloro/Trait/Role.pm',
    'lib/Chloro/Trait/Role/Composite.pm',
    'lib/Chloro/Types.pm',
    'lib/Chloro/Types/Internal.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/bool.t',
    't/default.t',
    't/extractor.t',
    't/extractor2.t',
    't/extractor3.t',
    't/form-error.t',
    't/group.t',
    't/inheritance.t',
    't/lib/Chloro/Test/Address.pm',
    't/lib/Chloro/Test/CompoundDate.pm',
    't/lib/Chloro/Test/DateFromStr.pm',
    't/lib/Chloro/Test/Default.pm',
    't/lib/Chloro/Test/Login.pm',
    't/lib/Chloro/Test/NoNameExtractor.pm',
    't/lib/Chloro/Test/User.pm',
    't/lib/Chloro/Test/Validator.pm',
    't/role.t',
    't/storable.t',
    't/validator.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
