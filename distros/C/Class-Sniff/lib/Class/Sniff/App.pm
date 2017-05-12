package Class::Sniff::App;

use 5.006;
use strict;
use warnings;

use Class::Sniff;
use Getopt::Long 2.24 qw/ :config no_ignore_case /;
use File::Find::Rule;
use File::Spec;

=head1 NAME

Class::Sniff::App - C<cnsiff> support class.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

 use Class::Sniff::App;
 my $app = Class::Sniff::App->new(@ARGV);
 $app->run;

=head1 DESCRIPTION

This class implements the functionality for the C<csniff> executable which
ships with C<Class::Sniff>.  See C<perldoc csniff> for more information.

=cut

sub new {
    my ( $class, @args ) = @_;
    local @ARGV = @args;
    my $self = bless {
        dirs      => undef,
        ignore    => undef,
        namespace => qr/./,
        output    => undef,
        verbose   => undef,
    } => $class;
    GetOptions(
        "ignore=s"    => \$self->{ignore},
        "namespace=s" => \$self->{namespace},
        "verbose"     => \$self->{verbose},
        "png"         => sub { $self->{output} = 'png' },
        "gif"         => sub { $self->{output} = 'gif' },
        "output=s"    => \$self->{output},
        "I=s@"        => \$self->{lib},
    );
    $self->{output} ||= 'txt';

    unless ( @ARGV ) {
        die "You must supply at least one directory to load for Class::Sniff::App";
    }

    $self->{dirs} = \@ARGV;
    $self->_initialize;
    return $self;
}

sub _dirs      { @{$_[0]->{dirs}} }
sub _ignore    { $_[0]->{ignore} }
sub _graph     { $_[0]->{graph} }
sub _namespace { $_[0]->{namespace} }
sub _output    { $_[0]->{output} }
sub _verbose   { $_[0]->{verbose} }

sub _initialize {
    my $self = shift;

    $self->{namespace} = qr/$self->{namespace}/
      unless 'Regexp' eq ref $self->{namespace};
    $self->{ignore} = qr/$self->{ignore}/ if $self->{ignore};
}

sub run {
    my $self = shift;
    $self->_load_classes;
    my $graph = Class::Sniff->graph_from_namespace(
        {
            namespace => $self->_namespace,
            ignore    => $self->_ignore,
            universal => 1,
            clean     => 1,
        }
    );
    $self->{graph} = $graph;
    my $output = $self->_output;

    print $output eq 'txt'
      ? ( $self->_as_txt )
      : ( $self->_as_dot($output) );
}

sub _as_txt { shift->_graph->as_ascii }

sub _as_dot {
    my ($self, $format) = @_;
    my $graphviz = $self->_graph->as_graphviz();
    open my $DOT, "|dot -T$format" or die("Cannot open pipe to dot: $!");
    print $DOT $graphviz;
}

sub _load_classes {
    my ($self) = @_;
    my @dirs = $self->_dirs;

    foreach my $dir (@dirs) {

        unless ( -d $dir ) {
            die "Cannot find ($dir) to sniff";
        }
        my @classes =
        map { $self->_load_class($_, $dir) }
        File::Find::Rule->file->name('*.pm')->in($dir);
        push @{$self->{classes}}, @classes;
    }
}

sub _load_class {
    my ( $self, $file, $dir ) = @_;
    $self->_say("Attempting to load ($file)");
    $file =~ s{\.pm$}{};    # remove .pm extension
    $file =~ s{\\}{/}g;     # to make win32 happy
    $dir  =~ s{\\}{/}g;     # to make win32 happy
    $file =~ s/^$dir//;
    my $_package = join '::' => grep $_ => File::Spec->splitdir($file);

    # untaint that puppy!
    my ($package) = $_package =~ /^([[:word:]]+(?:::[[:word:]]+)*)$/;

    my $use_lib = $self->{lib} ? "use lib qw(@{$self->{lib}});" : "";
    eval "$use_lib; use $package";    ## no critic
    warn $@ if $@;
    unless ($@) {
        $self->_say("$package loaded successfully");
    }
    return $package;
}

sub _say {
    my ( $self, $message ) = @_;
    return unless $self->_verbose;
    print "$message\n";
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-class-sniff at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Sniff>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Sniff

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Sniff>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Sniff>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Sniff>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Sniff/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
