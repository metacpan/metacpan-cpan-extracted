[![Build Status](https://travis-ci.org/karupanerura/Cache-Keys-DSL.svg?branch=master)](https://travis-ci.org/karupanerura/Cache-Keys-DSL)
# NAME

Cache::Keys::DSL - Declare cache key generator by DSL

# SYNOPSIS

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

# DESCRIPTION

Cache::Keys::DSL provides DSL for declaring cache key.

# FUNCTIONS

- `key $name`

    For declaring static key.
    It generates exportable constant subroutine named `key_for_$name`.

- `keygen $name`

    For declaring dynamic key.
    It generates exportable subroutine named `gen_key_for_$name`.

- `with_version $name, $version`

    For declaring cache version.

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
