package Config::LDAPClient;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use Config::LDAPClient::Search;
use Carp qw();
use warnings;
use strict;


our $VERSION = '0.01';


my $PAM_SECRET_KEY = 'rootbindpw';


# Here for future support.
#has 'c_scope'         => ( is => 'rw', isa => enum([qw/ sub one base             /]));
#has 'c_deref'         => ( is => 'rw', isa => enum([qw/ never search find always /]));
#has 'c_ssl_key'       => ( is => 'rw', isa => 'Str' );
#has 'c_ssl_cert'      => ( is => 'rw', isa => 'Str' );

has 'c_ssl_type'      => ( is => 'rw', isa => enum([qw/ off ssl tls               /]));
has 'c_ssl_verify'    => ( is => 'rw', isa => enum([qw/ none optional require     /]));

has 'c_ssl_capath'    => ( is => 'rw', isa => 'Str' );
has 'c_ssl_cafile'    => ( is => 'rw', isa => 'Str' );
has 'c_ldap_version'  => ( is => 'rw', isa => 'Int' );
has 'c_bind_dn'       => ( is => 'rw', isa => 'Str' );
has 'c_bind_password' => ( is => 'rw', isa => 'Str' );
has 'c_base'          => ( is => 'rw', isa => 'Str' );
has 'c_search_passwd' => ( is => 'rw', isa => 'Config::LDAPClient::Search' );
has 'c_search_group'  => ( is => 'rw', isa => 'Config::LDAPClient::Search' );
has 'c_search_shadow' => ( is => 'rw', isa => 'Config::LDAPClient::Search' );

has 'c_uri' => (
    is          =>  'rw',
    isa         =>  'ArrayRef[Str]',
    default     =>  sub { [] },
    auto_deref  =>  1,
);

has 'raw_configs' => ( is => 'rw', isa => 'HashRef', default => sub {{}} );
has 'parsed'      => ( is => 'rw', isa => 'HashRef', default => sub {{}} );

has 'diag' => (
    metaclass   =>  'Collection::Array',
    is          =>  'ro',
    isa         =>  'ArrayRef[Str]',
    default     =>  sub { [] },
    auto_deref  =>  1,
    provides    =>  {
        push    =>  'add_diag',
        clear   =>  'clear_diag',
    },
);

__PACKAGE__->meta->make_immutable;




sub debug {
    my($self)   = shift;
    my $message = join "", @_;
    $self->add_diag($message);
}




sub connect {
    my($self, %args) = @_;
    my $new = $args{'new'} || {};
    Carp::croak("'new' argument must be a hashref")
        unless ref $new eq 'HASH';

    require Net::LDAP;

    my $ldap = Net::LDAP->new(
        [$self->c_uri],
        onerror =>  'die',
        version =>  $self->c_ldap_version,
        %$new,
    );

    Carp::croak("Unable to connect to LDAP: $@") unless $ldap;


    my $bind_dn = $self->c_bind_dn;
    my @bind_args;
    if (defined $bind_dn) {
        my $pw = $self->c_bind_password;
        push @bind_args, $bind_dn;
        push @bind_args, password => $pw if defined $pw;
    }

    {
        my $mesg = $ldap->bind(@bind_args);
        Carp::croak("Unable to bind LDAP connection: ", $mesg->error)
            if $mesg->is_error;
    }


    my $ssl = $self->c_ssl_type;
    if ($ssl ne 'off') {
        my $mesg = $ldap->start_tls(
            verify      =>  $self->c_ssl_verify,
            capath      =>  $self->c_ssl_capath,
            cafile      =>  $self->c_ssl_cafile,
            sslversion  =>  $ssl eq 'tls' ? 'tlsv1' : 'sslv3',
        );

        Carp::croak("Unable to start TLS on LDAP connection: ", $mesg->error)
            if $mesg->is_error;
    }

    return $ldap;
}




sub parse {
    my $self  = shift;
    my @specs = $self->_validate_specs(@_);

    my %raw_configs;
    my %final_parsed;
    $self->clear_diag;

    # The user specifies specs in priority order; first overrides second, etc.
    # So we reverse them, and let the hashes fall out as necessary.

    foreach my $spec (reverse @specs) {
        my($configs, $secret, $parse) = @$spec;

        foreach my $config (@$configs) {
            my($parsed, $raw);
            my $success = eval {
                ($parsed, $raw) = $self->$parse($config, $secret);
                1;
            };

            if ($success) {
                $raw_configs{$config} = $raw;

                my($dn, $dnpw) = delete @{$parsed}{'bind_dn', 'bind_password'};
                if (defined $dn and length $dn) {
                    # These values are associated, so we only assign both if
                    # we have a DN to use.
                    $final_parsed{'bind_dn'}       = $dn;
                    $final_parsed{'bind_password'} = $dnpw;
                }

                while (my($k, $v) = each %$parsed) {
                    $final_parsed{$k} = $v
                        if defined $v and length $v;
                }

            } else {
                $self->debug($@ || "unknown error parsing '$config'");
            }
        }
    }

    $self->raw_configs(\%raw_configs);
    $self->parsed     (\%final_parsed);

    foreach my $key (keys %final_parsed) {
        my $method = $self->can("c_$key");
        Carp::croak("Unknown parsed key '$key' found") unless $method;
        $method->($self, $final_parsed{$key});
    }

    return $self;
}




my %SPECS = (
    pam => {
        config  =>  '/etc/pam_ldap.conf',
        secret  =>  '/etc/pam_ldap.secret',
        parse   =>  'parse_file_pam',
    },

    nss => {
        config  =>  '/etc/libnss-ldap.conf',
        secret  =>  '/etc/libnss-ldap.secret',
        parse   =>  'parse_file_nss',
    },

    pam_nss => {
        config  =>  '/etc/ldap.conf',
        secret  =>  '/etc/ldap.secret',
        parse   =>  'parse_file_nss',
    },

    libldap => {
        config  =>  '/etc/ldap/ldap.conf',
        parse   =>  'parse_file_libldap',
    },

    libldap_home => {
        config  =>  ["$ENV{HOME}/.ldaprc", "$ENV{HOME}/ldaprc"],
        parse   =>  'parse_file_libldap',
    },
);

sub _validate_specs {
    my $self = shift;

    my @specs;
    foreach my $reqspec (@_) {
        my $spec;
        if (not ref $reqspec) {
            $spec = $SPECS{$reqspec};
            Carp::croak("Unknown parsing specification name '$reqspec'")
                unless $spec;

        } elsif (ref $reqspec eq 'HASH') {
            $spec = $reqspec;

        } else {
            Carp::croak(
                "Unknown parsing specification reference '", ref $reqspec, "'"
            );
        }

        my($configs, $secret, $parse) = @{$spec}{qw( config secret parse )};
        $configs = [$configs] unless ref $configs eq 'ARRAY';
        $parse   = ref $parse eq 'CODE' ? $parse : $self->can($parse);

        {
            my $err;

            $err = "'parse' key must be a subref or valid method name"
                unless ref $parse eq 'CODE';

            $err = "no 'parse' key"
                unless defined $parse;

            $err = "no configuration files specified"
                unless grep { defined } @$configs;

            if ($err) {
                require Data::Dumper;
                my $safespec = Data::Dumper->new([$reqspec])
                    ->Terse(1)->Indent(0)->Useqq(1)->Dump;

                Carp::croak("Invalid parsing specification $safespec: $err");
            }
        }

        push @specs, [$configs, $secret, $parse];
    }

    return @specs;
}




sub _parse_lokv_file {
    # Parses a simple line-oriented, key-value pair file format.  Each line has
    # the name of a setting, followed by whitespace and the value.  Any line
    # starting wth #, with any amount of leading whitespace, is treated as a
    # comment and ignored.  Blank lines are ignored.
    #
    # Returns a hashref of the parsed key-value pairs.

    my($self, $file) = @_;

    open(my $conffh, '<', $file)
        || die("Unable to open configuration file '$file': $!.\n");

    my %config;
    while (my $line = <$conffh>) {
        next if $line =~ /^\s*#/ or $line !~ /\S/;

        chomp $line;
        my($key, $value) = split " ", $line, 2;

        Carp::carp("Duplicate keys '$key' in file '$file'")
            if exists $config{$key};
            
        $config{$key} = $value;
    }

    close $conffh;

    return \%config;
}




sub _parse_hosts_uris {
    my($self, $port, $hosts, $uris) = @_;

    if ($uris) {
        return split " ", $uris;

    } elsif ($hosts) {
        my @uri;
        foreach my $host (split " ", $hosts) {
            my $uri  = "ldap://$host";
            $uri    .= ":$port" if $port and $host !~ /:/;
            push @uri, $uri;
        }
        return @uri;
    }

    return;
}




my %LIBLDAP_REQCERT = (
    never   =>  'none',
    allow   =>  'optional',
    try     =>  'optional',
    demand  =>  'require',
    hard    =>  'require',
);

sub parse_file_libldap {
    my($self, $conf_filename) = @_;
    my %config = %{ $self->_parse_lokv_file($conf_filename) };

    my %parsed = (
        uri         =>  [ $self->_parse_hosts_uris(@config{qw/ PORT HOST URI /}) ],
        bind_dn     =>  $config{'BIND_DN'},
        ssl_capath  =>  $config{'TLS_CACERTDIR'},
        ssl_cacert  =>  $config{'TLS_CACERT'},
        ssl_verify  =>  $LIBLDAP_REQCERT{ $config{'TLS_REQCERT'} || 'allow' },
    );

    return (\%parsed, \%config);
}




sub parse_file_nss {
    my $self = shift;
    my($parsed, $config) = $self->parse_file_pam(@_);

    foreach my $map (qw( passwd group shadow )) {
        if ($config->{"nss_base_$map"}) {
            $parsed->{"search_$map"} = Config::LDAPClient::Search->new(
                split /\?/, $config->{"nss_base_$map"}, 3
            );
        }
    }

    return ($parsed, $config);
}




sub parse_file_pam {
    my($self, $conf_filename, $secret_filename) = @_;
    my %config = %{ $self->_parse_lokv_file($conf_filename) };

    if (defined $secret_filename) {
        if (open my $secretfh, '<', $secret_filename) {
            Carp::carp("Config file '$conf_filename' has a '$PAM_SECRET_KEY' key already")
                if exists $config{$PAM_SECRET_KEY};

            chomp($config{$PAM_SECRET_KEY} = <$secretfh>);
            close $secretfh;

        } else {
            $self->debug("Unable to open secret file '$secret_filename': $!.");
        }
    }


    my($dn, $dnpw) = $self->_process_pam_dn(\%config);
    my %parsed = (
        uri             =>  [ $self->_parse_hosts_uris(@config{qw( port host uri )}) ],
        ldap_version    =>  $config{'ldap_version'},
        bind_dn         =>  $dn,
        bind_password   =>  $dnpw,
        port            =>  $config{'port'},
        base            =>  $config{'base'},
        ssl_capath      =>  $config{'tls_cacertdir'},
        ssl_cafile      =>  $config{'tls_cacertfile'},
        ssl_type        =>  $self->_process_pam_ssl($config{'ssl'}),
        ssl_verify      =>
            lc $config{'tls_checkpeer'} eq 'yes'
                ? 'require'
                : 'optional',
    );


    return (\%parsed, \%config);
}



my %SSL_TYPES = qw( on ssl  start_tls tls  off off );
sub _process_pam_ssl { $SSL_TYPES{ $_[1] || 'off' } }




sub _process_pam_dn {
    my($self, $config) = @_;

    my $root_dn = $config->{'rootbinddn'};
    my $root_pw = $config->{'rootbindpw'};

    if ($root_dn and defined $root_pw) {
        return ($root_dn, $root_pw);
    } else {
        return ($config->{'binddn'}, $config->{'bindpw'});
    }
}




1;

__END__

=head1 NAME

Config::LDAPClient - parse system configuration for LDAP client settings.


=head1 SYNOPSIS

    use Config::LDAPClient;

    my $conf = Config::LDAPClient->new();
    $conf->parse(
        'pam', 'nss', 'libldap',
        { config => '/etc/custom-ldap.conf', parse => \&custom_ldap_parser },
    );

    print "hosts: ", join(" ", $conf->c_uri), "\n";

    my $ldap = $conf->connect;
    # Call Net::LDAP methods on $ldap.

    sub custom_ldap_parser { ... }


=head1 DESCRIPTION

*** WARNING *** This is very much alpha software.  Testing has been minimal,
and the API is somewhat subject to change.

On many systems there is existing configuration for how to connect to an LDAP
server, usually in order to perform authentication for the system itself.
This module reads that configuration, parses it, and presents a common
interface that can then be used to connect to the specified LDAP server.

For a list of configuration files supported see L</Configuration Files>.


=head2 Methods

All methods raise exceptions on errors.  Currently these are simply string
exceptions.

=over 4

=item $class->new( ... )

This is the class's constructor.  It takes a hashref, or a list of key-value
pairs; these are treated as method names, and the methods are called with the
associated values.  This method is supplied by Moose.


=item $object->connect

=item $object->connect( new => \%args )

Attempts to connect to an LDAP database using L<Net::LDAP>.  Attributes should
be set to appropriate values, which means L</parse> probably should be called
first.

The C<new> argument, if specified, must be a hashref.  It is dereferenced and
passed to the Net::LDAP constructor.  It is used to override any default
options set by L<Config::LDAPClient>, and any L<Net::LDAP> defaults.

Currently the only default constructor argument specified by
L<Config::LDAPClient> is C<onerror>, which is set to 'die'.


=item $object->parse( @names_or_specifications )

This is the workhorse of the module.  The arguments to this method are a
series of pre-defined names and/or hashrefs indicating what configuration
files to read, and how to parse them.

Pre-defined names are listed in L</Configuration Files>.

If a hashref is specified, it must contain at least two keys, C<config> and
C<parse>.  C<config> is a scalar or arrayref listing the configuration files
to read; C<parse> is the method or subroutine reference to call.  An
additional parameter, C<secret>, may be provided; this is the name of the
file that contains the bind password required to connect.  Any problems
opening this file are not fatal, and will be added to C<diag>, but otherwise
ignored.

The C<parse> subroutine or method is expected to return two values: a hashref
of the parsed values, to be passed to C<c_*> methods, and a data structure
representing the raw parsed configuration.  The C<parse> subroutine or method
is called with three arguments: the Config::LDAPClient object, the
configuration filename or names, and optionally the secret filename (if it's
specified).

Names and specifications are listed in priority order, meaning the first file
found takes precedence over subsequent files.  All settings are merged, with
the highest priority taking precedence.


=item $object->parse_file_pam($conf_filename, $secret_filename)

This parses the PAM LDAP configuration file format.  The parsing, and
subsequent handling of options, is based on a reading of the pam_ldap.conf(5)
man page from libpam-ldap 184-4.2 installed on Debian Lenny.

This method conforms to the description of the C<parse> argument described in
the L<"parse method"/parse> documentation.


=item $object->parse_file_nss($conf_filename, $secret_filename)

This parses the NSS LDAP configuration file format.  It first callse
L</parse_file_pam>, because the formats and most of the options are
identical, then does specific handling.  The handling of options ceomes from
a reading of the libnss-ldap.conf(5) man page from libnss-ldap 261-2.1
installed on Debian Lenny.

This method conforms to the description of the C<parse> argument described in
the L<"parse method"/parse> documentation.


=item $object->parse_file_libldap($conf_filename)

This parses the libldap configuration file format.  The parsing and handling
of options comes from a reading of the ldap.conf(5) man page from
libldap-2.4-2 installed on Debian Lenny.

This method conforms to the description of the C<parse> argument described in
the L<"parse method"/parse> documentation.


=item $object->diag

=item $object->add_diag($message)

=item $object->clear_diag

The C<diag> method accesses an array of non-fatal errors encountered in a
given L</parse> run.  C<add_diag> adds an entry, and C<clear_diag> clears the
entire array.


=item $object->raw_configs

=item $object->raw_configs(\%configs)

Accessor for the raw configuration data parsed from files.  The hash keys are
the filenames, the values the configuration data returned from the parse.


=item $object->parsed

=item $object->parsed(\%parsed)

Accessor for the parsed and processed data.  This is all of the original
merged data, and should correspond directly to the values returned by the
C<c_*> accessors.

=back


=head2 Configuration Accessors

=over 4

=item $object->c_uri

=item $object->c_uri(\@uris)

Accessor for URIs to connect to.  Corresponds to the HOST argument for the
new method in L<Net::LDAP>.  Returns a list of URIs, not an arrayref.


=item $object->c_ldap_version

=item $object->c_ldap_version($number)

Accessor for the LDAP protocol version to be used.  Corresponds to the
version argument to the L<Net::LDAP> constructor.


=item $object->c_bind_dn

=item $object->c_bind_dn($dn)

Accessor for the DN to bind to use on connect.  Corresponds to the first
argument to the bind method in L<Net::LDAP>.


=item $object->c_bind_password

=item $object->c_bind_password($password)

Accessor for the bind password to use on connect.  Corresponds to the
password argument to the bind method in L<Net::LDAP>.


=item $object->c_base

=item $object->c_base($base)

Accessor for the default base DN to use in searches.


=item $object->c_ssl_type

=item $object->c_ssl_type($type)

Accessor for the SSL access type; valid values are 'off', 'ssl', or 'tls'.


=item $object->c_ssl_verify

=item $object->c_ssl_verify($verify)

Accessor for the SSL verification requirement; valid values correspond to
the verify argument to start_tls in L<Net::LDAP>, namely 'none', 'optional',
and 'require'.


=item $object->c_ssl_capath

=item $object->c_ssl_capath($path)

Accessor for the directory of CA certificates.  Corresponds to the capath
argument to start_tls in L<Net::LDAP>.


=item $object->c_ssl_cafile

=item $object->c_ssl_cafile($filename)

Accessor for the CA certificates file.  Corresponds to the cafile argument to
start_tls in L<Net::LDAP>.


=item $object->c_search_passwd

=item $object->c_search_passwd($object)

=item $object->c_search_group

=item $object->c_search_group($object)

=item $object->c_search_shadow

=item $object->c_search_shadow($object)

These apply specifically to NSS.  They are accessors for base DNs to use for
specific lookups.  The object used is an L<Config::LDAPClient::Search>
object, or subclass thereof.

=back


=head2 Configuration Files

This module comes with several pre-defined paths that it can attempt to
parse.  These names can be passed directly to L</parse>.

=over 4

=item * pam

Attempts to parse /etc/pam_ldap.conf and /etc/pam_ldap.secret, using
L</parse_file_pam>.  The secret file is typically owned by root and mode
0600, so unless you run as root, you will get the binddn and bindpw values in
L</c_bind_dn> and L</c_bind_password>.


=item * nss

Attempts to parse /etc/libnss-ldap.conf and /etc/libnss-ldap.secret, using
L</parse_file_nss>.  The secret file is typically owned by root and mode
0600, so unless you run as root, you will get the binddn and bindpw values in
L</c_bind_dn> and L</c_bind_password>.


=item * pam_nss

Some systems merge their libnss-ldap and pam-ldap configuration files.  This
attempts to parse /etc/ldap.conf and /etc/ldap.secret.  The secret file is
typically owned by root and mode 0600, so unless you run as root, you will
get the binddn and bindpw values in L</c_bind_dn> and L</c_bind_password>.


=item * libldap

Attempts to parse /etc/ldap/ldap.conf using L</parse_file_libldap>.


=item * libldap_home

Attempts to parse C<$ENV{HOME}/.ldaprc> and C<$ENV{HOME}/ldaprc>.

=back


=head1 BUGS

The test suite is non-existent.

Option handling is not comprehensive.  Not all of the options available in
pam_ldap.conf and libnss-ldap.conf are actually used, even though they have
equivalents in Net::LDAP.

Currently this only supports common Linux setups (specifically Debian Lenny
and Ubuntu Hardy Heron).  Support for more systems is forthcoming.

In order to speed development time, this module uses Moose.  This increases
the dependency list by a few orders of magnitude, which you may or may not
consider a bug.

All of the configuration options available are specified as toplevel methods,
albeit with 'c_' prefixes.  This could be considered a design bug, but it was
the simplest way to involve Moose's type checking.

Aside from support and design, there are probably more than a few bugs lurking
about.  This module was written quickly over a weekend with very minimal
testing, as the lack of a test suite can attest.


=head1 AUTHOR

Michael Fowler <mfowler@cpan.org>


=head1 COPYRIGHT & LICENSE

Copyright 2009  Michael Fowler

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=cut
