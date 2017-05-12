package App::Dockerfile::Template
$App::Dockerfile::Template::VERSION = '2.00';
=head1 NAME

App::Dockerfile::Template - Make Dockerfile as Template Toolkit template file and use environment variables as data points

=head1 INSTALLATION

=head2 Install with cpan

 cpan -i App::Dockerfile::Template

=head2 Install with cpanm

 cpanm App::Dockerfile::Template

=head2 Install with carton

 echo 'requires "App::Dockerfile::Template";' >> cpanfile
 carton install

=head1 USAGE

=head2 Dockerfile example

Create a Dockerfile with varialbles

 FROM [% OS_NAME || "ubuntu" %]:[% OS_VERSION || "latest" %]

 ENV PLACK_ENV [% PLACK_ENV || "development" %]
 ENV DB_HOST   [% DB_HOST %]
 ENV DB_USER   [% DB_USER %]
 ENV DB_PASS   [% DB_PASS %]
 ENV DB_NAME   [% DB_NAME %]

=head2 BUILD

 export PLACK_ENV=prod
 export DB_HOST=foo.com
 export DB_USER=bar
 export DB_PASS=s0m3th1ng
 export DB_NAME=runtime

Same arguments with docker build command

 docker-build -t foo/bar .

=head2 What is behind the sense

 1. Use Environment Variables with Template Toolkit to output a buildable Dockerfile
 2. Run docker build the new Dockerfile with the command arguments

=head1 DATA POINTS

By default all the data points are from the environment variables.

If you need to pass in dynamic data points, there are some examples as below:

=head2 Add a function to the template to get a list of files

In the Dockerfile template

 [% FOREACH file IN list %]
 ADD [% file %] /home/here/[% file %]
 [% END %]

From the command line

 docker-build =Slist 'split /\n/, qx{find . -type f}' --tag some/image .

=head2 Load a File::Slurp to list the directory

In the Dockerfile template

 [% FOREACH file IN list %]
 ADD [% file %] /home/here/[% file %]
 [% END %]

From the command line

 docker-build =MFile::Slurp =Slist 'read_dir(".")' --tag some/image .

=head2 Add an extra key value

In the Dockerfile template

 FROM base/image

 AUTHOR [% author %]

 ...

From the command line

 docker-build =KVauthor "$USER <$EMAIL>" --tag some/image .

=head1 GIT REPO

L<https://bitbucket.org/mvu8912/app-dockerfile-template>

=cut

1;
