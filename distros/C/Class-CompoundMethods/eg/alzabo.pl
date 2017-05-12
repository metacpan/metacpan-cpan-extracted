use Class::CompoundMethods 'append_method';

my @versioned_tables = ( 'contacts' );
my @audited_tables = ( 't_interest','t_contact', 'contacts' );


for my $table_list ( { tables => \ @versioned_tables,
                       prefix => 'versioned' },
                     { tables => \ @audited_tables,
                       prefix => 'audited' } ) {
    my $tables = $table_list->{'tables'};
    my $prefix = $table_list->{'prefix'};
 
    for my $table ( @$tables ) {
        for my $hook ( qw[pre_insert pre_update pre_delete]) {
 
            my $method_name = "GreenPartyDB::Database::${table}::${hook}";
            my $method_inst = __PACKAGE__ . "::${prefix}_${hook}";
            append_method( $method_name, $method_inst );
 
        }
    }
}
 
sub versioned_pre_insert { 1 }
sub versioned_pre_update { 1 }
sub versioned_pre_delete { 1 }
sub audited_pre_insert { 1 }
sub audited_pre_update { 1 }
sub audited_pre_delete { 1 }
