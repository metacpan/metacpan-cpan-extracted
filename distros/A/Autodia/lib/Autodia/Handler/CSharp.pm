package Autodia::Handler::CSharp;
require Exporter;
use strict;

use vars qw($VERSION @ISA @EXPORT $DEBUG $FILENAME $LINENO);
use Autodia::Handler;
@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;

our $PARAM_REGEX = qr/[\[\]<>\w\,\.\s\*=\"\']*/;
our $METHOD_TYPES = qr/static|virtual|override|const|event/;
our $PRIVACY = qr/public|private|protected/;
our $CLASS = qr/class|interface/;
our $TYPE = qr/[\w,<>]+/;


#---------------------------------------------------------------

#####################
# Constructor Methods

# new inherited from Autodia::Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub debug {
    print "$FILENAME:$LINENO - @_\n";
}

sub _parse {
    my $self     = shift;
    my $fh       = shift;
    my $filename = shift;
    $FILENAME = $filename;
    $FILENAME =~ s{.*/}{};
    $LINENO = 0;

    my $Diagram = $self->{Diagram};

    my $Class;

    $self->{current_package} = $filename;
    $self->{namespace}       = "";
    $self->{privacy}         = 0;
    $self->{comment}         = 0;
    $self->{in_class}        = 0;
    $self->{in_declaration}  = 0;
    $self->{in_method}       = 0;
    $self->{brace_depth}     = 0;

    debug("processing file");

    # parse through file looking for stuff
    while (<$fh>) {
      LINE: {
            $LINENO++;

            chomp( my $line = $_ );
            last LINE if ( $self->_discard_line($line) );
            
            # This strips out all the template spaces, which makes it easier to parse
            while($line =~ s/(<[^>]*)\s+([^>]*>)/$1$2/g) {
                debug("Stripping templates: $line");
                next;
            }

            # we've entered a top level namespace
            if ( $line =~ m/^\s*namespace\s+([\w\.]+)/ ) {
                $self->{namespace} = $1;
                debug("Namespace: $1");
                last LINE;
            }

            # check for class declaration
            if ( $line =~ m/^\s*($PRIVACY)?\s*($CLASS)\s+(\w+)/ ) {
                my $classname = ($3) ? $3 : $2;

                $self->{in_class}   = 1;
                $self->{privacy}    = "private";
                $self->{visibility} = 1;
                $classname =~ s/[\{\}]//g;

		last if ($self->skip($classname));
                # we want to add on namespace
                #if ($self->{namespace}) {
                #    $classname = "$self->{namespace}.$classname";
                #}
                debug("Class: $classname");

                $Class = Autodia::Diagram::Class->new($classname);
		my $exists = $Diagram->add_class($Class);
		$Class = $exists if ($exists);

                # handle superclass(es)
                if ( $line =~ m/^\s*($PRIVACY)?\s*($CLASS)\s+\w+\s*\:\s*(.+)\s*/ )
                {
                    my @superclasses = split( /\s*,\s*/, $3 );
                    foreach my $super (@superclasses) {
                        $super =~ s/^\s*(\w+\s+)?([A-Za-z0-9\_]+)\s*$/$2/;
                        debug("Super Class: $super");
                        my $Superclass =
                          Autodia::Diagram::Superclass->new($super);
                        my $exists_already =
                          $Diagram->add_superclass($Superclass);
                        if ( ref $exists_already ) {
                            $Superclass = $exists_already;
                        }
                        my $Inheritance =
                          Autodia::Diagram::Inheritance->new( $Class,
                            $Superclass );
                        $Superclass->add_inheritance($Inheritance);
                        $Class->add_inheritance($Inheritance);
                        $Diagram->add_inheritance($Inheritance);
                    }
                }
                last LINE;
            }

# check for end of class declaration
# TODO: this won't ever trigger with C#, not sure the best way to close things here.
            if ( $self->{in_class} && ( $line =~ m|^\s*\}\;| ) ) {

                #	      print "found end of class\n";
                $self->{in_class} = 0;
                $self->{privacy}  = 0;
                last LINE;
            }

            # because the rest of this requires that we are in a class
            last LINE if ( not $self->{in_class} );

            if ( $line =~ m/^\s*protected\s*/ ) {
                debug("protected variables/classes");
                $self->{privacy}    = "protected";
                $self->{visibility} = 2;
                $self->_parse_private_things( $line, $Class );
                last LINE;
            }
            elsif ( $line =~ m/^\s*private\s*\w*/ ) {
                debug("private variables/classes");
                $self->{privacy}    = "private";
                $self->{visibility} = 1;

                # check for attributes and methods
                $self->_parse_private_things( $line, $Class );

                last LINE;
            }
            elsif ( $line =~ m/^\s*public\s*\w*/ ) {
                debug("public variables/classes");

                #		  print "found public variables/classes\n";
                $self->{privacy}    = "public";
                $self->{visibility} = 0;
                $self->_parse_private_things( $line, $Class );
                last LINE;
            }

            # if inside a class method then discard line
            if ( $self->{in_method} ) {

              # count number of braces and increment decrement depth accordingly
              # if depth = 0 then reset in_method and next;
              # else next;
                my $start_brace_cnt = $line =~ tr/{/{/;
                my $end_brace_cnt   = $line =~ tr/}/}/;

                $self->{brace_depth} =
                  $self->{brace_depth} + $start_brace_cnt - $end_brace_cnt;
                $self->{in_method} = $self->{brace_depth} == 0 ? 0 : 1;

#		  print "In method: ",$start_brace_cnt, $end_brace_cnt, $self->{brace_depth}, $self->{in_method} ,"\n";
                last LINE;
            }

# check for simple declarations
# space* const? space+ (namespace::)* type space* modifier? space+ name;
#             if ($line =~ m/^\s*\w*?\s*((\w+\s*::\s*)*\w+\s*[\*&]?)\s*(\w+)\s*\;.*$/) # Added support for pointers/refs/namespaces
#               {
#                   my $name = $3;
#                   my $type = $1;
#                   #		  print "found simple variable declaration : name = $name, type = $type\n";

            #                   #my $visibility = ( $name =~ m/^\_/ ) ? 1 : 0;

#                   $Class->add_attribute({
#                                          name => $name,
#                                          visibility => $self->{visibility}, #was: $visibility,
#                                          type => $type,
#                                         });

            #                   last LINE;
            #               }

# # check for simple sub
#             if ($line =~ m/^                       # start of line
#                            \s*                      # whitespace
#                            (\w*?\s*?(\w+\s*::\s*)*\w*?\s*[\*&]?) # type of the method: $1. Added support for namespaces
#                            \s*                      # whitespace
#                            (\w+)                  # name of the method: $2
#                            \s*                      # whitespace
#                            \(\s*                    # start of parameter list
#                            ([:\w\,\s\*=&,<>\"]*)        # all parameters: $3
#                            (\)?)                    # may be an ending bracket: $4
#                            [\w\s=]*(;?)             # possibly end of signature $5
#                            .*$/x
#                ) {
#                 my $name = $3;
#                 my $type = $1 || "void";
#                 my $params = $4;
#                 my $end_bracket = $5;
#                 my $end_semicolon = $6;

            #                 debug("simple sub: $name");
            #                 my $have_continuation = 0;
            #                 my $have_end_semicolon= 0;

#                 if ($name eq $Class->{"name"}) {
#                     #		      print "found constructor declaration : name = $name\n";
#                     $type = "";

#                 } else {
#                     #			  print "found simple function declaration : name = $name, type = $type\n";
#                 }

        #                 $have_continuation  = 1 unless $end_bracket    eq ")";
        #                 $have_end_semicolon = 1 if     $end_semicolon  eq ";";

#                 #		  print $have_continuation  ? "no ":"with " ,"end bracket : $end_bracket\n";
#                 #		  print $have_end_semicolon ? "with ":"no " ,"end semicolon : $end_semicolon\n";

            #                 $params    =~ s|\s+$||;
            #                 my @params = split(",",$params);
            #                 my $pc = 0;     # parameter count

          #                 my %subroutine = (
          #                                   name       => $name,
          #                                   type       => $type,
          #                                   visibility => $self->{visibility},
          #                                  );

#                 # If we have continuation lines for the parameters get them all
#                 while ($have_continuation) {
#                     my $line = <$fh>;
#                     last unless ($line);
#                     chomp $line;

#                     if ($line =~ m/^                        # start of line
#                                    \s*                      # whitespace
#                                    ([:\w\,\|\s\*=&\"]*)      # all parameters: $1
#                                    (\)?)                    # may be an ending bracket: $2
#                                    [\w\s=]*(;?)             # possibly end of signature $3
#                                    .*$/x) {
#                         my $cparams     = $1;
#                         $end_bracket    = $2;
#                         $end_semicolon  = $3;

            #                         $cparams =~ s|\s+$||;
            #                         my @cparams = split(",",$cparams);
            #                         push @params, @cparams;

          #                         #			  print "More parameters: >$cparams<\n";

   #                         $have_continuation  = 0 if ($end_bracket   eq ")");
   #                         $have_end_semicolon = 1 if ($end_semicolon eq ";");

#                         #			  print $have_continuation ? "no ":"with " ,"end bracket : $end_bracket\n";
#                         #			  print $have_end_semicolon ? "with ":"no " ,"end semicolon : $end_semicolon\n";
#                     }
#                 }

    #                 # then get parameters and types
    #                 my @parameters = ();
    #                 #		  print "All parameters: ",join(';',@params),"\n";
    #                 foreach my $parameter (@params) {
    #                     $parameter =~ s/const\s+//;
    #                     $parameter =~ m/\s*((\w+::)*\w+\s*[\*|\&]?)\s*(\w+)/ ;
    #                     my ($type, $name) = ($1,$3);

            #                     $type =~ s/\s//g;
            #                     $name =~ s/\s//g;

            #                     $parameters[$pc] = {
            #                                         Name => $name,
            #                                         Type => $type,
            #                                        };
            #                     $pc++;
            #                 }

            #                 $subroutine{"Params"} = \@parameters;
            #                 $Class->add_operation(\%subroutine);

   #                 # Now finished with parameters.  If there was no end
   #                 # semicolon we have an inline method: we read on until we
   #                 # see the start of the method. This deals with (multi-line)
   #                 # constructor initialization lists as well.
   #                 last LINE if $have_end_semicolon;

#                 while (defined $line and $line !~ /{/) {
#                     $line = <$fh>;
#                     print "$filename: waiting for start of method def: $line\n";
#                 }
#                 my $start_brace_cnt = $line =~ tr/{/{/ ;
#                 my $end_brace_cnt   = $line =~ tr/}/}/ ;

#                 $self->{brace_depth} = $start_brace_cnt - $end_brace_cnt;
#                 $self->{in_method}   = 1 unless $self->{brace_depth}  == 0;
#                 #		  print "Start: ",$start_brace_cnt, $end_brace_cnt, $self->{brace_depth}, $self->{in_method} ,"\n";

            #                 last LINE;
            #             }

        # if line starts with word,space,word then its a declaration (probably)
        # Broken.
        #  if ($line =~ m/\s*\w+\s+(\w+\s*::\s*)*\w+/i) {
        #                 #		  print " probably found a declaration : $line\n";
        #                 my @words = m/^(\w+)\s*[\(\,\;].*$/g;
        #                 my $name = $&;
        #                 my $rest = $';  #' to placate some syntax highlighters
        #                 my $type = '';

          #                 my $pc = 0;     # point count (ie location in array)
          #                 foreach my $start_point (@-) {
          #                     my $start = $start_point;
          #                     my $end = $+[$pc];
          #                     $type .= substr($line, $start, ($end - $start));
          #                     $pc++;
          #                 }

#                 # if next character is a ( then the line is a function declaration
#                 if ($rest =~ m|^\((\w+)\(.*(\;?)\s*$|) {
#                                 #		      print "probably found a function : $line \n";
#                     my $params = $1;
#                     my @params = split(",",$params);

#                     my $declaration = 0;
#                     if (defined $2) # if line ends with ";" then its a declaration
#                       {
#                           $declaration = 1;
#                           my @parameters = ();
#                           my $pc = 0; # parameter count
#                           my %subroutine = (
#                                             name       => $name,
#                                             type       => $type,
#                                             visibility => $self->visibility,
#                                            );

      #                           # then get parameters and types
      #                           foreach my $parameter (@params) {
      #                               my ($type, $name) = split(" ",$parameter);

            #                               $type =~ s/\s//g;
            #                               $name =~ s/\s//g;

            #                               $parameters[$pc] = {
            #                                                   name => $name,
            #                                                   type => $type,
            #                                                  };
            #                               $pc++;
            #                           }

#                           $subroutine{param} = \@parameters;
#                           $Class->add_operation(\%subroutine);
#                       } else {
#                           my @attributes = ();
#                           # else next character is , or ;
#                           # the line's a variable declaration
#                           $Class->add_attribute ({
#                                                   name       => $name,
#                                                   type       => $type,
#                                                   visibility => $self->{visibility},
#                                                  });
#                           my %attribute = { name => $name , type => $type };
#                           $attributes[0] = \%attribute;
#                           if ($rest =~ m/^\,.*\;/) {
#                               my @atts = split (",");
#                               foreach my $attribute (@atts) {
#                                   my @attribute_parts = split(" ", $attribute);
#                                   my $n = scalar @attribute_parts;
#                                   my $name = $attribute_parts[$n];
#                                   my $type = join(" ",$attribute_parts[0...$n-1]);
#                                   $Class->add_attribute ( {
#                                                            name       => $name,
#                                                            type       => $type,
#                                                            visibility => $self->{visibility},
#                                                           });
# 				#
#                               }
#                                 #
#                           }
#                           #
#                       }
#                                 #
#                 }
#                 #
#             }
#
        }
    }

    $self->{Diagram} = $Diagram;
    close $fh;
    return;
}

sub _discard_line {
    my $self    = shift;
    my $line    = shift;
    my $discard = 0;

  SWITCH: {
        if ( $line =~ m/^\s*$/ ) {    # if line is blank or white space discard
            $discard = 1;
            last SWITCH;
        }

        if ( $line =~ /^\s*\/\// ) {    # if line is a comment discard
            $discard = 1;
            last SWITCH;
        }

        # if line is a comment discard
        if ( $line =~ m!^\s*/\*.*\*/! ) {
            $discard = 1;
            last SWITCH;
        }

        # if line starts with multiline comment syntax discard and set flag
        if ( $line =~ /^\s*\/\*/ ) {
            $self->{comment} = 1;
            $discard = 1;
            last SWITCH;
        }

        if ( $line =~ /^.*\*\/\s*$/ ) {
            $self->{comment} = 0;
        }
        if ( $self->{comment} == 1 ) { # if currently inside a multiline comment
                # if line starts with comment end syntax then unflag and discard
            if ( $line =~ /^.*\*\/\s*$/ ) {
                $self->{comment} = 0;
                $discard = 1;
                last SWITCH;
            }

            $discard = 1;
            last SWITCH;
        }
    }
    return $discard;
}

####-----

sub _parse_private_things {
    my $self  = shift;
    my $line  = shift;
    my $Class = shift;

    return unless ( $line =~ m/^\s*($PRIVACY)\s*(\w.*)$/ );
    my @private_things = split( ";", $2 );
    foreach my $thing (@private_things) {

# print "- private/public thing : $private_thing\n";
# FIXME : Next line type definition seems erroneous. Any C++ hackers care to check it?
# strip off comments
        $thing =~ s{//.*}{};

        debug("private thing = $thing");

        if ( $thing =~ m/^\s*($METHOD_TYPES)?\s*($TYPE)\s+(\w+\(?$PARAM_REGEX*\)?)\s*\w*\s*\w*.*$/ )
        {
            my $name = $3;
            my $type = ($1) ? "$1 $2" : "$2";
            my $vis  = $self->{visibility};

            #    print "- found declaration : name = $name, type = $type\n";
            debug("private - name = $name, type = $type");
            if ( $name =~ /\(/ ) {
                debug("declaration is a method");

                #      print "-- declaration is a method \n";
                # check for simple sub
                if ( $name =~ /^\s*(\w+)\s*\(\s*($PARAM_REGEX*)(\)?)/ ) {
                    $name = $1;
                    my $params      = $2;
                    my $end_bracket = $3;

                    my $have_continuation  = 0;
                    my $have_end_semicolon = 1;

                    $params =~ s|\s+$||;
                    my @params = split( ",", $params );
                    my $pc = 0;    # parameter count

                    my %subroutine = (
                        name       => $name,
                        type       => $type,
                        visibility => $self->{visibility},
                    );

                    # then get parameters and types
                    my @parameters = ();
                    debug( "All parameters: ", join( ';', @params ) );
                    foreach my $parameter (@params) {
                        $parameter =~ s/const\s+//;

                        my ( $type, $name ) = split( " ", $parameter );

                        $type =~ s/\s//g;
                        $name =~ s/\s//g;

                        $parameters[$pc] = {
                            name => $name,
                            type => $type,
                        };
                        $pc++;
                    }

                    $subroutine{param} = \@parameters;
                    $Class->add_operation( \%subroutine );
                }
            }
            else {
                debug("attribute: $name - $type");

                #     print "-- declaration is an attribute \n";
                $Class->add_attribute(
                    {
                        name       => $name,
                        visibility => $vis,
                        type       => $type,
                    }
                );
            }
        }
    }

}

sub _is_package {
    my $self    = shift;
    my $package = shift;
    my $Diagram = $self->{Diagram};

    unless ( ref $$package ) {
        my $filename = shift;

        # create new class with name
        $$package = Autodia::Diagram::Class->new($filename);

        # add class to diagram
        $Diagram->add_class($$package);
    }

    return;
}


###############################################################################

=head1 NAME

Autodia::Handler::CSharp - AutoDia handler for C#

=head1 INTRODUCTION

This module parses files into a Diagram Object, which all handlers use. The role of the handler is to parse through the file extracting information such as Class names, attributes, methods and properties.

=head1 CONSTRUCTION METHOD

use Autodia::Handler::CSharp;

my $handler = Autodia::Handler::CSharp->New(\%Config);

This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head1 ACCESS METHODS

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

$handler->output_xml(); # interpolates values into an xml or html template

$handler->output_graphviz(); # generates a gif file via graphviz

=head1 AUTHOR

Sean Dague <sean@dague.net>      

=head1 MAINTAINER

Aaron Trevena

=head1 COPYRIGHT

Copyright 2007 Sean Dague
Copyright 2001 - 2006 Aaron Trevena

=cut

1;
