package Cache::Keys::DSL;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Exporter 5.57 ();

sub import {
    my ($class, %args) = @_;
    my $caller = caller;

    my $base_version = $args{base_version};

    my %export;
    $export{key}    = _key($base_version);
    $export{keygen} = _keygen($base_version);
    for my $name (keys %export) {
        my $code = $export{$name};

        no strict qw/refs/;
        *{"${caller}::${name}"} = $code;
    }

    {
        local $Exporter::ExportLevel = 1;
        Exporter->import('import');
    }

    no strict qw/refs/;
    no warnings qw/once/;
    *{"${caller}::with_version"} = \&_with_version;
    @{"${caller}::EXPORT_OK"}    = ();
    %{"${caller}::EXPORT_TAGS"}  = (all => \@{"${caller}::EXPORT_OK"});
}

sub _with_version($$) {## no critic
    my $name    = shift;
    my $version = shift;
    return [$name, $version];
}

sub _key {
    my $base_version = shift;
    return sub ($) { ## no critic
        my $name = shift;

        my @versions;
        ($name, @versions) = @$name  if ref $name eq 'ARRAY';
        unshift @versions => $base_version if defined $base_version;

        my $caller  = caller;
        my $subname = "key_for_$name";
        my $value   = join '_', $name, @versions;
        my $code    = sub () { $value }; ## no critic
        {
            no strict 'refs'; ## no critic
            *{"${caller}::${subname}"}  = $code;
            push @{"${caller}::EXPORT_OK"} => $subname;
        }
    };
}

sub _keygen {
    my $base_version = shift;
    return sub ($;&) { ## no critic
        my ($name, $generator) = @_;
        $generator ||= sub { @_ };

        my @versions;
        ($name, @versions) = @$name  if ref $name eq 'ARRAY';
        unshift @versions => $base_version if defined $base_version;

        my $caller  = caller;
        my $subname = "gen_key_for_$name";
        my $code    = sub { join '_', $name, @versions, $generator->(@_) };
        {
            no strict 'refs'; ## no critic
            *{"${caller}::${subname}"}  = $code;
            push @{"${caller}::EXPORT_OK"} => $subname;
        }
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Cache::Keys::DSL - Declare cache key generator by DSL

=head1 SYNOPSIS

    package MyProj::Keys;
    use Cache::Keys::DSL base_version => 0.01; # base_version is optional

    key 'all_items';
    keygen 'item';

    keygen 'user';

    keygen with_version user_item => 0.01, sub {
        my ($user, $item) = @_;
        return $user->{id}, $item->{id};
    };

    1;

    package MyProj;
    use MyProj::Keys qw/key_for_all_items gen_key_for_item gen_key_for_user gen_key_for_user_item/;

    sub search_all_items {
        my $key = key_for_all_items();
        $cache->get_or_set($key => sub { $dbh->selectall_arrayref('SELECT * FROM item ORDER BY id', { Slice => {} }) });
    }

    sub fetch_item_by_id {
        my $item_id = shift;
        my $key = gen_key_for_item($item_id);
        $cache->get_or_set($key => sub { $dbh->selectrow_hashref('SELECT * FROM item WHERE id = ?', undef, $item_id) });
    }

    sub fetch_user_by_id {
        my $user_id = shift;
        my $key = gen_key_for_user($user_id);
        $cache->get_or_set($key => sub { $dbh->selectrow_hashref('SELECT * FROM user WHERE id = ?', undef, $user_id) });
    }

    sub fetch_user_item {
        my ($user, $item) = @_;
        my $key = gen_key_for_user_item($user, $item);
        $cache->get_or_set($key => sub {
            $dbh->selectrow_hashref('SELECT * FROM user_item WHERE user_id = ? AND item_id = ?', undef, $user->{id}, $item->{id});
        });
    }

=head1 DESCRIPTION

Cache::Keys::DSL provides DSL for declaring cache key.

=head1 FUNCTIONS

=over 4

=item C<key $name>

For declaring static key.
It generates exportable constant subroutine named C<key_for_$name>.

=item C<keygen $name>

For declaring dynamic key.
It generates exportable subroutine named C<gen_key_for_$name>.

=item C<with_version $name, $version>

For declaring cache version.

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

