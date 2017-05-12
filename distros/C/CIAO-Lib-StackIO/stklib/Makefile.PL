use ExtUtils::MakeMaker;

WriteMakefile(
      NAME	=> 'stk',
      LINKTYPE	=> 'static',
      SKIP	=> [qw(dynamic dynamic_lib dlsyms)],
      OBJECT	=> '$(O_FILES)',
      clean	=> { 'FILES' => 'libstk$(LIB_EXT) libstk$(OBJ_EXT)' },
);


sub MY::constants {
    package MY;
    my $self = shift;

    $self->{INST_STATIC} = 'libstk$(LIB_EXT)';

    return $self->SUPER::constants();
}

sub MY::top_targets {
    my $r = '
all :: static
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)

lint:
	lint -abchx $(LIBSRCS)

pure_all ::
	$(NOECHO) $(NOOP)
';
}
