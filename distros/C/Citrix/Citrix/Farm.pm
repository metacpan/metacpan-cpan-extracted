package Citrix::Farm;
# DONE: Change to use new keys, Change POD as well
our $VERSION = '0.25';

=head1 NAME

Citrix::Farm - Citrix Farm Context Configuration.

=head1 DESCRIPTION

Farm Context (used all over the Citrix::* modules) is a configuration (hash) for single
Citrix Farm with following members:

=over 4

=item farmid - Short ID (typically 2-8 chars) for Farm (to appear as farm ID in an App). 

=item name - Descriptive / displayable Name for the farm

=item masterhost - Master host of the farm, queries will be directed onto this host

=item domainsuffix - DNS Domain suffix to add to hostname to make a fully qualified host name

=item apps - List of applications available on the farm (a ref to an array with app name strings)

=item hosts - List of hosts (Including master host) available on farm

=back



Citrix Farm Information is expected to be stored and maintained in static configuration
file so that there is no need to alter the config at runtime (This may change later).
For now the accessor methods or class work only as getters.

=head1 METHODS

The simple Farm model class contains mostly simple getter methods.

=over 4

=item $fc->farmid() - Farm ID

=item $fc->name() - Farm Name

=item $fc->masterhost() - Hostname of masterhost on the farm

=item $fc->domainsuffix() - DNS Domain suffix (part after hostname) for farm

=item $fc->apps() - Names (IDs) of apps available on Citrix Farm

=item $fc->hosts() - Hosts for the farm (serving apps listed above)

=back 

Note once more that these accessor methods only work as getters (see above). 

=head2 $farminfo = $fc->getfarminfo();

Retrieve Farm info about Farm apps/hosts (by Farm Context).
This query is possibly slow and unreliable (if some hosts
are down on the farm). Return Farm Info as array(ref).

=cut

#OLD:=item s - Optional Sequence number (to explicitly order farms within farm collection)



# Read-only accessors. Config is assumed to be maintained externally and loaded asis
# with no need to "tinker".
sub farmid      {$_[0]->{'farmid'};}
sub name        {$_[0]->{'name'};}
sub masterhost  {$_[0]->{'masterhost'};}
sub domainsuffix {$_[0]->{'domainsuffix'};}
sub apps        {$_[0]->{'apps'};}
sub hosts       {$_[0]->{'hosts'};}

# Method Aliases
*Citrix::Farm::mh = \&Citrix::Farm::masterhost;

sub getfarminfo {
   my ($fc) = @_;
   # TODO: Change heuristics
   my $usehost = $fc->masterhost(); # OLD: {'mh'}
   my $cmd = "rsh $usehost $Citrix::binpath/ctxqserver -app";
   #DEBUG:print("<pre>$cmd:\n",`$cmd`,"</pre>");
   #my $t = alarm(0);
   local $SIG{'ALRM'} = sub {die("RSH Timeout\n");}; # (at $t)
   alarm(8);
   my $fh;
   eval {
      my $ok = open($fh, "$cmd |");
      if (!$ok) {
        $fc->{'msg'} = "$!/$?";print("Failed to open the pipe");
        #return(undef);
        die("$!/$?");
      }
   };
   alarm(0);
   if ($@) {
      $fc->{'msg'} = $@;
      close($fh);
      return(undef);
   }
   my $arr = [];
   my $atts = ['APPID', 'PROTO', 'SERVER', 'LOAD',];
   
   my $err = parse($fh, $arr, $atts, 3);
   if ($err) {print("Failed ....");return(undef);}
   
   # Join to context ?
   $fc->{'apphost'} = $arr;
   my %apphost;
   my %hosts = map({
      #my $s = $_->{'SERVER'};
      $_->{'SERVER'} =~ tr/A-Z/a-z/;
      $apphost{$_->{'APPID'}}->{$_->{'SERVER'}} = 1;
      ($_->{'SERVER'}, 1);
   } @$arr);
   $fc->{'hosts'} = [sort(keys(%hosts))];
   $fc->{'apps'} = [sort(keys(%apphost))];
   
   $fc->{'apphost'} = \%apphost; # Index ?!
   return($arr);
}
__END__

=head1 BUGS

This simple "model" of Farm context / configuration makes an assumption
that all listed applications are available on all listed hosts of the farm.
However application using these modules may have additional
configuration (hash members) to refine this simplified model.

=cut

1;
