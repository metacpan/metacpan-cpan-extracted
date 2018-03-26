package DBIx::Class::InflateColumn::DT;

use strict;
use warnings;

use DT;
use base 'DBIx::Class::InflateColumn::DateTime';

our $VERSION = '0.1.0';

sub _post_inflate_datetime {
    my $self = shift;
    
    my $dt = $self->SUPER::_post_inflate_datetime(@_);
    
    bless $dt, 'DT';
    
    return $dt;
}

1;

__END__
=pod

=begin readme text

DBIx::Class::InflateColumn::DT
==============================

=end readme

=for readme stop

=head1 NAME

DBIx::Class::InflateColumn::DT - Inflate DBIx::Class columns to DT objects

=head1 SYNOPSIS

    package Foo::Schema::Result::Bar;
    
    use base 'DBIx::Class::Core';
    
    __PACKAGE__->load_components('InflateColumn::DT');
    __PACKAGE__->table('bars');
    
    __PACKAGE__->add_columns(
        consumed => {
            data_type => "timestamp with time zone",
            default_value => \"current_timestamp",
            is_nullable => 0,
        },
        ...
    );

=head1 DESCRIPTION

=for readme continue

This module is a tiny wrapper around L<DBIx::Class::InflateColumn::DateTime>
that does literally one thing: reblesses inflated L<DateTime> objects into L<DT>
objects.

This is to allow working with database C<timestamp> column values without the
need for lots of boilerplate just to compare them with current time.

=head1 INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make && make test && make install

=head1 DEPENDENCIES

L<DBIx::Class::InflateColumn::DateTime> is the parent for this class, and L<DT>
is the result.

=for readme stop

=head1 REPORTING BUGS

No doubt there are some. Please post an issue on GitHub (see below)
if you find something. Pull requests are also welcome.

GitHub repository: https://github.com/nohuhu/DBIx-Class-InflateColumn-DT

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 by Alex Tokarev E<lt>nohuhu@cpan.orgE<gt>.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<"perlartistic">.

=for readme stop

=cut
