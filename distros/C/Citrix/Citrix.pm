# API / Module version 1.X restructuring placeholder
# - Aim to ease up Citrix module use by including all the sub-modules here
# and allowing merely "use Citrix;" in the application
# TODO:
# - Provide porting guide ... (???)
# - CitrixPortal.pm
# DONE
# - Deprecated Citrix::Config.pm ? maybe leave for farms
# - Farms: uses 'farmid'
# Allow loading config from DB

package Citrix;
use Citrix::SessionSet;
use Citrix::SessOp;
use Citrix::Farm;
#use Citrix::Config;
use Citrix::LaunchMesg;

our $VERSION = '0.25';

=head1 NAME

Module Suite for managing UNIX Citrix Sessions.

=head1 DESCRIPTION

Citrix "top-level" module loads all Citrix::* modules into runtime for simple use.
Citrix::* modules have no problems running in mod_perl based web application.

=head1 CLASS VARIABLES

The following class variables serve as Global Citrix environment settings. 

=head2  $Citrix::binpath

Path to Citrix command line utilities (for ctxconnect,ctxdisconnect,ctxlogoff,ctxreset,
ctxquery,ctxquser,ctxshadow ... Default: /opt/CTXSmf/bin)

=head2 $Citrix::admins

Hash(ref) containing admin usernames set to (dummy) true value. Set this from external
configuration files (Optional, No default value). This is provided as convenience for application
to store "admin" role for certain users.

=head2 $Citrix::farms

Array of hashes for Citrix farms configuration. See L<Citrix::Farm> for Farm hash structure.
Load these with Citrix::loadconfig() (see METHODS).

=head2 $Citrix::touts

Timeout(s) for Citrix (over-the-network) Operations. Has separate settings for 'host','user','op'.
Set these by your network speed and latency.

=cut


# Citrix Admins 
our $admins = {};
# Global handle to farm configurations
our $farms; # []
# Domain to use in launch message
our $domain = '';
# Citrix Command line binaries path
our $binpath = '/opt/CTXSmf/bin';
# TODO: New Granular timeouts for various use-cases
our $touts = {'host' => 10, 'user' => 5, 'op' => 5,};

=head1 METHODS

=head2 my Citrix::loadconfig($fname);

Load Farm Configuration from a file in perl format. The file should "return" an array
of (non blessed) Citrix::Farm hashes with keys described in L<Citrix::Farm> module
(all this as a result of underlying "require()").
Do not terminate this config file with the traditional "1;" true value (the array
returned will be the true value).

This file is expected to be found in Perl library path (@INC). Usually the application
current directory is a safe choice for storing config (as '.' is always in @INC).

Behind the scenes the Farm config is stored in Citrix class to be accessed later by
getfarms

=head2 my $farms = Citrix::getfarms();

Get Handle to farms (array of hashes). Passing keyword param 'idx' set to true values makes getfarms
return a hash(ref) keyed by farm id (instead or array(ref) ).
Farm id keys are usually chosen to be short name string (Example 'la' for Los Angeles farm), see Citrix::Farm.
Passing keyword param 'sort' set to valid Farm attribute value makes getfarms() return farm set array sorted by
atribute ('sort' and 'idx' don't work together).

=head2 Citrix::loadconfig_db($dbh)

Load Citrix Farms from DB using DBI connection $dbh.
Method stores L<Citrix::Farm> entries in $Citrix::farms for later access.
Use Citrix::getfarms() to access farm info (see L<Citrix>).

Useful in bigger environments with world-wide multi-farm Citrix system layout.
Notice that Citrix::* modules are not tightly coupled with perl DBI, but to use
this method you do need DBI to to establish the connection.


=cut

# Load Farm Configuration
sub loadconfig {
   my ($fname) = @_;
   if ($farms && @$farms) {return($farms);}
   eval {
     $farms = require($fname);
   };
   if ($@) {die("No Farms Cached or config file found: $!\n");}
   return($farms);
}

sub loadconfig_db {
   my ($dbh, %opt) = @_;
   my $tn = $opt{'tabname'} || $farmtabname;
   my $w = " WHERE active = 1";
   my $qs = "SELECT * FROM $tn $w ";
   my $arr = $dbh->selectall_arrayref($qs, {Slice => {} });
 
   my @farms = map({
      $_->{'hosts'} = [split(/,\s*/, $_->{'hosts'})];
      $_->{'apps'} = [split(/,\s*/, $_->{'apps'})];
      #DEBUG:print("Entry:\n".Dumper($_));
      bless($_, 'Citrix::Farm');
   } @$arr);
   return(\@farms);
}

# Get Array of farm configs.
# Options
# - idx - Set to 1 return hash indexed by Farm id:s
# - sort - Sort by attribute
sub getfarms {
   my (%c) = @_;
   if (!$farms) {die("No Farms loaded / cached");}
   if (ref($farms) ne 'ARRAY') {die("Farms Not in array collection");}
   # ARRAY/HASH
   if ($c{'idx'}) {my %fi = map({$_->{'farmid'}, $_;} @$farms);return(\%fi);}
   elsif (my $sa = $c{'sort'}) {my @s = sort({$a->{$sa} cmp $b->{$sa};} @$farms);return(\@s);}
   return($farms);
}
1;

#Thanks to Ramana Mokkapati and Ken Venner, who are not only avid Perl users but
#friends of Open-Source in general and allowed me to contribute this module.

__END__


=head1 AUTHOR

Olli Hollmen E<lt>ohollmen@broadcom.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Olli Hollmen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 THANKS

Thanks to my daughter Milla Hollmen for proofreading the perldoc.

=head1 REFERENCES

Citrix Command line commands:
L<http://support.citrix.com/proddocs/index.jsp?topic=/ps-unix/ps-unix-cmd-ref-commands-ctxquery.html>


=cut
