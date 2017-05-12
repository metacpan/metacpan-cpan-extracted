package Benchmark::Perl::Formance::Analyzer::BenchmarkAnything;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Benchmark::Perl::Formance - analyze results using BenchmarkAnything backend store
$Benchmark::Perl::Formance::Analyzer::BenchmarkAnything::VERSION = '0.007';
use 5.010;

use Moose;
use File::Find::Rule;
use Data::DPath "dpath";
use Data::Dumper;
use TryCatch;
use version 0.77;
use Data::Structure::Util 'unbless';
use File::ShareDir 'dist_dir';
use BenchmarkAnything::Storage::Frontend::Lib;
use Template;
use JSON 'decode_json';

with 'MooseX::Getopt::Usage',
 'MooseX::Getopt::Usage::Role::Man';

has 'subdir'     => ( is => 'rw', isa => 'ArrayRef', documentation => "where to search for benchmark results", default => sub{[]} );
has 'name'       => ( is => 'rw', isa => 'ArrayRef', documentation => "file name pattern" );
has 'outfile'    => ( is => 'rw', isa => 'Str',      documentation => "output file" );
has 'verbose'    => ( is => 'rw', isa => 'Bool',     documentation => "Switch on verbosity" );
has 'debug'      => ( is => 'rw', isa => 'Bool',     documentation => "Switch on debugging output" );
has 'whitelist'  => ( is => 'rw', isa => 'Str',      documentation => "metrics to use (regular expression)" );
has 'blacklist'  => ( is => 'rw', isa => 'Str',      documentation => "metrics to skip (regular expression)" );
has 'dropnull'   => ( is => 'rw', isa => 'Bool',     documentation => "Drop metrics with null values", default => 0 );
has 'query'      => ( is => 'rw', isa => 'Str',      documentation => "Search query file or '-' for STDIN", default => "-" );
has 'balib'      => ( is => 'rw',                    documentation => "where to search for benchmark results", default => sub { BenchmarkAnything::Storage::Frontend::Lib->new } );
has 'template'   => ( is => 'rw', isa => 'Str',
                      documentation => 'output template file',
                      default => 'google-chart-area',
                      #default => 'google-chart-line',
                    );
has 'tt'         => ( is => 'rw',
                      documentation => "template renderer",
                      default => sub
                      {
                              Template->new({
                                             INCLUDE_PATH => dist_dir('Benchmark-Perl-Formance-Analyzer')."/templates", # or list ref
                                             INTERPOLATE  => 0,       # expand "$var" in plain text
                                             POST_CHOMP   => 0,       # cleanup whitespace
                                             EVAL_PERL    => 0,       # evaluate Perl code blocks
                                            });
                      }
                    );
has 'x_key'       => ( is => 'rw', isa => 'Str',      documentation => "x-axis key",  default => "perlconfig_version" );
has 'x_type'      => ( is => 'rw', isa => 'Str',      documentation => "x-axis type", default => "version" ); # version, numeric, string, date
has 'y_key'       => ( is => 'rw', isa => 'Str',      documentation => "y-axis key",  default => "VALUE" );
has 'y_type'      => ( is => 'rw', isa => 'Str',      documentation => "y-axis type", default => "numeric" );
has 'aggregation' => ( is => 'rw', isa => 'Str',      documentation => "which aggregation to use (avg, stdv, ci_95_lower, ci_95_upper)", default => "avg" );     # sub entries of {stats}: avg, stdv, ci_95_lower, ci_95_upper
has 'querybundle' => ( is => 'rw', isa => 'Str',      documentation => "which chartqueries/ subdirectory (e.g., perlformance, perlstone2015)", default => 'perlstone2015' );
has '_rawnumbers'  => ( is => 'rw', isa => 'Str',      default => "" );

use namespace::clean -except => 'meta';
__PACKAGE__->meta->make_immutable;
no Moose;

sub print_version
{
        my ($self) = @_;

        if ($self->verbose)
        {
                print STDERR "Benchmark::Perl::Formance::Analyzer version $Benchmark::Perl::Formance::Analyzer::VERSION\n";
        }
        else
        {
                print STDERR $Benchmark::Perl::Formance::Analyzer::VERSION, "\n";
        }
}

sub _print_to_template
{
        my ($self, $RESULTMATRIX, $options) = @_;

        require JSON;
        my $outfile = $options->{outfile};

        my $vars = {
                    RESULTMATRIX     => JSON->new->pretty->encode($RESULTMATRIX),
                    title            => ($options->{charttitle} || ""),
                    modulename       => ($options->{modulename} || ""),
                    outfile          => $outfile,
                    x_key            => $options->{x_key},
                    isStacked        => $options->{isStacked},
                    interpolateNulls => $options->{interpolateNulls},
                    areaOpacity      => $options->{areaOpacity},
                    width            => 700,
                    height           => 500,
                   };

        my $template = $self->template.".tt";
        $self->tt->process($template, $vars, ($outfile eq '-' ? () : $outfile))
         or die $self->tt->error."\n";
}

sub _print_to_template_multi
{
        my ($self, $chartlist, $options) = @_;

        require JSON;

        my $number = 0;
        my @extended_chartlist = map
        {
                $_->{json} = JSON->new->pretty->encode($_->{data});
                $_->{number} = $number++;
                $_
        } @$chartlist;

        # print
        my $vars = {
                    querybundle      => $options->{querybundle},
                    chartlist        => \@extended_chartlist,
                    width            => $options->{width} || 300,
                    height           => $options->{height} || 200,
                    x_key            => $options->{x_key},
                    isStacked        => $options->{isStacked},
                    interpolateNulls => $options->{interpolateNulls},
                    areaOpacity      => $options->{areaOpacity},
                   };
        my $template_multi = $self->template."_multi.tt";
        my $resultbuffer;
        $self->tt->process($template_multi, $vars, \$resultbuffer)
         or die $self->tt->error."\n";
        return $resultbuffer;
}

sub _get_chart
{
        my ($self, $chartname) = @_;

        require File::Slurper;

        my $querybundle = $self->querybundle;
        my $filename = dist_dir('Benchmark-Perl-Formance-Analyzer')."/chartqueries/$querybundle/$chartname.json";
        my $json = File::Slurper::read_text($filename);
        if ($self->debug) {
                say STDERR "READ: $chartname - $filename";
                say STDERR "JSON:\n$json";
        }
        return decode_json($json);
}

sub _search
{
        my ($self, $chartline_queries) = @_;

        $self->balib->connect;

        my @results;
        foreach my $q (@{$chartline_queries})
        {
                push @results,
                {
                 title   => $q->{title},
                 results => $self->balib->search($q->{query}),
                };
        }

        return \@results;
}

sub run
{
        my ($self) = @_;

        require File::Find::Rule;
        require File::Basename;
        require BenchmarkAnything::Evaluations;

        my $timestamp = ~~gmtime;
        my $headline  = "Perl::Formance - charts rendered at: $timestamp\n\n";
        $headline    .= "ci95l - confidence intervall 95 lower\n";
        $headline    .= "ci95u - confidence intervall 95 upper\n";
        $headline    .= "avg   - average\n";
        $headline    .= "stdv  - standard deviation\n";
        say STDERR sprintf($headline) if $self->verbose;
        $self->_rawnumbers($self->_rawnumbers.$headline);

        my $querybundle = $self->querybundle;

        my @chartnames =
         map { File::Basename::basename($_, ".json") }
          File::Find::Rule
                   ->file
                    ->name( '*.json' )
                     ->in( dist_dir('Benchmark-Perl-Formance-Analyzer')."/chartqueries/$querybundle/" );

        my @chartlist;
        foreach my $chartname (sort @chartnames)
        {

                my $chart             = $self->_get_chart($chartname);
                my $chartlines        = $self->_search($chart->{chartlines});
                my $transform_options = {
                                         x_key       => $self->x_key,
                                         x_type      => $self->x_type,
                                         y_key       => $self->y_key,
                                         y_type      => $self->y_type,
                                         aggregation => $self->aggregation,
                                         verbose     => $self->verbose,
                                         debug       => $self->debug,
                                        };
                my ($result_matrix, $rawnumbers) = BenchmarkAnything::Evaluations::transform_chartlines($chartlines, $transform_options);
                $self->_rawnumbers($self->_rawnumbers."\n$rawnumbers");

                my $outfile;
                if (not $outfile  = $self->outfile)
                {
                        require File::HomeDir;
                        $outfile  =  $chartname;
                        $outfile  =~ s/[\s\W:]+/-/g;
                        $outfile .=  ".html";
                        $outfile  = File::HomeDir->my_home . "/perlformance/results/$querybundle/".$outfile;
                }

                my $render_options = {
                                      x_key            => $self->x_key,
                                      charttitle       => ($chart->{charttitle} || $chartname),
                                      modulename       => $chart->{modulename},
                                      isStacked        => "false", # true, false, 'relative'
                                      interpolateNulls => "true", # true, false -- only works with isStacked=false
                                      areaOpacity      => 0.0,
                                      outfile          => $outfile,
                                     };
                $self->_print_to_template($result_matrix, $render_options);

                push @chartlist, {
                                  outfile    => File::Basename::basename($outfile),
                                  data       => $result_matrix,
                                  charttitle => ($chart->{charttitle} || $chartname),
                                  modulename => $chart->{modulename},
                                 };
                say STDERR "Done." if $self->verbose;

        }

        # DASHBOARD
        my $dashboard_options = {
                                 x_key            => $self->x_key,
                                 isStacked        => "false", # true, false, 'relative'
                                 interpolateNulls => "true",  # true, false -- only works with isStacked=false
                                 areaOpacity      => 0.0,
                                 querybundle      => $querybundle,
                                };
        my $dashboard_file    = File::HomeDir->my_home . "/perlformance/results/$querybundle/index.html";
        my $dashboard_content = $self->_print_to_template_multi(\@chartlist, $dashboard_options);
        open my $DASHBOARD, ">", $dashboard_file or die "Could not write to $dashboard_file";
        print $DASHBOARD $dashboard_content;
        close $DASHBOARD;

        # RAW NUMBERS
        my $rawnumbers_file    = File::HomeDir->my_home . "/perlformance/results/$querybundle/raw-numbers.txt";
        open my $RAWNUMBERS, ">", $rawnumbers_file or die "Could not write to $rawnumbers_file";
        print $RAWNUMBERS $self->_rawnumbers;
        close $RAWNUMBERS;

        # Done
        return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Analyzer::BenchmarkAnything - Benchmark::Perl::Formance - analyze results using BenchmarkAnything backend store

=head1 SYNOPSIS

Usage:

  $ benchmark-perlformance-process-benchmarkanything

=head1 ABOUT

Analyze L<Benchmark::Perl::Formance|Benchmark::Perl::Formance> results.

This is a commandline tool to process Benchmark::Perl::Formance
results which follow the
L<BenchmarkAnything|http://benchmarkanything.org> schema as produced
with C<benchmark-perlformance --benchmarkanything>.

=head1 METHODS

=head2 run

Entry point to actually start.

=head2 print_version

Print version.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
