package DBIx::ObjectMapper::Mapper::Constructor;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Params::Validate qw(:all);

my @CONSTRUCTOR_ARGUMENT_TYPES = qw( HASHREF HASH ARRAYREF ARRAY );

sub new {
    my $class  = shift;
    my $mapper = shift;
    my %option = validate(
        @_,
        {   name     => { type => SCALAR, default => 'new' },
            arg_type => {
                type      => SCALAR,
                default   => 'HASHREF',
                callbacks => { valid_arg => \&is_valid_arg_type }
            },
            auto => { type => BOOLEAN, default => 0 },
        },
    );

    return bless \%option, $class;
}

sub is_valid_arg_type { grep { $_[0] eq $_ } @CONSTRUCTOR_ARGUMENT_TYPES }

sub name         { $_[0]->{name} }
sub arg_type     { $_[0]->{arg_type} }
sub auto         { $_[0]->{auto} }
sub set_name     { $_[0]->{name} = $_[1] }
sub set_arg_type {
    confess "$_[1] is invalid arg_type" unless is_valid_arg_type($_[1]);
    $_[0]->{arg_type} = $_[1];
}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Mapper::Constructor

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

