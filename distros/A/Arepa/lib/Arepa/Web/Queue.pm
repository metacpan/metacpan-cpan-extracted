package Arepa::Web::Queue;

use strict;
use warnings;

use base 'Arepa::Web::Base';

use English qw(-no_match_vars);
use Encode;
use Arepa::PackageDb;

sub build_log {
    my ($self) = @_;

    # Force it to be a number
    my $request_id = 0 + $self->param('id');
    my $pdb    = Arepa::PackageDb->new($self->config->get_key('package_db'));
    eval {
        $pdb->get_compilation_request_by_id($request_id);
    };
    if ($EVAL_ERROR) {
        return $self->show_view({errors => [{output => "No such compilation " .
                                                "request: '$request_id'"}]},
                                template => 'error');
    }
    else {
        my $build_log_path =
                File::Spec->catfile($self->config->get_key('dir:build_logs'),
                                    $request_id);
        open F, $build_log_path or do {
            return $self->show_view(
                {errors => [{output => "Can't read build log for " .
                                "compilation request '$request_id' from " .
                                "'$build_log_path'"}]},
                template => 'error');
        };
        my $build_log_contents = join("", <F>);
        close F;
        $self->show_view({log => decode('utf-8', $build_log_contents)});
    }
}

sub requeue {
    my ($self) = @_;

    $self->_only_if_admin(sub {
        # Force it to be a number
        my $request_id = 0 + $self->param('id');
        my $pdb    = Arepa::PackageDb->new($self->config->get_key('package_db'));
        eval {
            $pdb->get_compilation_request_by_id($request_id);
        };
        if ($EVAL_ERROR) {
            return $self->show_view('error.tmpl',
                                    {errors => [{output => "No such compilation request: '$request_id'"}]});
        }
        else {
            $pdb->mark_compilation_pending($request_id);
            $self->redirect_to('home');
        }
    });
}

1;
