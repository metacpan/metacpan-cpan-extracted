# Client Credentials Class
package API::Client::Credentials;

use Data::Object::Class;
use Data::Object::Signatures;

our $VERSION = '0.04'; # VERSION

# METHODS

method process (("InstanceOf['Mojo::Transaction']") $tx) {

    return $tx;

}

1;
