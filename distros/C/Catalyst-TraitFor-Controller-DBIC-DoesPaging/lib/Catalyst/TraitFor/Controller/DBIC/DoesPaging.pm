package Catalyst::TraitFor::Controller::DBIC::DoesPaging;
{
  $Catalyst::TraitFor::Controller::DBIC::DoesPaging::VERSION = '1.001003';
}

# ABSTRACT: Helps you paginate, search, sort, and more easily using DBIx::Class

use Moose::Role;
use Web::Util::DBIC::Paging ':all' => { -prefix => '_' };

has ignored_params => (
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { [qw{limit start sort dir _dc rm xaction}] },
);

has page_size => (
   is => 'ro',
   isa => 'Int',
   default => 25,
);

sub page_and_sort {
   _page_and_sort(c => $_[1], $_[2], { page_size => $_[0]->page_size })
}

sub paginate {
   _paginate(c => $_[1], $_[2], { page_size => $_[0]->page_size })
}

sub search { _search(c => $_[1], $_[2], { skip => $_[0]->ignored_params }) }

sub sort { _sort_rs(c => $_[1], $_[2]) }

sub simple_deletion { _simple_deletion(c => $_[1], $_[2]) }

sub simple_search {
   _simple_search(c => $_[1], $_[2], { skip => $_[0]->ignored_params });
}

sub simple_sort { _simple_sort(c => $_[1], $_[2]) }

1;

__END__

=pod

=head1 NAME

Catalyst::TraitFor::Controller::DBIC::DoesPaging - Helps you paginate, search, sort, and more easily using DBIx::Class

=head1 VERSION

version 1.001003

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use Moose;
 BEGIN { extends 'Catalyst::Controller' }
 with 'Catalyst::TraitFor::Controller::DBIC::DoesPaging';

 sub people {
    my ($self, $c) = @_;
    my $people = $self->page_and_sort(
       $self->search( $self->model('DB::People') )
    );
    # ...
 }

=head1 DESCRIPTION

This module helps you to map various L<DBIx::Class> features to CGI parameters.
For the most part that means it will help you search, sort, and paginate with a
minimum of effort and thought.

=head1 METHODS

All methods take the context and a ResultSet as their arguments.  All methods
return a ResultSet.

=head2 page_and_sort

 my $result = $self->page_and_sort($c, $c->model('DB::Foo'));

This is a helper method that will first L</sort> your data and then L</paginate>
it.

=head2 paginate

 my $result = $self->paginate($c, $c->model('DB::Foo'));

Paginates the passed in resultset based on the following CGI parameters:

 start - first row to display
 limit - amount of rows per page

=head2 search

 my $searched_rs = $self->search($c, $c->model('DB::Foo'));

If the C<$resultset> has a C<controller_search> method it will call that method
on the passed in resultset with all of the CGI parameters.  I like to have this
method look something like the following:

 # Base search dispatcher, defined in MyApp::Schema::ResultSet
 sub _build_search {
    my $self           = shift;
    my $dispatch_table = shift;
    my $q              = shift;

    my %search = ();
    my %meta   = ();

    foreach ( keys %{$q} ) {
       if ( my $fn = $dispatch_table->{$_} and $q->{$_} ) {
          my ( $tmp_search, $tmp_meta ) = $fn->( $q->{$_} );
          %search = ( %search, %{$tmp_search||{}} );
          %meta   = ( %meta,   %{$tmp_meta||{}} );
       }
    }

    return $self->search(\%search, \%meta);
 }

 # search method in specific resultset
 sub controller_search {
    my $self   = shift;
    my $params = shift;
    return $self->_build_search({
       status => sub {
          return { 'repair_order_status' => shift }, {};
       },
       part_id => sub {
          return {
             'lineitems.part_id' => { -like => q{%}.shift( @_ ).q{%} }
          }, { join => 'lineitems' };
       },
    },$params);
 }

If the C<controller_search> method does not exist, this method will call
L</simple_search> instead.

=head2 sort

 my $result = $self->sort($c, $c->model('DB::Foo'));

Exactly the same as search, except calls C<controller_sort> or L</simple_sort>.
Here is how I use it:

 # Base sort dispatcher, defined in MyApp::Schema::ResultSet
 sub _build_sort {
    my $self = shift;
    my $dispatch_table = shift;
    my $default = shift;
    my $q = shift;

    my %search = ();
    my %meta   = ();

    my $direction = $q->{dir};
    my $sort      = $q->{sort};

    if ( my $fn = $dispatch_table->{$sort} ) {
       my ( $tmp_search, $tmp_meta ) = $fn->( $direction );
       %search = ( %search, %{$tmp_search||{}} );
       %meta   = ( %meta,   %{$tmp_meta||{}} );
    } elsif ( $sort && $direction ) {
       my ( $tmp_search, $tmp_meta ) = $default->( $sort, $direction );
       %search = ( %search, %{$tmp_search||{}} );
       %meta   = ( %meta,   %{$tmp_meta||{}} );
    }

    return $self->search(\%search, \%meta);
 }

 # sort method in specific resultset
 sub controller_sort {
    my $self = shift;
    my $params = shift;
    return $self->_build_sort({
       first_name => sub {
          my $direction = shift;
          return {}, {
             order_by => { "-$direction" => [qw{last_name first_name}] },
          };
       },
    }, sub {
       my $param = shift;
       my $direction = shift;
       return {}, {
          order_by => { "-$direction" => $param },
       };
    },$params);
 }

=head2 simple_deletion

 $self->simple_deletion($c, $c->model('DB::Foo'));

Deletes from the passed in resultset based on the following CGI parameter:

 to_delete - values of the ids of items to delete

This is the only method that does not return a ResultSet.  Instead it returns an
arrayref of the id's that it deleted.  If the ResultSet has has a multipk this will
expect each tuple of PK's to be separated by commas.

Note that this method uses the C<< $rs->delete >> method, as opposed to
C<< $rs->delete_all >>

=head2 simple_search

 my $searched_rs = $self->simple_search($c, $c->model('DB::Foo'));

Searches the resultset based on all fields in the request, except for fields
listed in C<ignored_params>.  Searches with
C<< $fieldname => { -like => "%$value%" } >>.  If there are multiple values for
a CGI parameter it will use all values via an C<or>.

=head2 simple_sort

 my $sorted_rs = $self->simple_sort($c, $c->model('DB::Foo'));

Sorts the passed in resultset based on the following CGI parameters:

 sort - field to sort by, defaults to primarky key
 dir  - direction to sort

=head1 CONFIG VARIABLES

=over 4

=item page_size

Default size of a page.  Defaults to 25.

=item ignored_params

ArrayRef of params that will be ignored in simple_search, defaults to:

 [qw{limit start sort dir _dc rm xaction}]

=back

=head1 SEE ALSO

L<Web::Util::DBIC::Paging>, which this module is a thin wrapper around

=head1 CREDITS

Thanks to Micro Technology Services, Inc. for funding the initial development
of this module.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
