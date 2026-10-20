use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

ok( defined &Clay_MinMemorySize, 'Clay_MinMemorySize is loaded' );

my $size = Clay_MinMemorySize();
ok( $size > 0, "Clay_MinMemorySize() returned a positive value ($size)" );

# A representative set of constants - confirms BOOT installed them.
is( CLAY_LEFT_TO_RIGHT,           0, 'CLAY_LEFT_TO_RIGHT == 0' );
is( CLAY_TOP_TO_BOTTOM,           1, 'CLAY_TOP_TO_BOTTOM == 1' );
is( CLAY__SIZING_TYPE_FIT,        0, 'CLAY__SIZING_TYPE_FIT == 0' );
is( CLAY_RENDER_COMMAND_TYPE_RECTANGLE, 1, 'CLAY_RENDER_COMMAND_TYPE_RECTANGLE == 1' );

my $GROUPS = Clay::XS::_constant_groups();

is( [ sort map { @{ $_->{members} } } values %$GROUPS ], [ sort( Clay::XS::_constant_names() ) ],
	'the constant groups hold exactly the exported constants' );

# Every exported group lists exactly the members of its enum in the patched
# clay.h, in declaration order, so a member Clay adds cannot go missing.
# Explicit values (the flags group's combinations) are not compared.
sub enums_in_header ($path) {
	open my $fh, '<', $path or die "cannot read $path: $!";
	my $source = do { local $/; <$fh> };
	$source =~ s{/\*.*?\*/}{}gs;
	$source =~ s{//[^\n]*}{}g;
	my %enums;
	while ( $source =~ /typedef\s+(?:CLAY_PACKED_ENUM|enum)\s*\{([^}]*)\}\s*(\w+)\s*;/g ) {
		my ($body, $type) = ($1, $2);
		$enums{$type} = [ map { /^\s*(\w+)/ ? $1 : () } split /,/, $body ];
	}
	return \%enums;
}

SKIP: {
	my $header = 'src/clay/clay.h';
	skip "$header is not generated (run make first)", scalar keys %$GROUPS unless -f $header;
	my $enums = enums_in_header($header);
	for my $group ( sort keys %$GROUPS ) {
		my ($type, $members) = @{ $GROUPS->{$group} }{qw(type members)};
		is( $members, $enums->{$type}, "$group lists every member of $type, in order" );
	}
}

# Every enum field of the struct schemas accepts its group's largest value
# and nothing past it: a sequence group's last member, or for a flags group
# every member OR-ed together.
sub largest_value ($group) {
	my $description = $GROUPS->{$group} or die "the schemas name the unknown constant group '$group'";
	my @values = map { Clay::XS->can($_)->() } @{ $description->{members} };
	return $values[-1] if $description->{kind} eq 'sequence';
	my $all = 0;
	$all |= $_ for @values;
	return $all;
}

# Anonymous schemas are listed as '<struct>.<field>'; check_struct takes the
# struct and reaches them through the path.
my $SCHEMAS = Clay::XS::_struct_schemas();
my @enum_fields;
for my $schema ( sort keys %$SCHEMAS ) {
	my ($type, @outer) = split /\./, $schema;
	for my $field ( @{ $SCHEMAS->{$schema} } ) {
		next unless defined $field->{enum};
		push @enum_fields, [ $type, join( '.', @outer, $field->{name} ), largest_value( $field->{enum} ) ];
	}
}
ok( scalar @enum_fields, 'the struct schemas name the enum group of their enum fields' );

# { a => { b => $value } } for the path 'a.b'.
sub nested ($path, $value) {
	my $hash = $value;
	$hash = { $_ => $hash } for reverse split /\./, $path;
	return $hash;
}

for my $case (@enum_fields) {
	my ($type, $path, $last) = @$case;
	ok( lives { check_struct($type, nested($path, $last)) }, "$type.$path accepts $last" ) or note $@;
	like( dies { check_struct($type, nested($path, $last + 1)) },
		qr/^\Q$type.$path\E: expected an integer in 0\.\.$last, got '${\($last + 1)}'/, "$type.$path ends at $last" );
}

done_testing;
