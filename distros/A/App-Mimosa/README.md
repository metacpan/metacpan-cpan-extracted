# Mimosa - Miniature Model Organism Sequence Aligner

## What is Mimosa?

Mimosa is a application which provides an web interface to various sequence
alignment programs and sequence databases. Currently BLAST is supported, and
support for other alignment programs, such as BLASTP and BWA are planned.

## What does Mimosa do?

Mimosa allows evolutionary researchers to run sequence alignment programs on
nucleotides or proteins, and request sequences from various sequence databases,
all from a friendly web interface.

## Who is Mimosa for?

Mimosa is intended to be used by evolutionary biology researchers who do
sequence alignment against sets of nucleotide or protein data. These sets could
all be for different organisms, or all the same organism. Mimosa doesn't care.

If the data is public, Mimosa can be installed on a publicly-availabe website,
and allow sequence aligment by collaborators. If the data is pre-publication
and still actively changing, Mimosa can also be setup to only be accessed by
certain persons, either people on the local intranet, or those logging in with
a username and password.

## Why does Mimosa exist? Aren't there a lot of things that already do this?

Mimosa exists to solve the problem of making a standalone sequence alignment
web interface. All existing sequence alignment web interfaces are either tightly
coupled to legacy codebases, difficult to deploy, or just plain *unfriendly* to
end users.

Mimosa plans on being an easy-to-install standalone sequence aligner, which
can be integrated into an existing website via a REST interface.

## How do I get Mimosa?

You can install Mimosa from CPAN (where it is called
[http://p3rl.org/App::Mimosa](App::Mimosa)) .

If you use cpanminus (preferred) :

    cpanm App::Mimosa

If you use CPAN.pm:

    cpan App::Mimosa

### Installing non-Perl dependencies

Mimosa requires the 'fastacmd' binary and some image libraries. If you are on
a Debian-ish system, you can install these with apt-get:

    apt-get install libgd2-xpm-dev blast2

### Cloning via Git

If you have cpanminus:

    git clone git://github.com/GMOD/mimosa.git
    cd mimosa
    cpanm --installdeps . # install necessary Perl dependencies
    perl Build.PL
    ./Build

If you don't have cpanminus:

    git clone git://github.com/GMOD/mimosa.git
    cd mimosa
    perl Build.PL
    ./Build --installdeps # install necessary Perl dependencies
    ./Build

## How do I run the Mimosa test suite ?

After you have run the command

    perl Build.PL

you can either type:

    ./Build test

or use prove:

    prove -lrv t/

to run the Mimosa test suite.

## How do I deploy a Mimosa schema?

If you want to use Mimosa with SQLite, that is the default:

    perl script/mimosa_deploy.pl

If you want to deploy Mimosa to an already installed Chado schema, pass the --chado flag

    perl script/mimosa_deploy.pl --chado 1

This will also require you to give the proper DSN to your Chado instance in app_mimosa.conf.

If you want to use a different config file:

    perl script/mimosa_deploy.pl --chado 1 --conf my_other.conf

If you want to deploy an empty schema, because you plan to load custom sequence sets later on:

    perl script/mimosa_deploy.pl --chado 1 --empty 1 --conf some.conf

## How do I start Mimosa ?

To start Mimosa on the default port of 3000 :

    perl -Ilib script/mimosa_server.pl

If you want to run it on a specific port, then pass the -p param :

    perl -Ilib script/mimosa_server.pl -p 8080

## How do I hack on Mimosa ?

If you are developing a new feature in Mimosa, and you want start a new Mimosa
instance with the default database, there is a convenient script:

    ./scripts/debug_freshly_deployed_server.sh

That will remove mimosa.db, deploy a new mimosa_db, and start a new Mimosa
instance on port 8080 with DBIC_TRACE=1 set so every SQL statement run will be
shown.

Each new Mimosa feature should have a new test file in t/ of the form
t/NNN_feature_name.t .

## How do I configure Mimosa ?

The file called "app_mimosa.conf" contaings your configuration. In it, you can
tell Mimosa what your database backend is (SQLite, MySQL, PostgreSQL, Oracle, and
anything else that DBI supports) and set various paramters. Here is a partial list:

###  min_sequence_input_length 6

This sets the smallest sequence input length. If a sequence smaller than this length
is submitted, an exception is thrown and an error page is shown to the user.

### allow_anonymous 1

Whether to allow anonymous people (those that have not authenticated) to submit
jobs for reports.

### disable_qsub 1

Disable qsub job queueing support, which means jobs will be run on the local machine.

### tmp_dir /tmp/mimosa

The temporary directory that Mimosa can use.

### job_runtime_max		30

The default maximum time that a job can take, if it is happening during a
request cycle. Defaults to thirty seconds.

### sequence_data_dir examples/data

The directory where sequence data can be found.

### <Model::BCS>

This Config key is a container for Bio::Chado::Schema-related
configuration. It has:

### schema_class App::Mimosa::Schema::BCS

The schema class.

### traits undef

A trait, such as "Caching", which is good for production, but
not testing.

The <Model::BCS> container has a <connect_info> container,
which contains the "dsn" config key.

### dsn dbi:SQLite:./mimosa.db

The default is to deploy to a SQLite database in the current
directory, but if you want to use this with a
currently-existing Chado installation, you should but the
connection information in this config key.


## What is Mimosa written in?

Mimosa is written in Perl 5, HTML, CSS, and JavaScript.  On the server side, it
uses Moose, BioPerl and the Catalyst web framework.  On the client side, it uses
JQuery, JQuery UI.

## How can I help hack on Mimosa or otherwise get involved?

Please join our mailing list at <http://groups.google.com/group/gmod-mimosa> and
take a look at our Github issues for ideas about what we need help with:
<https://github.com/GMOD/mimosa/issues> . Please use Mimosa and tell us how we
can improve it and help it meet your sequence alignment needs.

You are also welcome to join the #gmod IRC channel on irc.freenode.net, where
many GMOD developers hang out and talk about various GMOD projects.
