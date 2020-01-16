FROM cpantesters/base
# Load some modules that will always be required, to cut down on docker
# rebuild time
RUN cpanm \
    DBIx::Class \
    DBIx::Class::Candy \
    DBD::SQLite \
    DateTime \
    DateTime::Format::ISO8601 \
    DateTime::Format::MySQL \
    DateTime::Format::SQLite \
    Mojolicious \
    Log::Any \
    Path::Tiny \
    SQL::Translator
# Load last version's modules, to again cut down on rebuild time
COPY ./cpanfile /app/cpanfile
RUN cpanm --installdeps .
COPY ./ /app
RUN dzil install --install-command "cpanm -v ."
