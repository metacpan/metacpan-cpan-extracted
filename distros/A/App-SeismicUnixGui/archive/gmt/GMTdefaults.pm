package App::SeismicUnixGui::gmt::GMTdefaults;
use Moose;

sub set {

    system("gmt gmtset PROJ_ELLIPSOID GRS-80");
    system("gmt gmtset PROJ_LENGTH_UNIT cm");
    system("gmt gmtset FORMAT_FLOAT_OUT 0");
}
1;
