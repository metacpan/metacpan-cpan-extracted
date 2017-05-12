package RunThrowCGI;

#####################################################################
# RunThrowCGI module
#
# Test support module that runs CGI programs that use and test
# CGI::Carp::Throw.  Has routines that make some standard checks
# for the presence or absence of text in the output or, in some
# cases, the error output, like Carp or Throw styles of tracing output.
#####################################################################

use strict;
use warnings;
use Config;
use Test::More;
use FileHandle;
use File::Spec;
use IPC::Open3;

my $null_dev = File::Spec->devnull;
our $perl_path;

# probably more trouble than it's worth
foreach my $perl ($^X, $Config{perlpath}, 'perl') {
    if (length(`$perl -v 2>$null_dev` || '') >= 100) {
        $perl_path = $perl;
        last;
    }
}

#####################################################################
# basic constructor
#####################################################################
sub new {
    my $obclass = shift;
    my $class = ref($obclass) || $obclass;
    
    die "Can't do nothin without perl" unless ($perl_path);
    
    return bless {}, $obclass;
}

#####################################################################
# Run a CGI script that is likely to die / carp / throw and
# collect its output.  Put the whole retreived page in output_page,
# the part of the page with Carp::Throw's trace comment in
# trace_comment and the rest of the page in wo_trace_comment.
#####################################################################
sub run_throw_cgi {
    my $self = shift;
    my $script = $self->{ script } = shift;
    
    delete @$self{ qw(output_page trace_comment wo_trace_comment err_out) };
    
    $self->{ output_page } = `$perl_path -Ilib t/$script 2>$null_dev`;
    
    ($self->{ trace_comment }) =
        $self->{ output_page } =~ /(<!--\s*CGI::Carp::Throw tracing.*?-->)/s;
    $self->{ wo_trace_comment } = $self->{ output_page };
    $self->{ wo_trace_comment } =~ s/<!--\s*CGI::Carp::Throw tracing.*?-->//s;
    
    return @$self{ qw(output_page trace_comment wo_trace_comment) };
}

#####################################################################
# Run a CGI script that is likely to die / carp / throw and
# collect its output and error output.  Otherwise pretty much
# like run_throw_cgi.
#####################################################################
sub run_throw_cgi_w_err {
    no strict 'vars';
    my $self = shift;
    my $script = $self->{ script } = shift;
    
    delete @$self{ qw(output_page trace_comment wo_trace_comment err_out) };    
    
    local $/ = undef;
    my ($wtr, $rdr);
    my $err = new FileHandle;
    my $pid = open3($wtr, $rdr, $err,
        "$perl_path -Ilib t/$script"
    );
    
    close $wtr;
    $self->{ output_page } = <$rdr>;
    $self->{ err_out } = <$err>;
    
    waitpid $pid, 0;
    
    ($self->{ trace_comment }) =
        $self->{ output_page } =~ /(<!--\s*CGI::Carp::Throw tracing.*?-->)/s;
    $self->{ wo_trace_comment } = $self->{ output_page };
    $self->{ wo_trace_comment } =~ s/<!--\s*CGI::Carp::Throw tracing.*?-->//s;
    
    return @$self{ qw(output_page trace_comment wo_trace_comment) };
}

#####################################################################
# Check if output has signature indicating CGI::Carp::Throw trace data.
#####################################################################
sub has_trace {
    my $self = shift;

    return ($self->{ trace_comment } || '') =~ /::throw_browser\(/s;
}

#####################################################################
# Test ok if output has CGI::Carp::Throw trace data.
#####################################################################
sub ok_has_trace {
    my $self = shift;
    
    ok( $self->has_trace, "found trace in comment from $self->{ script }" );    
}

#####################################################################
# Check if output LACKS signature indicating CGI::Carp visible trace data.
#####################################################################
sub has_no_vis_trace {
    my $self = shift;
    
    return $self->{ wo_trace_comment } !~ /\bat\b.*line\s+\d+/s;
}

#####################################################################
# Test ok if output LACKS signature indicating CGI::Carp visible trace data.
#####################################################################
sub ok_has_no_vis_trace {
    my $self = shift;

    ok( $self->has_no_vis_trace,
        "no trace outside comment in reply body from $self->{ script }"
    );    
    
}

#####################################################################
# Read only accessors - no need to write to them from outside for now.
#####################################################################
sub output_page         { return $_[0]->{ output_page } }
sub trace_comment       { return $_[0]->{ trace_comment } }
sub wo_trace_comment    { return $_[0]->{ wo_trace_comment } }
sub err_output          { return $_[0]->{ err_out } }
sub script              { return $_[0]->{ script } }

1;
