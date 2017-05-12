package App::Nopaste::Service::Linode;
our $VERSION = '0.06';
use strict;
use warnings;
use base 'App::Nopaste::Service::AnyPastebin';

sub uri { "http://p.linode.com" }

sub get {
    my $self = shift;
    my $mech = shift;
    my %args = @_;

    $args{username} ||= 'no';
    $args{password} ||= 'spam';
    
    return $self->SUPER::get($mech => %args);
}

sub post_content {
    my ($self, %args) = @_;

    my $content = $self->SUPER::post_content(%args);

    # On p.linode.com the code2 parameter is called code2z for some
    # reason.
    $content->{code2z} = delete $content->{code2};

    return $content;
}

=head1 NAME

App::Nopaste::Service::Linode - L<App::Nopaste> interface to L<http://p.linode.com>

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=cut

1;

