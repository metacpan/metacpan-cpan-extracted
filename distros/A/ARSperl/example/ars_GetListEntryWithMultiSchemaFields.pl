use strict;
use warnings;
use ARS;


my( $server, $user, $passwd, $tcpport ) = ( 'server', 'user', 'passwd', 0 );
my $ctrl = ars_Login( $server, $user, $passwd, '', '', $tcpport );
die qq/ars_Login($server,$user,'***',$tcpport): $ars_errstr\n/ if ! $ctrl;

die qq/This example works for the ARS 7.5 API only\n/ unless ars_APIVersion() == 14;


my $aSchema = [{
	queryFromAlias => 'U',
	schemaName     => 'User',
	joinType       => 0,
	joinQual       => undef,
}, {
	queryFromAlias => 'G',
	schemaName     => 'Group',
	joinType       => 0,
	joinQual       => {
		oper   => 'rel_op',
		rel_op => {
			oper => 'like',
			left => {
				fieldId => 'U.104',
			},
			right => {
				dataType => 'char',
				value    => '%',
			},
#			right => {
#				arith => {
#					oper => '+',
#					left => {
#						dataType => 'char',
#						value    => '%',
#					},		
#					right => {
#						arith => {
#							oper => '+',
#							left => {
#								fieldId => 'G.106',
#							},				
#							right => {
#								dataType => 'char',
#								value    => ';%',
#							},
#						},
#					},
#				},
#			},
		}, 
	},
}];


my $hQualifier = undef; 
my $hQualifier2 = {
	oper   => 'rel_op',
	rel_op => {
		oper => '==',
		left => {
			fieldId => 'G.106',
		},
		right => {
			dataType => 'integer',
			value    => 3,
		},
	},
};


my $aFields = [ 'U.101', 'U.104', 'G.105', 'G.106' ];

my $aSortList = [ 'G.106' => 1 ];


my @entries = ars_GetListEntryWithMultiSchemaFields( $ctrl, $aSchema, $hQualifier, 0, 0, $aFields, @$aSortList );
die qq/ars_GetListEntryWithMultiSchemaFields: $ars_errstr\n/ if $ars_errstr;


foreach my $hEntry ( @entries ){
	use Data::Dumper;
	print Data::Dumper->Dump( [$hEntry], ['entry'] ), "\n";
}














