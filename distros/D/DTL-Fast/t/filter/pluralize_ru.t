#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use DTL::Fast::Filter::Ru::Pluralize;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 1,
    'var2' => 2,
    'var7' => 7,
    'var12' => 11,
    'var21' => 21,
    'var100' => 100,
    'var2_5' => 2.5,
});

my $SET = [
    {
        'template' => '�����{{ var1|pluralize }}',
        'test' => '�����',
        'title' => 'Default single',
    },
    {
        'template' => '�����{{ var2|pluralize }}',
        'test' => '�����',
        'title' => 'Default multi',
    },
    {
        'template' => '�����{{ var2|pluralize:",��" }}',
        'test' => '�������',
        'title' => 'Override not complete values',
    },
    {
        'template' => '�����{{ var1|pluralize:",�,��" }} �����{{ var2|pluralize:",�,��" }} �����{{ var7|pluralize:",�,��" }} �����{{ var12|pluralize:",�,��" }} �����{{ var21|pluralize:",�,��" }} �����{{ var100|pluralize:",�,��" }}',
        'test' => '����� ������ ������� ������� ����� �������',
        'title' => 'Override multi',
    },
    {
        'template' => '�����{{ var7|pluralize:",��" }}',
        'test' => '�������',
        'title' => 'Override not complete values 2',
    },
    {
        'template' => '�����{{ var2_5|pluralize:",�,��" }}',
        'test' => '������',
        'title' => 'Float value',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
