package Data::Collection;

=head1 NAME

Data::Collection - capability based collection model

=head1 CAPABILITIES

  AllMembers: (Mappable Greppable MemberCount Sortable Reversible Printable Junctions::Common Joinable ToArray)

    $coll->members;
    defaults: map grep member_count sort reverse print any all one none join

  Mappable:

    $coll->map(CodeRef $mapping);

  Greppable: (Mappable)

    $coll->grep(CodeRef $filter); # defaulted

  MemberCount:

    $coll->member_count

  Sortable:

    $coll->sort(CodeRef $sort);

  Reversible:

    $coll->reverse

  Printable:

    $coll->print(IO $fh?);

  Joinable:

    $coll->join(Str $with?);

  Junctions::Common: (Junction::Any Junction::All Junction::None Junction::One)

  Junction::Any:

    $coll->any;

  Junction::All:

    $coll->all;

  Junction::None:

    $coll->none;

  Junction::One:

    $coll->one;

  ToArray:

    @{$coll}

=head1

Basic collection types:

  HashMap
  Set
  ArrayColl

Facets:

  Orderable
  Collatable

need to work out how this stuff interacts with types 

=cut

0; # not yet loadable
