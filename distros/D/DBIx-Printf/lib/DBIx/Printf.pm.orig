use strict;
use warnings;

use DBI;
use Carp::Clan;

package DBIx::Printf;

our $VERSION = '0.07';

sub _printf {
    my ($dbh, $fmt, $params, $in_like) = @_;
    
    $fmt =~ s/\%(?:([dfst\%])|like\((.*?)\))/
        _printf_quote({
            dbh      => $dbh,
            params   => $params,
            type     => $1 || 'like',
            like_fmt => $2,
            in_like  => $in_like,
        })
            /eg;
    $fmt;
}

sub _printf_quote {
    my $in = shift;
    my $out;
    
    if ($in->{type} eq '%') {
        return '%';
    } elsif ($in->{type} eq 'like') {
        return "'"
            . _printf($in->{dbh}, $in->{like_fmt}, $in->{params}, 1)
                . "'";
    }
    
    return _printf_quote_simple(
        $in->{dbh}, $in->{type}, $in->{params}, $in->{in_like}
    );
}

sub _printf_quote_simple {
    no warnings;
    my ($dbh, $type, $params, $in_like) = @_;
    
    Carp::Clan::croak "too few parameters\n" unless @$params;
    my $param = shift @$params;
    
    if ($type eq 'd') {
        $param = int($param);
    } elsif ($type eq 'f') {
        $param = $param + 0;
    } elsif ($type eq 'l') {
        $param = s/[\%_]/\\$1/g;
        $param = $dbh->quote($param); # be paranoiac, use DBI::db::quote
        $param =~ s/^'(.*)'$/$1/s
            or Carp::Clan::croak "unexpected quote char used: $param\n";
    } elsif ($type eq 's') {
        if ($in_like) {
            $param =~ s/[%_]/\\$&/g;
        }
        $param = $dbh->quote($param);
        if ($in_like) {
            $param =~ s/^'(.*)'$/$1/s
                or Carp::Clan::croak "unexpected quote char: $param\n";
        }
    } elsif ($type eq 't') {
        # pass thru
    } else {
        Carp::Clan::croak "unexpected type: $type\n";
    }
    
    $param;
}

package main;

sub DBI::db::printf {
    my ($dbh, $fmt, @params) = @_;
    
    my $sql = DBIx::Printf::_printf($dbh, $fmt, \@params);
    Carp::Clan::croak "too many parameters\n" if @params;
    $sql;
}

1;

__END__

=head1 NAME

DBIx::Printf - A printf-style prepared statement

=head1 SYNOPSIS

  use DBIx::Printf;

  my $sql = $dbh->printf(
      'select * from t where str=%s or int=%d or float=%f',
      'string',
      1,
      1.1e1);

=head1 DESCRIPTION

C<DBIx::Printf> is a printf-style prepared statement.  It adds a C<printf> method to DBI::db package.

=head1 METHODS

=head2 printf(stmt, [values])

Builds a SQL statement from given statement with placeholders and values.  Following placeholders are supported.

  %d         - integer
  %f         - floating point
  %s         - string
  %t         - do not quote, pass thru
  %like(fmt) - formats and quotes a string for like expression

=head3 %like example

Below is an example of using the %%like placeholder.  Since metacharacters of supplied parameters are escaped, the example would always by a prefix search.

  $dbh->printf('select * from t where name like %like(%s%%)', $name);


=head1 AUTHOR

Copyright (c) 2007 Kazuho Oku  All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
