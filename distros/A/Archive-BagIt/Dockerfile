#17.10
FROM ubuntu:artful-20171116

RUN useradd -u 1104 -g users -m russell && echo "America/Toronto" >/etc/timezone && \
    apt-get update && apt-get install -y build-essential cpanminus dh-dist-zilla git && apt-get clean

# Needed by Archive-BagIt
RUN cpanm -n Devel::Cover Path::Class inc::Module::Install::DSL Module::Manifest Test::DistManifest  Text::Diff Data::Printer IO::AIO String::CRC32 Dist::Zilla::PluginBundle::Author::DOHERTY && rm -rf /root/.cpanm || (cat /root/.cpanm/work/*/build.log && exit 1)

