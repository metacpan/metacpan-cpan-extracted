#
#   DBIx::XMLMessage
#
#   Copyright (c) 2000-2001 Andrei Nossov. All rights reserved.
#   This program is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
# _________________________________________________________________________
#   Modifications Log
#
#   Version Date    Author          Notes
# _________________________________________________________________________
#   0.04    3/01    Andrei Nossov   Root compound key bug fixed
#   0.03    11/00   Andrei Nossov   Bug fixes, more documentation
#   0.02    10/00   Andrei Nossov   Documentation improved
#   0.01    8/00    Andrei Nossov   First cut
# _________________________________________________________________________

require 5.003;

use Exporter;
use HTML::Entities ();
use POSIX;
use DBI;
use Data::Dumper;
use strict;

# _________________________________________________________________________
#   XMLMessage: head package
#
package DBIx::XMLMessage;

use Carp;
use XML::Parser;
use vars qw (@ISA %EXPORT_TAGS $TRACELEVEL $PACKAGE $VERSION);
$PACKAGE = 'DBIx::XMLMessage';
$VERSION  = '0.04';
$TRACELEVEL = 0;        # Don't trace by default
@ISA = qw ( Exporter );

%EXPORT_TAGS = ( 'elements' => ['VERSION', 'TRACELEVEL', '%TEMPLATE::',
        '%REFERENCE::', '%CHILD::', '%KEY::', '%COLUMN::', '%PARAMETER::']);
Exporter::export_ok_tags ('elements');

# _________________________________________________________________________
#   Allow to create via 'new'
#
sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    # Check if the external code references are correct
    # So far have: _OnError, _OnTrace
    foreach (keys %args) {
        if ( /^_On/ ) {     # Should be a CODE reference
            if ( (ref $args{$_}) ne 'CODE' ) {
                $self->error ("Argument $_ should be a CODE reference");
            } else {
                $self->{$_} = $args{$_};
            }
        } elsif ( /^Handlers$/ ) {
            $self->set_handlers ($self->{Handlers});
        } elsif ( /^TemplateString$/ ) {
            $self->prepare_template ($args{TemplateString});
        } elsif ( /^TemplateFile$/ ) {
            $self->prepare_template_from_file ($args{TemplateFile});
        }
    }
    return $self;
}   # -new

# _________________________________________________________________________
#   Set expat handlers
#
#   This is needed as a separate function, as Handlers for input_xml and
#   prepare_template can be different
#
sub set_handlers {
    my $self = shift;
    my $handlers_ref = shift;

    my $old_handlers = $self->{Handlers};
    # Check if Handlers is a hash referernce
    if ( $handlers_ref && (ref $handlers_ref) ne 'HASH' ) {
        $self->error ("Argument Handlers should be a HASH reference");
    } else {
        $self->{Handlers} = $handlers_ref;
    }
    return $old_handlers;
}

# _________________________________________________________________________
#   Error method: invoke $self->{_OnError} and die, otherwise croak
#
sub error {
    my $self = shift;

    if ( $self->{_OnError} ) {
        &{$self->{_OnError}} (@_);
        die;
    } else {
        croak (@_);
    }
}   # -error

# _________________________________________________________________________
#   trace method: invoke $self->{_OnTrace}, otherwise print to STDERR
#
sub trace {
    my $self = shift;

    if ( $TRACELEVEL || defined $self->{_OnTrace} ) {
        if ( $self->{_OnTrace} ) {
            &{$self->{_OnTrace}} (@_);
        } else {
            print STDERR @_;
    }   }
}   # -trace

# _________________________________________________________________________
#   Prepare template for the message type
#
sub prepare_template {
    my $self = shift;
    my $tplcontents = shift;

    my $parser = new XML::Parser (Style => 'Objects',
            Pkg => $PACKAGE, Handlers => $self->{Handlers});
    my $parsed;
    eval { $parsed = $parser->parse ($tplcontents) };
    if ( $@ ) {
        $self->error ($@);
    }
    $self->mk_refs ($parsed->[0]);
    $self->{_Template} = $parsed->[0];

    return $self->{_Template};

}   # -prepare_template

# _________________________________________________________________________
#   Prepare template for the message type
#
#   If no filename given, try to derive it from the _MessageType set by the
#   input_xml and SQLM_TEMPLATE_DIR environment variable
#
sub prepare_template_from_file {
    my $self = shift;   # XMLMessage
    my $fname = shift;  # Template file name

    if ( ! defined $fname ) {   # Full filename expected
        # If there's no name, try to derive it from the message type.
        # This hopefully makes things a little bit more flexible
        $fname = $self->{_MessageType} . '.xml';
        if ( $ENV{SQLM_TEMPLATE_DIR} ) {
            $fname = "$ENV{SQLM_TEMPLATE_DIR}/$fname";
        }
        $self->error ("Template file name not defined") unless -f $fname;
    }
    my $parser = new XML::Parser (Style => 'Objects',
            Pkg => $PACKAGE, Handlers => $self->{Handlers});
    my $parsed;
    eval { $parsed = $parser->parsefile ($fname) };
    if ( $@ ) {
        $self->error ($@);
    }
    $self->mk_refs ($parsed->[0]);
    $self->{_Template} = $parsed->[0];
    return $self->{_Template};
}   # -prepare_template_from_file

#__________________________________________________________________________
#   Parse the input request
#
sub input_xml {
    my $self = shift;
    my $content = shift;

    my $p = new XML::Parser (Style => 'Tree',
            Handlers => $self->{Handlers});
    $self->{_MessageTree} = $p->parse ($content);
    $self->{_MessageType} = undef;
    $self->{_MessageAttr} = undef;
    $self->{_MessageKids} = undef;
    foreach my $el (@{$self->{_MessageTree}}) {
        if ( (ref $el) =~ /HASH/ )  {
            $self->{_MessageAttr} = $el;
        } elsif ( (ref $el) =~ /ARRAY/ ) {
            $self->{_MessageKids} = $el;
        } elsif ( $el && !(ref $el) ) {
            $self->{_MessageType} = $el;
        } else {
            $self->error ("Unknown element type encountered: $el\n");
        }
    }

    return $self->{_MessageType};
}   ##input_xml

#__________________________________________________________________________
#   Parse the input file
#
sub input_xml_file {
    my $self = shift;
    my $fname = shift;

    my $p = new XML::Parser (Style => 'Tree',
            Handlers => $self->{Handlers});
    $self->{_MessageTree} = $p->parsefile ($fname);
    $self->{_MessageType} = undef;
    $self->{_MessageAttr} = undef;
    $self->{_MessageKids} = undef;
    foreach my $el (@{$self->{_MessageTree}}) {
        if ( (ref $el) =~ /HASH/ )  {
            $self->{_MessageAttr} = $el;
        } elsif ( (ref $el) =~ /ARRAY/ ) {
            $self->{_MessageKids} = $el;
        } elsif ( $el && !(ref $el) ) {
            $self->{_MessageType} = $el;
        } else {
            $self->error ("Unknown element type encountered: $el\n");
        }
    }
    return $self->{_MessageType};
}   # -input_xml_file

#__________________________________________________________________________
#
#   Store the values in the according objects
#
#   E.g.:
#   [   ServiceIncident,
#       [   {VERSION => "1.0"},
#           Service,
#           [   {},
#               0, "",
#               Case,
#               [   {},
#                   0, "",
#                   ID,
#                   [ {}, 0, "8014"
#                   ],
#                   0, ""
#               ]
#           ],
#           0, ""
#           ServiceTransaction,
#           [   {},
#               0, "",
#               DispStatus,
#               [   {}, 0, "In Progress"
#               ]
#           ]
#           0, ""
#       ]
#       0, ""
#   ]
#
# ------------------------------------------------------------------------
#
# FIXME: Buggy..
#
sub populate_objects {
    my $self = shift;       # XMLMessage
    my $ghash = shift;      # Global hash
    my $obj = shift;        # The matching object for this tag
    my $tag = shift;        # The tag name
    my $content = shift;    # Reference to the array of kids, hash is attrs
    my $parix = shift || 0; # Parent input set index
    my ($el, $attr, $i, $text, $kid, $kidcont, $papa);

    # Initialize the first object from _Template
    if ( !defined $obj ) {
        if ( $self->{_Template} ) {
            $obj = $self->{_Template};
        } else {
            $self->error ("Error: the template is empty"
                    . " (have you run prepare_template?)");
    }   }

    # Initialize the first tag name from _MessageType and the
    # first content -- from the _MessageKids
    if ( ! defined $tag && ! defined $content ) {
        $tag = $self->{_MessageType};
        $content = $self->{_MessageKids};
    }
    # Log the entry at this point.. Hopefully nothing will happen before..
    $self->trace ("populate_objects: $tag, $parix\n");

    # Figure out its own _INIX
    $obj->{_INIX} = (defined $obj->{_INIX}) ? ++$obj->{_INIX} : 0;

    # Verify that the object matches w/ the tag
    if ( $tag ne $obj->{NAME} )  {
        croak "Error: $tag doesn't match with the template ($obj->{NAME})";
    }
    $text = undef;

    for ( $i=0; defined $content->[$i]; $i++ ) {
    # while ( defined ($kid = shift @$content) ) {
        $kid = $content->[$i];
        if ( (ref $kid) =~ /HASH/ ) {   # Attributes -- verify
            foreach $attr ( keys %$kid ) {
                if ( $obj->{$attr} && $kid->{$attr} ne $obj->{$attr} )  {
                    $obj->error ("Error: $attr of the message $el->{$attr}"
                        . " don't match with that of the template"
                        . " ($obj->{$attr})");
            }   }
        } else {
            #<<<<<<<<
    $kidcont = $content->[++$i];
    if ( ref $kid ) {         # ?? Error
        $self->error ("Error: Unexpected reference $kid");
    } elsif (!$kid) {               # 0 -- text
        $kidcont =~ s/[\n\s]*$//;
        $text .= $kidcont;
    } else {                        # Not 0 -- tag
        undef $el;
        foreach my $typ (qw (CHI REF COL PAR KEY)) {
            if ( $obj->{"_$typ" . 'LIST'} && $obj->{"_$typ".'LIST'}->{$kid} ) {
                $el = $obj->{"_$typ" . 'LIST'}->{$kid};
                last;
        }   }
        if ( $el ) {    # Found
            $self->populate_objects ($ghash,$el,$kid,$kidcont,$obj->{_INIX});
        } else {
            # Kid not found -- see if we can dynamically create it..
            if ( $obj->{TOLERANCE} && $obj->{TOLERANCE} =~ /^CREATE/ ) {
                                                        # CREATE
                my $type = 'COLUMN';
                if ( $obj->{TOLERANCE} =~ /^CREATE (.+)$/ ) {
                    $type = $1;
                }
                # Dynamic creation
                $el = new "$PACKAGE::$type";
                $el->{NAME} = $kid;
                $el->{_PARENT_TAG} = $obj;
                push @{$obj->{Kids}}, $el;
                $obj->{_COLLIST}->{$kid} = $el;
                $self->populate_objects ($ghash,$el,$kid,$kidcont,$obj->{_INIX});
            } elsif ( $obj->{TOLERANCE}
                    && $obj->{TOLERANCE} eq 'REJECT' ) {# REJECT
                $self->error ("$obj->{NAME} doesn't allow child $kid");
            } else {                                    # IGNORE
                $self->trace ("$kid kid not found in the template"
                        . " for $obj->{NAME}, ignoring");
    }   }   }   }
            #<<<<<<<<
    }   ## while kid
    # Tweak up the text if there's a built-in..
    if ( $text && $obj->{BLTIN} ) {
        my $bltin = $obj->{BLTIN};
        @_ = ($self,$obj,$text);
        my $cmd = '$text = &' . $bltin . ';';
        eval $cmd || die "Error in BUILT-IN $bltin of $obj->{NAME}: $@";
    }
    # Figure out what to do w/ the text..
    if ( (ref $obj) =~ /::COLUMN$/ || (ref $obj) =~ /::PARAMETER$/
            || (ref $obj) =~ /::KEY$/ ) {
        $papa = $obj->{_PARENT_TAG};
        $papa->{_INVALUES}->[$parix]->{$tag} = $text;
    }

}   # -populate_objects

#__________________________________________________________________________
#   Debugging subroutine: Print the tree
#
sub pr_tree {
    my $self = shift;       # XMLMessage
    my $ref = shift;        # Root node of this subtree
    my $level = shift || 0; # Level of this root node
    my ($el, $i);

    if ( (ref $ref) =~ /ARRAY/ ) {
        foreach $el (@$ref) {
            $self->pr_tree ($el, $level+1);
        }
    } elsif ( (ref $ref) =~ /HASH/ ) {
        # Attributes only
        foreach $el ( keys %$ref ) {
            for ($i=0; $i<$level; $i++) { $self->trace ("  "); }
            $self->trace ("$el = $ref->$el\n");
        }
    } else {
        if ( $ref ) {
            for ($i=0; $i<$level; $i++) { $self->trace ("  "); }
            if ( $ref =~ /(.*)(\s+)$/ ) {
                $ref = $1;
            }
            if ( $ref =~ /(.*)(\n+)$/ ) {
                $ref = $1;
            }
            $self->trace ("$ref\n");
        }
    }
}   # -pr_tree

# _________________________________________________________________________
#   Create the necessary internal structures
#
sub mk_refs {
    my $self = shift;   # XMLMessage
    my $root = shift;   # Element

    foreach my $el (@{$root->{'Kids'}}) {
        if ( (ref $el) =~ /::(\w+)$/ && (ref $el) !~ /::Characters/ ) {
            # Create the parent references
            $el->{_PARENT_TAG} = $root;
            # Store the object type lists in hashes
            # Constructs: _COLLIST, _KEYLIST, _PARLIST, _REFLIST, _CHILIST
            # The assumption here is that the tag name within an object
            # type is unique (i.e. there couldn't be two COLUMNs with the
            # same name)
            my $listname = "_" . substr($1,0,3) . "LIST";
            if ( $root->{$listname}->{$el->{NAME}} ) {
                $self->error ("$1 $el->{NAME} is defined more"
                        . " than once under $root->{NAME}");
            } else {
                $root->{$listname}->{$el->{NAME}} = $el;
            }
            $self->mk_refs($el);
    }   }

}   # -mk_refs

# _________________________________________________________________________
#   Get the value from global hash (not a method!)
#
sub get_hashval {
    my $href = shift;       # Hash reference
    my $name = shift;       # Name to look for
    my $resix = shift || 0; # Index to look for

    # Note: This function doesn't have to have a $inix argument, as the only
    # linkage to the higher level is $resix.
    #
    my $val = undef;
    if ( $href && defined $href->{$name} ) {
        if ( (ref $href->{$name}) eq 'CODE' )  {
            $val = &{$href->{$name}}($resix);
        } elsif ( (ref $href->{$name}) eq 'ARRAY' )  {
            return $href->{$name}->[$resix];
        } elsif ( !(ref $href->{$name}) && $resix == 0 ) {
            # Just a single value, only return if the index is 0
            $val = $href->{$name};
        }
    }
    return $val;
}   # -get_hashval

# _________________________________________________________________________
#   THESE ARE METHODS FOR THE ELEMENTS
#

# _________________________________________________________________________
#   Get the *parent* result value #n
#
sub get_resval {
    my $self = shift;           # XMLMessage
    my $node = shift;           # TEMPLATE | REFERENCE | CHILD
    my $name = shift;           # (COLUMN) name
    my $resix = shift || 0;     # Result set index

    $self->trace ("      get_resval ($node->{NAME},$name,$resix)\n");
    my $papa = $node->{_PARENT_TAG} || return undef;
    my $rref = $papa->{_RESULTS} || return undef;

    if ( (ref $rref) eq 'CODE' ) {
        # Should this work for global hash?
        return &{$rref}($resix);
    } elsif ( (ref $rref) eq 'ARRAY' ) {
        if ( $rref->[$resix] && defined $rref->[$resix]->{$name} ) {
            return $rref->[$resix]->{$name};
        }
    } elsif ( (ref $rref) eq 'HASH' && $rref->{$name} && $resix == 0 ) {
        # Should work for global hash as well?
        return $rref->{$name};
    }
    return undef;
}   # -get_resval

# _________________________________________________________________________
#   Get the parameter (input value) #n
#
sub get_inval {
    my $self = shift;           # XMLMessage
    my $node = shift;           # TEMPLATE|CHILD|REFERENCE
    my $name = shift;           # Name to look for
    my $ix = shift || 0;        # Input value set index

    $self->trace ("      get_inval ($node->{NAME},$name,$ix)\n");
    my $val = $node->{_INVALUES}
            ? $node->{_INVALUES}->[$ix]
                ? $node->{_INVALUES}->[$ix]->{$name}
                : undef
            : undef;
    return $val;
}   # -get_inval

#__________________________________________________________________________
#   Get the key value #($inix,$resix)
#
sub get_keyval {
    my $self = shift;           # XMLMessage
    my $node = shift;           # Key reference
    my $href = shift;           # External hash reference
    my $inix = shift || 0;      # Input set index
    my $resix = shift || 0;     # Parent result set index

    $self->trace ("    get_keyval ($node->{NAME},$inix,$resix)\n");
    my ($tag, $papa, $kname, $val);
    $tag = $node->{_PARENT_TAG};
    # Any key should have a parent TEMPLATE|CHILD|REFERENCE
    if ( !$tag )  {
        $self->error ("Internal error: Key $node->{NAME} has no parent");
    }
    # Find the corresponding name a level up
    $kname = $node->{PARENT_NAME} ? $node->{PARENT_NAME} : $node->{NAME};
    # Check itself
    # Keys are stored in a 2-dimensional array:
    # _____________________________________________________________________
    #      resix    0   1   2   3   ...
    # inix
    #    0          A   B   C   D
    #    1          E   F
    #    2          G   H   I
    #   ...
    # _____________________________________________________________________
    #   Thus, inix 0 should be always there and it's fake..
    #
    if ( $tag->{_KEYS} && $tag->{_KEYS}->[$inix]
            && defined $tag->{_KEYS}->[$inix]->[$resix]
            && defined $tag->{_KEYS}->[$inix]->[$resix]->{$kname} ) {
        $val = $self->format_value ($node,$tag->{_KEYS}->[$inix]->[$resix]->{$kname});
        $self->trace ("    *get_keyval = $val\n");
        return $val;
    }
    # Find the tag's parent (all but TEMPLATE should have)
    if ( $tag->{_PARENT_TAG} ) {
        $papa = $tag->{_PARENT_TAG};
    } elsif ( (ref $tag) !~ /::TEMPLATE$/ ) {
        $self->error ("Internal error: Tag $tag->{NAME} has no parent");
    }
    # Try to get from input values and parent results
    my $val1 = $self->get_inval ($tag, $node->{NAME}, $inix);
    # Get the parent result
    my $val2 = $self->get_resval ($tag, $kname, $resix);
    # Compare values
    if ( defined $val1 ) {
        if ( defined $val2 && $val1 ne $val2 ) {
            $self->error ("Key $node->{NAME} values don't"
                . " match in parent result set and input");
        }
        $val = $val1;
    } else {
        $val = $val2;
    }
    # If still undefined, then try the global hash
    if ( !defined $val ) {
        # None defined -- try the global hash
        $val = &get_hashval ($href, $kname, $resix);
    }
    if ( defined $val ) {
        $tag->{_KEYS}->[$inix]->[$resix]->{$kname} = $val;
    }
    $val = (defined $val) ? $self->format_value($node,$val) : undef;
    $self->trace ("    get_keyval = $val\n");
    return $val;

    # Should be able to have two references from two different columns
    # to the same table.. (I recall this idea seemed important..why?;^)

}   # -get_keyval

#__________________________________________________________________________
#   Get the parameter value #ix
#
sub get_parval {
    my $self = shift;           # XMLMessage
    my $node = shift;           # PARAMETER
    my $href = shift;           # External hash reference
    my $inix = shift || 0;      # Input value set index, real starts at 1
    my $resix = shift || 0;     # Parent result set index

    my $val = undef;
    my $tag = $node->{_PARENT_TAG};  # Parameter's tag
    if ( !$tag )  {
        $self->error ("Parameter $node->{NAME} has no parent tag");
    }

    # Try to get from input values and parent results
    my $val1 = $self->get_inval ($tag, $node->{NAME}, $inix);
    # Find the corresponding name a level up
    my $pname = $node->{PARENT_NAME} ? $node->{PARENT_NAME} : $node->{NAME};
    # Get the parent result
    my $val2 = $self->get_resval ($tag, $pname, $resix);
    # Compare values
    if ( defined $val1 ) {
        if ( defined $val2 && $val1 ne $val2 ) {
            $self->error ("Parameter $node->{NAME} values"
                . " don't match in parent result set and input");
        }
        $val = $val1;
    } else {
        $val = $val2;
    }
    # If still undefined, then try the global hash
    if ( !defined $val ) {
        $val = &get_hashval ($href, $pname, $resix);
    }
    if ( defined $val ) {
        $val = $self->format_value($node,$val);
    } else {
        if ( !defined $val && defined $node->{DEFAULT} )  {
            $val = $self->{DEFAULT};
    }   }
    return $val;
}   ##get_parval

#__________________________________________________________________________
#   Get and format the column value #($inix,$resix)
#
sub get_colval {
    my $self = shift;       # XMLMessage
    my $node = shift;       # COLUMN
    my $dbh = shift;        # Database handle
    my $href = shift;       # External hash reference
    my $inix = shift || 0;  # Input value set index
    my $resix = shift || 0; # Parent result set index

    $self->trace ("    get_colval ($node->{NAME},$inix,$resix)\n");
    my $tag = $node->{_PARENT_TAG};  # Parameter's tag
    if ( !$tag )  {
        $self->error ("Internal error: Column $node->{NAME} has no parent");
    }
    my $val = undef;
    # Find the tag's parent (all but TEMPLATE should have)
    my $papa;
    if ( $tag->{_PARENT_TAG} ) {
        $papa = $tag->{_PARENT_TAG};
    } elsif ( (ref $tag) =~ /::TEMPLATE$/ ) {
        $papa = $href;
    } else {
        die ("Internal error: Tag $tag->{NAME} has no parent");
    }
    # Look for the input value and parent result
    my $val1 = $self->get_inval ($tag, $node->{NAME}, $inix);
    my $val2 = $self->get_resval ($node, $node->{NAME}, $resix);
    $self->trace ("    inval=" . (defined $val1 ? $val1 : "UNDEF")
           . ", resval=" . (defined $val2 ? $val2 : "UNDEF") . "\n");
    if ( defined $val1 && length($val1) > 0 ) {
        if ( defined $val2 && length($val2) > 0 ) {
            if ( $val1 eq $val2 ) {
                $val = $val1
            } else {
                die ("Internal error: $node->{NAME} column values don't "
                    . "match in parent result set and input ($val1,$val2)");
            }
        } else {
            $val = $val1;
        }
    } else {
        $val = $val2;
    }
 # print "   val=$val\n";
    # Also try the keys with matching EXPR|NAME
    # as they might get pushed
    # from the lower levels (not anymore ;^))
    if ( !defined $val ) {
        if ( $node->{EXPR} && $tag->{_KEYLIST}->{$node->{EXPR}} ) {
            my $key = $tag->{_KEYLIST}->{$node->{EXPR}};
            $val = $self->get_keyval ($key,$href,$inix,$resix);
        } elsif ( $tag->{_KEYLIST}->{$node->{NAME}} ) {
            my $key = $tag->{_KEYLIST}->{$node->{NAME}};
            $val = $self->get_keyval ($key,$href,$inix,$resix);
    }   }

    if ( $val )  {
        $val = $self->format_value ($node,$val);
    } elsif ( $node->{GENERATE_PK} ) {
        if ( $node->{GENERATE_PK} eq 'HASH' ) {
            $val = &get_hashval ($href,"$tag->{TABLE}",$inix,$resix);
        } else {
            # Should contain a SQL that selects 1 value
            if ( $dbh ) {
                my $idtab = $tag->{TABLE} . "_ID";
                my $sql = $node->{GENERATE_PK};
                my $sth = $dbh->prepare ($sql) || die $DBI::errstr;
                my $rc = $sth->execute() || die $DBI::errstr;
                $rc = $sth->fetchall_arrayref();
                $val = $rc->[0]->[0];
                $rc  = $sth->finish();
            } elsif ( $self->{NODBH} eq 'OK' ) {
                # No database handle: Try hash anyway
                $self->trace ("Trying to get PK without database handle");
                $val = &get_hashval ($href,"$tag->{TABLE}",$inix,$resix);
            } else {
                $self->error (
                    "Can not generate primary key for table $tag->{TABLE}");
        }   }
    } elsif ( defined $node->{DEFAULT} )  {
        $val = $node->{DEFAULT};    # This goes as-is
    }
    return $val;
}   # -get_colval

#__________________________________________________________________________
#   Format element value according to its datatype
#
sub format_value {
    my $self = shift;
    my $node = shift;
    my $val = shift;

    # DATATYPE is CHAR by default
    if ( !$node->{DATATYPE} || $node->{DATATYPE} =~ /(CHAR|DATE|TIME)/ ) {
        if ( $val !~ /^\'(.*)\'$/ && $val !~ /^\"(.*)\"$/ )  {
            $val =~ s/\'/\'\'/g;
            $val = "'$val'";
    }   }
    return $val;
}   # -format_value

#__________________________________________________________________________
#   Create the WHERE clause for SELECT/UPDATE
#
sub create_where {
    my $self = shift;           # XMLMessage
    my $node = shift;           # TEMPLATE|CHILD|REFERENCE
    my $href = shift;           # Global hash reference
    my $inix = shift || 0;      # Key set index
    my $resix = shift || 0;     # Parent result set index

    $self->trace ("   create_where ($node->{NAME},$inix,$resix)\n");
    my ($el, $where);
    # Construct WHERE clause
    foreach ( keys %{$node->{_KEYLIST}} ) {
        $el = $node->{_KEYLIST}->{$_};
        my $val =  $self->get_keyval ($el,$href,$inix,$resix);
        if ( !defined $val ) {
            $self->error ("$el->{NAME}: Key value #($inix,$resix) not found");
        }
        $where .= " and ";
        if ( defined $el->{EXPR} )  {
            $where .= $el->{EXPR};
        } else {
            $where .= $el->{NAME};
        }
        if ( !$el->{DATATYPE} || $el->{DATATYPE} =~ /CHAR/ ) {
            $where .= " like ";
        } else {
            $where .= " = ";
        }
        $val = $self->format_value($el,$val);
        $where .= $val;
    }
    # Check if there is additional WHERE clause
    if ( $node->{'WHERE_CLAUSE'} ) {
        $where .= " and " if ( $where );
        $where .= $node->{'WHERE_CLAUSE'};
    }
    # Cut off the initial 'and'
    $where = substr ($where, 4) if ($where);
    return $where;
}   # -create_where

# _________________________________________________________________________
#   Construct SELECT statement
#
sub create_select {
    my $self = shift;       # XMLMessage
    my $node = shift;       # TEMPLATE|CHILD|REFERENCE
    my $dbh = shift;        # Database handle
    my $href = shift;       # Global hash reference
    my $inix = shift || 0;  # Input value set index
    my $resix = shift || 0; # Parent result set index

    $self->trace ("  create_select ($node->{NAME},$inix,$resix)\n");
    my ($el, $colexpr, $sql);
    # Construct column list, possibly with aliases
    foreach ( keys %{$node->{_COLLIST}} ) {
        # $self->trace ("  create_select: found column $_\n");
        $el = $node->{_COLLIST}->{$_};
        # Include expression if present
        if ( $el->{'EXPR'} ) {
            $colexpr = $el->{EXPR};
        } else {
            $colexpr = $el->{NAME};
        }
        # Include name if not the same
        if ( $el->{'NAME'} ne $colexpr ) {
            $colexpr .= " " if ($colexpr);
            $colexpr .= $el->{'NAME'};
        }
        # Add to the SQL if not empty
        $sql .= "\n\t$colexpr," if ($colexpr);
    }
    if ( $sql )  {
        chop ($sql);    # Chop the last comma
        $sql = "SELECT $sql";
    }
    if ( $sql && $node->{TABLE} )  {
        $sql .= "\nFROM\n\t" . $node->{'TABLE'};
        # WHERE clause doesn't make sence without FROM
        my $where = $self->create_where ($node, $href, $inix, $resix);
        $sql .= "\nWHERE $where";
    }
    return $sql;
}   # -create_select

# _________________________________________________________________________
#   Construct INSERT statement
#
sub create_insert {
    my $self = shift;       # XMLMessage
    my $node = shift;       # TEMPLATE|CHILD|REFERENCE
    my $dbh = shift;        # Database handle
    my $href = shift;       # Global hash reference
    my $inix = shift || 0;  # Input value set index
    my $resix = shift || 0; # Parent result set index

    my ($el, $colexpr, $colval, $sql, $sql1);
    $self->error ("$node->{NAME}: Cannot INSERT without TABLE")
            if(!$node->{TABLE});
    # Construct the list of columns and list of values
    foreach ( keys %{$node->{_COLLIST}} ) {
        $el = $node->{_COLLIST}->{$_};
        # Use EXPR if present
        if ( $el->{'EXPR'} ) {
            $colexpr = $el->{EXPR};
        } else {
            $colexpr = $el->{NAME};
        }
        $colval = $self->get_colval ($el, $dbh, $href, $inix, $resix);
        if ( defined $colval && $colval ne '' )  {
            # Add to the SQL if not empty
            $sql  .= "\n\t$colexpr," if ($colexpr);
            $sql1 .= "\n\t$colval,";
        } else {
            my $er = "Value #($inix,$resix) for col $colexpr not found";
            # For INSERT all column values are required
            $self->trace ("* $er\n");
            if ($node->{CARDINALITY} && $node->{CARDINALITY} eq 'OPTIONAL'){
                return 1;
            } else {
                $self->error ("$er\n");
    }   }   }
    if ( $sql )  {
        chop $sql;
        chop $sql1;
        $sql = "INSERT INTO $node->{TABLE} ($sql\n) VALUES ($sql1)";
    }
    return $sql;

}   # -create_insert

# _________________________________________________________________________
#   Construct UPDATE statement
#
sub create_update {
    my $self = shift;       # XMLMessage
    my $node = shift;       # TEMPLATE|CHILD|REFERENCE
    my $dbh = shift;        # Database handle
    my $href = shift;       # Global hash reference
    my $inix = shift || 0;  # Input value set index
    my $resix = shift || 0; # Parent result set index

    $self->trace ("   create_update ($node->{NAME},$inix,$resix)\n");
    my ($el, $colexpr, $sql);
    $self->error ("$node->{NAME}: Cannot UPDATE without TABLE")
            if (!$node->{TABLE});
    # Construct the list of columns with value assignments
    undef $sql;
    foreach ( keys %{$node->{_COLLIST}} ) {
        $el = $node->{_COLLIST}->{$_};
# print "   -el = $el->{NAME}\n";
        $colexpr = $self->get_colval ($el, $href, $dbh, $inix, $resix);
# print "   -colval = $colexpr\n";
        if ( defined $colexpr && $colexpr ne "" )  {
            if ( $el->{EXPR} )  {
                $colexpr = "\n\t" . $el->{EXPR} . " = $colexpr,";
            } else {
                $colexpr = "\n\t" . $el->{NAME} . " = $colexpr,";
            }
            $sql .= $colexpr;
# print "   -sql = $sql\n";
    }   }
    # If anything was created
    if ( $sql )  {
        chop $sql;
        my $where = $self->create_where ($node, $href, $inix, $resix);
        $sql = "UPDATE $node->{TABLE} set $sql where $where";
    }
    return $sql;
}   # -create_update

# _________________________________________________________________________
#   Construct EXEC statement (only works with Sybase/SQL Server I suspect)
#
sub create_exec {
    my $self = shift;       # XMLMessage
    my $node = shift;       # TEMPLATE|CHILD|REFERENCE
    my $dbh = shift;        # Database handle
    my $href = shift;       # Global hash reference
    my $inix = shift || 0;  # Input value set index
    my $resix = shift || 0; # Parent result set index

    my ($el, $val, $sql, $dbdriver);
    if ( !defined $node->{PROC} )  {
        $self->error ("$node->{NAME}: PROC required where ACTION is EXEC");
    }
    # Retrieve the driver name
    # $dbdriver = $dbh->{Driver}->{Name};

    # Collect the parameters
    foreach my $pname ( keys %{$node->{_PARLIST}} ) {
        my $el = $node->{_PARLIST}->{$pname};
        my $val = $self->get_parval($el,$href,$inix,$resix);
        if ( !defined $val ) {
            if ($node->{CARDINALITY} && $node->{CARDINALITY} eq 'OPTIONAL'){
                $self->trace ("Value #($inix,$resix) for $pname not found, "
                        ."but the tag is optional -- skipping");
                return 1;
            } else {
                $self->error (
                    "$el->{NAME}: $pname value #($inix,$resix) not found");
            }
        } else {
            $sql .= " \@$el->{NAME} = $val,"
    }   }
    if ( $sql ) {
        chop ($sql);
    }
    $sql = "EXEC $node->{PROC} $sql";
    return $sql;
}   # -create_exec

#__________________________________________________________________________
#   Execute the SQL for one index pair
#
sub execute_sql {
    my $self = shift;           # XMLMessage
    my $node = shift;           # TEMPLATE|CHILD|REFERENCE
    my $dbh = shift;            # Database handle
    my $href = shift;           # External hash reference for parameters
    my $inix = shift || 0;      # Input vector index
    my $resix = shift || 0;     # Parent result set index

    my ($sql, $sth, $rc, $row);
    $self->trace ("  execute_sql ($node->{NAME},$inix,$resix)\n");
    # Verify that all key values are available
    foreach my $el ( keys %{$node->{_KEYLIST}} ) {
        my $val = $self->get_keyval ($node->{_KEYLIST}->{$el},$href,$inix,$resix);
        if ( !defined $val ) {
            if ($node->{CARDINALITY} && $node->{CARDINALITY} eq 'OPTIONAL'){
                # Skipping the whole thing..
                return 1;
            } else {
                $self->error ("$node->{NAME}: $el value #($inix,$resix) not found");
    }   }   }
    #
    # Construct and execute SQL statement
    #
    # For different ACTIONs
    my $action = $node->{ACTION} ? $node->{ACTION} : 'SELECT';
    for ( $action ) {
        if ( /INSERT/ ) {
            $sql = $self->create_insert ($node,$href,$dbh,$inix,$resix);
            $self->trace ("SQL = $sql\n");
            $rc = $dbh->do ($sql) || croak ("$sql:\n" . $dbh->errstr);
            my %rowh = ();
            if ( $rc > 0 ) {
                $self->process_result($node,$dbh,\%rowh,$href,$inix,$resix);
            }
        } elsif ( /UPDATE/ ) {
            $sql = $self->create_update ($node,$href,$dbh,$inix,$resix);
            $self->trace ("SQL = $sql\n");
            &{$self->{_OnPreDoSQL}} ($dbh) if ($self->{_OnPreDoSQL});
            $rc = $dbh->do ($sql) || $self->error ("$sql\n".$dbh->errstr);
            &{$self->{_OnPostDoSQL}} ($dbh) if ($self->{_OnPostDoSQL});
            my %rowh = ();
            if ( $rc > 0 ) {
                $self->process_result($node,$dbh,\%rowh,$href,$inix,$resix);
            }
        } elsif ( /SAVE/ ) {
            # Logic of the SAVE operation: update if found, insert if not
            $sql = $self->create_select ($node, $href, $dbh, $inix, $resix);
            $self->trace ("SQL = $sql\n");
            $sth = $dbh->prepare ($sql)
                    || $self->error ("$sql\n".$dbh->errstr);
            $rc = $sth->execute() || croak ("$sql\n" . $dbh->errstr);
            if ( $row = $sth->fetchrow_hashref() ) {
                $sql = $self->create_update ($node,$href,$dbh,$inix,$resix);
                $self->trace ("SQL = $sql\n");
                $rc = $dbh->do ($sql)
                        || $self->error("$sql\n".$dbh->errstr);
            } else {
                $sql = $self->create_insert ($node,$href,$dbh,$inix,$resix);
                $self->trace ("SQL = $sql\n");
                $rc = $dbh->do($sql) || $self->error("$sql\n".$dbh->errstr);
            }
            my %rowh = ();
            if ( $rc > 0 ) {
                $self->process_result($node,$dbh,\%rowh,$href,$inix,$resix);
            }
        } elsif ( /EXEC/ ) {
            $sql = $self->create_exec ($node, $href, $dbh, $inix, $resix);
            $self->trace ("SQL = $sql\n");
            $sth = $dbh->prepare ($sql)
                    || $self->error ("$sql:\n" . $dbh->errstr);
            #
            # FIXME: we can analyze if the stored procedure does any selects
            # and fetch only for those. If there are no selects, we probably
            # should follow the INSERT/UPDATE schema and create one result
            # row..
            #
            $rc = $sth->execute() || $self->error ("$sql:\n".$dbh->errstr);
            while ( $row = $sth->fetchrow_hashref() ) {
                $self->process_result ($node,$dbh,$row,$href,$inix,$resix);
            }
        } elsif ( /SELECT/ || !defined $_ ) {
            $sql = $self->create_select ($node, $href, $dbh, $inix, $resix);
            $self->trace ("SQL = $sql\n");
            if ( !length $sql ) {
                $self->error ("ERROR: Unable to create a SQL statement");
            }
            $sth = $dbh->prepare ($sql)
                    || $self->error ("$sql\n" . $dbh->errstr);
            $rc = $sth->execute()
                    || $self->error ("$sql\n" . $dbh->errstr);
            while ( $row = $sth->fetchrow_hashref() ) {
                $self->process_result ($node,$dbh,$row,$href,$inix,$resix);
            }
        } else {
            $self->error ("$_: Unsupported action");
        }
    }

}   # -execute_sql

#__________________________________________________________________________
#   Function to be inoked per retrieved row
#   Adds 2 pseudo-columns to the row:
#       ->{_INIX}
#       ->{_RESIX}
#
sub process_result {
    my $self = shift;           # XMLMessage
    my $node = shift;           # TEMPLATE|CHILD|REFERENCE
    my $dbh = shift;            # DBI database handle
    my $results = shift;        # Result row hash reference
    my $href = shift;           # Global hash reference
    my $inix = shift || 0;      # Input value set index
    my $resix = shift || 0;     # Parent result set index

    my ($colname, $val, $el);

    # Collect the results on a per-colunm basis
    foreach $colname ( keys %{$node->{_COLLIST}} ) {
        $el = $node->{_COLLIST}->{$colname};
        if ( !defined $results->{$colname} )  {
            $val = $self->get_colval ($el, $dbh, $href, $inix, $resix);
            # De-format default values..
            if ( defined $val && $val =~ /^\'(.*)\'$/ ) {
                $val = $1;
                $val =~ s/\'\'/'/g;
            } elsif ( defined $val &&  $val =~ /^\"(.*)\"$/ ) {
                $val = $1;
                $val =~ s/\"\"/"/g;
            }
            if ( 'NULL' eq uc($val) ) {
                $val = undef;
            }
            $results->{$colname} = $val;
    }   }
    # Now look from the results' perspective
    foreach $colname ( keys %$results ) {
        $results->{$colname} =~ s/\s*$// if (defined $results->{$colname});
        my $col = $node->{_COLLIST}->{$colname};
        if ( !$col )  {  # Column does not exist
            # Should we tolerate undefined results?
            if ( $node->{TOLERANCE} && $node->{TOLERANCE} eq 'CREATE'
                    && $colname !~ /^_/ )  {
                $col = new "$PACKAGE::Element::COLUMN";
                $col->{NAME} = $colname;
                $col->{_PARENT_TAG} = $node;
                push @{$node->{Kids}}, $col;
                $self->{_COLLIST}->{$colname} = $col;
            } elsif ( $node->{TOLERANCE} && $node->{TOLERANCE} eq 'REJECT' ) {
                $self->error (
                    "ERROR: Unknown column $colname in the result set");
            # } elsif ( $self->{TOLERANCE}  eq 'IGNORE' )  {
            } else {    # IGNORE by default
                delete $$results{$colname};
        }   }
    }

    # And push it into results array
    # ... BUT COPY FIRST ...
    my $rescopy;
    foreach $colname ( keys %$results ) {
        $rescopy->{$colname} = $results->{$colname};
        if ( $rescopy->{$colname} &&
                $node->{_COLLIST}->{$colname}->{BLTIN} ) { # Builtin
            my $bltin = $node->{_COLLIST}->{$colname}->{BLTIN};
            $self->trace ("BUILTIN func: $bltin\n");
            my $cmd = '$rescopy->{$colname} = &' . $bltin . ';';
            @_ = ($self,$node,$rescopy->{$colname});
            $self->trace ("BUILTIN: $cmd\n");
            eval $cmd;
            $self->error("Error in BUILT-IN $bltin of $colname: $@") if($@);
        }
    }
    $rescopy->{_INIX} = $inix;
    $rescopy->{_RESIX} = $resix;
    push @{$node->{_RESULTS}}, $rescopy;

}   # -process_result

#__________________________________________________________________________
#   Execute the SQL for all parent results and input values
#
sub exec {
    my $self = shift;   # XMLMessage
    my $node = shift;   # TEMPLATE|CHILD|REFERENCE
    my $dbh = shift;    # Database handle
    my $href = shift;   # External hash reference for parameters

    $self->trace ("\n  exec $node->{NAME}\n");
    my $success = 1;
    my $papa = $node->{_PARENT_TAG};

    my $nres;
    if ( $papa ) {
        $nres = $papa->{_RESULTS} ? scalar @{$papa->{_RESULTS}} : 0;
    } else {
        # No parent tag -- pick up the key #0 and count number of values.
        my @keynames = defined $node->{_KEYLIST}
                ? keys %{$node->{_KEYLIST}} : ();
        my $key0 = scalar @keynames
                ? $node->{_KEYLIST}->{$keynames[0]}->{PARENT_NAME}
                        ? $node->{_KEYLIST}->{$keynames[0]}->{PARENT_NAME}
                        : $keynames[0]
                : undef;
        $nres = defined $key0
                ? scalar @{$href->{$key0}} : 1; # No keys -- execute once
    }

    my $nval = $node->{_INVALUES} ? scalar @{$node->{_INVALUES}} : 0;
    my $inix = 0;
    $self->trace ("  nval = $nval\n");
    do {    # Execute once with no input values
        for ( my $resix=0; $resix<$nres; $resix++ ) {
            # But not without results
            $success &= $self->execute_sql($node,$dbh,$href,$inix,$resix);
        }
    } while ( ++$inix < $nval );

    $success;
}   # -exec

#__________________________________________________________________________
#   Recursively execute SQL statements for all
#
sub rexec {
    my $self = shift;   # XMLMessage
    my $dbh = shift;    # database handle
    my $href = shift;   # External hash reference for parameters
    my $node = shift;   # TEMPLATE|CHILD|REFERENCE

    $node = $self->{_Template} if (!$node);
    $self->trace ("\nrexec $node->{NAME}\n");
    my ($el, $success);
    if ( !$dbh ) {
        #
        # FIXME: Allow for NODBH invocation
        #
        $self->error ("No database handle");
    }
    # Execute for yourself
    $success = $self->exec ($node, $dbh, $href);
    foreach $el ( @{$node->{'Kids'}} ) {
        if ( (ref $el) =~ /::REFERENCE$/ || (ref $el) =~ /::CHILD$/ ) {
            $success &= $self->rexec ($dbh, $href, $el);
    }   }

    $success;
}   # -rexec

#__________________________________________________________________________
#   Output the message
#
sub output_message {
    my $self = shift;   # XMLMessage

    #if ( $self->{TYPE} eq 'XML' ) {
        return $self->output_xml();
    #} else {
    #    print $self->{TYPE} . ": not implemented\n"
    #}
}

#__________________________________________________________________________
#   Should have executed prior to this
#
#   FIXME: Prints multuple childs
#
#
sub output_xml {
    my $self = shift;           # XMLMessage
    my $level = shift || 0;     # Level
    my $resix = shift || 0;     # Parent result set index
    my $node = shift || $self->{_Template}; # TEMPLATE|CHILD|REFERENCE

    my ($r, $i, $j, $el, $el1, $res, $rref, $xml);
    $xml = "";  # Target string

    # see if there's anything to output
    my $found = 0;
    foreach (@{$node->{_RESULTS}}) {
        if ( $_->{_RESIX} == $resix ) {
            $found = 1;
    }   }
    if ( !$found ) {
        if ( (ref $node) =~ /::TEMPLATE$/ ) {   # Always print the template
            for ( $j=0;$j<$level;$j++ ) { $xml .= "  "; }
            $xml .= "<$node->{NAME} />\n";
            return $xml;
        } else {                                # ... but nothing else!
            return $xml;
    }   }
    $i = 0; # Initial input value. The loop will execute once always
    do {
        for ( $r=0; $node->{_RESULTS}->[$r]; $r++ ) {   # $r is resix for kids
            # >>>>>>>>>>
  $rref = $node->{_RESULTS}->[$r];
  if ( $rref->{_INIX} == $i && $rref->{_RESIX} == $resix
        # FIXME: this is a hack...
        && !$rref->{_PRINTED} ) {
      # Output the tag
      for ( $j=0;$j<$level;$j++ ) { $xml .= "  "; }
      $xml .= "<$node->{NAME}";
      # Output columns with the face of 'ATTRIBUTE' as attributes
      foreach my $elname ( keys %{$node->{_COLLIST}} ) {
          $el = $node->{_COLLIST}->{$elname};
          if ( $el->{FACE} && $el->{FACE} eq 'ATTRIBUTE' ) {
              if (defined $rref->{$el->{NAME}} && $rref->{$el->{NAME}} ne ''){
                  $xml .= " $el->{'NAME'}=\"" .
                  HTML::Entities::encode($rref->{$el->{NAME}},'&<>"').'"';
      }   }   }
      $xml .= ">\n";
      # Output the rest of the stuff
      foreach $el ( @{$node->{'Kids'}} ) {
          if ( (ref $el) =~ /::COLUMN$/ &&
                  (!defined $el->{FACE} || $el->{FACE} eq 'TAG') ) {
              if ( !$el->{'HIDDEN'} ) {
                  for ( $j=0;$j<$level+1;$j++ ) { $xml .= "  "; }
                  if ( defined $rref->{$el->{NAME}}
                          && $rref->{$el->{NAME}} ne '' ) {
                      $xml .= "<$el->{'NAME'}>"
                      . HTML::Entities::encode($rref->{$el->{NAME}},"&<>")
                      . "</$el->{'NAME'}>\n";
                  } else {
                      $xml .= "<$el->{'NAME'} />\n";
                  }
              }
          } elsif ((ref $el)=~ /::REFERENCE$/ || (ref $el)=~ /::CHILD$/) {
              my $niter  = (defined $el->{_INVALUES})
                    ? scalar @{$el->{_INVALUES}}
                    : 0;
              for ( $i=0; $i<scalar @{$node->{_RESULTS}}; $i++ ) {
                  $j = 0;
                  do {
                      $xml .= $self->output_xml ($level+1,$r,$el);
                  } while ( $j++ < $niter );
              }
          }
      }
      for ( $j=0;$j<$level;$j++ ) { $xml .= "  "; }
      $xml .= "</$node->{'NAME'}>\n";
      # FIXME: this is the second part of the hack.. See above..
      $rref->{_PRINTED} = 1;
  }
            # >>>>>>>>>>
        }   ##for $r
    } while ( $node->{_INVALUES}->[$i++] );

    return $xml;
}   # -output_xml

#__________________________________________________________________________
#   Test BUILT-IN
#
sub t_bltin {
    print "t_bltin:";
    foreach (@_) {
        print "\t$_\n";
    }
    return "returned by t_bltin";
}

#__________________________________________________________________________
#   Fix the GMTIME values
#
sub fix_gmdatetime {
    my $self = shift;           # XMLMessage
    my $node = shift;           # TEMPLATE | CHILD | REFERENCE
    my $val = shift || undef;

    if ( !defined $val ) {
        return undef;
    }
    my $direction = $node->{_PARENT_TAG}->{ACTION}
        ? $node->{_PARENT_TAG}->{ACTION} eq 'SELECT'
            ? 'TOGMT'
            : 'FROMGMT'
        : 'TOGMT';
    my $curfmt = '';
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    my $hmon = { 'Jan' => 0, 'Feb' => 1, 'Mar' => 2, 'Apr' => 3,
        'May' => 4, 'Jun' => 5, 'Jul' => 6, 'Aug' => 7,
        'Sep' => 8, 'Oct' => 9, 'Nov' => 10, 'Dec' => 11
    };
    if ($val =~ /^\s*(\d{4})\/(\d{1,2})\/(\d{1,2})\s*(\d{1,2}):(\d{1,2})/ ||
            $val =~ /^\s*(\d{4})-(\d{1,2})-(\d{1,2})\s*(\d{1,2}):(\d{1,2})/
            ) {
        # E.g. 2000-3-21 12:05
        $curfmt = 'GMT';    # SES/SIS GMT
    } elsif ( $val =~  /^\s*(\d{8})\s*(\d{4})/ ) {
        # E.g. 20000321 1205
        $curfmt = 'GMTSHORT';   # Mark sends it like this..
    } elsif ( $val =~
            /^\s*(\D{3})\s*(\d{1,2})\s*(\d{4})\s*(\d{1,2}):(\d{2})(\D{2})/
            ) {
        # E.g. Mar 21 2000 12:05:46:350PM
        $curfmt = 'SYBASE'; # As delivered by the Sybase DB engine
    }
    if ( $direction eq 'TOGMT' && $curfmt eq 'SYBASE' ) {
        # - Transform from SYBASE to GMT
        # This time is received from database and it's local,
        # most probably according to the TZ environment variable
        # - Calculate the time difference to GMT
        my $ctime = time();
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
                = gmtime($ctime);
        my $time_t = POSIX::mktime ($sec,$min,$hour,$mday,$mon,$year);
        my $tdiff = $ctime - $time_t;
        ($year,$mon,$mday,$hour,$min) = ($3, $1, $2, $4, $5);
        $mon = $hmon->{$mon} ? $hmon->{$mon} : 0;
        $hour += 12 if ( $6 && $6 eq 'PM' && $hour != 12 );
        $year -= 1900;
        $time_t = POSIX::mktime (0,$min,$hour,$mday,$mon,$year);
        $val = POSIX::strftime "%Y/%m/%d %H:%M", gmtime($time_t-$tdiff);
        # print "Date = ", POSIX::ctime($time_t);
    } elsif ( $direction eq 'FROMGMT' && $curfmt eq 'GMT' ) {
        # - Transform from GMT to SYBASE
        ($year,$mon,$mday,$hour,$min) = ($1, $2, $3, $4, $5);
        $mon--;
        $year -= 1900;
        my $time_t = POSIX::mktime (0,$min,$hour,$mday,$mon,$year);
        if ( $node->{DATATYPE} eq 'DATE' ) {
            $val = POSIX::strftime "%b %d %Y", localtime($time_t);
        } elsif ( $node->{DATATYPE} eq 'TIME' ) {
            $val = POSIX::strftime "%I:%M", localtime($time_t);
        } else {
            $val = POSIX::strftime "%b %d %Y %I:%M:00:000%p",
                    localtime($time_t);
        }
    } elsif ( $direction eq 'FROMGMT' && $curfmt eq 'GMTSHORT' ) {
        # - Transform from GMTSHORT to SYBASE
        my ($ymd,$hmi) = ($1,$2);
        $year = substr ($ymd,0,4);
        $mon  = substr ($ymd,4,2);
        $mday = substr ($ymd,6,2);
        $hour = substr ($hmi,0,2);
        $min  = substr ($hmi,2,2);
        $mon--;
        $year -= 1900;
        my $time_t = POSIX::mktime (0,$min,$hour,$mday,$mon,$year);
        if ( $node->{DATATYPE} eq 'DATE' ) {
            $val = POSIX::strftime "%b %d %Y", localtime($time_t);
        } elsif ( $node->{DATATYPE} eq 'TIME' ) {
            $val = POSIX::strftime "%I:%M:00:000%p", localtime($time_t);
        } else {
            $val = POSIX::strftime "%b %d %Y %I:%M:00:000%p",
                    localtime($time_t);
        }
    }   # Otherwise don't touch
    return $val;
}   ##fix_gmdatetime



1;
# -package DBIx::XMLMessage;



# _________________________________________________________________________
#   Tag Prototype
#
package DBIx::XMLMessage::Element;

use strict;
use vars qw (@ISA %EXPORT_TAGS $VERSION @rattrs);
$VERSION  = '0.01';
@ISA = qw ( Exporter );
%EXPORT_TAGS = ('elements' => [ 'VERSION', '%TEMPLATE::',
        '%REFERENCE::', '%CHILD::', '%KEY::', '%COLUMN::', '%PARAMETER::']);
Exporter::export_ok_tags ('elements');
@rattrs = qw (NAME);
1;

#__________________________________________________________________________
#   Tag TEMPLATE
#
package DBIx::XMLMessage::TEMPLATE;

use vars qw (@ISA %EXPORT_TAGS @rattrs @oattrs @rkids @okids);
@ISA = qw (DBIx::XMLMessage::Element);
@rattrs = qw (NAME VERSION TYPE);
@oattrs = qw (
    ACTION
    DEBUG
    PROC
    RTRIMTEXT
    TABLE
    TOLERANCE
    _CHILIST
    _COLLIST
    _KEYLIST
    _PARENT_TAG
    _PARLIST
    _REFLIST
);
@okids  = qw (COLUMN REFERENCE CHILD PARAMETER KEY);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
1;

#__________________________________________________________________________
#   Tag KEY
#
package DBIx::XMLMessage::KEY;
use vars qw (@ISA %EXPORT_TAGS @rattrs @oattrs @rkids @okids);
@ISA = qw (DBIx::XMLMessage::Element);
@rattrs = qw (NAME);
@oattrs = qw (_PARENT_TAG DATATYPE RTRIMTEXT DEFAULT PARENT_NAME);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
1;

#__________________________________________________________________________
#   Tag COLUMN
#
package DBIx::XMLMessage::COLUMN;
use vars qw (@ISA %EXPORT_TAGS @rattrs @oattrs @rkids @okids);
@ISA = qw (DBIx::XMLMessage::Element);
@rattrs = qw (NAME);
@oattrs = qw (
    ACTION
    BLTIN
    CARDINALITY
    DATATYPE
    DEBUG
    DEFAULT
    EXPR
    FACE
    GENERATE_PK
    HIDDEN
    RTRIMTEXT
    TOLERANCE
    _PARENT_TAG
);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
1;

#__________________________________________________________________________
#   Tag REFERENCE
#
package DBIx::XMLMessage::REFERENCE;
use vars qw (@ISA %EXPORT_TAGS @rattrs @oattrs @rkids @okids);
@ISA = qw (DBIx::XMLMessage::Element);
@rattrs = qw (NAME);
@oattrs = qw (
    ACTION
    CARDINALITY
    DEBUG
    PROC
    RTRIMTEXT
    TABLE
    TOLERANCE
    WHERE_CLAUSE
    _CHILIST
    _COLLIST
    _KEYLIST
    _PARENT_TAG
    _PARLIST
    _REFLIST
);
@okids = qw (COLUMN REFERENCE CHILD PARAMETER KEY);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
1;

#__________________________________________________________________________
#   Tag CHILD
#
package DBIx::XMLMessage::CHILD;
use vars qw (@ISA %EXPORT_TAGS @rattrs @oattrs @rkids @okids);
@ISA = qw (DBIx::XMLMessage::Element);
@rattrs = qw (NAME);
@oattrs = qw (
    ACTION
    CARDINALITY
    DEBUG
    MAXROWS
    PROC
    RTRIMTEXT
    TABLE
    TOLERANCE
    WHERE_CLAUSE
    _CHILIST
    _COLLIST
    _KEYLIST
    _PARENT_TAG
    _PARLIST
    _REFLIST
);
@okids = qw (COLUMN REFERENCE CHILD PARAMETER KEY);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
1;

#__________________________________________________________________________
#   Tag PARAMETER
#
package DBIx::XMLMessage::PARAMETER;
use vars qw (@ISA %EXPORT_TAGS @rattrs @oattrs @rkids @okids);
@ISA = qw (DBIx::XMLMessage::Element);
@rattrs = qw (NAME);
@oattrs = qw (
    CARDINALITY
    DATATYPE
    DEFAULT
    EXPR
    RTRIMTEXT
    _PARENT_TAG
);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
1;

__END__

=head1 NAME

DBIx::XMLMessage - XML Message exchange between DBI data sources

=head1 SYNOPSIS

=head2 OUTBOUND MESSAGE

    #!/usr/bin/perl

    use DBI;
    use DBIx::XMLMessage;

    # Template string
    my $tpl_str =<< "_EOT_";
    <?xml version="1.0" encoding="UTF-8" ?>
    <TEMPLATE NAME='SysLogins' TYPE='XML' VERSION='1.0' TABLE='syslogins'>
    <KEY NAME='suid' DATATYPE='NUMERIC' PARENT_NAME='OBJECT_ID' />
    <COLUMN NAME='LoginId' EXPR='suid' DATATYPE='NUMERIC' />
    <COLUMN NAME='PasswordDate' EXPR='pwdate' DATATYPE='DATETIME'
        BLTIN="fix_gmdatetime" />
    <CHILD NAME='SysUsers' TABLE='sysusers'>
        <KEY NAME='suid' PARENT_NAME='LoginId' DATATYPE='NUMERIC' />
        <COLUMN NAME='UserId' EXPR='uid' DATATYPE='NUMERIC' />
        <COLUMN NAME='UserName' EXPR='name' />
    </CHILD>
    </TEMPLATE>
    _EOT_
    my $msg = new DBIx::XMLMessage ('TemplateString' => $tpl_str);
    my $ghash = { 'OBJECT_ID' => [ 1, 2 ] };
    my $dbh = DBI->connect('dbi:Sybase:server=x;database=master','sa','secret');
    $msg->rexec ($dbh, $ghash);

    print "\n\n", $msg->output_xml(0,0);
    print "\n\n", $msg->output_xml(0,1);


=head2 INBOUND MESSAGE

    #!/usr/bin/perl

    use DBI;
    use DBIx::XMLMessage;

    my $template_xml =<< "_EOD1_";
    <?xml version="1.0" encoding="UTF-8" ?>
    <TEMPLATE NAME='SysLogins' TYPE='XML' VERSION='1.0' TABLE='syslogins'
        ACTION='SAVE'>
    <KEY NAME='suid' DATATYPE='NUMERIC' PARENT_NAME='OBJECT_ID' />
    <COLUMN NAME='LoginId' EXPR='suid' DATATYPE='NUMERIC' />
    <COLUMN NAME='PasswordDate' EXPR='pwdate' DATATYPE='DATETIME'
        BLTIN="fix_gmdatetime" />
    <CHILD NAME='SysUsers' TABLE='sysusers'>
        <KEY NAME='suid' PARENT_NAME='LoginId' DATATYPE='NUMERIC' />
        <COLUMN NAME='UserId' EXPR='uid' DATATYPE='NUMERIC' />
        <COLUMN NAME='UserName' EXPR='name' />
    </CHILD>
    </TEMPLATE>
    _EOD1_

    my $message_xml =<< "_EOD2_";
    <?xml version="1.0" encoding="UTF-8"?>
    <SysLogins>
    <LoginId>1</LoginId>
    <PasswordDate>1999/08/17 08:31</PasswordDate>
    <SysUsers>
        <UserId>1</UserId>
        <UserName>sa</UserName>
    </SysUsers>
    </SysLogins>
    _EOD2_

    my $xmlmsg = new DBIx::XMLMessage ('TemplateString' => $template_xml);
    my $msgtype = $xmlmsg->input_xml($message_xml);
    my $ghash = {
        'OBJECT_ID' => [ 1 ]
    };
    $xmlmsg->populate_objects ($ghash);

    my $dbh = DBI->connect('dbi:Sybase:server=x;database=master','sa','secret');
    $xmlmsg->rexec ($dbh, $ghash);
    print $xmlmsg->output_message();


=head1 DESCRIPTION

The package maintains simple XML templates that describe object structure.

The package is capable of generating SQL statements based on these templates
and executing them against DBI data sources. After executing the SQL, the
package formats the data results into XML strings. E.g. the following simple
template

    <TEMPLATE NAME='SysLogins' TYPE='XML' VERSION='1.0' TABLE='syslogins'
        ACTION='SAVE'>
    <KEY NAME='suid' DATATYPE='NUMERIC' PARENT_NAME='OBJECT_ID' />
    <COLUMN NAME='LoginId' EXPR='suid' DATATYPE='NUMERIC' />
    </TEMPLATE>

being executed with key value = 1, will be tranlated into this SQL:

SELECT suid LoginId FROM syslogins where suid = 1

and the result will be formatted into this XML string:

    <SysLogins>
        <LoginId>1<LoginId>
    </SysLogins>

Inbound messages can be processed according to the same kind of templates
and the database is updated accordingly. Templates are capable of defining
the SQL operators, plus new SAVE operation which is basically a combination
of SELECT and either INSERT or UPDATE depending on whether the record was
found by the compound key value or not.

=head1 SALES PITCH

This package allows for objects exchange between different databases. They
could be from different vendors, as long as they both have DBD drivers. In
certain cases it is even possible to exchange objects between databases with
different data models. Publishing of databases on the web could
potentially be one of the applications as well.

=head1 TEMPLATE TAGS

=head2 TEMPLATE

This is manadatory top-level tag. It can correspond to a certain table and
be processed just like table-level REFERENCE and CHILD attributes described
below. Some of TEMPLATE attributes are related to the whole template (e.g.
TYPE or VERSION) while others desribe the table ti's based on (e.g. TABLE)

If the TABLE attribute is defined, the generated SQL is going to run against
some table. Otherwise a SQL with no table will be generated. This only makes
sense for outbound messages and only possible on certain engines, like
Sybase. Also, the immediate child columns should contain constants only for
apparent reasons.

=head2 REFERENCE

REFERENCE is a table-level tag. It's meant to represent a single record from
another table that's retrieved by unique key. E.g. if my current table is
EMPL then DEPARTMENT would be a REFERENCE since employee can have no more
than one departament.

=head2 CHILD

This tag meant to represent a number of child records usually retrieved by
a foreign key value (probably primary key of the current table). Right now
there's no difference in processing between CHILD and REFERENCE, but it may
appear in the future releases.

=head2 COLUMN

This tag is pretty self-explanatory. Each COLUMN tag will appear on the
SELECT, INSERT or UPDATE list of the generated SQL.

=head2 KEY

Key represents linkage of this table's records to the parent table. All
KEY's will appear on the WHERE clause as AND components. This way of linkage
is typical for most of relational systems and considered to be a good style.
I guess it shouldn't be much of a restriction anyway. If it gets that, you
could try tweak up the WHERE_CLAUSE attribute..

=head2 PARAMETER

This tag represents a parameter that will be passsed to a stored procedure.
Currently, only Sybase-style stored procedures are supported, i.e.

exec proc_name @param_name = 'param_value', ...

Fixes for Oracle, DB2 and Informix are welcome..



=head1 TEMPLATE TAG ATTRIBUTES

=head2 NAME

    Applicable to:  All template tags
    Required for:   All template tags

NAME is the only required attribute for all of the template tags. The main
purpose of it is to specify the tag name as it will appear in the resulting
XML document. Also, depending on the template tag type (COLUMN, PARAMETER
and KEY) it may serve as default value for EXPR discussed below. Here's a
small example of how it works. If my column is represented in the template
like this:

    <COLUMN NAME='ObjectId' />

the resulting SQL will contain

    SELECT ObjectID, ...

whereas if I have

    <COLUMN NAME='ObjectId' EXPR='igObjectId' />

it will generate the following SQL:

    SELECT igObjectId ObjectID, ...

I.e. in the latter example, NAME used as an alias and EXPR as a real
database column name. The column in the first example has no alias.


=head2 ACTION

    Applicable to:  TEMPLATE, REFERENCE, CHILD
    Required for:   None

Possible values for this attibute are SELECT, INSERT, UPDATE, EXEC and SAVE.
If action is not provided, it is assumed that t he action should be SELECT.
The first 4 values correspond to SQL data management operators (EXEC is
vendor-specific and represents execution of a stored procedure). The fifth
value, SAVE, is basically a combination of SELECT and either INSERT or
UPDATE, depending on whether the record was found by the compound key value
or not. This often helps to avoid usage of complicated stored procedures
with primary key generation and keep things generic and scalable. Primary
key generation issue is addressed separately by using of the GENERATE_PK
attribute (see below).

=head2 BLTIN

    Applicable to:  COLUMN
    Required for:   None

Represents a perl built-in function. before invocation of this subroutine
the package prepares array @_ and makes it visible to the built-in function.
The 3 arguments received by the built-in are:
    $self   -  DBIx::XMLMessage object
    $node   -  Correspondent DBIx::XMLMessage::COLUMN object. You
               can use it to obtain other column attributes, e.g.
               $node->{DATATYPE}
    $value  -  The column value

Meaning of the value depends on direction of the message, i.e. whether the
message is inbound or outbound. In case of inbound message, this is the
value received by the package from outside world; if the message is inbound
then this is the value selected from database. There's one built-in function
that comes with the package -- fix_gmdatetime. It converts date and time to
GMT for outbound messages and from GMT to the database date/time for inbound
messages. Just add one attribute to your datetime column:

    ... BLTIN="fix_gmdatetime" ...

=head2 CARDINALITY

    Applicable to:   KEY, PARAMETER, REFERENCE, CHILD
    Required for:    None
    Possible values: REQUIRED, OPTIONAL
    Default:         REQUIRED

This parameter has different meaning for different element types. Optional
KEYs and PARAMETERs allow to proceed execution if the value for it was not
found at some point of execution. Optional CHILDs and REFERENCEs will be
skipped from execution, and hence from output, if the package failed to
collect all the key values.

=head2 DATATYPE

    Applicable to:   KEY, PARAMETER, COLUMN
    Required for:    None
    Possible values: CHAR, VARCHAR, VARCHAR2, DATE, DATETIME, NUMERIC
    Default:         CHAR

This attribute loosely corresponds to the database column type. The only
processing difference in the core package is quoting of the non-numeric
datatypes, particularly those containign substrings CHAR, DATE or TIME.
The built-in fix_gmdatetime utilizes this attribute more extensively.

=head2 DEBUG

Recognized but not currently supported

=head2 DEFAULT

    Applicable to:   PARAMETER, COLUMN
    Required for:    None
    Possible values: Any string or number

This attribute allows to provide a default value for COLUMNs and PARAMETERS.
Please note that default values are not being formatted, so they have to
represent the literal value. E.g. if you want to provide a string DEFAULT
it would look somewhat like this:
    ... DEFAULT = "'UNKNOWN'"


=head2 EXPR

    Applicable to:  All template tags
    Required for:   None

For COLUMN and KEY this attribute represents the actual database column name
or a constant. For PARAMETER


=head2 FACE

    Applicable to:   COLUMN
    Required for:    None
    Possible values: ATTRIBUTE, TAG
    Default:         TAG

This attribute allows to output certain columns as attributes, as opposed
to the default TAG-fasion output. Since it's not supported for inbound
messages yet, usage of this feature is not recommended.


=head2 GENERATE_PK

    Applicable to:   COLUMN
    Required for:    None
    Possible values: HASH, SQL returning one value or name

This attribute allows you to specify how to generate primary key values. You
have 2 options here:

1. You can write your own Perl function, put its reference to the global
hash under the name of the table for which you intend to generate primary
key values and provide the value of 'HASH' as the GENERATE_PK value

2. You can put the generating SQL block/statement into the GENERATE_PK value


=head2 HIDDEN

    Applicable to:   COLUMN

Indicates that the column will be excluded from the output. This attribute
only makes sense for outbound messages.

=head2 MAXROWS

Currently not supported. In future, intends to limits the number of selected
rows.

=head2 PARENT_NAME

    Applicable to:   KEY

Indicates the name of the tag one level up to which this one tag is
corresponding. E.g.

    ...
    <COLUMN NAME='OBJECT_ID'/>
    <REFERENCE ...>
        <KEY NAME='nOrderId' PARENT_NAME='OBJECT_ID'/>
    </REFERENCE>

This feature is a workaround allowing to have two columns descending from
the same parent column at the same level. There was some other prolem it
was helping to resolve, but I forgot what it was ;^)


=head2 PROC

    Applicable to:   TEMPLATE, REFERENCE, CHILD

Used in conjunction with ACTION='PROC'. Defines the name of the stored
procedure to invoke.

=head2 RTRIMTEXT

Currently not supported. The package does automatic right-trimming for all
the character data.

=head2 TABLE

Name of the table against which the SQL will be run.

=head2 TOLERANCE

    Applicable to:   TEMPLATE, REFERENCE, CHILD
    Possible values: IGNORE, CREATE, REJECT
    Default:         IGNORE

Allows to adjust package behaviour when SQL execution produces unexpected
result columns. E.g. if there's a stored procedure that will return the
results for your message, you can omit describing of all the resulting
COLUMNS in the template and instead specify
    ... TOLERANCE='CREATE'
Whatever columns are returned by the stored procedure (Sybase & MS SQL) will
be added on-the-fly and available for the output.


=head2 WHERE_CLAUSE

Additional where clause. Added as an AND component at the end of generated
where clause.


=head1 METHODS

=head2 new

    my $xmsg = new DBIx::XMLMessage (
        [ _OnError => $err_coderef, ]
        [ _OnTrace => $trace_coderef, ]
        [ Handlers => $expat_handlers_hashref, ]
        [ TemplateString => $xml_template_as_a_string, ]
        [ TemplateFile => $xml_template_file_name, ]
    )

You can specify either TemplateString or TemplateFile, but not both. If any
of those specified, the template will be parsed.

=head2 set_handlers

    $xmsg->set_handlers ($expat_handlers_hashref)

Set additional expat handlers, see XML::Parser::Expat. Normally you won't
use this. The only case I could think of is processing of encoding..

=head2 prepare_template

    $xmsg->prepare_template ($template_xml_string)

This method can be invoked if the template was not specified in the 'new'
method invocation.

=head2 prepare_template_from_file

    $xmsg->prepare_template_from_file ($template_file_name)

Same as above, but template is read from file here.

=head2 input_xml

    $xmsg->input_xml ($inbound_xml_message_content)

Parse an inbound XML message. The values form this message will be used to
fill in COLUMNS and PARAMETERS. The structure of this message should comply
with template. Uses Tree parsing style.

=head2 input_xml_file

    $xmsg->input_xml_file ($inbound_xml_message_file_name)

Same as above, but the XML message is read from a file.

=head2 populate_objects

    $xmsg->populate_objects ($global_hash_ref [, $matching_object
        [, $tag_name [, $tag_content, [$parameter_index]]]])

This method is trying to stuff the existing template with the inbound
message previously parsed by one of the 'input_xml' methods. The only
mandatory attribute is global hash reference, which has to contain key
values for the topmost tag TEMPLATE.

=head2 rexec

    $xmsg->rexec ($dbh, $global_hash_ref)

This method is running the created query against a DBI/DBD source and fills
in the template with results in order to make them available for subsequent
output_message call. In case of INSERT/UPDATE operations only key values
will be filled in.

=head2 output_message

This method returns a string with query results in XML format suitable for
printing or whatever manupulations seem appropriate.


=head1 SEE ALSO

    XML::Parser
    XML::Parser::Expat

=head1 AUTHORS

  Andrei Nossov <andrein@andrein.com>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut