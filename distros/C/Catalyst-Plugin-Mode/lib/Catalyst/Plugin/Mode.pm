package Catalyst::Plugin::Mode;
use strict;
#use NEXT;

our $VERSION = 0.01;

sub setup {
    my ( $c ) = shift;
    
    my $config = $c->config;
    my $plugin_config = $config->{'Catalyst::Plugin::Mode'};
    
    unless ( $plugin_config || ref $plugin_config eq 'HASH' ){
        Catalyst::Exception("Wrong config for plugin Catalyst::Plugin::Mode");
    }
    
    my $mode = $plugin_config->{mode} || $ENV{APPLICATION_MODE};
    
    unless ( $mode =~/^(dev|test|pred|prod)$/ ){
        Catalyst::Exception("Wrong value for mode in plugin Catalyst::Plugin::Mode.Values must be 'dev|test|pred|prod'");
    }
    
    foreach my $key( @{$plugin_config->{keys}} ){
        foreach my $ci( keys %{$config} ){
            my $node = $c->_get_node($mode,$key,$ci);
            if(defined $node){
                $config->{$ci} = $node;
            }
            undef $node;
        }
    }
        
    $c->config($c->config,$config);
        
    return $c->NEXT::setup(@_);
}

sub _get_node {
    my($c,$mode,$key,$ci)=@_;
    
    my $res;
    if( ref $c->config->{$ci} eq 'HASH' ) {
        $res = $c->config->{$ci}->{$mode};
    }
    
    return $res;
}

sub _set_values {
    my($c,$mode,$node)=@_;
    
    return;
}

1;

__END__

=head1 NAME


Catalyst::Plugin::Mode - select config values depends in your development process


=head1 DESCRIPTION


Only include the plugin in your main app module
Sometimes you need any values for your environment(development,test,predproduction,production)


For example in development you use such urls as
http://you_url


in test
http://test_domain.you_url/path


in production
http://prod_domain.you_url/blabla


You can manage this process with the plugin - in configuration only, without any calling methods
describe some options in your config such way


in .yml

    Catalyst::Plugin::Mode:
        keys:
            - any
            - another
        mode: test    
    any:
        dev:
            one_url: http://dev_one_url
            two_url: http://dev_two_url
        test:
            one_url: http://test_one_url
            two_url: http://test_two_url
        prod: 
            one_url: http://prod_one_url
            two_url: http://prod_two_url
    another:
        dev:
            one_url: http://any_another_dev_one_url
            two_url: http://any_another_dev_two_url
        test:
            one_url: http://any_another_test_one_url
            two_url: http://any_another_test_two_url
        prod:
            one_url: http://any_another_prod_one_url
            two_url: http://any_another_prod_two_url


in perl


    __YOUR_APPLICATION__->config({
        'Catalyst::Plugin::Mode' => {
            keys => [qw/any any.else any.any.another/],
            mode => 'test'
        },
        any => {
            dev => {
                one_url => 'http://dev_one_url',
                two_url => 'http://dev_two_url'
            },    
            test => {
                one_url => 'http://test_one_url',
                two_url => 'http://test_two_url'
            }    
            prod => {
                one_url => 'http://prod_one_url',
                two_url => 'http://prod_two_url'
            },
        another => {
            dev => {
                one_url => 'http://any_another_dev_one_url',
                two_url => 'http://any_another_dev_two_url'
            },    
            test => {
                one_url => 'http://any_another_test_one_url',
                two_url => 'http://any_another_test_two_url'
            }    
            prod => {
                one_url => 'http://any_another_prod_one_url',
                two_url => 'http://any_another_prod_two_url'
            },
        }
    });


When you run your catalyst app, B<setup> parse config and will be


    any => {
        one_url => 'http://test_one_url',
        two_url => 'http://test_two_url'
    another => {
        one_url => 'http://any_another_test_one_url',
        two_url => 'http://any_another_test_two_url'
    }


In such way you can change only one value in your config - C<mode> and all urls will be as you need
You can define valid valuev for mode for your application to ENV{APPLICATION_MODE}
All examples in tests


Available options for C<mode>:  dev|test|pred|prod


=head1 METHODS


=head2 setup


=head1 WARRANTY


This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.


=head1 AUTHOR


PLCGI C<plcgi1 (-) gmail.com>


=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

