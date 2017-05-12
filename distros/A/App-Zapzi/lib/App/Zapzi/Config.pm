package App::Zapzi::Config;
# ABSTRACT: routines to access Zapzi configuration


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use App::Zapzi;
use Carp;


sub get
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;

    my $rs = _config()->find({name => $key});
    return $rs ? $rs->value : undef;
}


sub set
{
    my ($key, $value) = @_;

    croak 'Key and value need to be provided'
        unless $key && defined($value);

    if (! _config()->update_or_create({name => $key, value => $value}))
    {
        croak("Could not add $key=$value to config");
    }

    return 1;
}


sub delete
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;

    my $rs = _config()->find({name => $key});
    return 1 unless $rs;

    return $rs->delete;
}


sub get_keys
{
    my $rs = _config()->search(undef);

    my @keys;
    while (my $item = $rs->next)
    {
        push @keys, $item->name;
    }

    return @keys;
}

# Convenience function to get the DBIx::Class::ResultSet object for
# this table.

sub _config
{
    return App::Zapzi::get_app()->database->schema->resultset('Config');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Config - routines to access Zapzi configuration

=head1 VERSION

version 0.017

=head1 DESCRIPTION

These routines allow access to Zapzi configuration via the database.

=head1 METHODS

=head2 get(key)

Returns the value of C<key> or undef if it does not exist.

=head2 set(key, value)

Set the config parameter C<key> to C<value>.

=head2 delete(key)

Delete the config item identified by C<key>. If the key does not exist
then ignore the request.

=head2 get_keys

Returns a list of keys in the config store.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
