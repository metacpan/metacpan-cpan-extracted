use 5.008_001;
use strict;
use warnings;

package CPAN::Command::Bugtracker;
our $VERSION = '1.100840';
# ABSTRACT: Adds a 'bugtracker' command to the CPAN shell
use CPAN;    # so it can be used with CPAN::Commander or standalone
use Regexp::Common qw(URI);
use URI;
push @CPAN::Complete::COMMANDS, qw( bugtracker );
$CPAN::Shell::Help->{bugtracker} = "open a distribution's bug tracker web page";
sub CPAN::Shell::bugtracker { shift->rematein('bugtracker', @_) }
sub CPAN::Module::bugtracker { shift->rematein('bugtracker') }

sub CPAN::Distribution::bugtracker {
    my $self = shift;
    $self->get;
    my $package = $self->called_for;
    my $meta    = $self->parse_meta_yml;
    my $url     = $meta->{resources}{bugtracker}
      or return $CPAN::Frontend->mywarn(
        "$package doesn't have a bugtracker set in META.yml");
    if ($url =~ /^$RE{URI}{HTTP}$/) {
        system("open $url");
    } else {
        $CPAN::Frontend->mywarn("$url doesn't look like a URI");
    }
}
1;


__END__
=pod

=head1 NAME

CPAN::Command::Bugtracker - Adds a 'bugtracker' command to the CPAN shell

=head1 VERSION

version 1.100840

=head1 SYNOPSIS

    # sudo perl -MCPAN::Command -e 'CPAN::shell()'
    # cpan> bugtracker Foo::Bar

=head1 DESCRIPTION

This is a plugin for L<CPAN::Command> which adds a C<bugtracker> command to
the CPAN shell. The command expects a module name and opens the web page for
the distribution's bug tracker, if one is set in the distribution's
L<META.yml> file.

Currently opening the web page is done with the C<open(1)> command, so it
will probably only work with Mac OS X. Patches for other operating systems are
welcome.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Command>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/CPAN-Command/>.

The development version lives at
L<http://github.com/hanekomu/CPAN-Command/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

