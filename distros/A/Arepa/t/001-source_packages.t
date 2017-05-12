use strict;
use warnings;

use Test::More tests => 22;
use Arepa::PackageDb;

use constant TEST_DATABASE => 't/source_packages_test.db';

unlink TEST_DATABASE;
my $pdb = Arepa::PackageDb->new(TEST_DATABASE);
my %attrs = (name         => 'dhelp',
             full_version => '0.6.18',
             architecture => 'all',
             distribution => 'unstable');
my $id = $pdb->insert_source_package(%attrs);
my $id2 = $pdb->get_source_package_id($attrs{name}, $attrs{full_version});
is($id2, $id,
   "get_source_package_id should return the correct id");
my %attrs_from_db = $pdb->get_source_package_by_id($id);
foreach my $attr (qw(name full_version architecture distribution)) {
    is($attrs_from_db{$attr}, $attrs{$attr},
       "Attribute '$attr' should be '$attrs{$attr}' " .
            "(was '$attrs_from_db{$attr}')");
}



my %new_attrs = (name         => 'dhelp',
                 full_version => '0.6.18.1',
                 architecture => 'any',
                 distribution => 'lenny');
my $new_id = $pdb->insert_source_package(%new_attrs);
my $new_id2 = $pdb->get_source_package_id($new_attrs{name},
                                          $new_attrs{full_version});
is($new_id2, $new_id,
   "get_source_package_id should return the correct id (2)");
my %new_attrs_from_db = $pdb->get_source_package_by_id($new_id);
foreach my $attr (qw(name full_version architecture distribution)) {
    is($new_attrs_from_db{$attr}, $new_attrs{$attr},
       "Attribute '$attr' should be '$new_attrs{$attr}' " .
            "(was '$new_attrs_from_db{$attr}')");
}

# Try special value '*latest*'
my $new_id3 = $pdb->get_source_package_id($new_attrs{name}, '*latest*');
is($new_id, $new_id3,
   "Using '*latest*' as full version should give the latest");

# Try to insert the same source package again, with different properties
my $id3 = $pdb->insert_source_package(name         => $new_attrs{name},
                                      full_version => $new_attrs{full_version},
                                      architecture => 'amd64',
                                      distribution => 'unstable');
is($id3, $new_id,
   "Trying to insert a new source package should just return the same id");
my %new_attrs_from_db_again = $pdb->get_source_package_by_id($new_id);
foreach my $attr (qw(name full_version architecture distribution)) {
    is($new_attrs_from_db_again{$attr}, $new_attrs{$attr},
       "Attribute '$attr' should be '$new_attrs{$attr}' " .
            "(was '$new_attrs_from_db_again{$attr}')");
}


my $invalid_id_fails = 1;
eval {
    $pdb->get_source_package_by_id(666),
    $invalid_id_fails = 0;
};
is($invalid_id_fails, 1,
   "Asking for a source package with an invalid id should fail");



my %attrs4 = (name         => 'rabbitmq-server',
              full_version => '1.7.2-1',
              architecture => 'all',
              distribution => 'lenny',
              comments     => 'rabbitmq-server from squeeze. ' .
                                     'needed for python-celery');
my $id4 = $pdb->insert_source_package(%attrs4);
my %attrs4_from_db = $pdb->get_source_package_by_id($id4);
foreach my $attr (qw(name full_version architecture distribution comments)) {
    is($attrs4_from_db{$attr}, $attrs4{$attr},
       "Attribute '$attr' should be '$attrs4{$attr}' " .
            "(was '$attrs4_from_db{$attr}')");
}
