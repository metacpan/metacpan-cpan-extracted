package Acrux::DBI::Dump;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Acrux::DBI::Dump - Working with SQL dumps

=head1 SYNOPSIS

    use Acrux::DBI::Dump;

    my $dump = Acrux::DBI::Dump->new(
        dbi => $dbi
    );

    $dump->from_file('/tmp/test.sql')->poke;

=head1 DESCRIPTION

This class is used by L<Acrux::DBI> to allow database schemas import.
A dump file is just a collection of sql blocks, with one or more statements, separated by comments of the form
C<-- #NAME> or C<-- # NAME>

  -- #foo
  CREATE TABLE `pets` (`pet` TEXT);
  INSERT INTO `pets` VALUES ('cat');
  INSERT INTO `pets` VALUES ('dog');
  delimiter //
  CREATE PROCEDURE `test`()
  BEGIN
    SELECT `pet` FROM `pets`;
  END
  //

  -- #bar
  DROP TABLE `pets`;
  DROP PROCEDURE `test`;

  -- #baz (...you can comment freely here...)
  -- ...and here...
  CREATE TABLE `stuff` (`whatever` INT);

  -- #main
  DROP TABLE `stuff`;

This idea is to let you import SQL dumps step by step by its names

=head1 ATTRIBUTES

This class implements the following attributes

=head2 dbi

    $dump = $dump->dbi($dbi);
    my $dbi = $dump->dbi;

The object these processing belong to

=head2 name

    my $name = $dump->name;
    $dump = $dump->name('foo');

Name for this dump, defaults to C<schema>

=head1 METHODS

This class implements all methods from L<Mojo::Base> and implements
the following new ones

=head2 from_data

    $dump = $dump->from_data;
    $dump = $dump->from_data('main');
    $dump = $dump->from_data('main', 'file_name');

Extract dump data from a file in the DATA section of a class with
L<Mojo::Loader/"data_section">, defaults to using the caller class and
L</"name">.

  __DATA__
  @@ schema

  -- # up
  CREATE TABLE `pets` (`pet` TEXT);
  INSERT INTO `pets` VALUES ('cat');
  INSERT INTO `pets` VALUES ('dog');

  -- # down
  DROP TABLE `pets`

=head2 from_file

    $dump = $dump->from_file('/tmp/schema.sql');

Read dump data from a file

=head2 from_string

    $dump = $dump->from_string('
      -- # up
      CREATE TABLE `pets` (`pet` TEXT);

      -- # down
      DROP TABLE `pets`
    ');

Read dump data from string

=head2 peek

    my $sqls = $dump->peek; # 'main'
    my $sqls = $dump->peek('foo');
    my @sqls = $dump->peek('foo');

This method returns an array/arrayref of SQL statements stored at a specified dump location by tag-name.
By default will be used the C<main> tag

=head2 poke

    $dump = $dump->poke; # 'main'
    $dump = $dump->poke('foo');

Import named data-block of SQL dump to database by tag-name. By default will be used the C<main> tag

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acrux::DBI>, L<Mojo::mysql>, L<Mojo::Pg>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.01';

use Mojo::Base -base;

use Mojo::Loader qw/data_section/;
use Mojo::File qw/path/;

use constant {
    DELIMITER   => ';',
    TAG_DEFAULT => 'main',
};

has name => 'schema';
has 'dbi';
has 'pool' => sub {{}};

sub from_string {
    my $self = shift;
    my $s = shift;
    return $self unless defined $s;
    my $pool = $self->{pool} = {};
    my $tag = TAG_DEFAULT;
    my $delimiter = DELIMITER;
    my $is_new = 1;
    my $buf = '';

    # String processing
    while (length($s)) {
        my $chunk;

        # get fragments (chunks) from string
        if ($s =~ /^$delimiter/x) { # any delimiter char(s)
            $is_new = 1;
            $chunk = $delimiter;
        } elsif ($s =~ /^delimiter\s+(\S+)\s*(?:\n|\z)/ip) { # set new delimiter
            $is_new = 1;
            $chunk = ${^MATCH};
            $delimiter = $1;
        } elsif ($s =~ /^(\s+)/s or $s =~ /^(\w+)/) { # whitespaces or general name
            $chunk = $1;
        } elsif ($s =~ /^--.*(?:\n|\z)/p                            # double-dash comment
                or $s =~ /^\#.*(?:\n|\z)/p                          # hash comment
                or $s =~ /^\/\*(?:[^\*]|\*[^\/])*(?:\*\/|\*\z|\z)/p # C-style comment
                or $s =~ /^'(?:[^'\\]*|\\(?:.|\n)|'')*(?:'|\z)/p    # single-quoted literal text
                or $s =~ /^"(?:[^"\\]*|\\(?:.|\n)|"")*(?:"|\z)/p    # double-quoted literal text
                or $s =~ /^`(?:[^`]*|``)*(?:`|\z)/p ) {             # schema-quoted literal text
            $chunk = ${^MATCH};
        } else {
            $chunk = substr($s, 0, 1);
        }
        #say STDERR ">$chunk<";

        # cut string by chunk length
        substr($s, 0, length($chunk), '');

        # marker
        if ($chunk =~ /^--\s+[#]+\s*(\w+)/i) {
            my $_tag = $1 // TAG_DEFAULT;
            push @{$pool->{$tag} //= []}, $buf if length($tag) and $buf !~ /^\s*$/s;
            $tag = $_tag;
            $is_new = 0;
            $buf = '';
            $delimiter = DELIMITER; # flush delimiter to default
        }

        # make new block
        if ($is_new) {
            push @{$pool->{$tag} //= []}, $buf if length($tag) and $buf !~ /^\s*$/s;
            $is_new = 0;
            $buf = '';
        } else { # Or add cur chunk to section
            $buf .= $chunk;
        }
    }

    # add buf line to block
    push @{$pool->{$tag} //= []}, $buf if length($tag) and $buf !~ /^\s*$/s;

    return $self;
}
sub from_data {
    my $self = shift;
    my $class = shift;
    my $name = shift;
    return $self->from_string(data_section($class //= caller, $name // $self->name));
}
sub from_file {
    my $self = shift;
    my $file = shift;
    return $self->from_string(path($file)->slurp('UTF-8'));
}
sub poke {
    my $self = shift;
    my $tag = shift || TAG_DEFAULT;
    my $sqls = $self->pool->{$tag} || [];
    my $dbi = $self->dbi;
    return $self unless $dbi and $dbi->ping;

    # Import statements
    foreach my $sql (@$sqls) {
        #print STDERR $sql, "\n";
        $dbi->query($sql) or last;
    }

    return $self;
}
sub peek {
    my $self = shift;
    my $tag = shift || TAG_DEFAULT;
    my $sqls = $self->pool->{$tag} || [];
    return wantarray ? (@$sqls) : [@$sqls]; # copy of data
}

1;

__END__
