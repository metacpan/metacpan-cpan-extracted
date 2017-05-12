DBIx-Class-MassAssignable
=========================

Restrict which columns can be mass assigned, similar to attr_accessible and attr_protected in Rails

Synopsis
--------

    __PACKAGE__->load_components(qw/ MassAssignable /);
    __PACKAGE__->attr_accessible([qw( post_title post_content )]);
    __PACKAGE__->attr_protected([qw( is_admin )]);

Description
-----------

With this component loaded the methods set_columns and set_inflated_columns will either ignore
fields you haven't specified (if you use attr_accessible) or block fields that you have blacklisted (using attr_protected).

It is important to use only attr_accessible OR attr_protected. If you use both then it will default to using just
the whitelisted values (as this is the safer option).

    