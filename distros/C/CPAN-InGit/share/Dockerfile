# Build this docker image with
#   docker build -t cpangit .
# and then you can run the tool as:
#   docker run --rm -i -w $PWD -v $PWD:$PWD cpangit create ...
#   docker run --rm -i -w $PWD -v $PWD:$PWD cpangit add ...
#   docker run --rm -w $PWD -v $PWD:$PWD cpangit server ...

FROM debian:13

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gosu git ca-certificates cpanminus make \
      libio-socket-ssl-perl libgit-raw-perl libmoo-perl \
      libmojolicious-perl libmodule-metadata-perl \
      liblog-any-perl liblog-any-adapter-tap-perl \
 && rm -rf /var/lib/apt/lists \
 && cpanm Log::Any::Adapter::MojoLog CPAN::InGit \
 && rm -rf ~/.cpanm \
 && ln -s cpangit-create /usr/local/bin/create \
 && ln -s cpangit-add /usr/local/bin/add \
 && ln -s cpangit-server /usr/local/bin/server \
 && useradd -u 1000 user
