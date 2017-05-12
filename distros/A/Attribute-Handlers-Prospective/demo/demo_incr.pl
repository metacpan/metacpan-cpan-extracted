package Very::Selfish;

sub TIESCALAR {
        use Data::Dumper 'Dumper';
        bless { value => $_[2] }, $_[0];
}

sub FETCH {
	$_[0]{value}++;
}

package main;

use Attribute::Handlers::Prospective
	autotieref => { UNIVERSAL::Selfish => Very::Selfish };

package Elsewhere;

while (<>) {
	chomp;
	my $next : Selfish($_);

	print "$next\n";
	print "$next\n";
	print "$next\n";
}
