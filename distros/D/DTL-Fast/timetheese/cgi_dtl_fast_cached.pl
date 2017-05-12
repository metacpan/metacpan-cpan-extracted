#!/usr/bin/perl -I../lib -I../blib/arch

use DTL::Fast qw(get_template);
use DTL::Fast::Cache::File;

my $context = {
    'var1' => 'This',
    'var2' => 'is',
    'var3' => 'SPARTA',
    'var4' => 'GREEKS',
    'var5' => 'GO HOME!',
    'array1' => [qw( this is a text string as array )],
    "results" =>  
    {
        "test" =>  
        {
            "time_taken" =>  1, 
            "per_call" =>  1
        },
        "test2" =>  
        {
            "time_taken" =>  1, 
            "per_call" =>  1
        },
        "test3" =>  
        {
            "time_taken" =>  1, 
            "per_call" =>  1
        }
    },
    "platform" =>  
    {
        "django_version" =>  1,
        "python_version" =>  2
    },
    "error_message" =>  "error!",
    "poll" =>  
    {
        "question" =>  "test_question",
        "choice_set" =>  
        {
            "all" =>  
            [
                {"id" => 0, "choice_text" => "choice 0"},
                {"id" => 1, "choice_text" => "choice 1"},
                {"id" => 2, "choice_text" => "choice 2"},
                {"id" => 3, "choice_text" => "choice 3"},
            ]
        }
    }
};

my $cache = DTL::Fast::Cache::File->new('./cache');

my $tpl = get_template(
    'root.txt',
#    'child5.txt',
    , 'dirs' => [ './tpl' ]
    , 'cache' => $cache
    , 'url_source' => \&uri_source
);

sub uri_source
{
    return '^$';
}

$tpl->render($context);