package Ambrosia::CommonGatewayInterface::Options;
use strict;
use warnings;

use Getopt::Long::Descriptive 0.087;

use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::CommonGatewayInterface/],
    public  => [qw/options_spec/],
};

our $VERSION = 0.010;

sub open
{
    my $self = shift;

    my ($opt, $usage) = describe_options(@{$self->options_spec});
    $self->_handler = new Ambrosia::CommonGatewayInterface::Options::ICGI(
        __opt => $opt, __usage => $usage
    );
    return $self->SUPER::open();
}

sub error
{
    return $_[0]->_handler->usage()->text();
}

sub input_data
{
    my $self = shift;
    return $self->_handler->param(@_);
}

sub output_data
{
    return '';
}

sub redirect
{}

1;

package Ambrosia::CommonGatewayInterface::Options::ICGI;

use Ambrosia::Meta;

class sealed
{
    private => [qw/__opt __usage/],
};

sub param
{
    my $self = shift;
    if ( @_ )
    {
        my @res = map { eval { return $self->__opt->$_; } } @_;
        return wantarray ? @res : $res[0];
    }
    else
    {
        return map { $_->{name} } @{$self->__usage->{options}};
    }
}

sub usage
{
    $_[0]->__usage;
}

1;

__END__

=head1 NAME

Ambrosia::CommonGatewayInterface::Options - 

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::CommonGatewayInterface::Options> .

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
