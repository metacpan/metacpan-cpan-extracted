# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 13:22 (EDT)
# Function: read protocol data
#
# $Id: Protocol.pm,v 1.1 2010/11/01 18:41:43 jaw Exp $

package AC::MrGamoo::Protocol;
use AC::MrGamoo::Debug 'protocol';
use AC::DC::Protocol;
use AC::Import;
use strict;

our @ISA    = 'AC::DC::Protocol';
our @EXPORT = qw(read_protocol read_protocol_no_content);
my $HDRSIZE = __PACKAGE__->header_size();

my %MSGTYPE =
 (
  status		=> { num => 0, reqc => '', 			resc => 'ACPStdReply' },
  heartbeat		=> { num => 1, reqc => '', 			resc => '' },
  heartbeat_request	=> { num => 2, reqc => '', 			resc => 'ACPHeartBeat' },

  scribl_put		=> { num => 11, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },
  scribl_get		=> { num => 12, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },
  scribl_del		=> { num => 13, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },
  scribl_stat		=> { num => 14, reqc => 'ACPScriblRequest',     resc => 'ACPScriblReply' },

  mrgamoo_jobcreate	=> { num => 15, reqc => 'ACPMRMJobCreate',      resc => 'ACPStdReply' },
  mrgamoo_taskcreate	=> { num => 16, reqc => 'ACPMRMTaskCreate',     resc => 'ACPStdReply' },
  mrgamoo_jobabort	=> { num => 17, reqc => 'ACPMRMJobAbort',       resc => 'ACPStdReply' },
  mrgamoo_taskabort	=> { num => 18, reqc => 'ACPMRMTaskAbort',      resc => 'ACPStdReply' },
  mrgamoo_taskstatus	=> { num => 19, reqc => 'ACPMRMTaskStatus',     resc => 'ACPStdReply' },
  mrgamoo_filexfer	=> { num => 20, reqc => 'ACPMRMFileXfer',       resc => 'ACPStdReply' },
  mrgamoo_filedel	=> { num => 21, reqc => 'ACPMRMFileDel',        resc => 'ACPStdReply' },
  mrgamoo_diagmsg	=> { num => 22, reqc => 'ACPMRMDiagMsg',        resc => 'ACPStdReply' },
  mrgamoo_xferstatus	=> { num => 23, reqc => 'ACPMRMXferStatus',     resc => 'ACPStdReply' },
  mrgamoo_status	=> { num => 24, reqc => 'ACPMRMStatusRequest',  resc => 'ACPMRMStatusReply' },

 );


for my $name (keys %MSGTYPE){
    my $r = $MSGTYPE{$name};
    __PACKAGE__->add_msg( $name, $r->{num}, $r->{reqc}, $r->{resc});
}



sub read_protocol {
    my $io  = shift;
    my $evt = shift;

    $io->{rbuffer} .= $evt->{data};

    return read_http($io, $evt) if $io->{rbuffer} =~ /^GET/;

    my $p = _check_protocol( $io, $evt );
    return unless $p; 	# read more

    # do we have everything?
    return unless length($io->{rbuffer}) >= ($p->{data_length} + $p->{content_length} + $HDRSIZE);

    my $data    = substr($io->{rbuffer}, $HDRSIZE, $p->{data_length});
    my $content = substr($io->{rbuffer}, $HDRSIZE + $p->{data_length}, $p->{content_length});

    # content is passed as reference
    return ($p, $data, ($content ? \$content : undef));
}

sub read_protocol_no_content {
    my $io  = shift;
    my $evt = shift;

    $io->{rbuffer} .= $evt->{data};

    return _read_http($io, $evt) if $io->{rbuffer} =~ /^GET/;

    my $p = _check_protocol( $io, $evt );
    return unless $p; 	# read more

    # do we have everything?
    return unless length($io->{rbuffer}) >= ($p->{data_length} + $HDRSIZE);

    my $data    = substr($io->{rbuffer}, $HDRSIZE, $p->{data_length});
    my $content = substr($io->{rbuffer}, $HDRSIZE + $p->{data_length}, $p->{content_length});

    return ($p, $data, $content);
}

sub _check_protocol {
    my $io  = shift;
    my $evt = shift;

    if( length($io->{rbuffer}) >= $HDRSIZE && !$io->{proto_header} ){
        # decode header
        eval {
            $io->{proto_header} = __PACKAGE__->decode_header( $io->{rbuffer} );
        };
        if(my $e=$@){
            verbose("cannot decode protocol header: $e");
            $io->run_callback('error', {
                cause	=> 'read',
                error	=> "cannot decode protocol: $e",
            });
            $io->shut();
            return;
        }
    }

    return $io->{proto_header};
}

# for simple status queries, argus, debugging
# this is not an RFC compliant http server
sub _read_http {
    my $io  = shift;
    my $evt = shift;

    return unless $io->{rbuffer} =~ /\r?\n\r?\n/s;
    my($get, $url, $http) = $io->{rbuffer} =~ /^(\S+)\s+(\S+)\s+(\S+)/;

    return ( { type => 'http' }, $url );
}


1;
