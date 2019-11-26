
use Test::More;

BEGIN { use_ok('DDCCI') };

ok( defined &get_vcp_addr, 'function get_vcp_addr() presence' );
ok( get_vcp_addr('code page') == 0x00, 'check valid vcp name' );
ok( get_vcp_addr('CODE PAGE') == 0x00, 'check valid vcp name, uppercase' );
ok( get_vcp_addr('') == -1, 'check empty vcp name' );
ok( get_vcp_addr('_iNvAlId!_') == -1, 'check invalid vcp name' );
ok( get_vcp_addr(undef) == -1, 'check null vcp name' );

ok( defined &get_vcp_name, 'function get_vcp_name() presence' );
ok( get_vcp_name(0x00) eq 'Code Page', 'check valid vcp addr' );
ok( get_vcp_name(0xff) eq '???', 'check invalid vcp addr' );

ok( defined &list_vcp_names, 'function list_vcp_names() presence' );
my $names = list_vcp_names();
my $cnt = 0;
(get_vcp_name($_) ne '???') && $cnt++ for (0x00 .. 0xff);
ok( $names->[0] eq 'Code Page', 'check first vcp name' );
ok( scalar @{$names} == $cnt, 'check names count' );

ok( defined &decode_edid, 'function decode_edid() presence');
ok( ! defined decode_edid(undef), 'check null edid' );
ok( ! defined decode_edid(''), 'check empty edid' );
my $de = decode_edid(pack 'C128', 0x00);
ok( $de->{'id'} eq '@@@0000', 'check zeroed edid');

done_testing();
