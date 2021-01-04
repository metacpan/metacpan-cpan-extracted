# -*- mode: cperl; mode: follow; -*-
#

package App::Regather::Plugin::configfile;

=head1 NAME

configfile - plugin to generate configuration file

=cut

use strict;
use warnings;
use diagnostics;

use POSIX;
use IPC::Open2;
use File::Temp;
use Template;

use Net::LDAP;
use Net::LDAP::Util qw(generalizedTime_to_time);

use constant SYNST => [ qw( LDAP_SYNC_PRESENT LDAP_SYNC_ADD LDAP_SYNC_MODIFY LDAP_SYNC_DELETE ) ];

=head1 METHODS

Each loadable module must provide at least two method: the
cosntructor B<new> and runtime method B<run>.

=head2 new

Creates an instance of the class and saves a reference to its
arguments for further use.

=cut

sub new {
  my ( $self, $args ) = @_;

  bless {
	 cf           => delete $args->{cf},
	 force        => delete $args->{force},
	 log          => delete $args->{log},
	 obj          => delete $args->{obj},
	 out_file_old => delete $args->{out_file_old},
	 rdn          => delete $args->{rdn},
	 service      => delete $args->{s},
	 st           => delete $args->{st},
	 ts_fmt       => delete $args->{ts_fmt},
	 v            => delete $args->{v},
	 rest         => $args,
	}, $self;
}

sub cf           { shift->{cf} }
sub force        { shift->{force} }
sub log          { shift->{log} }
sub obj          { shift->{obj} }
sub out_file_old { shift->{out_file_old} }
sub rdn          { shift->{rdn} }
sub service      { shift->{service} }
sub syncstate    { shift->{st} }
sub ts_fmt       { shift->{ts_fmt} }
sub v            { shift->{v} }
sub rest         { shift->{rest} }


=head2 ldap_sync_add_modify

performs creation for new and re-wring for existent config file

=cut

sub ldap_sync_add_modify {
  my $self = shift;

  my ($tt_vars, $pp, $chin, $chou, $chst, $cher);

  $self->log->cc( pr => 'debug', fm => "%s called with arguments: %s",
		  ls => [ __PACKAGE__, join(',', sort(keys( %{$self}))), ] ) if $self->{v} > 3;

  ### PREPARING OUTPUT RELATED VARIABLES
  my %out_paths = out_paths( cf      => $self->cf,      obj => $self->obj,
			     service => $self->service, rdn => $self->rdn, log => $self->log );
  return if ! %out_paths;
  my $out_file_pfx //= $out_paths{out_file_pfx};
  my $out_file     //= $out_paths{out_file};
  my $dir          = $out_file_pfx // $self->cf->get('service', $self->service, 'out_path');
  my $out_to       = $dir . '/' . $out_file;

  $self->log->cc( pr => 'debug', fm => "%s: output directory: %s; file: %s",
		  ls => [ __PACKAGE__, $dir, $out_file ] ) if $self->{v} > 2;

  if ( defined $self->out_file_old ) {
    if ( unlink $dir . '/' . $self->out_file_old ) {
      $self->log->cc( pr => 'info', fm => "%s: file %s deleted (after ModRDN)",
		ls => [ __PACKAGE__, $dir . '/' . $self->out_file_old ] );
    } else {
      $self->log->cc( pr => 'err', fm => "%s: %s not removed (after ModRDN); error: %s",
		      ls => [ __PACKAGE__, $dir . '/' . $self->out_file_old, $! ], nt => 1, );
    }
  }

  ### COLLECTING ALL MAPPED ATTRIBUTES VALUES
  foreach my $i ( ( 'm', 's') ) {
    if ( $self->cf->is_section('service', $self->service, 'map', $i) ) {
      foreach my $j ( $self->cf->names_of('service', $self->service, 'map', $i) ) {
	if ( $i eq 's' && ! $self->obj->exists( $self->cf->get('service', $self->service, 'map', $i, $j)) ) {
	  if ( $self->cf->get(qw(core dryrun)) ) {
	    $self->log->cc( pr => 'debug', fm => "%s: DRYRUN: %s to be deleted (no attribute: %s)",
		      ls => [ __PACKAGE__, $out_to, $self->cf->get('service', $self->service, 'map', $i, $j) ] );
	  } else {
	    if ( unlink $out_to ) {
	      $self->log->cc( pr => 'debug', fm => "%s: file %s deleted (no attribute: %s)",
			ls => [ __PACKAGE__, $out_to, $self->cf->get('service', $self->service, 'map', $i, $j) ] )
		if $self->{v} > 0;
	    } else {
	      $self->log->cc( pr => 'err', fm => "%s: %s not removed (no attribute: %s); error: ",
			ls => [ __PACKAGE__, $out_to, $self->cf->get('service', $self->service, 'map', $i, $j), $! ],
			nt => 1, );
	    }
	  }

	  ### if any of `map s` attributes doesn't exist, we delete that config file
	  ### preliminaryly and skip that attribute from been processed by Template
	  next;

	} elsif ( $i eq 'm' && $self->obj->exists( $self->cf->get('service', $self->service, 'map', $i, $j)) ) {
	  $tt_vars->{$j} = $self->obj->get_value( $self->cf->get('service', $self->service, 'map', $i, $j),
					    asref => 1 );
	} else {
	  if ( $j =~ /certificateRevocationList/ ) {
	    $tt_vars->{$j} =
	      opensslize({ in => $self->obj->get_value( $self->cf->get('service', $self->service, 'map', $i, $j) ) });
	  } elsif ( $j =~ /cACertificate/ ) {
	    $tt_vars->{$j} =
	      opensslize({ cmd => 'x509',
			   in  => $self->obj->get_value( $self->cf->get('service', $self->service, 'map', $i, $j) ),
			   log => $self->log,
			   v => $self->{v} });
	  } else {
	    $tt_vars->{$j} = $self->obj->get_value( $self->cf->get('service', $self->service, 'map', $i, $j) ) // 'NA';
	  }
	}
      }
    }
  }

  $tt_vars->{prog}       = $self->{prog};
  $tt_vars->{DN}         = $self->obj->dn;
  $tt_vars->{date}       = strftime( $self->{ts_fmt}, localtime(time));
  $tt_vars->{descr}      = $self->obj->get_value('description')
    if $self->obj->exists('description');
  $tt_vars->{server}     = ( split(/\@/, $self->obj->get_value('authorizedService')) )[1]
    if $self->obj->exists('authorizedService');
  $tt_vars->{createdby}  =
    $self->obj->exists('creatorsName') ?
    ( split(/=/, ( split(/,/, $self->obj->get_value('creatorsName')) )[0]) )[1] :
    'UNKNOWN';
  $tt_vars->{modifiedby} =
    $self->obj->exists('modifiersName') ?
    ( split(/=/, ( split(/,/, $self->obj->get_value('modifiersName')) )[0]) )[1] :
    'UNKNOWN';

  if ( ! $self->force && -e $out_to &&
       ( generalizedTime_to_time($self->obj->get_value('modifyTimestamp'))
	 <
	 (stat($out_to))[9] ) ) {
    $self->log->cc( pr => 'debug',
	      fm => "%s: skip. object %s is older than target file %s, (object modifyTimestamp: %s is older than file mtime: %s",
	      ls => [ __PACKAGE__, $self->obj->dn, $out_to,
		      strftime( "%F %T",
				localtime(generalizedTime_to_time($self->obj->get_value('modifyTimestamp')))),
		      strftime( "%F %T", localtime((stat($out_to))[9])),
		    ] )
      if $self->{v} > 0;
    return;
  }

  ### PICKING ROOT OBJECT RDN (IN OUR CASE IT IS "UID")
  foreach ( reverse split(/,/, $self->obj->dn) ) {
    next if $_ !~ /^uid=/;
    $tt_vars->{uid} = ( split(/=/, $_) )[1];
    last;
  }

  ### DRYRUN
  if ( $self->cf->get(qw(core dryrun)) ) {

    $self->log->cc( pr => 'debug', fm => "%s: DRYRUN: %s -> %s",
	      ls => [ __PACKAGE__,
		     sprintf("%s/%s", $self->cf->get(qw(core tt_path)),
			     $self->cf->get('service', $self->service, 'tt_file')),
		     $dir. '/' . $out_file
		    ] );

    if ( $self->cf->is_set($self->service, 'chmod') ) {
      $self->log->cc( pr => 'err', fm => "%s: DRYRUN: chmod %s, %s",
		ls => [ __PACKAGE__, $self->cf->get('service', $self->service, 'chmod'), $out_to ] );
    } elsif ( $self->cf->is_set(qw(core chmod)) ) {
      $self->log->cc( pr => 'err', fm => "%s: DRYRUN: chmod %s, %s",
		ls => [ __PACKAGE__, $self->cf->get('core', 'chmod'), $out_to ] );
    }

    if ( $self->cf->is_set($self->service, 'chown') ) {
      $self->log->cc( pr => 'err', fm => "%s: DRYRUN: chown %s, %s, %s",
		ls => [ __PACKAGE__, $self->obj->get_value('uidNumber'),
			$self->obj->get_value('gidNumber'),
			$out_to ] );
    }
    return;
  }

  my ( $tmp_fh, $tmp_fn );
  eval { $tmp_fh = File::Temp->new( UNLINK => 0, DIR => $dir ); };
  if ( $@ ) {
    $self->log->cc( pr => 'err', fm => "%s: File::Temp->new( DIR => %s ); service \"%s\"; err: \"%s\"",
	      ls => [ __PACKAGE__, $dir, $self->service, $@ ] );
    return;
  }
  $tmp_fn = $tmp_fh->filename;
  my $tt = Template->new( TRIM        => $self->cf->get(qw(core tt_trim)),
			  ABSOLUTE    => 1,
			  RELATIVE    => 1,
			  OUTPUT_PATH => $dir,
			  DEBUG       => $self->log->foreground // $self->cf->get(qw(core tt_debug)) );

  $self->log->cc( pr => 'err', fm => "%s: Template->new( OUTPUT_PATH => %s ) for service %s error: %s",
	    ls => [ __PACKAGE__, $dir, $self->service, $! ] )
    if ! defined $tt;

  $tt->process( sprintf("%s/%s",
			$self->cf->get(qw(core tt_path)),
			$self->cf->get('service', $self->service, 'tt_file')),
		$tt_vars,
		$tmp_fh ) || do {
		  $self->log->cc( pr => 'err', fm => "%s: %s .tt process error: %s",
			    ls => [ __PACKAGE__, SYNST->[$self->syncstate], $tt->error ] );
		  return;
		};

  close( $tmp_fh ) || do {
    $self->log->cc( pr => 'err', fm => "%s: close file (opened for writing), service %s, failed: %s",
	      ls => [ __PACKAGE__, $self->service, $! ] );
    next;
  };

  if ( $self->cf->get(qw(core dryrun)) ) {
    $self->log->cc( pr => 'debug', fm => "%s: DRYRUN: rename %s should be renamed to %s",
	      ls => [ __PACKAGE__, $tmp_fn, $out_file ] );
  } else {
    rename $tmp_fn, $out_to ||
      $self->log->cc( pr => 'err', fm => "%s: rename %s to %s, failed",
		ls => [ __PACKAGE__, $tmp_fn, $out_to ] );

    if ( -e $out_to ) {
      if ( $self->cf->is_set('service', $self->service, 'chmod') ) {
	chmod oct($self->cf->get('service', $self->service, 'chmod')), $out_to ||
	  $self->log->cc( pr => 'err', fm => "%s: chmod for %s failed",
		    ls => [ __PACKAGE__, $out_to ] );
      } elsif ( $self->cf->is_set(qw(core chmod)) ) {
	chmod oct($self->cf->(qw(core chmod))), $out_to ||
	  $self->log->cc( pr => 'err', fm => "%s: chmod for %s failed",
		    ls => [ __PACKAGE__, $out_to ] );
      }

      if ( $self->cf->is_set('service', $self->service, 'chown') ) {
	chown $self->obj->get_value('uidNumber'),
	  $self->obj->get_value('gidNumber'),
	  $out_to ||
	  $self->log->cc( pr => 'err', fm => "%s: chown (%s:%s) %s failed",
		    ls => [ __PACKAGE__, $self->obj->get_value('uidNumber'),
			    $self->obj->get_value('gidNumber'),
			    $out_to ] );
      }
    } else {
      $self->log->cc( pr => 'err', fm => "%s: %s disappeared, no such file any more...",
		ls => [ __PACKAGE__, $out_to ] );
    }
  }
  $self->log->cc( pr => 'debug', fm => "%s: control %s: dn: %s processed successfully.",
	    ls => [ __PACKAGE__, SYNST->[$self->syncstate], $self->obj->dn ] );

  if ( $self->cf->is_set('service', $self->service, 'post_process') ) {
    foreach $pp ( @{$self->cf->get('service', $self->service, 'post_process')} ) {
      my $pid = open2( $chou, $chin, $pp );
      waitpid( $pid, 0 );
      $chst = $? >> 8;
      if ( $chst ) {
	$cher .= $_ while ( <$chou> );
	$self->log->cc( pr => 'err', ls => [ __PACKAGE__, $self->service, $pp, $cher ], nt => 1,
		  fm => "%s: service %s post_process: %s, error: %s", );
      }
    }
  }
}

=head2 ldap_sync_delete

performs deletion of an existent config file

=cut

sub ldap_sync_delete {
  my $self = shift;

  my ($tt_vars, $pp, $chin, $chou, $chst, $cher);

  $self->log->cc( pr => 'debug', fm => "%s: %s called with arguments: %s",
	    ls => [ __PACKAGE__, join(',', sort(keys( %{$self}))), ] ) if $self->{v} > 3;

  ### PREPARING OUTPUT RELATED VARIABLES
  my %out_paths = out_paths( cf      => $self->cf,      obj => $self->obj,
			     service => $self->service, rdn => $self->rdn, log => $self->log );
  return if ! %out_paths;
  my $out_file_pfx //= $out_paths{out_file_pfx};
  my $out_file     //= $out_paths{out_file};
  my $dir          = $out_file_pfx // $self->cf->get('service', $self->service, 'out_path');
  my $out_to       = $dir . '/' . $out_file;

  $self->log->cc( pr => 'debug', fm => "%s: output directory: %s; file: %s",
	    ls => [ __PACKAGE__, $dir, $out_file ] ) if $self->{v} > 2;

  if ( $self->cf->get(qw(core dryrun)) ) {
    $self->log->cc( pr => 'debug', fm => "%s: DRYRUN: file %s should be deleted",
	      ls => [ __PACKAGE__, $out_to ] );
  } else {
    if ( unlink $out_to ) {
      $self->log->cc( pr => 'debug', fm => "%s: file %s was successfully deleted",
		ls => [ __PACKAGE__, $out_to ] )
	if $self->{v} > 0;
    } else {
      $self->log->cc( pr => 'err', fm => "%s: file %s was not removed; error: ",
		ls => [ __PACKAGE__, $out_to, $! ] );
    }
  }
  $self->log->cc( pr => 'debug', fm => "%s: control %s: dn: %s processed successfully..",
	    ls => [ __PACKAGE__, SYNST->[$self->syncstate], $self->obj->dn ] );

  if ( $self->cf->is_set('service', $self->service, 'post_process') ) {
    foreach $pp ( @{$self->cf->get('service', $self->service, 'post_process')} ) {
      my $pid = open2( $chou, $chin, $pp );
      waitpid( $pid, 0 );
      $chst = $? >> 8;
      if ( $chst ) {
	$cher .= $_ while ( <$chou> );
	$self->log->cc( pr => 'err', ls => [ __PACKAGE__, $self->service, $pp, $cher ], nt => 1,
		  fm => "%s: service %s post_process: %s, error: %s", );
      }
    }
  }

}



sub out_paths {
  local %_ = @_;

  my ($out_file_pfx, $out_file);
  if ( $_{cf}->is_set('service', $_{service}, 'out_file_pfx') &&
       $_{cf}->is_set('service', $_{service}, 'out_file') ) {
    $out_file_pfx = $_{obj}->get_value($_{cf}->get('service', $_{service}, 'out_file_pfx'));
    $out_file_pfx = substr($out_file_pfx, 1) if $_{cf}->is_set(qw(core altroot));
    if ( ! -d $out_file_pfx ) {
      $_{log}->cc( pr => 'err', fm => "%s: service %s, target directory %s doesn't exist",
		   ls => [ __PACKAGE__, $_{service}, $out_file_pfx ] );
      return ();
    } else {
      $out_file = sprintf("%s%s",
			  $_{cf}->get('service', $_{service}, 'out_file'),
                          $_{cf}->get('service', $_{service}, 'out_ext') // '');
    }
  } elsif ( ! $_{cf}->is_set('service', $_{service}, 'out_file_pfx') &&
            $_{cf}->is_set('service', $_{service}, 'out_file')) {
    $out_file = sprintf("%s%s",
			$_{cf}->get('service', $_{service}, 'out_file'),
                        $_{cf}->get('service', $_{service}, 'out_ext') // '');
  } elsif ( ! $_{cf}->is_set('service', $_{service}, 'out_file_pfx') &&
            ! $_{cf}->is_set('service', $_{service}, 'out_file')) {
    $out_file = sprintf("%s%s",
			$_{rdn_val} // $_{obj}->get_value($_{rdn}),
                        $_{cf}->get('service', $_{service}, 'out_ext') // '');
  }

  return ( out_file_pfx => $out_file_pfx, out_file => $out_file );
}

sub opensslize {
  my $args = shift;
  my $arg = { cmd     => $args->{cmd}     // 'crl',
	      in      => $args->{in},
	      inform  => $args->{inform}  // 'DER',
	      outform => $args->{outform} // 'PEM',
	    };

  my ( $chin, $chou );
  my $pid = open2($chou, $chin,
		  '/usr/bin/openssl', $arg->{cmd}, '-inform', $arg->{inform}, '-outform', $arg->{outform});

  print $chin $arg->{in};
  waitpid( $pid, 0 );
  my $chst = $? >> 8;

  $args->{log}->cc( pr => 'err', fm => "%s: opensslize() error!", ls => [ __PACKAGE__ ] )
    if $chst && $args->{v} > 1;

  $arg->{res} .= $_ while ( <$chou> );

  return $arg->{res};
}

######################################################################

1;
