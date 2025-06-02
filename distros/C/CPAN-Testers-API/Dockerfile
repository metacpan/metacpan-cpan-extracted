FROM cpantesters/schema
# Load some modules that will always be required, to cut down on docker
# rebuild time
RUN cpanm -v \
    Minion::Backend::mysql \
    Beam::Minion \
    Mojolicious \
    Mojolicious::Plugin::OAuth2 \
    Mojolicious::Plugin::Yancy
# Load last version's modules, to again cut down on rebuild time
COPY ./cpanfile /app/cpanfile
RUN cpanm --installdeps .

COPY ./ /app
RUN dzil authordeps --missing | cpanm -v --notest
RUN dzil listdeps --missing | cpanm -v --notest
RUN dzil install --install-command "cpanm -v ."

COPY ./etc/docker/api/my.cnf /root/.cpanstats.cnf
COPY ./etc/docker/api/api.development.conf /app
COPY ./etc/docker/legacy-metabase/metabase.conf /app
ENV MOJO_HOME=/app \
    BEAM_MINION='mysql+dsn+dbi:mysql:mysql_read_default_file=~/.cpanstats.cnf;mysql_read_default_group=application' \
    MOJO_PUBSUB_EXPERIMENTAL=1 \
    MOJO_MAX_MESSAGE_SIZE=33554432
CMD [ "cpantesters-api", "daemon", "-l", "http://*:4000" ]
EXPOSE 4000
