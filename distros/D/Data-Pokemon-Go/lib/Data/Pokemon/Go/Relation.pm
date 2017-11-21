package Data::Pokemon::Go::Relation;
use 5.008001;

use Moose;
extends 'Data::Pokemon::Go::Relation::Dual';

sub BUILD {
    my $self = shift;
    return Data::Pokemon::Go::Relation::Dual->new(@_);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=encoding utf-8

=head1 NAME

Data::Pokemon::Go::Relation - It's new $module

=head1 SYNOPSIS

    use Data::Pokemon::Go::Relation;

=head1 DESCRIPTION

Data::Pokemon::Go::Relation is ...

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut
