package Catalyst::Plugin::ENV;
use strict;

our $VERSION = 0.02;

sub get_env_value {
    my ($c,$name) = @_;
    my ($value,$env);
    
    my $get = sub {
        my $name = shift;
        my $env = shift;
        my $res;
        if( defined $name && defined $env->{$name} ){
            $res = $env->{$name};
        }
        else {
            $res = $env;
        }
        return $res;
    };
    
    if( ref $c->engine->env eq 'HASH' ){
        $env = $c->engine->env;
    }
    else {
        $env = \%ENV;
    }
    if( ref $name eq 'ARRAY'){
        foreach ( @$name ){
            $value = $get->($_,$env);
            if ( $value ) { last; } 
        }
    }
    else  {
        $value = $get->($name,$env);    
    }
        
    return $value;
}


1;

__END__

=head1 NAME

Catalyst::Plugin::ENV - getter for value from enviroment

=head1 DESCRIPTION

In some tasks in catalyst app - you need value for your variable from %ENV
When catapp works as fcgi server - you can get this values from $c->engine->env
If you run devel catalyst server - you can get this values from %ENV
The plugin give you availablity to get value from enviroment with one method C<get_env_value>

=head1 METHODS

=head2 get_env_value

Getter for value from environment
Input param:

=item c<name>

If scalar - name to get value from environment
If array ref - array ref to get value from environment

=head1 AUTHOR

 PLCGI C<plcgi1 (-) gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

