package analogize;
# ABSTRACT: classify data with AM from the command line
use strict;
use warnings;
our $VERSION = '3.10';
use 5.010;
use Carp;
use Algorithm::AM::Batch;
use Path::Tiny;
# 2.13 needed for aliases
use Getopt::Long 2.13 qw(GetOptionsFromArray);
use Pod::Usage;

_run(@ARGV) unless caller;

sub _run {
    my %args = (
        # defaults here...
    );
    GetOptionsFromArray(\@_, \%args,
        'format=s',
        'exemplars|train|data:s',
        'project:s',
        'test:s',
        'print:s',
        'include_given',
        'include_nulls',
        'linear',
        'help|?',
    ) or pod2usage(2);
    _validate_args(%args);

    my @print_methods;
    if($args{print}){
        @print_methods = split ',', $args{print};
    }

    my ($train, $test);
    if($args{exemplars}){
        $train = dataset_from_file(
            path => $args{exemplars},
            format => $args{format});
    }
    if($args{test}){
        $test = dataset_from_file(
            path => $args{test},
            format => $args{format});
    }
    if($args{project}){
        $train = dataset_from_file(
            path => path($args{project})->child('data'),
            format => $args{format});
        if(path($args{project})->child('test')->exists){
            $test = dataset_from_file(
                path => path($args{project})->child('test'),
                format => $args{format});
        }else{
            $test = $train;
        }
    }
    # default to leave-one-out if no test set specified
    $test ||= $train;

    my $count = 0;
    my $batch = Algorithm::AM::Batch->new(
        linear => $args{linear},
        exclude_given => !$args{include_given},
        exclude_nulls => !$args{include_nulls},

        training_set => $train,
        # print the result of each classification at the time it is provided
        end_test_hook => sub {
            my ($batch, $test_item, $result) = @_;
            ++$count if $result->result eq 'correct';
            say $test_item->comment . ":\t" . $result->result . "\n";
            for (@print_methods) {
                if($_ eq 'gang_detailed'){
                    say ${ $result->gang_summary(1) };
                }else{
                    say ${ $result->$_ };
                }
            }
        }
    );
    $batch->classify_all($test);

    say "$count out of " . $test->size . " correct";
    return;
}

sub _validate_args {
    my %args = @_;
    if($args{help}){
        pod2usage(1);
    }
    my $errors = '';
    if(!$args{exemplars} and !$args{project}){
        $errors .= "Error: need either --exemplars or --project parameters\n";
    }elsif(($args{exemplars} or $args{test}) and $args{project}){
        $errors .= "Error: --project parameter cannot be used with --exempalrs or --test\n";
    }
    if(!defined $args{format}){
        $errors .= "Error: missing --format parameter\n";
    }elsif($args{format} !~ m/^(?:no)?commas$/){
        $errors .=
            "Error: --format parameter must be either 'commas' or 'nocommas'\n";
    }
    if($args{print}){
        my %allowed =
            map {$_ => 1} qw(
                config_info
                statistical_summary
                analogical_set_summary
                gang_summary
                gang_detailed
            );
        for my $param (split ',', $args{print}){
            if(!exists $allowed{$param}){
                $errors .= "Error: unknown print parameter '$param'\n";
            }
        }
    }
    if($errors){
        $errors .= 'use "analogize --help" for detailed usage information';
        chomp $errors;
        pod2usage($errors);
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

analogize - classify data with AM from the command line

=head1 VERSION

version 3.10

=head1 SYNOPSIS

analogize --format <format> [--exemplars <file>] [--test <file>]
[--project <dir>] [--print <config_info,statistical_summary,
analogical_set_summary,gang_summary,gang_detailed>]
[--help]

=head1 DESCRIPTION

Classify data with analogical modeling from the command line.
Required arguments are B<format> and either B<exemplars> or
B<project>. You can use old AM::Parallel projects (a directory
containing C<data> and C<test> files) or specify individual data
and test files. By default, only the accuracy of the predicted
outcomes is printed. More detail may be printed using the B<print>
option.

=head1 OPTIONS

=over

=item B<format>

specify either commas or nocommas format for exemplar and test data files
(C<=> should be used for "null" variables). See L<Algorithm::AM::DataSet/dataset_from_file>
for details on the two formats.

=item C<exemplars>, C<data> or C<train>

path to the file containing the examplar/training data

=item C<project>

path to an AM::Parallel-style project (ignores 'outcome' file); this
should be a directory containing a file called C<data> containing known
exemplars and C<test> containing test exemplars. If the C<test> file does
not exist, then a leave-one-out scheme is used for testing using the
exemplars in the C<data> file.

=item C<test>

path to the file containing the test data. If none is specified,
performs leave-one-out classification with the exemplar set.

=item C<print>

reports to print, separated by commas (be careful not to add spaces between report names!).
For example, C<--print analogical_set_summary,gang_summary> would print
analogical sets and gang summaries.

Available options are:

=over

=item C<config_info>

Describes the configuration used and some simple information about the data,
i.e. cardinality, etc.

=item C<statistical_summary>

A statistical summary of the classification results, including
all predicted outcomes with their scores and percentages and
the total score for all outcomes. Whether the predicted class is
correct, incorrect, or a tie is also included, if the test item
had a known class.

=item C<analogical_set_summary>

The analogical set, showing all items that contributed to the predicted
outcome, along with the amount contributed by each item (score and
percentage overall).

=item C<gang_summary>

A summary of the gang effects on the outcome prediction.

=item C<gang_detailed>

Same as C<gang_summary>, but also includes lists of exemplars for each
gang.

=back

=item C<include_given>

Allow a test item to be included in the data set during classification.
If false (default), test items will be removed from the dataset during
classification.

=item C<include_nulls>

Treat null variables in a test item as regular variables. If false (default),
these variables will be excluded and not considered during classification.

=item C<linear>

Calculate scores using I<occurrences> (linearly) instead of using I<pointers>
(quadratically).

=item C<help> or C<?>

print help message

=back

=head2 EXAMPLES

This distribution comes with a sample dataset in the C<datasets/soybean>
directory. Data exemplars are in C<data> and a single test exemplar is in C<test>.
The files are in the C<commas> format. The following two commands are equivalent
and will analyze the test exemplar and output a summary of gang effects to C<gang.txt>:

    analogize --exemplars datasets/soybean/data --test datasets/soybean/test --format commas --print gang_summary > gang.txt

    analogize --project datasets/soybean --format commas --print gang_summary > gang.txt

The resulting files are best viewed in a text editor with word wrap turned I<off>.

=head1 AUTHOR

Theron Stanford <shixilun@yahoo.com>, Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Royal Skousen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
