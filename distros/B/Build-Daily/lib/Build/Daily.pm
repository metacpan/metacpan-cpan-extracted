package Build::Daily;

use warnings;
use strict;

our $VERSION = '0.01';

=head1 NAME

Build::Daily - module to update daily versions for Module::Build and ExtUtils::MakeMaker

=head1 SYNOPSIS

    perl -MBuild::Daily Build.PL
    perl -MBuild::Daily Makefile.PL
    
    # force version append, useful when not building daily but based on ex. SVN revisions
    perl -MBuild::Daily=version,12345 Build.PL
    perl -MBuild::Daily=version,12345 Build
    perl -MBuild::Daily=version,12345 Build distmeta
    perl -MBuild::Daily=version,12345 Build dist

=head1 DESCRIPTION

Updates C<$VERSION> string based on current date or forced string. This
allows to create daily/commit builds.

=head2 FUNCTIONS

=cut

use Module::Build 0.2808;
use Module::Build::ModuleInfo;
use ExtUtils::MakeMaker;
use DateTime;

# a references to the original methods
my $MODULE_BUILD_NEW;
my $EXTUTILS_MM_NEW;
BEGIN {
	$MODULE_BUILD_NEW = \&Module::Build::Base::new;
	$EXTUTILS_MM_NEW  = \&ExtUtils::MakeMaker::new;
}
our $FORCED_VERSION;
our $BUILD_DAILY_VERSION = \&version;

=head2 import()

    use Build::Daily 'version' => '12345';

Forces string that will be appended.

=cut

sub import {
    my $class = shift;
    my %args  = @_;
    
    $FORCED_VERSION = $args{'version'};
}

=head2 version($original_version)

For original version returns new version.

    $original_version.($original_version =~ m/_/ ? '' : '_').$append

C<$append> is either YearMonthDay or the forced string.

=cut

sub version {
    my $original_version = shift;
        
    my $append = (
        defined $FORCED_VERSION
        ? $FORCED_VERSION
        : DateTime->now('time_zone' => 'local')->ymd("")
    );
    
    return $original_version.($original_version =~ m/_/ ? '' : '_').$append;
}

no warnings 'redefine';

package Module::Build::Base;

sub new {
    my $class = shift;
    my %args  = @_;
    
    if (defined $args{'dist_version_from'}) {
        my $info = eval { Module::Build::ModuleInfo->new_from_file($args{'dist_version_from'}) };
        die 'failed to get VERSION from '.$args{'dist_version_from'}
            if not defined $info;
        
        delete $args{'dist_version_from'};
        $args{'dist_version'} = $info->{'version'}->{'original'};
    }
    if (defined $args{'dist_version'}) {
        $args{'dist_version'} = $BUILD_DAILY_VERSION->($args{'dist_version'});
    }
    
    return $MODULE_BUILD_NEW->($class, %args);
}

package ExtUtils::MakeMaker;

sub new {
    my $class = shift;
    my $args  = shift;
    
    if (defined $args->{'VERSION_FROM'}) {
        my $info = eval { Module::Build::ModuleInfo->new_from_file($args->{'VERSION_FROM'}) };
        die 'failed to get VERSION from '.$args->{'VERSION_FROM'}
            if not defined $info;
        
        delete $args->{'VERSION_FROM'};        
        $args->{'VERSION'} = $info->{'version'}->{'original'};
    }
    if (defined $args->{'VERSION'}) {
        $args->{'VERSION'} = $BUILD_DAILY_VERSION->($args->{'VERSION'});
    }
    
    return $EXTUTILS_MM_NEW->($class, $args);
}

'SUPERMAN gesucht';



__END__

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-build-daily at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Build-Daily>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Build::Daily


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Build-Daily>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Build-Daily>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Build-Daily>

=item * Search CPAN

L<http://search.cpan.org/dist/Build-Daily>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
