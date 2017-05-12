#!/usr/bin/perl -I../lib
use strict; use warnings FATAL => 'all';
use Benchmark qw(:all);
use DTL::Fast qw(get_template);
use Dotiac::DTL qw/Template Context/;

# test taken from http://tomforb.es/just-how-slow-are-django-templates
# removed csrf token
# removed iteration by items

@Dotiac::DTL::TEMPLATE_DIRS = ('./tpl');

my $tutorial_context = {
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

sub uri_source
{
    return '^$';
}

my $results_context = {
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
    }
};

my $fast1 = get_template( "empty_template.html", 'dirs' => \@Dotiac::DTL::TEMPLATE_DIRS, 'url_source' => \&uri_source );
my $fast2 = get_template( "stackoverflow_homepage.html", 'dirs' => \@Dotiac::DTL::TEMPLATE_DIRS, 'url_source' => \&uri_source );
my $fast3 = get_template( "django_tutorial_page.html", 'dirs' => \@Dotiac::DTL::TEMPLATE_DIRS, 'url_source' => \&uri_source );
my $fast4 = get_template( "results.html", 'dirs' => \@Dotiac::DTL::TEMPLATE_DIRS, 'url_source' => \&uri_source );

my $dotiac1 = Dotiac::DTL::Template( "empty_template.html");
my $dotiac2 = Dotiac::DTL::Template( "stackoverflow_homepage.html");
my $dotiac3 = Dotiac::DTL::Template( "django_tutorial_page.html");
my $dotiac4 = Dotiac::DTL::Template( "results.html");

timethese( 10000, {
    'DTL::Fast  ' => sub
    {
        $fast1->render();
        $fast2->render();
        $fast3->render($tutorial_context);
        $fast4->render($results_context);
    },
    'Dotiac::DTL' => sub
    {
        $dotiac1->string();
        $dotiac2->render();
        $dotiac3->string($tutorial_context);
        $dotiac4->string($results_context);
    },
});