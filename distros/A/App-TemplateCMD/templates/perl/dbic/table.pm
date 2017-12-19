[% IF not module -%]
    [%- IF out.match('^lib') -%]
        [%- out = out.replace('lib/', '') -%]
        [%- out = out.replace('[.]pm', '') -%]
        [%- out = out.replace('/', '::', 1) -%]
        [%- module = out -%]
    [%- END -%]
[% END -%]
[% IF not module %][% module = 'My::Schema::Result::Album' %][% END -%]
[% IF not version %][% version.perl = '0.001' %][% END -%]
[% IF not table %][% table = 'album' %][% END -%]
[% IF not columns %][% columns = ['id', 'name', 'date', 'artist'] %][% END -%]
package [% module %];

# Created on: [% date %] [% time %]
# Create by:  [% contact.fullname or user %]
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components('InflateColumn::DateTime', 'Core');
# or ordered columns
#__PACKAGE__->load_components(qw/ Ordered /);
#__PACKAGE__->position_column('rank');

__PACKAGE__->table('[% table %]');

__PACKAGE__->add_columns(
[%- FOREACH column = columns %]
    '[% column %]' => {
        data_type         => 'integer',
        default_value     => undef,
        size              => undef,
        is_auto_increment => 0,
        is_nullable       => 1,
        sequence          => 'url_url_id_seq',
        #original          => { data_type => 'varchar' },
    },
[%- END %]
);

__PACKAGE__->set_primary_key('[% columns.0 %]');

#__PACKAGE__->has_many(
#    'accessor_name' => (
#        'related_class',
#        {
#            'foreign.fid' => 'self.fid',
#        },
#        {
#            cascade_copy => 0,
#            cascade_delete => 0,
#        },
#    )
#);

1;

__END__

=head1 NAME

[% module %] - <One-line description of module's purpose>

[% INCLUDE perl/pod/VERSION.pl %]
[% INCLUDE perl/pod/SYNOPSIS.pl %]
[% INCLUDE perl/pod/DESCRIPTION.pl %]
[% INCLUDE perl/pod/METHODS.pl %]
[% INCLUDE perl/pod/detailed.pl %]
=head1 AUTHOR

[% contact.fullname %] - ([% contact.email %])

=head1 LICENSE AND COPYRIGHT
[% INCLUDE licence.txt %]
=cut
