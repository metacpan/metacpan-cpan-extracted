use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Catalyst/Controller/HTML/FormFu.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/Form.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/FormConfig.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/FormMethod.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/MultiForm.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/MultiFormConfig.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/MultiFormMethod.pm',
    'lib/Catalyst/Controller/HTML/FormFu/ActionBase/Form.pm',
    'lib/Catalyst/Helper/HTML/FormFu.pm',
    'lib/HTML/FormFu/Constraint/RequestToken.pm',
    'lib/HTML/FormFu/Element/RequestToken.pm',
    'lib/HTML/FormFu/Plugin/RequestToken.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01basic-form.t',
    't/01basic-formconfig.t',
    't/01basic-formconfig_conf_ext.t',
    't/01basic-formmethod.t',
    't/01basic-token.t',
    't/02multiform-multiformconfig.t',
    't/02multiform-multiformmethod.t',
    't/02multiform-token.t',
    't/03instancepercontext.t',
    't/elements/requesttoken.t',
    't/elements/requesttoken.yml',
    't/lib/TestApp.pm',
    't/lib/TestApp/Controller/Basic.pm',
    't/lib/TestApp/Controller/MultiForm.pm',
    't/lib/TestApp/Controller/MultiFormToken.pm',
    't/lib/TestApp/Controller/Root.pm',
    't/lib/TestApp/Controller/Token.pm',
    't/lib/TestApp/Controller/TokenExpire.pm',
    't/lib/TestApp/View/TT.pm',
    't/root/form.tt',
    't/root/forms/basic/formconfig.yml',
    't/root/forms/basic/formconfig_conf_ext.yml',
    't/root/forms/multiform/file_upload.yml',
    't/root/forms/multiform/formconfig.yml',
    't/root/multiform.tt'
);

notabs_ok($_) foreach @files;
done_testing;
