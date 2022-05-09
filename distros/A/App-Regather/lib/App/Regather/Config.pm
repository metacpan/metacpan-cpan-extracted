# -*- mode: cperl; eval: (follow-mode); -*-
#

package App::Regather::Config;

use strict;
use warnings;
use diagnostics;
use parent 'Config::Parser::Ini';
use Carp;
use File::Basename;

use App::Regather::Plugin;

use constant LDAP => { opt => { async      => '',
				debug      => '',
				inet4      => '',
				inet6      => '',
				keepalive  => '',
				localaddr  => '',
				multihomed => '',
				onerror    => '',
				port       => 'port',
				raw        => '',
				scheme     => '',
				timeout    => 'timeout',
				uri        => 'uri',
				version    => '',
			      },

		       ssl => {
			       cafile     => 'tls_cacert',
			       capath     => 'tls_cacertdir',
			       checkcrl   => 'tls_crlfile',
			       ciphers    => 'tls_cipher_suite',
			       clientcert => 'tls_cert',
			       clientkey  => 'tls_key',
			       keydecrypt => '',
			       sslversion => 'tls_protocol_min',
			       verify     => { tls_reqcert => {
							       none   => 'never',
							       allow  => 'optional',
							       demand => 'require',
							       hard   => 'require',
							       try    => 'optional',
							      },
					     },
			      },
		       bnd => {
			       anonymous => '',
			       dn        => 'binddn',
			       password  => 'bindpw',
			      },

		       srch=> {
			       attrs     => '',
			       base      => 'base',
			       filter    => '',
			       raw       => '',
			       scope     => '',
			       sizelimit => 'sizelimit',
			       timelimit => 'timelimit',
			      }
		     };

=pod

=encoding UTF-8

=head1 NAME

App::Regather::Config - config file processing class

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a class to log messages.

=head1 CONSTRUCTOR

=over 4

=item new

Creates a new B<App::Regather::Config> object

=over 4

=item filename =E<gt> config-file-name

Name of the file to parse.

=item cli =E<gt> = delete $_{cli};

Hash with CLI provided config options.

=item logger =E<gt> = delete $_{logger};

App::Regather::Logg object created preliminary.

=item fg =E<gt> 0 | 1

wheather we run in foreground

=item verbose  =E<gt> N

verbosity level

=back

=back

=cut

sub new {
  my $class = shift;
  local %_  = @_;

  my $filename = delete $_{filename};
  my $cli      = delete $_{cli};
  my $logger   = delete $_{logger};
  my $fg       = delete $_{fg};
  my $verbose  = delete $_{verbose};
  my $nodes    = delete $_{add_nodes};

  my $self = $class->SUPER::new(%_);

  $self->{logger}  = $logger;
  $self->{verbose} = $verbose;

  $self->get_ldap_config_file;

  $self->parse($filename);

  if ( defined $cli && ref($cli) eq 'HASH' ) {
    while ( my( $k, $v ) = each %{$cli} ) {
      $self->add_value($k, $v, new Text::Locus("\noption \"$k\" provided from CLI",1)) ||
	exit 1;
    }
  } elsif ( defined $cli && ref($cli) ne 'HASH' ) {
    $self->error("malformed option/s provided from CLI");
    exit 1;
  }

  # set node/s (absent in config file) from arguments if any
  if ( defined $nodes ) {
    while (my ($key, $val) = each %$nodes) {
      next if ! %$val;
      while (my ($k, $v) = each %$val) {
	# next if $self->is_set($key, $k);
	$self->set($key, $k, $v);
      }
    }
  }

  $self->commit or return;

  $self
}

=head1 METHODS

=over 4

=item get_ldap_config_file

ldap.conf processing (with L<Config::Parser::ldap>) to add options
from it to config object

files searched are:

    $ENV{LDAP_CONF}
    /usr/local/etc/openldap/ldap.conf
    /etc/ldap.conf
    /etc/ldap/ldap.conf
    /etc/openldap/ldap.conf );

the first one found is used.

=cut

sub get_ldap_config_file {
  my $self = shift;

  use Config::Parser::ldap;

  my $ldap_config = {};
  my @ldap_config_files = qw( /usr/local/etc/openldap/ldap.conf
			      /etc/ldap.conf
			      /etc/ldap/ldap.conf
			      /etc/openldap/ldap.conf );

  unshift @ldap_config_files, $ENV{LDAP_CONF} if defined($ENV{LDAP_CONF});

  my ( $cf, $val );

  foreach (@ldap_config_files) {
    if ( -e $_ ) {
      $cf = new Config::Parser::ldap(filename => $_ );

      foreach my $section ( keys %{ LDAP()} ) { # $section: bnd, opt or ssl
	foreach my $item ( keys %{ LDAP->{$section} } ) { # $_: item in each of ones above

	  $self->add_value( 'ldap.' . $section . '.' . $item,

			    $section eq 'ssl' && $item eq 'verify' && $cf->is_set('tls_reqcert')
			    ?
			    LDAP->{$section}->{$item}->{tls_reqcert}->{ $cf->get('tls_reqcert') }
			    :
			    $cf->get( LDAP->{$section}->{$item} ),

			    new Text::Locus("option \"$item\" provided from ldap.conf",1))
	    if LDAP->{$section}->{$item} ne '' &&
	    $cf->is_set( LDAP->{$section}->{$item} ) &&
	    ! $self->is_set( 'ldap', $section, $item );
	}
      }
      last;
    }
  }
}

=item mangle

modify the created source tree. (resolve I<uid/gid> symbolic to number, add I<altroot>)

=cut

sub mangle {
  my $self = shift;
  my ( $section, $item, $k, $v );

  my $re_mod = qr(^Can.t locate.*);

  if ( $self->is_set(qw(core uid)) ) {
    $item = getpwnam( $self->get(qw(core uid)) );
    if ( defined $item ) {
      $self->{logger}->cc( pr => 'info', fm => "%s: setuid user %s(%s) confirmed",
			   ls => [ sprintf("%s:%s",__FILE__,__LINE__), $self->get(qw(core uid)), $item ] )
	if $self->{verbose} > 1;
      $self->set('core', 'uid_number', $item);
    } else {
      print "No user $self->get('uid') found\n\n";
      exit 2;
    }
  }

  if ( $self->is_set(qw(core gid)) ) {
    $item = getgrnam( $self->get(qw(core gid)) );
    if ( defined $item ) {
      $self->{logger}->cc( pr => 'info', fm => "%s: setgid group %s(%s) confirmed",
			   ls => [ sprintf("%s:%s",__FILE__,__LINE__), $self->get(qw(core gid)), $item ] )
	if $self->{verbose} > 1;
      $self->set('core', 'gid_number', $item);
    } else {
      print "No group $self->get('gid') found\n\n";
      exit 2;
    }
  }

  foreach my $svc ( $self->names_of('service') ) {
    if ( $self->is_set(qw($svc uid)) ) {
      $item = getpwnam( $self->get(qw($svc uid)) );
      if ( defined $item ) {
	$self->{logger}->cc( pr => 'info', fm => "%s: setuid user %s(%s) confirmed",
			     ls => [ sprintf("%s:%s",__FILE__,__LINE__), $self->get(qw($svc uid)), $item ] )
	  if $self->{verbose} > 1;
	$self->set($svc, 'uid_number', $item);
      } else {
	print "No user $self->get('uid') found\n\n";
	exit 2;
      }
    }

    if ( $self->is_set($svc, 'gid') ) {
      $item = getgrnam( $self->get($svc, 'gid') );
      if ( defined $item ) {
	$self->{logger}->cc( pr => 'info', fm => "%s: setgid group %s(%s) confirmed",
			     ls => [ sprintf("%s:%s",__FILE__,__LINE__), $self->get(qw($svc gid)), $item ] )
	  if $self->{verbose} > 1;
	$self->set($svc, 'gid_number', $item);
      } else {
	print "No group $self->get('gid') found\n\n";
	exit 2;
      }
    }

    if ( $self->is_set('service', $svc, 'plugin') ) {
      foreach my $plg ( $self->get('service', $svc, 'plugin') ) {

	if ( $plg eq 'nsupdate' ) {
	  eval { require Net::DNS };
	  if ( $@ =~ /$re_mod/ ) {
	    print "ERROR: ", sprintf("%s:%s",__FILE__,__LINE__), ": ", $@, "\n";
	    exit 2;
	  }

	  if ( ! $self->is_set('service', $svc, 'ns_attr') ) {
	    print sprintf("%s:%s",__FILE__,__LINE__), ": service $svc lacks ns_attr option\n";
	    exit 2;
	  }
	}

	if ($plg eq 'configfile' ) {
	  eval { require Template };
	  if ( $@ =~ /$re_mod/ ) {
	    print "ERROR: ", sprintf("%s:%s",__FILE__,__LINE__), ": ", $@, "\n";
	    exit 2;
	  }

	  eval { require File::Temp };
	  if ( $@ =~ /$re_mod/ ) {
	    print "ERROR: ", sprintf("%s:%s",__FILE__,__LINE__), ": ", $@, "\n";
	    exit 2;
	  }

	  if ( ! $self->is_set('service', $svc, 'tt_file') ) {
	    print sprintf("%s:%s",__FILE__,__LINE__), ": service $svc lacks tt_file option\n";
	    exit 2;
	  }
	}

      }
    }

  }

  if ( $self->is_set(qw(core altroot)) ) {
    chdir($self->get(qw(core altroot))) || do {
      $self->{logger}->cc( pr => 'err', fm => "%s: unable to chdir to %s",
			   ls => [ sprintf("%s:%s",__FILE__,__LINE__), $self->get(qw(core altroot)) ] );
      exit 1;
    };

    foreach ( $self->names_of('service') ) {
      $self->add_value('service.' . $_ . '.out_path',
		       substr($self->get('service', $_, 'out_path'), 1),
		       new Text::Locus(sprintf("in \"%s\" ", $self->get(qw(core altroot))), 1)) ||
			 exit 1;
      $self->{logger}->cc( pr => 'debug', fm => "%s: service %s out_path has been changed to %s",
			   ls => [ sprintf("%s:%s",__FILE__,__LINE__), $_, $self->get('service', $_, 'out_path') ] )
	if $self->{verbose} > 1;
    }
  } else {
    chdir('/');
  }

  if ( $self->get(qw(core notify)) == 1 && ! $self->is_set(qw(core notify_email)) ) {
    print "option core.notify requested, while core.notify_email is not set\n\n";
    exit 2;
  }
}

=item config_help

print config lexicon help

output is not sorted, it is in todo

=cut

sub config_help {
  my $self = shift;

  my $lex = $self->lexicon;
  my ( $default, $re, $check );
  foreach (sort keys %$lex) {
    print "\n[$_]\n";
    while ( my($k,$v) = each %{$lex->{$_}->{section}} ) {
      if ( ref($v) eq 'HASH' && exists $v->{section} ) {
	print "\n[$_ $k]\n";
	while ( my($kk,$vv) = each %{$v->{section}} ) {
	  if ( ref($vv) eq 'HASH' && exists $vv->{section} ) {
	    print "\n[$_ $k $kk]\n";
	    while ( my($kkk,$vvv) = each %{$vv->{section}} ) {
	      if ( ref($vvv) eq 'HASH' && exists $vvv->{section} ) {
		print "\n[$_ $k $kk $kkk]\n";
		while ( my($kkkk,$vvvv) = each %{$vvv->{section}} ) {
		  print $self->config_help_opt($kkkk, $vvvv);
		}
	      } else {
		print $self->config_help_opt($kkk, $vvv);
	      }
	    }
	  } else {
	    print $self->config_help_opt($kk, $vv);
	  }
	}
      } else {
	print $self->config_help_opt($k, $v);
      }
    }
  }

  if ( $self->{verbose} > 0 ) {
    print "\n\n";
    $self->{logger}->cc( fg => 1, pr => 'info', fm => "%s: lexicon():%s\n%s",
			 ls => [ sprintf("%s:%s",__FILE__,__LINE__), '-' x 70, $lex ] );
  }
}

sub config_help_opt {
  my ($self, $k, $v) = @_;
  return sprintf("  %- 20s%s%s%s%s\n",
		 $k,
		 $v->{mandatory} ? ' :mandatory' : '',
		 $v->{default}   ? ' :default ' . $v->{default} : '',
		 $v->{re}        ? ' :re ' . $v->{re}      : '',
		 $v->{check}     ? ' :check ' . $v->{check}   : '');
}

=item chk_dir

check wheather the target directory exists

=cut

sub chk_dir {
  my ($self, $valref, $prev_value, $locus) = @_;

  unless ( -d $$valref ) {
    $self->error("directory \"$$valref\" does not exist",
		 locus => $locus);
    return 0;
  }
  $self->{chk_dir_passed} = 1;
  return 1;
}

sub chk_dir_pid {
  my ($self, $valref, $prev_value, $locus) = @_;
  my $dir = dirname($$valref);
  unless ( -d $dir ) {
    $self->error("pid file directory \"$dir\"does not exist",
		 locus => $locus);
    return 0;
  }
  return 1;
}

=item chk_file_tt

.tt file existance checker

=cut

sub chk_file_tt {
  my ($self, $valref, $prev_value, $locus) = @_;
  my $tt = sprintf("%s/%s",
		   $self->tree->subtree('core')->subtree('tt_path')->value,
		   $$valref);

  unless ( -f $tt && -r $tt  ) {
    $self->error(sprintf("file \"%s\" does not exist", $tt),
		 locus => $locus);
    return 0;
  }
  return 1;
}

=item core_only

informer (to spawn error if I<core> section option been used in not I<core> section)

=cut

sub core_only {
  my ($self, $valref, $prev_value, $locus) = @_;
  $self->error(sprintf("wrong location for option, it can appear only in the section \"core\""),
	       locus => $locus);
  return 0;
}

=item chk_notify_email

email address validation against regex

    ^[a-z0-9]([a-z0-9.]+[a-z0-9])?\@[a-z0-9.-]+$

=cut

sub chk_notify_email {
  my ($self, $valref, $prev_value, $locus) = @_;

  if ( $$valref !~ /^[a-z0-9]([a-z0-9.]+[a-z0-9])?\@[a-z0-9.-]+$/ ) {
    $self->error('notify_email is not valid email address', locus => $locus);
    return 0;
  }

  return 1;
}

=item chk_plugin

check plugin name against existent plugins list

=cut

sub chk_plugin {
  my ($self, $valref, $prev_value, $locus) = @_;
  my %names = App::Regather::Plugin->names;
  $self->{plugin_names} //= [ keys(%names) ];
  0 < grep { $$valref eq $_ } @{$self->{plugin_names}} ? return 1 : return 0;
}

=item error

error handler

=cut

=back

sub error {
  my $self = shift;
  my $err  = shift;
  local %_ = @_;

  $self->{logger}->cc( pr => 'err',
		       fm => "%s: config parser error: %s%s",
		       ls => [ sprintf("%s:%s",__FILE__,__LINE__),
			       exists $_{locus} ? $_{locus} . ': ' : '',
			       $err ] );
}


=head1 CONFIG FILE

An ini-style configuration file is a textual file consisting of
settings grouped into one or more sections.

1. do read L<Config::Parser::Ini> documentation section B<DESCRIPTION>
for general description of the format used.

2. look at the output of: I<regather -c regather.conf --config-help>

3. look into sources ... (this section is to be amended yet)

So, in general, config file consists of mandatory sections (with theirs
subsections) B<core>, B<ldap> and B<service>

B<core> must go first, all other after it.

Each section can have mandatory options.

Each I<service> must have these options:

=over 4

1. at least one (can be set multiple times, and in that case all of
   them are checked) option I<ctrl_attr> which contains name of the
   attribute to check in event LDAP object. In case it is present,
   the object is considered to be processed, in case it is absent,
   we skip that event (since LDAP object has no I<ctrl_attr>)

2. one I<ctrl_srv_re> option which is regular expression to match
   service against LDAP event object DN

3. at least one I<plugin> option.
   B<This option should be placed in the end of the section>

=back

If both, 1. and 2. checks are positive, then object considered to be processed
for that service.

Each I<service> must have atleast one of two possible maps. Those maps
are for mapping .tt variables to LDAP attributes values. Maps have
names I<s> for single value attributes and I<m> for attributes which
can have multiple values.

=head1 SEE ALSO

L<App::Regather::Logg>,
L<Config::AST>,
L<Config::Parser>,
L<Config::Parser::Ini>,
L<Config::Parser::ldap>

=head1 AUTHOR

Zeus Panchenko E<lt>zeus@gnu.org.uaE<gt>

=head1 COPYRIGHT

Copyright 2019 Zeus Panchenko.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


1;


__DATA__

[core]
altroot      = STRING :re="^/tmp/.*" :check=chk_dir
dryrun       = NUMBER :default 0
gid          = STRING
notify       = NUMBER :default 0
notify_email = STRING :mandatory :array :check=chk_notify_email
pid_file     = STRING :check=chk_dir_pid :default /var/run/openldap/regather.pid
tt_debug     = NUMBER :default 0
tt_path      = STRING :check=chk_dir :default /usr/local/etc/regather.d
tt_trim      = NUMBER :default 0
uid          = STRING

[log]
facility     = STRING :default local4
colors       = NUMBER :default 0
foreground   = NUMBER :default 0
verbosity    = NUMBER :default 0
altroot      = STRING :check=core_only
dryrun       = STRING :check=core_only
pid_file     = STRING :check=core_only
tt_debug     = STRING :check=core_only
tt_path      = STRING :check=core_only

[ldap]
altroot      = STRING :check=core_only
dryrun       = STRING :check=core_only
pid_file     = STRING :check=core_only
tt_debug     = STRING :check=core_only
tt_path      = STRING :check=core_only
ANY          = STRING

[ldap srch]
attrs        = STRING
base         = STRING
filter       = STRING :mandatory
raw          = STRING
scope        = STRING :default sub
sizelimit    = NUMBER :default 0
timelimit    = NUMBER :default 0
log_base     = STRING

[ldap bnd]
anonymous    = STRING
bindpw       = STRING
dn           = STRING
password     = STRING

[ldap opt]
async        = NUMBER :default 0
debug        = NUMBER :default 0
inet4        = STRING
inet6        = STRING
keepalive    = STRING
localaddr    = STRING
multihomed   = STRING
onerror      = STRING
port         = STRING
raw          = STRING
scheme       = STRING
timeout      = STRING
uri          = STRING
version      = NUMBER :default 3

[ldap ssl]
cafile       = STRING
capath       = STRING
checkcrl     = STRING
ciphers      = STRING
clientcert   = STRING
clientkey    = STRING
keydecrypt   = STRING
ssl          = STRING
sslversion   = STRING
verify       = STRING

[service ANY]
all_attr     = NUMBER :default 0
chmod        = OCTAL  :default 0640
chown	     = NUMBER :default 1
ctrl_attr    = STRING :mandatory :array
ctrl_srv_re  = STRING :mandatory
gid          = STRING
out_ext      = STRING
out_file     = STRING
out_file_pfx = STRING
out_path     = STRING :check=chk_dir
tt_file      = STRING :check=chk_file_tt
uid          = STRING
ns_attr      = STRING
ns_keyfile   = STRING
ns_ttl       = NUMBER :default 600
ns_txt_pfx   = STRING :default REGATHER:
ns_server    = STRING :array
ns_zone      = STRING :array
plugin       = STRING :mandatory :array :check=chk_plugin
notify       = NUMBER :default 0 :check=chk_depend_notify
post_process = STRING :array
skip         = NUMBER :default 0

[service ANY map s]
ANY          = STRING
altroot      = STRING :check=core_only
dryrun       = STRING :check=core_only
pid_file     = STRING :check=core_only
tt_debug     = STRING :check=core_only
tt_path      = STRING :check=core_only

[service ANY map m]
ANY          = STRING
altroot      = STRING :check=core_only
dryrun       = STRING :check=core_only
pid_file     = STRING :check=core_only
tt_debug     = STRING :check=core_only
tt_path      = STRING :check=core_only

