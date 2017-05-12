#===========================================================================

=head1 t::Convert::CiscoTest 

=head1 Methods

=cut

package t::Convert::CiscoTest;
use base qw(t::TestCase);

use strict;
use Convert::Cisco;

### Control which tests are run
#sub list_tests { return "test_noconfig" }

#----------------------------------------

=head2 test_nofile

=cut

sub test_nofile {
   my $self = shift;

   ### Test
   eval {
      my $obj = Convert::Cisco->new();
      $obj->to_xml("nosuchfile.bin", "test.xml");
   };

   ### Assertions
   $self->assert_not_null($@, "Expected error to be thrown");
   $self->assert_log("FATAL> Cannot open nosuchfile.bin - No such file or directory at t/Convert/CiscoTest.pm line 30\n");
}

#----------------------------------------

=head2 test_to_xml

=cut

sub test_to_xml {
   my $self = shift;
   $self->register_file("test.xml");

   ### Test
   my $obj = Convert::Cisco->new();
   $obj->to_xml("t/data/cdr_20061026133657_105573.bin", "test.xml");

   ### Assertions
   $self->assert_file_contents_identical("test.xml", "t/data/cdr_20061026133657_105573.xml");
   $self->assert_log(undef);
}

#----------------------------------------

=head2 test_noconfig

=cut

sub test_noconfig {
   my $self = shift;
   $self->register_file("test.xml");

   ### Test
   my $obj = Convert::Cisco->new(config=>"");
   $obj->to_xml("t/data/cdr_20061026133657_105573.bin", "test.xml");

   ### Assertions
   $self->assert_file_contents_identical("test.xml", "t/data/cdr_20061026133657_105573.noconfig.xml");

   # Header warnings
   $self->assert_log("WARN> CDB not configured: 1090");
   $self->assert_log("WARN> CDE not configured: 4000");
   $self->assert_log("WARN> CDE not configured: 4001");
   $self->assert_log("WARN> CDE not configured: 4002");
   $self->assert_log("WARN> CDE not configured: 6000");
   $self->assert_log("WARN> CDE not configured: 6001");
   $self->assert_log("WARN> CDE not configured: 6004");

   # Record 1 warnings
   $self->assert_log("WARN> CDB not configured: 1110");
   $self->assert_log("WARN> CDE not configured: 3000");
   # etc, etc
}

1;
