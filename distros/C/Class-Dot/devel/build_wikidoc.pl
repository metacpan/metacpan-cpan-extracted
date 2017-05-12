# $Id: build_wikidoc.pl 37 2007-11-03 20:08:48Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/devel/build_wikidoc.pl $
# $Revision: 37 $
# $Date: 2007-11-03 21:08:48 +0100 (Sat, 03 Nov 2007) $
package XXX::Build::WikiDoc;

use strict;
use warnings;

use Class::Dot qw(-new :std);
use File::Next 0.40;
use English    qw(-no_match_vars);

my %IGNORE_FILE = map {$_ => 1} qw(
    Build.PL Makefile.PL
);

my $DIST_MODULE = 'Class::Dot';

my $RE_PERL_FILE = qr/\.(?: pm | pmc | pl ) \z/xms;

my $dist_version;
eval "require $DIST_MODULE"; ## no critic
if (not $EVAL_ERROR) {
    $dist_version = $DIST_MODULE->VERSION;
}

my $caller = caller;
if (not defined $caller or $caller eq 'PAR') {
    my $wikidoc_builder = __PACKAGE__->new();
    $wikidoc_builder->build_wikidoc();
}

sub build_wikidoc {
    my $self = shift;

    eval 'use Pod::WikiDoc'; ## no critic;
    if ($EVAL_ERROR eq q{}) {

        my $parser = Pod::WikiDoc->new(
            {   comment_blocks  => 1,
                keywords        => {VERSION => $dist_version,},
            }
        );
        my $next_file = File::Next::files('lib');
        FILE:
        while (defined (my $file = $next_file->())) {
            if (-f $file && $file =~ $RE_PERL_FILE) {
                next FILE if $IGNORE_FILE{$file}; 
                my $source_file = $file;
                my $output_file = $self->pm_file_to_pod_file($source_file);
                $parser->filter(
                    {   input  => $source_file,
                        output => $output_file,
                    }
                );
                $self->log_info("Creating $output_file\n");
            }
        }
    }
    else {
        $self->log_warn(
            'Pod::WikiDoc not available. Skipping wikidoc.'
        );
    }

    return;
}

sub pm_file_to_pod_file {                                                                 
    my ($self, $filename) = @_;                                                           
    $filename =~ s{(?:\. .*?)\z}{.pod}xms;                                                        
    return $filename;                                                                     
}

sub log_warn {                                                                            
    my ($self, @messages) = @_;                                                           
                                                                                          
    for my $message (@messages) {                                                         
        chomp $message;                                                                   
        $message .= qq{\n};                                                               
    }

    warn @messages;
                                                                                          
    return;
}

sub log_info {                                                                            
    my ($self, @messages) = @_;                                                           
                                                                                          
    for my $message (@messages) {                                                         
        chomp $message;                                                                   
        $message .= qq{\n};                                                               
    }

    warn @messages;
                                                                                          
    return;
}

1;
