package CHI::Driver::Role::IsSubcache;
$CHI::Driver::Role::IsSubcache::VERSION = '0.60';
use Moo::Role;
use strict;
use warnings;

has 'parent_cache'  => ( is => 'ro', weak_ref => 1 );
has 'subcache_type' => ( is => 'ro' );

1;
