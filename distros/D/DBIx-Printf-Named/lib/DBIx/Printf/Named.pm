use strict;
use warnings;

use DBI;
use Carp::Clan;

package DBIx::Printf::Named;

use Regexp::Common qw /balanced/;

our $VERSION = '0.01';

sub _printf {
    my ($dbh, $fmt, $params, $in_like, $like_escape) = @_;
    my $re = $RE{balanced}{-parens=>'()'}{-keep};
    $fmt =~ s/\%(?:\((.+?)\)([dfst])|like$re((?i)\s+ESCAPE\s+(['"])(.*?)\5(?:\s+|$))?|(\%))/
        _printf_quote({
            dbh      => $dbh,
            params   => $params,
            key      => $1,
            type     => $2 || ( $7 || 'like'),
            like_fmt => $3,
            like_escape => $4,
            like_escape_char => defined $like_escape ? $like_escape : $6,
            in_like  => $in_like,
        })
            /eg;
    $fmt;
}

sub _printf_quote {
    my $in = shift;

    if ($in->{type} eq '%') {
        return '%';
    } elsif ($in->{type} eq 'like') {
        $in->{like_fmt} =~ s/(:?^\(|\)$)//g if $in->{like_fmt};
        return "'"
            . _printf($in->{dbh}, $in->{like_fmt}, $in->{params}, 1, $in->{like_escape_char})
                . "'" . ($in->{like_escape} || '');
    }
    $in->{params} ||= {};
    Carp::Clan::croak "$in->{key} is not exists in parameters" 
            if ! exists $in->{params}->{$in->{key}};

    return _printf_quote_simple(
        $in->{dbh}, $in->{type}, $in->{params}->{$in->{key}}, $in->{in_like}, $in->{like_escape_char}
    );
}

sub _printf_quote_simple {
    no warnings;
    my ($dbh, $type, $param, $in_like, $like_escape_char) = @_;
        
    if ($type eq 'd') {
        $param = int($param);
    } elsif ($type eq 'f') {
        $param = $param + 0;
    } elsif ($type eq 's') {
        if ($in_like) {
            my $escape_char = defined $like_escape_char ? $like_escape_char : '\\';
            $param =~ s/[${escape_char}%_]/$escape_char$&/g;
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

sub DBI::db::nprintf {
    my ($dbh, $fmt, $params) = @_;
    
    my $sql = DBIx::Printf::Named::_printf($dbh, $fmt, $params);
    $sql;
}

1;

1;
__END__

=head1 NAME

DBIx::Printf::Named - A named-printf-style prepared statement

=head1 SYNOPSIS

  use DBIx::Printf::Named;

  use DBIx::Printf;

  my $sql = $dbh->nprintf(
      'select * from t where str=%(str)s or int=%(int)d or float=%(float)f',
      {
          str => 'string',
          int => 1,
          float => 1.1e1
      }
  );

=head1 DESCRIPTION

C<DBIx::Printf::Named> is a named-printf-style prepared statement.  It adds a C<nprintf> method to DBI::db package.
This module is based on C<DBIx::Printf> by kazuho oku.

=head2 nprintf(stmt, { key1 => value1, key2 => value2 })

Builds a SQL statement from given statement with placeholders and values.  Following placeholders are supported.

  %(key)d         - integer
  %(key)f         - floating point
  %(key)s         - string
  %(key)t         - do not quote, pass thru
  %like(fmt) - formats and quotes a string for like expression

=head3 %like example

Below is an example of using the %%like placeholder.  Since metacharacters of supplied parameters are escaped, the example would always by a prefix search.

  $dbh->printf('select * from t where name like %like(%(name)s%%)', { name => $name });

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

C<DBIx::Printf>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
