#$Id: Rule.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator::Rule;
use strict;
use warnings;
use base qw (Class::Data::Inheritable Class::Accessor);
use Carp;
use Module::Pluggable search_path => ['Acme::Web20::Validator::Rule'] ;

__PACKAGE__->mk_classdata('name');
__PACKAGE__->mk_accessors(qw(is_ok));
__PACKAGE__->name(__PACKAGE__);

sub validate {
    croak "this method is abstract";
}

1;

__END__
