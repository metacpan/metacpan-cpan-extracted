package MY;

our @INCLUDE_ENV = ();

sub test {
    my ( $self, %attrs ) = @_;

    my $env = join(
        " " => map { sprintf( "%s=\"%s\"" => $_, $ENV{$_} ) }
						grep { exists $ENV{$_} } @INCLUDE_ENV
    );
    my $section = $self->SUPER::test(%attrs);

    $section =~ s|(PERL_DL_NONLAZY=1)|$1 $env|g if ($env);

    return $section;
}

1;
