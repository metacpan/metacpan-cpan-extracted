package DataFlow;

use strict;
use warnings;

# ABSTRACT: A framework for dataflow processing

our $VERSION = '1.121830';    # VERSION

use Moose;
use Moose::Exporter;
with 'DataFlow::Role::Processor';
with 'DataFlow::Role::Dumper';

use DataFlow::Types qw(WrappedProcList);

use Moose::Autobox;

use namespace::autoclean;
use Queue::Base 2.1;

with 'MooseX::OneArgNew' => { 'type' => 'Str',      'init_arg' => 'procs', };
with 'MooseX::OneArgNew' => { 'type' => 'ArrayRef', 'init_arg' => 'procs', };
with 'MooseX::OneArgNew' => { 'type' => 'CodeRef',  'init_arg' => 'procs', };
with 'MooseX::OneArgNew' => { 'type' => 'DataFlow', 'init_arg' => 'procs', };
with 'MooseX::OneArgNew' =>
  { 'type' => 'DataFlow::Proc', 'init_arg' => 'procs', };

Moose::Exporter->setup_import_methods( as_is => ['dataflow'] );

# attributes
has 'default_channel' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'lazy'    => 1,
    'default' => 'default',
);

has 'auto_process' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'lazy'    => 1,
    'default' => 1,
);

has '_procs' => (
    'is'       => 'ro',
    'isa'      => 'WrappedProcList',
    'required' => 1,
    'coerce'   => 1,
    'builder'  => '_build_procs',
    'init_arg' => 'procs',
);

has '_queues' => (
    'is'      => 'ro',
    'isa'     => 'ArrayRef[Queue::Base]',
    'lazy'    => 1,
    'default' => sub { return shift->_make_queues(); },
    'handles' => {
        '_firstq' => sub { return shift->_queues->[0] },
        'has_queued_data' =>
          sub { return _count_queued_items( shift->_queues ) },
        '_make_queues' => sub {
            shift->_procs->map( sub { Queue::Base->new() } );
        },
    },
);

has '_lastq' => (
    'is'      => 'ro',
    'isa'     => 'Queue::Base',
    'lazy'    => 1,
    'default' => sub { return Queue::Base->new },
);

##############################################################################

sub _build_procs {
    return;
}

sub procs {
    return @{ [ shift->_procs ]->map( sub { $_->on_proc } ) };
}

# functions
sub _count_queued_items {
    my $q     = shift;
    my $count = 0;

    $q->map( sub { $count = $count + $_->size } );

    return $count;
}

sub _process_queues {
    my ( $proc, $inputq, $outputq ) = @_;

    my $item = $inputq->remove;
    my @res  = $proc->process($item);
    $outputq->add(@res);
    return;
}

sub _reduce {
    my ( $p, @q ) = @_;
    [ 0 .. $#q - 1 ]
    ->map( sub { _process_queues( $p->[$_], $q[$_], $q[ $_ + 1 ] ) } );
    return;
}

# methods
sub clone {
    my $self = shift;
    return DataFlow->new( procs => $self->_procs );
}

sub channel_input {
    my ( $self, $channel, @args ) = @_;
    $self->prefix_dumper( $self->has_name ? $self->name . ' <<' : '<<', @args )
      if $self->dump_input;

    $self->_firstq->add(
        @{ @args->map( sub { DataFlow::Item->itemize( $channel, $_ ) } ) } );
    return;
}

sub input {
    my ( $self, @args ) = @_;
    $self->channel_input( $self->default_channel, @args );
    return;
}

sub process_input {
    my $self = shift;
    my @q = ( @{ $self->_queues }, $self->_lastq );
    _reduce( $self->_procs, @q );
    return;
}

sub _unitem {
    my ( $item, $channel ) = @_;
    return unless defined $item;
    return $item->get_data($channel);
}

sub _output_items {
    my $self = shift;
    $self->process_input if ( $self->_lastq->empty && $self->auto_process );
    return wantarray ? $self->_lastq->remove_all : $self->_lastq->remove;
}

sub output_items {
    my $self = shift;
    my @res = wantarray ? $self->_output_items : scalar( $self->_output_items );
    $self->prefix_dumper( $self->has_name ? $self->name . ' >>' : '>>', @res )
      if $self->dump_output;
    return wantarray ? @res : $res[0];
}

sub output {
    my $self = shift;
    my $channel = shift || $self->default_channel;

    my @res = wantarray ? $self->_output_items : scalar( $self->_output_items );
    $self->prefix_dumper( $self->has_name ? $self->name . ' >>' : '>>', @res )
      if $self->dump_output;
    return wantarray
      ? @{ @res->map( sub { _unitem( $_, $channel ) } ) }
      : _unitem( $res[0], $channel );
}

sub reset {    ## no critic
    return shift->_queues->map( sub { $_->clear } );
}

sub flush {
    my $self = shift;
    while ( $self->has_queued_data ) {
        $self->process_input;
    }
    return $self->output;
}

sub process {
    my ( $self, @args ) = @_;

    my $flow = $self->clone();
    $flow->input(@args);
    return $flow->flush;
}

sub proc_by_index {
    my ( $self, $index ) = @_;
    return unless $self->_procs->[$index];
    return $self->_procs->[$index]->on_proc;
}

sub proc_by_name {
    my ( $self, $name ) = @_;
    return $self->_procs->map( sub { $_->on_proc } )
      ->grep( sub { $_->name eq $name } )->[0];
}

sub dataflow (@) {    ## no critic
    my @args = @_;
    return __PACKAGE__->new( procs => [@args] );
}

__PACKAGE__->meta->make_immutable;

1;



__END__
=pod

=encoding utf-8

=head1 NAME

DataFlow - A framework for dataflow processing

=head1 VERSION

version 1.121830

=head1 SYNOPSIS

	use DataFlow;

	my $flow = DataFlow->new(
		procs => [
		    DataFlow::Proc->new( p => sub { do this thing } ), # a Proc
			sub { ... do something },   # a code ref
			'UC',                       # named Proc
			[                           # named Proc, with parameters
			  CSV => {
				direction     => 'CONVERT_TO',
				text_csv_opts => { binary => 1 },
			  }
			],
			# named Proc, named "Proc"
			[ Proc => { p => sub { do this other thing }, deref => 1 } ],
			DataFlow->new( ... ),       # another flow
		]
	);

	$flow->input( <some input> );
	my $output = $flow->output();

	my $output = $flow->output( <some other input> );

	# other ways to invoke the constructor
	my $flow = DataFlow->new( sub { .. do something } );   # pass a sub
	my $flow = DataFlow->new( [                            # pass an array
		sub { ... do this },
		'UC',
		[
		  HTMLFilter => (
		    search_xpath => '//td',
			result_type  => 'VALUE'
		  )
		]
	] );
	my $flow = DataFlow->new( $another_flow ); # pass another DataFlow or Proc

	# other way to pass the data through
	my $output = $flow->process( qw/long list of data/ );

=head1 DESCRIPTION

A C<DataFlow> object is able to accept data, feed it into an array of
processors (L<DataFlow::Proc> objects), and return the result(s) back to the
caller.

=head1 ATTRIBUTES

=head2 name

(Str) A descriptive name for the dataflow. (OPTIONAL)

=head2 default_channel

(Str) The name of the default communication channel. (DEFAULT: 'default')

=head2 auto_process

(Bool) If there is data available in the output queue, and one calls the
C<output()> method, this attribute will flag whether the dataflow should
attempt to automatically process queued data. (DEFAULT: true)

=head2 procs

(ArrayRef[DataFlow::Role::Processor]) The list of processors that make this
DataFlow. Optionally, you may pass CodeRefs that will be automatically
converted to L<DataFlow::Proc> objects. (REQUIRED)

The C<procs> parameter will accept some variations in its value. Any
C<ArrayRef> passed will be parsed, and additionaly to plain
C<DataFlow::Proc> objects, it will accept: C<DataFlow> objects (so one can
nest flows), code references (C<sub{}> blocks), array references and plain
text strings. Refer to L<DataFlow::Types> for more information on these
different forms of passing the C<procs> parameter.

Additionally, one may pass any of these forms as a single argument to the
constructor C<new>, plus a single C<DataFlow>, or C<DataFlow:Proc> or string.

=head1 METHODS

=head2 has_queued_data

Returns true if the dataflow contains any queued data within.

=head2 clone

Returns another instance of a C<DataFlow> using the same array of processors.

=head2 input

Accepts input data for the data flow. It will gladly accept anything passed as
parameters. However, it must be noticed that it will not be able to make a
distinction between arrays and hashes. Both forms below will render the exact
same results:

	$flow->input( qw/all the simple things/ );
	$flow->input( all => 'the', simple => 'things' );

If you do want to handle arrays and hashes differently, we strongly suggest
that you use references:

	$flow->input( [ qw/all the simple things/ ] );
	$flow->input( { all => the, simple => 'things' } );

Processors using the L<DataFlow::Policy::ProcessInto> policy (default) will
process the items inside an array reference, and the values (not the keys)
inside a hash reference.

=head2 channel_input

Accepts input data into a specific channel for the data flow:

	$flow->channel_input( 'mydatachannel', qw/all the simple things/ );

=head2 process_input

Processes items in the array of queues and place at least one item in the
output (last) queue. One will typically call this to flush out some unwanted
data and/or if C<auto_process> has been disabled.

=head2 output_items

Fetches items, more specifically objects of the type L<DataFlow::Item>, from
the data flow. If called in scalar context it will return one processed item
from the flow. If called in list context it will return all the items from
the last queue.

=head2 output

Fetches data from the data flow. It accepts a parameter that points from which
data channel the data must be fetched. If no channel is specified, it will
default to the 'default' channel.
If called in scalar context it will return one processed item from the flow.
If called in list context it will return all the elements in the last queue.

=head2 reset

Clears all data in the dataflow and makes it ready for a new run.

=head2 flush

Flushes all the data through the dataflow, and returns the complete result set.

=head2 process

Immediately processes a bunch of data, without touching the object queues. It
will process all the provided data and return the complete result set for it.

=head2 proc_by_index

Expects an index (Num) as parameter. Returns the index-th processor in this
data flow, or C<undef> otherwise.

=head2 proc_by_name

Expects a name (Str) as parameter. Returns the first processor in this
data flow, for which the C<name> attribute has the same value of the C<name>
parameter, or C<undef> otherwise.

=head1 FUNCTIONS

=head2 dataflow

Syntax sugar function that can be used to instantiate a new flow. It can be
used like this:

	my $flow = dataflow
		[ 'Proc' => p => sub { ... } ],
		...
		[ 'CSV' => direction => 'CONVERT_TO' ];

	$flow->process('bananas');

=head1 HISTORY

This is a framework for data flow processing. It started as a spin-off project
from the L<OpenData-BR|http://www.opendatabr.org/> initiative.

As of now (Mar, 2011) it is still a 'work in progress', and there is a lot of
progress to make. It is highly recommended that you read the tests, and the
documentation of L<DataFlow::Proc>, to start with.

An article has been recently written in Brazilian Portuguese about this
framework, per the São Paulo Perl Mongers "Equinócio" (Equinox) virtual event.
Although an English version of the article in in the plans, you can figure
a good deal out of the original one at

L<http://sao-paulo.pm.org/equinocio/2011/mar/5>

B<UPDATE:> L<DataFlow> is a fast-evolving project, and this article, as
it was published there, refers to versions 0.91.x of the framework. There has
been a big refactor since then and, although the concept remains the same,
since version 0.950000 the programming interface has been changed violently.

Any doubts, feel free to get in touch.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc DataFlow

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/DataFlow>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/DataFlow>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/DataFlow>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/DataFlow>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/DataFlow>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/DataFlow>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=DataFlow>

=back

=head2 Email

You can email the author of this module at C<RUSSOZ at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #sao-paulo.pm then talk to this person for help: russoz.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dataflow at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DataFlow>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/russoz/DataFlow>

  git clone https://github.com/russoz/DataFlow.git

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

