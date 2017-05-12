package App::PNGCrush;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use Proc::Reliable;
use Devel::TakeHashArgs;
use base 'Class::Data::Accessor';

my %Valid_Options = qw(
    already_size            -already
    bit_depth               -bit_depth
    background              -bkgd
    brute_force             -brute
    color_type              -c
    color_counting          -cc
    output_dir              -d
    double_image_gamma      -dou
    output_extension        -e
    filter                  -f
    fix_fatal               -fix
    output_force            -force
    gamma                   -g
    itxt                    -itxt
    level                   -l 
    method                  -m
    maximum_idat            -max
    no_output               -n
    no_color_counting       -no_cc
    plte_length             -plte_len
    remove                  -rem
    replace_gamma           -replace_gamma
    resolution              -res
    save_unknown            -save
    srgb                    -srgb
    text                    -text
    transparency            -trns
    window_size             -w
    strategy                -z
    insert_ztxt             -zitxt
    ztxt                    -ztxt
    verbose                 -v
);

my %No_Arg_Options = map { $_ => 1 } qw(
    brute_force
    color_counting
    double_image_gamma
    fix_fatal
    output_force
    no_output
    no_color_counting
    save_unknown
    verbose
);

__PACKAGE__->mk_classaccessors (
    qw( proc error results ),
    keys %Valid_Options
);

sub new {
    my $self = bless {}, shift;
    get_args_as_hash( \@_, \my %args, { maxtime => 300 } )
        or croak $@;

    my $proc = Proc::Reliable->new;

    $proc->$_( $args{$_} ) for keys %args;

    $self->proc( $proc );

    return $self;
}

sub run {
    my $self = shift;
    my $in   = shift;

    get_args_as_hash( \@_, \ my %args, { in => $in }, )
        or croak $@;

    $self->$_(undef) for qw(error results);

    my @options = exists $args{opts}
                ? @{ $args{opts} }
                : $self->_make_options;

    my $proc = $self->proc;
    my %out;
    @out{ qw(stdout stderr status msg) }
    = $proc->run( [ 'pngcrush', @options, $in ] );

    return $self->_set_error("Proc::Reliable error: $out{error}")
        if defined $out{error};

    return $self->_set_error("File $in does not seem to exist")
        if $out{stdout} =~ /Could not find file: \Q$in/;

    @out{ qw(idat size) } = $out{stdout}
    =~ /\(([\d.]+)% IDAT reduction\).+?\(([\d.]+)% filesize reduction\)/s;

    $out{idat} = 0
        if not defined $out{idat}
            and $out{stdout} =~ /\Q(no IDAT change)/;

    $out{size} = 0
        if not defined $out{size}
            and $out{stdout} =~ /\Q(no filesize change)/;

    @{ $out{cpu} }{ qw(total decoding encoding other) } = $out{stdout}
    =~ /CPU \s time \s used \s = \s ([\d.]+) \s seconds \s
            \(decoding \s ([\d.]+), \s+
          encoding \s ([\d.]+), \s other \s ([\d.]+) \s seconds\)
    /x;

    ( $out{total_idat_length} ) = $out{stdout}
    =~ /Total length of data found in IDAT chunks\s+=\s+([\d.]+)/;

    return $self->results( \%out );
}

sub set_options {
    my $self = shift;
    get_args_as_hash( \@_, \my %args, {}, [], [ %Valid_Options ] )
        or croak $@;

    $self->reset_options;

    keys %args;
    my %shell_args = reverse %Valid_Options;
    while ( my ( $key, $value ) = each %args ) {
        $key = $shell_args{$key}
            unless exists $Valid_Options{$key};

        $self->$key( $value );
    }

    return 1;
}

sub reset_options {
    my $self = shift;

    $self->$_(undef) for keys %Valid_Options;

    return 1;
}

sub _make_options {
    my $self = shift;

    my @options;
    for my $opt ( keys %Valid_Options ) {
        my $value = $self->$opt;
        next
            unless defined $value;

        if ( ref $value eq 'ARRAY' ) {
            if ( $opt eq 'verbose' ) {
                push @options, ('-v') x @$value;
                next;
            }
            push @options, map { $Valid_Options{$opt} => $_ } @$value;
        }
        else {
            push @options, $Valid_Options{$opt},
                exists $No_Arg_Options{$opt} ? () : $value;
        }
    }
    return @options;
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error($error);
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

App::PNGCrush - Perl wrapper around ``pngcrush'' program

=head1 SYNOPSIS

    use strict;
    use warnings;

    use App::PNGCrush;

    my $crush = App::PNGCrush->new;

    # let's use best compression and remove a few chunks
    $crush->set_options(
        qw( -d OUT_DIR -brute 1 ),
        remove  => [ qw( gAMA cHRM sRGB iCCP ) ],
    );

    my $out_ref = $crush->run('picture.png')
        or die "Error: " . $crush->error;

    print "Size reduction: $out_ref->{size}%\n"
                . "IDAT reduction: $out->{idat}%\n";

=head1 DESCRIPTION

The module is a simple wrapper around ``pngcrush'' program. The program
is free open source and you can obtain it from
L<http://pmt.sourceforge.net/pngcrush/> on Debian systems you
can find it in the repos: C<sudo -H apt-get install pngcrush>

I needed this module to utilize only little subsection of C<pngcrush>'s
functionality, if you would like some features added, I am more than open
for suggestions.

=head1 CONSTRUCTOR

=head2 C<new>

    my $crush = App::PNGCrush->new;

    my $crush = App::PNGCrush->new( max_time => 300 );

Creates a new App::PNGCrush object. Arguments are optional and passed
as key/value pairs with keys being L<Proc::Reliable> methods and values
being the values for those methods, here you can set some options
controlling how C<pngcrush> will be run. Generally, you'd worry only
about C<max_time> (which B<defaults> to C<300> seconds in C<App::PNGCrush>)
and set it to a higher value if you are about to process large images
with brute force.

=head1 METHODS

=head2 C<run>

    my $results_ref = $crush->run('pic.png')
        or die $crush->error;

    my $results_ref = $crush->run('pic.png', opts => [ qw(custom stuff) ] );

Instructs the object to run C<pngcrush>. The first argument is mandatory
and must be a filename which will be passed to C<pngcrush> as input file.
Takes one optional argument (so far), which is passed as key/value
pair; the key being C<opts> and value being an arrayref of custom options
you want to give to C<pngcrush> (those will bypass shell processing).
Generally the custom options option is in here "just in case" and B<you
are recommended to set options via individual methods or C<set_options()>
method (see below).>

Returns either C<undef> or an empty list (depending on the context)
if an error occurred and the reason for the error will be available via
C<error()> method. On success returns a hashref with the following
keys/values:

    $VAR1 = {
        'total_idat_length' => '1880',
        'cpu' => {
                    'decoding' => '0.010',
                    'other' => '0.050',
                    'total' => '0.210',
                    'encoding' => '0.150'
        },
        'stderr' => '',
        'status' => '0',
        'idat' => '0.80',
        'stdout' => '| pngcrush 1.6.4 .. blah blah full STDOUT here',
        'size' => '1.56'
    };

=head3 C<size>

    { 'size' => '1.56', }

The C<size> key will contain percentage of filesize reduction.

=head3 C<idat>

    { 'idat' => '0.80', }

The C<idat> key will contain the percentage of IDAT size reduction.

=head3 C<total_idat_length>

    { 'total_idat_length' => '1880', }

The C<total_idat_length> key will contain total length of data found in
IDAT chunks.

=head3 C<cpu>

    'cpu' => {
        'decoding' => '0.010',
        'other' => '0.050',
        'total' => '0.210',
        'encoding' => '0.150'
    },

The C<cpu> key will contain a hashref with with four keys:
C<total>, C<decoding>, C<other> and C<encoding> with values being
number of seconds it took to process.

=head3 C<stderr>

    { 'stderr' => '', }

The C<stderr> key will contain any collected data from STDERR while
C<pngcrush> was running.

=head3 C<stdout>

    { 'stdout' => '| pngcrush 1.6.4 .. blah blah full STDOUT here', }

The C<stdout> key will contain any collected data from STDOUT while
C<pngcrush> was running.

=head3 C<status>

    { 'status' => '0' }

The C<status> key will contain the exit code of C<pngcrush>.

=head2 C<error>

    my $ret_ref = $crush->run('some.png')
        or die $crush->error;

If C<run> failed it will return either C<undef> or an empty list depending
on the context and the reason for failure will be available via C<error()>
method. Takes no arguments, returns a human parsable error message
explaining why C<run> failed.

=head2 C<results>

    my $results_ref = $crush->results;

Must be called after a successful call to C<run()>. Takes no arguments,
returns the exact same hashref last call to C<run()> returned.

=head2 C<set_options>

    $crush->set_options(
        qw( -d OUT_DIR -brute 1 ),
        remove  => [ qw( gAMA cHRM sRGB iCCP ) ],
    );

Always returns a true value. Sets the options with which to run
C<pngcrush>. As argument takes a list of key/value pairs of
either standard C<pngcrush> options or more verbose names this module
offers (see below). If you want to B<repeat> certain option pass values
as B<an arrayref>, thus if on a command line you'd write
C<< pngcrush -rem gAMA -rem cHRM -rem sRGB ... >> you'd use
C<< ->set_options( '-rem' => [ qw( gAMA cHRM sRGB iCPP ) ] ) >>.

B<Note:> if C<pngcrush> option does not take an argument you B<must>
give it a value of C<1> when setting it via C<set_options()> method.
For C<-v> option you can set it to value C<2> to repeat twice
(aka uber verbose). B<Same applies> to individual option setting methods.

B<Note 2:> call to C<set_options()> will call C<reset_options()> method
(see below) before setting any of your options, thus whatever you
don't specify will not be passed to C<pngcrush>

=head2 C<reset_options>

    $crush->reset_options;

Always returns a true value, takes no arguments. Instructs the object
to reset all C<pngcrush> options.

=head2 individual option methods

Module provides methods to set (almost) all C<pngcrush> options individually
You'd probably would want to use C<set_options()> method (see above)
in most cases. See C<set_options()> method which describes how to
repeat options and how to set options which take no arguments in
C<pngcrush>. The following is the list of methods (on the left) and
corresponding C<pngcrush> options they set (on the right); some
options were deemed useless to the module and were not included
(this is as of C<pngcrush> version 1.6.4):

    already_size            -already
    bit_depth               -bit_depth
    background              -bkgd
    brute_force             -brute
    color_type              -c
    color_counting          -cc
    output_dir              -d
    double_image_gamma      -dou
    output_extension        -e
    filter                  -f
    fix_fatal               -fix
    output_force            -force
    gamma                   -g
    itxt                    -itxt
    level                   -l 
    method                  -m
    maximum_idat            -max
    no_output               -n
    no_color_counting       -no_cc
    plte_length             -plte_len
    remove                  -rem
    replace_gamma           -replace_gamma
    resolution              -res
    save_unknown            -save
    srgb                    -srgb
    text                    -text
    transparency            -trns
    window_size             -w
    strategy                -z
    insert_ztxt             -zitxt
    ztxt                    -ztxt
    verbose                 -v

See C<pngcrush> manpage (C<man pngcrush> or C<pngcrush -v>)
for descriptions of these options.

Out of those listed above the following C<pngcrush> options do not take
arguments,
thus to set these you'd need to pass C<1> as an argument to the option
setting method (except for C<verbose> which can take a value of C<2> to
indicate double verboseness (equivalent to passing C<-v -v> to
C<pngcrush>)

    brute_force
    color_counting
    double_image_gamma
    fix_fatal
    output_force
    no_output
    no_color_counting
    save_unknown
    verbose

=head2 C<proc>

    my $proc_reliable_obj = $crush->proc;

    $crush->proc( Proc::Reliable->new );

Returns a currently used L<Proc::Reliable> object used under the hood,
thus you could dynamically set arguments as
C<< $crush->proc->max_time(300) >>. When called with an argument
it must be a C<Proc::Reliable> object which will replace the currently
used one (and you just SOO don't wanna do this, do you?)

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-pngcrush at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-PNGCrush>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::PNGCrush

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-PNGCrush>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-PNGCrush>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-PNGCrush>

=item * Search CPAN

L<http://search.cpan.org/dist/App-PNGCrush>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

