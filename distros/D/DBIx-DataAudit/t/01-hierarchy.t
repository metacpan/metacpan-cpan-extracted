use strict;
use Test::More tests => 38;

use_ok 'DBIx::DataAudit';

no warnings 'once';
my @all_types = sort keys %DBIx::DataAudit::trait_hierarchy;
my @all_traits = sort keys %DBIx::DataAudit::trait_type;

my %seen_trait;
for (['count'  => 'any','ordered','numeric','string'],
     ['values' => 'any','ordered','numeric','string'],
     ['min'    =>       'ordered','numeric','string'],
     ['max'    =>       'ordered','numeric','string'],
     ['null'   => 'any','ordered','numeric','string'],
     ['avg'    =>                 'numeric'         ],
     ['blank'  =>                           'string'],
     ['empty'  =>                           'string'],
     ['missing'=>                           'string'],
    ) {
    my ($trait,@coltypes) = @$_;
    no warnings 'redefine';
    my %applies; @applies{@coltypes} = (1) x @coltypes;
    $seen_trait{$trait}++;

    for (@all_types) {
        *DBIx::DataAudit::column_type = sub { $_ };
	my $verb = $applies{$_} ? 'applies' : 'does not apply';
        ok( !($applies{$_} xor DBIx::DataAudit->trait_applies($trait,"test")),"$trait $verb to $_")
	;
    };
};

my @unhandled_traits = grep {! $seen_trait{$_}} @all_traits;
is scalar @unhandled_traits, 0, "All traits specified"
    or diag "Unknown traits: @unhandled_traits";
