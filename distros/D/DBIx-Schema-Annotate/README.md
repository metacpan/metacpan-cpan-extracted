# NAME

DBIx::Schema::Annotate - Add table schema as comment to your ORM file. This module is inspired by annotate\_models.

# SYNOPSIS

    use DBIx::Schema::Annotate;

    my $dbh = DBI->connect('....') or die $DBI::errstr;
    my $annotate = DBIx::Schema::Annotate->new( dbh => $dbh );
    $annotate->write_files(
      dir       => '...',
      exception_rule => {
        # todo
      }
    );

    # Amon2 + Teng
    $ carton exec -- perl -Ilib -MMyApp -MDBIx::Schema::Annotate -e 'my $c = MyApp->bootstrap; DBIx::Schema::Annotate->new( dbh => $c->db->{dbh})->write_files(dir => q!lib/MyApp/DB/Row/!)'

# DESCRIPTION

Schema is added to pm file of specified path follower of the same camelize name as table.

For example 'post' table and 'post\_comment' table exist, and we assume that $self->write\_files(dir => $dir) was carried out.
The targets to which DBIx::Schema::Annotate adds a annotate are $dir/Post.pm and $dir/PostComment.pm.

This module is supporting MySQL and SQLite.

# METHODS

## new( dbh => $dbh )

Constructor.

## write\_files( dir => 'path/to/...' )

Schema is added to pm file of 'path/to/...' follower of the same camelize name as table.

# LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokubass <tokubass@cpan.org>
