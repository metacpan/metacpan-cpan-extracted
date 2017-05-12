package App::CLI::Extension::Component::Config;

=pod

=head1 NAME

App::CLI::Extension::Component::Config - for App::CLI::Extension config module

=head1 VERSION

1.421

=cut

use strict;
use base qw(Class::Accessor::Grouped);

our $VERSION  = '1.421';

__PACKAGE__->mk_group_accessors( "inherited" => "_config" );
__PACKAGE__->_config({});

sub config {

    my $self = shift;

    my %hash;
    if(scalar(@_) == 1 && ref($_[0]) eq "HASH"){
        %hash = %{$_[0]};
    } elsif(scalar(@_) > 1) {
        %hash = @_;
    }
    my @keys = keys %hash;
    if (scalar(@keys) > 0) {
        map { $self->_config->{$_} = $hash{$_} } @keys;
    }
    return $self->_config;
}

1;

__END__

=head1 SEE ALSO

L<App::CLI::Extension> L<Class::Accessor::Grouped>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2010 Akira Horimoto

=cut
