package BGPmon::CPM::PrefixAuthoritativeForDomain;  

use base qw(BGPmon::CPM::DBObject);

our $VERSION = '1.03';

__PACKAGE__->meta->setup
(
  table   => 'authoritative_for',
  columns => [ qw(prefix_dbid domain_dbid) ],
  pk_columns => ['prefix_dbid', 'domain_dbid'],

  foreign_keys =>
  [
    prefix =>
    {
      class       => 'BGPmon::CPM::Prefix',
      key_columns => { prefix_dbid => 'dbid' },
    },

    color =>
    {
      class       => 'BGPmon::CPM::Domain',
      key_columns => { domain_dbid => 'dbid' },
    },
  ],
);
__PACKAGE__->meta->error_mode('return');
