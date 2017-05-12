package Alien::Packages;

use warnings;
use strict;

require 5.008;
require Module::Pluggable::Object;

=head1 NAME

Alien::Packages - Find information of installed packages

=cut

our $VERSION = '0.003';

=head1 SYNOPSIS

    my $ap = Alien::Packages->new();

    my @packages = $ap->list_packages();
    foreach my $pkg (@packages)
    {
	print "$pkg->[0] version $pkg->[1]: $pkg->[2]\n";
    }

    my %perl_owners = $ap->list_fileowners( File::Spec->rel2abs( $^X ) );
    while( my ($fn, $pkg) = each( %perl_owners ) )
    {
	print "$fn is provided by ", join( ", ", @$pkg ), "\n";
    }

=head1 SUBROUTINES/METHODS

=head2 new

Instantiates new Alien::Packages object. Attributes can be specified
for used finder (of type L<Module::Pluggable::Object>). Additionally,

=over 4

=item C<only_loaded>

Use only plugins which are still loaded.

=back

can be specified with a true value. This forces to grep C<%INC> instead
of using Module::Pluggable.

=cut

sub new
{
    my ( $class, %attrs ) = @_;
    my $self = bless( { plugins => [], }, $class );

    my $only_loaded = delete $attrs{only_loaded};

    if ($only_loaded)
    {
        my @search_path = __PACKAGE__ eq $class ? (__PACKAGE__) : ( __PACKAGE__, $class );
        foreach my $path (@search_path)
        {
            $path =~ s|::|/|g;
            $path .= "/";
            my @loadedModules = grep { 0 == index( $_, $path ) } keys %INC;
            foreach my $module (@loadedModules)
            {
                $module =~ s|/|::|;
                $module =~ s/\.pm$//;
                next unless ( $module->can('usable') && $module->usable() );
                push( @{ $self->{plugins} }, $module->new() );
            }
        }
    }
    else
    {
        %attrs = (
                   require     => 1,
                   search_path => [ __PACKAGE__ eq $class ? __PACKAGE__ : ( __PACKAGE__, $class ) ],
                   inner       => 0,
                   %attrs,
                 );
        my $finder     = Module::Pluggable::Object->new(%attrs);
        my @pkgClasses = $finder->plugins();
        foreach my $pkgClass (@pkgClasses)
        {
            next unless ( $pkgClass->can('usable') && $pkgClass->usable() );
            push( @{ $self->{plugins} }, $pkgClass->new() );
        }
    }

    return $self;
}

=head2 list_packages

Lists the installed packages on the system (if the caller has the
permission to do).

Results in a list of array references, whereby each item contains:

  {
      PkgType => $pkg_type, # e.g. 'dpkg', 'pkgsrc', ...
      Package => $pkg_name,
      Version => $version,
      Summary => $summary,
  }

C<type> is the packager type, e.g. I<rpm>, I<lpp> or I<pkgsrc>.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    foreach my $plugin ( @{ $self->{plugins} } )
    {
        my @ppkgs   = $plugin->list_packages();
        my $pkgtype = $plugin->pkgtype();
        foreach my $pkg (@ppkgs)
        {
            $pkg->{PkgType} = $pkgtype;
            push( @packages, $pkg );
        }
    }

    return @packages;
}

=head2 list_fileowners

Provides an association between files on the system and the package which
reference it (has presumably installed it).

Returns a hash with the files names as key and a list of referencing
package names as value:

  '/absolute/path/to/file' =>
      [
	  {
	      PkgType => $pkg_type,
	      Package => $pkg_name,
	  }
      ],
  ...

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

    foreach my $plugin ( @{ $self->{plugins} } )
    {
        my $pkgtype = $plugin->pkgtype();
        my %pfos    = $plugin->list_fileowners(@files);
        while ( my ( $fn, $pkgs ) = each %pfos )
        {
            foreach my $pkg (@$pkgs)
            {
                $pkg->{PkgType} = $pkgtype;
            }

            if ( defined( $file_owners{$fn} ) )
            {
                push( @{ $file_owners{$fn} }, @{$pkgs} );
            }
            else
            {
                $file_owners{$fn} = $pkgs;
            }
        }
    }

    return %file_owners;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 GETTING HELP

To get novice help, it's usually recommended to ask on typical platforms
like PerlMonks.  To help you make the best use of the PerlMonks platform,
and any other lists or forums you may use, I strongly recommend that you
read "How To Ask Questions The Smart Way" by Eric Raymond:
L<http://www.catb.org/~esr/faqs/smart-questions.html>.

If you really asks a question what noone can answer, please drop me a
note with the question URL to either my CPAN address or on C<irc.perl.org>
in the channels C<#toolchain> or C<#devops>. I'll try to answer as best
as I can (and as soon, as possible, of course).

=head2 Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version only.
To get patches for earlier versions, you need to get an agreement with a
developer of your choice - who may or not report the issue and a suggested
fix upstream (depends on the license you have chosen).

=head2 Business support and maintenance

For business support you can contact Jens via his CPAN email address
rehsackATcpan.org. Please keep in mind that business support is neither
available for free nor are you eligible to receive any support based on
the license distributed with this package.

=head1 BUGS

This module is alpha software, the API may change in future releases.
See L<Alien::Packages::Roadmap> for more details.

Please report any bugs or feature requests to
C<bug-alien-packages at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-Packages>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::Packages

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-Packages>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-Packages>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-Packages>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-Packages/>

=back

If you think you've found a bug then please also read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 RESOURCES AND CONTRIBUTIONS

There're several ways how you can help to support future development: You can
hire the author to implement the features you require at most (this also
defines priorities), you can negotiate a support and maintenance contract
with the company of the author and you can provide tests and patches. Further,
you can submit documentation and links to resources to improve or add
packaging systems or grant remote access to machines with insufficient
supported packaging tools.

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Alien::Packages
