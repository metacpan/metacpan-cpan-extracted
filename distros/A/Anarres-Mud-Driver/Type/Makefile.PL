require 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Anarres::Mud::Driver::Compiler::Type',
    VERSION_FROM	=> 'Type.pm', # finds $VERSION
    AUTHOR			=> 'Shevek (cpan@anarres.org)',
	INC				=> '-I../include',
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	$new .= <<'EON';

dep : $(C_FILES) $(H_FILES)
	$(RM_F) .depend
	$(CC) -MM $(INC) -I$(PERL_INC) $(CCFLAGS) $(C_FILES) >> .depend

include .depend

config :: $(C_FILES)

EON
	return $old . $new;
}
