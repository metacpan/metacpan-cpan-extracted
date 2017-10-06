FROM postgres
COPY ./app/sql sql
RUN cat sql/999_init.sql > /docker-entrypoint-initdb.d/init.sql
RUN echo '' >> /docker-entrypoint-initdb.d/init.sql
RUN echo 'COMMIT;' >> /docker-entrypoint-initdb.d/init.sql