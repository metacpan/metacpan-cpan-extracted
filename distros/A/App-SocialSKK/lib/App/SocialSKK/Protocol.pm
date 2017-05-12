package App::SocialSKK::Protocol;
use strict;
use warnings;
use base qw(App::SocialSKK::Base);

my %dispatch_table = (
    1 => 'on_get_candidates',
    2 => 'on_get_version',
    3 => 'on_get_serverinfo',
);

__PACKAGE__->mk_accessors(values %dispatch_table);

sub accept {
    my ($self, $input) = @_;
    return if !defined $input;
    my ($code, $text) = $input =~ /^(\d)(.+)?\s*$/ismx;
    $self->dispatch($code, $text);
}

sub dispatch {
    my ($self, $code, $text) = @_;
    return if !defined $code;
    my $method = $dispatch_table{$code} or return;
    $self->$method->($text);
}

1;
