=head1 NAME

Catmandu::FedoraCommons - Low level Catmandu interface to the Fedora Commons REST API

=head1 SYNOPSIS

  # Use the command line tools 
  $ fedora_admin.pl

  # Or the low-level API-s
  use Catmandu::FedoraCommons;
  
  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');
  
  my $result = $fedora->findObjects(terms=>'*');
  
  die $result->error unless $result->is_ok;
  
  my $hits = $result->parse_content();
  
  for my $hit (@{ $hits->{results} }) {
       printf "%s\n" , $hit->{pid};
  }
  
  # Or using the higher level Catmandu::Store codes you can do things like
  
  use Catmandu::Store::FedoraCommons;

  my $store = Catmandu::Store::FedoraCommons->new(
           baseurl  => 'http://localhost:8080/fedora',
           username => 'fedoraAdmin',
           password => 'fedoraAdmin',
           model    => 'Catmandu::Store::FedoraCommons::DC' # default
   );
   
  $store->bag->each(sub {
        my $model = shift;
        printf "title: %s\n" , join("" , @{ $model->{title} });
        printf "creator: %s\n" , join("" , @{ $model->{creator} });
        
        my $pid = $model->{_id};
        my $ds  = $store->fedora->listDatastreams(pid => $pid)->parse_content;
  });
   
  my $obj = $store->bag->add({ 
        title => ['The Master and Margarita'] , 
        creator => ['Bulgakov, Mikhail'] }
  );
  
  $store->fedora->addDatastream(pid => $obj->{_id} , url => "http://myurl/rabbit.jpg");
  
  # Add your own perl version of a descriptive metadata model by implementing your own
  # model that can do a serialize and deserialize.
  
=head1 DESCRIPTION

Catmandu::FedoraCommons is an Perl API to the Fedora Commons REST API (http://www.fedora.info/). 
Supported versions are Fedora Commons 3.6 or better. 

=head1 ACCESS METHODS

=cut
package Catmandu::FedoraCommons;

use Catmandu::FedoraCommons::Response;

our $VERSION = '0.274';
use URI::Escape;
use HTTP::Request::Common qw(GET POST DELETE PUT HEAD);
use LWP::UserAgent;
use MIME::Base64;
use strict;
use Carp;
use Data::Validate::URI qw(is_uri);

=head2 new($base_url,$username,$password)

Create a new Catmandu::FedoraCommons connecting to the baseurl of the Fedora Commons installation.

=cut
sub new {
    my ($class,$baseurl,$username,$password) = @_;
    
    Carp::croak "baseurl missing" unless defined $baseurl;
    
    my $ua = LWP::UserAgent->new(
                   agent   => 'Catmandu-FedoraCommons/' . $VERSION,
                   timeout => 180,
               );
    
    $baseurl =~ m/(\w+):\/\/([^\/:]+)(:(\d+))?(\S+)/;
              
    bless { baseurl  => $baseurl,
            scheme   => $1,
            host     => $2,
            port     => $4 || 8080,
            path     => $5,
            username => $username,
            password => $password,
            ua       => $ua} , $class;
}

sub _GET {
    my ($self,$path,$data,$callback,$headers) = @_;
    $headers = {} unless $headers;
        
    my @parts;
    for my $part (@$data) {
        my ($key) = keys %$part;
        my $name  = uri_escape($key) || "";
        my $value = uri_escape($part->{$key}) || "";
        push @parts , "$name=$value";
    }
    
    my $query = join("&",@parts);
   
    my $req = GET $self->{baseurl} . $path . '?' . $query ,  %$headers;
    
    $req->authorization_basic($self->{username}, $self->{password});
    
    defined $callback ?
        return $self->{ua}->request($req, $callback, 4096) :
        return $self->{ua}->request($req);
}

sub _POST {
    my ($self,$path,$data,$callback) = @_;
        
    my $content = undef;
    my @parts;
    
    for my $part (@$data) {
        my ($key) = keys %$part;
        
        if (ref $part->{$key} eq 'ARRAY') {
            $content = [ $key => $part->{$key} ];
        }
        else {
            my $name  = uri_escape($key) || "";
            my $value = uri_escape($part->{$key}) || "";
            push @parts , "$name=$value";
        }
    }
    
    my $query = join("&",@parts);
   
    my $req;
    
    if (defined $content) {
        $req = POST $self->{baseurl} . $path . '?' . $query, Content_Type => 'form-data' , Content => $content;
    }
    else {
        # Need a Content_Type text/xml because of a Fedora 'ingest' feature that requires it...
        $req = POST $self->{baseurl} . $path . '?' . $query, Content_Type => 'text/xml';
    }
    
    $req->authorization_basic($self->{username}, $self->{password});

    defined $callback ?
        return $self->{ua}->request($req, $callback, 4096) :
        return $self->{ua}->request($req);
}

sub _PUT {
    my ($self,$path,$data,$callback) = @_;

    my $content = undef;
    my @parts;
    
    for my $part (@$data) {
        my ($key) = keys %$part;
        
        if (ref $part->{$key} eq 'ARRAY') {
            $content = $part->{$key};
        }
        else {
            push @parts , uri_escape($key) . "=" . uri_escape($part->{$key});
        }
    }
    
    my $query = join("&",@parts);
   
    my $req;
    
    if (defined $content) {
        if (@$content == 1) {
            my $file = $content->[0];
            $req = PUT $self->{baseurl} . $path . '?' . $query;
            open(my $fh,'<',$file) or Carp::croak "can't open $file : $!";
            local($/) = undef;
            $req->content(scalar(<$fh>));
            $req->header( 'Content-Length' => -s $file );
            close($fh);
        }
        else {
            my $xml = $content->[-1];
            $req = PUT $self->{baseurl} . $path . '?' . $query;
            $req->content($xml);
            $req->header( 'Content-Length' => length($xml) );
        }
    }
    else {
        # Need a Content_Type text/xml because of a Fedora 'ingest' feature that requires it...
        $req = PUT $self->{baseurl} . $path . '?' . $query, Content_Type => 'text/xml';
    }

    $req->authorization_basic($self->{username}, $self->{password});
    
    defined $callback ?
        return $self->{ua}->request($req, $callback, 4096) :
        return $self->{ua}->request($req);
}

sub _DELETE {
    my ($self,$path,$data,$callback) = @_;
    
    my @parts;
    for my $part (@$data) {
        my ($key) = keys %$part;
        my $name  = uri_escape($key) || "";
        my $value = uri_escape($part->{$key}) || "";
        push @parts , "$name=$value";
    }
    
    my $query = join("&",@parts);
   
    my $req = DELETE sprintf("%s%s%s", $self->{baseurl} , $path , $query ? '?' . $query : "");
    
    $req->authorization_basic($self->{username}, $self->{password});

    defined $callback ?
        return $self->{ua}->request($req, $callback, 4096) :
        return $self->{ua}->request($req);
}

=head2 findObjects(query => $query, maxResults => $maxResults)

=head2 findObjects(terms => $terms , maxResults => $maxResults)

Execute a search query on the Fedora Commons server. One of 'query' or 'terms' is required. Query 
contains a phrase optionally including '*' and '?' wildcards. Terms contain one or more conditions separated by space.
A condition is a field followed by an operator, followed by a value. The = operator will match if the field's 
entire value matches the value given. The ~ operator will match on phrases within fields, and accepts 
the ? and * wildcards. The <, >, <=, and >= operators can be used with numeric values, such as dates.

Examples:

  query => "*o*"
  
  query => "?edora"
  
  terms => "pid~demo:* description~fedora"

  terms => "cDate>=1976-03-04 creator~*n*"

  terms => "mDate>2002-10-2 mDate<2002-10-2T12:00:00"
  
Optionally a maxResults parameter may be specified limiting the number of search results (default is 20). This method
returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::findObjects> model.

=cut
sub findObjects {
    my $self = shift;
    my %args = (query => "", terms => "", maxResults => 20, @_);      
    
    Carp::croak "terms or query required" unless defined $args{terms} || defined $args{query};
               
    my %defaults = (pid => 'true' , label => 'true' , state => 'true' , ownerId => 'true' ,	
                    cDate => 'true' , mDate => 'true' , dcmDate => 'true' , title => 'true' , 	
                    creator => 'true' , subject => 'true' , description => 'true' , publisher => 'true' ,	
                    contributor => 'true' , date => 'true' , type => 'true' , format => 'true' ,	
                    identifier => 'true' , source => 'true' , language => 'true' , relation => 'true' , 	
                    coverage => 'true' , rights => 'true' , resultFormat => 'xml');
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory( 
            'findObjects' , $self->_GET('/objects',$form_data) 
           );
}

=head2 resumeFindObjects(sessionToken => $token)

This method returns the next batch of search results. This method returns a L<Catmandu::FedoraCommons::Response> object
with a L<Catmandu::FedoraCommons::Model::findObjects> model.

Example:

    my $result = $fedora->findObjects(terms=>'*');

    die $result->error unless $result->is_ok;

    my $hits = $result->parse_content();
    
    for my $hit (@{ $hits->{results} }) {
           printf "%s\n" , $hit->{pid};
    }
    
    my $result = $fedora->resumeFindObjects(sessionToken => $hits->{token});
    
    my $hits = $result->parse_content();
    
    ...
    
=cut
sub resumeFindObjects {
    my $self = shift;
    my %args = (sessionToken => undef , query => "", terms => "", maxResults => 20, @_);      
    
    Carp::croak "sessionToken required" unless defined $args{sessionToken};
    Carp::croak "terms or query required" unless defined $args{terms} || defined $args{query};
               
    my %defaults = (pid => 'true' , label => 'true' , state => 'true' , ownerId => 'true' ,	
                    cDate => 'true' , mDate => 'true' , dcmDate => 'true' , title => 'true' , 	
                    creator => 'true' , subject => 'true' , description => 'true' , publisher => 'true' ,	
                    contributor => 'true' , date => 'true' , type => 'true' , format => 'true' ,	
                    identifier => 'true' , source => 'true' , language => 'true' , relation => 'true' , 	
                    coverage => 'true' , rights => 'true' , resultFormat => 'xml');
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'resumeFindObjects' , $self->_GET('/objects',$form_data)
            );
}

=head2 getDatastreamDissemination(pid => $pid, dsID=> $dsID, asOfDateTime => $date, callback => \&callback)

This method returns a datastream from the Fedora Commons repository. Required parameters are
the identifier of the object $pid and the identifier of the datastream $dsID. Optionally a datestamp $asOfDateTime
can be provided. This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::getDatastreamDissemination>
model.

To stream the contents of the datastream a callback function can be provided.

Example:
    
    $fedora->getDatastreamDissemination(pid => 'demo:5', dsID => 'VERYHIGHRES', callback => \&process);
    
    sub process {
        my ($data, $response, $protocol) = @_;
        print $data;
    }
    
=cut
sub getDatastreamDissemination {
    my $self = shift;
    my %args = (pid => undef , dsID => undef , asOfDateTime => undef, download => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    
    my $pid  = $args{pid};
    my $dsId = $args{dsID};
    my $callback = $args{callback};
    
    delete $args{pid};
    delete $args{dsID};
    delete $args{callback};
    
    my $form_data = [];
                   
    for my $name (keys %args) {
        push @$form_data , { $name => $args{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'getDatastreamDissemination' , $self->_GET('/objects/' . $pid . '/datastreams/' . $dsId . '/content' , $form_data, $callback)
           );
}

=head2 getDissemination(pid => $pid , sdefPid => $sdefPid , method => $method , %method_parameters , callback => \&callback)

This method execute a dissemination method on the Fedora Commons server. Required parametes are the object $pid, the service definition $sdefPid and the name of the method $method. Optionally
further method parameters can be provided and a callback function to stream the results (see getDatastreamDissemination).
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::getDatastreamDissemination> model.

  Example:
  
  $fedora->getDissemination(pid => 'demo:29', sdefPid => 'demo:27' , method => 'resizeImage' , width => 100, callback => \&process);
  
=cut
sub getDissemination {
    my $self = shift;
    my %args = (pid => undef , sdefPid => undef , method => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{sdefPid};
    Carp::croak "need method" unless $args{method};
    
    my $pid      = $args{pid};
    my $sdefPid  = $args{sdefPid};
    my $method   = $args{method};
    my $callback = $args{callback};
    
    delete $args{pid};
    delete $args{sdefPid};
    delete $args{method};
    delete $args{callback};
    
    my $form_data = [];
                   
    for my $name (keys %args) {
        push @$form_data , { $name => $args{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory( 
            'getDissemination' , $self->_GET('/objects/' . $pid . '/methods/' . $sdefPid . '/' . $method , $form_data, $callback)
           );
}

=head2 getObjectHistory(pid => $pid)

This method returns the version history of an object. Required is the object $pid.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::getObjectHistory> model.

 Example:
 
 my $obj = $fedora->getObjectHistory(pid => 'demo:29')->parse_content;
 
 for @{$obj->{objectChangeDate}} {}
    print "$_\n;
 }
 
=cut
sub getObjectHistory {
    my $self = shift;
    my %args = (pid => undef , @_);

    Carp::croak "need pid" unless $args{pid};
    
    my $pid     = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ( format => 'xml' );
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
     
    return Catmandu::FedoraCommons::Response->factory( 
            'getObjectHistory' , $self->_GET('/objects/' . $pid . '/versions', $form_data)
            );
}

=head2 getObjectProfile(pid => $pid, asOfDateTime => $date)

This method returns a detailed description of an object. Required is the object $pid. Optionally a
version date asOfDateTime can be provided. This method returns a L<Catmandu::FedoraCommons::Response> object
with a L<Catmandu::FedoraCommons::Model::getObjectProfile> model.

  Example:

   my $obj = $fedora->getObjectProfile(pid => 'demo:29')->parse_content;

   printf "Label: %s\n" , $obj->{objLabel};
  
=cut
sub getObjectProfile {
    my $self = shift;
    my %args = (pid => undef , asOfDateTime => undef , @_);

    Carp::croak "need pid" unless $args{pid};
    
    my $pid     = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ( format => 'xml' );
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
     
    return Catmandu::FedoraCommons::Response->factory(
            'getObjectProfile' , $self->_GET('/objects/' . $pid , $form_data)
           );
}

=head2 listDatastreams(pid => $pid, asOfDateTime => $date)

This method returns a list of datastreams provided in the object. Required is the object $pid.
Optionally a version date asOfDateTime can be provided. This method returns a L<Catmandu::FedoraCommons::Response> object
with a L<Catmandu::FedoraCommons::Model::listDatastreams> model.

  Example:
  
  my $obj = $fedora->listDatastreams(pid => 'demo:29')->parse_content;
  
  for (@{ $obj->{datastream}} ) {
     printf "Label: %s\n" , $_->{label};
  }
  
=cut
sub listDatastreams {
    my $self = shift;
    my %args = (pid => undef , asOfDateTime => undef , @_);

    Carp::croak "need pid" unless $args{pid};
    
    my $pid     = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ( format => 'xml' );
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
     
    return Catmandu::FedoraCommons::Response->factory(
            'listDatastreams' , $self->_GET('/objects/' . $pid . '/datastreams', $form_data)
           );    
}

=head2 listMethods(pid => $pid , sdefPid => $sdefPid , asOfDateTime => $date)

This method return a list of methods that can be executed on an object. Required is the object $pid
and the object $sdefPid. Optionally a version date asOfDateTime can be provided.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::listMethods>
model.

  Example:
  
   my $obj = $fedora->listMethods(pid => 'demo:29')->parse_content;
   
   for ( @{ $obj->{sDef} }) {
        printf "[%s]\n" , $_->{$pid};
        
        for my $m ( @{ $_->{method} } ) {
            printf "\t%s\n" , $m->{name};
        }
   }

=cut
sub listMethods {
    my $self = shift;
    my %args = (pid => undef , sdefPid => undef, asOfDateTime => undef , @_);

    Carp::croak "need pid" unless $args{pid};
    
    my $pid     = $args{pid};
    my $sdefPid = $args{sdefPid};
     
    delete $args{pid};
    delete $args{sdefPid};
    
    my %defaults = ( format => 'xml' );
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
     
    return Catmandu::FedoraCommons::Response->factory(
            'listMethods' , $self->_GET('/objects/' . $pid . '/methods' . ( defined $sdefPid ? "/$sdefPid" : "" ), $form_data)
           );
}
=head2 describeRepository

This method returns information about the fedora repository. No arguments required.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::describeRepository> model.

    Example:

    my $desc = $fedora->describeRepository()->parse_content();

=cut

sub describeRepository {
    my $self = $_[0];
    my $form_data = [ { xml => "true" } ];

    return Catmandu::FedoraCommons::Response->factory(
        'describeRepository' , $self->_GET('/describe', $form_data)
    );
}
*describe = \&describeRepository;

=head1 MODIFY METHODS

=head2 addDatastream(pid => $pid , dsID => $dsID, url => $remote_location, %args)

=head2 addDatastream(pid => $pid , dsID => $dsID, file => $filename , %args)

=head2 addDatastream(pid => $pid , dsID => $dsID, xml => $xml , %args)

This method adds a data stream to the object. Required parameters are the object $pid, a new datastream $dsID and
a remote $url, a local $file or an $xml string which contains the content. Optionally any of these datastream modifiers
may be provided: controlGroup, altIDs, dsLabel, versionable, dsState, formatURI, checksumType, checksum,
mimeType, logMessage. See: https://wiki.duraspace.org/display/FEDORA36/REST+API for more information.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::datastreamProfile>
model.

 Example:
 
   my $obj = $fedora->addDatastream(pid => 'demo:29', dsID => 'TEST' , file => 'README', mimeType => 'text/plain')->parse_content;
   
   print "Uploaded at: %s\n" , $obj->{dateTime};
   
=cut
sub addDatastream {
    my $self = shift;
    my %args = (pid => undef , dsID => undef, url => undef , file => undef , xml => undef , @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    Carp::croak "need url or file (filename)" unless defined $args{url} || defined $args{file} || defined $args{xml};
    
    my $pid  = $args{pid};
    my $dsID = $args{dsID};
    my $url  = $args{url};
    my $file = $args{file};
    my $xml  = $args{xml};
     
    delete $args{pid};
    delete $args{dsID};
    delete $args{url};
    delete $args{file};
    delete $args{xml};
    
    my %defaults = ( versionable => 'false');
    
    if (defined $file) {
        $defaults{file} = ["$file"];
        $defaults{controlGroup} = 'M';
    }
    elsif (defined $xml) {
        $defaults{file} = [ undef , 'upload.xml' , Content => $xml ];
        $defaults{controlGroup} = 'X';
        $defaults{mimeType} = 'text/xml';
    }
    elsif (defined $url) {
        $defaults{dsLocation} = $url;
        $defaults{controlGroup} = 'M';
    }
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'addDatastream' , $self->_POST('/objects/' . $pid . '/datastreams/' . $dsID, $form_data)
           );
}

=head2 addRelationship(pid => $pid, relation => [ $subject, $predicate, $object] [, dataType => $dataType])

This methods adds a triple to the 'RELS-EXT' data stream of the object. Requires parameters are the object
$pid and a relation as a triple ARRAY reference. Optionally the $datatype of the literal may be provided.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::addRelationship>
model.

  Example:
  
  $fedora->addRelationship(pid => 'demo:29' , relation => [ 'info:fedora/demo:29' , 'http://my.org/name' , 'Peter']);

=cut
sub addRelationship {
    my $self = shift;
    my %args = (pid => undef , relation => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need relation" unless defined $args{relation} && ref $args{relation} eq 'ARRAY';
    
    my $pid       = $args{pid};
    my $subject   = $args{relation}->[0];
    my $predicate = $args{relation}->[1];
    my $object    = $args{relation}->[2];
    my $dataType  = $args{dataType};
    my $isLiteral = is_uri($object) ? "false" : "true";
    
    my $form_data = [
        { subject   => $subject },
        { predicate => $predicate },
        { object    => $object },
        { dataType  => $dataType },
        { isLiteral => $isLiteral },
    ];

    return Catmandu::FedoraCommons::Response->factory(
               'addRelationship' , $self->_POST('/objects/' . $pid . '/relationships/new', $form_data)
           );
}

=head2 export(pid => $pid [, format => $format , context => $context , encoding => $encoding])

This method exports the data model of the object in FOXML,METS or ATOM. Required is $pid of the object.
Optionally a $context may be provided and the $format of the export.
See: https://wiki.duraspace.org/display/FEDORA36/REST+API for more information.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::export>
model.

 Example:
 
   my $res = $fedora->export(pid => 'demo:29');
   
   print $res->raw;
   
   print "%s\n" , $res->parse_content->{objectProperties}->{label};

=cut
sub export {
    my $self = shift;
    my %args = (pid => undef , format => undef , context => undef , encoding => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    
    my $pid     = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ();
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'export' , $self->_GET('/objects/' . $pid . '/export', $form_data)
           );  
}

=head2 getDatastream(pid => $pid, dsID => $dsID , %args)

This method return metadata about a data stream. Required is the object $pid and the $dsID of the data stream.
Optionally a version 'asOfDateTime' can be provided and a 'validateChecksum' check.
See: https://wiki.duraspace.org/display/FEDORA36/REST+API for more information.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::datastreamProfile>
model.

  Example:
  
  my $obj = $fedora->getDatastream(pid => 'demo:29', dsID => 'DC')->parse_content;
  
  printf "Label: %s\n" , $obj->{profile}->{dsLabel};
 
=cut
sub getDatastream {
    my $self = shift;
    my %args = (pid => undef , dsID => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    
    my $pid  = $args{pid};
    my $dsID = $args{dsID};
     
    delete $args{pid};
    delete $args{dsID};
    
    my %defaults = ( format => 'xml');
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'getDatastream' , $self->_GET('/objects/' . $pid . '/datastreams/' . $dsID, $form_data)
           );  
}

=head2 getDatastreamHistory(pid => $pid , dsID => $dsID , %args)

This method returns the version history of a data stream. Required paramter is the $pid of the object and the $dsID of the
data stream. This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::datastreamHistory>
model.

  Example:
  
  my $obj = $fedora->getDatastreamHistory(pid => 'demo:29', dsID => 'DC')->parse_content;
  
  for (@{ $obj->{profile} }) {
     printf "Version: %s\n" , $_->{dsCreateDate};
  }

=cut
sub getDatastreamHistory {
    my $self = shift;
    my %args = (pid => undef , dsID => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    
    my $pid  = $args{pid};
    my $dsID = $args{dsID};
     
    delete $args{pid};
    delete $args{dsID};
    
    my %defaults = ( format => 'xml');
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'getDatastreamHistory' , $self->_GET('/objects/' . $pid . '/datastreams/' . $dsID . '/history', $form_data)
           );  
}

=head2 getNextPID(namespace => $namespace, numPIDs => $numPIDs)

This method generates a new pid. Optionally a 'namespace' can be provided and the required 'numPIDs' you need. This method returns a L<Catmandu::FedoraCommons::Response> object with a
L<Catmandu::FedoraCommons::Model::pidList> model.

    Example:
    
    my $pid = $fedora->getNextPID()->parse_content->[0];
    
=cut
sub getNextPID {
    my $self = shift;
    my %args = (namespace => undef, @_);
    
    my %defaults = ( format => 'xml');
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'getNextPID' , $self->_POST('/objects/nextPID', $form_data)
           ); 
}

=head2 getObjectXML(pid => $pid)

This method exports the data model of the object in FOXML format. Required is $pid of the object.
This method returns a L<Catmandu::FedoraCommons::Response> object .

 Example:
 
   my $res = $fedora->getObjectXML(pid => 'demo:29');
   
   print $res->raw;
   
=cut
sub getObjectXML {
    my $self = shift;
    my %args = (pid => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    
    my $pid  = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ();
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'getObjectXML' , $self->_GET('/objects/' . $pid . '/objectXML', $form_data)
           );  
}

=head2 getRelationships(pid => $pid [, relation => [$subject, $predicate, undef] , format => $format ])

This method returns all RELS-EXT triples for an object. Required parameter is the $pid of the object.
Optionally the triples may be filetered using the 'relation' parameter. Format defines the returned format.
See: https://wiki.duraspace.org/display/FEDORA36/REST+API for more information.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::getRelationships> model.

 Example:
 
 my $obj = $fedora->getRelationships(pid => 'demo:29')->parse_content;

 my $iter = $obj->get_statements();
 
 print "Names of things:\n";
 while (my $st = $iter->next) {
     my $s = $st->subject;
     my $name = $st->object;
     print "The name of $s is $name\n";
 }
 
=cut
sub getRelationships {
    my $self = shift;
    my %args = (pid => undef , relation => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    
    my $pid       = $args{pid};
    my $format    = $args{format};
    
    my ($subject,$predicate);
    
    if (defined $args{relation} && ref $args{relation} eq 'ARRAY') {
        $subject   = $args{relation}->[0];
        $predicate = $args{relation}->[1];
    }
    
    my %defaults = (subject => $subject, predicate => $predicate, format => 'xml');
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} } if defined $values{$name};
    }
    return Catmandu::FedoraCommons::Response->factory(
               'getRelationships' , $self->_GET('/objects/' . $pid . '/relationships', $form_data)
           );
}

=head2 ingest(pid => $pid , file => $filename , xml => $xml , format => $format , %args)

=head2 ingest(pid => 'new' , file => $filename , xml => $xml , format => $format , %args)

This method ingest an object into Fedora Commons. Required is the $pid of the new object (which can be
the string 'new' when Fedora has to generate a new pid), and the $filename or $xml to upload writen as $format.
Optionally the following parameters can be provided: label, encoding, namespace, ownerId, logMessage.
See: https://wiki.duraspace.org/display/FEDORA36/REST+API for more information.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::ingest> model.

  Example:

  my $obj = $fedora->ingest(pid => 'new', file => 't/obj_demo_40.zip', format => 'info:fedora/fedora-system:ATOMZip-1.1')->parse_content;
  
  printf "created: %s\n" , $obj->{pid};
  
=cut
sub ingest {
    my $self = shift;
    my %args = (pid => undef , file => undef , xml => undef , @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need file or xml" unless defined $args{file} || defined $args{xml};
    
    my $pid     = $args{pid};
    my $file    = $args{file};
    my $xml     = $args{xml};
     
    delete $args{pid};
    delete $args{file};
    delete $args{xml};

    my %defaults = (ignoreMime => 'true');
    
    if (defined $file) {
        $defaults{format}   = 'info:fedora/fedora-system:FOXML-1.1';
        $defaults{encoding} = 'UTF-8';
        $defaults{file}     = ["$file"];
    }
    elsif (defined $xml) {
        $defaults{format}   = 'info:fedora/fedora-system:FOXML-1.1';
        $defaults{encoding} = 'UTF-8';
        $defaults{file} = [undef, 'upload.xml' , Content => $xml];
    }
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'ingest' , $self->_POST('/objects/' . $pid, $form_data)
           );
}

=head2 modifyDatastream(pid => $pid , dsID => $dsID, url => $remote_location, %args)

=head2 modifyDatastream(pid => $pid , dsID => $dsID, file => $filename , %args)

=head2 modifyDatastream(pid => $pid , dsID => $dsID, xml => $xml , %args)

This method updated a data stream in the object. Required parameters are the object $pid, a new datastream $dsID and
a remote $url, a local $file or an $xml string which contains the content. Optionally any of these datastream modifiers
may be provided: controlGroup, altIDs, dsLabel, versionable, dsState, formatURI, checksumType, checksum,
mimeType, logMessage. See: https://wiki.duraspace.org/display/FEDORA36/REST+API for more information.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::datastreamProfile>
model.

 Example:
 
   my $obj = $fedora->modifyDatastream(pid => 'demo:29', dsID => 'TEST' , file => 'README', mimeType => 'text/plain')->parse_content;
   
   print "Uploaded at: %s\n" , $obj->{dateTime};
   
=cut
sub modifyDatastream {
    my $self = shift;
    my %args = (pid => undef , dsID => undef, url => undef , file => undef , xml => undef , @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    Carp::croak "need url or file (filename)" unless defined $args{url} || defined $args{file} || defined $args{xml};
    
    my $pid  = $args{pid};
    my $dsID = $args{dsID};
    my $url  = $args{url};
    my $file = $args{file};
    my $xml  = $args{xml};
     
    delete $args{pid};
    delete $args{dsID};
    delete $args{url};
    delete $args{file};
    delete $args{xml};
    
    my %defaults = (versionable => 'false');
    
    if (defined $file) {
        $defaults{file} = ["$file"];
        $defaults{controlGroup} = 'M';
    }
    elsif (defined $xml) {
        $defaults{file} = [undef, 'upload.xml' , Content => $xml];
        $defaults{controlGroup} = 'X';
        $defaults{mimeType} = 'text/xml';
    }
    elsif (defined $url) {
        $defaults{dsLocation} = $url;
        $defaults{controlGroup} = 'E';
    }
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'modifyDatastream' , $self->_PUT('/objects/' . $pid . '/datastreams/' . $dsID, $form_data)
           );
}

=head2 modifyObject(pid => $pid, label => $label , ownerId => ownerId , state => $state , logMessage => $logMessage , lastModifiedDate => $lastModifiedDate)

This method updated the metadata of an object. Required parameter is the $pid of the object. Optionally one or more of label, ownerId, state, logMessage
and lastModifiedDate can be provided.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::modifyObject> model.

  Example:
  
  $fedora->modifyObject(pid => 'demo:29' , state => 'I');
  
=cut
sub modifyObject {
    my $self = shift;
    my %args = (pid => undef , @_);
    
    Carp::croak "need pid" unless $args{pid};
    
    my $pid  = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ();

    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'modifyObject' , $self->_PUT('/objects/' . $pid , $form_data)
           );
}

=head2 purgeDatastream(pid => $pid , dsID => $dsID , startDT => $startDT , endDT => $endDT , logMessage => $logMessage)

This method purges a data stream from an object. Required parameters is the $pid of the object and the $dsID of the data
stream. Optionally a range $startDT to $endDT versions can be provided to be deleted.
See: https://wiki.duraspace.org/display/FEDORA36/REST+API for more information.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::purgeDatastream> model.

  Example:
  
  $fedora->purgeDatastream(pid => 'demo:29', dsID => 'TEST')->parse_content;
  
=cut
sub purgeDatastream {
    my $self = shift;
    my %args = (pid => undef , dsID => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    
    my $pid  = $args{pid};
    my $dsID = $args{dsID};
     
    delete $args{pid};
    delete $args{dsID};
    
    my %defaults = ();
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'purgeDatastream' , $self->_DELETE('/objects/' . $pid . '/datastreams/' . $dsID, $form_data)
           );  
}

=head2 purgeObject(pid => $pid, logMessage => $logMessage)

This method purges an object from Fedora Commons. Required parameter is the $pid of the object. Optionally a $logMessage can
be provided.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::purgeObject> model.

  Example:
  
  $fedora->purgeObject(pid => 'demo:29');

=cut
sub purgeObject {
    my $self = shift;
    my %args = (pid => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    
    my $pid  = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ();
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'purgeObject' , $self->_DELETE('/objects/' . $pid, $form_data)
           );
}

=head2 purgeRelationship(pid => $pid, relation => [ $subject, $predicate, $object] [, dataType => $dataType])

This method removes a triple from the RELS-EXT data stream of an object. Required parameters are the $pid of
the object and the relation to be deleted. Optionally the $dataType of the literal can be provided.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::purgeRelationship> model.

  Example:
  
  $fedora->purgeRelationship(pid => 'demo:29' , relation => [ 'info:fedora/demo:29' , 'http://my.org/name' , 'Peter'])

=cut
sub purgeRelationship {
    my $self = shift;
    my %args = (pid => undef , relation => undef, @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need relation" unless defined $args{relation} && ref $args{relation} eq 'ARRAY';
    
    my $pid       = $args{pid};
    my $subject   = $args{relation}->[0];
    my $predicate = $args{relation}->[1];
    my $object    = $args{relation}->[2];
    my $dataType  = $args{dataType};
    my $isLiteral = is_uri($object) ? "false" : "true";
    
    my $form_data = [
        { subject   => $subject },
        { predicate => $predicate },
        { object    => $object },
        { dataType  => $dataType },
        { isLiteral => $isLiteral },
    ];

    return Catmandu::FedoraCommons::Response->factory(
               'purgeRelationship' , $self->_DELETE('/objects/' . $pid . '/relationships', $form_data)
           );
}

=head2 setDatastreamState(pid => $pid, dsID => $dsID, dsState => $dsState)

This method can be used to put a data stream on/offline. Required parameters are the $pid of the object , the
$dsID of the data stream and the required new $dsState ((A)ctive, (I)nactive, (D)eleted).
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::datastreamProfile> model.
  
  Example:
  
  $fedora->setDatastreamState(pid => 'demo:29' , dsID => 'url' , dsState => 'I');
  
=cut
sub setDatastreamState {
    my $self = shift;
    my %args = (pid => undef , dsID => undef, dsState => undef , @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    Carp::croak "need dsState" unless $args{dsState};
    
    my $pid     = $args{pid};
    my $dsID    = $args{dsID};
     
    delete $args{pid};
    delete $args{dsID};
    
    my %defaults = ();
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'setDatastreamState' , $self->_PUT('/objects/' . $pid . '/datastreams/' . $dsID, $form_data)
           );
}

=head2 setDatastreamVersionable(pid => $pid, dsID => $dsID, versionable => $versionable)

This method updates the versionable state of a data stream. Required parameters are the $pid of the object,
the $dsID of the data stream and the new $versionable (true|false) state.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::datastreamProfile> model.

  Example:
  
  $fedora->setDatastreamVersionable(pid => 'demo:29' , dsID => 'url' , versionable => 'false');
  
=cut
sub setDatastreamVersionable {
    my $self = shift;
    my %args = (pid => undef , dsID => undef, versionable => undef , @_);
    
    Carp::croak "need pid" unless $args{pid};
    Carp::croak "need dsID" unless $args{dsID};
    Carp::croak "need versionable" unless $args{versionable};
    
    my $pid     = $args{pid};
    my $dsID    = $args{dsID};
     
    delete $args{pid};
    delete $args{dsID};
    
    my %defaults = ();
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'setDatastreamVersionable' , $self->_PUT('/objects/' . $pid . '/datastreams/' . $dsID, $form_data)
           ); 
}

=head2 validate(pid => $pid)

This method can be used to validate the content of an object. Required parameter is the $pid of the object.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::validate> model.

  Example:
  
  my $obj = $fedora->validate(pid => 'demo:29')->parse_content;
  
  print "Is valid: %s\n" , $obj->{valid};
  
=cut
sub validate {
    my $self = shift;
    my %args = (pid => undef , @_);
    
    Carp::croak "need pid" unless $args{pid};
    
    my $pid     = $args{pid};
     
    delete $args{pid};
    
    my %defaults = ();
    
    my %values = (%defaults,%args);  
    my $form_data = [];
                   
    for my $name (keys %values) {
        push @$form_data , { $name => $values{$name} };
    }
    
    return Catmandu::FedoraCommons::Response->factory(
            'validate' , $self->_GET('/objects/' . $pid . '/validate', $form_data)
           );
}

=head2 upload(file => $file)

This method uploads a file to the Fedora Server. Required parameter is the $file name.
This method returns a L<Catmandu::FedoraCommons::Response> object with a L<Catmandu::FedoraCommons::Model::upload-> model.

 Example:
 
 my $obj = $fedora->upload(file => 't/marc.xml')->parse_content;
 
 print "Upload id: %s\n" , $obj->{id};
 
=cut
sub upload {
    my $self = shift;
    my %args = (file => undef , @_);
    
    Carp::croak "need file" unless $args{file};
    
    my $file = $args{file};

    delete $args{file};
    
    my $form_data = [ { file => [ "$file"] }];
    
    return Catmandu::FedoraCommons::Response->factory(
            'upload' , $self->_POST('/upload', $form_data)
           );
}


=head1 SEE ALSO

L<Catmandu::FedoraCommons::Response>,
L<Catmandu::Model::findObjects>,
L<Catmandu::Model::getObjectHistory>,
L<Catmandu::Model::getObjectProfile>,
L<Catmandu::Model::listDatastreams>,
L<Catmandu::Model::listMethods>

=head1 AUTHOR

=over

=item * Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the terms
of either: the GNU General Public License as published by the Free Software Foundation;
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut


1;
