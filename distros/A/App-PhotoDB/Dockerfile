FROM alpine:latest
LABEL maintainer="Jonathan Gazeley <me@jonathangazeley.com>"

# Install PhotoDB source
COPY . photodb
WORKDIR photodb

# Persistent storage for ini file
RUN mkdir -p /photodb
VOLUME /photodb

# Install Perl deps and build PhotoDB
RUN apk add build-base perl perl-dev perl-app-cpanminus perl-module-build mariadb-dev \
	&& perl Build.PL \
	&& ./Build installdeps --cpan-client "cpanm --no-wget -q -n" \
	&& ./Build install \
	&& rm -rf ~/photodb \
	&& rm -rf ~/.cpanm \
	&& apk del build-base perl-dev perl-app-cpanminus perl-module-build \
	&& rm -rf /var/cache/apk/*

# Run PhotoDB in interactive mode
ENTRYPOINT ["photodb"]
