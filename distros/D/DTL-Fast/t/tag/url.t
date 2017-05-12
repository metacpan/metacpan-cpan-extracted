#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];
my $ssi_dirs = ['./t/ssi'];
$context = new DTL::Fast::Context({
    'array' => ['one', 'two', 'three'],
    'var1' => 1234,
    'slug' => 'дрель',
});

my $url_source = sub
{
    my $model = shift;
    my $arguments = shift;

#    warn "Looking for path for $model";
    
    my %map =(
        'catalog.product' => '^catalogs/catalog-(\d+)/(?<slug>)?$',
        'catalog.list' => '^catalogs/group-(?<group_id>\d+)/(?<slug>.+)?$',
    );
    
    return $map{$model};
};

my $SET = [
    {
        'template' => 'here is href="{% url "catalog.product" %}" example',
        'test' => 'here is href="/catalogs/catalog-/" example',
        'title' => 'Url without arguments',
    },
    {
        'template' => 'here is href="{% url "catalog.product" var1 "powertool" %}" example',
        'test' => 'here is href="/catalogs/catalog-1234/powertool" example',
        'title' => 'Url with positional arguments',
    },
    {
        'template' => 'here is href="{% url "catalog.list" slug="powertools" group_id=var1 %}" example',
        'test' => 'here is href="/catalogs/group-1234/powertools" example',
        'title' => 'Url with named arguments',
    },
    {
        'template' => 'here is href="{% url "catalog.list" slug="тестэскейпа" group_id=slug %}" example',
        'test' => 'here is href="/catalogs/group-%D0%B4%D1%80%D0%B5%D0%BB%D1%8C/%D1%82%D0%B5%D1%81%D1%82%D1%8D%D1%81%D0%BA%D0%B5%D0%B9%D0%BF%D0%B0" example',
        'title' => 'Url with named with escaping of utf8',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'}, 'url_source' => $url_source)->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
