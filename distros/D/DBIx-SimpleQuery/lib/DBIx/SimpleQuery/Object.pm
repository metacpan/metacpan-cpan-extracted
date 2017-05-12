##
## File: DBIx/SimpleQuery/Object.pm
## Author: Steve Simms
##
## Revision: $Revision$
## Date: $Date$
##
## An object created by DBIx::SimpleQuery which holds the results of a
## query.
##

package DBIx::SimpleQuery::Object;

use strict;

use overload
    '""'   => \&as_string,
    '0+'   => \&as_integer,
    'bool' => \&as_boolean,
    '@{}'  => \&as_arrayref,
    '<<'   => \&left_shift,
    '>>'   => \&right_shift,
    '<>'   => \&as_iterative;

sub new {
    my $class = shift;
    my $params = shift;
    return bless $params, $class;
}

sub as_string {
    my $self = shift();
    my @results = @{$self->{"results"}};
    if (not scalar @results and $self->{"field_count"} == 1) {
	return "";
    }
    elsif (scalar @results == 1) {
	my $first_result = $results[0];
	if ($self->{"field_count"} == 1) {
	    my @keys = keys %{$first_result};
	    my $key = shift(@keys);
	    return $first_result->{$key};
	}
    }
    return $self->{"count"};
}

sub as_integer {
    my $self = shift();
    return $self->{"count"};
}

sub as_boolean {
    my $self = shift();
    return ($self->{"count"} ? 1 : 0);
}

sub as_arrayref {
    my $self = shift();
    return $self->{"results"};
}

sub left_shift {
    my ($self, $i) = @_;
    $i = 1 unless defined $i;
    return $self->{"results"}->[$i-1];
}

sub right_shift {
    my ($self, $i) = @_;
    $i = 1 unless defined $i;
    left_shift($self, $i*-1+1);
}

sub as_iterative {
    my $self = shift();
    return $self->{"results"}->[$self->{"iter"}++];
}

1;

__END__

=head1 NAME

DBIx::SimpleQuery::Object - An object containing the results of a DBIx::SimpleQuery::query.

=head1 SYNOPSIS

  use DBIx::SimpleQuery;
  
  DBIx::SimpleQuery::set_defaults({
      "dsn"      => "DBI:Pg:test_database",
      "user"     => "test_user",
      "password" => "test_password",
  });
  
  # Perform maintenance on users
  foreach my $user (query "SELECT * FROM users") {
      my $user_id = $user->{"user_id"};

      # Does this user have a password?
      unless (query "SELECT * FROM passwords WHERE user_id = $user_id") {
          print "User $user_id does not have a password!\n";
      }

      # How many widgets do they have?
      my $widget_count = query "SELECT * FROM widgets WHERE user_id = $user_id";
      print "User $user_id has $widget_count widgets.\n";

      # Get their first and last widgets
      my $first_widget <<= query "SELECT * FROM widgets WHERE user_id = $user_id ORDER BY time";
      my $last_widget >>= query "SELECT * FROM widgets WHERE user_id = $user_id ORDER BY time";
  }

=head1 DESCRIPTION

DBIx::SimpleQuery::Object is a background module that allows a
programmer to interact with the results of a query without having to
resort to a structure like:

  my $first_row_id = @{$results_arrayhashref}->[0]->{"user_id"};

Instead, it overloads the stringify, boolify, and other -ify functions
to return values that the programmer wants, without needing all of the
extra markup.

It should never be generated directly, but only as a result of a
DBIx::SimpleQuery::query call.  Use the synopsis above to get some
ideas of how it works.

=head1 AUTHOR

Steve Simms (ssimms@cpan.org)

=head1 COPYRIGHT

Copyright 2004 Steve Simms.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

DBI
DBIx::SimpleQuery

=cut
