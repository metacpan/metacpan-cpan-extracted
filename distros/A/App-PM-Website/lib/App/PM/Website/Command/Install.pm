use strict;
use warnings;

package App::PM::Website::Command::Install;
{
  $App::PM::Website::Command::Install::VERSION = '0.131611';
}
use base 'App::PM::Website::Command';
use Net::Netrc;
use HTTP::DAV;
use Data::Dumper;

#ABSTRACT: install the built website into production via caldav

sub options
{
    my ($class, $app) = @_;
    return (
        [ 'url=s'         => 'path to webdav directory' ],
        [ 'build-dir=s'   => 'path to local rendered files' ,
            { default => 'website' }],
        [ 'filename=s'    => 'upload name, rather than index.html' ,
            {default => 'index.html'}],
        [ 'username=s'    => 'username for webdav, override .netrc' ],
        [ 'password=s'    => 'password for webdav, override .netrc' ],
        [ 'certificate=s' => 'path to ca certificate' ],
    );
}

sub validate
{
    my ($self, $opt, $args ) = @_;

    $self->validate_certificate($opt);
    $self->validate_url($opt);
    $self->validate_login($opt);

    if(@$args)
    {
        die $self->usage_error("no arguments allowed")
    }
}
sub validate_certificate
{
    my ($self, $opt) = @_;
    my $c = $self->{config}{config}{website};
    $opt->{certificate} ||= $c->{certificate};

    if ($opt->{certificate} && ! -f $opt->{certificate} )
    {
        die $self->usage_error("could not find certificate file: $opt->{certificate}");

    }

    return 1; #certificate is optional.
}
sub validate_url
{
    my ($self, $opt ) = @_;
    my $c = $self->{config}{config}{website};

    $opt->{url} ||= $c->{url};
    die $self->usage_error( "url must be defined on command line or in config file") 
        unless $opt->{url};
}
sub validate_login
{
    my ( $self, $opt ) = @_;

    my $c       = $self->{config}{config}{website};
    my $url     = $opt->{url};
    my $machine = $opt->{machine} || $c->{machine};

    $opt->{username} ||= $c->{username};
    $opt->{password} ||= $c->{password};

    return 1 if ( $opt->{username} && $opt->{password} );

    if( $machine  )
    {
        my $mach = Net::Netrc->lookup($machine);
        if ( defined $mach )
        {
            $opt->{username} ||= $mach->login();
            $opt->{password} ||= $mach->password();
        }
        else
        {
            warn "machine '$machine' not found in .netrc"
        }
    }

    return 1 if ( $opt->{username} && $opt->{password} );

    die $self->usage_error(
        "username and password must be defined on the command line, config file or in .netrc"
    );
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $webdav             = HTTP::DAV->new();
    if( $opt->{certificate} )
    {
        print Dumper { certificate => $opt->{certificate} };
        my $ua = $webdav->get_user_agent;
        if ( $ua->can('ssl_opts') )
        {
            $ua->ssl_opts(SSL_ca_file => $opt->{certificate});
        }
        else
        {
            warn "Old version of LWP::UserAgent doesn't support ssl_opts"
        }
    }
    my %webdav_credentials = (
        -user  => $opt->{username},
        -pass  => $opt->{password},
        -url   => $opt->{url},
        -realm => "groups.perl.org",
    );
    print Dumper { credentials => \%webdav_credentials };
    $webdav->credentials(%webdav_credentials);
    $webdav->open( -url => $opt->{url} )
        or die sprintf( "failed to open url [%s] : %s\n",
        $opt->{url}, $webdav->message() );

    my %put_options = (
        -local => "$opt->{build_dir}/$opt->{filename}",
        -url   => $opt->{url},
    );
    print Dumper { put_options => \%put_options };
    my $success = $opt->{dry_run} ? 1 : $webdav->put(%put_options);

    die sprintf(
        "failed to put file %s/%s to url %s : %s\n",
        $opt->{build_dir}, $opt->{filename},
        $opt->{url},       $webdav->message(),
    ) unless $success;

    return $success;
}
1;

__END__
=pod

=head1 NAME

App::PM::Website::Command::Install - install the built website into production via caldav

=head1 VERSION

version 0.131611

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

