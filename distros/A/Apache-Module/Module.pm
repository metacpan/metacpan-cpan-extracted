package Apache::Module;

use strict;
use vars qw($VERSION @ISA);

use Apache::Constants ();
use DynaLoader ();

@ISA = qw(DynaLoader);

$VERSION = '0.11';

if($ENV{MOD_PERL}) {
    bootstrap Apache::Module $VERSION;
}

sub find {
    my($self,$name) = @_;
    my $top_module = $self->top_module;

    for (my $modp = $top_module; $modp; $modp = $modp->next) {
	return $modp if $modp->name =~ /$name/;
    }
    
    return undef;
}

sub commands {
    my $modp = shift;
    my @retval = ();
    for (my $cmd = $modp->cmds; $cmd; $cmd = $cmd->next) {
	push @retval, $cmd->name;
    }
    \@retval;
}

sub content_handlers {
    my $modp = shift;
    my @handlers = ();
    for (my $hand = $modp->handlers; $hand; $hand = $hand->next) {
	push @handlers, $hand->content_type;
    }
    return @handlers;
}

1;
__END__

=head1 NAME

Apache::Module - Interface to Apache C module structures

=head1 SYNOPSIS

  use Apache::Module ();

=head1 DESCRIPTION

This module provides an interface to the list of apache modules configured
with your httpd and their C<module *> structures.

=head1 METHODS

=over 4

=item top_module

This method returns a pointer the first module in Apache's internal list
of modules.

   Example:

   my $top_module = Apache::Module->top_module;

   print "Configured modules: \n";

   for (my $modp = $top_module; $modp; $modp = $modp->next) {
	print $modp->name, "\n";
   }

=item find($module_name)

This method returns a pointer to the module structure if found, under
otherwise.

  Example:

 for (qw(proxy perl include cgi)) {
     if(my $modp = Apache::Module->find($_)) {
	 print "$_ module is configured\n";
         print "with enabled commands: \n";

	 for (my $cmd = $modp->cmds; $cmd; $cmd = $cmd->next) {
	     print "   ", $cmd->name, "\n";
	 }
     }
     else {
	 print "$_ module is not configured\n";
     }
 }

=item handlers

Returns a pointer to the module response handler table.

Example:

    print "module ", $modp->name, " handles:\n";

    for (my $hand = $modp->handlers; $hand; $hand = $hand->next) {
	print $hand->content_type, "\n";
    }

=item Other Stuff

There's more you can do with this module, I will document it later.
For now, see Apache::ModuleDoc and Apache::ShowRequest for examples.

=back

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO

Apache::ModuleDoc(3), Apache::ShowRequest(3), Apache(3), mod_perl(3).

=cut
