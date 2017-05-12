package CGI::Application::Plugin::ExtJS;
{
  $CGI::Application::Plugin::ExtJS::VERSION = '1.000001';
}

# ABSTRACT: Convert paginated DBIx::Class::ResultSet's to JSON-style structures

use strict;
use warnings;

require Exporter;
use Scalar::Util 'blessed';

use base qw(Exporter AutoLoader);

our @EXPORT_OK   = qw(&ext_paginate &ext_parcel);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub ext_paginate {
   my $self      = shift;
   my $resultset = shift;
   my $method    = shift || 'TO_JSON';
   return $self->ext_parcel(
      [map { blessed($_) ? $_->$method : $_ } $resultset->all],
      $resultset->is_paged
         ? ($resultset->pager->total_entries)
         : (),
   );
}

sub ext_parcel {
   my $self   = shift;
   my $values = shift;
   my $total  = shift || scalar @{$values};

   return {
      data  => $values,
      total => $total,
   };
}

1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::ExtJS - Convert paginated DBIx::Class::ResultSet's to JSON-style structures

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

  use CGI::Application::Plugin::ExtJS ':all';

  sub people {
     # ...
     my $json = $self->ext_paginate($paginated_rs);
     # ...
  }

  sub people_lite {
     # ...
     my $json = $self->ext_paginate($paginated_rs, sub {
        my $person = shift;
        return {
           first_name => $person->first_name,
           last_name => $person->last_name,
        }
     });
     # ...
  }

  # this will call the 'foo' method on each person and put the returned
  # value into the datastructure
  sub people_more_different {
     # ...
     my $json = $self->ext_paginate($paginated_rs, 'foo');
     # ...
  }

  sub programmers_do_it_by_hand {
     # ...
     my $data = [qw{foo bar baz}];
     my $total = 10;
     my $json = $self->ext_parcel($data, $total);
     # ...
  }

  # defaults total to amount of items passed in
  sub some_programmers_do_it_by_hand_partially {
     # ...
     my $data = [qw{foo bar baz}];
     my $json = $self->ext_parcel($data);
     # ...
  }

=head1 DESCRIPTION

This module is mostly for sending L<DBIx::Class> paginated data to ExtJS based javascript code.

=head1 METHODS

=head2 ext_paginate

  my $resultset = $self->schema->resultset('Foo');
  my $results   = $self->paginate($resultset);
  my $json      = $self->ext_paginate($resultset);
  my $json_str  = to_json($json);

=head3 Description

Returns a structure like the following from the ResultSet:

  {
     data  => [@results],
     total => $count_before_pagination
  }

=head3 Valid arguments are:

  rs      - paginated ResultSet to get the data from
  coderef - any valid scalar that can be called on the result object

=head2 ext_parcel

  my $items    = [qw{foo bar baz}];
  my $total    = 7;
  my $json     = $self->ext_parcel($data, $total);
  my $json_str = to_json($json);

=head3 Description

Returns a structure like the following:

  {
     data  => [@{$items}],
     total => $total || scalar @{$items}
  }

=head3 Valid arguments are:

  list  - a list of anything you want to be in the data structure
  total - whatever you want to say the total is.  Defaults to size of
          the list passed in.

=head1 SEE ALSO

L<CGI::Application::Plugin::DBIx::Class>.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
