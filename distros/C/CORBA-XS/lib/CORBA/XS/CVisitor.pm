
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::XS::CVisitor;

use strict;
use warnings;

our $VERSION = '0.62';

use File::Basename;
use POSIX qw(ctime);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{modules} = [ @{$parser->YYData->{modules}} ];
    $self->{inc} = {};
    $self->{has_methods} = 0;
    $self->{num_key} = 'num_xs_c';
    return $self;
}

sub open_stream {
    my $self = shift;
    my($filename) = @_;
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
}

sub _insert_inc {
    my $self = shift;
    my($filename) = @_;
    my $FH = $self->{out};
    if (! exists $self->{inc}->{$filename}) {
        $self->{inc}->{$filename} = 1;
        $filename = basename($filename, '.idl') . '.h';
        print $FH "#include \"",$filename,"\"\n";
    }
}

sub _get_defn {
    my $self = shift;
    my($defn) = @_;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{symbtab}->Lookup($defn);
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my($node) = @_;
    my $src_name = basename($self->{srcname}, '.idl');
    $self->open_stream($src_name . '.c');
    my $FH = $self->{out};
    print $FH "/* ex: set ro: */\n";
    print $FH "/* This file was generated (by ",$0,"). DO NOT modify it */\n";
    print $FH "/*\n";
    print $FH " * From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH " */\n";
    print $FH "\n";
    print $FH "#include \"EXTERN.h\"\n";
    print $FH "#include \"perl.h\"\n";
    print $FH "#include \"XSUB.h\"\n";
    print $FH "\n";
    $self->{newXS} = q{};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "#ifdef __cplusplus\n";
    print $FH "extern \"C\"\n";
    print $FH "#endif\n";
    print $FH "XS(boot_",$src_name,")\n";
    print $FH "{\n";
    print $FH "    dXSARGS;\n";
    print $FH "    char* file = __FILE__;\n";
    print $FH "\n";
    print $FH "    XS_VERSION_BOOTCHECK ;\n";
    print $FH "\n";
    print $FH $self->{newXS};
    print $FH "    XSRETURN_YES;\n";
    print $FH "}\n";
    print $FH "\n";
    print $FH "/* end of file : ",$self->{filename}," */\n";
    print $FH "\n";
    print $FH "/*\n";
    print $FH " * Local variables:\n";
    print $FH " *   buffer-read-only: t\n";
    print $FH " * End:\n";
    print $FH " */\n";    
    close $FH;
    unless ($self->{has_methods}) {
        unlink $self->{filename}
             or die "can't delete $self->{filename} ($!).\n";
        return;
    }

    my $filename = 'Makefile.PL';
    open my $OUT, '>', $filename
            or die "can't open $filename ($!).\n";
    print $OUT "use ExtUtils::MakeMaker;\n";
    print $OUT "# See lib/ExtUtils/MakeMaker.pm for details of how to influence\n";
    print $OUT "# the contents of the Makefile that is written.\n";
    print $OUT "WriteMakefile(\n";
    print $OUT "    'NAME'          => '",$src_name,"',\n";
    print $OUT "    'VERSION_FROM'  => '",$src_name,".pm', # finds \$VERSION\n";
    print $OUT "    'PREREQ_PM'     => {\n";
    print $OUT "                        'Error'                 => 0,\n";
    print $OUT "                        'CORBA::Perl::CORBA'    => 0\n";
    print $OUT "    },\n";
    print $OUT "    'LIBS'          => [''], # e.g., '-lm'\n";
    print $OUT "    'DEFINE'        => '', # e.g., '-DHAVE_SOMETHING'\n";
    print $OUT "    'INC'           => '', # e.g., '-I/usr/include/other'\n";
    print $OUT "    'MYEXTLIB'      => 'cdr_",$src_name,"\$(OBJ_EXT) skel_",$src_name,"\$(OBJ_EXT) corba\$(OBJ_EXT)',\n";
    print $OUT "    'PM'            => {\n";
    foreach (@{$self->{modules}}) {
        print $OUT "                        '",$_,".pm' => '\$(INST_LIBDIR)/",$_,".pm',\n";
    }
    print $OUT "                        '",$src_name,".pm' => '\$(INST_LIBDIR)/",$src_name,".pm'\n";
    print $OUT "    },\n";
    print $OUT ");\n";
    close $OUT;

    $filename = 'MANIFEST';
    open $OUT, '>', $filename
            or die "can't open $filename ($!).\n";
    foreach (@{$self->{modules}}) {
        print $OUT $_,".pm\n";
        print $OUT $_,".h\n";
    }
    print $OUT $src_name,".pm\n";
    print $OUT $src_name,".c\n";
    print $OUT $src_name,".h\n";
    print $OUT "cdr_",$src_name,".c\n";
    print $OUT "skel_",$src_name,".c\n";
    print $OUT "corba.c\n";
    print $OUT "Changes\n";
    print $OUT "Makefile.PL\n";
    print $OUT "MANIFEST\n";
    print $OUT "test.pl\n";
    close $OUT;

    $filename = 'Changes';
    open $OUT, '>', $filename
            or die "can't open $filename ($!).\n";
    print $OUT "Revision history for Perl extension ",$src_name,".\n";
    print $OUT "\n";
    print $OUT "0.01  ",POSIX::ctime(time());
    print $OUT "\t- original version; created by idl2xs_c\n";
    print $OUT "\t\tfrom ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    close $OUT;

    $filename = 'test.pl';
    open $OUT, '>', $filename
            or die "can't open $filename ($!).\n";
    print $OUT "# Before `make install' is performed this script should be runnable with\n";
    print $OUT "# `make test'. After `make install' it should work as `perl test.pl'\n";
    print $OUT "\n";
    print $OUT "######################### We start with some black magic to print on failure.\n";
    print $OUT "\n";
    print $OUT "# Change 1..1 below to 1..last_test_to_print .\n";
    print $OUT "# (It may become useful if the test is moved to ./t subdirectory.)\n";
    print $OUT "\n";
    print $OUT "BEGIN { \$| = 1; print \"1..1\\n\"; }\n";
    print $OUT "END {print \"not ok 1\\n\" unless \$loaded;}\n";
    print $OUT "use ",$src_name,";\n";
    print $OUT "\$loaded = 1;\n";
    print $OUT "print \"ok 1\\n\";\n";
    print $OUT "\n";
    print $OUT "######################### End of black magic.\n";
    print $OUT "\n";
    print $OUT "# Insert your test code below (better if it prints \"ok 13\"\n";
    print $OUT "# (correspondingly \"not ok 13\") depending on the success of chunk 13\n";
    print $OUT "# of the test code):\n";
    close $OUT;

    my $path = $INC{'CORBA/XS/CVisitor.pm'};
    $path =~ s/CVisitor\.pm$//i;
    $path .= 'corba.c';
    open my $IN, '<', $path
            or die "can't read $path ($!)";
    $filename = 'corba.c';
    open $OUT, '>', $filename
            or die "can't open $filename ($!).\n";
    while (<$IN>) {
        print $OUT $_;
    }
    close $OUT;
    close $IN;

    do 'Makefile.PL';
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my($node) = @_;
    unless (exists $node->{$self->{num_key}}) {
        $node->{$self->{num_key}} = 0;
    }
    my $module = ${$node->{list_decl}}[$node->{$self->{num_key}}];
    $module->visit($self);
    $node->{$self->{num_key}} ++;
}

sub visitModule {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
        }
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my($node) = @_;
    if ($self->{srcname} eq $node->{filename}) {
        $self->{itf} = $node->{c_name};
        my $FH = $self->{out};
        print $FH "/* interface ",$node->{pl_name}," */\n";
        print $FH "\n";
        foreach (values %{$node->{hash_attribute_operation}}) {
            $self->_get_defn($_)->visit($self);
        }
    }
}

sub visitAbstractInterface {
    my $self = shift;
    my($node) = @_;
    if ($self->{srcname} eq $node->{filename}) {
        $self->{itf} = $node->{c_name};
        my $FH = $self->{out};
        print $FH "/* abstract interface ",$node->{pl_name}," */\n";
        print $FH "\n";
        foreach (values %{$node->{hash_attribute_operation}}) {
            $self->_get_defn($_)->visit($self);
        }
    }
}

sub visitForwardRegularInterface {
    # empty
}

sub visitForwardAbstractInterface {
    # empty
}

sub visitBaseInterface {
    # C mapping is aligned with CORBA 2.1
}

sub visitForwardBaseInterface {
    # C mapping is aligned with CORBA 2.1
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarators {
    # empty
}

sub visitNativeType {
    # empty
}

#
#   3.11.2  Constructed Types
#

sub visitStructType {
    # empty
}

sub visitUnionType {
    # empty
}

sub visitForwardStructType {
    # empty
}

sub visitForwardUnionType {
    # empty
}

sub visitEnumType {
    # empty
}

#
#   3.12    Exception Declaration
#

sub visitException {
    # empty
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    $self->{has_methods} = 1;
    my $c_package = $node->{pl_package};
    $c_package =~ s/::/_/g;
    if (exists $node->{modifier}) {     # oneway
        print $FH "extern void cdr_",$self->{itf},"_",$node->{c_name},"(void * ref, char *is);\n";
        print $FH "\n";
        print $FH "XS(XS_",$c_package,"_cdr_",$node->{pl_name},")\n";
        print $FH "{\n";
        print $FH "    dXSARGS;\n";
        print $FH "    if (items != 2)\n";
        print $FH "        Perl_croak(aTHX_ \"Usage: ",$node->{pl_package},"::cdr_",$node->{pl_name},"(ref, is)\");\n";
        print $FH "    {\n";
        print $FH "        void * ref = (void *)SvIV(ST(0));\n";
        print $FH "        char * is = (char *)SvPV(ST(1),PL_na);\n";
        print $FH "        dXSTARG;\n";
        print $FH "        cdr_",$self->{itf},"_",$node->{c_name},"(ref, is);\n";
        print $FH "        XSprePUSH; PUSHi((IV)0);\n";
        print $FH "    }\n";
        print $FH "    XSRETURN(1);\n";
        print $FH "}\n";
        print $FH "\n";
    }
    else {
        print $FH "extern int cdr_",$self->{itf},"_",$node->{c_name},"(void * ref, char *is, char **os);\n";
        print $FH "\n";
        print $FH "XS(XS_",$c_package,"_cdr_",$node->{pl_name},")\n";
        print $FH "{\n";
        print $FH "    dXSARGS;\n";
        print $FH "    if (items != 3)\n";
        print $FH "        Perl_croak(aTHX_ \"Usage: ",$node->{pl_package},"::cdr_",$node->{pl_name},"(ref, is, os)\");\n";
        print $FH "    {\n";
        print $FH "        void * ref = (void *)SvIV(ST(0));\n";
        print $FH "        char * is = (char *)SvPV(ST(1),PL_na);\n";
        print $FH "        char * os;\n";
        print $FH "        int size;\n";
        print $FH "        dXSTARG;\n";
        print $FH "        size = cdr_",$self->{itf},"_",$node->{c_name},"(ref, is, &os);\n";
        print $FH "        if (size >= 0)\n";
        print $FH "            sv_setpvn((SV*)ST(2), os, size);\n";
        print $FH "        SvSETMAGIC(ST(2));\n";
        print $FH "        XSprePUSH; PUSHi((IV)size);\n";
        print $FH "    }\n";
        print $FH "    XSRETURN(1);\n";
        print $FH "}\n";
        print $FH "\n";
    }
    $self->{newXS} .= "        newXS(\"" . $node->{pl_package} . "::cdr_" . $node->{pl_name} . "\", XS_";
        $self->{newXS} .= $c_package . "_cdr_" . $node->{pl_name} . ", file);\n";
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my($node) = @_;
    $node->{_get}->visit($self);
    $node->{_set}->visit($self) if (exists $node->{_set});
}

1;

