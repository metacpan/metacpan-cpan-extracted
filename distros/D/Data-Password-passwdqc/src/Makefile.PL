use ExtUtils::MakeMaker;

my $passwdqc_dir = 'passwdqc';
my @objects = qw(concat passwdqc_check passwdqc_load passwdqc_memzero passwdqc_parse passwdqc_random wordset_4k);

WriteMakefile(
    NAME   => 'passwdqc',
    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    clean  => {'FILES' => 'libpasswdqc$(LIB_EXT)' },
    OBJECT => '$(O_FILES)',
);


package MY;

sub c_o {
    my $self = shift;
    my $inherited = $self->SUPER::c_o(@_);
    $inherited =~ s/(\$\*\.c)/-o \$*\$(OBJ_EXT) $1/ig;
    return $inherited;
}

sub post_initialize {
    my $self = shift;

    my %o_files;
    my $obj_ext = $self->{'OBJ_EXT'};
    $o_files{$_}++ for @{ $self->{'O_FILES'} };
    $o_files{$self->catfile('.', $passwdqc_dir, $_ . $obj_ext)}++ for @objects;
    $self->{'O_FILES'} = [sort keys %o_files];

    $self->{clean}{FILES} .= ' ' . $self->catfile($passwdqc_dir, '*' . $obj_ext);
    return '';
}

sub top_targets {
    return '
all :: static

pure_all :: static

static :: libpasswdqc$(LIB_EXT)

dynamic ::

libpasswdqc$(LIB_EXT): $(O_FILES)
	$(AR) cr libpasswdqc$(LIB_EXT) $(O_FILES)
	$(RANLIB) libpasswdqc$(LIB_EXT)

';
}
