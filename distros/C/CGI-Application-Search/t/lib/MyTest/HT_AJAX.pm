package MyTest::HT_AJAX;
use base 'MyTest::AJAXBase';
use File::Spec::Functions qw(catfile);

# will be overridden by subclasses
sub options {
    return (
        TEMPLATE_TYPE => 'HTMLTemplate',
        AJAX          => 1,
    );
}

1;


