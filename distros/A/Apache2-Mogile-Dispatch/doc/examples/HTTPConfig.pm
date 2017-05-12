package HTTPConfig;

use strict;
use warnings;

use base 'Apache2::Mogile::Dispatch';

use Cache::Memcached;
use YAML::Syck;

my @directives = (
	{
        name         => 'MogReproxyToken',
        func         => __PACKAGE__ . '::MogReproxyToken',
        req_override => Apache2::Const::RSRC_CONF,
        args_how     => Apache2::Const::TAKE1,
        errmsg       => 'MogReproxyToken hostname',
    },
    {
        name         => 'MogDomain',
        func         => __PACKAGE__ . '::MogDomain',
        req_override => Apache2::Const::RSRC_CONF,
        args_how     => Apache2::Const::TAKE1,
        errmsg       => 'MogDomain hostname',
    },
    {
        name         => '<MogTrackers',
        func         => __PACKAGE__ . '::MogTrackers',
        req_override => Apache2::Const::RSRC_CONF,
        args_how     => Apache2::Const::RAW_ARGS,
        errmsg       => '<MogTrackers>
	    mog1 192.168.100.3:1325
	    mog2 192.168.100.4:1325
	    mog3 localhost:1325
	    mog4 localhost:1326
...
</MogTrackers>',
    },
    {
        name         => '</MogTrackers>',
        func         => __PACKAGE__ . '::MogTrackersEND',
        req_override => Apache2::Const::OR_ALL,
        args_how     => Apache2::Const::NO_ARGS,
        errmsg       => '</MogTrackers> without <MogTrackers>',
    },
    {
        name         => '<MogStaticServers',
        func         => __PACKAGE__ . '::MogStaticServers',
        req_override => Apache2::Const::RSRC_CONF,
        args_how     => Apache2::Const::RAW_ARGS,
        errmsg       => '<MogStaticServers>
	    web1 192.168.100.3:80
	    web2 192.168.100.4:80
	    web3 localhost:80
...
</MogStaticServers>',
    },
    {
        name         => '</MogStaticServers>',
        func         => __PACKAGE__ . '::MogStaticServersEND',
        req_override => Apache2::Const::OR_ALL,
        args_how     => Apache2::Const::NO_ARGS,
        errmsg       => '</MogStaticServers> without <MogStaticServers>',
    },
);

eval { Apache2::Module::add(__PACKAGE__, \@directives); };

sub MogReproxyToken {
	my ($i, $parms, $arg) = @_;
    $i = Apache2::Module::get_config( __PACKAGE__, $parms->server );
    $i->{'MogReproxyToken'} = $arg;
}

sub MogDomain {
	my ($i, $parms, $arg) = @_;
    $i = Apache2::Module::get_config( __PACKAGE__, $parms->server );
    $i->{'MogDomain'} = $arg;
}

sub MogTrackers {
    my ($i, $parms, @args)=@_;
    $i = Apache2::Module::get_config( __PACKAGE__, $parms->server );
    $i->{'MogTrackers'} = _parse_serverlist( $parms->directive->as_string);
}

sub MogTrackersEND {
    die 'ERROR: </MogTrackers> without <MogTrackers>';
}

sub MogStaticServers {
    my ($i, $parms, @args)=@_;
    $i = Apache2::Module::get_config( __PACKAGE__, $parms->server );
    $i->{'MogStaticServers'} = _parse_serverlist( $parms->directive->as_string);
}

sub MogStaticServersEND {
    die 'ERROR: </MogStaticServers> without <MogStaticServers>';
}

sub _parse_serverlist {
    my $conf = shift;
    my $a = [];
    foreach my $line (split /\r?\n/, $conf) {
        if( $line=~/^\s*(\w+):?\s+(.+?)\s*$/ ) {
            push @{$a}, $2;
        }
    }
    return $a;
}

# XXX To be subclassed
sub memcache_key {
    my ($r) = @_;
    return $r->uri;
}

# XXX To be subclassed
sub mogile_key {
    my ($r) = @_;
    return $r->uri;
}

# XXX To be subclassed
sub get_direction {
    return { 'mogile' => 1 };
}

# XXX To be subclassed
sub get_config {
    my ($r) = @_;
    return Apache2::Module::get_config(__PACKAGE__, $r->server);
}

# XXX To be subclassed
sub reproxy_request {
    return 1;
}

1;
__END__

=pod

=head1 NAME

HTTPConfig - A httpd configured dispatcher

=head1 SYNOPSIS

This example module shows how to take advantage of the httpd configuration to
configure your dispatcher.

  # -- httpd.conf
  MogReproxyToken old_web
  MogDomain localhost
  <MogTrackers>
    mog1 192.168.100.3:1325
    mog2 192.168.100.4:1325
  </MogTrackers>

  <LocationMatch "^/">
      SetHandler modperl
      PerlHandler HTTPConfig
  </LocationMatch>

=head1 CONFIGURATION

=head2 MogReproxyToken

If a reproxy token is set and a given uri/file is not to be handled through
mogile then it will issue a 'X-REPROXY-SERVICE' => TOKEN_XYZ instead of
reproxying the url through one of the static servers.

Note that when this option is set the static servers directive is completely
ignored.

=head2 MogDomain

This option is passed on to mogile object creation.

=head2 MogTrackers

The MogTrackers directive sets the MogileFS trackers to query.

  <MogTrackers>
    mog1 192.168.100.3:1325
    mog2 192.168.100.4:1325
    mog3 localhost:1325
    mog4 localhost:1326
    ...
  </MogTrackers>

Note that the first column indicating node names really doesn't mean or do
anything.

=head2 MogStaticServers

Much like MogTrackers and MogMemcaches, this option sets the static servers to
reproxy to if a given file/uri is not handled by mogile. Note that this is
completely useless if mogile handles everything, via setting MogAlways to
'mogile'.

  <MogStaticServers>
    web1 http://192.168.100.3:80
    web2 http://192.168.100.4:80
    web3 http://localhost:80
    ...
  </MogStaticServers>

If Apache2::Mogile::Dispatch handles the uri '/socklabs/index.html' and the
director says that it is not infact to be handled by mogile, it will attempt
to content the static servers to request the file. In this case it starts at
the top and works its way through the list using the first one that returns
200 - OK. If none of them return then a 404 - Not Found is returned.

Note that the format for the reproxy is very simple:

  <static server x><uri>

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Apache2::Mogile::Dispatch

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
