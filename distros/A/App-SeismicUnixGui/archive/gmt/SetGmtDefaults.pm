package App::SeismicUnixGui::gmt::SetGmtDefaults;

sub system {

    system("gmtset ELLIPSOID GRS-80");
    system("gmtset MEASURE_UNIT cm");
    system("gmtset D_FORMAT 0");
    system("gmtset DEGREE_FORMAT 3");
    system("gmtset PSIMAGE_FORMAT ascii");
}
1;
