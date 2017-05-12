package Alien::gputils;
use strict;
use warnings;
use Env qw(@PATH);

if ($^O =~ /mswin32/i) {
    foreach (qw{PROGRAMFILES ProgramFiles PROGRAMFILES(X86)
                ProgramFiles(X86) ProgamFileW6432 PROGRAMFILESW6432}) {
        next unless exists $ENV{$_};
        my $dir = ($ENV{$_} =~ /\s+/) ? Win32::GetShortPathName($ENV{$_}) : $ENV{$_};
        push @PATH, File::Spec->catdir($dir, 'gputils', 'bin') if $dir;
    }
}
use File::Which qw(which);
use File::Spec;

our $VERSION = '0.08';
$VERSION = eval $VERSION;

use parent 'Alien::Base';

sub _get_gputils {
    my $self = shift;
    my $type = shift;
    my $bd = $self->bin_dir;
    if (defined $bd) {
        my $ext = ($^O =~ /mswin32/i) ? '.exe' : '';
        my $exe = File::Spec->catfile($bd, "$type$ext");
        return $exe if (defined $exe and -e $exe);
    }
    my ($exe2) = which($type);
    return $exe2;
}
sub gpasm { return $_[0]->_get_gputils('gpasm'); }
sub gplink { return $_[0]->_get_gputils('gplink'); }
sub gplib { return $_[0]->_get_gputils('gplib'); }
sub gpdasm { return $_[0]->_get_gputils('gpdasm'); }
sub gpstrip { return $_[0]->_get_gputils('gpstrip'); }
sub gpvc { return $_[0]->_get_gputils('gpvc'); }
sub gpvo { return $_[0]->_get_gputils('gpvo'); }
sub bin_dir {
    my $self = shift;
    if ($self->install_type('system')) {
        my ($path) = $self->config('gputils_system_path');
        return $path if $path;
    }
    return $self->SUPER::bin_dir();
}

1;

__END__
#### COPYRIGHT: Vikas N Kumar. Selective Intellect LLC. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 18th Nov 2014
#### LICENSE: Refer LICENSE file.

=head1 NAME

Alien::gputils

=head1 SYNOPSIS

Alien::gputils is a perl module that enables the installation of the gputils
toolkit for developing code for Microchip PIC microcontrollers.

The source code is taken from L<http://gputils.sourceforge.net>.

=head1 VERSION

0.07

=head1 METHODS

=over

=item B<gpasm>

This method returns the path to the C<gpasm> binary whether installed by this
module or if already installed in the C<$PATH>.

=item B<gplink>

This method returns the path to the C<gplink> binary whether installed by this
module or if already installed in the C<$PATH>.

=item B<gplib>

This method returns the path to the C<gplib> binary whether installed by this
module or if already installed in the C<$PATH>.

=item B<gpdasm>

This method returns the path to the C<gpdasm> binary whether installed by this
module or if already installed in the C<$PATH>.

=item B<gpstrip>

This method returns the path to the C<gpstrip> binary whether installed by this
module or if already installed in the C<$PATH>.

=item B<gpvc>

This method returns the path to the C<gpvc> binary whether installed by this
module or if already installed in the C<$PATH>.

=item B<gpvo>

This method returns the path to the C<gpvo> binary whether installed by this
module or if already installed in the C<$PATH>.

=item B<bin_dir>

This method provides the directory for the binaries that form the package of
gputils such as C<gpasm> and C<gplink> which are needed by their downstream
modules like L<VIC>.

=item B<config>

This method provides the access to configuration information for the library on
the system. More information can be seen in the module
L<Alien::gputils::ConfigData>.

=back

=head1 SEE ALSO

=over

=item C<Alien::gputils::ConfigData>

=back

=head1 AUTHORS

Vikas N Kumar <vikas@cpan.org>

=head1 REPOSITORY

L<https://github.com/vikasnkumar/Alien-gputils.git>

=head1 COPYRIGHT

Copyright (C) 2013-2014. Vikas N Kumar <vikas@cpan.org>. All Rights Reserved.

=head1 LICENSE

This is free software. YOu can redistribute it or modify it under the terms of
Perl itself.

