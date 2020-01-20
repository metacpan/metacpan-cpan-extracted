package Dash::Table;
use strict;
use warnings;
use Module::Load;

sub DataTable {
    shift @_;
    load Dash::Table::DataTable;
    return Dash::Table::DataTable->new(@_);
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Table

=head1 VERSION

version 0.06

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
