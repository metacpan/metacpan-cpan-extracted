% my $p = shift;
#!/bin/sh
export MOJO_MODE=development
export MOJO_LOG_LEVEL=debug
exec `dirname $0`/<%= $p->{name} %>.pl prefork --listen 'http://*:<%= int(rand()*5000+3024) %>'
