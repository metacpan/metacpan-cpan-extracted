package Apache::AuthenN2;

use strict;
use Apache::Constants qw/:common/;
use vars qw/%ENV/;
use Authen::Smb;
use Net::NISPlus::Table;

$Apache::AuthenN2::VERSION = '0.06';
my $self="Apache::AuthenN2";

sub handler {

   # get request object
   my $r = shift;

   # service only the first internal request
   return OK unless $r->is_initial_req;

   # get password user entered in browser
   my($res, $sent_pwd) = $r->get_basic_auth_pw;

   # decline if not basic
   return $res if $res;

   # get user name
   my $name = $r->connection->user;

   # blank user name would cause problems
   unless($name){
      $r->note_basic_auth_failure;
      $r->log_reason($self . ': no username supplied', $r->uri);
      return AUTH_REQUIRED;
   }

   # load apache config vars
   my $dir_config = $r->dir_config;   

   # get nt controllers
   my $controllers = $r->dir_config('NT_Controllers') || '';
   $r->log_reason(
      $self . ': no NT_Controllers specified in config', $r->uri
   ) unless $controllers;
   my @controllers = split /\s+/, $controllers;
   
   # get nt domain name
   my @domains;
   if ($name =~ /^.*\\/){
      # user-specified domain name
      @domains = split /\\/, $name;
      $name = pop @domains;
   }
   else{
      # get list of default domains from config
      @domains = split /\s+/, $r->dir_config('NT_Default_Domains');
      $r->log_reason(
         $self . 
         ': user did not specify domain, and there are no NT_Default_Domains specified in config', $r->uri
      ) unless @domains;
   }

   # try nt
   my ($pdc, $bdc);
   foreach my $domain (@domains){
      foreach my $controller (@controllers){
         ($pdc, $bdc) = split /:/, $controller;
         $bdc = $pdc unless $bdc;
         unless (Authen::Smb::authen($name, $sent_pwd, $pdc, $bdc, $domain)){
            $r->push_handlers(PerlAuthzHandler => \&authz);
            return OK;
         }
      }
   }

   # try nis+
   # get passwd table name
   my $passwd_table = $dir_config->get('NISPlus_Passwd_Table');
   # get user password entry
   my $pwd_table = Net::NISPlus::Table->new($passwd_table);
   unless ($pwd_table){
      $r->note_basic_auth_failure;
      $r->log_reason($self . ': cannot get nis+ passwd table', $r->uri);
      return AUTH_REQUIRED;
   }
   my $pwd = '';
   my $group = '';
   # look for name match
   foreach ($pwd_table->lookup('[name=' . $name . ']')){
      $pwd = $_->{'passwd'};
      $group = $_->{'gid'};
      last;
   }
   # stash group id lookup for authorization check 
   $r->notes($name . 'Group', $group);
   unless($pwd){
      $r->note_basic_auth_failure;
      $r->log_reason(
         $self . ': user ' . $name .
         ' failed to authenticate in the nt domain(s) ' .
         join(' ', @domains) . ', and is not in ' . $passwd_table .
         ', either', $r->uri
      );
      return AUTH_REQUIRED;
   }
   unless(crypt($sent_pwd, $pwd) eq $pwd) {
      $r->note_basic_auth_failure;
      $r->log_reason(
         $self . ': user ' . $name .
         ' failed to authenticate in the nt domain(s) ' .
         join(' ', @domains) . ', or ' . $passwd_table, $r->uri
      );
      return AUTH_REQUIRED;
   }

   $r->push_handlers(PerlAuthzHandler => \&authz);
   return OK;
}

sub authz {
 
   # get request object
   my $r = shift;
   my $requires = $r->requires;
   return OK unless $requires;

   # get user name
   my $name = $r->connection->user;

   # get group table name
   my $dir_config = $r->dir_config;   
   my $group_table=$dir_config->get('NISPlus_Group_Table');

   for my $req (@$requires) {
      my($require, @rest) = split /\s+/, $req->{requirement};

      # ok if user is simply authenticated
      if($require eq 'valid-user'){return OK}

      # ok if user is one of these users
      elsif($require eq 'user') {return OK if grep $name eq $_, @rest}

      # ok if user is member of a required group. warning: this will fail 
      # if user is not in the nis+ domain, because there is no current
      # concept of nt domain groups in Authen::Smb
      elsif($require eq 'group') {
         my $group_table = Net::NISPlus::Table->new($group_table);
         unless ($group_table){
            $r->note_basic_auth_failure;
            $r->log_reason($self . ': cannot get nis+ group table', $r->uri);
            return AUTH_REQUIRED;
         }
         my %groups_to_gids;
         foreach ($group_table->list()){$groups_to_gids{@{$_}[0]} = @{$_}[2]}
         for my $group (@rest) {
            next unless exists $groups_to_gids{$group};
            return OK if $r->notes($name . 'Group') == $groups_to_gids{$group};
         }
      }
   }

   $r->note_basic_auth_failure;
   $r->log_reason(
      $self . ': user ' . $name . 
      ' not member of required group in ' . $group_table, $r->uri
   );
   return AUTH_REQUIRED;

}

1;

__END__

=pod

=head1 NAME

Apache::AuthenN2 - Authenticate into the NT and NIS+ domains

=head1 SYNOPSIS

Allow windows and unix users to use their familiar credentials to
gain authenticated access to restricted applications and files
offered via apache.

   #httpd.conf
   <Files *challenge*>
      AuthName 'your nt or nis+ account'
      AuthType Basic
      PerlSetVar NISPlus_Passwd_Table passwd.org_dir.yoyodyne.com
      PerlSetVar NISPlus_Group_Table group.org_dir.yoyodyne.com
      PerlSetVar NT_Default_Domains 'eng corporate'
      PerlSetVar NT_Controllers 'bapdc:babdc njpdc:njbdc'
      PerlAuthenHandler Apache::AuthenN2
      require group eng
      require user john larry
   </Files>

=head1 DESCRIPTION

Authenticate to one or more pdc:bdc controller pairs; these can be
true nt controllers or properly configured samba servers.  Only one
pdc:bdc pair is required by the module; you can add pairs to increase
reliability, or to circumvent domain trust wars.  If the user has
specified a domain, e.g., sales\john, then just try against that
domain; if no domain was specified by the user, try all of the
default domains listed in the above config.  Failing nt
authentication, try nis+.  This order (nt then nis+) is simply to
boost average apparent performance because the nt population is much
larger than the unix population at the author's company.  If your
population has an opposite demographic, feel free to reverse the
order of checking.

Note that this scheme is quite permissive.  Valid nt credentials
against any of the controllers or domains, or valid nis+ credentials
will allow access.  This multiplies exposure to poorly selected
passwords.

<Files *challenge*> is just a way of specifying which files should be
protected by this authenticator.  In this example, a script named
newbug-challenge.pl would be protected, regardless of where it is
located in the apache htdocs or cgi directories.  If you prefer, you
can use the simpler <Location> directive to protect a particular file
or directory.

Instead of requiring specific groups or users, you could just
'require valid-user'.

The nt part requires the Authen::Smb module.  When Authen::Smb
supports group authentication, I will add it to this module.

The nis+ part requires the Net::NISPlus module.

You just read all you need to know to get started -- but you should
read on if you care about nt/nis+ server load, network performance,
or response time (as the user perceives it).

_Every_ time a protected file is requested, this handler is invoked.
Depending on your configuration (how many controllers and default
domains you specify), and where the matching credentials are, it can
take a while.  This adds to your network and server load, as well as
bothering some users with the wait.  It makes sense to cache valid
credentials in memory so as to avoid invoking this expensive module
every time.  Luckily, Jason Bodnar already created AuthenCache.
Although written with AuthenDBI in mind, it works beautifully in this
case as well.  It is _highly_ recommended.  After installing it, you
need a few more lines in httpd.conf; to expand on the above example:

   PerlModule Apache::AuthenCache
   <Files *challenge*>
      AuthName 'your nt or nis+ account'
      AuthType Basic
      PerlSetVar NISPlus_Passwd_Table passwd.org_dir.yoyodyne.com
      PerlSetVar NISPlus_Group_Table group.org_dir.yoyodyne.com
      PerlSetVar NT_Default_Domains 'eng corporate'
      PerlSetVar NT_Controllers 'bapdc:babdc nypdc:nybdc'
      PerlSetVar AuthenCache_casesensitive off
      PerlAuthenHandler Apache::AuthenCache Apache::AuthenN2 Apache::AuthenCache::manage_cache
      require group eng
      require user john larry
   </Files>

A couple of tips about AuthenCache: 1 comment out the $r->warn lines
that echo the password to the apache error log (they are fine for
debugging but not good for production), and 2 keep in mind that the
cache has to be established separately in each current httpd child
process, so it does not appear to be working consistently until all
the children know about the user.  This is nothing to panic about; we
are just playing the odds: the more active the user is, the more they
will benefit from the caching.

=head1 AUTHOR

valerie at savina dot com (Valerie Delane), originally based more or
less on code shamelessly lifted from Doug MacEachern's
Apache::AuthNIS and Micheal Parkers's Apache::AuthenSMB.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

mod_perl(3), Apache(3)

=cut
