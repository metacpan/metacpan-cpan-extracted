package AnyEvent::WebService::ImKayac;

use strict;
use warnings;

our $VERSION = '0.01';
our $URL = "http://im.kayac.com";

use AnyEvent::HTTP;
use HTTP::Request::Common;
use Digest::SHA qw/sha1_hex/;
use JSON;
use Carp;

=head1 NAME

AnyEvent::WebService::ImKayac - connection wrapper for im.kayac.com

=head1 SYNOPSIS

  use AnyEvent::WebService::ImKayac;

  my $im = AnyEvent::WebService::ImKayac->new(
    type     => 'password',
    user     => '...',
    password => '...'
  );

  $im->send( message => 'Hello! test send!!', cb => sub {
      my ($hdr, $json, $reason) = @_;

      if ( $json ) {
          if ( $json->{result} eq "posted" ) {
          }
          else {
              warn $json->{error};
          }
      }
      else {
          warn $reason;
      }
  });

=head2 METHODS

=head3 new

You must pass C<< type >> and C<< user >> parameter to new method. And type should be
secret, password or none.

=over 3

=item type is secret

You should pass secret_key parameter.

=item type is password

You should pass password parameter.

=item type is none

You dond need to pass other parameter.

=back

=cut

sub new {
    my $pkg = shift;
    my %args = ($_[1]) ? @_ : %{$_[1]};

    croak "missing require parameter 'user'" unless defined $args{user};
    croak "missing require parameter 'type'" unless defined $args{type};

    $args{type} = 'none' if $args{type} !~ /^(none|password|secret)$/;

    if ($args{type} eq 'password' && ! defined $args{password}) {
        croak "require password";
    }

    if ($args{type} eq 'secret' && ! defined $args{secret_key}) {
        croak "require secret_key";
    }

    bless \%args, $pkg;
}


=head3 $imkayac->send( message => '...', cb => sub {} );

Send with message and cb parameters. cb is called when message have been sent.

=cut

sub send {
    my ($self, %args) = @_;

    croak "missing required parameter 'message'" unless defined $args{message};
    my $cb = delete $args{cb} || croak "missing required parameter 'cb'";

    croak "parameter 'cb' should be coderef" unless ref $cb eq 'CODE';

    my $user = $self->{user};
    my $f = sprintf('_param_%s', $self->{type});

    # from http://github.com/typester/irssi-plugins/blob/master/hilight2im.pl
    my $req = POST "$URL/api/post/${user}", [ $self->$f(%args) ];

    my %headers = map { $_ => $req->header($_), } $req->headers->header_field_names;

    # steal from AnyEvent::Twitter
    http_post $req->uri, $req->content, headers => \%headers, sub {
        my ($body, $hdr) = @_;

        local $@;
        my $json = eval { decode_json($body) };

        if ( $hdr->{Status} =~ /^2/ ) {
            $cb->( $hdr, $json, $@ ? "parse error: $@" : $hdr->{Reason} );
        }
        else {
            $cb->( $hdr, undef, $hdr->{Reason}, $json );
        }
    };
}


sub _param_none {
    my ($self, %args) = @_;
    %args;
}

sub _param_password {
    my ($self, %args) = @_;

    (
        %args,
        password => $self->{password},
    );
}

sub _param_secret {
    my ($self, %args) = @_;

    my $skey = $self->{secret_key};

    (
        %args,
        sig => sha1_hex($args{message} . $skey),
    );
}

1;

__END__

=head1 AUTHORS

taiyoh E<lt>sun.basix@gmail.comE<gt>

soh335 E<lt>sugarbabe335@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
