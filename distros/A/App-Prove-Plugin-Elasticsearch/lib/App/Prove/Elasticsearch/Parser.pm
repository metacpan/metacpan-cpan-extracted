# PODNAME:  App::Prove::Elasticsearch::Parser
# ABSTRACT: Capture the output of prove, and upload the results of the test to elasticsearch

package App::Prove::Elasticsearch::Parser;
$App::Prove::Elasticsearch::Parser::VERSION = '0.001';
use strict;
use warnings;

use parent qw/TAP::Parser/;

use Clone qw{clone};
use File::Basename qw{basename dirname};
use POSIX qw{strftime};
use App::Prove::Elasticsearch::Utils();

sub new {
    my ($class, $opts) = @_;
    $opts = clone $opts;  #Convenience, if we are passing over and over again...

    #Load our callbacks
    $opts->{'callbacks'} = {
        'test'    => \&testCallback,
        'comment' => \&commentCallback,
        'unknown' => \&unknownCallback,
        'bailout' => \&bailoutCallback,
        'EOF'     => \&EOFCallback,
        'plan'    => \&planCallback,
    };

    my $esopts = {
        'server.host'       => delete $opts->{'server.host'},
        'server.port'       => delete $opts->{'server.port'},
        'client.indexer'    => delete $opts->{'client.indexer'},
        'client.versioner'  => delete $opts->{'client.versioner'} // 'Default',
        'client.blamer'     => delete $opts->{'client.blamer'} // 'Default',
        'client.platformer' => delete $opts->{'client.platformer'} // 'Default',
        'client.autodiscover' => delete $opts->{'client.autodiscover'},
    };

    my $self = $class->SUPER::new($opts);
    if (ref($self->{'_iterator'}->{'command'}) eq 'ARRAY') {
        $self->{'file'} = $self->{'_iterator'}->{'command'}->[-1];
        print "# PROCESSING RESULTS FROM TEST FILE: $self->{'file'}\n";
    }

    my $indexer = $esopts->{'client.indexer'};
    _require_indexer($indexer);
    my $versioner =
      App::Prove::Elasticsearch::Utils::require_versioner($esopts);
    my $platformer =
      App::Prove::Elasticsearch::Utils::require_platformer($esopts);
    my $blamer = App::Prove::Elasticsearch::Utils::require_blamer($esopts);

    $self->{executor} =
      &{\&{$blamer . "::get_responsible_party"}}($self->{file});
    $self->{sut_version} = &{\&{$versioner . "::get_version"}}($self->{file});
    $self->{platform}    = &{\&{$platformer . "::get_platforms"}}();
    $self->{indexer}     = $indexer;

    $self->{test_version} =
      &{\&{$versioner . "::get_file_version"}}($self->{file});
    $self->{steps}     = [];
    $self->{starttime} = [ Time::HiRes::gettimeofday() ];
    $self->{es_opts}   = $esopts;
    return $self;
}

sub _require_indexer {
    my $indexer = shift;
    eval "require $indexer" or die "cannot find needed indexer $indexer";
}

# Look for file boundaries, etc.
sub unknownCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    #Unofficial "Extensions" to TAP
    my ($status_override) = $line =~ m/^% mark_status=([A-Z|_]*)/;
    $self->{global_status} = $status_override if $status_override;

    return;
}

# Register the current suite or test desc for use by test callback, if the line begins with the special magic words
sub commentCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    return;
}

sub testCallback {
    my ($test) = @_;
    my $self = $test->{'parser'};

    my $line = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    $line =~ s/^(ok|not ok)\s[0-9]*\s-\s//g;
    my $test_name = $line;

    #Setup args to pass to function
    my $status_name = 'NOT OK';
    if ($test->is_actual_ok()) {
        $status_name = 'OK';
        if ($test->has_skip()) {
            $status_name = 'SKIP';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# skip //gi;
        }
        if ($test->has_todo()) {
            $status_name = 'TODO PASS';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# todo & skip //gi;    #handle todo_skip
            $test_name =~ s/# todo\s(.*)$//gi;
        }
    } else {
        if ($test->has_todo()) {
            $status_name = 'TODO FAIL';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# todo & skip //gi;    #handle todo_skip
            $test_name =~ s/# todo\s(.*)$//gi;
        }
    }

    #XXX much of the above code would be unneeded if $test->description wasn't garbage
    $test_name =~ s/\s+$//g;

    #Test done.  Record elapsed time.
    my $tm = [ Time::HiRes::gettimeofday() ];
    $self->{lasttime} //= $self->{starttime};
    push(
        @{$self->{steps}},
        {
            elapsed => Time::HiRes::tv_interval($self->{'lasttime'}, $tm),
            step   => $test->number,    #XXX TODO maybe this isn't right
            name   => $test_name,
            status => $status_name,
        }
    );
    $self->{lasttime} = $tm;

    return 1;
}

sub bailoutCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";
    $self->{'is_bailout'} = 1;
    return;
}

sub EOFCallback {
    my ($self) = @_;

    #Test done.  Record elapsed time.
    $self->{'elapsed'} = Time::HiRes::tv_interval($self->{'starttime'});

    my $todo_failed = $self->todo() - $self->todo_passed();

    my $status = 'OK';

    $status = 'NOT OK' if $self->has_problems();

    $status = 'TODO PASSED'
      if $self->todo_passed()
      && !$self->failed()
      && $self->is_good_plan();    #If no fails, but a TODO pass, mark as TODOP

    $status = 'TODO FAILED'
      if $todo_failed
      && !$self->failed()
      && $self->is_good_plan()
      ;    #If no fails, but a TODO fail, prefer TODOF to TODOP

    $status = "SKIPPED" if $self->skip_all();    #Skip all, whee

    $status = "BAIL OUT" if $self->{is_bailout};

    #Global status override
    $status = $self->{'global_status'} if $self->{'global_status'};
    return if $status eq 'DISCARD';

    #Notify user about bad plan a bit better, supposing we haven't bailed
    if (!$self->is_good_plan() && !$self->{'is_bailout'}) {
        $self->{'raw_output'} .=
            "\n# ERROR: Bad plan.  You ran "
          . $self->tests_run
          . " tests, but planned "
          . $self->tests_planned . ".";
    }

    $self->{upload} = {
        body    => $self->{raw_output},
        elapsed => $self->{elapsed},
        occurred =>
          strftime("%Y-%m-%d %H:%M:%S", localtime($self->{starttime}->[0])),
        status        => $status,
        platform      => $self->{platform},
        executor      => $self->{executor},
        version       => $self->{sut_version},
        test_version  => $self->{test_version},
        name          => basename($self->{file}),
        path          => dirname($self->{file}),
        steps         => $self->{steps},
        steps_planned => $self->tests_planned
    };

    &{\&{$self->{indexer} . "::index_results"}}($self->{upload});
    return $status;
}

sub planCallback {
    my ($plan) = @_;
    my $self = $plan->{'parser'};
    $self->{raw_output} .= $plan->as_string . "\n";
}

sub make_result {
    my ($self, @args) = @_;
    my $res = $self->SUPER::make_result(@args);
    $res->{'parser'} = $self;
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Elasticsearch::Parser - Capture the output of prove, and upload the results of the test to elasticsearch

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    App::Prove::Elasticsearch::Parser->new();

=head1 CONSTRUCTOR

=head2 new

Creates a TAP::Parser that will upload test results to your repository using the provided indexer.

=head1 OVERRIDDEN CALLBACKS

=head2 unknownCallback

Checks for status overrides (% mark_status=DISCARD) and records unknown lines for later upload.

=head2 commentCallback

=head2 planCallback

=head2 bailoutCallback

These do little more than record the information printed during prove for upload to the result index.

=head2 testCallback

Captures step information and runtime, along with the raw text of the assertion.

=head2 EOFCallback

Actually does the uploading of the result to the index.

Sets test global status as the 'most anomalous' result encountered in the test in the following order (most to least):

=over 4

=item Bailout

=item Skipped (when skip_all happens)

=item Failed

=item Todo Passed

=item Todo Failed

=back

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://https://github.com/teodesian/App-Prove-Elasticsearch>
and may be cloned from L<git://https://github.com/teodesian/App-Prove-Elasticsearch.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
