#!/usr/bin/perl -w

use strict;

use Alzabo::Create::Schema;

unless (@ARGV)
{
    print <<'EOF';

This script requires at least one argument, a schema name.  If it is
given multiple arguments it will treat them all as script names
EOF

    exit 0;
}

foreach (@ARGV)
{
    my $s = Alzabo::Create::Schema->load_from_file( name => $_ );
    reverse_cardinality($s);
}

sub reverse_cardinality
{
    my $s = shift;

    foreach my $t ($s->tables)
    {
	foreach my $fk ($t->all_foreign_keys)
	{
	    my @c = $fk->cardinality;

	    $fk->set_cardinality(@c[1,0]);
	}
    }

    $s->save_to_file;
}

