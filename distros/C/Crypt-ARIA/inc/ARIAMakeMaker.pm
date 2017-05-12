package inc::ARIAMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {
    my $endian = join( " ", map { sprintf "%02x", $_ }
                            unpack( "C*", pack("L", 0x12345678) )
                     ) eq '12 34 56 78'
                 ? '-DARIA_BIG_ENDIAN' : '-DARIA_LITTLE_ENDIAN';
    my $LIBS = '';
    my $INC = '';
    my $DEFINE = "$endian";

    +{
        %{super()},
        LIBS => $LIBS,
        INC  => $INC,
        DEFINE => $DEFINE,
    };
};

__PACKAGE__->meta->make_immutable;
