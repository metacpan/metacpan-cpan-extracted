# $Id: XSLTHelper.pm,v 1.3 2005/06/15 16:21:09 cmungall Exp $
#
#

=head1 NAME

  Bio::Chaos::XSLTHelper     - chains xslts

=head1 SYNOPSIS

  Bio::Chaos::XSLTHelper->xsltchain($infile,$outfile,@chaos_xslt_name_list)

=cut

=head1 DESCRIPTION

=cut

package Bio::Chaos::XSLTHelper;

use strict;
use XML::LibXSLT;
use FileHandle;
use base qw(Bio::Chaos::Root);

sub _expand_xslt_name {
    my $name = shift;

    if ($name =~ /\.xsl$/ && -f $name) {
        return $name;
    }

    if (!$ENV{CHAOS_HOME}) {
        printf STDERR <<EOM;

You must set the environment CHAOS_HOME to the location of
your chaos distribution

EOM
        ;
        die;
    }
    my $xf = "$ENV{CHAOS_HOME}/xsl/$name.xsl";
    return $xf;
}

sub xsltchain {
    my $self = shift;
    my $infile = shift;
    my $outfile = shift;
    my @chain = @_;

    if (!@chain) {
        $self->throw("must pass at least one xslt file!");
    }
    @chain = map {_expand_xslt_name($_)} @chain;
          
    my $xslt = shift @chain;
    my @pipe_chain = map {"| xsltproc $_ -"} @chain;
    
    my $cmd = "xsltproc $xslt $infile @pipe_chain";
    if ($outfile) {
        $cmd .= "> $outfile";
    }
    my $err = system($cmd);
    if ($err) {
        $self->throw("problem with xsltchain, running $cmd");
    }
    return;
}


sub _make_temp_file {
    my $base = shift || 'base';
    my $n = shift || '0';
    $base =~ s/.*\///;
    $base =~ s/TMP:\d+//;
    my $fn = "TMP:$$:$base.xml";
    return $fn;
}

sub _write_node_to_temp_file {
    my $node = shift;
    my $f = _make_temp_file(@_);
    my $fh = FileHandle->new(">$f") || die("cannot write tempfile $f");
    print $fh $node->xml;
    $fh->close;
    return $f;
}

sub xsltchain_node {
    my $self = shift;
    my $in = shift;
    my @chain = @_;

    if (!@chain) {
        $self->throw("must pass at least one xslt file!");
    }
    @chain = map {_expand_xslt_name($_)} @chain;
          
    my $xslt = shift @chain;
    my @pipe_chain = map {"| xsltproc $_ -"} @chain;
    
    my $infile = _write_node_to_temp_file($in);

    my $cmd = "xsltproc $xslt $infile @pipe_chain";
    print STDERR "cmd=$cmd\n";
    my $fh = FileHandle->new("$cmd |") || $self->throw($cmd);
    my $out = Data::Stag->parse(-format=>'xml',-fh=>$fh);
    #$fh->close || $self->throw($cmd);
    return $out;
}

1;
