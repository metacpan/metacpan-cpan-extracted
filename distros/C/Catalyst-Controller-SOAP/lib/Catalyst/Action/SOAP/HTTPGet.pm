{   package Catalyst::Action::SOAP::HTTPGet;

    use base 'Catalyst::Action::SOAP';

    sub execute {
        my $self = shift;
        my ( $controller, $c ) = @_;
        $self->prepare_soap_helper($controller,$c);
        $self->next::method(@_);
    }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::HTTPGet - HTTP Get service

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This actually is here just to help delivering services that are
invoked by simple http get requests, as defined in the SOAP spec. It
won't do much, except for preparing the $c->stash->{soap} variable, so
the returns can be implemented.

=head1 TODO

There is not much to be done here.

=head1 AUTHORS

Daniel Ruoso <daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

