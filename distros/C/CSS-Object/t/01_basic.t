#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use_ok( 'CSS::Object' );
    use_ok( 'CSS::Object::Builder' );
    use_ok( 'CSS::Object::Comment' );
    use_ok( 'CSS::Object::Element' );
    use_ok( 'CSS::Object::Format' );
    use_ok( 'CSS::Object::Format::Inline' );
    use_ok( 'CSS::Object::Parser' );
    use_ok( 'CSS::Object::Parser::Default' );
    use_ok( 'CSS::Object::Parser::Enhanced' );
    use_ok( 'CSS::Object::Property' );
    use_ok( 'CSS::Object::Rule' );
    use_ok( 'CSS::Object::Rule::At' );
    use_ok( 'CSS::Object::Rule::Keyframes' );
    use_ok( 'CSS::Object::Selector' );
    use_ok( 'CSS::Object::Value' );
};

my $css = CSS::Object->new;
isa_ok( $css, 'CSS::Object', 'CSS::Object object class' );

my $b = CSS::Object::Builder->new( $css );
isa_ok( $b, 'CSS::Object::Builder', 'CSS::Object::Builder object class' );

my $css_def = CSS::Object::Parser::Default->new( $css );
isa_ok( $css_def, 'CSS::Object::Parser::Default', 'CSS::Object::Parser::Default object class' );

# my $css_heavy = CSS::Object::Parser::Heavy->new;
# isa_ok( $css_heavy, 'CSS::Object::Parser::Heavy', 'CSS::Object::Parser::Heavy object class' );

my $css_rule = CSS::Object::Rule->new;
isa_ok( $css_rule, 'CSS::Object::Rule', 'CSS::Object::Rule object class' );

my $css_selector = CSS::Object::Selector->new;
isa_ok( $css_selector, 'CSS::Object::Selector', 'CSS::Object::Selector object class' );

my $css_property = CSS::Object::Property->new;
isa_ok( $css_property, 'CSS::Object::Property', 'CSS::Object::Property object class' );

my $css_value = CSS::Object::Value->new;
isa_ok( $css_value, 'CSS::Object::Value', 'CSS::Object::Value object class' );

