package DBIx::Cookbook::RDBO::RoseDB;

use base qw(Rose::DB);

__PACKAGE__use_private_registry;

use DBIx::Cookbook::DBH;

my $config = DBIx::Cookbook::DBH->new;

# Register your lone data source using the default type and domain

my %register =   (
   domain   => __PACKAGE__->default_domain,
   type     => __PACKAGE__->default_type,
   $config->for_rose_db
  );

__PACKAGE__->register_db(%register);

1;


