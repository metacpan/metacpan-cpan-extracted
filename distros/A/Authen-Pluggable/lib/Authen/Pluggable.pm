package Authen::Pluggable;
$Authen::Pluggable::VERSION = '0.02';
use Mojo::Base -base, -signatures;
use Mojo::Loader qw/load_class/;

has '_providers' => sub { return {} };
has 'log';

sub AUTOLOAD ($s) {
    our $AUTOLOAD;
    $AUTOLOAD =~ s/.*:://;
    return $s->_providers->{$AUTOLOAD};
}

sub provider($s, $provider, $plugin=undef) {
    $plugin //= $provider;
    my %v = (provider => $plugin);
    $s->_load_provider($provider, provider => $plugin)
        unless exists($s->_providers->{$provider});
    return $s->_providers->{$provider};
}

sub providers ( $s, @providers ) {
    foreach my $provider (@providers) {
        $provider = { $provider => undef } if (ref($provider) ne 'HASH');
        while ( my ( $k, $v ) = each %$provider ) {
            $s->_load_provider( $k, %$v );
        }
    }
    return $s;
}

sub _load_provider ( $s, $provider, %cfg ) {
    my $class = delete($cfg{provider}) // $provider;
    $class = __PACKAGE__ . "::$class";
    unless ( my $e = load_class $class ) {
        $s->_providers->{$provider} //= $class->new( parent => $s );
        $s->_providers->{$provider}->cfg(%cfg) if (%cfg);
    } else {
        ( $s->log && $s->log->error($e) ) || croak $e;
    }
}

sub authen ( $s, $user, $pass ) {
    foreach my $provider ( keys %{ $s->_providers } ) {
        my $uinfo = $s->_providers->{$provider}->authen( $user, $pass );
        $uinfo && do {
            $uinfo->{provider} = $provider;
            return $uinfo;
        }
    }

    return undef;
}

1;

=pod

=head1 NAME

Authen::Pluggable - A Perl module to authenticate users via pluggable modules

=for html <p>
    <a href="https://github.com/emilianobruni/authen-pluggable/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/authen-pluggable/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/authen-pluggable">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/authen-pluggable">
</p>

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Authen::Pluggable;

  my $auth = Authen::Pluggable->new();
  $auth->provider('plugin1','plugin2');
  $auth->plugin1->cfg({...});
  $auth->plugin2->cfg({...});

  my $user_info = $auth->authen($username, $password) || die "Login failed";

=head1 DESCRIPTION

Authen::Pluggable is a Perl module to authenticate users via pluggable modules

Every plugin class is in namespace C<Authen::Pluggable::*> so you must omit it

=encoding UTF-8

=head1 METHODS

=head2 new

This method takes a hash of parameters. The following options are valid:

=over

=item log

Any object that supports debug, info, error and warn.

  log => Log::Log4perl->get_logger('Authen::Simple::LDAP')

=back

=head2 provider($provider, $plugin [opt])

If C<$plugin> is omitted C<Authen::Pluggable::$provider> is loaded.
If C<$plugin> is set C<Authen::Pluggable::$plugin> is loaded with
C<$provider> as alias.

It return the plugin object.

=head2 providers(@providers)

If C<@providers> items are scalar, they are considered as plugin name and they
are loaded. Else they can be hashref items. The hash key is considered as
plugin name if there isn't a provider key inside else it's considered as
alias name while provider key are considered as plugin name.

  $auth->providers('plugin1', 'plugin2')

loads C<Authen::Pluggable::plugin1> and C<Authen::Pluggable::plugin2>

  $auth->providers(
    {   alias1 => {
            provider => 'plugin1',
            ... other configurations ...
        },
        alias2 => {
            provider => 'plugin1',
            ... other configurations ...
        }
    }
  ),

loads C<Authen::Pluggable::plugin1> two times, one with provider name C<alias1> and
one with C<alias2>. See L<t/50-alias.t> in test folder for an example with two
different password files

It always return the object itself.

=head2 authen($username, $password)

Call all configured providers and return the first with a valid authentication.

The structure returned is usually something like this

  { provider => $provider, user => $user, cn => $cn, gid => $gid };

where C<$provider> is the alias of the provider which return the valid
authentication and C<$cn> is the common name of the user.

If no plugins return a valid authentication, this method returns undef.

=head1 EXAMPLE FOR CONFIGURING PROVIDERS

There are various methods to select the providers where autenticate and to configure it.
Here some example using chaining.

This load and configure Passwd plugin

  $auth->provider('Passwd')->cfg(
    'file' => ...
  );

This load and confgure AD plugin

  $auth->provider('AD')->cfg(%opt)

Multiple configuration at one time via autoloaded methods

  $auth->providers( 'Passwd', 'AD' )
    ->Passwd->cfg('file' => ...)
    ->AD->cfg(%opt);

Same but via providers hashref configuration

  $auth->providers({
    'Passwd' => { 'file' => ... },
    'AD'     => \%opt,
  });

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/authen-pluggable/issues>

If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/authen-pluggable/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Authen::Pluggable

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A Perl module to authenticate users via pluggable modules

