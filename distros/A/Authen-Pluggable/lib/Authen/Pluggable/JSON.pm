package Authen::Pluggable::JSON;
$Authen::Pluggable::JSON::VERSION = '0.02';
use Mojo::Base -base, -signatures;
use Mojo::UserAgent;
use Mojo::URL;

has 'parent' => undef, weak => 1;

has _cfg => sub {
    return {
        url           => new Mojo::URL('http://127.0.0.1:3000/api/auth'),
        query_builder => sub {
            Mojo::URL->new(shift)->query( user => shift, pass => shift );
        },
        res_builder => sub($json) {return %$json ? $json : undef },
    };
};

sub authen ( $s, $user, $pass ) {
    my $ub = $s->_cfg->{query_builder};
    my $ut = $s->_cfg->{url};
    my $rb = $s->_cfg->{res_builder};

    my $url = $ub->( $ut, $user, $pass );

    my $ua  = Mojo::UserAgent->new;
    my $res = $ua->get($url)->result;

    return $rb->( $res->json ) if ( $res->is_success );

    return undef;
}

sub cfg ( $s, %cfg ) {
    if (%cfg) {
        while ( my ( $k, $v ) = each %cfg ) {
            $s->_cfg->{$k} = $v;
        }
    }
    return $s->parent;
}

sub log ( $s, $type, $msg ) {
    return unless $s->parent->log;
    $s->parent->log->$type($msg);
}

1;

=pod

=head1 NAME

Authen::Pluggable::JSON - Authentication via external json

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

  $auth->provider('JSON')->cfg({
    url           => ...,
    query_builder => ...,
    res_builder   => ...,
  });

  my $user_info = $auth->authen($username, $password) || die "Login failed";

=head1 DESCRIPTION

Authen::Pluggable::JSON is a L<Authen::Pluggable> plugin to authenticate users
via JSON calls.
You can personalize url, query parameters and returned JSON via configuration.

=encoding UTF-8

=head1 METHODS

=head2 cfg

This method takes a hash of parameters. The following options are valid:

=over

=item url

Url to JSON service. Default: a L<Mojo::URL> istance to
C<http://127.0.0.1:3000/api/auth>

=item query_builder

A subroutine ref for appending query string to url. The sub is called like this:

  $qb->($url, $username, $password);

Default appends C<user=$username&pass=$password> to url.

=item res_builder

A subroutine ref for altering JSON structure returned by remote service to be
compliance with L<Authen::Pluggable> structure. The sub is called like this:

  $rb->($json);

Default: return JSON structure returned by remote service as is or undef if
remote service return C<{}>.

=back

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/authen-pluggable/issues>

If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/authen-pluggable/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Authen::Pluggable::JSON

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Authentication via external json

