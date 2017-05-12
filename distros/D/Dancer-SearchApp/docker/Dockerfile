# My Dockerfile for Dancer-SearchApp
# DOCKER-VERSION 0.3.4
#
# Invoke from the distribution directory as
#     docker build -t dancer-searchapp -f docker/Dockerfile .
#
FROM        perl:latest
MAINTAINER  Max Maischein <corion@corion.net>

WORKDIR /root/Dancer-SearchApp

# For running Tika
RUN apt-get update && apt-get install -y \
  default-jre-headless \
   && rm -rf /var/lib/apt/lists/*

# Install Tika
RUN mkdir jar \
&& curl http://www.apache.org/dyn/closer.cgi/tika/tika-server-1.14.jar -o jar/tika-server-1.14.jar

# Install Elasticsearch
# + Language detection plugin

# Copy Makefile.PL, META.json early so we can install the prerequisites
# so we don't rebuild the container tower needlessly
ADD ["Makefile.PL","META.json", "./"]
ADD ["lib/Dancer/SearchApp.pm", "lib/Dancer/"]

# Install App prerequisites, using --notest to speed things up vastly,
# at the cost of not testing the resulting setup
RUN    cd /root/Dancer-SearchApp \
    && cpanm --notest --local-lib vendor/ --installdeps . \
    && rm -fr /root/.cpanm /tmp/*

# Copy the current build into the Docker image
COPY . /root/Dancer-SearchApp/

# We should document the mountpoints
# ... and install a cron job for scanning mounted directories

EXPOSE 8080

# ENV # the elasticsearch we will use to store the data
ENTRYPOINT ["/root/Dancer-SearchApp/docker/docker-entrypoint.sh"]
# use docker run -d -P -name config -v ../config-examples:/config ...
VOLUME /es-data
CMD ["--port", "8080"]