#!/usr/bin/env perl
=head1 NAME

 fedora_admin.pl - Fedora Commons Administrative client

=head1 SYNOPSIS

 ./fedora_admin.pl [options] [cmd]

 cmd:
    list
    doc ID [DSID]
    find query|terms STR
    update ID [active|inactive|deleted]
    purge ID
    list_datastreams ID
    list_methods ID
    list_relationships ID
    set_relationships ID FILE
    get_dissemination ID SDEFPID METHOD
    get_datastream ID DSID [DATE]
    set_datastream ID DSID url|file|xml FILE
    update_datastream ID DSID active|inactive|deleted|versionable|notversionable
    purge_datastream ID DSID
    validate ID
    history ID [DSID]
    xml ID
    export ID
    import ID|new file|xml FILE

 options:

  --database=<NAME>
  --exporter=<EXPORTER>
  --importer=<IMPORTER>
  --param foo=bar
  -y
  -d directory_containing_catmandu.yml

=head1 DESCRIPTION

B<fedora_admin.pl> is a B<Fedora Commons>-compatible client that execute HTTP Rest commands
to a Fedora server.

B<fedora_admin.pl> is intended to be conformat to Fedora Commons version up to Fedore 3.6.x.

=head1 CONFIGURATION

This script requires a catmandu.yml file containing the connection parameters to the Fedora
repository. Here is an example 'catmandu.yml' file:

 ---
 store:
  fedora:
     package: FedoraCommons
     options:
       baseurl: http://localhost:8080/fedora
       username: fedoraAdmin
       password: fedoraAdmin

This file needs to be provided in the working directory or can be specified in the directory
given by the -d option or specified in the environment by setting CATMANDU_CONF

  export CATMANDU_CONF=/etc/catamandu_conf_dir

=head1 OPTIONS

=over 4

=item --database I<name>

Name of a Fedora Commons server configured  in I<catmandu.yml>.

=item --exporter I<exporter>

Name of a Catmandu::Exporter or a configuration in I<catmandu.yml>.

=item --importer I<importer>

Name of a Catmandu::Importer or a configuration in I<catmandu.yml>.

=item --param FOO=BAR

Pass a parameter "FOO" with value "BAR" as optional parameter to a fedora_admin.pl command.

=item -y

Answer yes to all question.

=item -f directory_containing_catmandu.yml

Configuration directory

=back

=head1 COMMANDS

=over 4

=item list

Returns a list of all object identifiers (I<pid>-s) that are store in the Fedora server.

=item doc ID

Returns a short description of the object with identifier ID (audit trail, dublin core, object
properties, pid and version).

=item doc ID DSID

Return a short description about the latets version of datastream DSID in object ID.

=item find query|term QUERY

Execute a search query on the Fedora Commons server. One of 'query' or 'terms' is required.

=item update ID active|inactive|deleted

Updates the status of an object  with identifier ID.

=item purge ID

Purges the object with identifier ID.

=item list_datastreams ID

Returns a listing of all datastreams for an object with identifier ID.

=item list_methods ID

Returns a listing of all methods for an object with identifier ID.

=item list_relations ID

Returns a RDF/Turtle expression of all relationships defined for an object with identifier ID. The turtle includes all relationships for all the datastreams.

=item set_relationships ID FILE

Updates all relationships of an object with identifier ID with RDF/Turtle expressions from FILE.

   $ cat /tmp/rel.ttl
   <info:fedora/demo:20> <info:fedora/fedora-system:def/model#hasModel>
                         <info:fedora/fedora-system:ServiceDeployment-3.0> ;
                         <info:fedora/fedora-system:def/model#isContractorOf>
                         <info:fedora/demo:FO_TO_PDFDOC>, <info:fedora/demo:TEI_TO_PDFDOC> ;
    <info:fedora/fedora-system:def/model#isDeploymentOf> <info:fedora/demo:19> .

   $ fedora_admin.pl set_relationships demo:20 /tmp/rel.ttl

=item get_dissemination ID SDEFPID METHOD

Returns the binary stream when executing a dissemination on an object with identifier ID, sDef definition SDEFPID and method identifier METHOD.

  $ fedora_admin.pl --param width=100 demo:29 demo:27 resizeImage

=item get_datastream ID DSID

Returns the binary stream for an object with identifier ID and data stream identifier DSID.

=item set_datastream ID DSID url|file|xml FILE

Updates a data stream DSID for an object with identifiet ID. Use the url, file or xml upload mechanism to import a file FILE.

  $ fedora_admin.pl demo:99 PDF file /tmp/my/pdf

  $ fedora_admin.pl --param controlGroep=E \
                    demo:99 PDF url http://inst.org/my.pdf

=item update_datastream ID DSID active|inactive|deleted|versionable|notversionable

Update the datastream status of an object with identifier ID and data stream identifier DSID.

=item purge_datastream ID DSID

Purges the data stream DSID from an object with identifier ID.

=item validate ID

Validate the content of an object with identifier ID.

=item history ID [DSID]

Returns the version history of an object with identifier ID. Optionally provide a data stream identifier DSID.

=item xml ID

Return an XML dump of an object with identifier ID.

=item export ID

Exports the object with identifier ID to standard ouput.

  $ fedora_admin.pl --param context=archive demo:999

See L<https://wiki.duraspace.org/display/FEDORA36/REST+API#RESTAPI-export> for possible
parameters.

=item import ID|new file|xml FILE

Imports an object into the Fedora store. Force an own identifier using or let the Fedora store
mint a new one using 'new'.

  $ fedora_admin.pl --param format=info:fedora/fedora-system:ATOMZip-1.1 \
                      demo:999 file /tmp/demo_999.zip

  $ fedora_admin.pl --param format=info:fedora/fedora-system:ATOMZip-1.1 \
                    --param ownerId=admin \
                      new file /tmp/demo_999.zip

See L<https://wiki.duraspace.org/display/FEDORA36/REST+API#RESTAPI-ingest> for possible
parameters.

=back

=head1 SEE ALSO

 L<Catmandu>, L<Catmandu::FedoraCommons>

=head1 AUTHORS

 Patrick Hochstenbach, "<patrick.hochstenbach at ugent.be>"

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the terms
of either: the GNU General Public License as published by the Free Software Foundation;
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
=cut
$|++;

use Catmandu -all;
use Catmandu::Util;
use Getopt::Long;
use RDF::Trine;
use Data::Dumper;
use Cwd;

my $database   = 'fedora';
my $config     = $ENV{CATMANDU_CONF} // Cwd::getcwd();
my $exporter   = 'YAML';
my $importer   = 'YAML';
my $yes        = undef;
my %params     = ();

GetOptions("database=s" => \$database,
           "exporter=s" => \$exporter,
           "importer=s" => \$importer,
           "param=s"    => \%params,
           "y"          => \$yes,
           "d=s"        => \$config);

my $cmd = shift;

if (defined $config) {
   Catmandu->load($config);
}
    
unless (defined Catmandu->config->{store}->{$database}) {
   &usage("Need a catmandu.yml file or use the -f option");
}

if (undef) {}
elsif ($cmd eq 'list') {
    &cmd_list;
}
elsif ($cmd eq 'find') {
    my $type = shift;
    my $query = shift;
    &usage("find query|terms STR") unless defined $type && $type =~ /^(query|terms)$/;
    &cmd_find($type,$query);
}
elsif ($cmd eq 'doc') {
    my $id = shift;
    my $dsid = shift;
    &usage("doc ID") unless defined $id;
    &cmd_doc($id,$dsid);
}
elsif ($cmd eq 'update') {
    my $id = shift;
    my $action = shift;
    &usage("update ID") unless defined $id;
    &cmd_update($id,$action);
}
elsif ($cmd eq 'list_datastreams') {
    my $id = shift;
    &usage("list_datastreams ID") unless defined $id;
    &cmd_list_datastreams($id);
}
elsif ($cmd eq 'list_methods') {
    my $id = shift;
    &usage("list_methods ID") unless defined $id;
    &cmd_list_methods($id);
}
elsif ($cmd eq 'get_datastream') {
    my $id = shift;
    my $dsid = shift;
    &usage("get_datastream ID DSID") unless defined $id && defined $dsid;
    &cmd_get_datastream($id,$dsid);
}
elsif ($cmd eq 'get_dissemination') {
    my $id = shift;
    my $sdefpid = shift;
    my $method = shift;
    &usage("get_dissemination ID SDEFPID METHOD") unless defined $id && defined $sdefpid && defined $method;
    &cmd_get_dissemination($id,$sdefpid,$method);
}
elsif ($cmd eq 'set_datastream') {
    my $id = shift;
    my $dsid = shift;
    my $type = shift;
    my $file = shift;
    &usage("set_datastream ID DSID url|file|xml FILE")
        unless defined $id && defined $dsid && defined $file && $type =~ /^(url|file|xml)$/;
    &cmd_set_datastream($id,$dsid,$type,$file);
}
elsif ($cmd eq 'update_datastream') {
    my $id = shift;
    my $dsid = shift;
    my $action = shift;
    &usage("update_datastream ID DSID action")
        unless defined $id && defined $dsid && defined $action && $action =~ /^(active|inactive|deleted|versionable|notversionable)$/;
    &cmd_update_datastream($id,$dsid,$action);
}
elsif ($cmd eq 'purge_datastream') {
    my $id = shift;
    my $dsid = shift;
    &usage("purge_datastream ID DSID") unless defined $id && defined $dsid;
    &cmd_purge_datastream($id,$dsid);
}
elsif ($cmd eq 'purge') {
    my $id = shift;
    &usage("purge ID") unless defined $id;
    &cmd_purge($id);
}
elsif ($cmd eq 'history') {
    my $id = shift;
    my $dsid = shift;
    &usage("history ID") unless defined $id;
    &cmd_history($id,$dsid);
}
elsif ($cmd eq 'list_relationships') {
    my $id = shift;
    &usage("list_relationships ID") unless defined $id;
    &cmd_list_relationships($id);
}
elsif ($cmd eq 'set_relationships') {
    my $id = shift;
    my $file = shift;
    &usage("set_relationships ID FILE") unless defined $id && defined $file && -r $file;
    &cmd_set_relationships($id,$file);
}
elsif ($cmd eq 'xml') {
    my $id = shift;
    &usage("xml ID") unless defined $id;
    &cmd_xml($id);
}
elsif ($cmd eq 'validate') {
    my $id = shift;
    &usage("validate ID") unless defined $id;
    &cmd_validate($id);
}
elsif ($cmd eq 'export') {
    my $id = shift;
    &usage("export ID") unless defined $id;
    &cmd_export($id);
}
elsif ($cmd eq 'import') {
    my $id = shift;
    my $type = shift;
    my $file = shift;
    &usage("import ID|new file|xml") unless defined $id && defined $type && $type =~ /^(file|xml)/;
    &cmd_import($id,$type,$file);
}
else {
    &usage;
}

sub cmd_list {
    store($database)->bag->each(sub {
        my $obj = shift;
        printf "%s\n" ,  $obj->{_id};
    });
}

sub cmd_find {
    my $type = shift;
    my $query = shift;

    my $hits = store($database)->fedora->findObjects( $type => $query )->parse_content;
    my $token = $hits->{token};

    my $e    = exporter($exporter);
    my $stop = 0;
    do {
        for (@{ $hits->{results} }) {
            $e->add($_);
        }

        if (defined $token) {
            $hits = store($database)->fedora->resumeFindObjects(sessionToken => $token)->parse_content;
            $token = $hits->{token};
        }
        else {
            $stop = 1;
        }
    }
    while ( ! $stop );
}

sub cmd_doc {
    my $id  = shift;
    my $dsid = shift;

    my $obj;

    if ($dsid) {
        $obj = store($database)->fedora->getDatastream(pid => $id , dsID => $dsid)->parse_content->{profile};
    }
    else {
        $obj = store($database)->fedora->export(pid => $id)->parse_content;
    }

    die "no such object $id" unless $obj;

    my $e   = exporter($exporter);
    $e->add($obj);
    $e->commit;
}

sub cmd_update {
    my $id  = shift;
    my $action = shift // '';

    if ($action eq 'active') {
        $params{state} = 'A';
    }
    elsif ($action eq 'inactive') {
        $params{state} = 'I';
    }
    elsif ($action eq 'deleted') {
        $params{state} = 'D';
    }

    my $res = store($database)->fedora->modifyObject(pid => $id, %params);

    die "failed" unless ($res->is_ok);

    &cmd_doc($id);
}

sub cmd_list_datastreams {
    my $id = shift;

    my $obj = store($database)->fedora->listDatastreams(pid => $id)->parse_content;
    die "no such object $id" unless $obj;

    my $e   = exporter('CSV',header=>1);

    for (@{ $obj->{datastream}} ) {
        $e->add($_);
    }

    $e->commit;
}

sub cmd_list_methods {
    my $id = shift;

    my $obj = store($database)->fedora->listMethods(pid => $id)->parse_content;
    die "no such object $id" unless $obj;

    my $e   = exporter($exporter);
    $e->add($obj->{sDef});
    $e->commit;
}

sub cmd_get_dissemination {
    my $id = shift;
    my $sdefpid = shift;
    my $method = shift;

    binmode(STDOUT,':raw');
    store($database)->fedora->getDissemination(
            pid => $id , sdefPid => $sdefpid , method => $method, %params , callback => sub {
                my ($data, undef, undef) = @_;
                print $data;
            });
}

sub cmd_history {
    my $id = shift;
    my $dsid = shift;

    if (defined $dsid) {
        my $obj = store($database)->fedora->getDatastreamHistory(pid => $id, dsID => $dsid)->parse_content;
        die "no such object $id" unless $obj;

        my $e   = exporter('CSV',header=>1);

        for (@{ $obj->{profile}} ) {
            $e->add($_);
        }

        $e->commit;
    }
    else {
        my $obj = store($database)->fedora->getObjectHistory(pid => $id)->parse_content;
        die "no such object $id" unless $obj;

        my $e   = exporter('CSV',header=>1);

        for (@{ $obj->{objectChangeDate}} ) {
            $e->add({objectChangeDate => $_});
        }

        $e->commit;
    }
}

sub cmd_get_datastream {
    my $id = shift;
    my $dsid = shift;

    binmode(STDOUT,':raw');
    store($database)->fedora->getDatastreamDissemination(
            pid => $id , dsID => $dsid, callback => sub {
                my ($data, undef, undef) = @_;
                print $data;
            });
}

sub cmd_set_datastream {
    my $id = shift;
    my $dsid = shift;
    my $type = shift;
    my $file = shift;

    if ($type eq 'xml') {
        $file = Catmandu::Util::read_file($file);
    }

    my $exists = store($database)->fedora->getDatastream(
        pid => $id , dsID => $dsid

    )->is_ok;

    my $obj;

    if ($exists) {
        $obj = store($database)->fedora->modifyDatastream(
                    pid => $id , dsID => $dsid , $type => $file , %params
               )->parse_content;
    } else {
        $obj = store($database)->fedora->addDatastream(
                    pid => $id , dsID => $dsid , $type => $file , %params
               )->parse_content;
    }

    my $e   = exporter('YAML');
    $e->add($obj->{profile});
    $e->commit;
}

sub cmd_update_datastream {
    my $id = shift;
    my $dsid = shift;
    my $action = shift;

    my $res;
    if ($action eq 'active') {
        $res = store($database)->fedora->setDatastreamState(pid => $id , dsID => $dsid , dsState => 'A');
    }
    elsif ($action eq 'inactive') {
        $res = store($database)->fedora->setDatastreamState(pid => $id , dsID => $dsid , dsState => 'I');
    }
    elsif ($action eq 'deleted') {
        $res = store($database)->fedora->setDatastreamState(pid => $id , dsID => $dsid , dsState => 'D');
    }
    elsif ($action eq 'versionable') {
        $res = store($database)->fedora->setDatastreamVersionable(pid => $id , dsID => $dsid , versionable=> 'true');
    }
    elsif ($action eq 'notversionable') {
        $res = store($database)->fedora->setDatastreamVersionable(pid => $id , dsID => $dsid , versionable=> 'false');
    }

    die "failed" unless $res->is_ok;
}

sub cmd_purge_datastream {
    my $id = shift;
    my $dsid = shift;

    return unless &confirm;

    my $res = store($database)->fedora->purgeDatastream(pid => $id , dsID => $dsid , %params);

    die "failed" unless $res->is_ok;
}

sub cmd_purge {
    my $id = shift;

    return unless &confirm;

    my $res = store($database)->fedora->purgeObject(pid => $id , %params);

    die "failed" unless $res->is_ok;
}

sub cmd_list_relationships {
    my $id = shift;

    my $rdf_ext = store($database)->fedora->getDatastreamDissemination(pid => $id, dsID => 'RELS-EXT');
    my $rdf_int = store($database)->fedora->getDatastreamDissemination(pid => $id, dsID => 'RELS-INT');

    die "no relations $id" unless ($rdf_ext->is_ok || $rdf_int->is_ok);

    my $model = undef;

    $model = &turtle2model($rdf_ext->raw,$model,'rdfxml') if $rdf_ext->is_ok;
    $model = &turtle2model($rdf_int->raw,$model,'rdfxml') if $rdf_int->is_ok;

    my $serializer =  RDF::Trine::Serializer::Turtle->new();
    print $serializer->serialize_model_to_string($model);
}

sub cmd_set_relationships {
    my $id = shift;
    my $file = shift;

    my $obj = store($database)->get($id);
    die "no such object $id" unless $obj;

    my $turtle = Catmandu::Util::read_file($file);
    my $model  = &turtle2model($turtle);

    &cmd_reset_relationships($id);

    my $iter   = $model->get_statements();

    while(my $st = $iter->next) {
        my $subject    = $st->subject->value;
        my $predicate  = $st->predicate->value;
        my $object     = $st->object->value;

        my $isLiteral  = $st->object->is_literal;
        my $dataType   = $isLiteral ? $st->object->literal_datatype : undef;

        store($database)->fedora->addRelationship(
            pid => $id,
            relation => [
                $subject, $predicate, $object
            ],
            dataType => $dataType
        );
    }

    &cmd_list_relationships($id);
}

sub cmd_xml {
    my $id = shift;

    my $res = store($database)->fedora->getObjectXML(pid => $id);

    print $res->raw if $res->is_ok;
}

sub cmd_validate {
    my $id = shift;

    my $res = store($database)->fedora->validate(pid => $id);

    die "failed: " . $res->error unless $res->is_ok;

    my $e = exporter($exporter);
    $e->add($res->parse_content);
    $e->commit;
}

sub cmd_export {
    my $id = shift;

    my $res = store($database)->fedora->export(pid => $id , %params);

    die "no such object $id" unless $res->is_ok;

    print $res->raw;
}

sub cmd_import {
    my $id = shift;
    my $type = shift;
    my $file = shift;

    if ($type eq 'xml') {
        $file = Catmandu::Util::read_file($file);
    }

    my $res = store($database)->fedora->ingest(pid => $id , $type => $file , %params);

    die "failed: " . $res->error unless $res->is_ok;

    print $res->parse_content->{pid} , "\n";
}

sub cmd_reset_relationships  {
    my $id = shift;

    store($database)->fedora->purgeDatastream(pid => $id , dsID => 'RELS-EXT');
    store($database)->fedora->purgeDatastream(pid => $id , dsID => 'RELS-INT');
}

sub turtle2model {
    my $turtle = shift;
    my $model = shift // RDF::Trine::Model->temporary_model;
    my $type = shift // 'turtle';
    my $parser = RDF::Trine::Parser->new($type);
    $parser->parse_into_model(undef, $turtle, $model);
    return $model;
}


sub confirm {
    return 1 if $yes;

    my $msg = shift // 'Are you sure?';
    print "$msg [y/N] ";
    my $ans = <STDIN>; chop($ans);
    $ans eq 'y';
}

sub usage {
    my $msg = shift;
    print STDERR <<EOF;
usage: $0 [options] $msg

cmds:
    list
    doc ID [DSID]
    find query|terms STR
    update ID [active|inactive|deleted]
    purge ID
    list_datastreams ID
    list_methods ID
    list_relationships ID
    set_relationships ID FILE
    get_dissemination ID SDEFPID METHOD
    get_datastream ID DSID
    set_datastream ID DSID url|file|xml FILE
    update_datastream ID DSID active|inactive|deleted|versionable|notversionable
    purge_datastream ID DSID
    validate ID
    history ID [DSID]
    xml ID
    export ID
    import ID|new file|xml FILE

options:

  --database=<NAME>
  --exporter=<EXPORTER>
  --importer=<IMPORTER>
  --param foo=bar
  -y
  -d directory_containing_catmandu.yml

config file:

Requires a YAML configuration file 'catmandu.yml' in working directory or use -d option.
Syntax like:

 ---
 store:
   fedora:
       package: FedoraCommons
       options:
         baseurl: http://localhost:8080/fedora
         username: fedoraAdmin
         password: fedoraAdmin

EOF
    exit 1;
}
