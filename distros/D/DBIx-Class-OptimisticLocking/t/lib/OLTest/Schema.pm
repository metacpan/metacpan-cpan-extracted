package    # hide from PAUSE
  OLTest::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/TestDirty TestDirtyIgnored TestAll TestAllIgnored TestVersion TestVersionAlt TestVersionIgnored/);

1;
