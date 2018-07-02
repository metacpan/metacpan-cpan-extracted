package Data::MuForm::Model::DBIC;
# ABSTRACT: MuForm class with DBIC model already applied

use Moo;
extends 'Data::MuForm';
with 'Data::MuForm::Role::Model::DBIC';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Model::DBIC - MuForm class with DBIC model already applied

=head1 VERSION

version 0.03

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
