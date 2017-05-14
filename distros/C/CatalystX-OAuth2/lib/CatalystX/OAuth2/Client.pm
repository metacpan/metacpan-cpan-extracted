package CatalystX::OAuth2::Client;
use Moose;
use LWP::UserAgent;

# ABSTRACT: An http client for requesting oauth2-protected resources using a token

our $UA;

has token => ( isa => 'Str', is => 'rw', required => 1 );

sub ua { $UA ||= LWP::UserAgent->new };
sub request { shift->ua->request(@_) }

before request => sub {
  my($self, $req) = @_;
  my $token = $self->token;
  $req->header( Authorization => 'Bearer ' . $token );
};

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Client - An http client for requesting oauth2-protected resources using a token

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
