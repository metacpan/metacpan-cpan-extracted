package App::Du::Analyze::Filter;
$App::Du::Analyze::Filter::VERSION = '0.2.2';
use strict;
use warnings;

sub _my_all
{
    my $cb = shift;

    foreach my $x (@_)
    {
        if ( not $cb->( local $_ = $x ) )
        {
            return 0;
        }
    }

    return 1;
}

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _depth
{
    my $self = shift;

    if (@_)
    {
        $self->{_depth} = shift;
    }

    return $self->{_depth};
}

sub _prefix
{
    my $self = shift;

    if (@_)
    {
        $self->{_prefix} = shift;
    }

    return $self->{_prefix};
}

sub _should_sort
{
    my $self = shift;

    if (@_)
    {
        $self->{_should_sort} = shift;
    }

    return $self->{_should_sort};
}

sub _init
{
    my ( $self, $args ) = @_;

    $self->_prefix( $args->{prefix} );
    $self->_depth( $args->{depth} );
    $self->_should_sort(1);

    if ( exists( $args->{should_sort} ) )
    {
        $self->_should_sort( $args->{should_sort} );
    }

    return;
}

sub filter
{
    my ( $self, $in_fh, $out_fh ) = @_;

    my $prefix = $self->_prefix;
    my $sort   = $self->_should_sort;
    my $depth  = $self->_depth;

    my $compare_depth = $depth - 1;
    my @results;

    $prefix =~ s#/+\z##;

    my @prefix_to_test = split( m#/#, $prefix );

    while ( my $line = <$in_fh> )
    {
        chomp($line);
        if ( my ( $size, $total_path, $path ) =
            $line =~ m#\A(\d+)\t(\.(.*?))\z# )
        {
            my @path_to_test = split( m#/#, $total_path );

            # Get rid of the ".".
            shift(@path_to_test);

            if (
                ( @path_to_test == @prefix_to_test + $depth )
                and (
                    _my_all(
                        sub { $path_to_test[$_] eq $prefix_to_test[$_] },
                        ( 0 .. $#prefix_to_test )
                    )
                )
                )
            {
                $path =~ s#\A/##;
                push @results, [ $path, $size ];
            }
        }
    }

    if ($sort)
    {
        @results = ( sort { $a->[1] <=> $b->[1] } @results );
    }

    foreach my $r (@results)
    {
        print {$out_fh} "$r->[1]\t$r->[0]\n";
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Du::Analyze::Filter - filter algorithm for L<App::Du::Analyze>

=head1 VERSION

version 0.2.2

=head1 VERSION

version 0.2.2

=head1 NOTE

Everything here is subject to change. The API is for internal use.

=head1 METHODS

=head2 App::Du::Analyze::Filter->new()

Accepted arguments:

=over 4

=item * prefix

The prefix of the path to filter.

=item * depth

The number of directory components below. Defaults to 1.

=item * should_sort

Should the items be sorted. A boolean that defaults to 0.

=back

=head2 $obj->filter($in_fh, $out_fh)

Filter the input from $in_fh (a readonly or readwrite filehandle), which
is the output of du, and output it to $out_fh .

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Du-Analyze>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Du-Analyze>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Du-Analyze>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Du-Analyze>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Du-Analyze>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Du::Analyze>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-du-analyze at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Du-Analyze>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-App-Du-Analyze>

  git clone git://github.com/shlomif/perl-App-Du-Analyze.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-App-Du-Analyze/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Du-Analyze>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Du-Analyze>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Du-Analyze>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Du-Analyze>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Du-Analyze>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Du::Analyze>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-du-analyze at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Du-Analyze>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-App-Du-Analyze>

  git clone git://github.com/shlomif/perl-App-Du-Analyze.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-App-Du-Analyze/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
