use 5.006;
use strict;
use warnings;

package Data::Freq;

=head1 NAME

Data::Freq - Collects data, counts frequency, and makes up a multi-level counting report

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

our $ROOT_VALUE = 'Total';

use Carp qw(croak);
use Data::Freq::Field;
use Data::Freq::Node;
use Data::Freq::Record;
use List::Util qw(max);
use Scalar::Util qw(blessed openhandle);

=head1 SYNOPSIS

    use Data::Freq;
    
    my $data = Data::Freq->new('date');
    
    while (my $line = <STDIN>) {
        $data->add($line);
    }
    
    $data->output();

=head1 DESCRIPTION

C<Data::Freq> is an object-oriented module to collect data from log files
or any kind of data sources, count frequency of particular patterns,
and generate a counting report.

See also the command-line tool L<data-freq>.

The simplest usage is to count lines of a log files in terms of a particular category
such as date, username, remote address, and so on.

For more advanced usage, C<Data::Freq> is capable of aggregating counting results
at multiple levels.
For example, lines of a log file can be grouped into I<months> first,
and then under each of the months, they can be further grouped into individual I<days>,
where all the frequency of both months and days is summed up consistently.

=head2 Analyzing an Apache access log

The example below is a copy from the L</SYNOPSIS> section.

    my $data = Data::Freq->new('date');
    
    while (my $line = <STDIN>) {
        $data->add($line);
    }
    
    $data->output();

It will generate a report that looks something like this:

    123: 2012-01-01
    456: 2012-01-02
    789: 2012-01-03
    ...

where the left column shows the number of occurrences of each date.

The date/time value is automatically extracted from the log line,
where the first field enclosed by a pair of brackets C<[...]>
is parsed as a date/time text by the C<Date::Parse::str2time()> function.
(See L<Date::Parse>.)

See also L<Data::Freq::Record/logsplit>.

=head2 Multi-level counting

The initialization parameters for the L<new()|/new> method can be customized
for a multi-level analysis.

If the field specifications are given, e.g.

    Data::Freq->new(
        {type => 'date'},           # field spec for level 1
        {type => 'text', pos => 2}, # field spec for level 2
    );
    # assuming the position 2 (third portion, 0-based)
    # is the remote username.

then the output will look like this:

    123: 2012-01-01
        100: user1
         20: user2
          3: user3
    456: 2012-01-02
        400: user1
         50: user2
          6: user3
    ...

Below is another example along this line:

    Data::Freq->new('month', 'day');
        # Level 1: 'month'
        # Level 2: 'day'

with the output:

    12300: 2012-01
          123: 2012-01-01
          456: 2012-01-02
          789: 2012-01-03
          ...
    45600: 2012-02
          456: 2012-02-01
          789: 2012-02-02
        ...

See L</field specification> for more details about the initialization parameters.

=head2 Custom input

The data source is not restricted to log files.
For example, a CSV file can be analyzed as below:

    my $data = Data::Freq->new({pos => 0}, {pos => 1});
    # or more simply, Data::Freq->new(0, 1);
    
    open(my $csv, 'source.csv');
    
    while (<$csv>) {
        $data->add([split /,/]);
    }

Note: the L<add()|/add> method accepts an array ref,
so that the input does not have to be split by the default
L<Data::Freq::Record/logsplit> function.

For more generic input data, a hash ref can also be given
to the L<add()|/add> method.

E.g.

    my $data = Data::Freq->new({key => 'x'}, {key => 'y'});
    # Note: keys *cannot* be abbrebiated like Data::Freq->new('x', 'y')
    
    $data->add({x => 'foo', y => 'abc'});
    $data->add({x => 'bar', y => 'def'});
    $data->add({x => 'foo', y => 'ghi'});
    $data->add({x => 'bar', y => 'jkl'});
    ...

In the field specifications, the value of C<pos> or C<key> can also be an array ref,
where the multiple elements selected by the C<pos> or C<key> will be C<join>'ed
by a space (or the value of C<$">).

This is useful when a log format contains a date that is not enclosed by a pair of
brackets C<[...]>.

E.g.

    my $data = Data::Freq->new({type => 'date', pos => [0..3]});
    
    # Log4x with %d{dd MMM yyyy HH:mm:ss,SSS}
    $data->add("01 Jan 2012 01:02:03,456 INFO - test log\n");
    
    # pos 0: "01"
    # pos 1: "Jan"
    # pos 2: "2012"
    # pos 3: "01:02:03,456"

As a result, "01 Jan 2012 01:02:03,456" will be parsed as a date string.

=head2 Custom output

The L<output()|/output> method accepts different types of parameters as below:

=over 4

=item * A file handle or an instance of C<IO::*>

By default, the result is printed out to C<STDOUT>.
With this parameter given, it can be any other output destination.

=item * A callback subroutine ref

If a callback is specified, it will be invoked with a node object (L<Data::Freq::Node>)
passed as an argument.
See L</frequency tree> for more details about the tree structure.

Roughly, each node represents a counting result for each line
in the default output format, in the depth-first order (i.e. the same order
as the default output lines).

    $data->output(sub {
        my $node = shift;
        print "Count: ", $node->count, "\n";
        print "Value: ", $node->value, "\n";
        print "Depth: ", $node->depth, "\n";
        print "\n";
    });

=item * A hash ref of options to control output format

    $data->output({
        with_root  => 0     , # also prints total (root node)
        transpose  => 0     , # prints values before counts
        indent     => '    ', # repeats (depth - 1) times
        separator  => ': '  , # separates the count and the value
        prefix     => ''    , # prepended before the count
        no_padding => 0     , # disables padding for the count
    });

=item * The format option can be specified together with a file handle.

    $data->output(\*STDERR, {indent => "\t"});

=back

The output does not include the grand total by default.
If the C<with_root> option is set to a true value, the total count will be printed
as the first line (level 0), and all the subsequent levels will be shifted to the right.

The C<transpose> option flips the order of the count and the value in each line. E.g.

    2012-01: 12300
        2012-01-01: 123
        2012-01-02: 456
        2012-01-03: 789
        ...
    2012-02: 45600
        2012-02-01: 456
        2012-02-02: 789
        ...

The indent unit (repeated appropriate times) and the separator
(between the count and the value) can be customized with the respective options,
C<indent> and C<separator>.

The default output format has apparent ambiguity between the indent
and the padding for alignment.

For example, consider the output below:

    1200000: Level 1
         900000: Level 2
             900000: Level 3
              5: Level 2
    ...

where the second "Level 2" appears to have a deeper indent than the "Level 3."

Although the positions of colons (C<:>) are consistently aligned,
it may seem to be slightly inconsistent.

The indent depth will be clearer if a C<prefix> is added:

    $data->output({prefix => '* '});
    
    * 1200000: Level 1
        *  900000: Level 2
            *  900000: Level 3
        *       5: Level 2
    ...

Alternatively, the C<no_padding> option can be set to a true value
to disable the left padding.

    $data->output({no_padding => 1});
    
    1200000: Level 1
        900000: Level 2
            900000: Level 3
        5: Level 2
    ...

=head2 Field specification

Each argument passed to the L<new()|/new> method is passed to the L<Data::Freq::Field/new> method.

For example,

    Data::Freq->new(
        'month',
        'day',
    );
    
is equivalent to

    Data::Freq->new(
        Data::Freq::Field->new('month'),
        Data::Freq::Field->new('day'),
    );

and because of the way the argument is interpreted by the L<Data::Freq::Field> class,
it is also equivalent to

    Data::Freq->new(
        Data::Freq::Field->new({type => 'month'}),
        Data::Freq::Field->new({type => 'day'}),
    );

=over 4

=item * C<< type => { 'text' | 'number' | 'date' } >>

The basic data types are C<'text'>, C<'number'>, and C<'date'>,
which determine how each input data is normalized for the frequency counting,
and how the results are sorted.

The C<'date'> type can also be written as the format string for C<POSIX::strftime()> function.
(See L<POSIX>.)

    Data::Freq->new('%Y-%m');
    
    Data::Freq->new({type => '%H'});

If the type is simply specified as C<'date'>, the format defaults to C<'%Y-%m-%d'>.

In addition, the keywords below can be used as synonims:

    'year'  : equivalent to '%Y'
    'month' : equivalent to '%Y-%m'
    'day'   : equivalent to '%Y-%m-%d'
    'hour'  : equivalent to '%Y-%m-%d %H'
    'minute': equivalent to '%Y-%m-%d %H:%M'
    'second': equivalent to '%Y-%m-%d %H:%M:%S'

=item * C<< aggregate => { 'unique' | 'max' | 'min' | 'average' } >>

The C<aggregate> parameter alters how each C<count> is calculated,
where the default C<count> is equal to the sum of all the C<count>'s for its child nodes.

    'unique' : the number of distinct child values
    'max'    : the maximum count of the child nodes
    'min'    : the minimum count of the child nodes
    'average': the average count of the child nodes

=item * C<< sort => { 'value' | 'count' | 'first' | 'last' } >>

The C<sort> parameter is used as the key by which the group of records
will be sorted for the output.

    'value': sort by the normalized value
    'count': sort by the frequency count
    'first': sort by the first occurrence in the input
    'last' : sort by the last occurrence in the input

=item * C<< order => { 'asc' | 'desc' } >>

The C<order> parameter controls the sorting in the either ascending or descending order.

=item * C<< pos => { 0, 1, 2, -1, -2, ... } >>

If the C<pos> parameter is given or an integer value (or a list of integers) is given
without a parameter name, the value whose frequency is counted will be selected
at the indices from an array ref input or a text split
by the L<logsplit()|Data::Freq::Record/logsplit> function.

=item * C<< key => { any key(s) for input hash refs } >>

If the C<pos> parameter is given, it is assumed that the input is a hash ref,
where the value whose frequency is counted will be selected by the specified key(s).

=item * C<< convert => sub {...} >>

If the C<convert> parameter is set to a subroutine ref,
it is invoked to convert the value to a normalized form for frequency counting.

The subroutine is expected to take one string argument and return a converted string.

=back

If the C<type> parameter is either C<text> or C<number>,
the results are sorted by C<count> in the descending order by default
(i.e. the most frequent value first).

For the C<date> type, the C<sort> parameter defaults to C<value>,
and the C<order> parameter defaults to C<asc>
(i.e. the time-line order).

=head2 Frequency tree

Once all the data have been collected with the L<add()|/add> method,
a C<frequency tree> has been constructed internally.

Suppose the C<Data::Freq> instance is initialized with the two fields as below:

   my $field1 = Data::Freq::Field->new({type => 'month'});
   my $field2 = Data::Freq::Field->new({type => 'text', pos => 2});
   my $data = Data::Freq->new($field1, $field2);
   ...

a result tree that looks like below will be constructed as each data record is added:

     Depth 0            Depth 1             Depth 2
                        $field1             $field2

    {432: root}--+--{123: "2012-01"}--+--{10: "user1"}
                 |                    +--{ 8: "user2"}
                 |                    +--{ 7: "user3"}
                 |                    ...
                 +--{135: "2012-02"}--+--{11: "user3"}
                 |                    +--{ 9: "user2"}
                 |                    ...
                 ...

In the diagram, a node is represented by a pair of braces C<{...}>,
and each integer value is the total number of occurrences of the node value,
under its parent category.

The root node maintains the grand total of records that have been added.

The tree structure can be recursively visited by the L<traverse()|/traverse> method.

Below is an example to generate a HTML:

    print qq(<ul>\n);
    
    $data->traverse(sub {
        my ($node, $children, $recurse) = @_;
        
        my ($count, $value) = ($node->count, $node->value);
            # HTML-escape $value if necessary
        
        print qq(<li>$count: $value);
        
        if (@$children > 0) {
            print qq(\n<ul>\n);
            
            for my $child (@$children) {
                $recurse->($child); # invoke recursion
            }
            
            print qq(</ul>\n);
        }
        
        print qq(</li>\n);
    });
    
    print qq(</ul>\n);

=head1 METHODS

=head2 new

Usage:

    Data::Freq->new($field1, $field2, ...);

Constructs a C<Data::Freq> object.

The arguments C<$field1>, C<$field2>, etc. are instances of L<Data::Freq::Field>,
or any valid arguments that can be passed to L<Data::Freq::Field/new>.

The actual data to be analyzed need to be added by the L<add()|/add> method one by one.

The C<Data::Freq> object maintains the counting results, based on the specified fields.
The first field (C<$field1>) is used to group the added data into the major category.
The next subsequent field (C<$field2>) is for the sub-category under each major group.
Any more subsequent fields are interpreted recursively as sub-sub-category, etc.

If no fields are given to the L<new()|/new> method, one field of the C<text> type will be assumed.

=cut

sub new {
    my $class = shift;
    
    my $fields = eval {[map {
        blessed($_) && $_->isa('Data::Freq::Field') ?
                $_ : Data::Freq::Field->new($_)
    } (@_ ? (@_) : ('text'))]};
    
    croak $@ if $@;
    
    return bless {
        root   => Data::Freq::Node->new($ROOT_VALUE),
        fields => $fields,
    }, $class;
}

=head2 add

Usage:

    $data->add("A record");
    
    $data->add("A log line text\n");
    
    $data->add(['Already', 'split', 'data']);
    
    $data->add({key1 => 'data1', key2 => 'data2', ...});

Adds a record that increments the counting by 1.

The interpretation of the input depends on the type of fields specified in the L<new()|/new> method.
See L<Data::Freq::Field/evaluate_record>.

=cut

sub add {
    my $self = shift;
    
    for my $input (@_) {
        my $record = Data::Freq::Record->new($input);
        
        my $node = $self->root;
        $node->{count}++;
        
        for my $field (@{$self->fields}) {
            my $value = $field->evaluate_record($record);
            last unless defined $value;
            $node = $node->add_subnode($value);
        }
    }
    
    return $self;
}

=head2 output

Usage:

    # I/O
    $data->output();      # print results (default format)
    $data->output(\*OUT); # print results to open handle
    $data->output($io);   # print results to IO::* object
    
    # Callback
    $data->output(sub {
        my $node = shift;
        # $node is a Data::Freq::Node instance
    });
    
    # Options
    $data->output({
        with_root  => 0   , # if true, prints total at root
        transpose  => 0   , # if true, prints values before counts
        indent     => '  ', # repeats (depth - 1) times
        separator  => ': ', # separates the count and the value
        prefix     => ''  , # prepended before the count
        no_padding => 0   , # if true, disables padding for the count
    });
    
    # Combination
    $data->output(\*STDERR, {opt => ...});
    $data->output($open_fh, {opt => ...});

Generates a report of the counting results.

If no arguments are given, default format results are printed out to C<STDOUT>.
Any open handle or an instance of C<IO::*> can be passed as the output destination.

If the argument is a subroutine ref, it is regarded as a callback
that will be called for each node of the I<frequency tree> in the depth-first order.
(See L</frequency tree> for details.)

The following arguments are passed to the callback:

=over 4

=item * $node: Data::Freq::Node

The current node (L<Data::Freq::Node>)

=item * $children: [$child_node1, $child_node2, ...]

An array ref to the list of child nodes, sorted based on the field

Note: C<< $node->children >> is a hash ref (unsorted) of a raw counting data.

=back

=cut

sub output {
    my $self = shift;
    my ($fh, $callback, $opt);
    
    for (@_) {
        if (openhandle($_)) {
            $fh = $_;
        } elsif (ref $_ eq 'HASH') {
            $opt = $_;
        } else {
            $callback = $_;
        }
    }
    
    $opt ||= {};
    
    my $indent     = defined $opt->{indent}    ? $opt->{indent}    : '    ';
    my $prefix     = defined $opt->{prefix}    ? $opt->{prefix}    : ''  ;
    my $separator  = defined $opt->{separator} ? $opt->{separator} : ': ';
    my $with_root  = $opt->{with_root}  ? 1 : 0;
    my $no_padding = $opt->{no_padding} ? 1 : 0;
    my $transpose  = $opt->{transpose}  ? 1 : 0;
    
    if (!$callback) {
        my $maxlen = $with_root ? length($self->root->count) : length($self->root->max || '');
        $fh ||= \*STDOUT;
        
        $callback = sub {
            my ($node, $children, $field, $subfield) = @_;
            
            if ($with_root || $node->depth > 0) {
                print $fh $indent x ($node->depth - ($with_root ? 0 : 1));
                print $fh $prefix;
                
                my $value = $node->value;
                my $count;
                
                if ($field and my $aggregate = $field->aggregate) {
                    $count = $node->$aggregate;
                } else {
                    $count = $node->count;
                }
                
                if ($transpose) {
                    print $fh $value;
                } elsif ($no_padding) {
                    print $fh $count;
                } else {
                    printf $fh '%'.$maxlen.'d', $count;
                }
                
                print $fh $separator;
                
                if ($transpose) {
                    print $fh $count;
                } else {
                    print $fh $value;
                }
                
                print $fh "\n";
            }
        };
    }
    
    $self->traverse(sub {
        my ($node, $children, $recurse, $field) = @_;
        $callback->($node, $children, $field);
        $recurse->($_) foreach @$children;
    });
}

=head2 traverse

Usage:

    $data->traverse(sub {
        my ($node, $children, $recurse) = @_;
        
        # Do something with $node before its child nodes
        
        # $children is a sorted list of child nodes,
        # based on the field specification
        for my $child (@$children) {
            $recurse->($child); # invoke recursion
        }
        
        # Do something with $node after its child nodes
    });

Provides a way to traverse the result tree with more control than the L<output()|/output> method.

A callback must be passed as an argument, and will ba called with the following arguments:

=over 4

=item * $node: Data::Freq::Node

The current node (L<Data::Freq::Node>)

=item * $children: [$child_node1, $child_node2, ...]

An array ref to the list of child nodes, sorted based on the field

Note: C<< $node->children >> is a hash ref (unsorted) of a raw counting data.

=item * $recurse: sub ($a_child_node)

A subroutine ref, with which the resursion is invoked at a desired time

=back

When the L<traverse()|/traverse> method is called,
the root node is passed as the C<$node> parameter first.
Until the C<$recurse> subroutine is explicitly invoked for the child nodes,
B<no> recursion will be invoked automatically.

=cut

sub traverse {
    my $self = shift;
    my $callback = shift;
    
    my $fields = $self->fields;
    my $recurse; # separate declaration for closure access
    
    $recurse = sub {
        my $node = shift;
        my $children = [];
        my $field = $fields->[$node->depth];
        my $subfield = $fields->[$node->depth + 1];
        
        if ($field) {
            $children = [values %{$node->children}];
            $children = $field->select_nodes($children, $subfield);
        }
        
        $callback->($node, $children, $recurse, $field, $subfield);
    };
    
    $recurse->($self->root);
}

=head2 root

Returns the root node of the I<frequency tree>. (See L</frequency tree> for details.)

The root node is created during the L<new()|/new> method call,
and maintains the total number of added records and a reference to its direct child nodes
for the first field.

=head2 fields

Returns the array ref to the list of fields (L<Data::Freq::Field>).

The returned array should B<not> be modified.

=cut

sub root   {shift->{root  }}
sub fields {shift->{fields}}

=head1 AUTHOR

Mahiro Ando, C<< <mahiro at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-freq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Freq>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Freq

You can also look for information at:

=over 4

=item * GitHub repository (report bugs here)

L<https://github.com/mahiro/perl-Data-Freq>

=item * RT: CPAN's request tracker (report bugs here, alternatively)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Freq>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Freq>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Freq>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Freq/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mahiro Ando.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::Freq
