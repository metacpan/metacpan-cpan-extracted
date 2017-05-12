package DBIx::Class::InflateColumn::URI;

=head1 NAME

DBIx::Class::InflateColumn::URI - Auto-create URI objects from columns

=head1 SYNOPSIS

Load this component and then declare one or more columns as URI columns.

  package Resources;
  __PACKAGE__->load_components(qw/InflateColumn::URI Core/);
  __PACKAGE__->add_columns(
      url => {
          datatype => 'varchar',
          size => 255,
          is_nullable => 1,
          default_uri_scheme => 'http',
          is_uri => 1,
      },
  );

Then you can treat the specified column as an URI object.

  print 'stringified URI: ', $resource->url, "\n";
  print 'scheme: ', $resource->url->scheme, "\n";
  print 'domain: ', $resource->url->host, "\n";
  print 'path:   ', $resource->url->path, "\n";

=head1 DESCRIPTION

This module inflates/deflates designated columns into URI objects.

=cut

use strict;
use warnings;
use URI;

our $VERSION = '0.01002';

=head2 Methods

=over 4

=item default_uri_scheme

Gets/sets the default scheme to use when no scheme is specified in the URI.

  __PACKAGE__->default_uri_scheme('http');

You can also set this on a per column basis, as shown in the L</SYNOPSIS>.

=cut

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('inherited', qw/
        default_uri_scheme
    /);
};

=item register_column

Chains with the "register_column" in DBIx::Class::Row method, and sets up
currency columns appropriately. This would not normally be directly called by
end users.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);

    return unless defined $info->{'is_uri'};

    my $default_uri_scheme = $info->{'default_uri_scheme'} || $self->default_uri_scheme || '';

    $self->inflate_column(
        $column => {
            inflate => sub {
                my ($value, $obj) = @_;
                if ($default_uri_scheme and $value !~ m|://|) {
                    return URI->new($default_uri_scheme . '://' . $value);
                }
                return URI->new($value, $default_uri_scheme);
            },
            deflate => sub {
                return shift->as_string;
            },
        }
    );
};

=back

=cut

1;
__END__

=head1 SEE ALSO

L<URI>,
L<DBIx::Class::InflateColumn>,
L<DBIx::Class>.

=head1 AUTHOR

Nathan Gray E<lt>kolibrie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Nathan Gray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

