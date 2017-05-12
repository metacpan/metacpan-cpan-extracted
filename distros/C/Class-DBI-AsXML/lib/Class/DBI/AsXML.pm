package Class::DBI::AsXML;
# $Id: AsXML.pm,v 1.2 2005/01/15 15:32:32 cwest Exp $
use strict;

=head1 NAME

Class::DBI::AsXML - Format CDBI Objects as XML

=head1 SYNOPSIS

  # As you do...
  package MyApp::User;
  use base qw[Class::DBI];
  
  __PACKAGE__->connection('dbi:SQLite:dbfile', '', '');
  __PACKAGE__->table(q[users]);
  __PACKAGE__->columns(Primary => 'id');
  __PACKAGE__->columns(Essential => qw[username password]);
  __PACKAGE__->columns(Others    => qw[email zip_code phone]);
  __PACKAGE__->has_a(pref => 'MyApp::Pref');

  # Enter XML Support!
  use Class::DBI::AsXML;
  __PACKAGE__->to_xml_columns([qw[username email zip_code]]);

  # Elsewhere...
  my $user = MyApp::User->retrieve(shift);
  my $user_and_prefs_xml = $user->to_xml(depth => 1);

  # Or... override defaults
  my $uname_pwd_xml = $user->to_xml( columns => {
      ref($user) => [qw[username password]],
  });
  
  # Create from XML
  my $new_user = MyApp::User->create_from_xml(<<__XML__);
  <user>
    <username>new_user</username>
    <password>new_pass</password>
    <email>&lt;casey@geeknest.com%gt;</email>
  </user>
  __XML__

=cut

use base qw[Exporter];
use vars qw[@EXPORT $VERSION];
$VERSION = sprintf "%d.%02d", split m/\./, (qw$Revision: 1.2 $)[1];
@EXPORT  = qw[to_xml create_from_xml _to_xml_stringify];

use XML::Simple;
use overload;

=head1 DESCRIPTION

This software adds XML output support to C<Class::DBI> based objects.

=head2 to_xml_columns

  Class->to_xml_columns([qw[columns to dump with xml]]);

This class method sets the default columns this class should dump
when calling C<to_xml()> on an object. The single parameter is a
list reference with column names listed.

=head2 to_xml

  my $xml = $object->to_xml(
                columns => {
                    MyApp::User  => [ qw[username email zip_code] ],
                    MyApp::File  => [ qw[user filename size]      ],
                    MyApp::Pref  => [ MyApp::Pref->columns        ],
                },
                depth => 10,
                xml => {
                    NoAttr => 0,
                },
            );

All arguments are optional.

C<columns> - A hash reference containing key/value pairs associating
class names to a list of columns to dump as XML when the class is
serialized. They keys are class names and values are list references
containing column names, just as they'd be sent to C<to_xml_columns()>.
Passing a C<columns> parameter to this instance method will override
any defaults associated with this object. Failing that, C<to_xml_colunms()>
is checked and failing that, the C<Primary> and C<Essential> columns
are dumped by default.

Each column requested for XML output will go through an attempt to
be stringified. If the column value is an object with stringification
overloaded (using C<overload>) then it is stringified in that manner.
If the column is an object and its interface supports either C<as_string()>
or C<as_text()> methods, those method will be called and the results
returned. Finally, if the value is defined then it is stringified and
returned (this means references will become ugly). If the value is
undefined then an empty string is used in its place.

C<depth> - Depth to dump to. Depth of zero, the default, will not
recurse. Column values are interogated to determine if they should
be recursed down. If the column value is an object whose API supports
the C<to_xml()> method, then that method will be called and the resulting
XML will be parsed via C<XMLin()> from C<XML::Simple>. The root node
will not be kept when converting the XML back into a data structure.

C<xml> - Hash reference of XML::Simple options. Change these only
if you really know what you're doing. By default the following
options are set.

  NoAttr   => 1,
  RootName => $self->moniker,
  XMLDecl  => 0,

=head2 create_from_xml

  my $new_user = MyApp::User->create_from_xml($xml);

Creates a new user from an XML document. The document is parsed with
C<XMLin> and the root node is thrown away. All information passed in
to this method is ignored except the tags that match column names.

=head1 EXPORTS

This module is implemented as a mixin and therefore exports the
functions C<to_xml>, C<create_from_xml>, and C<_to_xml_stringify> into
the caller's namespace. If you don't want these to be exported, then
load this module using C<require>.

=cut

Class::DBI->mk_classdata('to_xml_columns');
Class::DBI->to_xml_columns([]);

sub to_xml {
    my ($self, %args) = @_;

    my @keys  =   ($args{columns} && $args{columns}->{ref($self)})
                ? @{$args{columns}->{ref($self)}}
                :   @{$self->to_xml_columns}
                  ? @{$self->to_xml_columns}
                  : (map $self->columns($_), qw[Primary Essential]);
    my @vals  = $self->get(@keys);
    
    my %hash;
    foreach my $col ( @keys ) {
        my $val = $self->$col;
        if ( $args{depth} && $val && ref($val) && $val->can('to_xml')) {
            $hash{$col} = XMLin $val->to_xml(%args, depth => $args{depth} - 1);
        } else {
            $hash{$col} = $self->_to_xml_stringify($val);
        }
    }

    my %xml_simple = $args{xml} ? %{$args{xml}} : ();
    my $xml = XMLout \%hash,
                     NoAttr   => 1,
                     RootName => $self->moniker,
                     XMLDecl  => 0,
                     %xml_simple;
    
    return $xml;
}

sub create_from_xml {
    my ($class, $xml) = @_;
    
    my $data = XMLin $xml;

    my %args;
    foreach ( $class->columns ) {
        next unless exists $data->{$_};
        $args{$_} = $data->{$_};
    }
    return $class->create(\%args);
}

sub _to_xml_stringify {
    my ($self, $val) = @_;

    if ($val && ref($val)) {
        return "$val" if    overload::Overloaded($val)
                         && overload::Method($val, '""');
        return $val->as_string if $val->can('as_string');
        return $val->as_text   if $val->can('as_text');
    }

    return "$val" if defined $val;
    return '';
}

1;

__END__

=head1 SEE ALSO

L<Class::DBI>,
L<XML::Simple>,
L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
