package CWB::CQP::More;
$CWB::CQP::More::VERSION = '0.08';
use parent CWB::CQP;
use CWB;

use Carp;
use Try::Tiny;
use Encode;
use warnings;
use strict;
use POSIX::Open3;
use CWB::CQP::More::Iterator;

our $DEBUG = 0;

sub import {
    my @ops = @_;
    $DEBUG = grep { $_ eq "DEBUG" } @ops;
}

=head1 NAME

CWB::CQP::More - A higher level interface for CWB::CQP

=head1 SYNOPSIS

    use CWB::CQP::More;

    my $cqp = CWB::CQP::More->new( { utf8 => 1 } );

    $cqp->change_corpus('HANSARDS');

    # This needs to get fixed... not nice to say "'<b>'"
    $cqp->set(Context  => [20, 'words'],
              LD       => "'<b>'",
              RD       => "'</b>'");

    # using Try::Tiny...
    try {
        $cqp->exec('A = "dog";');
        my $result_size = $cqp->size('A');
        my @lines = $cqp->cat('A');
    } catch {
        print "Error: $_\n";
    }

    $cqp->annotation_show("pos");

    $details = $cqp->corpora_details('hansards');

    $available_corpora = $cqp->show_corpora;

    # for debug
    use CWB::CQP::More 'DEBUG';

=head1 METHODS

This class superclasses CWB::CQP and adds some higher-order
functionalities.

=head2 new

The C<new> constructor has the same behavior has the C<CWB::CQP>
C<new> method, unless the first argument is a hash reference. In that
case, it is shifted and used as configuration for
C<CWB::CQP::More>. The remaining arguments are sent unaltered to
C<CWB::CQP> constructor.

=cut

sub _super_hacked_new {
    my @options = @_;
    my $self = {};

    # split options with values, e.g. "-r /my/registry" => "-r", "/my/registry"
    # (doesn't work for multiple options in one string)
    @options = map { (/^(--?[A-Za-z0-9]+)\s+(.+)$/) ? ($1, $2) : $_ } @options;

    ## run CQP server in the background
    my $in  = $self->{'in'}  = new FileHandle; # stdin  of CQP
    my $out = $self->{'out'} = new FileHandle; # stdout of CQP
    my $err = $self->{'err'} = new FileHandle; # stderr of CQP

    my $pid = open3($in, $out, $err, $CWB::CQP, @CWB::CQP::CQP_options, @options);

    $self->{'pid'} = $pid; # child process ID (so process can be killed if necessary)
    $in->autoflush(1); # make sure that commands sent to CQP are always flushed immediately

    my ($need_major, $need_minor, $need_beta) = split /\./, $CWB::CQP::CQP_version;
    $need_beta = 0 unless $need_beta;

    my $version_string = $out->getline; # child mode (-c) should print version on startup
    chomp $version_string;
    croak "ERROR: CQP backend startup failed ('$CWB::CQP @CWB::CQP::CQP_options @options')\n"
      unless $version_string =~
        m/^CQP\s+(?:\w+\s+)*([0-9]+)\.([0-9]+)(?:\.b?([0-9]+))?(?:\s+(.*))?$/;
    $self->{'major_version'} = $1;
    $self->{'minor_version'} = $2;
    $self->{'beta_version'} = $3 || 0;
    $self->{'compile_date'} = $4 || "unknown";
    croak "ERROR: CQP version too old, need at least v$CWB::CQP::CQP_version ($version_string)\n"
      unless ($1 > $need_major or
              $1 == $need_major
              and ($2 > $need_minor or
                   ($2 == $need_minor and $3 >= $need_beta)));

    ## command execution
    $self->{'command'} = undef; # CQP command string that is currently being processed (undef = last command has been completed)
    $self->{'lines'} = [];      # array of output lines read from CQP process
    $self->{'buffer'} = "";     # read buffer for standard output from CQP process
    $self->{'block_size'} = 256;  # block size for reading from CQP's output and error streams
    $self->{'query_lock'} = undef;# holds random key while query lock mode is active
    ## error handling (messages on stderr)
    $self->{'error_handler'} = undef; # set to subref for user-defined error handler
    $self->{'status'} = 'ok';         # status of last executed command ('ok' or 'error')
    $self->{'error_message'} = [];    # arrayref to array containing message produced by last command (if any)
    ## handling of CQP progress messages
    $self->{'progress'} = 0;             # whether progress messages are activated
    $self->{'progress_handler'} = undef; # optional callback for progress messages
    $self->{'progress_info'} = [];       # contains last available progress information: [$total_percent, $pass, $n_passes, $message, $percent]
    ## debugging (prints more or less everything on stdout)
    $self->{'debug'} = 0;
    ## select vectors for CQP output (stdout, stderr, stdout|stderr)
    $self->{'select_err'} = new IO::Select($err);
    $self->{'select_out'} = new IO::Select($out);
    $self->{'select_any'} = new IO::Select($err, $out);
    ## CQP object setup complete
    return $self;
}

sub new {
    my ($class, @args) = @_;
    my $conf = shift @args if ref($args[0]);

    my $self = _super_hacked_new(@args);
    if (exists($conf->{parallel}) && $conf->{parallel}) {
        bless $self, __PACKAGE__."::Parallel";
    } else {
        bless $self, __PACKAGE__;
    }

    $self->exec("set PrettyPrint off");

    for my $k (keys %$conf) {
        $self->{"__$k"} = $conf->{$k};
    }

    $self->set_error_handler( sub { } );

    return $self;
}

=head2 utf8

Set utf8 mode on or off. Pass it a 1 or a 0 as argument. Returns that
same value. If used without arguments, returns current value.

=cut

sub utf8 {
    my ($self, $v) = @_;
    $self->{__utf8} = $v if $v;
    return $self->{__utf8} || 0;
}

=head2 size

Uses the C<size> CQP command to fetch the size of a query result
set. Pass it its name, returns an integer. C<-1> if the result set
does not exist or an error occurred.

=cut

sub size {
    my ($self, $name) = @_;
    my $n;
    try {
        ($n) = $self->exec("size $name");
    } catch {
        return -1;
    };
    return $n;
}

=head2 cat

This method uses the C<cat> method to return a result set. The first
mandatory argument is the name of the result set. Second and Third
arguments are optional, and correspond to the interval of matches to
return.

Returns empty list on any error.

=cut

sub cat {
    my ($self, $id, $from, $to) = @_;
    my $extra = "";
    $extra = "$from $to" if defined($from) && defined($to);
    my @ans;
    try {
        @ans = $self->exec("cat $id $extra;");
    } catch {
        @ans = ();
    };
    return @ans;
}

=head2 annotation_show

Use this method to specify what annotations to make CQP to show. Pass
it a list of the annotation names.

=cut

sub annotation_show($@) {
    my ($self, @annotations) = @_;
    my $annots = join(" ", map { "+$_" } @annotations);
    $self->exec("show $annots;");
}

=head2 annotation_hide

Use this method to specify what annotations to make CQP to not show
(hide). Pass it a list of the annotation names.

=cut

sub annotation_hide($@) {
    my ($self, @annotations) = @_;
    my $annots = join(" ", map { "-$_" } @annotations);
    $self->exec("show $annots;");
}

=head2 change_corpus

Change current active corpus. Pass the corpus name as the argument.

=cut

sub change_corpus($$) {
    my ($self, $cname) = @_;
    $cname = uc $cname;
    $self->exec("$cname;");
}

=head2 set

Set CQP properties. Pass a hash (not a reference) of key/values to be
set. Note that at the moment string values should be double quoted
(see example in the synopsis).

=cut

sub set($%) {
    my ($self, %vars) = @_;
    for my $key (keys %vars) {
        my $values;
        if (ref($vars{$key}) eq "ARRAY") {
            $values = join(" ", @{$vars{$key}});
        } else {
            $values = $vars{$key};
        }

        try {
            $self->exec("set $key $values;");
        };
    }
}

=head2 exec

Similar to CWB::CQP->exec, but dying in case of error with the error
message. Useful for use with C<Try::Tiny>. Check the synopsis above
for an example.

=cut

sub exec {
    my ($self, @args) = @_;
    @args = map { Encode::_utf8_off($_); $_ } @args if $self->{__utf8};
    print STDERR join(' || ', @args), "\n" if $DEBUG;
    my @answer = $self->SUPER::exec(@args);
    die $self->error_message unless $self->ok;
    @answer = map { Encode::_utf8_on($_); $_ } @answer if $self->{__utf8};
    return @answer;
}

=head2 corpora_details

Returns a reference to a hash with details about a specific corpus,
like name, id, home directory, properties and attributes;

=cut

sub corpora_details {
    my ($self, $cname) = @_;
    return undef unless $cname;

    $cname = lc $cname unless $cname =~ m{[/\\]};

    my $details = {};
    my $reg = new CWB::RegistryFile $cname;
    return undef unless $reg;

    $details->{filename}  = $reg->filename;
    $details->{name}      = $reg->name;
    $details->{corpus_id} = $reg->id;
    $details->{home_dir}  = $reg->home;
    $details->{info_file} = $reg->info;

    my @properties = $reg->list_properties;
    for my $property (@properties) {
        $details->{property}{$property} = $reg->property($property);
    }

    my @attributes = $reg->list_attributes;
    for my $attr (@attributes) {
        $details->{attribute}{$reg->attribute($attr)}{$attr} = $reg->attribute_path($attr);
    }

    return $details;
}

=head2 show_corpora

Returns a reference to a list of the available corpora;

=cut

sub show_corpora {
    my $self = shift;
    my $ans;
    try {
        $ans = [ $self->exec("show corpora;") ];
    } catch {
        $ans = [];
    };
    return $ans;
}

=head2 iterator

Returns a new iterator, to iterate over a result set. See
L<CWB::CQP::More::Iterator> for documentation on how to use it.

=cut

sub iterator {
    return CWB::CQP::More::Iterator->new(@_);
}

=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cwb-cqp-more at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CWB-CQP-More>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CWB::CQP::More


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CWB-CQP-More>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CWB-CQP-More>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CWB-CQP-More>

=item * Search CPAN

L<http://search.cpan.org/dist/CWB-CQP-More/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks for Stefan Evert for all help.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Alberto Simoes.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CWB::CQP::More
