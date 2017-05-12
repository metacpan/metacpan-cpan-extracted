package DBIx::Placeholder::Named;

use warnings;
use strict;

use base qw(DBI);

our $VERSION = '0.08';
our $PREFIX  = ':';
our $SUFFIX  = '';

use constant {
    ATTR       => 3,
    OLD_DRIVER => 4,
};

sub connect {
    my ( $class, @args ) = @_;

    my ( $prefix, $suffix );

    if ( $args[ATTR] and ref( $args[ATTR] ) eq 'HASH' ) {
        $prefix = delete $args[ATTR]{PlaceholderPrefix}
          if ( exists $args[ATTR]{PlaceholderPrefix} );
        $suffix = delete $args[ATTR]{PlaceholderSuffix}
          if ( exists $args[ATTR]{PlaceholderSuffix} );
    }

    my $self = $class->SUPER::connect(@args);

    $self->{private_dbix_placeholder_named_info}{prefix} =
      defined $prefix ? $prefix : ':';
    $self->{private_dbix_placeholder_named_info}{suffix} =
      defined $suffix ? $suffix : '';

    return $self;
}

sub connect_cached {
    my ( $class, @args ) = @_;

    my ( $prefix, $suffix );

    if ( $args[ATTR] and ref( $args[ATTR] ) eq 'HASH' ) {
        $prefix = delete $args[ATTR]{PlaceholderPrefix}
          if ( exists $args[ATTR]{PlaceholderPrefix} );
        $suffix = delete $args[ATTR]{PlaceholderSuffix}
          if ( exists $args[ATTR]{PlaceholderSuffix} );
    }

    my $self = $class->SUPER::connect_cached(@args);

    $self->{private_dbix_placeholder_named_info}{prefix} =
      defined $prefix ? $prefix : ':';
    $self->{private_dbix_placeholder_named_info}{suffix} =
      defined $suffix ? $suffix : '';

    return $self;
}

package DBIx::Placeholder::Named::db;

use SQL::Tokenizer;
use base qw(DBI::db);

sub prepare {
    my ( $dbh, $query ) = @_;

    # each token is analyzed. if the token starts with ':', it is pushed to
    # @tao_dbi_placeholders. each element represents the named placeholder,
    # and its index represents the order we will create the
    # DBI::st::execute()'s argument (see Tao::DBI::st::execute()).
    #
    # TODO: someday we can benchmark this piece of code and check if using
    # substr is more efficient.

    my @placeholders;
    my @query_tokens = SQL::Tokenizer->tokenize($query);

    my $prefix = $DBIx::Placeholder::Named::PREFIX;
    my $suffix = $DBIx::Placeholder::Named::SUFFIX;

    if ( exists $dbh->{private_dbix_placeholder_named_info} ) {
        $prefix = $dbh->{private_dbix_placeholder_named_info}{prefix};
        $suffix = $dbh->{private_dbix_placeholder_named_info}{suffix};
    }

    my $prefix_length = length($prefix);
    my $suffix_length = length($suffix);

    foreach my $token (@query_tokens) {
        my $token_length = length($token);
        if (    substr( $token, 0, $prefix_length ) eq $prefix
            and substr( $token, $token_length - $suffix_length, $suffix_length ) eq $suffix )
        {
            my $token_stripped = substr( $token, $prefix_length );
            $token_stripped =
              substr( $token_stripped, 0, length($token_stripped) - $suffix_length );
            push @placeholders, $token_stripped;
            $token = '?';
        }
    }

    my $new_query = join '', @query_tokens;

    # it's time to call DBI::st::prepare(). we use the modified tokenized
    # query (with all named placeholders substituted by '?').

    my $sth = $dbh->SUPER::prepare($new_query)
      or return;

    # we can now store the named placeholders array.
    $sth->{private_dbix_placeholder_named_info} =
      { placeholders => \@placeholders };

    return $sth;
}

package DBIx::Placeholder::Named::st;

use base qw(DBI::st);

sub execute {
    my $sth = shift;

    my @params;

    if ( ref $_[0] eq 'HASH' ) {

        # create the DBI::st::execute()'s parameter. we iterate each named
        # placeholder stored in Tao::DBI::db::prepare() and retrieve its value
        # from the user supplied dictionary.

        @params =
          map { $_[0]->{$_} } @{ $sth->{private_dbix_placeholder_named_info}->{placeholders} };

    }
    else {

        # user haven't supplied a dictionary, so we use the parameters 'as is'
        @params = @_;
    }

    # DBI::st::execute() always returns.
    my $rv = $sth->SUPER::execute(@params);

    return $rv;
}

1;

=pod

=head1 NAME

DBIx::Placeholder::Named - DBI with named placeholders

=head1 SYNOPSIS

  use DBIx::Placeholder::Named;

  my $dbh = DBIx::Placeholder::Named->connect($dsn, $user, $password)
    or die DBIx::Placeholder::Named->errstr;

  my $sth = $dbh->prepare(
    q{ INSERT INTO some_table (this, that) VALUES (:this, :that) }
  )
    or die $dbh->errstr;

  $sth->execute({ this => $this, that => $that, });

  $dbh =
    DBIx::Placeholder::Named->connect( $dsn, $user, $password,
      { PlaceholderPrefix => '__', PlaceholderSuffix => '**' } );

  my $sth = $dbh->prepare(
    q{ INSERT INTO some_table (this, that) VALUES (__this**, __that**) }
  );

=head1 DESCRIPTION

DBIx::Placeholder::Named is a subclass of DBI, which implements the ability 
to understand named placeholders.

=head1 METHODS

=over 4

=item DBIx::Placeholder::Named::connect()

This method, overloaded from L<DBI|DBI>, is responsible to create a
new connection to database. It is overloaded to accept new keywords
within the C<$attr> hash.

  my $dbh =
    DBIx::Placeholder::Named->connect( $dsn, $user, $password,
      { RaiseError => 1, PlaceholderSuffix => '', PlaceholderPrefix => ':', } );

By default, C<PlaceholderPrefix> is C<:> and C<PlaceholderSuffix> is
empty string.

=item DBIx::Placeholder::Named::connect_cached()

This method, overloaded from L<DBI|DBI>, is responsible to create a
cached connection to database. It is overloaded to accept new keywords
within the C<$attr> hash.

  my $dbh =
    DBIx::Placeholder::Named->connect_cached( $dsn, $user, $password,
      { RaiseError => 1, PlaceholderSuffix => '', PlaceholderPrefix => ':', } );

By default, C<PlaceholderPrefix> is C<:> and C<PlaceholderSuffix> is
empty string.

=item DBIx::Placeholder::Named::db::prepare()

This method, overloaded from L<DBI|DBI::db>, is responsible to create a prepared 
statement for further execution. It is overloaded to accept a SQL query which
has named placeholders, like:

  SELECT a, b, c FROM t WHERE id = :id

It uses L<SQL::Tokenizer|SQL::Tokenizer> to correctly tokenize the SQL query,
preventing extract erroneous placeholders (date/time specifications, comments,
inside quotes or double quotes, etc).

=item DBIx::Placeholder::Named::st::execute()

=back

=cut

=head1 THANKS

Gabor Szabo <szabgab@gmail.com> for requesting prefix support.

=head1 AUTHOR

Copyright (c) 2007, Igor Sutton Lopes "<IZUT@cpan.org>". All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<SQL::Tokenizer>

=cut

