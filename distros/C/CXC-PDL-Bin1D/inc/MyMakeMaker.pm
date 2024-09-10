package inc::MyMakeMaker;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {

    return +{ %{ super() }, };
};

before setup_installer => sub {
    my $self = shift;
    push @{ $self->WriteMakefile_arg_strs }, '%PDL_WriteMakefileArgs';

    push @{ $self->header_strs }, <<'EOT';
use PDL::Core::Dev;
use File::Spec::Functions qw( catfile );
our @dirh = qw( lib CXC PDL );
our @pprec = ( catfile( @dirh, 'Bin1D.pd' ), 'Bin1D', 'CXC::PDL::Bin1D' );


our @deps = map { catfile( @dirh, $_ ) } qw(
  bin_adaptive_snr.c
  bin_adaptive_snr.pl
  bin_on_index.c
  bin_on_index.pl
);

my %PDL_WriteMakefileArgs = (
    pdlpp_stdargs( \@pprec ),
    NO_MYMETA => 0,
    PM        => {
        catfile( @dirh, 'Bin1D', 'Utils.pm' ) =>
          catfile( '$(INST_LIB)', 'CXC', 'PDL', 'Bin1D', 'Utils.pm' ),
        'Bin1D.pm' => catfile( '$(INST_LIB)', 'CXC', 'PDL', 'Bin1D.pm'),
    },
);
EOT

    push @{ $self->footer_strs }, <<'EOT';
sub MY::postamble {
    my $postamble = pdlpp_postamble( \@pprec );
    # make Bin1D.pm depend upon all of its included files
    $postamble =~ s/^(Bin1D.pm:.*)/$1 @{[ join q[ ], @deps]}/m;
    return $postamble;
};
EOT

};

__PACKAGE__->meta->make_immutable;

1;
