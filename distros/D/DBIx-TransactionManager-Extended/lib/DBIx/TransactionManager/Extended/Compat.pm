package DBIx::TransactionManager::Extended::Compat;
use strict;
use warnings;

use DBIx::TransactionManager;
use DBIx::TransactionManager::Extended;

*_super_new = DBIx::TransactionManager->can('new');

{
    no warnings qw/redefine/;
    *DBIx::TransactionManager::new = \&_new;
}

sub _new { _super_new('DBIx::TransactionManager::Extended', @_[1..$#_])->_initialize() }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

DBIx::TransactionManager::Extended::Compat - compatibility with DBIx::TransactionManager

=head1 SYNOPSIS

    use DBIx::TransactionManager;
    use DBIx::TransactionManager::Extended::Compat;

    DBIx::TransactionManager->new(); # returns DBIx::TransactionManager::Extended object

=head1 DESCRIPTION

If this module is loaded, it applys patches for L<DBIx::TransactionManager> to create L<DBIx::TransactionManager::Extended> object.

=head1 SEE ALSO

L<DBIx::TransactionManager>
L<DBIx::TransactionManager::Extended>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
