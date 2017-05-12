package Catalyst::Plugin::EnvironmentDetector;

use strict;
use Sys::Hostname;

our $VERSION = '0.01';

sub is_environment {
    my ($c, $env_str) = @_;

    my $config = $c->config->{environmentdetector};

    if( exists $config->{$env_str} ) {
        foreach my $match_type ( keys %{ $config->{$env_str} } ) {
            if( $match_type eq "env" ) {
                my $env_key = $config->{$env_str}->{$match_type}[0];
                my $env_pattern = $config->{$env_str}->{$match_type}[1];
                return ($ENV{$env_key} =~ /$env_pattern/);
            } elsif( $match_type eq "hostname" ) {
                return (hostname =~ /$config->{$env_str}{hostname}/);
            } else {
                # unsupported matching criteria
                return undef;
            }
        }
    } 
    
    # in the event you have not configured the pattern
    # match for this environment then always return
    # undef so you will never detect this environment
    # as true.
    return undef;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::EnvironmentDetector - Catalyst plugin for environment detection

=head1 SYNOPSIS

    use Catalyst 'EnvironmentDetector';

    __PACKAGE__->config->(
        environmentdetector => { 
            production => { hostname => 'production.server.com' },
            test => { env => [ 'db_dsn', 'testdb.server.com' ] } 
        }
    );

    if( $c->is_environment( 'production' ) {
        # do things only on production
    } elsif ( $c->is_environment( 'test' ) ) {
        # do something else only on test
    }

=head1 DESCRIPTION

This plugin is intended to provide a generic way to detect what environment your
catalyst instance is currently operating in.  This is good for when you need/want
to modify behavior depending on the context that you are running the instance in.

This is done in a generic way so if the nature of the environment ever changes
you can simply update the config and it will work rather than propagating the
change to every place in your code you may have needed to detect environments.

Why would you want to do this?:
    Changing the authentication behavior in test or development
    Changing email recipients for test or development
    Circumventing security policies in a dedicated test environment

=head1 CONFIGURATION

Supported methods of environment detection:

Environment variables can be configured as follows:
    
    __PACKAGE__->config->( 
        environmentdetector => { 
            test => { env => [ 'db_dsn', 'testdb.server.com' ] } 
        }
    );

'test' is the environment key, env signifies the environment variables
method of detection and the array specifies the ENV key to use and the
pattern to match against.

Hostname based detection can be configured as follows:

    __PACKAGE__->config->(
        environmentdetector => { 
            production => { hostname => 'production.server.com' }
        }
    );

'production' is the environment key, hostname signifies the hostname method
of detection and the string it keys to is the pattern that should be matched.

=head1 METHODS

=head2 is_environment

Accepts a string that is the environment name that you are trying to detect.
This environment name must be set in this plugins configuration in order
for the detection to work.  Trying to detect an environment that has no
configuration will cause this function to return undef.  Under normal
circumstances it will return 1 if the environment matches and 0 it if does not.

=head1 SEE ALSO

https://github.com/klkane/catalyst-env-detector

=head1 AUTHOR

Kevin L. Kane, <kkane@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Kane

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
