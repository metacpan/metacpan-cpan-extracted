#!/usr/bin/env perl
#
#
use strict;
use warnings;
use feature qw[unicode_strings switch];
use open ':encoding(utf8)';
no if $] >= 5.018, 'warnings', "experimental::smartmatch";

use Encode;
use File::Basename;
use File::Glob;
use File::Slurp;
use File::Spec;
use IO::File;
use IO::String;
use XML::Twig;
use Data::Dump;

my $request_info = {};
my $type_info    = {};
my $current_set;

# ------------------------------------------------------------------------
sub list {
    return () unless ( defined( $_[0] ) );
    return @{ $_[0] } if ( ref( $_[0] ) eq 'ARRAY' );
    return $_[0];
}

# ----------------------------------------------------------------------
sub build_pod {
    my $info = shift;
    my $twg  = shift;

    # extract documentation and output
    my $docelt = $twg->first_elt('xs:documentation');
    if ($docelt) {
        my $doc = $docelt->text;
        $info->{is_command} = 1 if ( $doc =~ /SuccessResponse/ );

        # condition docs
        $doc =~ tr/\001-\176/ /cs;
        $doc =~ s/^\s{6,}//mg;
        $doc =~ s/\s+$//mg;
        $doc =~ s/^\s\s?(?=\w)/\n/mg;
        $doc =~ s/\s+(?=The\s+response\s+is)/\n\n/mg;
        $doc =~ s/\b(\w+[A-Z][a-z]\w+)\b/C<$1>/g;

        $info->{pod} = $doc;
    }
}

# ----------------------------------------------------------------------
sub build_sub_entry {
    my $out  = shift;
    my $info = shift;

    # output method header with parameters
    $out->printf( "method %s\n(%s)\n{\n", $info->{name}, join( ', ', @{ $info->{input_parameter_names} || [] } ) );

    # output command call
    $out->printf(
        "return \$self->send_%s('%s',\n%s\n);\n}\n",
        ( $info->{is_command} ? 'command' : 'query' ),
        $info->{name}, join( ', ', @{ $info->{output_parameter_map} } )
    );

    # output tail
    $out->print("# ----------------------------------------------------------------------\n");
}

# ----------------------------------------------------------------------
sub build_pod_entry {
    my $out  = shift;
    my $info = shift;

    $out->printf( "\n=head3 %s\n\n", $info->{name} );

    $out->print( $info->{pod} );

    # output fixed parameter info
    $out->print("\n\nFixed parameters are:-\n");
    $out->print("\n=over 4\n");
    $out->print("\n$_\n") foreach ( @{ $info->{parameter_pod} } );
    $out->print("\n=back\n");

    # and any additionals
    $out->print("\nAdditionally there are generic tagged parameters.\n") if ( $info->{need_generic_params} );
}

# ----------------------------------------------------------------------
sub expand_one_parameter {
    my $name                  = shift;
    my $type                  = shift || 'Unknown';
    my $cref                  = shift;
    my $prefix                = shift;
    my $input_parameter_names = shift;
    my $param_pod             = shift;

    my $return_param;

    # see if this is expandable
    my $tinfo = $type_info->{$type};
    if ( defined($tinfo) and $tinfo->{expandable} ) {
        my @param_set;
        my $nprefix = $prefix . $name . ' / ';
        foreach my $comp ( @{ $tinfo->{components} } ) {
            push(
                @param_set,
                expand_one_parameter(
                    $comp->{name}, $comp->{$type}, $cref, $nprefix, $input_parameter_names, $param_pod
                )
            );
        }
        $return_param = sprintf( '%s => [%s]', $name, join( ', ', @param_set ) );
    }
    else {
        my $ipname = sprintf( '$x%d', ${$cref}++ );
        push( @{$input_parameter_names}, $ipname );
        $return_param = sprintf( '%s => %s', $name, $ipname );
        push( @{$param_pod}, sprintf( '=item B<%s%s> - I<%s>', $prefix, $name, $type ) );
    }
##print " $return_param\n";
    return $return_param;
}

# ----------------------------------------------------------------------
sub expand_parameters {
    my $info = shift;

    my @input_parameter_names;
    my @output_parameter_map;
    my @parameter_pod;
    my $count = 0;

    # deal with initial fixed parameters
    foreach my $pname ( @{ $info->{fixed_parameters} } ) {
        my $type = $info->{parameter_type}{$pname};
        push( @output_parameter_map,
            expand_one_parameter( $pname, $type, \$count, '', \@input_parameter_names, \@parameter_pod ) );
    }

    # deal with generic output parameters
    if ( $info->{need_generic_params} ) {
        push( @output_parameter_map, '@generic_params' );
    }

    # deal with trailing fixed parameters
    foreach my $pname ( @{ $info->{end_fixed_parameters} } ) {
        my $type = $info->{parameter_type}{$pname};
        push( @output_parameter_map,
            expand_one_parameter( $pname, $type, \$count, '', \@input_parameter_names, \@parameter_pod ) );
    }

    # deal with generic input parameters
    if ( $info->{need_generic_params} ) {
        push( @input_parameter_names, '@generic_params' );
    }

    $info->{input_parameter_names} = \@input_parameter_names;
    $info->{output_parameter_map}  = \@output_parameter_map;
    $info->{parameter_pod}         = \@parameter_pod;
    $info->{parameter_count}       = $count;
}

# ----------------------------------------------------------------------
sub generate_code_header {
    my $fh         = shift;
    my $set_name   = shift;
    my $deprecated = shift;

    $fh->printf( "package Broadworks::OCIP::%s;\n", $set_name );
    $fh->print("\n");
    $fh->printf( "# ABSTRACT: Broadworks OCI-P %s autogenerated from XML Schema\n", $set_name );
    $fh->print("\n");
    $fh->print("use strict;\n");
    $fh->print("use warnings;\n");
    $fh->print("use utf8;\n");
    $fh->print("use namespace::autoclean;\n");
    $fh->print("use Function::Parameters;\n");

    if ($deprecated) {
        $fh->print("use Moose::Role;\n");
    }
    else {
        $fh->print("use Moose;\n");
    }
    ##$fh->print("#  This file will be too big for perl critic to work well\n");
    ##$fh->print("## no critic\n");
    $fh->print("\n");
    $fh->print("# VERSION\n");
    $fh->print("# AUTHORITY\n");
    $fh->print("\n");
    $fh->print("# ----------------------------------------------------------------------\n");
    $fh->print("\n");
}

# ----------------------------------------------------------------------
sub generate_code_trailer {
    my $fh         = shift;
    my $set_name   = shift;
    my $deprecated = shift;

    $fh->print("\n");
    $fh->print("__PACKAGE__->meta->make_immutable;\n") unless ($deprecated);
    $fh->print("1;\n");
}

# ----------------------------------------------------------------------
sub generate_pod_header {
    my $fh         = shift;
    my $set_name   = shift;
    my $deprecated = shift;

    $fh->printf( "# PODNAME: Broadworks::OCIP::OCIP::%s\n",                         $set_name );
    $fh->printf( "# ABSTRACT: Broadworks OCI-P %s autogenerated from XML Schema\n", $set_name );
    $fh->print("\n");
}

# ----------------------------------------------------------------------
sub generate_pod_trailer {
    my $fh         = shift;
    my $set_name   = shift;
    my $deprecated = shift;

    $fh->print("\n");
}

# ----------------------------------------------------------------------
sub get_class_name {
    my $fn = shift;

    my ( $volume, $directories, $file ) = File::Spec->splitpath($fn);
    my $class = $file;
    $class =~ s/\..*$//;        # remove extension
    $class =~ s/OCISchema//;    # remove basename

    return $class;
}

# ----------------------------------------------------------------------
sub parse_request_info {
    my $name = shift;
    my $twg  = shift;
    my $elt  = shift;

    my $ptypes = {};
    my @fixed_parameters;
    my @end_fixed_parameters;
    my $res = {
        name                 => $name,
        fixed_parameters     => \@fixed_parameters,
        end_fixed_parameters => \@end_fixed_parameters,
        parameter_type       => $ptypes,
        is_command           => 0,
        need_generic_params  => 0
    };
    $request_info->{$name} = $res;
    $current_set->{classes}{ $current_set->{current_class} } ||= [];
    push( @{ $current_set->{classes}{ $current_set->{current_class} } }, $name );

    # parse through the parameter sets
    my $seq = $elt->first_child;    # This should be a sequence
    unless ( defined($seq) ) {
        ## no parameters at all...
    }
    elsif ( $seq->tag eq 'xs:sequence' ) {
        my @elements = $seq->children;
        while ( my $elem = shift @elements ) {
            if ( $elem->tag eq 'xs:element' ) {
                my $ename = $elem->att('name');
                my $etype = $elem->att('type');
                $ptypes->{$ename} = $etype;

                # deal with optional/multi params
                my $minoc = -1;
                if ( $elem->att_exists('minOccurs') ) {
                    $minoc                      = $elem->att('minOccurs');
                    $res->{need_generic_params} = 1;
                    @end_fixed_parameters       = ();
                    next if ( $minoc == 0 );
                }

                # if there are generics, see if there are fixed ends
                if ( $res->{need_generic_params} ) {
                    push( @end_fixed_parameters, $ename ) if ( $minoc == -1 );
                }
                else {
                    push( @fixed_parameters, $ename );
                }
            }
            else {
                $res->{need_generic_params} = 1;
                @end_fixed_parameters = ();
            }
        }
    }
    elsif ( $seq->tag eq 'xs:choice' ) {
        $res->{need_generic_params} = 1;
    }
    else {
        die "Expected sequence or choice in $name\n";
    }
    build_pod( $res, $twg );
}

# ----------------------------------------------------------------------
sub parse_type_info {
    my $name = shift;
    my $twg  = shift;
    my $elt  = shift;

    my @components;
    my $res = {
        name       => $name,
        expandable => 0,
        components => \@components,
    };
    $type_info->{$name} = $res;

    # parse through the parameter sets
    my $seq = $elt->first_child('xs:sequence');    # This should be a sequence
    if ( defined($seq) ) {
        my @elements = $seq->children;
        $res->{expandable} = 1;                    # presume expandable until find otherwise
        while ( my $elem = shift @elements ) {
            if ( $elem->tag eq 'xs:element' ) {
                my $ename = $elem->att('name');
                my $etype = $elem->att('type');
                push( @components, { name => $ename, type => $etype } );

                # If there are any optionals or multiples then give up - not expandeable
                if ( $elem->att_exists('minOccurs') or $elem->att_exists('maxOccurs') ) {
                    $res->{expandable} = 0;
                }
            }
            else {
                # choice or some other weird type stuff - can't expand that
                $res->{expandable} = 0;
            }
        }
    }
}

# ----------------------------------------------------------------------
sub complex_type_parser {
    my ( $t, $type ) = @_;

    my $name = $type->att('name');
    if ( defined($name) ) {
        my $base_elt = $t->first_elt('xs:extension[@base]');
        if ($base_elt) {
            my $base = $base_elt->att('base');
            my $i;
            given ($base) {
                when ('core:OCIRequest')      { $i = 'Q'; parse_request_info( $name, $t, $base_elt ); }
                when ('core:OCIDataResponse') { $i = 'D' }
                when ('core:OCIResponse')     { $i = 'R' }
                default                       { $i = '?' }
            }
            ### print "#    $i $name\n";
        }
        else {
            parse_type_info( $name, $t, $type );
            ### print "#    - $name\n";
        }
    }
    $type->purge;
}

# ----------------------------------------------------------------------
sub process_file {
    my $fn      = shift;
    my $twig    = shift;
    my $dataset = shift;

    my $class_base_name = get_class_name($fn);
    warn("- $class_base_name\n");
    $dataset->{classlist} ||= [];
    push( @{ $dataset->{classlist} }, $class_base_name );
    $dataset->{current_class} = $class_base_name;

    my $xml = read_file( $fn, { binmode => ':encoding(ISO-8859-1)' } );
    $twig->parse($xml);
}

# ----------------------------------------------------------------------
sub build_twig {
    my $twig = XML::Twig->new( twig_handlers => { 'xs:complexType' => \&complex_type_parser, }, );

    return $twig;
}

# ----------------------------------------------------------------------

my $twig     = build_twig();
my $datasets = {};
while ( my $fn = shift ) {
    my $set = ( $fn =~ /Deprecated/ ) ? 'Deprecated' : 'Methods';
    $datasets->{$set} ||= {};
    $current_set = $datasets->{$set};
    process_file( $fn, $twig, $current_set );
}

# generate files
foreach my $set (qw[Methods Deprecated]) {
    my $thisset = $datasets->{$set};

    my $code = IO::File->new( $set . '.pm',  'w' ) || die "Cannot open code $set - $!";
    my $pod  = IO::File->new( $set . '.pod', 'w' ) || die "Cannot open pod $set - $!";
    generate_code_header( $code, $set, ( $set eq 'Deprecated' ) ? 1 : 0 );
    generate_pod_header( $pod, $set, ( $set eq 'Deprecated' )   ? 1 : 0 );
    foreach my $class ( @{ $thisset->{classlist} } ) {
        $code->printf("##\n## $class\n##\n");
        $pod->printf("\n=head2 $class\n\n");
        foreach my $func ( @{ $thisset->{classes}{$class} } ) {
            expand_parameters( $request_info->{$func} );
            build_sub_entry( $code, $request_info->{$func} );
            build_pod_entry( $pod, $request_info->{$func} );
        }
    }

    # generate trailers and close files
    generate_code_trailer( $code, $set, ( $set eq 'Deprecated' ) ? 1 : 0 );
    generate_pod_trailer( $pod, $set, ( $set eq 'Deprecated' )   ? 1 : 0 );
    $code->close;
    $pod->close;
}

