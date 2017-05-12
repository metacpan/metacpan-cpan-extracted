package Catalyst::ActionRole::ExpiresHeader;
BEGIN {
  $Catalyst::ActionRole::ExpiresHeader::VERSION = '0.01';
}
# ABSTRACT: Set default Expires header for actions

use strict;
use Moose::Role;
use HTTP::Date qw(time2str);

after 'execute' => sub {
    my $self = shift;
    my ($controller, $c, @args) = @_;

    if ( my $expires_attr = $c->action->attributes->{Expires} ) {
        my $expires = $self->_parse_Expires_attr( $expires_attr->[0] );
        unless ( $c->response->header('Expires') ) {
            $c->response->header(
                Expires =>
                    $expires =~ /^\d+$/ ? time2str( $expires ) : $expires
            );
        }
    }
};

{
    my (%mult) = (
        's' => 1,
        'm' => 60,
        'h' => 60*60,
        'd' => 60*60*24,
        'M' => 60*60*24*30,
        'y' => 60*60*24*365
    );

    sub _parse_Expires_attr {
        my ($self, $time) = @_;

        # below code is copied from CGI::Util for compability with CGI::Cookie
        my($offset);
        if (!$time || (lc($time) eq 'now')) {
          $offset = 0;
        } elsif ($time=~/^\d+/) {
          return $time;
        } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
          $offset = ($mult{$2} || 1)*$1;
        } else {
          return $time;
        }
        return (time+$offset);
    }
}

no Moose::Role;


1; # End of Catalyst::ActionRole::ExpiresHeader


__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::ActionRole::ExpiresHeader - Set default Expires header for actions

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    package MyApp::Controller::Foo;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    __PACKAGE__->config(
        action_roles => [qw( ExpiresHeader )],
    );

    sub expire_in_one_day : Local Expires('+1d') { ... }

    sub already_expired : Local Expires('-1d') { ... }

=head1 DESCRIPTION

Provides a ActionRole to set HTTP Expires header for actions, which will be
set unless Expires header was already set.

Argument syntax matches the C<-expires> from
L<CGI/CREATING_A_STANDARD_HTTP_HEADER:>.

=head1 SEE ALSO

Take a look at L<Catalyst::ActionRole::NotCacheableHeaders> to make your
action not cachable by default.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

