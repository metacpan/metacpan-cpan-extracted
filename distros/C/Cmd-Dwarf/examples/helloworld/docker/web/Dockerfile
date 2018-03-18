FROM perl

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install postfix libsasl2-modules

# RUN postconf -e smtp_sasl_auth_enable=yes
# RUN postconf -e smtp_sasl_password_maps=static:USERNAME:PASSWORD
# RUN postconf -e smtp_sasl_security_options=noanonymous
# RUN postconf -e smtp_tls_security_level=encrypt
# RUN postconf -e header_size_limit=4096000
# RUN postconf -e relayhost=[161.202.148.160]:587 # smtp.sendgrid.net

RUN mkdir -p /data/www/example/app
COPY ./app/cpanfile /data/www/example/app/cpanfile
# COPY ./app/cpanfile.snapshot /data/www/example/app/cpanfile.snapshot
COPY ./app/Makefile /data/www/example/app/Makefile

WORKDIR /data/www/example/app

RUN make carton
COPY ./app /data/www/example/app
COPY ./htdocs /data/www/example/htdocs

EXPOSE 11022

CMD postfix start && env PERL5LIB=local/lib/perl5 ./script/start_server.sh -c