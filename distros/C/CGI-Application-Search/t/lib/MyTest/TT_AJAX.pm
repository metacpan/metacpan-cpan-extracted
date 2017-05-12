package MyTest::TT_AJAX;
use base 'MyTest::AJAXBase';
use File::Spec::Functions qw(catfile);

# will be overridden by subclasses
sub options {
    return (
        TEMPLATE_TYPE => 'TemplateToolkit',
        AJAX          => 1,
    );
}

1;


