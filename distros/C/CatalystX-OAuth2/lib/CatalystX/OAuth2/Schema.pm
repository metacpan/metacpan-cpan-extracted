package CatalystX::OAuth2::Schema;
use base qw(DBIx::Class::Schema);
__PACKAGE__->load_namespaces;

# ABSTRACT: A L<DBIx::Class> schema for use as the backend of the DBIC OAuth2 store

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Schema - A L<DBIx::Class> schema for use as the backend of the DBIC OAuth2 store

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
