use ExtUtils::MakeMaker;
WriteMakefile(
    NAME			=> 'Crypt::Dining',
    VERSION_FROM	=> 'lib/Crypt/Dining.pm',
    PREREQ_PM		=> {
			'Crypt::Random'				=> 0,
			'Net::Address::IPv4::Local'	=> 0,
					},
	ABSTRACT_FROM	=> 'lib/Crypt/Dining.pm',
	AUTHOR			=> 'Shevek <shevek@cpan.org>',
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux readme

aux : readme

readme : lib/Crypt/Dining.pm
	perldoc -t lib/Crypt/Dining.pm > README

EON
	return $old . $new;
}
