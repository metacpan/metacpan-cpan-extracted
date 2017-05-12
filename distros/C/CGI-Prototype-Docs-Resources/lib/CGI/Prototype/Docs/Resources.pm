package CGI::Prototype::Docs::Resources;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Prototype::Docs::Resources ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CGI::Prototype::Docs::Resources - links to CGI::Prototype resources

=head1 Mailing list

There is now a mailing list for discussing the use of 
CGI::Prototype, a Perl module which allows for class and
prototype-based object-oriented development of CGI applications. 

=head2 SUBSCRIBING

=head3 Via Mailman/Sourceforge

Visit
L<http://lists.sourceforge.net/lists/listinfo/cgi-prototype-users> and
enter your subscription information.

=head3 Via Gmane

You can join the newsgroup
gmane.comp.lang.perl.modules.cgi-prototype.user 

If you are a Gnus user, here's the subscription string for you:
nntp+news.gmane.org:gmane.comp.lang.perl.modules.cgi-prototype.user

=head2 ARCHIVES

=over

=item *
L<http://dir.gmane.org/gmane.comp.lang.perl.modules.cgi-prototype.user>

=item *
L<http://sourceforge.net/mailarchive/forum.php?forum=cgi-prototype-users>

=item *
L<http://www.mail-archive.com/cgi-prototype-users%40lists.sourceforge.net/>

This last one should work. I am still waiting for my primer message to
show in the archive.

=back


=head1 Tutorials / Overviews

=head2 Linux Magazine "Introduction to CGI::Prototype"

L<http://www.stonehenge.com/merlyn/LinuxMag/col70.html>
L<http://www.stonehenge.com/merlyn/LinuxMag/col71.html>
L<http://www.stonehenge.com/merlyn/LinuxMag/col72.html>


=head2 Ourmedia's "Introduction to CGI::Prototype"

L<http://sourceforge.net/project/showfiles.php?group_id=135173&package_id=149434>

=head2 "Prototype Programming for Classless Classes"

L<http://www.stonehenge.com/merlyn/LinuxMag/col56.html>

=head1 Perlmonks CGI::Protoytpe Posts

=head2 "Seeking enlightenment on CGI::Prototype"

L<http://perlmonks.org/?node_id=442480>

=head2 "Mixins (problem with CGI::Prototype and Class::Protototyped with subtemplates)"

L<http://perlmonks.org/?node_id=439974>

=head2	"Trying to understand how CGI::Prototype::Hidden, Template Toolkit and CGI.pm work together."

L<http://perlmonks.org/?node_id=438026>

=head2 "CGI::Prototype - let me clarify the response phase for you"

L<http://perlmonks.org/?node_id=428222>

=head2	"A CGI::Prototype respond() subroutine for Data::FormValidator users"

L<http://perlmonks.org/?node_id=428151>

=head2	"CGI::Prototype and use base"

L<http://perlmonks.org/?node_id=426381>

=head2	"CGI::Prototype: questions and feedback"

L<http://perlmonks.org/?node_id=426162>

=head2 "Basic CGI::Prototype::Hidden"

L<http://perlmonks.org/?node_id=423071>

=head2 "Try CGI::Prototype"

L<http://perlmonks.org/?node_id=410803>

=head2 "Review: CGI::Prototype"

L<http://perlmonks.org/?node_id=411760>


=head1 Tips and Tricks

=head2 Setting up under mod_perl

=head3 startup.pl

 use lib qw( 
  /home/tbrannon/cvs/blue/wagsvr/install/httpd/prefork/modperl 
  /home/tbrannon/cvs/blue/wagsvr 
  /home/tbrannon/cvs/blue/wagsvr/install 
 ); 
 
 warn 'startup complete'; 
 1; 

=head2 httpd.conf

 <Location /> 
   SetHandler perl-script 
   PerlResponseHandler Blue::App 
 </Location> 

=head2 Blue/App.pm

 
 package Blue::App; 
 
 use strict; 
 use warnings; 
 
 use Apache2::RequestRec (); 
 use Apache2::RequestIO (); 
 
 use Apache2::Const -compile => qw(OK); 
 
 use base qw(CGI::Prototype); 
 
 sub handler { 
   my $r = shift; 
 
   __PACKAGE__->reflect->addSlot(r => $r); 
   __PACKAGE__->activate; 
 
   return Apache2::Const::OK; 
 }
 
 
 
 1; 



=head1 AUTHOR

Terrence Brannon, metaperl@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Terrence Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
