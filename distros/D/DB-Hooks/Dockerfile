# syntax=docker/dockerfile:1.3.1
ARG  PERL_VERSION=5.34.1-buster
FROM perl:$PERL_VERSION AS build


WORKDIR /dbhooks
COPY . .

RUN cpanm -L local --notest Module::Build
RUN perl -Ilocal/lib/perl5 Build.PL
RUN perl -Ilocal/lib/perl5 ./Build --cpan_client="cpanm -L local --notest" installdeps
RUN PERL_MB_OPT="--install_base /dbhooks/local" \
    PERL_MM_OPT="INSTALL_BASE=/dbhooks/local"   \
    perl -Ilocal/lib/perl5 ./Build install

RUN tar -cvf local.tar local

CMD ["/bin/cat", "local.tar"]


# docker exec -it debugger /bin/bash --login

# OLD. Do not use.
# docker run --name debugger --entrypoint /bin/bash -d db-hooks:latest -c 'while true; do sleep 30; done'
# docker cp debugger:/dbhooks/local.tar ./

# docker build -t db-hooks:latest .
# docker run --rm --name debugger db-hooks:latest > local.tar
# tar -xvf local.tar -C local --strip-components=1

# ./Build distdir; cp Dockerfile DB-Hooks-0.01_05/; cd DB-Hooks-0.01_05; docker build -t db-hooks:latest . ; docker run --rm --name debugger db-hooks:latest > local.tar ; docker cp ./local.tar proj-${BUILD_NUMBER}-api-1:/opt/proj/; docker exec -it proj-${BUILD_NUMBER}-api-1 tar -xvf local.tar -C local --strip-components=1
