
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/MuForm.pm',
    'lib/Data/MuForm/Common.pm',
    'lib/Data/MuForm/Field.pm',
    'lib/Data/MuForm/Field/Boolean.pm',
    'lib/Data/MuForm/Field/Button.pm',
    'lib/Data/MuForm/Field/Checkbox.pm',
    'lib/Data/MuForm/Field/Compound.pm',
    'lib/Data/MuForm/Field/CompoundDateTime.pm',
    'lib/Data/MuForm/Field/Currency.pm',
    'lib/Data/MuForm/Field/Date.pm',
    'lib/Data/MuForm/Field/Display.pm',
    'lib/Data/MuForm/Field/Email.pm',
    'lib/Data/MuForm/Field/Float.pm',
    'lib/Data/MuForm/Field/Hidden.pm',
    'lib/Data/MuForm/Field/Integer.pm',
    'lib/Data/MuForm/Field/List.pm',
    'lib/Data/MuForm/Field/Multiple.pm',
    'lib/Data/MuForm/Field/Password.pm',
    'lib/Data/MuForm/Field/PrimaryKey.pm',
    'lib/Data/MuForm/Field/Repeatable.pm',
    'lib/Data/MuForm/Field/Repeatable/Instance.pm',
    'lib/Data/MuForm/Field/Reset.pm',
    'lib/Data/MuForm/Field/Select.pm',
    'lib/Data/MuForm/Field/Submit.pm',
    'lib/Data/MuForm/Field/Text.pm',
    'lib/Data/MuForm/Field/Textarea.pm',
    'lib/Data/MuForm/Field/Time.pm',
    'lib/Data/MuForm/Field/URL.pm',
    'lib/Data/MuForm/Field/Upload.pm',
    'lib/Data/MuForm/Fields.pm',
    'lib/Data/MuForm/Localizer.pm',
    'lib/Data/MuForm/Manual.pod',
    'lib/Data/MuForm/Manual/Cookbook.pod',
    'lib/Data/MuForm/Manual/Defaults.pod',
    'lib/Data/MuForm/Manual/Errors.pod',
    'lib/Data/MuForm/Manual/Fields.pod',
    'lib/Data/MuForm/Manual/FormHandlerDiff.pod',
    'lib/Data/MuForm/Manual/Hooks.pod',
    'lib/Data/MuForm/Manual/Intro.pod',
    'lib/Data/MuForm/Manual/Reference.pod',
    'lib/Data/MuForm/Manual/Rendering.pod',
    'lib/Data/MuForm/Manual/Testing.pod',
    'lib/Data/MuForm/Manual/Transformations.pod',
    'lib/Data/MuForm/Manual/Validation.pod',
    'lib/Data/MuForm/Merge.pm',
    'lib/Data/MuForm/Meta.pm',
    'lib/Data/MuForm/Model.pm',
    'lib/Data/MuForm/Model/Object.pm',
    'lib/Data/MuForm/Params.pm',
    'lib/Data/MuForm/Renderer/Base.pm',
    'lib/Data/MuForm/Role/RequestToken.pm',
    'lib/Data/MuForm/Test.pm',
    'lib/Data/MuForm/Types.pm'
);

notabs_ok($_) foreach @files;
done_testing;
