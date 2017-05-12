package Apache::PerlVINC;

use strict;
use Apache::ModuleConfig ();
use Apache::Constants qw(DECLINE_CMD OK DECLINED);
use DynaLoader ();

$Apache::PerlVINC::VERSION = '0.03';


if($ENV{MOD_PERL}) 
{
  no strict;
  @ISA = qw(DynaLoader);
  __PACKAGE__->bootstrap($VERSION); #command table, etc.
}

sub new { return bless {}, shift }

#------------------------------------------------------------#
#---------------Configuration Directive Methods--------------#
#------------------------------------------------------------#

sub PerlINC ($$$) 
{
  my($cfg, $parms, $path) = @_;
  $cfg->{INC} = $path;
}

sub PerlVersion ($$@) 
{
  my($cfg, $parms, $name) = @_;
  $cfg->{'Files'}->{$name}++;
}



sub handler 
{
  my $r = shift;
  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  if ($r->current_callback() eq "PerlCleanupHandler") 
  {
    map { delete $INC{$_} } keys %{$cfg->{Files}};
    return OK;
  }
   
  local @INC = @INC;
  unshift @INC, @{ $cfg->{'VINC'} };
  for (keys %{ $cfg->{'Files'} }) 
  {
    delete $INC{$_};
    #let mod_perl catch any error thrown here
    require $_;
  }
  
  return OK;
}

#------------------------------------------------------------#
#----------------Configuration Merging Routines--------------#
#------------------------------------------------------------#


sub DIR_CREATE
{
  my $self = shift->new();
  $self->{VINC} ||= [];
  $self->{Files} ||= {};
  return $self;
}


sub DIR_MERGE
{
  my ($prt, $kid) = @_;

  my %new = (%$prt, %$kid);

  $new{INC} = $prt->{INC} if $kid->{INC} eq "";
  %{$new{Files}} = (%{$prt->{Files}}, %{$kid->{Files}});

  # INC paths get built here
  @{$new{VINC}} = ($prt->{INC}, $kid->{INC});

  return bless \%new, ;
}


1;
__END__

=head1 NAME

  Apache::PerlVINC - Allows versioning of modules among directories or v-hosts.

=head1 SYNOPSIS

#example httpd.conf:


<VirtualHost dave.domain.com>

  # include the module. this line must be here.
  PerlModule Apache::PerlVINC

  # set the include path
  PerlINC /home/dave/site/files/modules
  # make sure VINC reloads the modules
  PerlFixupHandler Apache::PerlVINC
  # aptionally have VINC unload versioned modules
  PerlCleanupHandler Apache::PerlVINC


  # reloads Stuff::Things for all requests
  PerlVersion Stuff/Things.pm

  <Location /Spellcheck>
    SetHandler perl-script
    PerlHandler Spellcheck

    # reload version of this module found in PerlINC line
    PerlVersion Spellcheck.pm 
  </Location>

</VirtualHost>

<VirtualHost steve.domain.com>

  PerlModule Apache::PerlVINC
    
  <Location /Spellcheck>
    SetHandler perl-script
    PerlHandler Spellcheck
    PerlFixupHandler Apache::PerlVINC
    # only reload for requests in /Spellcheck

    PerlINC /home/steve/site/files/modules
    PerlVersion Spellcheck.pm  # makes PerlVINC load this version
  </Location>

</VirtualHost>


=head1 DESCRIPTION

With this module you can run two copies of a module without having to
worry about which version is being used. Suppose you have two C<VirtualHost>
or C<Location> that want to each use their own version of C<Spellcheck.pm>.
Durning the FixUp phase, C<Apache::PerlVINC> will tweak C<@INC> and reload 
C<Spellcheck>. Optionally, it will unload that version if you specify 
C<Apache::PerlVINC> as a PerlCleanUpHandler.

As you can guess, this module slows things down a little because it unloads and
reloads on a per-request basis. Hence, this module should only be used in a 
development environment, not a mission critical one.

=head1 DIRECTIVES

=over 4

=item PerlINC

Takes only one argument: the path to be prepended to C<@INC>. In v0.1, this was 
stored internally as an array. This is no longer the case. However, it still works 
somewhat as expected in that subsequent calls to C<PerlINC> will not overwrite the 
previous ones, provided they are not in the same config section (see BUGS). They will 
both be prepended to C<@INC>. Note that C<@INC> is not changed for the entire request, 
so dont count on that path being in C<@INC> for your scripts.

=item PerlVersion

This directives specifies the files you want reloaded. Depending on where this 
directive sits, files will be loaded (and perhaps unloaded). Ie. if this sits in 
a C<Location> section, the files will only be reloaded on requests to that location.
If this lies in a server section, all requests to the server or v-host will have 
these files reloaded. 

=back

=head1 BUGS AND LIMITATIONS

Under some setups, C<PerlModule>'ing PerlVINC will cause the server to silently 
crash on startup. Upgrading C<Apache::ExtUtils> to v/1.04 might fix the problem. As
of this writing, the current version of mod_perl (1.24) does not contain this version
of C<Apache::ExtUtils>. Until the next version is released, you will have to obtain
it from the latest cvs snapshot.

If the C<PerlINC> directive is used twice in the same config section, the first call 
will be overwritten. Ie.

  PerlINC /qwe
  PerlINC /poi
 
  <Location /asdf/>
    PerlINC /zxc
  </Location>

For requests outside of /asdf/, @INC will contain /poi. Inside /asdf/ @INC will 
contain /zxc and /poi. This is kinda sucky, I know, and I hope to fix for the next 
release.

=head1 AUTHORS

 Doug MacEachern <dougm@pobox.com>
 Dave Moore <dave@epals.com>

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
