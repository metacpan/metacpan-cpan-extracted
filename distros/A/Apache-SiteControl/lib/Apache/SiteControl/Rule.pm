package Apache::SiteControl::Rule;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = "1.0";

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $this  = { };
   bless ($this, $class);
   return $this;
}

sub grants($$$$)
{
   my $this = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;

   return 0;
}

sub denies($$$$)
{
   my $this = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;

   return "Abstract rule denies everything. Do not use.";
}

1;

__END__

=head1 NAME

Apache::SiteControl::Rule - Permission manager access rule.

=head2 DESCRIPTION

Each rule is a custom-written class that implements some aspect of your site's
access logic. Rules can choose to grant or deny a request. 

   package sample::Test;

   use strict;
   use warnings;
   use Carp;
   use Apache::SiteControl::Rule;

   use base qw(Apache::SiteControl::Rule);

   sub grants($$$$)
   {
      my $this = shift;
      my $user = shift;
      my $action = shift;
      my $resource = shift;

      if($action eq "edit" && $resource->isa("sample::Record")) {
         return 1 if($user{name} eq "root");
      }

      return 0;
   }

   sub denies($$$$)
   {
      return 0;
   }

   1;

The PermissionManager will only give permission if I<at least> one rule grants
permission, I<and no> rule denies it. 

It is important that your rules never grant or deny a request they do not
understand, so it is a good idea to use type checking to prevent strangeness.
B<Assertions should not be used> if you expect different rules to accept
different resource types or user types, since each rule is used on every access
request.

=head1 EXPORT

None by default.

=head1 SEE ALSO

Apache::SiteControl::UserFactory, Apache::SiteControl::ManagerFactory,
Apache::SiteControl::PermissionManager, Apache::SiteControl

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

=cut
