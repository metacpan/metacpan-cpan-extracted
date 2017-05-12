package Data::StreamSerializer;

use 5.010001;
use strict;
use warnings;
use Carp;

use Data::Dumper;
require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Data::StreamSerializer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.07';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Data::StreamSerializer::constant not defined"
        if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Data::StreamSerializer', $VERSION);

use subs qw(_next);
sub new
{
    my ($class, @data) = @_;

    my $self = bless {
        stack       => [ 0 ],
        data        => \@data,
        eof         => 0,
        recursions  => 1,
        block_size  => 512,
    } => ref($class) || $class;

    $self->{eof} = 1 unless @data > 0;
    return $self;
}

sub block_size
{
    my ($self, $value) = @_;
    return $self->{block_size} unless @_ > 1;
    croak "block_size must not be zero" unless $value;
    return $self->{block_size} = $value;
}

sub recursion_depth
{
    my ($self, $value) = @_;
    return $self->{recursions} unless @_ > 1;
    croak "You can't uze zero as recursion_depth parameter"
        unless $value;
    return $self->{recursions} = $value;
}

sub next
{
    my ($self) = @_;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Useqq    = 1;
    local $Data::Dumper::Deepcopy = 1;
    return if $self->{eof};

    my $str;

    my $status = _next($self->{data},
            $self->block_size,
            $self->{stack},
            $self->{eof},
            \&Dumper,
            $str,
            $self->recursion_depth,
    );
    $self->{status} ||= $status;

    delete $self->{data} if $self->{eof} and exists $self->{data};
    return $str if length $str;
    return if $self->{eof};
    return $str;
}


sub is_eof
{
    my ($self) = @_;
    return $self->{eof};
}

sub recursion_detected
{
    my ($self) = @_;
    return 1 if $self->{status};
    return 0;
}

sub DESTROY
{
    my ($self) = @_;
    delete $self->{data};
}


1;
__END__


=head1 NAME

Data::StreamSerializer - non-blocking serializer.

=head1 SYNOPSIS

  use Data::StreamSerializer;

  my $sr = new Data::StreamSerializer('You data');

  while(defined(my $part = $sr->next)) {
      print $socket $part;
  }

=head1 DESCRIPTION

Sometimes You need to serialize a lot of data. If You use 'Dumper'
it can take You for much time. If Your code is executed in event
machine it can be inadmissible. So using the module You can serialize
Your data progressively and do something between serialization itearions.

This module works slower than L<Data::Dumper>, but it can serialize object
progressively and You can do something else between serialization iterations.

=head2 Recognized types.

=head3 HASH

=head3 ARRAY

=head3 REF

=head3 Regexp

=head3 SCALAR



=head1 METHODS

=head2 new

Constructor. All arguments will be serialized.

=head2 next

Returns next part of serialized string or B<undef> if all data were serialized.

=head2 block_size

Block size for one iteration. Too small value allows You to spend less time
for each iteration, but in this case total serialization time will grow.
Nod bad choice to set the value between 200 - 2000 bytes
(default value is 512). See L<BENCHMARKS> to make a decision.


=head2 recursion_depth

If serialized object has recursive references, they will be replaced by
empty objects. But if this value is higher than 1 recursion will be
reserialized until the value is reached.

Example:

    my $t = { a => 'b' };
    $t->{c} = $t;

This example will be serialized into string:

    {"c",{"c",{},"a","b"},"a","b"}

and if You increment L<recursion_depth>, this example will be serialized into
string:
    {"c",{"c",{"c",{},"a","b"},"a","b"},"a","b"}

etc.

=head2 recursion_detected

Returns B<TRUE> if a recursion was detected.

=head2 is_eof

Returns B<TRUE> if eof is reached. If it is B<TRUE> the following L<next> will
return B<undef>.

=head1 SEE ALSO

L<Data::StreamDeserializer>.


=head1 BENCHMARKS

You can try a few scripts in B<benchmark/> directory. There are a few
test arrays in this directory.

Here are a few test results of my system.

=head2 Array which contains 100 hashes:

    $ perl benchmark/vs_dumper.pl -n 1000 -b 512 benchmark/tests/01_100x10
    38296 bytes were read
    First serializing by eval... done
    First serializing by Data::StreamSerializer... done
    Starting 1000 iterations for Dumper... done (40.376 seconds)
    Starting 1000 iterations for Data::StreamSerializer... done (137.960 seconds)

    Dumper statistic:
            1000 iterations were done
            maximum serialization time: 0.0867 seconds
            minimum serialization time: 0.0396 seconds
            average serialization time: 0.0404 seconds

    Data::StreamSerializer statistic:
            1000 iterations were done
            58000 SUBiterations were done
            maximum serialization time: 0.1585 seconds
            minimum serialization time: 0.1356 seconds
            average serialization time: 0.1380 seconds
            average subiteration  time: 0.00238 seconds

=head2 Array which contains 1000 hashes:

    $  perl benchmark/vs_dumper.pl -n 1000 -b 512 benchmark/tests/02_1000x10
    355623 bytes were read
    First serializing by eval... done
    First serializing by Data::StreamSerializer... done
    Starting 1000 iterations for Dumper... done (405.334 seconds)
    Starting 1000 iterations for Data::StreamSerializer... done (1407.899 seconds)

    Dumper statistic:
            1000 iterations were done
            maximum serialization time: 0.4564 seconds
            minimum serialization time: 0.4018 seconds
            average serialization time: 0.4053 seconds

    Data::StreamSerializer statistic:
            1000 iterations were done
            520000 SUBiterations were done
            maximum serialization time: 2.0050 seconds
            minimum serialization time: 1.3862 seconds
            average serialization time: 1.4079 seconds
            average subiteration  time: 0.00271 seconds


You can see that in any cases one iteration gets the same time.

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=head1 VCS

The project is placed in my git repo. See here:
L<http://git.uvw.ru/?p=data-stream-serializer;a=summary>

=cut
