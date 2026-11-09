# DBD::Informix 2018.1031 with the Informix Client SDK 15

DBD::Informix 2018.1031 (the newest release) predates CSDK 15. Its
Makefile.PL stops at configure with

    Unexpected ESQL/C version number format IBM Informix CSDK Version 15.0, IBM Informix-ESQL Version 15.0.1.0

`dbd-informix-csdk15.patch` (apply with `patch -p1` in the unpacked tarball)
teaches it the new format:

- `lib/DBD/Informix/Configure.pm`: the ESQL/C version `15.0` becomes `1500`
  (major * 100 + minor), the old ones keep their numbers (4.50 -> 450).
- `Makefile.PL`: a version without the bitness letter (`15.0.1.0`) is 64-bit,
  as CSDK 15 ships 64-bit clients only on Unix; CSDK 15 takes the same
  ESQL/C path as CSDK 4.x.

Built this way against CSDK 15.0.1.0 and run against Informix 15.0.1.0.3
(maint/k8s/informix.yaml): the DBD::Informix suite passes 835 of 838 tests;
the three left are t/t09date.t 8-10, the date 1899-12-31.

## Build recipe

    # CSDK: IBM Informix Developer Edition downloads (IBMid), file
    # ibm.csdk.15.0.1.0.Linux.64.x86_64.tar; inner tar, then as a normal user:
    JAVA_TOOL_OPTIONS=-Djdk.xml.enableExtensionFunctions=true \
      ./installclientsdk -i silent -f csdk.properties \
      -DUSER_INSTALL_DIR=$HOME/opt/informix -DLICENSE_ACCEPTED=TRUE
    # csdk.properties: ENCRYPTION_LIBRARY=OPENSSL, features SDK,SDK-ESQL,
    # SDK-ESQL-ACM,SDK-LMI,SDK-ODBC,GLS,GLS-WEURAM,DBA-DBA

    eval "$(dbio-db env informix)"      # INFORMIXDIR, INFORMIXSERVER, sqlhosts, DSN
    export PATH=$INFORMIXDIR/bin:$PATH DBD_INFORMIX_DATABASE=dbio_test \
      DBD_INFORMIX_USERNAME=informix DBD_INFORMIX_PASSWORD=in4mix
    patch -p1 < dbd-informix-csdk15.patch
    perl Makefile.PL && make && make test && make install

Makefile.PL connects to the server while configuring, so the server must be
up first.

DBD-Informix declares only an RT queue, no repository.
