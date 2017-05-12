package MyTest::HT;
use base 'MyTest::Base';
use File::Spec::Functions qw(catfile);

# will be overridden by subclasses
sub options {
    return (
        TEMPLATE      => catfile('templates', 'search_results.tmpl'),
        TEMPLATE_TYPE => 'HTMLTemplate',
    );
}

1;


