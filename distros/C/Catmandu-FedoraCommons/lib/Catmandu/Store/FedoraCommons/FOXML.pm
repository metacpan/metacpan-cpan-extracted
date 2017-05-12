package Catmandu::Store::FedoraCommons::FOXML;

use Moo;

sub valid {
    my ($self) = @_;
    
    return (1,"ok");
}

sub serialize {
    my ($self) = @_;
    
    # This is the minimum object that can be created in Fedora
    return <<EOF;
<foxml:digitalObject VERSION="1.1"
      xmlns:foxml="info:fedora/fedora-system:def/foxml#"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
 <foxml:objectProperties>
   <foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="Active"/>
 </foxml:objectProperties>
 <foxml:datastream CONTROL_GROUP="X" ID="DC" STATE="A" VERSIONABLE="false">
   <foxml:datastreamVersion
     FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" ID="DC1.0"
     LABEL="Dublin Core Record for this object" MIMETYPE="text/xml">
     <foxml:xmlContent>
       <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
       </oai_dc:dc>
     </foxml:xmlContent>
   </foxml:datastreamVersion>
 </foxml:datastream>
 </foxml:digitalObject>
EOF
}

sub deserialize {
    die "not implemented";  
}

1;