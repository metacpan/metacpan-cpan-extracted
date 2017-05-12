#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 29;
BEGIN { use_ok('Audio::Opusfile') };

my $fail = 0;
foreach my $constname (qw(
	OPUS_CHANNEL_COUNT_MAX OP_ABSOLUTE_GAIN OP_DEC_FORMAT_FLOAT
	OP_DEC_FORMAT_SHORT OP_DEC_USE_DEFAULT OP_EBADHEADER OP_EBADLINK
	OP_EBADPACKET OP_EBADTIMESTAMP OP_EFAULT OP_EIMPL OP_EINVAL OP_ENOSEEK
	OP_ENOTAUDIO OP_ENOTFORMAT OP_EOF OP_EREAD OP_EVERSION OP_FALSE
	OP_GET_SERVER_INFO_REQUEST OP_HEADER_GAIN OP_HOLE
	OP_HTTP_PROXY_HOST_REQUEST OP_HTTP_PROXY_PASS_REQUEST
	OP_HTTP_PROXY_PORT_REQUEST OP_HTTP_PROXY_USER_REQUEST OP_PIC_FORMAT_GIF
	OP_PIC_FORMAT_JPEG OP_PIC_FORMAT_PNG OP_PIC_FORMAT_UNKNOWN
	OP_PIC_FORMAT_URL OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST OP_TRACK_GAIN)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Audio::Opusfile macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );

my $of = Audio::Opusfile->new_from_file('empty.opus');
ok $of->seekable, 'seekable';
is $of->link_count, 1, 'link_count';
is $of->serialno(0),   1745145935, 'serialno, arg=0';
is $of->serialno(200), 1745145935, 'serialno, arg=200';
is $of->serialno,      1745145935, 'serialno, no arg';

my $head = $of->head;
is $head->version, 1, 'head->version';
is $head->channel_count, 2, 'head->channel_count';
is $head->pre_skip, 356, 'head->pre_skip';
is $head->input_sample_rate, 44100, 'head->input_sample_rate';
is $head->output_gain, 0, 'head->output_gain';
is $head->mapping_family, 0, 'head->mapping_family';
is $head->stream_count, 1, 'head->stream_count';
is $head->coupled_count, 1, 'head->coupled_count';
is $head->mapping(0), 0, 'head->mapping(0)';
is $head->mapping(1), 1, 'head->mapping(1)';
eval { $head->mapping(1000) };
isn::t $@, '', 'head->mapping(1000) dies';

my $tags = $of->tags;
is $tags->query_count('TITLE'), 1, 'query_count';
is $tags->query('TITLE'), 'Cellule', 'query';
is_deeply [$tags->query_all('TITLE')], ['Cellule'], 'query_all';

open my $fh, '<', 'empty.opus';
read $fh, my $buf, 100;
ok Audio::Opusfile::test($buf), 'test';

seek $fh, 0, 0;
read $fh, $buf, 20000;
$of = Audio::Opusfile->new_from_memory($buf);
is $of->tags->query('TITLE'), 'Cellule', 'new_from_memory + query';

is $of->pcm_tell, 0, '->pcm_tell is 0 at the beginning';

$of->set_dither_enabled(0);
my ($li, @samples) = $of->read;
is $li, 0, '->read, correct link';
is scalar @samples, 1208, '->read, got correct number of samples';

isn::t $of->pcm_tell, 0, '->pcm_tell is not 0 after read';
$of->raw_seek(0);
is $of->pcm_tell, 0, '->pcm_tell is 0 right after raw_seek';
 @samples = $of->read_float_stereo;
is scalar @samples, 1208, '->read_float_stereo, got correct number of samples';
