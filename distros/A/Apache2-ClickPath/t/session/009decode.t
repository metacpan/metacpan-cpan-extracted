use strict;

use Test::More tests=>36;
use Apache::TestUtil;

BEGIN {use_ok( 'Apache2::ClickPath::Decode' );}
my $s1='PtVOR9:YhYsyaINNTSaB79NNNNNM';
my $s2=  '6r56:YhYsyaINNTSaB79NNNNNM';
my $s3='s9NNNd:vAYsyaINNTSaB7INNNNNMsMyq*.CF!vq*.InoJ';
my $s4=     'O:vAYsyaINNTSaB7INNNNNMsMyq*.CF!vq*.InoJ';
my $s5=     'N:qHL0wyDpZfpRC189RSdqrNM';

my $decoder=Apache2::ClickPath::Decode->new;

$decoder->parse( $s1 );

ok t_cmp( $decoder->server_id, '10.2.1.19', 'server_id' );
ok t_cmp( $decoder->creation_time, '1121948895', 'creation_time' );
ok t_cmp( $decoder->server_pid, '24909', 'server_pid' );
ok t_cmp( $decoder->connection_id, '0', 'connection_id' );
ok t_cmp( $decoder->seq_number, '55020', 'seq_number' );

$decoder->tag='-S:';

$decoder->parse( 'http://localhost/-S:'.$s1.'/bla' );

ok t_cmp( $decoder->server_id, '10.2.1.19', 'server_id (w/ tag)' );
ok t_cmp( $decoder->creation_time, '1121948895', 'creation_time (w/ tag)' );
ok t_cmp( $decoder->server_pid, '24909', 'server_pid (w/ tag)' );
ok t_cmp( $decoder->connection_id, '0', 'connection_id (w/ tag)' );
ok t_cmp( $decoder->seq_number, '55020', 'seq_number (w/ tag)' );
ok t_cmp( $decoder->session, $s1, 'session (w/ tag)' );

$decoder->server_map='';

$decoder->parse( 'http://localhost/-S:'.$s2.'/bla' );

ok t_cmp( $decoder->server_id, 'test', 'server_id (w/ server_map)' );
ok t_cmp( $decoder->creation_time, '1121948895', 'creation_time (w/ server_map)' );
ok t_cmp( $decoder->server_pid, '24909', 'server_pid (w/ server_map)' );
ok t_cmp( $decoder->connection_id, '0', 'connection_id (w/ server_map)' );
ok t_cmp( $decoder->seq_number, '55020', 'seq_number (w/ server_map)' );

undef $decoder->server_map;
$decoder->parse( 'http://localhost/-S:'.$s3.'/bla' );

ok t_cmp( $decoder->server_id, '127.0.0.1', 'server_id (s3)' );
ok t_cmp( $decoder->creation_time, '1121948895', 'creation_time (s3)' );
ok t_cmp( $decoder->server_pid, '24909', 'server_pid (s3)' );
ok t_cmp( $decoder->connection_id, '0', 'connection_id (s3)' );
ok t_cmp( $decoder->seq_number, '55023', 'seq_number (s3)' );
ok t_cmp( $decoder->remote_session, undef, 'remote_session (s3)' );
ok t_cmp( $decoder->remote_session_host, undef, 'remote_session_host (s3)' );

$decoder->friendly_session=<<'FRIENDLY';
  param.friendly.org   param(ld) param ( id )   f
  uri.friendly.org     uri(1) uri ( 3 )         u
  mixed.friendly.org    param(ld) uri ( 3 )     m
FRIENDLY

$decoder->parse( 'http://localhost/-S:'.$s3.'/bla' );
ok t_cmp( $decoder->session, $s3, 'session (s3 w/ friendly_session)' );
ok t_cmp( $decoder->remote_session, "ld=25\nid=8ab9", 'remote_session (s3 w/ friendly_session)' );
ok t_cmp( $decoder->remote_session_host, 'param.friendly.org', 'remote_session_host (s3 w/ friendly_session)' );

$decoder->server_map=<<'MACHINES';
  localhost A /store
  127.0.0.13 B http://klaus:32810/store
MACHINES

$decoder->parse( 'http://localhost/-S:'.$s4.'/bla' );
ok t_cmp( $decoder->server_name, 'B', 's4 server_name' );
ok t_cmp( $decoder->server_id, '127.0.0.13', 's4 server_id' );

$decoder->server_map=<<'MACHINES';
{B=>['127.0.0.12']}
MACHINES

$decoder->parse( 'http://localhost/-S:'.$s4.'/bla' );
ok t_cmp( $decoder->server_id, '127.0.0.12', 's4 server_id (dumped mach table)' );

$decoder->server_map=+{B=>['127.0.0.11'], A=>['127.0.0.1']};

$decoder->parse( 'http://localhost/-S:'.$s4.'/bla' );
ok t_cmp( $decoder->server_id, '127.0.0.11', 's4 server_id (HASH mach table)' );

$decoder->debug=1;
$decoder->secret='data:,So%20long%20and%20thanks%20for%20all%20the%20fish';
$decoder->parse( 'http://localhost/-S:'.$s5.'/bla' );
ok t_cmp( $decoder->server_id, '127.0.0.1', 'server_id (Secret)' );
ok t_cmp( $decoder->creation_time, 1121948902, 'creation_time (Secret)' );
ok t_cmp( $decoder->server_pid, 24909, 'server_pid (Secret)' );
ok t_cmp( $decoder->connection_id, 0, 'connection_id (Secret)' );
ok t_cmp( $decoder->seq_number, 55034, 'seq_number (Secret)' );

# Local Variables: #
# mode: cperl #
# End: #
