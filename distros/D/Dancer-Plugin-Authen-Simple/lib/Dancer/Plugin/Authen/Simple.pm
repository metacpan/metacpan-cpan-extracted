use strict;
use warnings;

package Dancer::Plugin::Authen::Simple;
{
  $Dancer::Plugin::Authen::Simple::VERSION = '0.130500';
}
use Dancer ':syntax';
use Dancer::Plugin;
use Module::Load;
use Authen::Simple;
use Memoize;

#ABSTRACT: Easy Authentication for Dancer applications via Authen::Simple




sub authen
{
    _authen( plugin_setting() );
}

memoize('_authen');
sub _authen
{
    my $conf = shift;
    my @adapters = ();
    $DB::single = 1;
    foreach my $adapter_name ( keys %$conf )
    {
        my $driver = "Authen::Simple::$adapter_name";
        load $driver;
        push @adapters, $driver->new( %{ $conf->{$adapter_name} } );
    }
    Authen::Simple->new(@adapters);
}

register authen => \&authen;
register_plugin for_versions => [ 1, 2 ];

__END__
=pod

=head1 NAME

Dancer::Plugin::Authen::Simple - Easy Authentication for Dancer applications via Authen::Simple

=head1 VERSION

version 0.130500

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Authen::Simple;

    # calling the authen keyword will get you a Authen::Simple object
    # e.g. authen->authenticate( $user, $pass)

    hook 'before' => sub {
        if ( !session('user') && request->path_info !~ m{^/login} )
        {
            var requested_path => request->path_info;
            request->path_info('/login');
        }
    };
    get '/login' => sub {
        template 'login', { path => vars->{requested_path} };
    };
    post '/login' => sub {
        if ( authen->authenticate( params->{user}, params->{pass} ) )
        {
            debug "Password correct";

            # Logged in successfully
            session user => params->{user};
            redirect params->{path} || '/';
        }
        else
        {
            debug("Login failed - password incorrect for " . params->{user});
            redirect '/login?failed=1';
        }
    };

=head1 CONFIGURATION

Configuration details will be taken from your Dancer application config file.  Each sub-key of Authen::Simple will add an additional Authen::Simple:* module to the parent Authen::Simple object.

See Authen::Simple for details on configuration options for each module.

Example configuration for Authen::Simple::Kerberos, Authen::Simple::SMB and Authen::Simple::LDAP:

    plugins:
        "Authen::Simple":
            Kerberos:
                realm: 'REALM.EXAMPLE.COM'
            SMB:
                domain: 'DOMAIN'
                pdc:    'PDC'
            LDAP
                host: 'ldap.example.com'
                binddn: 'example_user'
                bindpw: 'example_password'
                basedn: 'ou=People,dc=example,dc=com'
                filter: '(sAMAccountName=%s)'

This is functionally equivalent to:

    use Authen::Simple;
    use Authen::Simple::Kerberos;
    use Authen::Simple::SMB;
    use Authen::Simple::LDAP;

    my $authen = Authen::Simple->new(
        Authen::Simple::Kerberos->new(realm => 'REALM.EXAMPLE.COM'),
        Authen::Simple::SMB->new(domain => 'DOMAIN', pdc => 'PDC'),
        Authen::Simple::LDAP->new(host => 'ldap.example.com', ... )
    );

=head1 SEE ALSO

L<Dancer>

L<Authen::Simple>

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

