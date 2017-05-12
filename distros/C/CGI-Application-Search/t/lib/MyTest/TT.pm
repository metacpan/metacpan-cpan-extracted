package MyTest::TT;
use base 'MyTest::Base';
use File::Spec::Functions qw(catfile);

# will be overridden by subclasses
sub options {
    return (
        TEMPLATE      => catfile('templates', 'search_results.tt'),
        TEMPLATE_TYPE => 'TemplateToolkit',
    );
}

1;


