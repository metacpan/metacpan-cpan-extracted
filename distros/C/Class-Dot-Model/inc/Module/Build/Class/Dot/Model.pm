# $Id: Model.pm 4 2007-09-13 10:16:35Z asksol $
# $Source: /opt/CVS/Getopt-LL/inc/Module/Build/Getopt/LL.pm,v $
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/inc/Module/Build/Class/Dot/Model.pm $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
package Module::Build::Class::Dot::Model;
use strict;
use warnings;
use base 'Module::Build';
use vars qw($VERSION);
use English qw( -no_match_vars );

$VERSION = 1.0;

sub ACTION_wikidoc {
    my $self = shift;

    eval 'use Pod::WikiDoc'; ## no critic;
    if ($EVAL_ERROR eq q{}) {

        my $parser = Pod::WikiDoc->new(
            {   comment_blocks  => 1,
                keywords        => {VERSION => $self->dist_version,},
            }
        );
        for my $source_file (keys %{ $self->find_pm_files() }) {
            my $output_file = $self->pm_file_to_pod_file($source_file);
            $parser->filter(
                {   input  => $source_file,
                    output => $output_file,
                }
            );
            $self->log_info("Creating $output_file\n");
            $self->_add_to_manifest('MANIFEST', $output_file);
        }
    }
    else {
        $self->log_warn(
            'Pod::WikiDoc not available. Skipping wikidoc.'
        );
    }

    return;
}

sub ACTION_test {
    my $self = shift;
    my $missing_pod;
    for my $source_file (keys %{ $self->find_pm_files() }) {
        my $output_file = $self->pm_file_to_pod_file($source_file);
        if (! -e $output_file) {
            $missing_pod++;
        }
    }

    if ($missing_pod) {
        $self->depends_on('wikidoc');
        $self->depends_on('build');
    }

    return $self->SUPER::ACTION_test(@_);
}

sub ACTION_testpod {
    my $self = shift;
    $self->depends_on('wikidoc');
    return $self->SUPER::ACTION_testpod(@_);
}

sub ACTION_distdir {
    my $self = shift;
    $self->depends_on('wikidoc');
    return $self->SUPER::ACTION_distdir(@_);
}

sub ACTION_testcover {
    my $self = shift;

    $ENV{TEST_COVERAGE} = 1;
    $self->SUPER::ACTION_testcover(@_);

    return;
}


sub pm_file_to_pod_file {
    my ($self, $filename) = @_;
    $filename =~ s{\.pm}{.pod}xms;
    return $filename;
}

sub log_warn {
    my ($self, @messages) = @_;

    for my $message (@messages) {
        chomp $message;
        $message .= qq{\n};
    }

    return $self->SUPER::log_warn(@messages);
}

1;
