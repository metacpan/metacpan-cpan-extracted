package Catalyst::TraitFor::Controller::jQuery::jqGrid::Search;

use 5.008;

use Moose::Role;
use JSON;

our $VERSION = '0.02';

my %qOp = (
    'eq' => { pre => '',  post => '',  op => '=', },            # equal
    'ne' => { pre => '',  post => '',  op => '!=', },           # not equal
    'lt' => { pre => '',  post => '',  op => '<', },            # less
    'le' => { pre => '',  post => '',  op => '<=', },           # less or equal
    'gt' => { pre => '',  post => '',  op => '>', },            # greater
    'ge' => { pre => '',  post => '',  op => '>=', },           # greater or equal
    'bw' => { pre => '',  post => '%', op => '-like', },        # begins with
    'bn' => { pre => '',  post => '%', op => '-not_like', },    # does not begin with
    'in' => { pre => '%', post => '%', op => '-like', },        # is in (reverse contains)
    'ni' => { pre => '%', post => '%', op => '-not_like', },    # is not in (reverse does not contain)
    'ew' => { pre => '%', post => '',  op => '-like', },        # ends with
    'en' => { pre => '%', post => '',  op => '-not_like', },    # does not end with
    'cn' => { pre => '%', post => '%', op => '-like', },        # contains
    'nc' => { pre => '%', post => '%', op => '-not_like', },    # does not contain
    );

sub _complex_search {
  my ($cs_ref) = @_;
  if ( ref $cs_ref eq 'HASH' ) {

    # hash keys possible: groupOp, groups, rules
    # in complex search, only groupOp is certain to be present
    # (although a complex search with only a groupOp isn't really very complex...)

    if ( defined $cs_ref->{groupOp} ) {

      my $group_op = '-' . lc $cs_ref->{groupOp};

      my $group_aref;
      $group_aref = _complex_search($cs_ref->{groups}) if defined $cs_ref->{groups} && @{$cs_ref->{groups}};

      my $rule_aref;
      $rule_aref = _complex_search($cs_ref->{rules}) if defined $cs_ref->{rules} && @{$cs_ref->{rules}};

      if ( $group_aref && $rule_aref ) {
        push @{$group_aref}, $rule_aref;
      }
      elsif ( $rule_aref ) {
        $group_aref = $rule_aref;
      }
      return { $group_op => $group_aref } if $group_aref;
    }

    # empty search
    return {};

  }
  elsif ( ref $cs_ref eq 'ARRAY' ) {

    # array can be rules or groups, either is array of hashes
    my $rg_aref;
    for my $rg ( @{$cs_ref} ) {
      if ( defined $rg->{groupOp} ) {

        # this one's a group
        my $group_aref = _complex_search($rg);
        push @{$rg_aref}, $group_aref if $group_aref;
      }
      elsif ( defined $rg->{field} ) {

        # this one's a rule, handle like simple search
        my $rule_aref = jqGrid_search(
            undef,
            {   _search      => 'true',
            searchField  => $rg->{field},
            searchOper   => $rg->{op},
            searchString => $rg->{data},
            },
            );
        push @{$rg_aref}, $rule_aref if $rule_aref;
      }
      else {
        return 'not a jqGrid group/rule ARRAY';    # this shouldn't happen...
      }
    }
    return $rg_aref;
  }
} ## end sub _complex_search

sub jqGrid_search {
  my ( $self, $params ) = @_;
  return {} unless $params->{_search} eq 'true';
  if ( $params->{filters} ) {
    return _complex_search( JSON->new->decode( $params->{filters} ) );
  }
  elsif ( $params->{searchField} ) {

    # Simple search
    if ( $params->{searchOper} =~ /i/ ) {

      # 'in'/'ni' search - reverse field & value
      my $temp = $params->{searchField};
      $params->{searchField}  = $params->{searchString};
      $params->{searchString} = $temp;
    }
    return { $params->{searchField} =>
      { $qOp{ $params->{searchOper} }{op} => $qOp{ $params->{searchOper} }{pre} . $params->{searchString} . $qOp{ $params->{searchOper} }{post} }
    };
  }
  else {
    # unknown search type
    return {};
  }
}

=head1 NAME

Catalyst::TraitFor::Controller::jQuery::jqGrid::Search - Catalyst helper function for translating jqGrid search parameters

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Helper for translating search queries from the jQuery plugin jqGrid.

In your Catalyst Controller.

  package MyApp::Web::Controller::Root;

  use Moose;
  use namespace::autoclean;

  with 'Catalyst::TraitFor::Controller::jQuery::jqGrid::Search';

Then later on in your controllers you can do

  sub foo :Local {
    my ($self, $c) = @_;

    my $search_filter = $self->jqGrid_search($c->req->params);

    my $bar_rs = $c->model('DB::Baz')->search(
      $search_filter,
      {},
    );

=head1 DESCRIPTION

The L<http://jquery.com/> Javascript library simplifies the writing of
Javascript and does for Javascript what the MVC model does for Perl.

A very useful plugin to jQuery is a Grid control which can be used to page
through data obtained from a back-end database. Ajax calls to the back-end
retrieve JSON data. See L<http://www.trirand.com/blog/>

This module provides a helper function to translate the jqGrid simple and/or
complex search query strings to the L<DBIx::Class|DBIx::Class/> /
L<SQL::Abstract|SQL::Abstract/> search/where constructs.

=head1 SUBROUTINES/METHODS

=head2 jqGrid_search

=head3 Simple Search (single field)

jqGrid submits the parameters C<searchField>, C<searchOper>, and C<searchString>.
For example, the query "B<cust_name = 'Bob'>" would set:

  searchField  = 'cust_name'
  searchOper   = 'eq'
  searchString = 'Bob'

jqGrid_search translates that into:

  { 'cust_name' => { '=' => 'Bob' } }

=head3 Complex Search

jqGrid submits the parameter C<filters> with JSON-encoded data.
For example, the query: "B<( (name LIKE "%Bob%" AND tax E<gt>= 20) OR
(note LIKE "no tax%" AND amount E<lt> 1000) )>"
would result in the following:

  filters = '{"groupOp":"OR","rules":[],"groups":[{"groupOp":"AND","rules":[{"field":"name","op":"cn","data":"Bob"},
             {"field":"tax","op":"ge","data":20}],"groups":[]},{"groupOp":"AND","rules":[{"field":"note","op":"bw",
             "data":"no tax"},{"field":"amount","op":"lt","data":"1000"}],"groups":[]}]}'

jqGrid_search translates that into:

  {
    '-or' => [
      {
        '-and' => [
          { 'name'   => { '-like' => '%Bob%' } },
          { 'tax'    => { '>=' => '20' } }
        ]
      },
      {
        '-and' => [
          { 'note'   => { '-like' => 'no tax%' } },
          { 'amount' => { '<' => '1000' } }
        ]
      }
    ]
  }

=head3 The jqGrid Search Operators are:

=over

=item * eq ( equal )

... WHERE searchField = 'searchString'

=item * ne ( not equal )

... WHERE searchField != 'searchString'

=item * lt ( less )

... WHERE searchField < searchString

=item * le ( less or equal )

... WHERE searchField <= searchString

=item * gt ( greater )

... WHERE searchField > searchString

=item * ge ( greater or equal )

... WHERE searchField >= searchString

=item * bw ( begins with )

... WHERE searchField like 'searchString%'

=item * bn ( does not begin with )

... WHERE searchField not like 'searchString%'

=item * in ( is in )

According to L<http://stackoverflow.com/questions/9383267/what-is-the-usage-of-jqgrid-search-is-in-and-is-not-in> 'in' and 'ni' are
not set-based operators (C<WHERE field IN (val1,val2,val3)>) but are: "I<... the equivalents of contains and does not contain, with the operands reversed>", thus:

... WHERE searchB<String> like '%searchB<Field>%'

=item * ni ( is not in )

... WHERE searchB<String> not like '%searchB<Field>%'

=item * ew ( ends with )

... WHERE searchField like '%searchString'

=item * en ( does not end with )

... WHERE searchField not like '%searchString'

=item * cn ( contains )

... WHERE searchField like '%searchString%'

=item * nc ( does not contain )

... WHERE searchField not like '%searchString%'

=back

=head3 jqGrid Search Setup

In your jqGrid colModel options, be sure to set sensible search operators for each field in the B<sopt> option within B<searchoptions>.
For example, the various B<like>-like operators (B<bw>, B<ew>, etc.) probably don't make sense for a numeric field. Similarly, anything other
than B<eq> for a boolean field is unnecessary.

=head1 DEPENDENCIES

JSON - for parsing the jqGrid "complex search" parameter C<filters>.

=head1 AUTHOR

Scott R. Keszler, C<< <keszler at srkconsulting.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-catalyst-traitfor-controller-jquery-jqgrid-search at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-TraitFor-Controller-jQuery-jqGrid-Search>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Catalyst::TraitFor::Controller::jQuery::jqGrid::Search

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-TraitFor-Controller-jQuery-jqGrid-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-TraitFor-Controller-jQuery-jqGrid-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-TraitFor-Controller-jQuery-jqGrid-Search>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-TraitFor-Controller-jQuery-jqGrid-Search/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Ian Docherty <pause@iandocherty.com> for L<Catalyst::TraitFor::Controller::jQuery::jqGrid|Catalyst::TraitFor::Controller::jQuery::jqGrid>,
which I used as a template for this code.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Scott R. Keszler.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Catalyst::TraitFor::Controller::jQuery::jqGrid::Search
