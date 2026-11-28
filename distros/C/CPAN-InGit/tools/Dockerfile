# This docker image contains everything needed to develop CPAN::InGit
# Build with
#   docker build -t cpangit-dev .
# and then you can open a shell for development as:
#   docker run --rm -it -w $PWD -v $PWD:$PWD cpangit-dev

FROM debian:13

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gosu git ca-certificates cpanminus make linux-perf \
      libio-socket-ssl-perl libgit-raw-perl libmoo-perl \
      libmojolicious-perl libmodule-metadata-perl \
      liblog-any-perl liblog-any-adapter-tap-perl \
      libtest-pod-coverage-perl libtest-pod-perl libpod-coverage-trustpod-perl \
      libdist-zilla-perl libdist-zilla-plugin-git-perl \
      libdist-zilla-plugin-ourpkgversion-perl libdist-zilla-plugin-podweaver-perl \
      nodejs \
 && rm -rf /var/lib/apt/lists \
 && cpanm Log::Any::Adapter::MojoLog Dist::Zilla::Plugin::ShareDir \
      Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable \
 && rm -rf ~/.cpanm

ENTRYPOINT ["/usr/bin/env"]
CMD ["/bin/bash"]
