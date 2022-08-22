package Dash::Table;
use strict;
use warnings;
use Module::Load;

sub DataTable {
    shift @_;
    load Dash::Table::DataTable;
    if ( Dash::Table::DataTable->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Table::DataTable->new(@_);
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Table

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
