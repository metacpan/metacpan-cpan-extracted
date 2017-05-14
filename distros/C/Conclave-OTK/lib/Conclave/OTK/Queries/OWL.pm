use strict;
use warnings;
package Conclave::OTK::Queries::OWL;
# ABSTRACT: templates for OTK queries using OWL language

use parent qw/Template::Provider/;
no warnings qw/redefine/;

my $templates = {

'add_class' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

INSERT DATA {
  GRAPH <[% graph %]> {
    [% name %] rdf:type owl:Class .
    [% FOREACH c IN parents -%]
    [% name %] rdfs:subClassOf [% c %] .
    [%- END %]
  }
}
EOT
,
'get_classes' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

SELECT ?c
FROM <[% graph %]>
WHERE {
  ?c rdf:type owl:Class
}
EOT
,
'get_subclasses' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

SELECT ?c FROM <[% graph %]>
WHERE { 
  ?c rdf:type owl:Class .
  ?c rdfs:subClassOf [% class %] .
} 
EOT
,
'get_instance_classes' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

SELECT DISTINCT ?c
FROM <[% graph %]>
  WHERE {
    <[%- i -%]> rdf:type ?c . 
    FILTER regex(str(?c), 'program#', '')
  }
EOT
,
'add_instance' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

INSERT DATA {
  GRAPH <[% graph %]> {
    [% name %] rdf:type [% class %] ;
      rdf:type owl:NamedIndividual .
  }
}
EOT
,
'get_instances' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

SELECT ?i
FROM <[% graph %]>
WHERE {
  ?i rdf:type [% class %]
}
EOT
,
'add_obj_prop' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

INSERT DATA {
  GRAPH <[% graph %]> {
    [% subject %] [% relation %] [% target %] .
    [% relation %] rdf:type owl:ObjectProperty .
  }
}
EOT
,
'add_data_prop' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

INSERT DATA {
  GRAPH <[% graph %]> {
    [% subject %] [% relation %] "[% target %]"^^xsd:[% type %] .
    [% relation %] rdf:type owl:DatatypeProperty .
  }
}
EOT
,
'select_from_graph' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

SELECT ?s ?p ?r
FROM <[% graph %]>
WHERE {
  ?s ?p ?r
}
EOT
,
'graph_dump_rdf' => <<'EOT'
CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <[% graph %]> { ?s ?p ?o } }
EOT
,
'get_children' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

CONSTRUCT { ?c rdfs:subClassOf [% parent %] }
WHERE { GRAPH <[% graph %]> { ?c rdfs:subClassOf [% parent %] } }
EOT
,
'get_obj_props' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

SELECT DISTINCT ?n ?p ?v
FROM <[% graph %]>
  WHERE {
    ?n ?p ?v .
    ?p rdf:type owl:ObjectProperty .
  FILTER ( 
    REGEX(str(?n), "^<?[% instance %]>?$") ||
    REGEX(str(?v), "^<?[% instance %]>?$")
  )
}
EOT
,
'get_obj_props_for' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]

SELECT DISTINCT ?o
FROM <[% graph %]>
  WHERE {
    ?o [% rel %] [% el %]
  }
EOT
,
'get_data_props' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]
SELECT DISTINCT ?n ?p ?v
FROM <[% graph %]>
  WHERE {
    ?n ?p ?v .
    ?p rdf:type owl:DatatypeProperty .
  FILTER ( 
    REGEX(str(?n), "^<?[% instance.remove('(<|>)') %]>?$") ||
    REGEX(str(?v), "^<?[% instance.remove('(<|>)')  %]>?$")
  )
}
EOT
,
'get_ranges' => <<'EOT'
[% FOREACH p IN prefixes.keys -%]
PREFIX [% p %]: <[% prefixes.item(p) %]>
[% END -%]
SELECT DISTINCT ?p ?r

FROM <[% graph %]>
  WHERE {
    ?p rdf:type owl:ObjectProperty . 
    ?p rdfs:range ?r .
  }
EOT
};

sub _template_modified {
    my($self,$path) = @_;

   return 1;
}

sub _template_content {
    my($self,$path) = @_;

   $path =~ s#^templates/##;
    $self->debug("get $path") if $self->{DEBUG};

   my $data = $templates->{$path};
   my $error = "error: $path not found";
   my $mod_date = 1;

   return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Conclave::OTK::Queries::OWL - templates for OTK queries using OWL language

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  TODO

=head1 DESCRIPTION

  TODO

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2015 by Nuno Carvalho <smash@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
