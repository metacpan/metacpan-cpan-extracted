package Catalyst::TraitFor::Controller::DoesExtPaging;
{
  $Catalyst::TraitFor::Controller::DoesExtPaging::VERSION = '1.000001';
}

use Moose::Role;
use Web::Util::ExtPaging ':all' => { -prefix => '_' };

# ABSTRACT: Paginate DBIx::Class::ResultSets for ExtJS consumption

has root => (
   is      => 'ro',
   isa     => 'Str',
   default => 'data',
);

has total_property => (
   is      => 'ro',
   isa     => 'Str',
   default => 'total',
);

sub ext_paginate {
   my $self      = shift;
   return _ext_paginate(@_, {
      root => $self->root,
      total_property => $self->total_property,
   });
}

sub ext_parcel {
   my $self   = shift;

   return _ext_parcel(@_, {
      root => $self->root,
      total_property => $self->total_property,
   });
}

1;

__END__

=pod

=head1 NAME

Catalyst::TraitFor::Controller::DoesExtPaging - Paginate DBIx::Class::ResultSets for ExtJS consumption

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

  package MyApp::Controller;

  use Moose;
  BEGIN { extends 'Catalyst::Controller' }

  # a single with would be better, but we can't do that
  # see: http://rt.cpan.org/Public/Bug/Display.html?id=46347
  with 'Catalyst::TraitFor::Controller::DBIC::DoesPaging';
  with 'Catalyst::TraitFor::Controller::DoesExtPaging';

  sub people :Local {
     # ...
     my $json = $self->ext_paginate($paginated_rs);
     # ...
  }

  sub people_lite :Local {
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
  sub people_more_different :Local {
     # ...
     my $json = $self->ext_paginate($paginated_rs, 'foo');
     # ...
  }

  sub programmers_do_it_by_hand :Local {
     # ...
     my $data = [qw{foo bar baz}];
     my $total = 10;
     my $json = $self->ext_parcel($data, $total);
     # ...
  }

  # defaults total to amount of items passed in
  sub some_programmers_do_it_by_hand_partially :Local {
     # ...
     my $data = [qw{foo bar baz}];
     my $json = $self->ext_parcel($data);
     # ...
  }

=head1 DESCRIPTION

This module is mostly for sending L<DBIx::Class> paginated data to ExtJS based javascript code.

=head1 METHODS

=head2 ext_paginate

  my $resultset = $self->model('DB::Foo');
  my $results   = $self->paginate($resultset);
  my $json      = $self->ext_paginate($resultset);
  my $json_str  = to_json($json);

=head3 Description

Returns a structure like the following from the ResultSet:

  {
     data  => \@results,
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

=head1 CONFIG VARIABLES

=over 2

=item root

Sets the name of the root for the data structure.  Defaults to data.

=item total_property

Sets the name for the total property for the data structure.  Defaults to total.

=back

=head1 SEE ALSO

L<Catalyst::Controller::Role::DBIC::DoesPaging>.

=head1 THANKS

Thanks to Micro Technology Services, Inc. for sponsoring initial development of
this module.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
